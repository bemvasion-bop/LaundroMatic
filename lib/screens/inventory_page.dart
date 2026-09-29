import 'package:flutter/material.dart';

import '../models/inventory.dart';
import '../services/inventory_service.dart';
import 'inventory_transactions_page.dart';

class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  final InventoryService _inventoryService = InventoryService();

  String selectedFilter = 'All';

  // ================================================================
  // ADD / EDIT INVENTORY DIALOG
  // ================================================================

  void _showInventoryDialog({InventoryItem? item}) {
    final bool isEditing = item != null;

    final itemNameController =
        TextEditingController(text: item?.itemName ?? '');

    final brandController =
        TextEditingController(text: item?.brand ?? '');

    final scentController =
        TextEditingController(text: item?.scent ?? '');

    final sizeController =
        TextEditingController(text: item?.size ?? '');

    // Quantity is ONLY needed when adding a new item.
    final quantityController = TextEditingController();

    final unitController =
        TextEditingController(text: item?.unit ?? '');

    final priceController = TextEditingController(
      text: item?.pricePerUnit.toString() ?? '',
    );

    final minimumStockController = TextEditingController(
      text: item?.minimumStock.toString() ?? '',
    );

    final imageUrlController =
        TextEditingController(text: item?.imageUrl ?? '');

    String selectedItemType = item?.itemType ?? 'Detergent';

    Future<void> saveItem(BuildContext dialogContext) async {
      final String itemName = itemNameController.text.trim();
      final String brand = brandController.text.trim();
      final String scent = scentController.text.trim();
      final String size = sizeController.text.trim();

      // When editing, keep the existing quantity.
      // When adding, read the quantity from the field.
      final int? enteredQuantity = isEditing
          ? item.quantity
          : int.tryParse(quantityController.text.trim());

      final String unit = unitController.text.trim();

      final double? price =
          double.tryParse(priceController.text.trim());

      final int? minimumStock =
          int.tryParse(minimumStockController.text.trim());

      final String imageUrl =
          imageUrlController.text.trim();

      // ------------------------------------------------------------
      // VALIDATION
      // ------------------------------------------------------------

      if (itemName.isEmpty ||
          enteredQuantity == null ||
          enteredQuantity < 0 ||
          unit.isEmpty ||
          price == null ||
          price < 0 ||
          minimumStock == null ||
          minimumStock < 0) {
        if (dialogContext.mounted) {
          ScaffoldMessenger.of(dialogContext).showSnackBar(
            const SnackBar(
              content: Text(
                'Please enter valid inventory information.',
              ),
            ),
          );
        }

        return;
      }

      try {
        // ----------------------------------------------------------
        // EDIT EXISTING ITEM
        // ----------------------------------------------------------

        if (isEditing) {
          await _inventoryService.updateInventoryItem(
            inventoryId: item.inventoryId,
            itemName: itemName,
            brand: brand,
            scent: scent,
            itemType: selectedItemType,
            size: size,
            quantity: enteredQuantity,
            unit: unit,
            pricePerUnit: price,
            minimumStock: minimumStock,
            imageUrl: imageUrl,
          );
        }

        // ----------------------------------------------------------
        // ADD NEW ITEM
        // ----------------------------------------------------------

        else {
          await _inventoryService.addInventoryItem(
            itemName: itemName,
            brand: brand,
            scent: scent,
            itemType: selectedItemType,
            size: size,
            quantity: enteredQuantity,
            unit: unit,
            pricePerUnit: price,
            minimumStock: minimumStock,
            imageUrl: imageUrl,
          );
        }

        if (!mounted) return;

        if (dialogContext.mounted) {
          Navigator.of(dialogContext).pop();
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEditing
                  ? 'Inventory item updated.'
                  : 'Inventory item added.',
            ),
          ),
        );
      } catch (e) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error saving inventory item: $e',
            ),
          ),
        );
      }
    }

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                isEditing
                    ? 'Edit Inventory Item'
                    : 'Add Inventory Item',
              ),

              content: SingleChildScrollView(
                child: SizedBox(
                  width: 450,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ------------------------------------------------
                      // ITEM NAME
                      // ------------------------------------------------

                      TextField(
                        controller: itemNameController,
                        decoration: const InputDecoration(
                          labelText: 'Item Name',
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // ------------------------------------------------
                      // ITEM TYPE
                      // ------------------------------------------------

                      DropdownButtonFormField<String>(
                        initialValue: selectedItemType,
                        decoration: const InputDecoration(
                          labelText: 'Item Type',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'Detergent',
                            child: Text('Detergent'),
                          ),
                          DropdownMenuItem(
                            value: 'Fabric Conditioner',
                            child: Text('Fabric Conditioner'),
                          ),
                          DropdownMenuItem(
                            value: 'Plastic Bag',
                            child: Text('Plastic Bag'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() {
                              selectedItemType = value;
                            });
                          }
                        },
                      ),

                      const SizedBox(height: 12),

                      // ------------------------------------------------
                      // BRAND
                      // ------------------------------------------------

                      TextField(
                        controller: brandController,
                        decoration: const InputDecoration(
                          labelText: 'Brand',
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // ------------------------------------------------
                      // SCENT
                      // ------------------------------------------------

                      TextField(
                        controller: scentController,
                        decoration: const InputDecoration(
                          labelText: 'Scent / Variety',
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // ------------------------------------------------
                      // SIZE
                      // ------------------------------------------------

                      TextField(
                        controller: sizeController,
                        decoration: const InputDecoration(
                          labelText: 'Size',
                          border: OutlineInputBorder(),
                          hintText: 'e.g. Small, Medium, 50g',
                        ),
                      ),

                      const SizedBox(height: 12),

                      // ------------------------------------------------
                      // QUANTITY
                      // ONLY SHOW WHEN ADDING
                      // ------------------------------------------------

                      if (!isEditing) ...[
                        TextField(
                          controller: quantityController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Initial Quantity',
                            border: OutlineInputBorder(),
                            hintText: 'e.g. 50',
                          ),
                        ),

                        const SizedBox(height: 12),
                      ],

                      // ------------------------------------------------
                      // UNIT
                      // ------------------------------------------------

                      TextField(
                        controller: unitController,
                        decoration: const InputDecoration(
                          labelText: 'Unit',
                          border: OutlineInputBorder(),
                          hintText: 'e.g. sachets, pieces',
                        ),
                      ),

                      const SizedBox(height: 12),

                      // ------------------------------------------------
                      // PRICE
                      // ------------------------------------------------

                      TextField(
                        controller: priceController,
                        keyboardType:
                            const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Price per Unit',
                          border: OutlineInputBorder(),
                          prefixText: '₱ ',
                        ),
                      ),

                      const SizedBox(height: 12),

                      // ------------------------------------------------
                      // MINIMUM STOCK
                      // ------------------------------------------------

                      TextField(
                        controller: minimumStockController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Minimum Stock',
                          border: OutlineInputBorder(),
                          hintText:
                              'Alert when stock reaches this level',
                        ),
                      ),

                      const SizedBox(height: 12),

                      // ------------------------------------------------
                      // IMAGE URL
                      // ------------------------------------------------

                      TextField(
                        controller: imageUrlController,
                        decoration: const InputDecoration(
                          labelText: 'Image URL',
                          border: OutlineInputBorder(),
                          hintText: 'Optional',
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Cancel'),
                ),

                ElevatedButton(
                  onPressed: () => saveItem(dialogContext),
                  child: Text(
                    isEditing ? 'Update' : 'Add',
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ================================================================
  // ADD STOCK
  // ================================================================

  void _showAddStockDialog(InventoryItem item) {
    final quantityController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Add Stock'),

          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.itemName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                'Current stock: ${item.quantity} ${item.unit}',
                style: TextStyle(
                  color: Colors.grey.shade600,
                ),
              ),

              const SizedBox(height: 20),

              TextField(
                controller: quantityController,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Quantity to Add',
                  hintText: 'e.g. 20',
                  suffixText: item.unit,
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Cancel'),
            ),

            ElevatedButton(
              onPressed: () async {
                final int? quantityToAdd =
                    int.tryParse(
                  quantityController.text.trim(),
                );

                if (quantityToAdd == null ||
                    quantityToAdd <= 0) {
                  if (dialogContext.mounted) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Please enter a valid quantity.',
                        ),
                      ),
                    );
                  }

                  return;
                }

                try {
                  await _inventoryService.addStock(
                    inventoryId: item.inventoryId,
                    quantityToAdd: quantityToAdd,
                  );

                  if (!mounted) return;

                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext).pop();
                  }

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '$quantityToAdd ${item.unit} added to ${item.itemName}.',
                      ),
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Error adding stock: $e',
                      ),
                    ),
                  );
                }
              },
              child: const Text('Add Stock'),
            ),
          ],
        );
      },
    );
  }

  // ================================================================
  // DELETE
  // ================================================================

  void _confirmDelete(InventoryItem item) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Inventory Item'),

          content: Text(
            'Are you sure you want to delete '
            '${item.itemName}?',
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Cancel'),
            ),

            ElevatedButton(
              onPressed: () async {
                try {
                  await _inventoryService.deleteInventoryItem(
                    item.inventoryId,
                  );

                  if (!mounted) return;

                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext).pop();
                  }

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Inventory item deleted.',
                      ),
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Error deleting item: $e',
                      ),
                    ),
                  );
                }
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  // ================================================================
  // STATUS
  // ================================================================

  String _getStockStatus(InventoryItem item) {
    if (item.quantity == 0) {
      return 'Out of Stock';
    }

    if (item.quantity <= item.minimumStock) {
      return 'Low Stock';
    }

    return 'In Stock';
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Out of Stock':
        return Colors.red;

      case 'Low Stock':
        return Colors.orange;

      default:
        return Colors.green;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Out of Stock':
        return Icons.error_outline;

      case 'Low Stock':
        return Icons.warning_amber_rounded;

      default:
        return Icons.check_circle_outline;
    }
  }

  // ================================================================
  // FILTER
  // ================================================================

  List<InventoryItem> _filterInventory(
    List<InventoryItem> inventory,
  ) {
    if (selectedFilter == 'Low Stock') {
      return inventory.where((item) {
        return item.quantity > 0 &&
            item.quantity <= item.minimumStock;
      }).toList();
    }

    if (selectedFilter == 'Out of Stock') {
      return inventory.where((item) {
        return item.quantity == 0;
      }).toList();
    }

    return inventory;
  }

  // ================================================================
  // BUILD
  // ================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory'),
        actions: [
        IconButton(
          tooltip: 'Inventory Transactions',
          icon: const Icon(
            Icons.history_rounded,
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    const InventoryTransactionsPage(),
              ),
            );
          },
        ),
      ],
      ),

      body: StreamBuilder<List<InventoryItem>>(
        stream: _inventoryService.getInventory(),

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
                'Error loading inventory: ${snapshot.error}',
              ),
            );
          }

          final inventory = snapshot.data ?? [];

          final lowStockItems = inventory.where((item) {
            return item.quantity > 0 &&
                item.quantity <= item.minimumStock;
          }).toList();

          final outOfStockItems = inventory.where((item) {
            return item.quantity == 0;
          }).toList();

          final filteredInventory =
              _filterInventory(inventory);

          return RefreshIndicator(
            onRefresh: () async {
              await Future.delayed(
                const Duration(milliseconds: 300),
              );
            },

            child: ListView(
              padding: const EdgeInsets.all(16),

              children: [
                // ------------------------------------------------
                // ALERT SUMMARY
                // ------------------------------------------------

                Row(
                  children: [
                    Expanded(
                      child: _StockSummaryCard(
                        icon: Icons.warning_amber_rounded,
                        title: 'Low Stock',
                        count: lowStockItems.length,
                        color: Colors.orange,
                        onTap: () {
                          setState(() {
                            selectedFilter = 'Low Stock';
                          });
                        },
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: _StockSummaryCard(
                        icon: Icons.error_outline,
                        title: 'Out of Stock',
                        count: outOfStockItems.length,
                        color: Colors.red,
                        onTap: () {
                          setState(() {
                            selectedFilter = 'Out of Stock';
                          });
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ------------------------------------------------
                // FILTERS
                // ------------------------------------------------

                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,

                  child: Row(
                    children: [
                      _FilterChip(
                        label: 'All',
                        selected: selectedFilter == 'All',
                        onTap: () {
                          setState(() {
                            selectedFilter = 'All';
                          });
                        },
                      ),

                      const SizedBox(width: 8),

                      _FilterChip(
                        label: 'Low Stock',
                        count: lowStockItems.length,
                        selected:
                            selectedFilter == 'Low Stock',
                        color: Colors.orange,
                        onTap: () {
                          setState(() {
                            selectedFilter = 'Low Stock';
                          });
                        },
                      ),

                      const SizedBox(width: 8),

                      _FilterChip(
                        label: 'Out of Stock',
                        count: outOfStockItems.length,
                        selected:
                            selectedFilter == 'Out of Stock',
                        color: Colors.red,
                        onTap: () {
                          setState(() {
                            selectedFilter = 'Out of Stock';
                          });
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ------------------------------------------------
                // EMPTY STATE
                // ------------------------------------------------

                if (filteredInventory.isEmpty)
                  _EmptyInventoryState(
                    filter: selectedFilter,
                  ),

                // ------------------------------------------------
                // INVENTORY LIST
                // ------------------------------------------------

                ...filteredInventory.map(
                  (item) {
                    final currentStatus =
                        _getStockStatus(item);

                    return _InventoryCard(
                      item: item,
                      status: currentStatus,
                      statusColor:
                          _getStatusColor(currentStatus),
                      statusIcon:
                          _getStatusIcon(currentStatus),

                      onAddStock: () {
                        _showAddStockDialog(item);
                      },

                      onEdit: () {
                        _showInventoryDialog(item: item);
                      },

                      onDelete: () {
                        _confirmDelete(item);
                      },
                    );
                  },
                ),

                const SizedBox(height: 90),
              ],
            ),
          );
        },
      ),

      floatingActionButton:
          FloatingActionButton.extended(
        onPressed: () {
          _showInventoryDialog();
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Item'),
      ),
    );
  }
}

// ================================================================
// STOCK SUMMARY CARD
// ================================================================

class _StockSummaryCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final int count;
  final Color color;
  final VoidCallback onTap;

  const _StockSummaryCard({
    required this.icon,
    required this.title,
    required this.count,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),

      child: Container(
        padding: const EdgeInsets.all(16),

        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: 0.20),
          ),
        ),

        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),

              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),

              child: Icon(
                icon,
                color: color,
                size: 20,
              ),
            ),

            const SizedBox(width: 10),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 3),

                  Text(
                    '$count',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
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

// ================================================================
// FILTER CHIP
// ================================================================

class _FilterChip extends StatelessWidget {
  final String label;
  final int? count;
  final bool selected;
  final Color? color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    this.count,
    required this.selected,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final displayColor =
        color ?? Theme.of(context).colorScheme.primary;

    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),

          if (count != null) ...[
            const SizedBox(width: 5),

            Text(
              '$count',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: selected
                    ? Colors.white
                    : displayColor,
              ),
            ),
          ],
        ],
      ),

      selected: selected,

      onSelected: (_) => onTap(),

      selectedColor: displayColor,

      labelStyle: TextStyle(
        color: selected
            ? Colors.white
            : Colors.black87,
        fontSize: 12,
      ),

      side: BorderSide(
        color: selected
            ? displayColor
            : Colors.grey.shade300,
      ),
    );
  }
}

// ================================================================
// INVENTORY CARD
// ================================================================

class _InventoryCard extends StatelessWidget {
  final InventoryItem item;
  final String status;
  final Color statusColor;
  final IconData statusIcon;

  final VoidCallback onAddStock;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _InventoryCard({
    required this.item,
    required this.status,
    required this.statusColor,
    required this.statusIcon,
    required this.onAddStock,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),

      elevation: 0,

      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Colors.grey.shade200,
        ),
      ),

      child: Padding(
        padding: const EdgeInsets.all(14),

        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            // ------------------------------------------------------
            // IMAGE
            // ------------------------------------------------------

            item.imageUrl.isNotEmpty
                ? ClipRRect(
                    borderRadius:
                        BorderRadius.circular(12),

                    child: Image.network(
                      item.imageUrl,
                      width: 58,
                      height: 58,
                      fit: BoxFit.cover,

                      errorBuilder:
                          (context, error, stackTrace) {
                        return const _InventoryIcon();
                      },
                    ),
                  )
                : const _InventoryIcon(),

            const SizedBox(width: 12),

            // ------------------------------------------------------
            // DETAILS
            // ------------------------------------------------------

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [
                  Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,

                    children: [
                      Expanded(
                        child: Text(
                          item.itemName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          overflow:
                              TextOverflow.ellipsis,
                        ),
                      ),

                      const SizedBox(width: 6),

                      Icon(
                        statusIcon,
                        color: statusColor,
                        size: 17,
                      ),
                    ],
                  ),

                  const SizedBox(height: 3),

                  Text(
                    '${item.itemType} • '
                    '${item.brand.isEmpty ? 'No brand' : item.brand}',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Text(
                        '${item.quantity} ${item.unit}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),

                      const SizedBox(width: 6),

                      Text(
                        '• Min ${item.minimumStock}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  Text(
                    '₱${item.pricePerUnit.toStringAsFixed(2)} / ${item.unit}',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Container(
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),

                        decoration: BoxDecoration(
                          color: statusColor.withValues(
                            alpha: 0.10,
                          ),
                          borderRadius:
                              BorderRadius.circular(20),
                        ),

                        child: Text(
                          status,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 11,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ),

                      const Spacer(),

                      // ------------------------------------------------
                      // MENU
                      // ------------------------------------------------

                      PopupMenuButton<String>(
                        icon: const Icon(
                          Icons.more_vert,
                          size: 20,
                        ),

                        onSelected: (value) {
                          switch (value) {
                            case 'add_stock':
                              onAddStock();
                              break;

                            case 'edit':
                              onEdit();
                              break;

                            case 'delete':
                              onDelete();
                              break;
                          }
                        },

                        itemBuilder: (context) => const [
                          PopupMenuItem(
                            value: 'add_stock',

                            child: Row(
                              children: [
                                Icon(
                                  Icons.add_box_outlined,
                                  size: 18,
                                ),

                                SizedBox(width: 8),

                                Text('Add Stock'),
                              ],
                            ),
                          ),

                          PopupMenuItem(
                            value: 'edit',

                            child: Row(
                              children: [
                                Icon(
                                  Icons.edit_outlined,
                                  size: 18,
                                ),

                                SizedBox(width: 8),

                                Text('Edit'),
                              ],
                            ),
                          ),

                          PopupMenuItem(
                            value: 'delete',

                            child: Row(
                              children: [
                                Icon(
                                  Icons.delete_outline,
                                  size: 18,
                                  color: Colors.red,
                                ),

                                SizedBox(width: 8),

                                Text('Delete'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
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

// ================================================================
// INVENTORY ICON
// ================================================================

class _InventoryIcon extends StatelessWidget {
  const _InventoryIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58,
      height: 58,

      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),

      alignment: Alignment.center,

      child: const Icon(
        Icons.inventory_2_outlined,
        size: 28,
      ),
    );
  }
}

// ================================================================
// EMPTY STATE
// ================================================================

class _EmptyInventoryState extends StatelessWidget {
  final String filter;

  const _EmptyInventoryState({
    required this.filter,
  });

  @override
  Widget build(BuildContext context) {
    String message;
    IconData icon;

    if (filter == 'Low Stock') {
      message = 'No low-stock items.';
      icon = Icons.check_circle_outline;
    } else if (filter == 'Out of Stock') {
      message = 'No out-of-stock items.';
      icon = Icons.inventory_2_outlined;
    } else {
      message = 'No inventory items yet.';
      icon = Icons.inventory_2_outlined;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 60,
      ),

      child: Column(
        children: [
          Icon(
            icon,
            size: 50,
            color: Colors.grey.shade400,
          ),

          const SizedBox(height: 12),

          Text(
            message,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}