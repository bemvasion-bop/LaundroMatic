import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../controllers/theme_controller.dart';
import '../models/order.dart';
import '../services/auth_service.dart';
import '../services/order_service.dart';
import '../utils/ai_report_generator.dart';
import '../utils/file_download_helper.dart';
import 'customer_page.dart';
import 'dashboard_page.dart';
import 'inventory_page.dart';
import 'inventory_transactions_page.dart';
import 'login_page.dart';
import 'orders_page.dart';
import 'services_page.dart';

class MorePage extends StatefulWidget {
  const MorePage({super.key});

  @override
  State<MorePage> createState() => _MorePageState();
}

class _MorePageState extends State<MorePage> {
  final OrderService _orderService = OrderService();

  Future<void> _confirmLogout() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(Icons.logout_rounded, color: Colors.red, size: 24),
              SizedBox(width: 8),
              Text(
                'Log Out',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          content: const Text(
            'Are you sure you want to log out of LaundroMatic?',
            style: TextStyle(fontSize: 14, color: Color(0xFF475569)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel',
                  style: TextStyle(color: Color(0xFF64748B))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text(
                'Log Out',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        await AuthService.signOut();
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error logging out: $e')),
        );
      }
    }
  }

  void _showPaymentsSheet() {
    int paymentCurrentPage = 1;
    const int paymentsPerPage = 15;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final colors = ThemeController.of(context);
        final isDark = colors.isDark;

        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85,
                maxWidth: 440,
              ),
              decoration: BoxDecoration(
                color: colors.cardBg,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  // Sheet Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.payments_rounded,
                                color: colors.primary, size: 22),
                            const SizedBox(width: 8),
                            Text(
                              'Payments History',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: colors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: Icon(Icons.close_rounded,
                              color: colors.textMuted),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: colors.border),

                  // Stream of Paid Orders
                  Expanded(
                    child: StreamBuilder<List<LaundryOrder>>(
                      stream: _orderService.getOrders(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(
                            child: CircularProgressIndicator(
                                color: colors.primary),
                          );
                        }

                        final orders = snapshot.data ?? [];
                        final paidOrders = orders
                            .where((o) => o.paymentStatus == 'Paid')
                            .toList();

                        double totalCollected = 0;
                        for (final o in paidOrders) {
                          totalCollected += o.totalAmount;
                        }

                        final int totalPages = paidOrders.isEmpty
                            ? 1
                            : (paidOrders.length / paymentsPerPage).ceil();

                        final int effectivePage = paymentCurrentPage > totalPages
                            ? totalPages
                            : (paymentCurrentPage < 1 ? 1 : paymentCurrentPage);

                        final int startIndex =
                            (effectivePage - 1) * paymentsPerPage;
                        final int endIndex = (startIndex + paymentsPerPage)
                            .clamp(0, paidOrders.length);

                        final paginatedPaidOrders = paidOrders.isEmpty
                            ? <LaundryOrder>[]
                            : paidOrders.sublist(startIndex, endIndex);

                        return Column(
                          children: [
                            Expanded(
                              child: ListView(
                                padding: const EdgeInsets.all(16),
                                children: [
                                  // Summary Banner
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          colors.primary,
                                          const Color(0xFF3B82F6)
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: colors.primary
                                              .withValues(alpha: 0.25),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Total Revenue Collected',
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '₱${totalCollected.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 26,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 3),
                                              decoration: BoxDecoration(
                                                color: Colors.white
                                                    .withValues(alpha: 0.2),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                '${paidOrders.length} Paid Orders',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            const Text(
                                              '100% Cash Settlement',
                                              style: TextStyle(
                                                color: Colors.white70,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 20),

                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Recent Settlements',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: colors.textPrimary,
                                        ),
                                      ),
                                      if (paidOrders.isNotEmpty)
                                        Text(
                                          '${startIndex + 1}-$endIndex of ${paidOrders.length}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: colors.textMuted,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),

                                  if (paidOrders.isEmpty)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 40),
                                      child: Center(
                                        child: Text(
                                          'No payment records found.',
                                          style: TextStyle(
                                            color: colors.textMuted,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    )
                                  else
                                    ...paginatedPaidOrders.map(
                                      (order) {
                                        final shortId = order.orderId.length > 6
                                            ? order.orderId.substring(0, 6)
                                            : order.orderId;
                                        return Container(
                                          margin:
                                              const EdgeInsets.only(bottom: 10),
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: colors.subCardBg,
                                            borderRadius:
                                                BorderRadius.circular(14),
                                            border: Border.all(
                                                color: colors.border),
                                          ),
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 40,
                                                height: 40,
                                                decoration: BoxDecoration(
                                                  color: isDark
                                                      ? colors.successText
                                                          .withValues(
                                                              alpha: 0.18)
                                                      : const Color(0xFFDCFCE7),
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                child: Icon(
                                                  Icons.check_circle_rounded,
                                                  color: isDark
                                                      ? colors.successText
                                                      : const Color(0xFF16A34A),
                                                  size: 20,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'Order #$shortId',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 13.5,
                                                        color:
                                                            colors.textPrimary,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      'Cash • ${order.packageCount} package(s)',
                                                      style: TextStyle(
                                                        fontSize: 11.5,
                                                        color:
                                                            colors.textSecondary,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Text(
                                                '₱${order.totalAmount.toStringAsFixed(2)}',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15,
                                                  color: isDark
                                                      ? colors.successText
                                                      : const Color(0xFF16A34A),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                ],
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
                                              setSheetState(() {
                                                paymentCurrentPage =
                                                    effectivePage - 1;
                                              });
                                            }
                                          : null,
                                      icon: const Icon(
                                          Icons.chevron_left_rounded),
                                      color: colors.primary,
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
                                          color: colors.textPrimary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    IconButton(
                                      onPressed: effectivePage < totalPages
                                          ? () {
                                              setSheetState(() {
                                                paymentCurrentPage =
                                                    effectivePage + 1;
                                              });
                                            }
                                          : null,
                                      icon: const Icon(
                                          Icons.chevron_right_rounded),
                                      color: colors.primary,
                                      disabledColor: colors.textMuted,
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showReportsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final colors = ThemeController.of(context);
        final isDark = colors.isDark;

        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.88,
            maxWidth: 440,
          ),
          decoration: BoxDecoration(
            color: colors.cardBg,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: StreamBuilder<List<LaundryOrder>>(
            stream: _orderService.getOrders(),
            builder: (context, snapshot) {
              final orders = snapshot.data ?? [];
              final reportData = AiReportData.fromOrders(orders);

              return Column(
                children: [
                  // Sheet Header with Title and Quick Export Button
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.bar_chart_rounded,
                                color: colors.primary, size: 24),
                            const SizedBox(width: 8),
                            Text(
                              'Reports & Analytics',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: colors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: Icon(Icons.close_rounded,
                              color: colors.textMuted),
                          onPressed: () => Navigator.pop(sheetContext),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: colors.border),

                  Expanded(
                    child: snapshot.connectionState == ConnectionState.waiting
                        ? Center(
                            child: CircularProgressIndicator(
                                color: colors.primary),
                          )
                        : ListView(
                            padding:
                                const EdgeInsets.fromLTRB(16, 16, 16, 24),
                            children: [
                              // Operational Summary Banner
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? colors.subCardBg
                                      : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: colors.border),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                color: colors.primary
                                                    .withValues(alpha: 0.12),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Icon(
                                                Icons.analytics_rounded,
                                                color: colors.primary,
                                                size: 16,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'OPERATIONAL SUMMARY',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w800,
                                                letterSpacing: 0.5,
                                                color: colors.primary,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF16A34A)
                                                .withValues(alpha: 0.12),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                            border: Border.all(
                                              color: const Color(0xFF16A34A)
                                                  .withValues(alpha: 0.3),
                                            ),
                                          ),
                                          child: Text(
                                            '${reportData.completionRate.toStringAsFixed(0)}% Fulfilled',
                                            style: const TextStyle(
                                              color: Color(0xFF16A34A),
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      'Over ${reportData.totalOrders} total recorded orders, LaundroMatic has completed ${reportData.completedOrders} orders with ₱${reportData.totalRevenue.toStringAsFixed(2)} in total realized revenue.',
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        color: colors.textSecondary,
                                        height: 1.45,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),

                              // KPI Matrix
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildKpiCard(
                                      title: 'Total Revenue',
                                      value:
                                          '₱${reportData.totalRevenue.toStringAsFixed(2)}',
                                      icon: Icons.payments_outlined,
                                      color: const Color(0xFF16A34A),
                                      colors: colors,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildKpiCard(
                                      title: 'Total Washed',
                                      value:
                                          '${reportData.totalWeight.toStringAsFixed(1)} kg',
                                      icon: Icons.scale_outlined,
                                      color: const Color(0xFF1E64D4),
                                      colors: colors,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildKpiCard(
                                      title: 'Completed Orders',
                                      value: '${reportData.completedOrders}',
                                      icon: Icons.task_alt_rounded,
                                      color: const Color(0xFF9333EA),
                                      colors: colors,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildKpiCard(
                                      title: 'Avg Order Value',
                                      value:
                                          '₱${reportData.avgTicket.toStringAsFixed(2)}',
                                      icon: Icons.receipt_long_outlined,
                                      color: const Color(0xFFF59E0B),
                                      colors: colors,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 18),

                              // Order Fulfillment Pipeline
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? colors.subCardBg
                                      : const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: colors.border),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Order Fulfillment Pipeline',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13.5,
                                        color: colors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Completed: ${reportData.completedOrders}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF16A34A),
                                          ),
                                        ),
                                        Text(
                                          'Active / Staging: ${reportData.inProgressOrders}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: colors.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: LinearProgressIndicator(
                                        value: orders.isNotEmpty
                                            ? reportData.completedOrders /
                                                orders.length
                                            : 0,
                                        minHeight: 8,
                                        backgroundColor: isDark
                                            ? const Color(0xFF334155)
                                            : const Color(0xFFE2E8F0),
                                        valueColor:
                                            const AlwaysStoppedAnimation(
                                                Color(0xFF16A34A)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Operational Highlights Card
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: colors.cardBg,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: colors.border),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                          alpha: isDark ? 0.2 : 0.02),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.insights_rounded,
                                            color: colors.primary, size: 18),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Operational Highlights',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13.5,
                                            color: colors.textPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    _buildPreviewObservation(
                                      'Revenue Collection',
                                      '₱${reportData.totalRevenue.toStringAsFixed(2)} collected (${reportData.paymentRate.toStringAsFixed(1)}%). ₱${reportData.unpaidRevenue.toStringAsFixed(2)} pending collection.',
                                      colors: colors,
                                    ),
                                    _buildPreviewObservation(
                                      'Machine Throughput',
                                      'Average load is ${reportData.avgWeight.toStringAsFixed(1)} kg per order across ${reportData.totalWeight.toStringAsFixed(1)} kg washed in total.',
                                      colors: colors,
                                    ),
                                    _buildPreviewObservation(
                                      'Order Fulfillment',
                                      '${reportData.completedOrders} orders picked up and completed, with ${reportData.inProgressOrders} active in staging.',
                                      colors: colors,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Full width Export Action Button
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: colors.primary,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  onPressed: () => _exportReport(orders),
                                  icon: const Icon(Icons.download_rounded,
                                      size: 18),
                                  label: const Text(
                                    'Export Business Report',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  void _exportReport(List<LaundryOrder> orders) {
    final reportData = AiReportData.fromOrders(orders);
    final colors = ThemeController.of(context);
    final isDark = colors.isDark;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: colors.cardBg,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.file_download_outlined,
                          color: colors.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Export Business Report',
                            style: TextStyle(
                              fontSize: 16.5,
                              fontWeight: FontWeight.bold,
                              color: colors.textPrimary,
                            ),
                          ),
                          Text(
                            'Choose your preferred export format',
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close_rounded,
                          color: colors.textMuted),
                      onPressed: () => Navigator.pop(sheetContext),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Divider(height: 1, color: colors.border),
                const SizedBox(height: 12),

                // Option 1: Executive HTML & PDF Report
                _buildExportOptionTile(
                  icon: Icons.description_rounded,
                  iconColor: const Color(0xFF1E64D4),
                  iconBg: isDark
                      ? const Color(0xFF1E3A8A).withValues(alpha: 0.3)
                      : const Color(0xFFEBF2FE),
                  title: 'Executive Report (.html / Print PDF)',
                  subtitle:
                      'Complete printable report with KPI cards, metrics breakdown & transaction log',
                  badge: 'Print Ready',
                  badgeColor: const Color(0xFF16A34A),
                  colors: colors,
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    final html = AiReportGenerator.generateAiHtmlReport(
                        reportData, orders);
                    final date =
                        DateTime.now().toIso8601String().split('T').first;
                    final filename = 'LaundroMatic_Report_$date.html';
                    final result = await downloadFile(
                      filename: filename,
                      content: html,
                      mimeType: 'text/html',
                    );
                    if (result.success) {
                      _showExportSnackBar(
                        '$filename downloaded to ${result.storageFolder}!',
                        actionLabel: 'OPEN',
                        onAction: () => shareFile(
                          filePath: result.filePath,
                          filename: result.filename,
                          mimeType: 'text/html',
                        ),
                      );
                    } else {
                      _showExportSnackBar(
                        'Failed to download report: ${result.error ?? "Unknown error"}',
                        isError: true,
                      );
                    }
                  },
                ),
                const SizedBox(height: 10),

                // Option 2: Copy & Share Summary
                _buildExportOptionTile(
                  icon: Icons.copy_all_rounded,
                  iconColor: const Color(0xFF9333EA),
                  iconBg: isDark
                      ? const Color(0xFF581C87).withValues(alpha: 0.3)
                      : const Color(0xFFF3E8FF),
                  title: 'Copy & Share Summary Text',
                  subtitle:
                      'Structured summary with key performance metrics for messaging or email',
                  colors: colors,
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    final summary =
                        AiReportGenerator.generateMarkdownSummary(reportData);
                    await Clipboard.setData(ClipboardData(text: summary));
                    final date =
                        DateTime.now().toIso8601String().split('T').first;
                    final filename = 'LaundroMatic_Summary_$date.txt';
                    final result = await downloadFile(
                      filename: filename,
                      content: summary,
                      mimeType: 'text/plain',
                    );
                    _showExportSnackBar(
                      '$filename downloaded to ${result.storageFolder} & copied to clipboard!',
                      actionLabel: 'SHARE',
                      onAction: () => shareText(
                        text: summary,
                        subject: 'LaundroMatic Operations Summary',
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),

                // Option 3: Raw CSV
                _buildExportOptionTile(
                  icon: Icons.table_chart_rounded,
                  iconColor: const Color(0xFF059669),
                  iconBg: isDark
                      ? const Color(0xFF064E3B).withValues(alpha: 0.3)
                      : const Color(0xFFD1FAE5),
                  title: 'Raw Orders Data (.csv)',
                  subtitle:
                      'Comma-separated spreadsheet of all order logs for Excel or Google Sheets',
                  colors: colors,
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    final csv = AiReportGenerator.generateCsvData(orders);
                    final date =
                        DateTime.now().toIso8601String().split('T').first;
                    final filename = 'LaundroMatic_Orders_$date.csv';
                    final result = await downloadFile(
                      filename: filename,
                      content: csv,
                      mimeType: 'text/csv',
                    );
                    if (result.success) {
                      _showExportSnackBar(
                        '$filename downloaded to ${result.storageFolder}!',
                        actionLabel: 'OPEN',
                        onAction: () => shareFile(
                          filePath: result.filePath,
                          filename: result.filename,
                          mimeType: 'text/csv',
                        ),
                      );
                    } else {
                      _showExportSnackBar(
                        'Failed to download CSV: ${result.error ?? "Unknown error"}',
                        isError: true,
                      );
                    }
                  },
                ),
                const SizedBox(height: 10),

                // Option 4: Preview in App
                _buildExportOptionTile(
                  icon: Icons.visibility_rounded,
                  iconColor: const Color(0xFFF59E0B),
                  iconBg: isDark
                      ? const Color(0xFF78350F).withValues(alpha: 0.3)
                      : const Color(0xFFFEF3C7),
                  title: 'Preview Report',
                  subtitle:
                      'Read the operational metrics and breakdown directly in the app',
                  colors: colors,
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _showReportPreviewDialog(reportData, orders);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildExportOptionTile({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required ThemeColors colors,
    String? badge,
    Color? badgeColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: colors.isDark ? colors.subCardBg : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: colors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: badgeColor?.withValues(alpha: 0.15) ??
                                const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            badge,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: badgeColor ?? const Color(0xFF16A34A),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: colors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                size: 18, color: colors.textMuted),
          ],
        ),
      ),
    );
  }

  void _showExportSnackBar(
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
    bool isError = false,
  }) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError
                  ? Icons.error_outline_rounded
                  : Icons.check_circle_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor:
            isError ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        action: (actionLabel != null && onAction != null)
            ? SnackBarAction(
                label: actionLabel,
                textColor: Colors.white,
                onPressed: onAction,
              )
            : null,
      ),
    );
  }

  void _showReportPreviewDialog(
      AiReportData data, List<LaundryOrder> orders) {
    final colors = ThemeController.of(context);
    final isDark = colors.isDark;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: colors.cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.analytics_rounded,
                      color: colors.primary, size: 22),
                  const SizedBox(width: 8),
                  Text('Business Report Preview',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                          color: colors.textPrimary)),
                ],
              ),
              IconButton(
                icon: Icon(Icons.close_rounded,
                    size: 20, color: colors.textMuted),
                onPressed: () => Navigator.pop(dialogContext),
              ),
            ],
          ),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Performance Summary
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color:
                          isDark ? colors.subCardBg : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colors.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Operational Overview',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: colors.primary,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF16A34A)
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFF16A34A)
                                  .withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            '${data.completionRate.toStringAsFixed(0)}% Fulfilled',
                            style: const TextStyle(
                              color: Color(0xFF16A34A),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  Text(
                    'Executive Summary',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'LaundroMatic sustained stable operations across ${data.totalOrders} customer orders. Cumulative processed throughput reached ${data.totalWeight.toStringAsFixed(1)} kg with ₱${data.totalRevenue.toStringAsFixed(2)} realized gross revenue. Order completion rate is currently at ${data.completionRate.toStringAsFixed(1)}% with a ${data.paymentRate.toStringAsFixed(1)}% payment collection rate.',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: colors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 14),

                  Text(
                    'Operational Highlights',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _buildPreviewObservation(
                    'Revenue Collection',
                    'Average ticket value of ₱${data.avgTicket.toStringAsFixed(2)} with ${data.paymentRate.toStringAsFixed(1)}% collected on completed/in-progress orders.',
                    colors: colors,
                  ),
                  _buildPreviewObservation(
                    'Throughput & Staging',
                    'With ${data.inProgressOrders} active orders in progress, maintaining pickup notifications ensures fast customer collection.',
                    colors: colors,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton.icon(
              onPressed: () async {
                final summary =
                    AiReportGenerator.generateMarkdownSummary(data);
                await Clipboard.setData(ClipboardData(text: summary));
                final date =
                    DateTime.now().toIso8601String().split('T').first;
                final filename = 'LaundroMatic_Summary_$date.txt';
                final result = await downloadFile(
                  filename: filename,
                  content: summary,
                  mimeType: 'text/plain',
                );
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
                _showExportSnackBar(
                  '$filename downloaded to ${result.storageFolder} & copied!',
                  actionLabel: 'SHARE',
                  onAction: () => shareText(
                    text: summary,
                    subject: 'LaundroMatic Operations Summary',
                  ),
                );
              },
              icon: const Icon(Icons.share_rounded, size: 16),
              label: Text('Share Summary',
                  style: TextStyle(color: colors.primary)),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () async {
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
                final html =
                    AiReportGenerator.generateAiHtmlReport(data, orders);
                final date =
                    DateTime.now().toIso8601String().split('T').first;
                final filename = 'LaundroMatic_Report_$date.html';
                final result = await downloadFile(
                  filename: filename,
                  content: html,
                  mimeType: 'text/html',
                );
                if (result.success) {
                  _showExportSnackBar(
                    '$filename downloaded to ${result.storageFolder}!',
                    actionLabel: 'OPEN',
                    onAction: () => shareFile(
                      filePath: result.filePath,
                      filename: result.filename,
                      mimeType: 'text/html',
                    ),
                  );
                } else {
                  _showExportSnackBar(
                    'Failed to download report: ${result.error ?? "Unknown error"}',
                    isError: true,
                  );
                }
              },
              icon: const Icon(Icons.download_rounded, size: 16),
              label: const Text('Export HTML'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPreviewObservation(
    String title,
    String body, {
    ThemeColors? colors,
  }) {
    final effectiveColors = colors ?? ThemeController.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 4, right: 8),
            child: Icon(Icons.check_circle_rounded,
                size: 14, color: Color(0xFF16A34A)),
          ),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                    fontSize: 12, color: effectiveColors.textSecondary),
                children: [
                  TextSpan(
                    text: '$title: ',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: effectiveColors.textPrimary),
                  ),
                  TextSpan(text: body),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    ThemeColors? colors,
  }) {
    final effectiveColors = colors ?? ThemeController.of(context);
    final isDark = effectiveColors.isDark;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: effectiveColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: effectiveColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(
                fontSize: 11.5, color: effectiveColors.textMuted),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: effectiveColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  void _showEditProfileDialog() {
    final user = FirebaseAuth.instance.currentUser;
    final nameController = TextEditingController(
      text: user?.displayName ?? 'LaundroMatic Administrator',
    );
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;
    bool isLoading = false;
    String? errorMessage;
    String? successMessage;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEBF2FE),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.manage_accounts_rounded,
                      color: Color(0xFF1E64D4),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Edit Profile & Password',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 440,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Email display
                      const Text(
                        'Account Email',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.email_outlined,
                                size: 18, color: Color(0xFF64748B)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                user?.email ?? 'No email associated',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF334155),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Display Name
                      const Text(
                        'Full Name / Display Name',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      TextField(
                        controller: nameController,
                        decoration: InputDecoration(
                          prefixIcon:
                              const Icon(Icons.badge_outlined, size: 20),
                          hintText: 'Enter full name',
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Change Password Section
                      const Row(
                        children: [
                          Icon(Icons.lock_reset_rounded,
                              size: 18, color: Color(0xFF1E64D4)),
                          SizedBox(width: 6),
                          Text(
                            'Security & Password',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Leave password fields blank if you only want to update your name.',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Current Password
                      TextField(
                        controller: currentPasswordController,
                        obscureText: obscureCurrent,
                        decoration: InputDecoration(
                          prefixIcon:
                              const Icon(Icons.lock_outline_rounded, size: 20),
                          hintText: 'Current Password',
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscureCurrent
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              size: 18,
                            ),
                            onPressed: () {
                              setDialogState(() {
                                obscureCurrent = !obscureCurrent;
                              });
                            },
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // New Password
                      TextField(
                        controller: newPasswordController,
                        obscureText: obscureNew,
                        decoration: InputDecoration(
                          prefixIcon:
                              const Icon(Icons.vpn_key_outlined, size: 20),
                          hintText: 'New Password (min. 6 characters)',
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscureNew
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              size: 18,
                            ),
                            onPressed: () {
                              setDialogState(() {
                                obscureNew = !obscureNew;
                              });
                            },
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Confirm New Password
                      TextField(
                        controller: confirmPasswordController,
                        obscureText: obscureConfirm,
                        decoration: InputDecoration(
                          prefixIcon:
                              const Icon(Icons.check_circle_outline, size: 20),
                          hintText: 'Confirm New Password',
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscureConfirm
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              size: 18,
                            ),
                            onPressed: () {
                              setDialogState(() {
                                obscureConfirm = !obscureConfirm;
                              });
                            },
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),

                      if (errorMessage != null) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline,
                                  color: Color(0xFFDC2626), size: 16),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  errorMessage!,
                                  style: const TextStyle(
                                    color: Color(0xFFDC2626),
                                    fontSize: 11.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      if (successMessage != null) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle_outline,
                                  color: Color(0xFF16A34A), size: 16),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  successMessage!,
                                  style: const TextStyle(
                                    color: Color(0xFF16A34A),
                                    fontSize: 11.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 12),
                      // Reset password email option
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(50, 30),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          icon: const Icon(Icons.mark_email_read_outlined,
                              size: 15, color: Color(0xFF1E64D4)),
                          label: const Text(
                            'Send password reset email to my inbox',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: Color(0xFF1E64D4),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          onPressed: user?.email == null
                              ? null
                              : () async {
                                  try {
                                    await FirebaseAuth.instance
                                        .sendPasswordResetEmail(
                                            email: user!.email!);
                                    setDialogState(() {
                                      successMessage =
                                          'Password reset link dispatched to ${user.email}!';
                                      errorMessage = null;
                                    });
                                  } catch (e) {
                                    setDialogState(() {
                                      errorMessage =
                                          'Failed to send reset email: $e';
                                      successMessage = null;
                                    });
                                  }
                                },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed:
                      isLoading ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E64D4),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: isLoading
                      ? null
                      : () async {
                          final newName = nameController.text.trim();
                          final currentPass =
                              currentPasswordController.text.trim();
                          final newPass = newPasswordController.text.trim();
                          final confirmPass =
                              confirmPasswordController.text.trim();

                          setDialogState(() {
                            isLoading = true;
                            errorMessage = null;
                            successMessage = null;
                          });

                          try {
                            // Update display name if changed
                            if (newName.isNotEmpty &&
                                newName != (user?.displayName ?? '')) {
                              await user?.updateDisplayName(newName);
                            }

                            // Update password if specified
                            if (newPass.isNotEmpty) {
                              if (newPass.length < 6) {
                                setDialogState(() {
                                  isLoading = false;
                                  errorMessage =
                                      'New password must be at least 6 characters.';
                                });
                                return;
                              }
                              if (newPass != confirmPass) {
                                setDialogState(() {
                                  isLoading = false;
                                  errorMessage =
                                      'New passwords do not match.';
                                });
                                return;
                              }
                              if (currentPass.isEmpty) {
                                setDialogState(() {
                                  isLoading = false;
                                  errorMessage =
                                      'Please provide your current password for security verification.';
                                });
                                return;
                              }

                              // Re-authenticate
                              if (user?.email != null) {
                                final cred = EmailAuthProvider.credential(
                                  email: user!.email!,
                                  password: currentPass,
                                );
                                await user.reauthenticateWithCredential(cred);
                              }
                              await user?.updatePassword(newPass);
                            }

                            if (context.mounted) {
                              Navigator.pop(dialogContext);
                              setState(() {});
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      '✦ Profile updated successfully!'),
                                  backgroundColor: Color(0xFF16A34A),
                                ),
                              );
                            }
                          } on FirebaseAuthException catch (e) {
                            setDialogState(() {
                              isLoading = false;
                              errorMessage = e.message ?? e.code;
                            });
                          } catch (e) {
                            setDialogState(() {
                              isLoading = false;
                              errorMessage = 'Update error: $e';
                            });
                          }
                        },
                  child: isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Save Changes'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildThemeToggleItem(bool isDark) {
    return InkWell(
      onTap: () {
        ThemeController.toggleTheme();
      },
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              color: isDark ? const Color(0xFFFACC15) : const Color(0xFF64748B),
              size: 22,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Theme Appearance',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isDark ? 'Dark Mode (Active)' : 'Light Mode (Active)',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            Switch.adaptive(
              value: isDark,
              activeTrackColor: const Color(0xFF1E64D4),
              onChanged: (val) {
                ThemeController.toggleTheme();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingRow(String title, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF64748B)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 11.5, color: Color(0xFF64748B))),
              Text(value,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F172A))),
            ],
          ),
        ),
      ],
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: const Row(
            children: [
              Icon(Icons.help_outline_rounded,
                  color: Color(0xFF1E64D4), size: 22),
              SizedBox(width: 8),
              Text('Help & Support',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'LaundroMatic Support Hub',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              const Text(
                'Need assistance managing your laundry orders, customers, or inventory tracking?',
                style: TextStyle(fontSize: 12.5, color: Color(0xFF475569)),
              ),
              const SizedBox(height: 14),
              _buildSettingRow(
                  'Email Support', 'support@laundromatic.ph', Icons.email_outlined),
              const SizedBox(height: 8),
              _buildSettingRow(
                  'Hotline', '+63 (02) 8123-4567', Icons.phone_outlined),
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E64D4),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFFEBF2FE),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.local_laundry_service_rounded,
                  color: Color(0xFF1E64D4),
                  size: 32,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'LaundroMatic',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Smart Laundromat Management System',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Version 1.0.0 (Release)',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF475569),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E64D4),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Close'),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.themeModeNotifier,
      builder: (context, themeMode, _) {
        final isDark = themeMode == ThemeMode.dark;
        final pageBg =
            isDark ? const Color(0xFF0F172A) : const Color(0xFFF7F8FC);
        final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
        final textDark = isDark ? Colors.white : const Color(0xFF0F172A);
        final textMuted =
            isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
        final borderColor =
            isDark ? const Color(0xFF334155) : Colors.grey.shade200;
        final dividerColor =
            isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9);
        const primaryBlue = Color(0xFF1E64D4);

        final currentUser = FirebaseAuth.instance.currentUser;
        final displayName = (currentUser?.displayName != null &&
                currentUser!.displayName!.isNotEmpty)
            ? currentUser.displayName!
            : 'LaundroMatic Administrator';
        final userEmail = currentUser?.email ?? 'admin@laundromatic.ph';

        Widget moreContent = Scaffold(
          backgroundColor: pageBg,
          appBar: AppBar(
            backgroundColor: pageBg,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            automaticallyImplyLeading: false,
            leading: Navigator.canPop(context)
                ? IconButton(
                    icon: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 19,
                      color: textDark,
                    ),
                    onPressed: () => Navigator.pop(context),
                  )
                : null,
            title: Text(
              'More',
              style: TextStyle(
                color: textDark,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 440),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
            children: [
              // User Profile Banner
              // User Profile Banner (Clickable to Edit Profile & Password)
              InkWell(
                onTap: _showEditProfileDialog,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black
                            .withValues(alpha: isDark ? 0.2 : 0.02),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1E3A8A).withValues(alpha: 0.3)
                              : const Color(0xFFEBF2FE),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.person_rounded,
                            color: primaryBlue,
                            size: 26,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    displayName,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: textDark,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(Icons.edit_outlined,
                                    size: 14, color: textMuted),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              userEmail,
                              style: TextStyle(
                                fontSize: 12,
                                color: textMuted,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Active',
                          style: TextStyle(
                            color: Color(0xFF16A34A),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Group 1: Business Operations (Matching Inspo)
              Container(
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black
                          .withValues(alpha: isDark ? 0.2 : 0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildMenuItem(
                      icon: Icons.people_rounded,
                      iconColor: primaryBlue,
                      title: 'Customers',
                      isDark: isDark,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const CustomerPage()),
                        );
                      },
                    ),
                    Divider(height: 1, indent: 52, color: dividerColor),
                    _buildMenuItem(
                      icon: Icons.local_laundry_service_rounded,
                      iconColor: primaryBlue,
                      title: 'Services',
                      isDark: isDark,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const ServicesPage()),
                        );
                      },
                    ),
                    Divider(height: 1, indent: 52, color: dividerColor),
                    _buildMenuItem(
                      icon: Icons.payments_rounded,
                      iconColor: primaryBlue,
                      title: 'Payments',
                      isDark: isDark,
                      onTap: _showPaymentsSheet,
                    ),
                    Divider(height: 1, indent: 52, color: dividerColor),
                    _buildMenuItem(
                      icon: Icons.bar_chart_rounded,
                      iconColor: primaryBlue,
                      title: 'Reports & Analytics',
                      isDark: isDark,
                      onTap: _showReportsSheet,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Group 2: Account & System Preferences (Replaced Settings with Edit Profile & Dark/Light mode)
              Container(
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black
                          .withValues(alpha: isDark ? 0.2 : 0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildMenuItem(
                      icon: Icons.manage_accounts_rounded,
                      iconColor: primaryBlue,
                      title: 'Edit Profile & Password',
                      isDark: isDark,
                      onTap: _showEditProfileDialog,
                    ),
                    Divider(height: 1, indent: 52, color: dividerColor),
                    _buildThemeToggleItem(isDark),
                    Divider(height: 1, indent: 52, color: dividerColor),
                    _buildMenuItem(
                      icon: Icons.help_outline_rounded,
                      iconColor: textMuted,
                      title: 'Help & Support',
                      isDark: isDark,
                      onTap: _showHelpDialog,
                    ),
                    Divider(height: 1, indent: 52, color: dividerColor),
                    _buildMenuItem(
                      icon: Icons.info_outline_rounded,
                      iconColor: textMuted,
                      title: 'About',
                      isDark: isDark,
                      onTap: _showAboutDialog,
                    ),
                    Divider(height: 1, indent: 52, color: dividerColor),
                    _buildMenuItem(
                      icon: Icons.logout_rounded,
                      iconColor: const Color(0xFFEF4444),
                      title: 'Log Out',
                      isDestructive: true,
                      isDark: isDark,
                      onTap: _confirmLogout,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),

      // Persistent 5-Tab Bottom Navigation Bar
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: cardBg,
          border: Border(
            top: BorderSide(color: borderColor, width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: 4, // More is active
          onTap: (index) {
            if (index == 4) return;
            if (index == 0) {
              if (Navigator.canPop(context)) {
                Navigator.popUntil(context, (route) => route.isFirst);
              } else {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const DashboardPage()),
                );
              }
            } else if (index == 1) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const OrdersPage()),
              );
            } else if (index == 2) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const InventoryPage()),
              );
            } else if (index == 3) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => const InventoryTransactionsPage(),
                ),
              );
            }
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: cardBg,
          selectedItemColor: primaryBlue,
          unselectedItemColor: textMuted,
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
            color: isDark ? const Color(0xFF020617) : const Color(0xFFE2E8F0),
            child: Center(
              child: ConstrainedBox(
                constraints:
                    const BoxConstraints(maxWidth: 440, maxHeight: 920),
                child: Container(
                  decoration: BoxDecoration(
                    color: pageBg,
                    borderRadius: BorderRadius.circular(kIsWeb ? 20 : 0),
                    boxShadow: [
                      if (kIsWeb)
                        BoxShadow(
                          color: Colors.black
                              .withValues(alpha: isDark ? 0.35 : 0.12),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: moreContent,
                ),
              ),
            ),
          );
        }
        return moreContent;
      },
    );
      },
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
    bool? isDark,
  }) {
    final effectiveIsDark = isDark ?? ThemeController.isDark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight:
                      isDestructive ? FontWeight.bold : FontWeight.w600,
                  color: isDestructive
                      ? const Color(0xFFEF4444)
                      : (effectiveIsDark ? Colors.white : const Color(0xFF0F172A)),
                ),
              ),
            ),
            if (!isDestructive)
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: effectiveIsDark ? const Color(0xFF94A3B8) : Colors.grey.shade400,
              ),
          ],
        ),
      ),
    );
  }
}
