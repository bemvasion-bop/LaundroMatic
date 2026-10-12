import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../controllers/theme_controller.dart';
import '../models/inventory.dart';
import '../models/order.dart';
import '../models/service.dart';
import '../services/inventory_service.dart';
import '../services/order_service.dart';
import '../services/service_service.dart';
import 'inventory_page.dart';
import 'inventory_transactions_page.dart';
import 'more_page.dart';
import 'orders_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String _selectedRevenuePeriod = 'This Week';

  final OrderService _orderService = OrderService();
  final ServiceService _serviceService = ServiceService();
  final InventoryService _inventoryService = InventoryService();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.themeModeNotifier,
      builder: (context, themeMode, _) {
        final colors = ThemeController.of(context);
        final isDark = colors.isDark;

        final primaryBlue = colors.primary;
        final primaryLight = colors.primaryLight;
        final textDark = colors.textPrimary;
        final textMuted = colors.textSecondary;
        final cardBg = colors.cardBg;
        final pageBg = colors.pageBg;
        final borderColor = colors.border;

        final successGreen = colors.successText;
        final successBg = colors.successBg;

        final warningOrange = colors.warningText;
        final warningBg = colors.warningBg;

        final errorRed = colors.errorText;
        final errorBg = colors.errorBg;

        final purpleColor = colors.purpleText;
        final purpleBg = colors.purpleBg;

    Widget dashboardContent = StreamBuilder<List<LaundryOrder>>(
      stream: _orderService.getOrders(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: pageBg,
            body: Center(child: CircularProgressIndicator(color: primaryBlue)),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: pageBg,
            body: Center(
              child: Text(
                'Error loading dashboard:\n${snapshot.error}',
                textAlign: TextAlign.center,
                style: TextStyle(color: errorRed),
              ),
            ),
          );
        }

        final List<LaundryOrder> orders = snapshot.data ?? [];
        final DateTime now = DateTime.now();
        final DateTime today = DateTime(now.year, now.month, now.day);

        // Today's overview stats
        final int todaysOrders = orders.where((order) {
          final DateTime? date = order.orderDate;
          if (date == null) return false;
          return date.year == today.year &&
              date.month == today.month &&
              date.day == today.day;
        }).length;

        final int processingOrders = orders.where((order) {
          return order.orderStatus == 'Processing';
        }).length;

        final int readyForPickupOrders = orders.where((order) {
          return order.orderStatus == 'Ready for Pickup';
        }).length;

        final int pickedUpToday = orders.where((order) {
          final DateTime? date = order.pickedUpDate;
          if (date == null) return false;
          return date.year == today.year &&
              date.month == today.month &&
              date.day == today.day;
        }).length;

        // Dynamic Revenue calculations based on _selectedRevenuePeriod
        List<double> chartValues = [];
        List<String> chartLabels = [];
        String comparisonSubtitle = 'this week';
        double calculatedTotalRevenue = 0.0;
        int paidOrderCount = 0;

        if (_selectedRevenuePeriod == 'Today') {
          chartLabels = ['Morning', 'Afternoon', 'Evening', 'Night'];
          chartValues = List<double>.filled(4, 0.0);
          comparisonSubtitle = 'today';

          for (final order in orders) {
            if (order.paymentStatus.toLowerCase().trim() != 'paid') continue;
            final date =
                order.orderDate ?? order.processingDate ?? order.pickedUpDate;
            if (date == null) continue;
            if (date.year == today.year &&
                date.month == today.month &&
                date.day == today.day) {
              calculatedTotalRevenue += order.totalAmount;
              paidOrderCount++;
              if (date.hour < 12) {
                chartValues[0] += order.totalAmount;
              } else if (date.hour < 16) {
                chartValues[1] += order.totalAmount;
              } else if (date.hour < 20) {
                chartValues[2] += order.totalAmount;
              } else {
                chartValues[3] += order.totalAmount;
              }
            }
          }
        } else if (_selectedRevenuePeriod == 'This Month') {
          chartLabels = ['W1', 'W2', 'W3', 'W4'];
          chartValues = List<double>.filled(4, 0.0);
          comparisonSubtitle = 'this month';

          // 4-week (28-day) window ending today so month-boundary sales are accurately captured
          final DateTime startOfPeriod =
              today.subtract(const Duration(days: 28));

          for (final order in orders) {
            if (order.paymentStatus.toLowerCase().trim() != 'paid') continue;
            final date =
                order.orderDate ?? order.processingDate ?? order.pickedUpDate;
            if (date == null) continue;

            final orderDay = DateTime(date.year, date.month, date.day);
            if (!orderDay.isBefore(startOfPeriod) &&
                !orderDay.isAfter(today.add(const Duration(days: 1)))) {
              calculatedTotalRevenue += order.totalAmount;
              paidOrderCount++;
              int daysAgo = today.difference(orderDay).inDays;
              if (daysAgo < 0) daysAgo = 0;
              // 0-6 days ago -> W4 (most recent week)
              // 7-13 days ago -> W3
              // 14-20 days ago -> W2
              // 21-28 days ago -> W1
              final weekIndex = (3 - (daysAgo / 7).floor()).clamp(0, 3);
              chartValues[weekIndex] += order.totalAmount;
            }
          }
        } else if (_selectedRevenuePeriod == 'This Year') {
          chartLabels = [
            'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
            'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
          ];
          chartValues = List<double>.filled(12, 0.0);
          comparisonSubtitle = 'this year';

          for (final order in orders) {
            if (order.paymentStatus.toLowerCase().trim() != 'paid') continue;
            final date =
                order.orderDate ?? order.processingDate ?? order.pickedUpDate;
            if (date == null) continue;
            if (date.year == today.year) {
              calculatedTotalRevenue += order.totalAmount;
              paidOrderCount++;
              final monthIndex = (date.month - 1).clamp(0, 11);
              chartValues[monthIndex] += order.totalAmount;
            }
          }
        } else {
          // Default: "This Week"
          chartLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
          chartValues = List<double>.filled(7, 0.0);
          comparisonSubtitle = 'this week';

          final DateTime startOfWeek = DateTime(
            today.year,
            today.month,
            today.day,
          ).subtract(
            Duration(days: today.weekday - 1),
          );
          final DateTime endOfWeek = startOfWeek.add(const Duration(days: 7));

          for (final order in orders) {
            if (order.paymentStatus.toLowerCase().trim() != 'paid') continue;
            final date =
                order.orderDate ?? order.processingDate ?? order.pickedUpDate;
            if (date == null) continue;

            final orderDay = DateTime(date.year, date.month, date.day);
            if (!orderDay.isBefore(startOfWeek) && orderDay.isBefore(endOfWeek)) {
              final dayDifference =
                  orderDay.difference(startOfWeek).inDays.clamp(0, 6);
              chartValues[dayDifference] += order.totalAmount;
              calculatedTotalRevenue += order.totalAmount;
              paidOrderCount++;
            }
          }
        }

        final displayTotalRevenue = calculatedTotalRevenue;

        double maxChartValue = 0;
        for (final val in chartValues) {
          if (val > maxChartValue) maxChartValue = val;
        }

        return Scaffold(
          backgroundColor: pageBg,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Good morning, ',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: textDark,
                                ),
                              ),
                              Text(
                                'Jane!',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: textDark,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                '👋',
                                style: TextStyle(fontSize: 18),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatHeaderDate(now),
                            style: TextStyle(
                              fontSize: 13,
                              color: textMuted,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: primaryLight,
                          border: Border.all(color: borderColor, width: 1),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.person_rounded,
                            color: primaryBlue,
                            size: 26,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Today's Overview Section Header
                  Text(
                    "Today's Overview",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 4 Stat Cards in 2x2 Grid (Interactive Quick Access)
                  GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.45,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildStatCard(
                        icon: Icons.receipt_long_rounded,
                        iconColor: primaryBlue,
                        iconBg: primaryLight,
                        title: "Today's Orders",
                        value: todaysOrders.toString(),
                        badgeText: "Tap to view orders",
                        badgeColor: successGreen,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const OrdersPage(initialDate: 'Today'),
                            ),
                          );
                        },
                      ),
                      _buildStatCard(
                        icon: Icons.sync_rounded,
                        iconColor: warningOrange,
                        iconBg: warningBg,
                        title: "Processing",
                        value: processingOrders.toString(),
                        badgeText: "Tap to view orders",
                        badgeColor: warningOrange,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const OrdersPage(initialStatus: 'Processing'),
                            ),
                          );
                        },
                      ),
                      _buildStatCard(
                        icon: Icons.inventory_2_rounded,
                        iconColor: successGreen,
                        iconBg: successBg,
                        title: "Ready for Pickup",
                        value: readyForPickupOrders.toString(),
                        badgeText: "Tap to view orders",
                        badgeColor: successGreen,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const OrdersPage(initialStatus: 'Ready'),
                            ),
                          );
                        },
                      ),
                      _buildStatCard(
                        icon: Icons.check_circle_rounded,
                        iconColor: purpleColor,
                        iconBg: purpleBg,
                        title: "Picked Up Today",
                        value: pickedUpToday.toString(),
                        badgeText: "Tap to view orders",
                        badgeColor: purpleColor,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const OrdersPage(initialStatus: 'Completed'),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Prominent Revenue Card Section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderColor),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.bar_chart_rounded,
                                  size: 22,
                                  color: primaryBlue,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Revenue',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: textDark,
                                  ),
                                ),
                              ],
                            ),

                            // Interactive Functional Revenue Period Dropdown Selector
                            PopupMenuButton<String>(
                              onSelected: (selectedPeriod) {
                                setState(() {
                                  _selectedRevenuePeriod = selectedPeriod;
                                });
                              },
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              itemBuilder: (context) => const [
                                PopupMenuItem(
                                  value: 'Today',
                                  child: Text('Today'),
                                ),
                                PopupMenuItem(
                                  value: 'This Week',
                                  child: Text('This Week'),
                                ),
                                PopupMenuItem(
                                  value: 'This Month',
                                  child: Text('This Month'),
                                ),
                                PopupMenuItem(
                                  value: 'This Year',
                                  child: Text('This Year'),
                                ),
                              ],
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: pageBg,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: borderColor),
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      _selectedRevenuePeriod,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: textDark,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      size: 16,
                                      color: textMuted,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '₱${displayTotalRevenue.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: textDark,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: paidOrderCount > 0
                                    ? successBg
                                    : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '$paidOrderCount paid',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: paidOrderCount > 0
                                      ? successGreen
                                      : textMuted,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              comparisonSubtitle,
                              style: TextStyle(
                                fontSize: 11,
                                color: textMuted,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Dynamic Weekly/Monthly/Yearly Bar Chart (Guaranteed zero pixel overflow)
                        SizedBox(
                          height: 124,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children:
                                List.generate(chartLabels.length, (index) {
                              final amount = chartValues[index];
                              final isPeak = maxChartValue > 0 &&
                                  amount == maxChartValue &&
                                  amount > 0;
                              final barHeight = maxChartValue > 0 && amount > 0
                                  ? (amount / maxChartValue * 66)
                                      .clamp(8.0, 66.0)
                                  : 4.0;
                              final barColor = isPeak
                                  ? primaryBlue
                                  : (amount > 0
                                      ? const Color(0xFF93C5FD)
                                      : const Color(0xFFE2E8F0));

                              return Expanded(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: chartLabels.length > 7 ? 2 : 3,
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    mainAxisSize: MainAxisSize.max,
                                    children: [
                                      SizedBox(
                                        height: 18,
                                        child: isPeak
                                            ? Center(
                                                child: FittedBox(
                                                  fit: BoxFit.scaleDown,
                                                  child: Text(
                                                    amount >= 10000
                                                        ? '₱${(amount / 1000).toStringAsFixed(1)}k'
                                                        : '₱${amount.toStringAsFixed(0)}',
                                                    style: TextStyle(
                                                      fontSize: 9.5,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: primaryBlue,
                                                    ),
                                                  ),
                                                ),
                                              )
                                            : const SizedBox.shrink(),
                                      ),
                                      const SizedBox(height: 2),
                                      Container(
                                        height: barHeight,
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          color: barColor,
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      SizedBox(
                                        height: 16,
                                        child: Center(
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Text(
                                              chartLabels[index],
                                              maxLines: 1,
                                              style: TextStyle(
                                                fontSize:
                                                    chartLabels.length > 7
                                                        ? 9
                                                        : 11,
                                                fontWeight: isPeak
                                                    ? FontWeight.bold
                                                    : FontWeight.w500,
                                                color: isPeak
                                                    ? primaryBlue
                                                    : textMuted,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Inventory Overview Section
                  StreamBuilder<List<InventoryItem>>(
                    stream: _inventoryService.getInventory(),
                    builder: (context, invSnapshot) {
                      final inventory = invSnapshot.data ?? [];
                      final totalItems = inventory.length;
                      final lowStockItems = inventory
                          .where((item) => item.status == 'Low Stock')
                          .length;
                      final outOfStockItems = inventory
                          .where((item) => item.status == 'Out of Stock')
                          .length;

                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: borderColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.inventory_2_outlined,
                                  size: 20,
                                  color: textDark,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Inventory Overview',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: textDark,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildInventoryBox(
                                    icon: Icons.inventory_2_rounded,
                                    iconColor: primaryBlue,
                                    iconBg: primaryLight,
                                    value: totalItems.toString(),
                                    label: 'Items',
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const InventoryPage(
                                                  initialFilter: 'All'),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _buildInventoryBox(
                                    icon: Icons.warning_amber_rounded,
                                    iconColor: warningOrange,
                                    iconBg: warningBg,
                                    value: lowStockItems.toString(),
                                    label: 'Low Stock',
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const InventoryPage(
                                                  initialFilter: 'Low Stock'),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _buildInventoryBox(
                                    icon: Icons.cancel_rounded,
                                    iconColor: errorRed,
                                    iconBg: errorBg,
                                    value: outOfStockItems.toString(),
                                    label: 'Out of Stock',
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const InventoryPage(
                                                  initialFilter:
                                                      'Out of Stock'),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),

                  // Orders by Service Card Section
                  StreamBuilder<List<LaundryService>>(
                    stream: _serviceService.getServices(),
                    builder: (context, serviceSnapshot) {
                      final List<LaundryService> services =
                          serviceSnapshot.data ?? [];
                      return _buildOrdersByServiceCard(
                        orders: orders,
                        services: services,
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // Bottom Navigation Bar
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: cardBg,
              border: Border(
                top: BorderSide(color: borderColor, width: 1),
              ),
            ),
            child: BottomNavigationBar(
              currentIndex: 0, // Home tab is active
              onTap: (index) {
                if (index == 0) return;
                if (index == 1) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const OrdersPage()),
                  );
                } else if (index == 2) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const InventoryPage()),
                  );
                } else if (index == 3) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            const InventoryTransactionsPage()),
                  );
                } else if (index == 4) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const MorePage()),
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
                  icon: Icon(Icons.receipt_long_outlined),
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
      },
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (kIsWeb || constraints.maxWidth > 500) {
          return Container(
            color: isDark ? const Color(0xFF020617) : const Color(0xFFE2E8F0),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 440,
                  maxHeight: 920,
                ),
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
                  child: dashboardContent,
                ),
              ),
            ),
          );
        }
        return dashboardContent;
      },
    );
      },
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String value,
    required String badgeText,
    required Color badgeColor,
    VoidCallback? onTap,
  }) {
    final colors = ThemeController.of(context);
    final textDark = colors.textPrimary;
    final borderColor = colors.border;
    final cardBg = colors.cardBg;
    final isDark = colors.isDark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.all(12),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: iconBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: iconColor, size: 20),
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: textDark,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                badgeText,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: badgeColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInventoryBox({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String value,
    required String label,
    VoidCallback? onTap,
  }) {
    final colors = ThemeController.of(context);
    final textDark = colors.textPrimary;
    final textMuted = colors.textSecondary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: iconBg.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textDark,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrdersByServiceCard({
    required List<LaundryOrder> orders,
    required List<LaundryService> services,
  }) {
    final colors = ThemeController.of(context);
    final textDark = colors.textPrimary;
    final textMuted = colors.textSecondary;
    final primaryBlue = colors.primary;
    final borderColor = colors.border;
    final cardBg = colors.cardBg;

    final Map<String, int> serviceCounts = {};
    for (final service in services) {
      serviceCounts[service.serviceId] = 0;
    }
    for (final order in orders) {
      if (serviceCounts.containsKey(order.serviceId)) {
        serviceCounts[order.serviceId] = serviceCounts[order.serviceId]! + 1;
      }
    }
    final int totalOrders = orders.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Orders by Service',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textDark,
            ),
          ),
          const SizedBox(height: 16),
          if (services.isEmpty)
            Text(
              'No services configured.',
              style: TextStyle(color: textMuted, fontSize: 13),
            )
          else
            ...services.map((service) {
              final int count = serviceCounts[service.serviceId] ?? 0;
              final double percentage =
                  totalOrders > 0 ? count / totalOrders : 0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          service.serviceName,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: textDark,
                          ),
                        ),
                        Text(
                          '$count orders (${(percentage * 100).toStringAsFixed(0)}%)',
                          style: TextStyle(
                            fontSize: 12,
                            color: textMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: percentage,
                        minHeight: 8,
                        backgroundColor: const Color(0xFFE2E8F0),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          primaryBlue,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  String _formatHeaderDate(DateTime date) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
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
    final dayName = days[date.weekday - 1];
    final monthName = months[date.month - 1];
    return '$monthName ${date.day}, ${date.year} • $dayName';
  }
}