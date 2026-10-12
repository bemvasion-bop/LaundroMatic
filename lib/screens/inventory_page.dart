import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../controllers/theme_controller.dart';
import '../models/inventory.dart';
import '../services/inventory_service.dart';
import 'dashboard_page.dart';
import 'inventory_transactions_page.dart';
import 'orders_page.dart';
import 'more_page.dart';

class InventoryPage extends StatefulWidget {
  final String? initialFilter;

  const InventoryPage({
    super.key,
    this.initialFilter,
  });

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  final InventoryService _inventoryService = InventoryService();
  final TextEditingController _searchController = TextEditingController();

  String selectedFilter = 'All';
  String _searchQuery = '';
  int currentPage = 1;
  static const int inventoryPerPage = 15;

  @override
  void initState() {
    super.initState();
    if (widget.initialFilter != null) {
      selectedFilter = widget.initialFilter!;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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

    String currentImageUrl = item?.imageUrl ?? '';
    bool isPickingImage = false;
    bool showManualUrlInput = false;

    String selectedItemType = item?.itemType ?? 'Detergent';

    Future<void> saveItem(BuildContext dialogContext) async {
      final String itemName = itemNameController.text.trim();
      final String brand = brandController.text.trim();
      final String scent = scentController.text.trim();
      final String size = sizeController.text.trim();

      final int? enteredQuantity = isEditing
          ? item.quantity
          : int.tryParse(quantityController.text.trim());

      final String unit = unitController.text.trim();
      final double? price =
          double.tryParse(priceController.text.trim());
      final int? minimumStock =
          int.tryParse(minimumStockController.text.trim());
      final String imageUrl = currentImageUrl.trim().isNotEmpty
          ? currentImageUrl.trim()
          : imageUrlController.text.trim();

      // Validation
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
        } else {
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
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (innerDialogContext, setDialogState) {
            Future<void> pickImage(ImageSource source) async {
              try {
                setDialogState(() {
                  isPickingImage = true;
                });
                final ImagePicker picker = ImagePicker();
                final XFile? pickedFile = await picker.pickImage(
                  source: source,
                  maxWidth: 400,
                  maxHeight: 400,
                  imageQuality: 70,
                );
                if (pickedFile != null) {
                  final bytes = await pickedFile.readAsBytes();
                  final base64String = base64Encode(bytes);
                  final mimeType = pickedFile.mimeType ?? 'image/jpeg';
                  final dataUri = 'data:$mimeType;base64,$base64String';
                  setDialogState(() {
                    currentImageUrl = dataUri;
                    imageUrlController.text = dataUri;
                  });
                }
              } catch (e) {
                if (innerDialogContext.mounted) {
                  final bool isMissingPlugin =
                      e.toString().contains('MissingPluginException');
                  final String errorMsg = isMissingPlugin
                      ? 'Please restart "flutter run -d chrome" in your terminal to enable the new image picker plugin.'
                      : 'Failed to pick image: $e';
                  ScaffoldMessenger.of(innerDialogContext).showSnackBar(
                    SnackBar(
                      content: Text(errorMsg),
                      duration: const Duration(seconds: 5),
                      backgroundColor: Colors.red.shade700,
                    ),
                  );
                }
              } finally {
                setDialogState(() {
                  isPickingImage = false;
                });
              }
            }

            final colors = ThemeController.of(innerDialogContext);

            void showImageSourceSheet() {
              showModalBottomSheet(
                context: innerDialogContext,
                backgroundColor: colors.cardBg,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (sheetContext) => SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select Product Photo',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 14),
                        ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: colors.primaryLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.photo_library_outlined,
                                color: colors.primary),
                          ),
                          title: Text('Choose from Gallery / Files',
                              style: TextStyle(fontWeight: FontWeight.w600, color: colors.textPrimary)),
                          subtitle: Text('JPG or PNG image',
                              style: TextStyle(
                                  fontSize: 12, color: colors.textSecondary)),
                          onTap: () {
                            Navigator.of(sheetContext).pop();
                            pickImage(ImageSource.gallery);
                          },
                        ),
                        ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: colors.primaryLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.camera_alt_outlined,
                                color: colors.primary),
                          ),
                          title: Text('Take Photo with Camera',
                              style: TextStyle(fontWeight: FontWeight.w600, color: colors.textPrimary)),
                          subtitle: Text('Capture using device camera',
                              style: TextStyle(
                                  fontSize: 12, color: colors.textSecondary)),
                          onTap: () {
                            Navigator.of(sheetContext).pop();
                            pickImage(ImageSource.camera);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            void onPickPhotoTap() {
              if (kIsWeb) {
                pickImage(ImageSource.gallery);
              } else {
                showImageSourceSheet();
              }
            }

            return AlertDialog(
              backgroundColor: colors.cardBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
              titlePadding: const EdgeInsets.fromLTRB(20, 20, 16, 12),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              actionsPadding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEditing ? 'Edit Inventory Item' : 'Add Inventory Item',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
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
                    children: [
                      const SizedBox(height: 4),

                      // Item Name
                      TextField(
                        controller: itemNameController,
                        style: TextStyle(color: colors.textPrimary),
                        decoration: InputDecoration(
                          labelText: 'Item Name *',
                          labelStyle: TextStyle(color: colors.textSecondary),
                          prefixIcon: Icon(
                              Icons.inventory_2_outlined,
                              color: colors.textSecondary,
                              size: 20),
                          filled: true,
                          fillColor: colors.inputFill,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: colors.inputBorder),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: colors.inputBorder),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: colors.primary, width: 1.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Item Type
                      DropdownButtonFormField<String>(
                        initialValue: selectedItemType,
                        dropdownColor: colors.cardBg,
                        style: TextStyle(color: colors.textPrimary),
                        decoration: InputDecoration(
                          labelText: 'Item Type *',
                          labelStyle: TextStyle(color: colors.textSecondary),
                          prefixIcon: Icon(
                              Icons.category_outlined,
                              color: colors.textSecondary,
                              size: 20),
                          filled: true,
                          fillColor: colors.inputFill,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: colors.inputBorder),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: colors.inputBorder),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: colors.primary, width: 1.5),
                          ),
                        ),
                        items: [
                          DropdownMenuItem(
                            value: 'Detergent',
                            child: Text('Detergent', style: TextStyle(color: colors.textPrimary)),
                          ),
                          DropdownMenuItem(
                            value: 'Fabric Conditioner',
                            child: Text('Fabric Conditioner', style: TextStyle(color: colors.textPrimary)),
                          ),
                          DropdownMenuItem(
                            value: 'Plastic Bag',
                            child: Text('Plastic Bag', style: TextStyle(color: colors.textPrimary)),
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

                      // Brand
                      TextField(
                        controller: brandController,
                        style: TextStyle(color: colors.textPrimary),
                        decoration: InputDecoration(
                          labelText: 'Brand',
                          labelStyle: TextStyle(color: colors.textSecondary),
                          prefixIcon: Icon(
                              Icons.branding_watermark_outlined,
                              color: colors.textSecondary,
                              size: 20),
                          filled: true,
                          fillColor: colors.inputFill,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: colors.inputBorder),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: colors.inputBorder),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: colors.primary, width: 1.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Scent / Variety
                      TextField(
                        controller: scentController,
                        style: TextStyle(color: colors.textPrimary),
                        decoration: InputDecoration(
                          labelText: 'Scent / Variety',
                          labelStyle: TextStyle(color: colors.textSecondary),
                          prefixIcon:
                              Icon(Icons.spa_outlined, color: colors.textSecondary, size: 20),
                          filled: true,
                          fillColor: colors.inputFill,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: colors.inputBorder),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: colors.inputBorder),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: colors.primary, width: 1.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Size
                      TextField(
                        controller: sizeController,
                        style: TextStyle(color: colors.textPrimary),
                        decoration: InputDecoration(
                          labelText: 'Size',
                          labelStyle: TextStyle(color: colors.textSecondary),
                          hintText: 'e.g. Small, Medium, 50g',
                          hintStyle: TextStyle(color: colors.textMuted),
                          prefixIcon: Icon(
                              Icons.straighten_outlined,
                              color: colors.textSecondary,
                              size: 20),
                          filled: true,
                          fillColor: colors.inputFill,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: colors.inputBorder),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: colors.inputBorder),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: colors.primary, width: 1.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Initial Quantity (only when adding)
                      if (!isEditing) ...[
                        TextField(
                          controller: quantityController,
                          style: TextStyle(color: colors.textPrimary),
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Initial Quantity *',
                            labelStyle: TextStyle(color: colors.textSecondary),
                            hintText: 'e.g. 50',
                            hintStyle: TextStyle(color: colors.textMuted),
                            prefixIcon: Icon(
                                Icons.format_list_numbered_rounded,
                                color: colors.textSecondary,
                                size: 20),
                            filled: true,
                            fillColor: colors.inputFill,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: colors.inputBorder),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: colors.inputBorder),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: colors.primary, width: 1.5),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Unit
                      TextField(
                        controller: unitController,
                        style: TextStyle(color: colors.textPrimary),
                        decoration: InputDecoration(
                          labelText: 'Unit *',
                          labelStyle: TextStyle(color: colors.textSecondary),
                          hintText: 'e.g. sachets, pieces, bottles',
                          hintStyle: TextStyle(color: colors.textMuted),
                          prefixIcon:
                              Icon(Icons.scale_outlined, color: colors.textSecondary, size: 20),
                          filled: true,
                          fillColor: colors.inputFill,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: colors.inputBorder),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: colors.inputBorder),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: colors.primary, width: 1.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Price per Unit
                      TextField(
                        controller: priceController,
                        style: TextStyle(color: colors.textPrimary),
                        keyboardType:
                            const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Price per Unit *',
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
                            borderSide: BorderSide(color: colors.inputBorder),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: colors.inputBorder),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: colors.primary, width: 1.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Minimum Stock
                      TextField(
                        controller: minimumStockController,
                        style: TextStyle(color: colors.textPrimary),
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Minimum Stock *',
                          labelStyle: TextStyle(color: colors.textSecondary),
                          hintText: 'Alert when stock reaches this level',
                          hintStyle: TextStyle(color: colors.textMuted),
                          prefixIcon: Icon(
                              Icons.warning_amber_rounded,
                              color: colors.textSecondary,
                              size: 20),
                          filled: true,
                          fillColor: colors.inputFill,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: colors.inputBorder),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: colors.inputBorder),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: colors.primary, width: 1.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Item Photo / Image Picker Section
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Item Photo',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: colors.textPrimary,
                                ),
                              ),
                              TextButton(
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                onPressed: () {
                                  setDialogState(() {
                                    showManualUrlInput = !showManualUrlInput;
                                  });
                                },
                                child: Text(
                                  showManualUrlInput
                                      ? 'Hide URL'
                                      : 'Use URL instead',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: colors.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          if (isPickingImage)
                            Container(
                              width: double.infinity,
                              height: 90,
                              decoration: BoxDecoration(
                                color: colors.subCardBg,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: colors.border),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: colors.primary),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Processing photo...',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: colors.textSecondary),
                                  ),
                                ],
                              ),
                            )
                          else if (currentImageUrl.isNotEmpty)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: colors.subCardBg,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: colors.border),
                              ),
                              child: Row(
                                children: [
                                  _buildProductImage(
                                    imageUrl: currentImageUrl,
                                    width: 60,
                                    height: 60,
                                    borderRadius: BorderRadius.circular(10),
                                    fallback: Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        color: colors.primaryLight,
                                        borderRadius:
                                            BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        Icons.image_not_supported_outlined,
                                        color: colors.primary,
                                        size: 26,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Product Photo Selected',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: colors.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          currentImageUrl.startsWith('data:')
                                              ? 'Attached from device (compressed)'
                                              : (currentImageUrl.length > 28
                                                  ? '${currentImageUrl.substring(0, 25)}...'
                                                  : currentImageUrl),
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: colors.textSecondary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            InkWell(
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              onTap: onPickPhotoTap,
                                              child: Padding(
                                                padding: const EdgeInsets.symmetric(
                                                    horizontal: 4, vertical: 2),
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.edit_outlined,
                                                        size: 14,
                                                        color:
                                                            colors.primary),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      'Change',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color:
                                                            colors.primary,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            InkWell(
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              onTap: () {
                                                setDialogState(() {
                                                  currentImageUrl = '';
                                                  imageUrlController.clear();
                                                });
                                              },
                                              child: const Padding(
                                                padding: EdgeInsets.symmetric(
                                                    horizontal: 4, vertical: 2),
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                        Icons
                                                            .delete_outline_rounded,
                                                        size: 14,
                                                        color: Colors.red),
                                                    SizedBox(width: 4),
                                                    Text(
                                                      'Remove',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.red,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: onPickPhotoTap,
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 18, horizontal: 16),
                                decoration: BoxDecoration(
                                  color: colors.subCardBg,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: colors.border,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: colors.primaryLight,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.add_photo_alternate_outlined,
                                        size: 26,
                                        color: colors.primary,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Upload Product Photo',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                        color: colors.primary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Click to select from gallery or files',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        color: colors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          if (showManualUrlInput) ...[
                            const SizedBox(height: 10),
                            TextField(
                              controller: imageUrlController,
                              style: TextStyle(color: colors.textPrimary),
                              onChanged: (val) {
                                setDialogState(() {
                                  currentImageUrl = val.trim();
                                });
                              },
                              decoration: InputDecoration(
                                labelText: 'Direct Image URL',
                                labelStyle: TextStyle(color: colors.textSecondary),
                                hintText: 'https://example.com/item.png',
                                hintStyle: TextStyle(color: colors.textMuted),
                                prefixIcon: Icon(Icons.link, color: colors.textSecondary, size: 20),
                                filled: true,
                                fillColor: colors.inputFill,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: colors.border,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: colors.border,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: colors.primary,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
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
                        onPressed: () =>
                            Navigator.of(dialogContext).pop(),
                        child: Text('Cancel',
                            style: TextStyle(color: colors.textSecondary)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () => saveItem(dialogContext),
                        child: Text(
                          isEditing ? 'Update Item' : 'Add Item',
                          style: const TextStyle(fontWeight: FontWeight.bold),
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

  // ================================================================
  // ADD STOCK DIALOG
  // ================================================================

  void _showAddStockDialog(InventoryItem item) {
    final quantityController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        final colors = ThemeController.of(dialogContext);
        return AlertDialog(
          backgroundColor: colors.cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          titlePadding: const EdgeInsets.fromLTRB(20, 20, 16, 12),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20),
          actionsPadding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Add Stock',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
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
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
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
                    Text(
                      item.itemName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Current stock: ${item.quantity} ${item.unit}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: quantityController,
                keyboardType: TextInputType.number,
                autofocus: true,
                style: TextStyle(color: colors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Quantity to Add *',
                  labelStyle: TextStyle(color: colors.textSecondary),
                  hintText: 'e.g. 20',
                  hintStyle: TextStyle(color: colors.textMuted),
                  suffixText: item.unit,
                  suffixStyle: TextStyle(color: colors.textSecondary),
                  filled: true,
                  fillColor: colors.inputFill,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colors.inputBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colors.inputBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colors.primary, width: 1.5),
                  ),
                ),
              ),
            ],
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
                    onPressed: () =>
                        Navigator.of(dialogContext).pop(),
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
                    onPressed: () async {
                      final int? quantityToAdd =
                          int.tryParse(quantityController.text.trim());

                      if (quantityToAdd == null || quantityToAdd <= 0) {
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
                    icon: const Icon(Icons.add_box_rounded, size: 18),
                    label: const Text(
                      'Add Stock',
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
  }

  // ================================================================
  // DELETE DIALOG
  // ================================================================

  void _confirmDelete(InventoryItem item) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        final colors = ThemeController.of(dialogContext);
        return AlertDialog(
          backgroundColor: colors.cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Delete Inventory Item',
            style: TextStyle(fontWeight: FontWeight.bold, color: colors.textPrimary),
          ),
          content: Text(
            'Are you sure you want to delete "${item.itemName}"? This action cannot be undone.',
            style: TextStyle(color: colors.textSecondary),
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(foregroundColor: colors.textSecondary),
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
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
  // STATUS HELPERS
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
        return const Color(0xFFEF4444);
      case 'Low Stock':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF16A34A);
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Out of Stock':
        return Icons.error_outline_rounded;
      case 'Low Stock':
        return Icons.warning_amber_rounded;
      default:
        return Icons.check_circle_outline_rounded;
    }
  }

  // ================================================================
  // FILTER
  // ================================================================

  List<InventoryItem> _filterInventory(List<InventoryItem> inventory) {
    return inventory.where((item) {
      // Stock Status Filter
      if (selectedFilter == 'Low Stock') {
        if (!(item.quantity > 0 && item.quantity <= item.minimumStock)) {
          return false;
        }
      } else if (selectedFilter == 'Out of Stock') {
        if (item.quantity != 0) return false;
      } else if (selectedFilter != 'All') {
        if (item.itemType != selectedFilter) return false;
      }

      // Search Query Filter
      if (_searchQuery.isNotEmpty) {
        final nameMatches =
            item.itemName.toLowerCase().contains(_searchQuery);
        final brandMatches =
            item.brand.toLowerCase().contains(_searchQuery);
        final typeMatches =
            item.itemType.toLowerCase().contains(_searchQuery);
        final scentMatches =
            item.scent.toLowerCase().contains(_searchQuery);
        if (!nameMatches && !brandMatches && !typeMatches && !scentMatches) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  // ================================================================
  // BUILD
  // ================================================================

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.themeModeNotifier,
      builder: (context, currentMode, _) {
        final colors = ThemeController.of(context);
        final pageBg = colors.pageBg;
        final textDark = colors.textPrimary;
        final primaryBlue = colors.primary;

        Widget inventoryContent = Scaffold(
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
              'Inventory',
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
                  onPressed: () => _showInventoryDialog(),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text(
                    'Add Item',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),

          body: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 440),
              child: StreamBuilder<List<InventoryItem>>(
                stream: _inventoryService.getInventory(),
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
                          'Error loading inventory: ${snapshot.error}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
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

                  final filteredInventory = _filterInventory(inventory);

                  final baseTypes = [
                    'Detergent',
                    'Fabric Conditioner',
                    'Plastic Bag',
                  ];
                  final dynamicTypes = inventory
                      .map((i) => i.itemType.trim())
                      .where((t) =>
                          t.isNotEmpty &&
                          !baseTypes.contains(t) &&
                          t != 'All' &&
                          t != 'Low Stock' &&
                          t != 'Out of Stock')
                      .toSet()
                      .toList();
                  final allCategoryOptions = [
                    ...baseTypes,
                    ...dynamicTypes,
                  ];
                  final allOptions = [
                    'All',
                    'Low Stock',
                    'Out of Stock',
                    ...allCategoryOptions,
                  ];

                  if (!allOptions.contains(selectedFilter)) {
                    selectedFilter = 'All';
                  }

                  final int totalPages = filteredInventory.isEmpty
                      ? 1
                      : (filteredInventory.length / inventoryPerPage).ceil();

                  final int effectivePage = currentPage > totalPages
                      ? totalPages
                      : (currentPage < 1 ? 1 : currentPage);

                  final int startIndex = (effectivePage - 1) * inventoryPerPage;
                  final int endIndex = (startIndex + inventoryPerPage)
                      .clamp(0, filteredInventory.length);

                  final paginatedInventory = filteredInventory.isEmpty
                      ? <InventoryItem>[]
                      : filteredInventory.sublist(startIndex, endIndex);

                  return Column(
                    children: [
                      Expanded(
                        child: RefreshIndicator(
                          onRefresh: () async {
                            await Future.delayed(
                              const Duration(milliseconds: 300),
                            );
                          },
                          child: ListView(
                            padding: EdgeInsets.fromLTRB(
                                16, 4, 16, totalPages > 1 ? 16 : 80),
                            children: [
                              // Search Bar with Filter Icon on the Right
                              TextField(
                                controller: _searchController,
                                style:
                                    TextStyle(color: textDark, fontSize: 13.5),
                                decoration: InputDecoration(
                                  hintText:
                                      'Search items by name, brand, or type...',
                                  hintStyle: TextStyle(
                                      color: colors.textSecondary,
                                      fontSize: 13.5),
                                  prefixIcon: Icon(Icons.search_rounded,
                                      color: colors.textSecondary, size: 21),
                                  suffixIcon: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (_searchQuery.isNotEmpty)
                                        IconButton(
                                          icon: Icon(Icons.clear_rounded,
                                              color: colors.textSecondary,
                                              size: 18),
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
                                            ? 'Filter items'
                                            : 'Filter: $selectedFilter',
                                        offset: const Offset(0, 45),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          side:
                                              BorderSide(color: colors.border),
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
                                                      'All (${inventory.length})',
                                                      style: TextStyle(
                                                        fontSize: 13,
                                                        fontWeight:
                                                            selectedFilter ==
                                                                    'All'
                                                                ? FontWeight
                                                                    .bold
                                                                : FontWeight
                                                                    .w500,
                                                        color: selectedFilter ==
                                                                'All'
                                                            ? colors.primary
                                                            : colors
                                                                .textPrimary,
                                                      ),
                                                    ),
                                                  ),
                                                  if (selectedFilter == 'All')
                                                    Icon(Icons.check_rounded,
                                                        size: 18,
                                                        color: colors.primary),
                                                ],
                                              ),
                                            ),
                                            PopupMenuItem<String>(
                                              value: 'Low Stock',
                                              child: Row(
                                                children: [
                                                  Container(
                                                    width: 8,
                                                    height: 8,
                                                    decoration: BoxDecoration(
                                                      color: colors.warningText,
                                                      shape: BoxShape.circle,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Text(
                                                      'Low Stock (${lowStockItems.length})',
                                                      style: TextStyle(
                                                        fontSize: 13,
                                                        fontWeight:
                                                            selectedFilter ==
                                                                    'Low Stock'
                                                                ? FontWeight
                                                                    .bold
                                                                : FontWeight
                                                                    .w500,
                                                        color: selectedFilter ==
                                                                'Low Stock'
                                                            ? colors.primary
                                                            : colors
                                                                .textPrimary,
                                                      ),
                                                    ),
                                                  ),
                                                  if (selectedFilter ==
                                                      'Low Stock')
                                                    Icon(Icons.check_rounded,
                                                        size: 18,
                                                        color: colors.primary),
                                                ],
                                              ),
                                            ),
                                            PopupMenuItem<String>(
                                              value: 'Out of Stock',
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
                                                      'Out of Stock (${outOfStockItems.length})',
                                                      style: TextStyle(
                                                        fontSize: 13,
                                                        fontWeight:
                                                            selectedFilter ==
                                                                    'Out of Stock'
                                                                ? FontWeight
                                                                    .bold
                                                                : FontWeight
                                                                    .w500,
                                                        color: selectedFilter ==
                                                                'Out of Stock'
                                                            ? colors.primary
                                                            : colors
                                                                .textPrimary,
                                                      ),
                                                    ),
                                                  ),
                                                  if (selectedFilter ==
                                                      'Out of Stock')
                                                    Icon(Icons.check_rounded,
                                                        size: 18,
                                                        color: colors.primary),
                                                ],
                                              ),
                                            ),
                                            const PopupMenuDivider(),
                                            ...allCategoryOptions.map(
                                              (category) =>
                                                  PopupMenuItem<String>(
                                                value: category,
                                                child: Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        category,
                                                        style: TextStyle(
                                                          fontSize: 13,
                                                          fontWeight:
                                                              selectedFilter ==
                                                                      category
                                                                  ? FontWeight
                                                                      .bold
                                                                  : FontWeight
                                                                      .w500,
                                                          color:
                                                              selectedFilter ==
                                                                      category
                                                                  ? colors
                                                                      .primary
                                                                  : colors
                                                                      .textPrimary,
                                                        ),
                                                      ),
                                                    ),
                                                    if (selectedFilter ==
                                                        category)
                                                      Icon(Icons.check_rounded,
                                                          size: 18,
                                                          color:
                                                              colors.primary),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ];
                                        },
                                        child: Container(
                                          margin: const EdgeInsets.only(
                                              right: 8, left: 2),
                                          padding: const EdgeInsets.all(7),
                                          decoration: BoxDecoration(
                                            color: selectedFilter != 'All'
                                                ? colors.primary
                                                : colors.primary.withValues(
                                                    alpha: colors.isDark
                                                        ? 0.22
                                                        : 0.10),
                                            borderRadius:
                                                BorderRadius.circular(10),
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

                              const SizedBox(height: 12),

                              // Stock Summary Cards
                              Row(
                                children: [
                                  Expanded(
                                    child: _StockSummaryCard(
                                      icon: Icons.warning_amber_rounded,
                                      title: 'Low Stock',
                                      count: lowStockItems.length,
                                      color: colors.warningText,
                                      isSelected: selectedFilter == 'Low Stock',
                                      onTap: () {
                                        setState(() {
                                          selectedFilter =
                                              selectedFilter == 'Low Stock'
                                                  ? 'All'
                                                  : 'Low Stock';
                                          currentPage = 1;
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _StockSummaryCard(
                                      icon: Icons.error_outline_rounded,
                                      title: 'Out of Stock',
                                      count: outOfStockItems.length,
                                      color: colors.errorText,
                                      isSelected:
                                          selectedFilter == 'Out of Stock',
                                      onTap: () {
                                        setState(() {
                                          selectedFilter =
                                              selectedFilter == 'Out of Stock'
                                                  ? 'All'
                                                  : 'Out of Stock';
                                          currentPage = 1;
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),

                              if (selectedFilter != 'All') ...[
                                const SizedBox(height: 8),
                                Row(
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
                                        color: colors.primary
                                            .withValues(alpha: 0.12),
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
                                            selectedFilter,
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
                                                selectedFilter = 'All';
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
                              ],

                              const SizedBox(height: 12),

                              // Empty State or Inventory List
                              if (filteredInventory.isEmpty)
                                _EmptyInventoryState(
                                  filter: selectedFilter,
                                  searchQuery: _searchQuery,
                                )
                              else
                                ...paginatedInventory.map(
                                  (item) {
                                    final currentStatus = _getStockStatus(item);
                                    return _InventoryCard(
                                      item: item,
                                      status: currentStatus,
                                      statusColor:
                                          _getStatusColor(currentStatus),
                                      statusIcon: _getStatusIcon(currentStatus),
                                      onAddStock: () =>
                                          _showAddStockDialog(item),
                                      onEdit: () =>
                                          _showInventoryDialog(item: item),
                                      onDelete: () => _confirmDelete(item),
                                    );
                                  },
                                ),
                            ],
                          ),
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
              ),
            ),
          ),

          // Main Action Button in bottom part
          //floatingActionButton: FloatingActionButton.extended(
          //  backgroundColor: primaryBlue,
          //  foregroundColor: Colors.white,
          //  elevation: 3,
          //  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          //  onPressed: () => _showInventoryDialog(),
          //  icon: const Icon(Icons.add_rounded),
          //  label: const Text(
          //    'Add Item',
          //    style: TextStyle(fontWeight: FontWeight.bold),
          //  ),
          // ),

          // Bottom Navigation Bar matching all other screens
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: colors.cardBg,
              border: Border(
                top: BorderSide(color: colors.border, width: 1),
              ),
            ),
            child: BottomNavigationBar(
              currentIndex: 2, // Inventory tab
              onTap: (index) {
                if (index == 2) return;
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
                } else if (index == 3) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const InventoryTransactionsPage(),
                    ),
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
                  icon: Icon(Icons.inventory_2_rounded),
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
                      child: inventoryContent,
                    ),
                  ),
                ),
              );
            }
            return inventoryContent;
          },
        );
      },
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
  final bool isSelected;
  final VoidCallback onTap;

  const _StockSummaryCard({
    required this.icon,
    required this.title,
    required this.count,
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: colors.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : colors.border,
            width: isSelected ? 1.8 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: colors.isDark
                  ? Colors.black.withValues(alpha: 0.25)
                  : Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: count > 0 ? color : colors.textPrimary,
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

Widget _buildProductImage({
  required String imageUrl,
  required double width,
  required double height,
  required Widget fallback,
  BorderRadius? borderRadius,
}) {
  final radius = borderRadius ?? BorderRadius.circular(12);
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
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => fallback,
      );
    } catch (_) {
      return fallback;
    }
  } else if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
    imageWidget = Image.network(
      trimmed,
      width: width,
      height: height,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => fallback,
    );
  }

  if (imageWidget != null) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(color: ThemeController.colors.border),
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: imageWidget,
      ),
    );
  }

  return fallback;
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

  Color _getItemTypeColor(String type, ThemeColors colors) {
    switch (type) {
      case 'Fabric Conditioner':
        return colors.purpleText;
      case 'Plastic Bag':
        return colors.isDark ? const Color(0xFF2DD4BF) : const Color(0xFF0D9488);
      case 'Detergent':
      default:
        return colors.primary;
    }
  }

  Color _getItemTypeBgColor(String type, ThemeColors colors) {
    switch (type) {
      case 'Fabric Conditioner':
        return colors.purpleBg;
      case 'Plastic Bag':
        return colors.isDark
            ? const Color(0xFF134E4A).withValues(alpha: 0.45)
            : const Color(0xFFF0FDFA);
      case 'Detergent':
      default:
        return colors.primaryLight;
    }
  }

  IconData _getItemTypeIcon(String type) {
    switch (type) {
      case 'Fabric Conditioner':
        return Icons.clean_hands_outlined;
      case 'Plastic Bag':
        return Icons.shopping_bag_outlined;
      case 'Detergent':
      default:
        return Icons.sanitizer_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeController.of(context);
    final typeColor = _getItemTypeColor(item.itemType, colors);
    final typeBg = _getItemTypeBgColor(item.itemType, colors);
    final typeIcon = _getItemTypeIcon(item.itemType);

    final double stockRatio = item.minimumStock > 0
        ? (item.quantity / (item.minimumStock * 2)).clamp(0.0, 1.0)
        : (item.quantity > 0 ? 1.0 : 0.0);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: colors.isDark
                ? Colors.black.withValues(alpha: 0.25)
                : Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Item Image or Type Icon
                _buildProductImage(
                  imageUrl: item.imageUrl,
                  width: 52,
                  height: 52,
                  borderRadius: BorderRadius.circular(12),
                  fallback: _buildFallbackIcon(typeBg, typeColor, typeIcon),
                ),

                const SizedBox(width: 12),

                // Details Column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.itemName,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: colors.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Icon(statusIcon, color: statusColor, size: 16),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${item.itemType} • ${item.brand.isEmpty ? 'No brand' : item.brand}',
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      if (item.scent.isNotEmpty || item.size.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          '${item.scent.isNotEmpty ? item.scent : ''}${item.scent.isNotEmpty && item.size.isNotEmpty ? ' • ' : ''}${item.size.isNotEmpty ? item.size : ''}',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: colors.textMuted,
                          ),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        '₱${item.pricePerUnit.toStringAsFixed(2)} / ${item.unit}',
                        style: TextStyle(
                          color: colors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Stock Progress & Info Bar
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${item.quantity} ${item.unit}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: statusColor,
                            ),
                          ),
                          Text(
                            'Min: ${item.minimumStock}',
                            style: TextStyle(
                              color: colors.textSecondary,
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: stockRatio,
                          backgroundColor: colors.subCardBg,
                          valueColor: AlwaysStoppedAnimation(statusColor),
                          minHeight: 5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            Divider(height: 18, color: colors.divider),

            // Action Row inside Card
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),

                // Quick Add Stock Button
                InkWell(
                  onTap: onAddStock,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: colors.primaryLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_box_rounded,
                            size: 15, color: colors.primary),
                        const SizedBox(width: 4),
                        Text(
                          'Add Stock',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: colors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 6),

                // Edit/Delete Menu
                PopupMenuButton<String>(
                  color: colors.cardBg,
                  icon: Icon(Icons.more_vert_rounded,
                      size: 20, color: colors.textSecondary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
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
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'add_stock',
                      child: Row(
                        children: [
                          Icon(Icons.add_box_outlined, size: 18, color: colors.textPrimary),
                          const SizedBox(width: 8),
                          Text('Add Stock', style: TextStyle(color: colors.textPrimary)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 18, color: colors.textPrimary),
                          const SizedBox(width: 8),
                          Text('Edit', style: TextStyle(color: colors.textPrimary)),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline,
                              size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
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
    );
  }

  Widget _buildFallbackIcon(Color bg, Color color, IconData icon) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Icon(
        icon,
        size: 24,
        color: color,
      ),
    );
  }
}

// ================================================================
// EMPTY STATE
// ================================================================

class _EmptyInventoryState extends StatelessWidget {
  final String filter;
  final String searchQuery;

  const _EmptyInventoryState({
    required this.filter,
    required this.searchQuery,
  });

  @override
  Widget build(BuildContext context) {
    final colors = ThemeController.of(context);
    String message;
    IconData icon;

    if (searchQuery.isNotEmpty) {
      message = 'No items matching "$searchQuery"';
      icon = Icons.search_off_rounded;
    } else if (filter == 'Low Stock') {
      message = 'No low-stock items at the moment.';
      icon = Icons.check_circle_outline_rounded;
    } else if (filter == 'Out of Stock') {
      message = 'No out-of-stock items.';
      icon = Icons.inventory_2_outlined;
    } else {
      message = 'No items found in "$filter".';
      icon = Icons.inventory_2_outlined;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 50),
      child: Column(
        children: [
          Icon(
            icon,
            size: 52,
            color: colors.textMuted,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Try adjusting your search query or filter chip',
            style: TextStyle(
              color: colors.textMuted,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}