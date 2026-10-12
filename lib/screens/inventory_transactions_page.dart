import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../controllers/theme_controller.dart';
import '../models/inventory_transactions.dart';
import '../services/inventory_service.dart';
import 'dashboard_page.dart';
import 'inventory_page.dart';
import 'orders_page.dart';
import 'more_page.dart';

class InventoryTransactionsPage extends StatefulWidget {
  const InventoryTransactionsPage({super.key});

  @override
  State<InventoryTransactionsPage> createState() =>
      _InventoryTransactionsPageState();
}

class _InventoryTransactionsPageState
    extends State<InventoryTransactionsPage> {
  final InventoryService _inventoryService = InventoryService();
  final TextEditingController _searchController = TextEditingController();

  String selectedFilter = 'All';
  String _searchQuery = '';
  int currentPage = 1;
  static const int transactionsPerPage = 15;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

        Widget transactionsContent = Scaffold(
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
              'Transactions',
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
              child: StreamBuilder<List<InventoryTransaction>>(
                stream: _inventoryService.getInventoryTransactions(),
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
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.error_outline_rounded,
                              size: 48,
                              color: Colors.red.shade300,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Unable to load transactions.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: textDark,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${snapshot.error}',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: colors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final transactions = snapshot.data ?? [];

                  int stockInQuantity = 0;
                  int stockOutQuantity = 0;
                  int stockInCount = 0;
                  int stockOutCount = 0;

                  for (final transaction in transactions) {
                    if (transaction.transactionType == 'IN') {
                      stockInQuantity += transaction.quantity;
                      stockInCount++;
                    } else if (transaction.transactionType == 'OUT') {
                      stockOutQuantity += transaction.quantity;
                      stockOutCount++;
                    }
                  }

                  final filteredTransactions = transactions.where((transaction) {
                    if (selectedFilter == 'IN') {
                      if (transaction.transactionType != 'IN') return false;
                    } else if (selectedFilter == 'OUT') {
                      if (transaction.transactionType != 'OUT') return false;
                    }

                    if (_searchQuery.isNotEmpty) {
                      final reasonMatches = transaction.reason
                          .toLowerCase()
                          .contains(_searchQuery);
                      final orderMatches = transaction.orderId != null &&
                          transaction.orderId!
                              .toLowerCase()
                              .contains(_searchQuery);
                      final idMatches = transaction.transactionId
                          .toLowerCase()
                          .contains(_searchQuery);
                      if (!reasonMatches && !orderMatches && !idMatches) {
                        return false;
                      }
                    }

                    return true;
                  }).toList();

                  final int totalPages = filteredTransactions.isEmpty
                      ? 1
                      : (filteredTransactions.length / transactionsPerPage).ceil();

                  final int effectivePage =
                      currentPage > totalPages ? totalPages : currentPage;

                  final int startIndex =
                      (effectivePage - 1) * transactionsPerPage;

                  final int endIndex = (startIndex + transactionsPerPage)
                      .clamp(0, filteredTransactions.length);

                  final List<InventoryTransaction> paginatedTransactions =
                      filteredTransactions.sublist(
                    startIndex,
                    endIndex,
                  );

                  return Column(
                    children: [
                      // Search Bar
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                        child: TextField(
                          controller: _searchController,
                          style: TextStyle(color: textDark, fontSize: 13.5),
                          decoration: InputDecoration(
                            hintText: 'Search transactions by reason, order ID...',
                            hintStyle: TextStyle(
                                color: colors.textSecondary, fontSize: 13.5),
                            prefixIcon: Icon(Icons.search_rounded,
                                color: colors.textSecondary, size: 21),
                            suffixIcon: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_searchQuery.isNotEmpty)
                                  IconButton(
                                    icon: Icon(Icons.clear_rounded,
                                        color: colors.textSecondary, size: 18),
                                    splashRadius: 18,
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {
                                        _searchQuery = '';
                                        currentPage = 1;
                                      });
                                    },
                                  ),
                                PopupMenuButton<String>(
                                  tooltip: selectedFilter == 'All'
                                      ? 'Filter transactions'
                                      : 'Filter: ${selectedFilter == 'IN' ? 'Stock In' : 'Stock Out'}',
                                  offset: const Offset(0, 45),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    side: BorderSide(color: colors.border),
                                  ),
                                  color: colors.cardBg,
                                  elevation: 6,
                                  onSelected: (val) {
                                    setState(() {
                                      selectedFilter = val;
                                      currentPage = 1;
                                    });
                                  },
                                  itemBuilder: (context) {
                                    return [
                                      PopupMenuItem<String>(
                                        value: 'All',
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                'All (${transactions.length})',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: selectedFilter == 'All'
                                                      ? FontWeight.bold
                                                      : FontWeight.w500,
                                                  color: selectedFilter == 'All'
                                                      ? colors.primary
                                                      : colors.textPrimary,
                                                ),
                                              ),
                                            ),
                                            if (selectedFilter == 'All')
                                              Icon(Icons.check_rounded,
                                                  size: 18, color: colors.primary),
                                          ],
                                        ),
                                      ),
                                      PopupMenuItem<String>(
                                        value: 'IN',
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 8,
                                              height: 8,
                                              decoration: BoxDecoration(
                                                color: colors.successText,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                'Stock In ($stockInCount)',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: selectedFilter == 'IN'
                                                      ? FontWeight.bold
                                                      : FontWeight.w500,
                                                  color: selectedFilter == 'IN'
                                                      ? colors.primary
                                                      : colors.textPrimary,
                                                ),
                                              ),
                                            ),
                                            if (selectedFilter == 'IN')
                                              Icon(Icons.check_rounded,
                                                  size: 18, color: colors.primary),
                                          ],
                                        ),
                                      ),
                                      PopupMenuItem<String>(
                                        value: 'OUT',
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 8,
                                              height: 8,
                                              decoration: BoxDecoration(
                                                color: colors.errorText,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                'Stock Out ($stockOutCount)',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: selectedFilter == 'OUT'
                                                      ? FontWeight.bold
                                                      : FontWeight.w500,
                                                  color: selectedFilter == 'OUT'
                                                      ? colors.primary
                                                      : colors.textPrimary,
                                                ),
                                              ),
                                            ),
                                            if (selectedFilter == 'OUT')
                                              Icon(Icons.check_rounded,
                                                  size: 18, color: colors.primary),
                                          ],
                                        ),
                                      ),
                                    ];
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.only(right: 8, left: 2),
                                    padding: const EdgeInsets.all(7),
                                    decoration: BoxDecoration(
                                      color: selectedFilter != 'All'
                                          ? colors.primary
                                          : colors.primary.withValues(
                                              alpha: colors.isDark ? 0.22 : 0.10),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      Icons.tune_rounded,
                                      size: 18,
                                      color: selectedFilter != 'All'
                                          ? Colors.white
                                          : colors.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            filled: true,
                            fillColor: colors.cardBg,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide:
                                  BorderSide(color: colors.border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide:
                                  BorderSide(color: colors.border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                  color: primaryBlue, width: 1.5),
                            ),
                          ),
                          onChanged: (val) {
                            setState(() {
                              _searchQuery = val.trim().toLowerCase();
                              currentPage = 1;
                            });
                          },
                        ),
                      ),

                      // Summary Cards
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                        child: Row(
                          children: [
                            Expanded(
                              child: _SummaryCard(
                                title: 'Stock In',
                                quantity: stockInQuantity,
                                transactionCount: stockInCount,
                                icon: Icons.south_west_rounded,
                                color: colors.successText,
                                isSelected: selectedFilter == 'IN',
                                onTap: () {
                                  setState(() {
                                    selectedFilter =
                                        selectedFilter == 'IN' ? 'All' : 'IN';
                                    currentPage = 1;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _SummaryCard(
                                title: 'Stock Out',
                                quantity: stockOutQuantity,
                                transactionCount: stockOutCount,
                                icon: Icons.north_east_rounded,
                                color: colors.errorText,
                                isSelected: selectedFilter == 'OUT',
                                onTap: () {
                                  setState(() {
                                    selectedFilter =
                                        selectedFilter == 'OUT' ? 'All' : 'OUT';
                                    currentPage = 1;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Active Filter Badge (if IN or OUT is selected)
                      if (selectedFilter != 'All')
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                          child: Row(
                            children: [
                              Text(
                                'Filtered by: ',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colors.textSecondary,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 9, vertical: 3),
                                decoration: BoxDecoration(
                                  color: (selectedFilter == 'IN'
                                          ? colors.successText
                                          : colors.errorText)
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: (selectedFilter == 'IN'
                                            ? colors.successText
                                            : colors.errorText)
                                        .withValues(alpha: 0.25),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      selectedFilter == 'IN'
                                          ? Icons.south_west_rounded
                                          : Icons.north_east_rounded,
                                      size: 13,
                                      color: selectedFilter == 'IN'
                                          ? colors.successText
                                          : colors.errorText,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      selectedFilter == 'IN'
                                          ? 'Stock In'
                                          : 'Stock Out',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.bold,
                                        color: selectedFilter == 'IN'
                                            ? colors.successText
                                            : colors.errorText,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    InkWell(
                                      onTap: () {
                                        setState(() {
                                          selectedFilter = 'All';
                                          currentPage = 1;
                                        });
                                      },
                                      child: Icon(
                                        Icons.close_rounded,
                                        size: 14,
                                        color: selectedFilter == 'IN'
                                            ? colors.successText
                                            : colors.errorText,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Section Title & Count
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Recent Transactions',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: textDark,
                              ),
                            ),
                            Text(
                              '${filteredTransactions.length} records',
                              style: TextStyle(
                                color: colors.textMuted,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Transaction List
                      Expanded(
                        child: filteredTransactions.isEmpty
                            ? _EmptyTransactionsState(
                                filter: selectedFilter,
                                searchQuery: _searchQuery,
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.fromLTRB(16, 2, 16, 12),
                                itemCount: paginatedTransactions.length,
                                itemBuilder: (context, index) {
                                  final transaction =
                                      paginatedTransactions[index];
                                  return _TransactionCard(
                                    transaction: transaction,
                                  );
                                },
                              ),
                      ),

                      // Main Pagination Controls in the bottom part
                      if (totalPages > 1)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: colors.cardBg,
                            border: Border(
                              top:
                                  BorderSide(color: colors.border, width: 1),
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
                                icon: const Icon(Icons.chevron_left_rounded),
                                color: primaryBlue,
                                disabledColor: colors.textMuted,
                              ),
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 6),
                                decoration: BoxDecoration(
                                  color: colors.subCardBg,
                                  borderRadius: BorderRadius.circular(20),
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
                                icon: const Icon(Icons.chevron_right_rounded),
                                color: primaryBlue,
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
          ),

          // Persistent Bottom Navigation Bar matching all other screens
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: colors.cardBg,
              border: Border(
                top: BorderSide(color: colors.border, width: 1),
              ),
            ),
            child: BottomNavigationBar(
              currentIndex: 3, // Transactions tab is active
              onTap: (index) {
                if (index == 3) return;
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
                      child: transactionsContent,
                    ),
                  ),
                ),
              );
            }
            return transactionsContent;
          },
        );
      },
    );
  }
}

// ======================================================================
// SUMMARY CARD
// ======================================================================

class _SummaryCard extends StatelessWidget {
  final String title;
  final int quantity;
  final int transactionCount;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _SummaryCard({
    required this.title,
    required this.quantity,
    required this.transactionCount,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = ThemeController.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: colors.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : colors.border,
            width: isSelected ? 1.8 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: colors.isDark ? 0.2 : 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: colors.isDark ? 0.22 : 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: color,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$quantity',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '$transactionCount transactions',
                    style: TextStyle(
                      color: colors.textMuted,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// ======================================================================
// TRANSACTION CARD
// ======================================================================

class _TransactionCard extends StatelessWidget {
  final InventoryTransaction transaction;

  const _TransactionCard({
    required this.transaction,
  });

  @override
  Widget build(BuildContext context) {
    final colors = ThemeController.of(context);
    final bool isStockIn = transaction.transactionType == 'IN';
    final Color transactionColor =
        isStockIn ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    final IconData transactionIcon = isStockIn
        ? Icons.south_west_rounded
        : Icons.north_east_rounded;
    final String transactionTitle =
        isStockIn ? 'Stock Added' : 'Stock Deducted';
    final String quantityText =
        '${isStockIn ? '+' : '-'}${transaction.quantity}';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: colors.isDark ? 0.2 : 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: transactionColor.withValues(alpha: colors.isDark ? 0.2 : 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              transactionIcon,
              color: transactionColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      transactionTitle,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: transactionColor.withValues(alpha: colors.isDark ? 0.2 : 0.10),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        transaction.transactionType,
                        style: TextStyle(
                          color: transactionColor,
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  transaction.reason.isEmpty
                      ? 'No reason specified'
                      : transaction.reason,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                if (transaction.orderId != null &&
                    transaction.orderId!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Order #${transaction.orderId!.length > 6 ? transaction.orderId!.substring(0, 6) : transaction.orderId!}',
                    style: TextStyle(
                      color: colors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  _formatDate(transaction.transactionDate),
                  style: TextStyle(
                    color: colors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                quantityText,
                style: TextStyle(
                  color: transactionColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                isStockIn ? 'units in' : 'units out',
                style: TextStyle(
                  color: colors.textMuted,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Date unavailable';

    const monthNames = [
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

    final month = monthNames[date.month - 1];
    final hour = date.hour == 0
        ? 12
        : date.hour > 12
            ? date.hour - 12
            : date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';

    return '$month ${date.day}, ${date.year} • $hour:$minute $period';
  }
}

// ======================================================================
// EMPTY STATE
// ======================================================================

class _EmptyTransactionsState extends StatelessWidget {
  final String filter;
  final String searchQuery;

  const _EmptyTransactionsState({
    required this.filter,
    required this.searchQuery,
  });

  @override
  Widget build(BuildContext context) {
    final colors = ThemeController.of(context);
    String title;
    String message;
    IconData icon;

    if (searchQuery.isNotEmpty) {
      title = 'No Matching Records';
      message = 'No transactions match "$searchQuery"';
      icon = Icons.search_off_rounded;
    } else if (filter == 'IN') {
      title = 'No Stock In';
      message = 'Stock additions will appear here.';
      icon = Icons.south_west_rounded;
    } else if (filter == 'OUT') {
      title = 'No Stock Out';
      message = 'Stock usage will appear here.';
      icon = Icons.north_east_rounded;
    } else {
      title = 'No Transactions';
      message = 'Your inventory transaction history will appear here.';
      icon = Icons.receipt_long_outlined;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 48,
              color: colors.textMuted.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}