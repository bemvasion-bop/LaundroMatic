import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../controllers/theme_controller.dart';
import '../models/customer.dart';
import '../models/inventory.dart';
import '../models/order.dart';
import '../models/service.dart';
import '../services/customer_service.dart';
import '../services/inventory_service.dart';
import '../services/notification_service.dart';
import '../services/order_service.dart';
import '../services/service_service.dart';
import 'dashboard_page.dart';
import 'inventory_page.dart';
import 'inventory_transactions_page.dart';
import 'more_page.dart';

class OrdersPage extends StatefulWidget {
  final String? initialStatus;
  final String? initialDate;

  const OrdersPage({
    super.key,
    this.initialStatus,
    this.initialDate,
  });

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  final CustomerService _customerService = CustomerService();
  final ServiceService _serviceService = ServiceService();
  final OrderService _orderService = OrderService();
  final InventoryService _inventoryService = InventoryService();
  final NotificationService _notificationService = NotificationService();

  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _cashReceivedController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _plasticQtyController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  String selectedStatus = 'All';
  String selectedDate = 'All Dates';
  DateTime? selectedCustomDate;
  int currentPage = 1;
  static const int ordersPerPage = 15;

  @override
  void initState() {
    super.initState();
    if (widget.initialStatus != null) {
      selectedStatus = widget.initialStatus!;
    }
    if (widget.initialDate != null) {
      selectedDate = widget.initialDate!;
    }
  }

  String? _selectedCustomerId;
  String? _selectedServiceId;
  LaundryService? _selectedService;

  InventoryItem? _selectedDetergent;
  int _detergentQty = 0;
  double _detergentFee = 0;
  bool _showDetergents = false;

  InventoryItem? _selectedConditioner;
  int _conditionerQty = 0;
  double _conditionerFee = 0;
  bool _showConditioners = false;

  int _packageCount = 0;
  double _serviceTotal = 0;

  @override
  void dispose() {
    _searchController.dispose();
    _weightController.dispose();
    _cashReceivedController.dispose();
    _notesController.dispose();
    _plasticQtyController.dispose();
    super.dispose();
  }

  void _calculatePrice() {
    final double? weight = double.tryParse(_weightController.text.trim());
    if (_selectedService == null || weight == null || weight <= 0) {
      setState(() {
        _packageCount = 0;
        _serviceTotal = 0;
      });
      return;
    }
    final int packages = (weight / _selectedService!.maxWeight).ceil();
    final double serviceTotal = packages * _selectedService!.bundlePrice;
    setState(() {
      _packageCount = packages;
      _serviceTotal = serviceTotal;
    });
  }

  double _calculateGrandTotal() {
    return _serviceTotal + _detergentFee + _conditionerFee;
  }

  void _clearForm() {
    _selectedCustomerId = null;
    _selectedServiceId = null;
    _selectedService = null;
    _weightController.clear();
    _cashReceivedController.clear();
    _notesController.clear();

    _selectedDetergent = null;
    _detergentQty = 0;
    _detergentFee = 0;
    _showDetergents = false;

    _selectedConditioner = null;
    _conditionerQty = 0;
    _conditionerFee = 0;
    _showConditioners = false;

    _packageCount = 0;
    _serviceTotal = 0;
  }

  Future<void> _saveOrder() async {
    if (_selectedCustomerId == null) {
      _showMessage('Please select a customer.');
      return;
    }
    if (_selectedServiceId == null) {
      _showMessage('Please select a service.');
      return;
    }
    final double? weight = double.tryParse(_weightController.text.trim());
    if (weight == null || weight <= 0) {
      _showMessage('Please enter a valid weight.');
      return;
    }
    if (_packageCount == 0) {
      _showMessage('Please select a service and calculate the price.');
      return;
    }
    final double totalAmount = _calculateGrandTotal();
    final double? cashReceived =
        double.tryParse(_cashReceivedController.text.trim());

    if (cashReceived == null || cashReceived <= 0) {
      _showMessage('Please enter the cash received.');
      return;
    }
    if (cashReceived < totalAmount) {
      _showMessage(
          'Cash received is not enough. Required: ₱${totalAmount.toStringAsFixed(2)}');
      return;
    }
    final double changeAmount = cashReceived - totalAmount;

    try {
      await _orderService.createPaidOrder(
        customerId: _selectedCustomerId!,
        serviceId: _selectedServiceId!,
        weight: weight,
        packageCount: _packageCount,
        detergentOption: _selectedDetergent == null ? 'none' : 'inventory',
        detergentBrand: _selectedDetergent?.brand ?? '',
        detergentInventoryId: _selectedDetergent?.inventoryId,
        detergentQty: _detergentQty,
        detergentFee: _detergentFee,
        conditionerOption: _selectedConditioner == null ? 'none' : 'inventory',
        conditionerBrand: _selectedConditioner?.brand ?? '',
        conditionerInventoryId: _selectedConditioner?.inventoryId,
        conditionerQty: _conditionerQty,
        conditionerFee: _conditionerFee,
        serviceTotal: _serviceTotal,
        totalAmount: totalAmount,
        cashReceived: cashReceived,
        changeAmount: changeAmount,
        notes: _notesController.text.trim(),
      );

      if (!mounted) return;
      Navigator.pop(context);
      _clearForm();
      setState(() {});
      _showMessage(
          'Order created successfully! Change: ₱${changeAmount.toStringAsFixed(2)}');
    } catch (e) {
      if (!mounted) return;
      _showMessage('Error creating order: $e');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  String _formatDateTime(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    final month = months[dt.month - 1];
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$month ${dt.day}, ${dt.year}, $hour:$minute $ampm';
  }

  String _formatDateOnly(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    final month = months[dt.month - 1];
    return '$month ${dt.day}, ${dt.year}';
  }

  bool _matchesDateFilter(LaundryOrder order) {
    if (selectedDate == 'All Dates') return true;
    DateTime? date;

    switch (order.orderStatus) {
      case 'Clothes Received':
      case 'Pending':
        date = order.orderDate;
        break;
      case 'Processing':
        date = order.processingDate ?? order.orderDate;
        break;
      case 'Ready for Pickup':
      case 'Ready':
        date = order.readyDate ?? order.orderDate;
        break;
      case 'Picked Up':
        date = order.pickedUpDate ?? order.orderDate;
        break;
      default:
        date = order.orderDate;
    }

    if (date == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final orderDay = DateTime(date.year, date.month, date.day);

    if (selectedDate == 'Today') return orderDay == today;
    if (selectedDate == 'Yesterday') {
      return orderDay == today.subtract(const Duration(days: 1));
    }
    if (selectedDate == 'This Week') {
      final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
      final endOfWeek = startOfWeek.add(const Duration(days: 7));
      return !orderDay.isBefore(startOfWeek) && orderDay.isBefore(endOfWeek);
    }
    if (selectedDate == 'This Month') {
      final startOfPeriod = today.subtract(const Duration(days: 30));
      return !orderDay.isBefore(startOfPeriod) &&
          !orderDay.isAfter(today.add(const Duration(days: 1)));
    }
    if (selectedDate == 'Custom Date' && selectedCustomDate != null) {
      return orderDay.year == selectedCustomDate!.year &&
          orderDay.month == selectedCustomDate!.month &&
          orderDay.day == selectedCustomDate!.day;
    }
    return true;
  }

  Future<void> _startProcessing(LaundryOrder order) async {
    try {
      await _orderService.startProcessing(order);
      if (!mounted) return;
      final shortId = order.orderId.length > 6
          ? order.orderId.substring(0, 6)
          : order.orderId;
      _showMessage('Order #$shortId is now Processing.');
    } catch (e) {
      if (!mounted) return;
      _showMessage('Error starting order: $e');
    }
  }

  Future<void> _markPickedUp(LaundryOrder order) async {
    try {
      await _orderService.markPickedUp(order.orderId);
      if (!mounted) return;
      _showMessage('Order marked as Picked Up.');
    } catch (e) {
      if (!mounted) return;
      _showMessage('Failed to mark order as picked up: $e');
    }
  }

  Future<void> _confirmPickedUp(LaundryOrder order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Mark as Picked Up?',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'Are you sure this order has been picked up by the customer?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E64D4),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
    if (confirmed == true) {
      await _markPickedUp(order);
    }
  }

  Future<void> _sendReadyForPickupNotification(
    LaundryOrder order,
    Customer? customer,
    LaundryService? service,
  ) async {
    if (customer == null || customer.email.trim().isEmpty) {
      _showMessage('Customer email is not available.');
      return;
    }
    try {
      await _notificationService.sendReadyForPickupEmail(
        toEmail: customer.email,
        customerName: customer.name,
        customerId: customer.customerId,
        orderId: order.orderId,
        serviceName: service?.serviceName ?? 'Unknown Service',
        weight: order.weight,
        totalAmount: order.totalAmount,
        orderStatus: order.orderStatus,
      );
      if (!mounted) return;
      _showMessage('Ready for Pickup notification sent to ${customer.email}.');
    } catch (e) {
      if (!mounted) return;
      _showMessage(e.toString().replaceAll('Exception: ', ''));
    }
  }

  void _showDateFilter() {
    final colors = ThemeController.colors;
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: colors.cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: colors.border),
          ),
          title: Text(
            'Filter by Date',
            style: TextStyle(fontWeight: FontWeight.bold, color: colors.textPrimary),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _dateFilterOption(dialogContext, 'All Dates'),
              _dateFilterOption(dialogContext, 'Today'),
              _dateFilterOption(dialogContext, 'Yesterday'),
              _dateFilterOption(dialogContext, 'This Week'),
              _dateFilterOption(dialogContext, 'This Month'),
              _dateFilterOption(dialogContext, 'Custom Date'),
            ],
          ),
        );
      },
    );
  }

  Widget _dateFilterOption(BuildContext dialogContext, String option) {
    final colors = ThemeController.colors;
    final bool isSelected = selectedDate == option;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      tileColor: isSelected
          ? colors.primaryLight
          : Colors.transparent,
      title: Text(
        option,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? colors.primary : colors.textPrimary,
        ),
      ),
      trailing: isSelected
          ? Icon(Icons.check_circle_rounded, color: colors.primary)
          : null,
      onTap: () async {
        if (option == 'Custom Date') {
          Navigator.pop(dialogContext);
          final pickedDate = await showDatePicker(
            context: context,
            initialDate: selectedCustomDate ?? DateTime.now(),
            firstDate: DateTime(2020),
            lastDate: DateTime.now(),
          );
          if (pickedDate != null) {
            setState(() {
              selectedDate = 'Custom Date';
              selectedCustomDate = pickedDate;
              currentPage = 1;
            });
          }
          return;
        }
        setState(() {
          selectedDate = option;
          selectedCustomDate = null;
          currentPage = 1;
        });
        Navigator.pop(dialogContext);
      },
    );
  }

  Color _getStatusBgColor(String status) {
    final isDark = ThemeController.isDark;
    switch (status) {
      case 'Processing':
        return isDark ? const Color(0xFF1E3A8A).withValues(alpha: 0.5) : const Color(0xFFDBEAFE);
      case 'Ready':
      case 'Ready for Pickup':
        return isDark ? const Color(0xFF064E3B).withValues(alpha: 0.5) : const Color(0xFFDCFCE7);
      case 'Picked Up':
        return isDark ? const Color(0xFF581C87).withValues(alpha: 0.5) : const Color(0xFFF3E8FF);
      case 'Clothes Received':
      case 'Pending':
      default:
        return isDark ? const Color(0xFF78350F).withValues(alpha: 0.5) : const Color(0xFFFEF3C7);
    }
  }

  Color _getStatusTextColor(String status) {
    final isDark = ThemeController.isDark;
    switch (status) {
      case 'Processing':
        return isDark ? const Color(0xFF93C5FD) : const Color(0xFF1D4ED8);
      case 'Ready':
      case 'Ready for Pickup':
        return isDark ? const Color(0xFF86EFAC) : const Color(0xFF15803D);
      case 'Picked Up':
        return isDark ? const Color(0xFFD8B4FE) : const Color(0xFF7E22CE);
      case 'Clothes Received':
      case 'Pending':
      default:
        return isDark ? const Color(0xFFFDE68A) : const Color(0xFFD97706);
    }
  }

  Color _getStatusIconBgColor(String status) {
    final isDark = ThemeController.isDark;
    switch (status) {
      case 'Processing':
        return isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF);
      case 'Ready':
      case 'Ready for Pickup':
        return isDark ? const Color(0xFF1E293B) : const Color(0xFFF0FDF4);
      case 'Picked Up':
        return isDark ? const Color(0xFF1E293B) : const Color(0xFFFAF5FF);
      case 'Clothes Received':
      case 'Pending':
      default:
        return isDark ? const Color(0xFF1E293B) : const Color(0xFFFFFBEB);
    }
  }

  Color _getStatusIconColor(String status) {
    final isDark = ThemeController.isDark;
    switch (status) {
      case 'Processing':
        return isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB);
      case 'Ready':
      case 'Ready for Pickup':
        return isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A);
      case 'Picked Up':
        return isDark ? const Color(0xFFC084FC) : const Color(0xFF9333EA);
      case 'Clothes Received':
      case 'Pending':
      default:
        return isDark ? const Color(0xFFFBBF24) : const Color(0xFFF59E0B);
    }
  }

  String _getDisplayStatus(String status) {
    if (status == 'Clothes Received') return 'Pending';
    return status;
  }

  void _showOrderDetails(
      LaundryOrder order, Customer? customer, LaundryService? service) {
    final colors = ThemeController.colors;
    final shortId = order.orderId.length > 6
        ? order.orderId.substring(0, 6)
        : order.orderId;
    final displayStatus = _getDisplayStatus(order.orderStatus);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: colors.cardBg,
          shape:
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
                side: BorderSide(color: colors.border),
              ),
          titlePadding: const EdgeInsets.fromLTRB(20, 20, 16, 12),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20),
          actionsPadding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Order #$shortId',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: colors.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusBgColor(order.orderStatus),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  displayStatus,
                  style: TextStyle(
                    color: _getStatusTextColor(order.orderStatus),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 440,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 6),

                  // Customer Section
                  _buildDetailCard(
                    title: 'Customer Details',
                    icon: Icons.person_outline_rounded,
                    children: [
                      Text(
                        customer?.name ?? 'Customer not found',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: colors.textPrimary,
                        ),
                      ),
                      if (customer?.phone.isNotEmpty == true) ...[
                        const SizedBox(height: 3),
                        Text('Phone: ${customer!.phone}',
                            style: TextStyle(
                                fontSize: 13, color: colors.textSecondary)),
                      ],
                      if (customer?.email.isNotEmpty == true) ...[
                        const SizedBox(height: 3),
                        Text('Email: ${customer!.email}',
                            style: TextStyle(
                                fontSize: 13, color: colors.textSecondary)),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Laundry Section
                  _buildDetailCard(
                    title: 'Laundry Service',
                    icon: Icons.local_laundry_service_outlined,
                    children: [
                      Text(
                        'Service: ${service?.serviceName ?? 'Unknown Service'}',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text('Weight: ${order.weight} kg',
                          style: TextStyle(
                              fontSize: 13, color: colors.textSecondary)),
                      const SizedBox(height: 3),
                      Text('Packages: ${order.packageCount}',
                          style: TextStyle(
                              fontSize: 13, color: colors.textSecondary)),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Add-ons Section
                  _buildDetailCard(
                    title: 'Add-ons',
                    icon: Icons.sanitizer_outlined,
                    children: [
                      Text(
                        order.detergentQty > 0
                            ? 'Detergent: ${order.detergentBrand} x ${order.detergentQty}'
                            : 'Detergent: None',
                        style: TextStyle(
                            fontSize: 13, color: colors.textSecondary),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        order.conditionerQty > 0
                            ? 'Fabric Conditioner: ${order.conditionerBrand} x ${order.conditionerQty}'
                            : 'Fabric Conditioner: None',
                        style: TextStyle(
                            fontSize: 13, color: colors.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Payment Section
                  _buildDetailCard(
                    title: 'Payment',
                    icon: Icons.payments_outlined,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total Amount',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: colors.textPrimary,
                            ),
                          ),
                          Text(
                            '₱${order.totalAmount.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: colors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Payment Method: Cash',
                        style:
                            TextStyle(fontSize: 13, color: colors.textSecondary),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text('Payment Status: ',
                              style: TextStyle(
                                  fontSize: 13, color: colors.textSecondary)),
                          Text(
                            order.paymentStatus,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: order.paymentStatus == 'Paid'
                                  ? colors.successText
                                  : colors.warningText,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Plastic Packaging section (if Processing)
                  if (order.orderStatus == 'Processing') ...[
                    const SizedBox(height: 12),
                    _buildDetailCard(
                      title: 'Plastic Packaging',
                      icon: Icons.inventory_2_outlined,
                      children: [
                        StreamBuilder<List<InventoryItem>>(
                          stream: _inventoryService.getPlasticBags(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const LinearProgressIndicator();
                            }
                            final plasticItems = snapshot.data ?? [];
                            if (plasticItems.isEmpty) {
                              return Text(
                                  'No plastic packaging available in inventory.',
                                  style: TextStyle(fontSize: 13, color: colors.textSecondary));
                            }
                            final plasticItem = plasticItems.first;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                        color: colors.border),
                                    borderRadius: BorderRadius.circular(10),
                                    color: colors.cardBg,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        plasticItem.itemName,
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            color: colors.textPrimary),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Brand: ${plasticItem.brand} • Size: ${plasticItem.size}',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: colors.textSecondary),
                                      ),
                                      Text(
                                        'Available: ${plasticItem.quantity} ${plasticItem.unit}',
                                        style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: colors.primary),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 10),
                                TextField(
                                  controller: _plasticQtyController,
                                  keyboardType: TextInputType.number,
                                  style: TextStyle(color: colors.textPrimary),
                                  decoration: InputDecoration(
                                    labelText: 'Quantity Used',
                                    labelStyle: TextStyle(color: colors.textSecondary),
                                    suffixText: plasticItem.unit,
                                    suffixStyle: TextStyle(color: colors.textSecondary),
                                    filled: true,
                                    fillColor: colors.inputFill,
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 10),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(
                                          color: colors.inputBorder),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(
                                          color: colors.inputBorder),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: colors.successText,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12),
                                    ),
                                    onPressed: () async {
                                      final quantity = int.tryParse(
                                          _plasticQtyController.text.trim());
                                      if (quantity == null || quantity <= 0) {
                                        _showMessage(
                                            'Please enter a valid plastic quantity.');
                                        return;
                                      }
                                      try {
                                        await _orderService.markReadyForPickup(
                                          order: order,
                                          plasticInventoryId:
                                              plasticItem.inventoryId,
                                          plasticQuantity: quantity,
                                        );
                                        if (!dialogContext.mounted) return;
                                        _plasticQtyController.clear();
                                        Navigator.pop(dialogContext);
                                        _showMessage(
                                            'Order marked Ready for Pickup.');
                                      } catch (e) {
                                        if (!mounted) return;
                                        _showMessage(e
                                            .toString()
                                            .replaceAll('Exception: ', ''));
                                      }
                                    },
                                    icon: const Icon(
                                        Icons.check_circle_outline_rounded,
                                        size: 18),
                                    label: const Text('Ready for Pickup',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ],

                  if (order.notes.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _buildDetailCard(
                      title: 'Notes',
                      icon: Icons.note_outlined,
                      children: [
                        Text(order.notes,
                            style: TextStyle(
                                fontSize: 13, color: colors.textSecondary)),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          actions: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (order.orderStatus == 'Clothes Received' &&
                    order.paymentStatus == 'Paid')
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () async {
                          Navigator.pop(dialogContext);
                          await _startProcessing(order);
                        },
                        icon: const Icon(
                            Icons.local_laundry_service_outlined,
                            size: 18),
                        label: const Text('Start Processing',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                if (order.orderStatus == 'Ready for Pickup') ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () async {
                          Navigator.pop(dialogContext);
                          await _sendReadyForPickupNotification(
                              order, customer, service);
                        },
                        icon: const Icon(Icons.email_outlined, size: 18),
                        label: const Text('Notify Customer',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.purpleText,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () async {
                          Navigator.pop(dialogContext);
                          await _confirmPickedUp(order);
                        },
                        icon: const Icon(Icons.check_circle_outline, size: 18),
                        label: const Text('Mark as Picked Up',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                ],
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: Text('Close',
                        style: TextStyle(color: colors.textSecondary)),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    final colors = ThemeController.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.subCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: colors.primary),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
          Divider(height: 16, thickness: 0.8, color: colors.divider),
          ...children,
        ],
      ),
    );
  }

  void _showCreateOrderDialog() {
    _clearForm();
    final colors = ThemeController.colors;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: colors.cardBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
                side: BorderSide(color: colors.border),
              ),
              titlePadding: const EdgeInsets.fromLTRB(20, 20, 16, 12),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              actionsPadding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Create Order',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 19,
                      color: colors.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded,
                        color: colors.textSecondary),
                    onPressed: () => Navigator.pop(dialogContext),
                  ),
                ],
              ),
              content: SizedBox(
                width: 450,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),

                      // Customer Dropdown
                      StreamBuilder<List<Customer>>(
                        stream: _customerService.getCustomers(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const LinearProgressIndicator();
                          }
                          final customers = snapshot.data ?? [];
                          return DropdownButtonFormField<String>(
                            isExpanded: true,
                            initialValue: _selectedCustomerId,
                            dropdownColor: colors.cardBg,
                            style: TextStyle(color: colors.textPrimary),
                            decoration: InputDecoration(
                              labelText: 'Customer *',
                              labelStyle: TextStyle(color: colors.textSecondary),
                              prefixIcon: Icon(
                                  Icons.person_outline_rounded,
                                  size: 20,
                                  color: colors.textSecondary),
                              filled: true,
                              fillColor: colors.inputFill,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                    color: colors.inputBorder),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                    color: colors.inputBorder),
                              ),
                            ),
                            items: customers.map((c) {
                              return DropdownMenuItem<String>(
                                value: c.customerId,
                                child: Text(c.name,
                                    style: TextStyle(color: colors.textPrimary),
                                    overflow: TextOverflow.ellipsis),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setDialogState(() => _selectedCustomerId = val);
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 12),

                      // Service Dropdown
                      StreamBuilder<List<LaundryService>>(
                        stream: _serviceService.getServices(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const LinearProgressIndicator();
                          }
                          final services = snapshot.data
                                  ?.where((s) => s.status == 'Active')
                                  .toList() ??
                              [];
                          return DropdownButtonFormField<String>(
                            isExpanded: true,
                            initialValue: _selectedServiceId,
                            dropdownColor: colors.cardBg,
                            style: TextStyle(color: colors.textPrimary),
                            decoration: InputDecoration(
                              labelText: 'Service *',
                              labelStyle: TextStyle(color: colors.textSecondary),
                              prefixIcon: Icon(
                                  Icons.local_laundry_service_outlined,
                                  size: 20,
                                  color: colors.textSecondary),
                              filled: true,
                              fillColor: colors.inputFill,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                    color: colors.inputBorder),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                    color: colors.inputBorder),
                              ),
                            ),
                            items: services.map((s) {
                              return DropdownMenuItem<String>(
                                value: s.serviceId,
                                child: Text(
                                  '${s.serviceName} - ₱${s.bundlePrice.toStringAsFixed(2)}',
                                  style: TextStyle(color: colors.textPrimary),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val == null) return;
                              final s = services.firstWhere(
                                  (element) => element.serviceId == val);
                              setDialogState(() {
                                _selectedServiceId = val;
                                _selectedService = s;
                              });
                              _calculatePrice();
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 12),

                      // Weight Field
                      TextField(
                        controller: _weightController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        style: TextStyle(color: colors.textPrimary),
                        decoration: InputDecoration(
                          labelText: 'Weight (kg) *',
                          labelStyle: TextStyle(color: colors.textSecondary),
                          prefixIcon:
                              Icon(Icons.scale_outlined, size: 20, color: colors.textSecondary),
                          suffixText: 'kg',
                          suffixStyle: TextStyle(color: colors.textSecondary),
                          filled: true,
                          fillColor: colors.inputFill,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                BorderSide(color: colors.inputBorder),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                BorderSide(color: colors.inputBorder),
                          ),
                        ),
                        onChanged: (_) {
                          _calculatePrice();
                          setDialogState(() {});
                        },
                      ),
                      const SizedBox(height: 12),

                      // Packages & Service Total summary card
                      if (_packageCount > 0)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colors.primaryLight,
                            border: Border.all(color: colors.primary.withValues(alpha: 0.3)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Packages: $_packageCount',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: colors.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Base bundle package',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: colors.primary.withValues(alpha: 0.8),
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                '₱${_serviceTotal.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: colors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 16),

                      // Add-ons Header
                      Text(
                        'Add-ons',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Detergent Toggle Button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: colors.border),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 11),
                          ),
                          onPressed: () {
                            setDialogState(
                                () => _showDetergents = !_showDetergents);
                          },
                          icon: Icon(
                            _showDetergents
                                ? Icons.keyboard_arrow_up
                                : Icons.add_rounded,
                            size: 18,
                            color: colors.primary,
                          ),
                          label: Text(
                            _showDetergents
                                ? 'Hide Detergents'
                                : 'Add Detergent',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: colors.primary,
                            ),
                          ),
                        ),
                      ),

                      if (_selectedDetergent != null) ...[
                        const SizedBox(height: 8),
                        _buildSelectedAddonCard(
                          item: _selectedDetergent!,
                          quantity: _detergentQty,
                          fee: _detergentFee,
                          onMinus: () {
                            if (_detergentQty > 1) {
                              setDialogState(() {
                                _detergentQty--;
                                _detergentFee =
                                    _selectedDetergent!.pricePerUnit *
                                        _detergentQty;
                              });
                            }
                          },
                          onPlus: () {
                            if (_detergentQty < _selectedDetergent!.quantity) {
                              setDialogState(() {
                                _detergentQty++;
                                _detergentFee =
                                    _selectedDetergent!.pricePerUnit *
                                        _detergentQty;
                              });
                            }
                          },
                          onRemove: () {
                            setDialogState(() {
                              _selectedDetergent = null;
                              _detergentQty = 0;
                              _detergentFee = 0;
                            });
                          },
                        ),
                      ],

                      if (_showDetergents) ...[
                        const SizedBox(height: 10),
                        _buildInventoryProducts(
                          stream: _inventoryService.getDetergents(),
                          title: 'Available Detergents',
                          selectedItem: _selectedDetergent,
                          onSelect: (item) {
                            setDialogState(() {
                              _selectedDetergent = item;
                              _detergentQty = 1;
                              _detergentFee = item.pricePerUnit;
                              _showDetergents = false;
                            });
                          },
                        ),
                      ],
                      const SizedBox(height: 12),

                      // Fabric Conditioner Toggle Button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: colors.border),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 11),
                          ),
                          onPressed: () {
                            setDialogState(
                                () => _showConditioners = !_showConditioners);
                          },
                          icon: Icon(
                            _showConditioners
                                ? Icons.keyboard_arrow_up
                                : Icons.add_rounded,
                            size: 18,
                            color: colors.primary,
                          ),
                          label: Text(
                            _showConditioners
                                ? 'Hide Fabric Conditioners'
                                : 'Add Fabric Conditioner',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: colors.primary,
                            ),
                          ),
                        ),
                      ),

                      if (_selectedConditioner != null) ...[
                        const SizedBox(height: 8),
                        _buildSelectedAddonCard(
                          item: _selectedConditioner!,
                          quantity: _conditionerQty,
                          fee: _conditionerFee,
                          onMinus: () {
                            if (_conditionerQty > 1) {
                              setDialogState(() {
                                _conditionerQty--;
                                _conditionerFee =
                                    _selectedConditioner!.pricePerUnit *
                                        _conditionerQty;
                              });
                            }
                          },
                          onPlus: () {
                            if (_conditionerQty <
                                _selectedConditioner!.quantity) {
                              setDialogState(() {
                                _conditionerQty++;
                                _conditionerFee =
                                    _selectedConditioner!.pricePerUnit *
                                        _conditionerQty;
                              });
                            }
                          },
                          onRemove: () {
                            setDialogState(() {
                              _selectedConditioner = null;
                              _conditionerQty = 0;
                              _conditionerFee = 0;
                            });
                          },
                        ),
                      ],

                      if (_showConditioners) ...[
                        const SizedBox(height: 10),
                        _buildInventoryProducts(
                          stream: _inventoryService.getFabricConditioners(),
                          title: 'Available Fabric Conditioners',
                          selectedItem: _selectedConditioner,
                          onSelect: (item) {
                            setDialogState(() {
                              _selectedConditioner = item;
                              _detergentQty = 1;
                              _conditionerFee = item.pricePerUnit;
                              _showConditioners = false;
                            });
                          },
                        ),
                      ],
                      const SizedBox(height: 16),

                      // Cash Payment Section
                      Text(
                        'Cash Payment',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _cashReceivedController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        style: TextStyle(color: colors.textPrimary),
                        decoration: InputDecoration(
                          labelText: 'Cash Received *',
                          labelStyle: TextStyle(color: colors.textSecondary),
                          prefixText: '₱ ',
                          prefixStyle: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: colors.textPrimary),
                          filled: true,
                          fillColor: colors.inputFill,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                BorderSide(color: colors.inputBorder),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                BorderSide(color: colors.inputBorder),
                          ),
                        ),
                        onChanged: (_) => setDialogState(() {}),
                      ),
                      const SizedBox(height: 10),

                      // Change Calculation Box
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: colors.subCardBg,
                          border: Border.all(color: colors.border),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Change',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: colors.textSecondary,
                              ),
                            ),
                            Text(
                              () {
                                final cash = double.tryParse(
                                    _cashReceivedController.text.trim());
                                final total = _calculateGrandTotal();
                                if (cash == null || cash < total) {
                                  return '₱0.00';
                                }
                                return '₱${(cash - total).toStringAsFixed(2)}';
                              }(),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 17,
                                color: colors.successText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Breakdown Box
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colors.subCardBg,
                          border: Border.all(color: colors.border),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Service:',
                                    style: TextStyle(
                                        fontSize: 13,
                                        color: colors.textSecondary)),
                                Text(
                                    '₱${_serviceTotal.toStringAsFixed(2)}',
                                    style: TextStyle(
                                        fontSize: 13,
                                        color: colors.textPrimary,
                                        fontWeight: FontWeight.w500)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Detergent:',
                                    style: TextStyle(
                                        fontSize: 13,
                                        color: colors.textSecondary)),
                                Text(
                                    '₱${_detergentFee.toStringAsFixed(2)}',
                                    style: TextStyle(
                                        fontSize: 13,
                                        color: colors.textPrimary,
                                        fontWeight: FontWeight.w500)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Fabric Conditioner:',
                                    style: TextStyle(
                                        fontSize: 13,
                                        color: colors.textSecondary)),
                                Text(
                                    '₱${_conditionerFee.toStringAsFixed(2)}',
                                    style: TextStyle(
                                        fontSize: 13,
                                        color: colors.textPrimary,
                                        fontWeight: FontWeight.w500)),
                              ],
                            ),
                            Divider(
                                height: 16, color: colors.divider),
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Total Amount:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: colors.textPrimary,
                                  ),
                                ),
                                Text(
                                  '₱${_calculateGrandTotal().toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 17,
                                    color: colors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Notes Input
                      TextField(
                        controller: _notesController,
                        maxLines: 3,
                        style: TextStyle(color: colors.textPrimary),
                        decoration: InputDecoration(
                          labelText: 'Notes (optional)',
                          labelStyle: TextStyle(color: colors.textSecondary),
                          filled: true,
                          fillColor: colors.inputFill,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                BorderSide(color: colors.inputBorder),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                BorderSide(color: colors.inputBorder),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: colors.border),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () => Navigator.pop(dialogContext),
                        child: Text('Cancel',
                            style: TextStyle(color: colors.textSecondary)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: _saveOrder,
                        icon: const Icon(Icons.payment_rounded, size: 18),
                        label: const Text(
                          'Pay & Create Order',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildProductThumbnail({
    required String imageUrl,
    double? width,
    double? height,
    double size = 48,
    required Widget fallback,
    BorderRadius? borderRadius,
    BoxFit fit = BoxFit.cover,
  }) {
    final colors = ThemeController.colors;
    final double effectiveWidth = width ?? size;
    final double effectiveHeight = height ?? size;
    final radius = borderRadius ?? BorderRadius.circular(10);
    final trimmed = imageUrl.trim();
    if (trimmed.isEmpty) {
      return fallback;
    }

    Widget? imageWidget;

    if (trimmed.startsWith('data:image') ||
        (!trimmed.startsWith('http://') &&
            !trimmed.startsWith('https://') &&
            trimmed.length > 50)) {
      try {
        final String base64Data =
            trimmed.contains(',') ? trimmed.split(',').last : trimmed;
        final bytes = base64Decode(base64Data);
        imageWidget = Image.memory(
          bytes,
          width: effectiveWidth,
          height: effectiveHeight,
          fit: fit,
          errorBuilder: (context, error, stackTrace) => fallback,
        );
      } catch (_) {
        return fallback;
      }
    } else if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      imageWidget = Image.network(
        trimmed,
        width: effectiveWidth,
        height: effectiveHeight,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => fallback,
      );
    }

    if (imageWidget != null) {
      return Container(
        width: effectiveWidth,
        height: effectiveHeight,
        decoration: BoxDecoration(
          borderRadius: radius,
          border: Border.all(color: colors.border),
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: imageWidget,
        ),
      );
    }

    return fallback;
  }

  Widget _buildSelectedAddonCard({
    required InventoryItem item,
    required int quantity,
    required double fee,
    required VoidCallback onMinus,
    required VoidCallback onPlus,
    required VoidCallback onRemove,
  }) {
    final colors = ThemeController.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(12),
        color: colors.subCardBg,
      ),
      child: Row(
        children: [
          _buildProductThumbnail(
            imageUrl: item.imageUrl,
            width: 56,
            height: 56,
            size: 56,
            borderRadius: BorderRadius.circular(10),
            fallback: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: colors.primaryLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                item.itemType == 'Detergent'
                    ? Icons.sanitizer_outlined
                    : Icons.clean_hands_outlined,
                size: 28,
                color: colors.primary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.brand.isNotEmpty ? item.brand : item.itemName,
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13, color: colors.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  item.scent.isNotEmpty ? item.scent : item.size,
                  style: TextStyle(
                      fontSize: 11.5, color: colors.textSecondary),
                ),
                Text(
                  '₱${item.pricePerUnit.toStringAsFixed(2)} / ${item.unit}',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colors.primary),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    InkWell(
                      onTap: quantity > 1 ? onMinus : null,
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: quantity > 1
                              ? colors.cardBg
                              : colors.subCardBg,
                          border: Border.all(color: colors.border),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(Icons.remove,
                            size: 16,
                            color: quantity > 1
                                ? colors.textPrimary
                                : colors.textMuted),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        '$quantity',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14, color: colors.textPrimary),
                      ),
                    ),
                    InkWell(
                      onTap: quantity < item.quantity ? onPlus : null,
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: quantity < item.quantity
                              ? colors.cardBg
                              : colors.subCardBg,
                          border: Border.all(color: colors.border),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(Icons.add,
                            size: 16,
                            color: quantity < item.quantity
                                ? colors.textPrimary
                                : colors.textMuted),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₱${fee.toStringAsFixed(2)}',
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 14, color: colors.textPrimary),
              ),
              const SizedBox(height: 6),
              TextButton(
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(50, 24),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: onRemove,
                child: Text('Remove',
                    style: TextStyle(color: colors.errorText, fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryProducts({
    required Stream<List<InventoryItem>> stream,
    required String title,
    required InventoryItem? selectedItem,
    required void Function(InventoryItem item) onSelect,
  }) {
    final colors = ThemeController.colors;
    return StreamBuilder<List<InventoryItem>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: colors.primary));
        }
        if (snapshot.hasError) {
          return Text('Error loading products: ${snapshot.error}', style: TextStyle(color: colors.errorText));
        }
        final items = (snapshot.data ?? [])
            .where((item) => item.quantity > 0)
            .toList();
        if (items.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(12),
            child: Text('No available items in inventory.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: colors.textSecondary)),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 13, color: colors.textPrimary)),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.70,
              ),
              itemBuilder: (context, index) {
                final item = items[index];
                final isSelected =
                    selectedItem?.inventoryId == item.inventoryId;
                return Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colors.cardBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected
                          ? colors.primary
                          : colors.border,
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: colors.isDark ? 0.2 : 0.03),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Prominent, large product image showcase
                      SizedBox(
                        width: double.infinity,
                        height: 105,
                        child: _buildProductThumbnail(
                          imageUrl: item.imageUrl,
                          width: double.infinity,
                          height: 105,
                          borderRadius: BorderRadius.circular(10),
                          fit: BoxFit.cover,
                          fallback: Container(
                            width: double.infinity,
                            height: 105,
                            decoration: BoxDecoration(
                              color: colors.primaryLight,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              item.itemType == 'Detergent'
                                  ? Icons.sanitizer_outlined
                                  : (item.itemType == 'Fabric Conditioner'
                                      ? Icons.clean_hands_outlined
                                      : Icons.inventory_2_outlined),
                              size: 38,
                              color: colors.primary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.brand.isNotEmpty ? item.brand : item.itemName,
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13.5, color: colors.textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '₱${item.pricePerUnit.toStringAsFixed(2)} / ${item.unit}',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: colors.primary),
                      ),
                      const Spacer(),
                      SizedBox(
                        width: double.infinity,
                        height: 32,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isSelected
                                ? colors.subCardBg
                                : colors.primary,
                            foregroundColor: isSelected
                                ? colors.textSecondary
                                : Colors.white,
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: isSelected ? 0 : 1,
                          ),
                          onPressed: isSelected ? null : () => onSelect(item),
                          child: Text(
                            isSelected ? 'Selected' : 'Add',
                            style: const TextStyle(
                                fontSize: 12.5, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  bool _matchesStatusFilter(LaundryOrder order) {
    if (selectedStatus == 'All') return true;
    if (selectedStatus == 'Pending' || selectedStatus == 'Clothes Received') {
      return order.orderStatus == 'Pending' ||
          order.orderStatus == 'Clothes Received';
    }
    if (selectedStatus == 'Ready' || selectedStatus == 'Ready for Pickup') {
      return order.orderStatus == 'Ready' ||
          order.orderStatus == 'Ready for Pickup';
    }
    return order.orderStatus == selectedStatus;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.themeModeNotifier,
      builder: (context, currentMode, _) {
        final colors = ThemeController.of(context);
        final pageBg = colors.pageBg;
        final textDark = colors.textPrimary;
        final primaryBlue = colors.primary;

        Widget ordersContent = Scaffold(
          backgroundColor: pageBg,
          appBar: AppBar(
            backgroundColor: pageBg,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            automaticallyImplyLeading: false,
            leading: Navigator.canPop(context)
                ? IconButton(
                    icon: Icon(Icons.arrow_back_ios_new_rounded,
                        size: 19, color: textDark),
                    onPressed: () => Navigator.pop(context),
                  )
                : null,
            title: Text(
              'Orders',
              style: TextStyle(
                color: textDark,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                  onPressed: _showCreateOrderDialog,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text(
                    'New Order',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
          body: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                children: [
                  // Search Input
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                    child: TextField(
                      controller: _searchController,
                      style: TextStyle(color: textDark),
                      decoration: InputDecoration(
                        hintText: 'Search order ID, customer, or service...',
                        hintStyle: TextStyle(
                            color: colors.textMuted, fontSize: 13.5),
                        prefixIcon: Icon(Icons.search_rounded,
                            color: colors.textMuted, size: 21),
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_searchController.text.isNotEmpty)
                              IconButton(
                                icon: Icon(Icons.clear_rounded,
                                    color: colors.textMuted, size: 18),
                                splashRadius: 18,
                                onPressed: () =>
                                    setState(() {
                                      _searchController.clear();
                                      currentPage = 1;
                                    }),
                              ),
                            // Calendar Icon Button
                            Tooltip(
                              message: selectedDate == 'All Dates'
                                  ? 'Filter by date'
                                  : (selectedDate == 'Custom Date' &&
                                          selectedCustomDate != null
                                      ? _formatDateOnly(selectedCustomDate!)
                                      : selectedDate),
                              child: InkWell(
                                onTap: _showDateFilter,
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  margin: const EdgeInsets.only(left: 2, right: 3),
                                  padding: const EdgeInsets.all(7),
                                  decoration: BoxDecoration(
                                    color: selectedDate != 'All Dates'
                                        ? colors.primary
                                        : colors.primary.withValues(
                                            alpha: colors.isDark ? 0.22 : 0.10),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.calendar_today_rounded,
                                    size: 17,
                                    color: selectedDate != 'All Dates'
                                        ? Colors.white
                                        : colors.primary,
                                  ),
                                ),
                              ),
                            ),
                            // Filter Icon Button (PopupMenu)
                            PopupMenuButton<String>(
                              tooltip: selectedStatus == 'All'
                                  ? 'Filter by status'
                                  : 'Status: $selectedStatus',
                              offset: const Offset(0, 45),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(color: colors.border),
                              ),
                              color: colors.cardBg,
                              elevation: 6,
                              onSelected: (val) {
                                setState(() {
                                  selectedStatus = val;
                                  currentPage = 1;
                                });
                              },
                              itemBuilder: (context) {
                                final statusList = [
                                  'All',
                                  'Processing',
                                  'Ready',
                                  'Picked Up',
                                  'Pending',
                                ];
                                return statusList.map((status) {
                                  final isSelected = selectedStatus == status;
                                  return PopupMenuItem<String>(
                                    value: status,
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            status == 'All'
                                                ? 'All Orders'
                                                : status,
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: isSelected
                                                  ? FontWeight.bold
                                                  : FontWeight.w500,
                                              color: isSelected
                                                  ? colors.primary
                                                  : colors.textPrimary,
                                            ),
                                          ),
                                        ),
                                        if (isSelected)
                                          Icon(Icons.check_rounded,
                                              size: 18, color: colors.primary),
                                      ],
                                    ),
                                  );
                                }).toList();
                              },
                              child: Container(
                                margin:
                                    const EdgeInsets.only(left: 3, right: 8),
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  color: selectedStatus != 'All'
                                      ? colors.primary
                                      : colors.primary.withValues(
                                          alpha: colors.isDark ? 0.22 : 0.10),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.tune_rounded,
                                  size: 18,
                                  color: selectedStatus != 'All'
                                      ? Colors.white
                                      : colors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        filled: true,
                        fillColor: colors.inputFill,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: colors.inputBorder),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: colors.inputBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide:
                              BorderSide(color: primaryBlue, width: 1.5),
                        ),
                      ),
                      onChanged: (_) => setState(() {
                        currentPage = 1;
                      }),
                    ),
                  ),

                  // Active Filter Badges (if any filter is applied)
                  if (selectedStatus != 'All' || selectedDate != 'All Dates')
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: [
                                if (selectedStatus != 'All')
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 9, vertical: 3),
                                    decoration: BoxDecoration(
                                      color:
                                          colors.primary.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: colors.primary
                                            .withValues(alpha: 0.25),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'Status: $selectedStatus',
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.bold,
                                            color: colors.primary,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        InkWell(
                                          onTap: () {
                                            setState(() {
                                              selectedStatus = 'All';
                                              currentPage = 1;
                                            });
                                          },
                                          child: Icon(
                                            Icons.close_rounded,
                                            size: 14,
                                            color: colors.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                if (selectedDate != 'All Dates')
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 9, vertical: 3),
                                    decoration: BoxDecoration(
                                      color:
                                          colors.primary.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: colors.primary
                                            .withValues(alpha: 0.25),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'Date: ${selectedDate == 'Custom Date' && selectedCustomDate != null ? _formatDateOnly(selectedCustomDate!) : selectedDate}',
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.bold,
                                            color: colors.primary,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        InkWell(
                                          onTap: () {
                                            setState(() {
                                              selectedDate = 'All Dates';
                                              selectedCustomDate = null;
                                              currentPage = 1;
                                            });
                                          },
                                          child: Icon(
                                            Icons.close_rounded,
                                            size: 14,
                                            color: colors.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

              // Orders Stream List
              Expanded(
                child: StreamBuilder<List<LaundryOrder>>(
                  stream: _orderService.getOrders(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: CircularProgressIndicator(color: primaryBlue),
                      );
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            'Error loading orders:\n${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      );
                    }

                    final orders = snapshot.data ?? [];
                    if (orders.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.receipt_long_outlined,
                                size: 56, color: Colors.grey.shade300),
                            const SizedBox(height: 12),
                            Text(
                              'No orders created yet',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return StreamBuilder<List<Customer>>(
                      stream: _customerService.getCustomers(),
                      builder: (context, customerSnapshot) {
                        final customers = customerSnapshot.data ?? [];
                        return StreamBuilder<List<LaundryService>>(
                          stream: _serviceService.getServices(),
                          builder: (context, serviceSnapshot) {
                            final services = serviceSnapshot.data ?? [];
                            final searchQuery =
                                _searchController.text.trim().toLowerCase();

                            final filteredOrders = orders.where((order) {
                              if (!_matchesStatusFilter(order)) return false;
                              if (!_matchesDateFilter(order)) return false;

                              if (searchQuery.isEmpty) return true;

                              Customer? cust;
                              for (final c in customers) {
                                if (c.customerId == order.customerId) {
                                  cust = c;
                                  break;
                                }
                              }
                              LaundryService? serv;
                              for (final s in services) {
                                if (s.serviceId == order.serviceId) {
                                  serv = s;
                                  break;
                                }
                              }

                              final orderId = order.orderId.toLowerCase();
                              final custName =
                                  cust?.name.toLowerCase() ?? '';
                              final servName =
                                  serv?.serviceName.toLowerCase() ?? '';

                              return orderId.contains(searchQuery) ||
                                  custName.contains(searchQuery) ||
                                  servName.contains(searchQuery);
                            }).toList();

                            if (filteredOrders.isEmpty) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.filter_alt_off_outlined,
                                        size: 56,
                                        color: Colors.grey.shade300),
                                    const SizedBox(height: 12),
                                    Text(
                                      'No matching orders found',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade600,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Try changing your search or filters',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade400,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            final int totalPages = filteredOrders.isEmpty
                                ? 1
                                : (filteredOrders.length / ordersPerPage).ceil();

                            final int effectivePage =
                                currentPage > totalPages ? totalPages : currentPage;

                            final int startIndex =
                                (effectivePage - 1) * ordersPerPage;

                            final int endIndex = (startIndex + ordersPerPage)
                                .clamp(0, filteredOrders.length);

                            final paginatedOrders = filteredOrders.sublist(
                              startIndex,
                              endIndex,
                            );

                            return Column(
                              children: [
                                Expanded(
                                  child: ListView.builder(
                                    padding: EdgeInsets.fromLTRB(
                                        16, 0, 16, totalPages > 1 ? 16 : 80),
                                    itemCount: paginatedOrders.length,
                                    itemBuilder: (context, index) {
                                      final order = paginatedOrders[index];

                                Customer? customer;
                                for (final c in customers) {
                                  if (c.customerId == order.customerId) {
                                    customer = c;
                                    break;
                                  }
                                }
                                LaundryService? service;
                                for (final s in services) {
                                  if (s.serviceId == order.serviceId) {
                                    service = s;
                                    break;
                                  }
                                }

                                final shortId = order.orderId.length > 6
                                    ? order.orderId.substring(0, 6)
                                    : order.orderId;

                                DateTime displayDate =
                                    order.orderDate ?? DateTime.now();
                                if (order.orderStatus == 'Processing' &&
                                    order.processingDate != null) {
                                  displayDate = order.processingDate!;
                                } else if (order.orderStatus ==
                                        'Ready for Pickup' &&
                                    order.readyDate != null) {
                                  displayDate = order.readyDate!;
                                } else if (order.orderStatus == 'Picked Up' &&
                                    order.pickedUpDate != null) {
                                  displayDate = order.pickedUpDate!;
                                }

                                final displayStatus =
                                    _getDisplayStatus(order.orderStatus);
                                final badgeBg =
                                    _getStatusBgColor(order.orderStatus);
                                final badgeText =
                                    _getStatusTextColor(order.orderStatus);
                                final iconBg =
                                    _getStatusIconBgColor(order.orderStatus);
                                final iconColor =
                                    _getStatusIconColor(order.orderStatus);

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    color: colors.cardBg,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                        color: colors.border),
                                    boxShadow: [
                                      BoxShadow(
                                        color: colors.isDark
                                            ? Colors.black.withValues(alpha: 0.25)
                                            : Colors.black.withValues(alpha: 0.03),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(16),
                                    onTap: () => _showOrderDetails(
                                        order, customer, service),
                                    child: Padding(
                                      padding: const EdgeInsets.all(14),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          // Left Icon Box
                                          Container(
                                            width: 48,
                                            height: 48,
                                            decoration: BoxDecoration(
                                              color: iconBg,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Center(
                                              child: Icon(
                                                Icons.inventory_2_outlined,
                                                color: iconColor,
                                                size: 24,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),

                                          // Center details
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '#$shortId',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                    color: textDark,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  customer?.name ??
                                                      'Customer not found',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 13.5,
                                                    color: textDark,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  _formatDateTime(displayDate),
                                                  style: TextStyle(
                                                    fontSize: 11.5,
                                                    color: colors.textMuted,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  '${service?.serviceName ?? 'Service'} • ${order.weight} kg',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: colors.textSecondary,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),

                                          const SizedBox(width: 8),

                                          // Right column: Badge & Price
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                              children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 10,
                                                        vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: badgeBg,
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  displayStatus,
                                                  style: TextStyle(
                                                    color: badgeText,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                '₱${order.totalAmount.toStringAsFixed(2)}',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15,
                                                  color: textDark,
                                                ),
                                              ),
                                            ],
                                          ),

                                          const SizedBox(width: 4),
                                          Icon(
                                            Icons.chevron_right_rounded,
                                            size: 20,
                                            color: colors.textMuted,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                              ),
                            ),
                            if (totalPages > 1)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: colors.cardBg,
                                  border: Border(
                                    top: BorderSide(
                                        color: colors.border, width: 1),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    IconButton(
                                      onPressed: effectivePage > 1
                                          ? () {
                                              setState(() {
                                                currentPage = effectivePage - 1;
                                              });
                                            }
                                          : null,
                                      icon: const Icon(
                                          Icons.chevron_left_rounded),
                                      color: primaryBlue,
                                      disabledColor: colors.textMuted,
                                    ),
                                    const SizedBox(width: 10),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: colors.subCardBg,
                                        borderRadius:
                                            BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        'Page $effectivePage of $totalPages',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: textDark,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    IconButton(
                                      onPressed: effectivePage < totalPages
                                          ? () {
                                              setState(() {
                                                currentPage = effectivePage + 1;
                                              });
                                            }
                                          : null,
                                      icon: const Icon(
                                          Icons.chevron_right_rounded),
                                      color: primaryBlue,
                                      disabledColor: colors.textMuted,
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),

      // Main Action Button at the bottom
      //: FloatingActionButton.extended(
       // backgroundColor: primaryBlue,
      //  foregroundColor: Colors.white,
      //  elevation: 3,
      //  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      //  onPressed: _showCreateOrderDialog,
      //  icon: const Icon(Icons.add_rounded),
      //  label: const Text(
      //    'Create Order',
      //    style: TextStyle(fontWeight: FontWeight.bold),
      //  ),
      //),

      // Bottom Navigation Bar matching other screens and screenshot
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: colors.cardBg,
          border: Border(
            top: BorderSide(color: colors.border, width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: 1, // Orders tab
          onTap: (index) {
            if (index == 1) return;
            if (index == 0) {
              if (Navigator.canPop(context)) {
                Navigator.popUntil(context, (route) => route.isFirst);
              } else {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const DashboardPage()),
                );
              }
            } else if (index == 2) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const InventoryPage()),
              );
            } else if (index == 3) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (_) => const InventoryTransactionsPage()),
              );
            } else if (index == 4) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const MorePage()),
              );
            }
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: colors.cardBg,
          selectedItemColor: colors.primary,
          unselectedItemColor: colors.textSecondary,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 11,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.normal,
            fontSize: 11,
          ),
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_rounded),
              label: 'Orders',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.inventory_2_outlined),
              label: 'Inventory',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.swap_horiz_rounded),
              label: 'Transactions',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.menu_rounded),
              label: 'More',
            ),
          ],
        ),
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (kIsWeb || constraints.maxWidth > 500) {
          return Container(
            color: colors.pageBg,
            child: Center(
              child: ConstrainedBox(
                constraints:
                    const BoxConstraints(maxWidth: 440, maxHeight: 920),
                child: Container(
                  decoration: BoxDecoration(
                    color: colors.pageBg,
                    borderRadius: BorderRadius.circular(kIsWeb ? 20 : 0),
                    boxShadow: [
                      if (kIsWeb)
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: ordersContent,
                ),
              ),
            ),
          );
        }
        return ordersContent;
      },
    );
  },
);
  }
}