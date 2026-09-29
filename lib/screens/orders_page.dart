import 'package:flutter/material.dart';

import '../models/customer.dart';
import '../models/inventory.dart';
import '../models/service.dart';
import '../models/order.dart';
import '../services/customer_service.dart';
import '../services/inventory_service.dart';
import '../services/order_service.dart';
import '../services/service_service.dart';
import '../services/notification_service.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

  

class _OrdersPageState extends State<OrdersPage> {
  final CustomerService _customerService = CustomerService();
  final ServiceService _serviceService = ServiceService();
  final OrderService _orderService = OrderService();
  final InventoryService _inventoryService = InventoryService();
  final NotificationService _notificationService = 
      NotificationService();  

  final TextEditingController _weightController =
    TextEditingController();

  final TextEditingController _cashReceivedController =
      TextEditingController();

  final TextEditingController _notesController =
      TextEditingController();

  final TextEditingController _plasticQtyController = 
      TextEditingController();

  final TextEditingController _searchController = 
      TextEditingController();

  String selectedStatus = 'All';
  String selectedDate = 'All Dates';
  DateTime? selectedCustomDate;

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
      final double? weight = double.tryParse(
        _weightController.text.trim(),
      );

      if (_selectedService == null ||
          weight == null ||
          weight <= 0) {
        setState(() {
          _packageCount = 0;
          _serviceTotal = 0;
        });
        return;
      }

      final int packages =
          (weight / _selectedService!.maxWeight).ceil();

      final double serviceTotal =
          packages * _selectedService!.bundlePrice;

      setState(() {
        _packageCount = packages;
        _serviceTotal = serviceTotal;
      });
    }

    double _calculateGrandTotal() {
      return _serviceTotal +
          _detergentFee +
          _conditionerFee;
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

    final double? weight = double.tryParse(
      _weightController.text.trim(),
    );

    if (weight == null || weight <= 0) {
      _showMessage('Please enter a valid weight.');
      return;
    }

    if (_packageCount == 0) {
      _showMessage(
        'Please select a service and calculate the price.',
      );
      return;
    }

    final double totalAmount = _calculateGrandTotal();

    final double? cashReceived = double.tryParse(
      _cashReceivedController.text.trim(),
    );

    if (cashReceived == null || cashReceived <= 0) {
      _showMessage(
        'Please enter the cash received.',
      );
      return;
    }

    if (cashReceived < totalAmount) {
      _showMessage(
        'Cash received is not enough. '
        'Required: ₱${totalAmount.toStringAsFixed(2)}',
      );
      return;
    }

    final double changeAmount =
        cashReceived - totalAmount;

    try {
      await _orderService.createPaidOrder(
        customerId: _selectedCustomerId!,
        serviceId: _selectedServiceId!,

        weight: weight,
        packageCount: _packageCount,

        detergentOption:
            _selectedDetergent == null
                ? 'none'
                : 'inventory',
        detergentBrand:
            _selectedDetergent?.brand ?? '',
        detergentInventoryId:
            _selectedDetergent?.inventoryId,
        detergentQty: _detergentQty,
        detergentFee: _detergentFee,

        conditionerOption:
            _selectedConditioner == null
                ? 'none'
                : 'inventory',
        conditionerBrand:
            _selectedConditioner?.brand ?? '',
        conditionerInventoryId:
            _selectedConditioner?.inventoryId,
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
        'Order created and payment received! '
        'Change: ₱${changeAmount.toStringAsFixed(2)}',
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Error creating order: $e',
      );
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  } 

  bool _matchesDateFilter(LaundryOrder order) {
    if (selectedDate == 'All Dates') {
      return true;
    }

    DateTime? relevantDate;

    switch (order.orderStatus) {
      case 'Clothes Received':
        relevantDate = order.orderDate;
        break;

      case 'Processing':
        relevantDate = order.processingDate;
        break;

      case 'Ready for Pickup':
        relevantDate = order.readyDate;
        break;

      case 'Picked Up':
        relevantDate = order.pickedUpDate;
        break;

      default:
        relevantDate = order.orderDate;
    }

    if (relevantDate == null) {
      return false;
    }

    final orderDate = relevantDate;
    final now = DateTime.now();

    final today = DateTime(
      now.year,
      now.month,
      now.day,
    );

    final orderDay = DateTime(
      orderDate.year,
      orderDate.month,
      orderDate.day,
    );

    if (selectedDate == 'Today') {
      return orderDay == today;
    }

    if (selectedDate == 'Yesterday') {
      final yesterday = today.subtract(
        const Duration(days: 1),
      );

      return orderDay == yesterday;
    }

    if (selectedDate == 'This Week') {
      final startOfWeek = today.subtract(
        Duration(days: today.weekday - 1),
      );

      final endOfWeek = startOfWeek.add(
        const Duration(days: 7),
      );

      return !orderDay.isBefore(startOfWeek) &&
          orderDay.isBefore(endOfWeek);
    }

    if (selectedDate == 'This Month') {
      return orderDay.year == today.year &&
          orderDay.month == today.month;
    }

    if (selectedDate == 'Custom Date' &&
        selectedCustomDate != null) {
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

      _showMessage(
        'Order ${order.orderId.substring(0, 6)} is now Processing.',
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Error starting order: $e',
      );
    }
  } 

  Future<void> _sendReadyForPickupNotification(
      LaundryOrder order,
      Customer? customer,
      LaundryService? service,
    ) async {
      if (customer == null) {
        _showMessage('Customer information could not be found.');
        return;
      }

      if (customer.email.trim().isEmpty) {
        _showMessage(
          'This customer does not have an email address.',
        );
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

        _showMessage(
          'Ready for Pickup notification sent to ${customer.email}.',
        );
      } catch (e) {
        if (!mounted) return;

        _showMessage(
          e.toString().replaceFirst('Exception: ', ''),
        );
      }
    }

  Future<void> _markPickedUp(LaundryOrder order) async {
    try { 
      await _orderService.markPickedUp(order.orderId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order marked as picked up.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text ('Failed to mark order as picked up: $e'),
        ),
      );
    }
  }

  

  Future<void> _confirmPickedUp(LaundryOrder order) async {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Mark as Picked Up?'),
            content: const Text(
              'Are you sure this order has been picked up by the customer?',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context, false);
                },
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context, true);
                },
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

  void _showDateFilter() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Filter by Date'),
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

  void _showOrderDetails(
      LaundryOrder order,
      Customer? customer,
      LaundryService? service,
    )
    {

      showDialog(
        context: context, 
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Order Details'),
            content: SizedBox(
              width: 450,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order #${order.orderId.substring(0,6)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 16),

                    const Text(
                      'Customer',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),

                    Text(
                      customer?.name ?? 'Customer not found',
                    ),

                    if (customer?.phone.isNotEmpty == true)
                      Text('Phone: ${customer!.phone}'),

                    if (customer?.email.isNotEmpty == true)
                      Text('Email: ${customer!.email}'),

                    const SizedBox (height: 16),

                    const Text(
                      'Laundry',
                      style: TextStyle(
                        fontWeight: FontWeight.bold, 
                        fontSize: 16
                        ),
                    ),
                    const SizedBox(height: 4),

                    Text('Service: ${service?.serviceName ?? 'Service not found'}',
                    ),
                    Text('Weight: ${order.weight} kg'),
                    Text('Packages: ${order.packageCount}'),

                    const SizedBox(height: 16),

                    const Text(
                      'Add-ons',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16
                        ),
                      ),
                      const SizedBox(height: 4),

                      if (order.detergentQty > 0)
                        Text (
                          'Detergent: ${order.detergentBrand} x ${order.detergentQty}',
                        )
                      else 
                      const Text('Detergent: None'),

                      if(order.conditionerQty > 0)
                        Text (
                          'Fabric Conditioner: ' 
                          '${order.conditionerBrand} x' 
                          '${order.conditionerQty}',
                        )
                      else 
                        const Text ('Fabric Conditioner: None'),

                      const SizedBox(height: 16),

                      const Text(
                        'Payment', 
                        style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16
                        ),
                      ),
                      const SizedBox(height: 16),

                      Text(
                        'Total: ₱${order.totalAmount.toStringAsFixed(2)}',
                      ),
                      Text(
                        'Payment Method: Cash',
                      ),
                      Text(
                        'Payment Status: ${order.paymentStatus}',
                      ),

                      const SizedBox(height: 16),

                      const Text(
                      'Order Status',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      'Status: ${order.orderStatus}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    if (order.orderStatus == 'Processing') ...[
                      const SizedBox(height: 16),

                      const Text(
                        'Plastic Packaging',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),

                      const SizedBox(height: 8),

                      StreamBuilder<List<InventoryItem>>(
                        stream: _inventoryService.getPlasticBags(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const LinearProgressIndicator();
                          }

                          final plasticItems = snapshot.data ?? [];

                          if (plasticItems.isEmpty) {
                            return const Text(
                              'No plastic packaging available in inventory.',
                            );
                          }

                          final plasticItem = plasticItems.first;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.blueGrey,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      plasticItem.itemName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),

                                    Text(
                                      'Brand: ${plasticItem.brand}',
                                    ),

                                    Text(
                                      'Size: ${plasticItem.size}',
                                    ),

                                    Text(
                                      'Available: '
                                      '${plasticItem.quantity} '
                                      '${plasticItem.unit}',
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 12),

                              TextField(
                                controller: _plasticQtyController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                  decimal: false,
                                ),
                                decoration: InputDecoration(
                                  labelText: 'Quantity Used',
                                  suffixText: plasticItem.unit,
                                  border: const OutlineInputBorder(),
                                ),
                              ),

                              const SizedBox(height: 12),

                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    final quantity = int.tryParse(
                                      _plasticQtyController.text.trim(),
                                    );

                                    if (quantity == null || quantity <= 0) {
                                      _showMessage(
                                        'Please enter a valid plastic quantity.',
                                      );
                                      return;
                                    }

                                    final plasticItem = plasticItems.first;

                                    try {
                                        await _orderService.markReadyForPickup(
                                          order: order,
                                          plasticInventoryId: plasticItem.inventoryId,
                                          plasticQuantity: quantity,
                                        );

                                        if (!dialogContext.mounted) return;

                                        _plasticQtyController.clear();

                                        Navigator.pop(dialogContext);

                                        _showMessage(
                                          'Order marked Ready for Pickup. '
                                          'Plastic inventory deducted.',
                                        );
                                      } catch (e) {
                                      if (!mounted) return;

                                      _showMessage(
                                        e.toString().replaceFirst('Exception: ', ''),
                                      );
                                    }
                                  },
                                  icon: const Icon(
                                    Icons.check_circle_outline,
                                  ),
                                  label: const Text(
                                    'Ready for Pickup',
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],

                      if (order.notes.isNotEmpty)... [
                        const SizedBox(height: 16),
                        const Text(
                          'Notes',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16
                            ),
                        ),
                        const SizedBox(height: 4),
                        Text(order.notes),
                      ],
                  ],
                ),
              ),
            ),

            actions: [
              if (order.orderStatus == 'Clothes Received')
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.pop(dialogContext);
                      await _startProcessing(order);
                    },
                    icon: const Icon(Icons.local_laundry_service),
                    label: const Text('Start Processing'),
                  ),
                ),

              if (order.orderStatus == 'Ready for Pickup') ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.pop(dialogContext);
                      await _sendReadyForPickupNotification(
                        order,
                        customer,
                        service,
                      );
                    },
                    icon: const Icon(Icons.email_outlined),
                    label: const Text('Notify Customer'),
                  ),
                ),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.pop(dialogContext);
                      await _confirmPickedUp(order);
                    },
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Mark as Picked Up'),
                  ),
                ),
              ],

              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                },
                child: const Text('Close'),
              ),
            ],
          );
        },
      );
    }

  
  Widget _dateFilterOption(
    BuildContext dialogContext,
    String option,
  ) {
    return ListTile(
      title: Text(option),
      trailing: selectedDate == option
          ? const Icon(Icons.check)
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
            });
          }

          return;
        }

        setState(() {
          selectedDate = option;
          selectedCustomDate = null;
        });

        Navigator.pop(dialogContext);
      },
    );
  }
  
  void _showCreateOrderDialog() {
    _clearForm();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Create Order'),
              content: SizedBox(
                width: 450,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      StreamBuilder<List<Customer>>(
                        stream: _customerService.getCustomers(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const LinearProgressIndicator();
                          }

                          final customers =
                              snapshot.data ?? [];

                          return DropdownButtonFormField<String>(
                            isExpanded: true,
                            initialValue: _selectedCustomerId,
                            decoration: const InputDecoration(
                              labelText: 'Customer',
                              border: OutlineInputBorder(),
                            ),
                            items: customers.map(
                              (customer) {
                                return DropdownMenuItem<String>(
                                  value: customer.customerId,
                                  child: Text(
                                    customer.name,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              },
                            ).toList(),
                            onChanged: (value) {
                              setDialogState(() {
                                _selectedCustomerId = value;
                              });
                            },
                          );
                        },
                      ),

                      const SizedBox(height: 12),

                      StreamBuilder<List<LaundryService>>(
                        stream: _serviceService.getServices(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const LinearProgressIndicator();
                          }

                          final services =
                              snapshot.data
                                      ?.where(
                                        (service) =>
                                            service.status ==
                                            'Active',
                                      )
                                      .toList() ??
                                  [];

                          return DropdownButtonFormField<String>(
                            isExpanded: true,
                            initialValue: _selectedServiceId,
                            decoration: const InputDecoration(
                              labelText: 'Service',
                              border: OutlineInputBorder(),
                            ),
                            items: services.map(
                              (service) {
                                return DropdownMenuItem<String>(
                                  value: service.serviceId,
                                  child: Text(
                                    '${service.serviceName} - ₱${service.bundlePrice.toStringAsFixed(2)}',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              },
                            ).toList(),
                            onChanged: (value) {
                              if (value == null) return;

                              final LaundryService selectedService = services.firstWhere(
                                (service) => service.serviceId == value,
                              );

                              setDialogState(() {
                                _selectedServiceId = value;
                                _selectedService = selectedService;
                              });

                              _calculatePrice();
                            },
                          );
                        },
                      ),

                      const SizedBox(height: 12),

                      TextField(
                        controller: _weightController,
                        keyboardType:
                            const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Weight (kg)',
                          border: OutlineInputBorder(),
                          suffixText: 'kg',
                        ),
                        onChanged: (_) {
                          _calculatePrice();
                          setDialogState(() {});
                        },
                      ),

                      const SizedBox(height: 12),

                      if (_packageCount > 0)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.blueGrey,
                            ),
                            borderRadius:
                                BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Packages: $_packageCount',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Service Total: ₱${_serviceTotal.toStringAsFixed(2)}',
                              ),
                            ],
                          ),
                        ),
                      

                      const SizedBox(height: 16),

                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Add-ons',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      // ADD DETERGENT BUTTON
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            setDialogState(() {
                              _showDetergents = !_showDetergents;
                            });
                          },
                          icon: Icon(
                            _showDetergents
                                ? Icons.keyboard_arrow_up
                                : Icons.add,
                          ),
                          label: Text(
                            _showDetergents
                                ? 'Hide Detergents'
                                : 'Add Detergent',
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
                            if (_detergentQty <
                                _selectedDetergent!.quantity) {
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

                      // ADD FABRIC CONDITIONER BUTTON
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            setDialogState(() {
                              _showConditioners = !_showConditioners;
                            });
                          },
                          icon: Icon(
                            _showConditioners
                                ? Icons.keyboard_arrow_up
                                : Icons.add,
                          ),
                          label: Text(
                            _showConditioners
                                ? 'Hide Fabric Conditioners'
                                : 'Add Fabric Conditioner',
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
                              _conditionerQty = 1;
                              _conditionerFee = item.pricePerUnit;
                              _showConditioners = false;
                            });
                          },
                        ),
                      ],


                      const SizedBox(height: 16),

                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Cash Payment',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      TextField(
                        controller: _cashReceivedController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Cash Received',
                          prefixText: '₱ ',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (_) {
                          setDialogState(() {});
                        },
                      ),

                      const SizedBox(height: 8),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.blueGrey,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Change',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              () {
                                final cash = double.tryParse(
                                  _cashReceivedController.text.trim(),
                                );

                                final total = _calculateGrandTotal();

                                if (cash == null || cash < total) {
                                  return '₱0.00';
                                }

                                return '₱${(cash - total).toStringAsFixed(2)}';
                              }(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.blueGrey,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Service: ₱${_serviceTotal.toStringAsFixed(2)}',
                            ),
                            Text(
                              'Detergent: ₱${_detergentFee.toStringAsFixed(2)}',
                            ),
                            Text(
                              'Fabric Conditioner: '
                              '₱${_conditionerFee.toStringAsFixed(2)}',
                            ),
                            const Divider(),
                            Text(
                              'Total: ₱${_calculateGrandTotal().toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 17,
                              ),
                            ),
                          ],
                        ),
                      ),

                              const SizedBox(height: 12),

                            TextField(
                              controller: _notesController,
                              maxLines: 3,
                              decoration: const InputDecoration(
                                labelText: 'Notes',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(dialogContext);
                        },
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton.icon(
                        onPressed: () async {
                          await _saveOrder();
                        },
                        icon: const Icon(Icons.payment),
                        label: const Text('Pay & Create Order'),
                      ),
                    ],
                  );
                },
              );
            },
          );
          
  
        }

      
    @override

    Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Orders'),
        ),
        body: Column (
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16,16,16,8),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search customer, order ID, or service',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty ? 
                                IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                      setState(() {
                                        _searchController.clear();
                                      });
                                  },
                                )
                                : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (_) {
                  setState(() {});
                },
              ),
            ),
            

            // Status Filter
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _statusFilterButton('All'),
                    _statusFilterButton('Clothes Received'),
                    _statusFilterButton('Processing'),
                    _statusFilterButton('Ready for Pickup'),
                    _statusFilterButton('Picked Up'),

                  ],
                ),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: _showDateFilter,
                  icon: const Icon(Icons.calendar_today),
                  label: Text(
                    selectedDate == 'Custom Date' && selectedCustomDate != null
                        ? '📅 ${selectedCustomDate!.month}/'
                          '${selectedCustomDate!.day}/'
                          '${selectedCustomDate!.year}'
                        : '📅 $selectedDate',
                  ),
                ),
              ),
            ),

            Expanded(
              child: StreamBuilder(
                stream: _orderService.getOrders(),
        
        
          builder: (context, snapshot) {
            if (snapshot.connectionState ==
                ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error loading orders:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              );
            }

            final orders = snapshot.data ?? [];

            if (orders.isEmpty) {
              return const Center(
                child: Text(
                  'No orders found.',
                  style: TextStyle(fontSize: 16),
                ),
              );
            }

            return StreamBuilder<List<Customer>>(
  stream: _customerService.getCustomers(),
  builder: (context, customerSnapshot) {
    if (customerSnapshot.connectionState ==
        ConnectionState.waiting) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    final customers = customerSnapshot.data ?? [];

    return StreamBuilder<List<LaundryService>>(
      stream: _serviceService.getServices(),
      builder: (context, serviceSnapshot) {
        if (serviceSnapshot.connectionState ==
            ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final services = serviceSnapshot.data ?? [];

        final searchQuery =
            _searchController.text.trim().toLowerCase();

        final filteredOrders = orders.where((order) {
        final matchesStatus =
            selectedStatus == 'All' ||
            order.orderStatus == selectedStatus;

        if (!matchesStatus) {
          return false;
        }

        final matchesDate = _matchesDateFilter(order);

        if (!matchesDate) {
          return false;
        }

        if (searchQuery.isEmpty) {
          return true;
        }

          Customer? customer;
          for (final item in customers) {
            if (item.customerId == order.customerId) {
              customer = item;
              break;
            }
          }

          LaundryService? service;
          for (final item in services) {
            if (item.serviceId == order.serviceId) {
              service = item;
              break;
            }
          }

          final orderId = order.orderId.toLowerCase();

          final customerName = customer?.name.toLowerCase() ?? '';

          final serviceName = service?.serviceName.toLowerCase() ?? '';

          return orderId.contains(searchQuery) ||
            customerName.contains(searchQuery) ||
            serviceName.contains(searchQuery);
        }).toList();

        if (filteredOrders.isEmpty) {
          return const Center(
            child: Text(
              'No matching orders. \n'
              'Try changing your search or status filter.',
              textAlign : TextAlign.center,
            ));
        }


        return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredOrders.length,
            itemBuilder: (context, index) {
              final order = filteredOrders[index];

              Customer? customer;

              for (final item in customers) {
                if (item.customerId == order.customerId) {
                  customer = item;
                  break;
                }
              }

              LaundryService? service;

              for (final item in services) {
                if (item.serviceId == order.serviceId) {
                  service = item;
                  break;
                }
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    _showOrderDetails(
                      order,
                      customer,
                      service,
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Order ${order.orderId.substring(0, 6)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              order.orderStatus,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        Row(
                          children: [
                            const Icon(
                              Icons.person_outline,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                customer?.name ??
                                    'Customer not found',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 4),

                        Text(
                          '${service?.serviceName ?? 'Service not found'}'
                          ' • ${order.weight} kg'
                          ' • ${order.packageCount} package(s)',
                        ),

                        const SizedBox(height: 4),

                        Text(
                          'Total: ₱${order.totalAmount.toStringAsFixed(2)}',
                        ),

                        const SizedBox(height: 4),

                        Row(
                          children: [
                            if (order.paymentStatus == 'Paid') ...[
                              const Icon(
                                Icons.check_circle,
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                            ],
                            Text(
                              'Payment: ${order.paymentStatus}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        if (order.orderStatus ==
                            'Clothes Received' &&
                            order.paymentStatus == 'Paid')
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () =>
                                  _startProcessing(order),
                              icon: const Icon(
                                Icons.local_laundry_service,
                              ),
                              label: const Text(
                                'Start Processing',
                              ),
                            ),
                          ),

                        if (order.orderStatus ==
                            'Processing')
                          const Row(
                            children: [
                              Icon(
                                Icons.sync,
                                size: 18,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Processing',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),

                        const SizedBox(height: 6),

                        const Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            'Tap to view details →',
                            style: TextStyle(
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
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
      floatingActionButton: FloatingActionButton.extended(
          onPressed: _showCreateOrderDialog,
          icon: const Icon(Icons.add),
          label: const Text('Create Order'),
        ),
      );
    }

    Widget _statusFilterButton (String status) {
      final bool isSelected = selectedStatus == status;

      return Padding (
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          label: Text(status),
          selected : isSelected,
          onSelected: (_) {
            setState(() {
              selectedStatus = status;
            });
          }
        )
      );
    }


    Widget _buildSelectedAddonCard({
      required InventoryItem item,
      required int quantity,
      required double fee,
      required VoidCallback onMinus,
      required VoidCallback onPlus,
      required VoidCallback onRemove,
    }) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.blueGrey,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            if (item.imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.network(
                  item.imageUrl,
                  width: 55,
                  height: 55,
                  fit: BoxFit.cover,
                  errorBuilder: (
                    context,
                    error,
                    stackTrace,
                  ) {
                    return const SizedBox(
                      width: 55,
                      height: 55,
                      child: Icon(
                        Icons.inventory_2,
                        size: 40,
                      ),
                    );
                  },
                ),
              )
            else
              const SizedBox(
                width: 55,
                height: 55,
                child: Icon(
                  Icons.inventory_2,
                  size: 40,
                ),
              ),

            const SizedBox(width: 10),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    item.brand.isNotEmpty
                        ? item.brand
                        : item.itemName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  Text(
                    item.scent.isNotEmpty
                        ? item.scent
                        : item.size,
                  ),

                  Text(
                    '₱${item.pricePerUnit.toStringAsFixed(2)} / ${item.unit}',
                  ),

                  Row(
                    children: [
                      IconButton(
                        onPressed:
                            quantity > 1 ? onMinus : null,
                        icon: const Icon(
                          Icons.remove_circle_outline,
                        ),
                        padding: EdgeInsets.zero,
                        constraints:
                            const BoxConstraints(),
                      ),

                      Padding(
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 12,
                        ),
                        child: Text(
                          '$quantity',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      IconButton(
                        onPressed:
                            quantity < item.quantity
                                ? onPlus
                                : null,
                        icon: const Icon(
                          Icons.add_circle_outline,
                        ),
                        padding: EdgeInsets.zero,
                        constraints:
                            const BoxConstraints(),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Column(
              children: [
                Text(
                  '₱${fee.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: onRemove,
                  child: const Text('Remove'),
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
      return StreamBuilder<List<InventoryItem>>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Text(
              'Error loading products: ${snapshot.error}',
            );
          }

          final items = (snapshot.data ?? [])
              .where((item) => item.quantity > 0)
              .toList();

          if (items.isEmpty) {
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: const Text(
                'No available items in inventory.',
                textAlign: TextAlign.center,
              ),
            );
          }

          return Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              GridView.builder(
                shrinkWrap: true,
                physics:
                    const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 0.72,
                ),
                itemBuilder: (context, index) {
                  final item = items[index];

                  return Card(
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => onSelect(item),
                      child: Padding(
                        padding:
                            const EdgeInsets.all(8),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: SizedBox(
                                width: double.infinity,
                                child: item.imageUrl
                                        .isNotEmpty
                                    ? Image.network(
                                        item.imageUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (
                                          context,
                                          error,
                                          stackTrace,
                                        ) {
                                          return const Center(
                                            child: Icon(
                                              Icons.inventory_2,
                                              size: 45,
                                            ),
                                          );
                                        },
                                      )
                                    : const Center(
                                        child: Icon(
                                          Icons.inventory_2,
                                          size: 45,
                                        ),
                                      ),
                              ),
                            ),

                            const SizedBox(height: 6),

                            Text(
                              item.brand.isNotEmpty
                                  ? item.brand
                                  : item.itemName,
                              style:
                                  const TextStyle(
                                fontWeight:
                                    FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow:
                                  TextOverflow.ellipsis,
                            ),

                            Text(
                              item.scent.isNotEmpty
                                  ? item.scent
                                  : item.size,
                              maxLines: 1,
                              overflow:
                                  TextOverflow.ellipsis,
                            ),

                            Text(
                              '₱${item.pricePerUnit.toStringAsFixed(2)} / ${item.unit}',
                              style:
                                  const TextStyle(
                                fontWeight:
                                    FontWeight.w500,
                              ),
                            ),

                            const SizedBox(height: 4),

                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed:
                                    selectedItem
                                                ?.inventoryId ==
                                            item.inventoryId
                                        ? null
                                        : () =>
                                            onSelect(item),
                                child:
                                    const Text('Add'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          );
        },
      );
    }
  }