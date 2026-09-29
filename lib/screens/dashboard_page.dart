import 'package:flutter/material.dart';

import '../models/order.dart';
import '../models/service.dart';
import '../models/inventory.dart';
import '../services/inventory_service.dart';
import '../services/order_service.dart';
import '../services/service_service.dart';

import 'customer_page.dart';
import 'services_page.dart';
import 'orders_page.dart';
import 'inventory_page.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final OrderService orderService = OrderService();
    final ServiceService serviceService = ServiceService();
    final InventoryService inventoryService = InventoryService();

    return Scaffold(
      appBar: AppBar(),
      body: StreamBuilder<List<LaundryOrder>>(
        stream: orderService.getOrders(),
        builder: (context, snapshot) {
          // ============================================================
          // LOADING
          // ============================================================

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // ============================================================
          // ERROR
          // ============================================================

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading dashboard:\n${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            );
          }

          final List<LaundryOrder> orders = snapshot.data ?? [];

          final DateTime now = DateTime.now();

          final DateTime today = DateTime(
            now.year,
            now.month,
            now.day,
          );

          // ============================================================
          // TODAY'S ORDERS
          // ============================================================

          final int todaysOrders = orders.where((order) {
            final DateTime? date = order.orderDate;

            if (date == null) {
              return false;
            }

            return date.year == today.year &&
                date.month == today.month &&
                date.day == today.day;
          }).length;

          // ============================================================
          // PROCESSING ORDERS
          // ============================================================

          final int processingOrders = orders.where((order) {
            return order.orderStatus == 'Processing';
          }).length;

          // ============================================================
          // READY FOR PICKUP
          // ============================================================

          final int readyForPickupOrders = orders.where((order) {
            return order.orderStatus == 'Ready for Pickup';
          }).length;

          // ============================================================
          // PICKED UP TODAY
          // ============================================================

          final int pickedUpToday = orders.where((order) {
            final DateTime? date = order.pickedUpDate;

            if (date == null) {
              return false;
            }

            return date.year == today.year &&
                date.month == today.month &&
                date.day == today.day;
          }).length;

          // ============================================================
          // WEEKLY REVENUE
          // ============================================================

          final DateTime startOfWeek = today.subtract(
            Duration(days: today.weekday - 1),
          );

          final List<double> weeklyRevenue = List<double>.filled(
            7,
            0,
          );

          for (final order in orders) {
            if (order.paymentStatus != 'Paid') {
              continue;
            }

            final DateTime? orderDate = order.orderDate;

            if (orderDate == null) {
              continue;
            }

            final DateTime orderDay = DateTime(
              orderDate.year,
              orderDate.month,
              orderDate.day,
            );

            final int dayDifference =
                orderDay.difference(startOfWeek).inDays;

            if (dayDifference >= 0 && dayDifference < 7) {
              weeklyRevenue[dayDifference] += order.totalAmount;
            }
          }

          final double totalWeeklyRevenue = weeklyRevenue.fold(
            0,
            (sum, amount) => sum + amount,
          );

          // ============================================================
          // RESPONSIVE LAYOUT
          // ============================================================

          return LayoutBuilder(
            builder: (context, constraints) {
              final double screenWidth = constraints.maxWidth;

              int columns;

              if (screenWidth < 600) {
                columns = 2;
              } else if (screenWidth < 900) {
                columns = 3;
              } else {
                columns = 4;
              }

              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 1200,
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ==================================================
                        // HEADER
                        // ==================================================

                        const Text(
                          'Welcome to LaundroMatic!',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 8),

                        const Text(
                          'Manage your laundry operations from here.',
                          style: TextStyle(
                            fontSize: 16,
                          ),
                        ),

                        const SizedBox(height: 30),

                        // ==================================================
                        // TODAY'S OVERVIEW
                        // ==================================================

                        const Text(
                          "Today's Overview",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 15),

                        GridView.count(
                          crossAxisCount: columns,
                          crossAxisSpacing: 15,
                          mainAxisSpacing: 15,
                          childAspectRatio: 1.35,
                          shrinkWrap: true,
                          physics:
                              const NeverScrollableScrollPhysics(),
                          children: [
                            _StatCard(
                              icon: Icons.receipt_long,
                              title: "Today's Orders",
                              value: todaysOrders.toString(),
                            ),

                            _StatCard(
                              icon: Icons.sync,
                              title: 'Processing',
                              value: processingOrders.toString(),
                            ),

                            _StatCard(
                              icon: Icons.inventory_2,
                              title: 'Ready for Pickup',
                              value: readyForPickupOrders.toString(),
                            ),

                            _StatCard(
                              icon: Icons.check_circle,
                              title: 'Picked Up Today',
                              value: pickedUpToday.toString(),
                            ),
                          ],
                        ),

                        const SizedBox(height: 30),

                        // ==================================================
                        // ANALYTICS
                        // ==================================================

                        const Text(
                          'Analytics',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 15),

                        // ==================================================
                        // REVENUE
                        // ==================================================

                        _RevenueCard(
                          weeklyRevenue: weeklyRevenue,
                          totalRevenue: totalWeeklyRevenue,
                          startOfWeek: startOfWeek,
                        ),

                        const SizedBox(height: 20),

                        StreamBuilder<List<InventoryItem>>(
                            stream: inventoryService.getInventory(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Card(
                                  child: Padding(
                                    padding: EdgeInsets.all(24),
                                    child: Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  ),
                                );
                              }

                              if (snapshot.hasError) {
                                return Card(
                                  child: Padding(
                                    padding: const EdgeInsets.all(18),
                                    child: Text(
                                      'Unable to load inventory.',
                                      style: TextStyle(
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                  ),
                                );
                              }

                              final inventory = snapshot.data ?? [];

                              final totalItems = inventory.length;

                              final lowStockItems = inventory
                                  .where((item) => item.status == 'Low Stock')
                                  .length;

                              final outOfStockItems = inventory
                                  .where((item) => item.status == 'Out of Stock')
                                  .length;

                              return Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(18),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // TITLE
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.inventory_2_outlined,
                                            size: 24,
                                          ),
                                          const SizedBox(width: 10),
                                          const Text(
                                            'Inventory Overview',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 16),

                                      // INVENTORY STATS
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _InventoryStat(
                                              icon: Icons.inventory_2,
                                              title: 'Items',
                                              value: totalItems.toString(),
                                            ),
                                          ),

                                          const SizedBox(width: 10),

                                          Expanded(
                                            child: _InventoryStat(
                                              icon: Icons.warning_amber_rounded,
                                              title: 'Low Stock',
                                              value: lowStockItems.toString(),
                                            ),
                                          ),

                                          const SizedBox(width: 10),

                                          Expanded(
                                            child: _InventoryStat(
                                              icon: Icons.error_outline,
                                              title: 'Out of Stock',
                                              value: outOfStockItems.toString(),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),


                        const SizedBox(height: 20),

                        // ==================================================
                        // ORDERS BY SERVICE
                        // ==================================================

                        StreamBuilder<List<LaundryService>>(
                          stream: serviceService.getServices(),
                          builder: (context, serviceSnapshot) {
                            if (serviceSnapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Card(
                                child: Padding(
                                  padding: EdgeInsets.all(30),
                                  child: Center(
                                    child:
                                        CircularProgressIndicator(),
                                  ),
                                ),
                              );
                            }

                            if (serviceSnapshot.hasError) {
                              return Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Text(
                                    'Error loading services:\n'
                                    '${serviceSnapshot.error}',
                                  ),
                                ),
                              );
                            }

                            final List<LaundryService> services =
                                serviceSnapshot.data ?? [];

                            return _OrdersByServiceCard(
                              orders: orders,
                              services: services,
                            );
                          },
                        ),

                        const SizedBox(height: 30),

                        // ==================================================
                        // QUICK ACCESS
                        // ==================================================

                        const Text(
                          'Quick Access',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 15),

                        GridView.count(
                          crossAxisCount: columns,
                          crossAxisSpacing: 15,
                          mainAxisSpacing: 15,
                          childAspectRatio: 1.15,
                          shrinkWrap: true,
                          physics:
                              const NeverScrollableScrollPhysics(),
                          children: [
                            // ORDERS
                            _DashboardCard(
                              icon: Icons.receipt_long,
                              title: 'Orders',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const OrdersPage(),
                                  ),
                                );
                              },
                            ),

                            // CUSTOMERS
                            _DashboardCard(
                              icon: Icons.people,
                              title: 'Customers',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const CustomerPage(),
                                  ),
                                );
                              },
                            ),

                            // SERVICES
                            _DashboardCard(
                              icon: Icons.local_laundry_service,
                              title: 'Services',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const ServicesPage(),
                                  ),
                                );
                              },
                            ),

                            // INVENTORY
                            _DashboardCard(
                              icon: Icons.inventory_2,
                              title: 'Inventory',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const InventoryPage(),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ======================================================================
// ORDERS BY SERVICE
// ======================================================================

class _OrdersByServiceCard extends StatelessWidget {
  final List<LaundryOrder> orders;
  final List<LaundryService> services;

  const _OrdersByServiceCard({
    required this.orders,
    required this.services,
  });

  @override
  Widget build(BuildContext context) {
    final Map<String, int> serviceCounts = {};

    // Count orders for each service.
    for (final service in services) {
      serviceCounts[service.serviceId] = 0;
    }

    for (final order in orders) {
      if (serviceCounts.containsKey(order.serviceId)) {
        serviceCounts[order.serviceId] =
            serviceCounts[order.serviceId]! + 1;
      }
    }

    final int totalOrders = orders.length;

    // Sort services from most used to least used.
    final List<LaundryService> sortedServices =
        List<LaundryService>.from(services);

    sortedServices.sort(
      (a, b) {
        final int countA = serviceCounts[a.serviceId] ?? 0;
        final int countB = serviceCounts[b.serviceId] ?? 0;

        return countB.compareTo(countA);
      },
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ----------------------------------------------------------
            // TITLE
            // ----------------------------------------------------------

            Row(
              children: [
                const Icon(
                  Icons.pie_chart,
                  size: 28,
                ),

                const SizedBox(width: 10),

                const Text(
                  'Orders by Service',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ----------------------------------------------------------
            // NO ORDERS
            // ----------------------------------------------------------

            if (totalOrders == 0)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'No orders available yet.',
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),

            // ----------------------------------------------------------
            // SERVICE LIST
            // ----------------------------------------------------------

            if (totalOrders > 0)
              ...sortedServices.map(
                (service) {
                  final int count =
                      serviceCounts[service.serviceId] ?? 0;

                  final double percentage =
                      count / totalOrders;

                  return Padding(
                    padding: const EdgeInsets.only(
                      bottom: 16,
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                service.serviceName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),

                            Text(
                              '$count orders',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),

                            const SizedBox(width: 8),

                            SizedBox(
                              width: 45,
                              child: Text(
                                '${(percentage * 100).toStringAsFixed(0)}%',
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 7),

                        // Progress bar
                        ClipRRect(
                          borderRadius:
                              BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: percentage,
                            minHeight: 10,
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
    );
  }
}

// ======================================================================
// REVENUE CARD
// ======================================================================

class _RevenueCard extends StatelessWidget {
  final List<double> weeklyRevenue;
  final double totalRevenue;
  final DateTime startOfWeek;

  const _RevenueCard({
    required this.weeklyRevenue,
    required this.totalRevenue,
    required this.startOfWeek,
  });

  @override
  Widget build(BuildContext context) {
    double maxRevenue = 0;

    for (final amount in weeklyRevenue) {
      if (amount > maxRevenue) {
        maxRevenue = amount;
      }
    }

    if (maxRevenue == 0) {
      maxRevenue = 1;
    }

    const List<String> dayLabels = [
      'Mon',
      'Tue',
      'Wed',
      'Thu',
      'Fri',
      'Sat',
      'Sun',
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.bar_chart,
                  size: 28,
                ),

                const SizedBox(width: 10),

                const Text(
                  'Revenue',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const Spacer(),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.grey.shade300,
                    ),
                  ),
                  child: const Text(
                    'This Week',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            Text(
              '₱${totalRevenue.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 4),

            const Text(
              'Total Revenue This Week',
              style: TextStyle(
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 25),

            SizedBox(
              height: 180,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(
                  7,
                  (index) {
                    final double amount =
                        weeklyRevenue[index];

                    final double barHeight =
                        amount == 0
                            ? 4
                            : (amount / maxRevenue) * 120;

                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                        ),
                        child: Column(
                          mainAxisAlignment:
                              MainAxisAlignment.end,
                          children: [
                            if (amount > 0)
                              Text(
                                '₱${amount.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),

                            const SizedBox(height: 5),

                            Container(
                              height: barHeight,
                              decoration: BoxDecoration(
                                borderRadius:
                                    const BorderRadius.vertical(
                                  top: Radius.circular(6),
                                ),
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary,
                              ),
                            ),

                            const SizedBox(height: 7),

                            Text(
                              dayLabels[index],
                              style: const TextStyle(
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 8),

            Text(
              '${_formatDate(startOfWeek)} - '
              '${_formatDate(startOfWeek.add(
                const Duration(days: 6),
              ))}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}';
  }
}

// ======================================================================
// STATISTICS CARD
// ======================================================================

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 30,
            ),

            const SizedBox(height: 8),

            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 4),

            Text(
              value,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ======================================================================
// QUICK ACCESS CARD
// ======================================================================

class _DashboardCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _DashboardCard({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 40,
              ),

              const SizedBox(height: 12),

              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InventoryStat extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InventoryStat({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 22,
          ),

          const SizedBox(height: 8),

          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 2),

          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}