import 'package:flutter/material.dart';

import '../models/inventory_transactions.dart';
import '../services/inventory_service.dart';

class InventoryTransactionsPage extends StatefulWidget {
  const InventoryTransactionsPage({super.key});

  @override
  State<InventoryTransactionsPage> createState() =>
      _InventoryTransactionsPageState();
}

class _InventoryTransactionsPageState
    extends State<InventoryTransactionsPage> {
  final InventoryService _inventoryService = InventoryService();

  String selectedFilter = 'All';

  int currentPage = 1;
  static const int transactionsPerPage = 15;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),

      // ================================================================
      // APP BAR
      // ================================================================
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F8FC),
        elevation: 0,
        surfaceTintColor: Colors.transparent,

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.black87,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),

        title: const Text(
          'Inventory Transactions',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      body: StreamBuilder<List<InventoryTransaction>>(
        stream: _inventoryService.getInventoryTransactions(),

        builder: (context, snapshot) {
          // ============================================================
          // LOADING
          // ============================================================

          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // ============================================================
          // ERROR
          // ============================================================

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

                    const Text(
                      'Unable to load transactions.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final transactions = snapshot.data ?? [];

          // ============================================================
          // SUMMARY
          // ============================================================

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

          // ============================================================
          // FILTER
          // ============================================================

          final filteredTransactions =
              transactions.where((transaction) {
            if (selectedFilter == 'IN') {
              return transaction.transactionType == 'IN';
            }

            if (selectedFilter == 'OUT') {
              return transaction.transactionType == 'OUT';
            }

            return true;
          }).toList();

          // ============================================================
          // PAGINATION
          // ============================================================

          final int totalPages = filteredTransactions.isEmpty
              ? 1
              : (filteredTransactions.length / transactionsPerPage).ceil();

          final int effectivePage =
              currentPage > totalPages ? totalPages : currentPage;

          final int startIndex =
              (effectivePage - 1) * transactionsPerPage;

          final int endIndex =
              (startIndex + transactionsPerPage)
                  .clamp(0, filteredTransactions.length);

          final List<InventoryTransaction> paginatedTransactions =
              filteredTransactions.sublist(
            startIndex,
            endIndex,
          );

          return Column(
            children: [
              // ========================================================
              // SUMMARY CARDS
              // ========================================================

              Padding(
                padding: const EdgeInsets.fromLTRB(
                  16,
                  4,
                  16,
                  12,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _SummaryCard(
                        title: 'Stock In',
                        quantity: stockInQuantity,
                        transactionCount: stockInCount,
                        icon: Icons.arrow_downward_rounded,
                        color: Colors.green,
                      ),
                    ),

                    const SizedBox(width: 10),

                    Expanded(
                      child: _SummaryCard(
                        title: 'Stock Out',
                        quantity: stockOutQuantity,
                        transactionCount: stockOutCount,
                        icon: Icons.arrow_upward_rounded,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ),

              // ========================================================
              // FILTERS
              // ========================================================

              Padding(
                padding: const EdgeInsets.fromLTRB(
                  16,
                  0,
                  16,
                  10,
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,

                  child: Row(
                    children: [
                      _TransactionFilterChip(
                        label: 'All',
                        selected: selectedFilter == 'All',
                        onTap: () {
                        setState(() {
                          selectedFilter = 'All';
                          currentPage = 1;
                        });
                      },
                      ),

                      const SizedBox(width: 8),

                      _TransactionFilterChip(
                        label: 'Stock In',
                        icon: Icons.arrow_downward_rounded,
                        color: Colors.green,
                        selected: selectedFilter == 'IN',
                        onTap: () {
                          setState(() {
                            selectedFilter = 'IN';
                            currentPage = 1;

                          });
                        },
                      ),

                      const SizedBox(width: 8),

                      _TransactionFilterChip(
                        label: 'Stock Out',
                        icon: Icons.arrow_upward_rounded,
                        color: Colors.red,
                        selected: selectedFilter == 'OUT',
                        onTap: () {
                          setState(() {
                            selectedFilter = 'OUT';
                            currentPage = 1;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // ========================================================
              // SECTION TITLE
              // ========================================================

              Padding(
                padding: const EdgeInsets.fromLTRB(
                  16,
                  4,
                  16,
                  8,
                ),
                child: Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Recent Transactions',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),

                    Text(
                      '${filteredTransactions.length} '
                      '${filteredTransactions.length == 1 ? 'transaction' : 'transactions'}',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),

              // ========================================================
              // TRANSACTION LIST
              // ========================================================

              Expanded(
                child: filteredTransactions.isEmpty
                    ? _EmptyTransactionsState(
                        filter: selectedFilter,
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(
                          16,
                          2,
                          16,
                          24,
                        ),
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

              // ============================================================
              // PAGINATION CONTROLS
              // ============================================================

              if (filteredTransactions.length > transactionsPerPage)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    16,
                    4,
                    16,
                    16,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // PREVIOUS
                      IconButton(
                        onPressed: effectivePage > 1
                            ? () {
                                setState(() {
                                  currentPage = effectivePage - 1;
                                });
                              }
                            : null,
                        icon: const Icon(
                          Icons.chevron_left_rounded,
                        ),
                      ),

                      const SizedBox(width: 8),

                      // PAGE INDICATOR
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.grey.shade300,
                          ),
                        ),
                        child: Text(
                          'Page $effectivePage of $totalPages',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ),

                      const SizedBox(width: 8),

                      // NEXT
                      IconButton(
                        onPressed: effectivePage < totalPages
                            ? () {
                                setState(() {
                                  currentPage = effectivePage + 1;
                                });
                              }
                            : null,
                        icon: const Icon(
                          Icons.chevron_right_rounded,
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

  const _SummaryCard({
    required this.title,
    required this.quantity,
    required this.transactionCount,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),

      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withValues(alpha: 0.18),
        ),
      ),

      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,

            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),

            child: Icon(
              icon,
              color: color,
              size: 18,
            ),
          ),

          const SizedBox(width: 9),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  '$quantity',
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                Text(
                  '$transactionCount '
                  '${transactionCount == 1 ? 'transaction' : 'transactions'}',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ======================================================================
// FILTER CHIP
// ======================================================================

class _TransactionFilterChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color? color;
  final bool selected;
  final VoidCallback onTap;

  const _TransactionFilterChip({
    required this.label,
    this.icon,
    this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color displayColor =
        color ?? Theme.of(context).colorScheme.primary;

    return GestureDetector(
      onTap: onTap,

      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),

        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 7,
        ),

        decoration: BoxDecoration(
          color: selected
              ? displayColor
              : Colors.white,

          borderRadius: BorderRadius.circular(20),

          border: Border.all(
            color: selected
                ? displayColor
                : Colors.grey.shade300,
          ),
        ),

        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: selected
                    ? Colors.white
                    : displayColor,
              ),

              const SizedBox(width: 5),
            ],

            Text(
              label,
              style: TextStyle(
                color: selected
                    ? Colors.white
                    : Colors.black87,
                fontSize: 11,
                fontWeight: selected
                    ? FontWeight.w600
                    : FontWeight.w400,
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
    final bool isStockIn =
        transaction.transactionType == 'IN';

    final Color transactionColor =
        isStockIn ? Colors.green : Colors.red;

    final IconData transactionIcon =
        isStockIn
            ? Icons.arrow_downward_rounded
            : Icons.arrow_upward_rounded;

    final String transactionTitle =
        isStockIn ? 'Stock Added' : 'Stock Used';

    final String quantityText =
        '${isStockIn ? '+' : '-'}${transaction.quantity}';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),

      padding: const EdgeInsets.all(13),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(15),

        border: Border.all(
          color: Colors.grey.shade200,
        ),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),

      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          // ============================================================
          // ICON
          // ============================================================

          Container(
            width: 42,
            height: 42,

            decoration: BoxDecoration(
              color: transactionColor.withValues(
                alpha: 0.10,
              ),
              shape: BoxShape.circle,
            ),

            child: Icon(
              transactionIcon,
              color: transactionColor,
              size: 20,
            ),
          ),

          const SizedBox(width: 11),

          // ============================================================
          // DETAILS
          // ============================================================

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        transactionTitle,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    const SizedBox(width: 6),

                    Container(
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),

                      decoration: BoxDecoration(
                        color:
                            transactionColor.withValues(
                          alpha: 0.09,
                        ),
                        borderRadius:
                            BorderRadius.circular(10),
                      ),

                      child: Text(
                        transaction.transactionType,
                        style: TextStyle(
                          color: transactionColor,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 5),

                Text(
                  transaction.reason.isEmpty
                      ? 'No reason provided'
                      : transaction.reason,

                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,

                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 11,
                  ),
                ),

                const SizedBox(height: 7),

                Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 12,
                      color: Colors.grey.shade400,
                    ),

                    const SizedBox(width: 4),

                    Text(
                      _formatDate(
                        transaction.transactionDate,
                      ),
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // ============================================================
          // QUANTITY
          // ============================================================

          Column(
            crossAxisAlignment:
                CrossAxisAlignment.end,

            children: [
              Text(
                quantityText,

                style: TextStyle(
                  color: transactionColor,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 3),

              Text(
                isStockIn ? 'added' : 'used',

                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) {
      return 'Date unavailable';
    }

    final monthNames = [
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
      'Dec',
    ];

    final month = monthNames[date.month - 1];

    final hour = date.hour == 0
        ? 12
        : date.hour > 12
            ? date.hour - 12
            : date.hour;

    final minute =
        date.minute.toString().padLeft(2, '0');

    final period =
        date.hour >= 12 ? 'PM' : 'AM';

    return '$month ${date.day}, ${date.year} • '
        '$hour:$minute $period';
  }
}

// ======================================================================
// EMPTY STATE
// ======================================================================

class _EmptyTransactionsState extends StatelessWidget {
  final String filter;

  const _EmptyTransactionsState({
    required this.filter,
  });

  @override
  Widget build(BuildContext context) {
    String title;
    String message;

    if (filter == 'IN') {
      title = 'No Stock In';
      message =
          'Stock additions will appear here.';
    } else if (filter == 'OUT') {
      title = 'No Stock Out';
      message =
          'Stock usage will appear here.';
    } else {
      title = 'No Transactions';
      message =
          'Your inventory activity will appear here.';
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),

        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,

          children: [
            Container(
              width: 70,
              height: 70,

              decoration: BoxDecoration(
                color: Colors.grey.withValues(
                  alpha: 0.08,
                ),
                shape: BoxShape.circle,
              ),

              child: Icon(
                Icons.receipt_long_outlined,
                size: 34,
                color: Colors.grey.shade400,
              ),
            ),

            const SizedBox(height: 16),

            Text(
              title,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 5),

            Text(
              message,
              textAlign: TextAlign.center,

              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}