import 'package:flutter/material.dart';

import '../controllers/theme_controller.dart';
import '../models/service.dart';
import '../services/service_service.dart';

class ServicesPage extends StatefulWidget {
  const ServicesPage({super.key});

  @override
  State<ServicesPage> createState() => _ServicesPageState();
}

class _ServicesPageState extends State<ServicesPage> {
  final ServiceService _serviceService = ServiceService();

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _maxWeightController = TextEditingController();
  final TextEditingController _bundlePriceController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  String _searchQuery = '';
  int currentPage = 1;
  static const int servicesPerPage = 15;

  @override
  void dispose() {
    _searchController.dispose();
    _nameController.dispose();
    _maxWeightController.dispose();
    _bundlePriceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _showServiceDialog({LaundryService? service}) {
    final bool isEditing = service != null;
    final colors = ThemeController.colors;

    if (isEditing) {
      _nameController.text = service.serviceName;
      _maxWeightController.text = service.maxWeight.toString();
      _bundlePriceController.text = service.bundlePrice.toString();
      _descriptionController.text = service.description;
    } else {
      _nameController.clear();
      _maxWeightController.clear();
      _bundlePriceController.clear();
      _descriptionController.clear();
    }

    String selectedStatus = service?.status ?? 'Active';

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: colors.cardBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: colors.border),
              ),
              title: Text(
                isEditing ? 'Edit Service' : 'Add New Service',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: colors.textPrimary,
                ),
              ),
              content: SizedBox(
                width: 440,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: _nameController,
                        style: TextStyle(color: colors.textPrimary),
                        decoration: InputDecoration(
                          labelText: 'Service Name *',
                          labelStyle: TextStyle(color: colors.textSecondary),
                          prefixIcon: Icon(Icons.local_laundry_service_outlined, size: 20, color: colors.textSecondary),
                          filled: true,
                          fillColor: colors.inputFill,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: colors.inputBorder),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: colors.inputBorder),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _maxWeightController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              style: TextStyle(color: colors.textPrimary),
                              decoration: InputDecoration(
                                labelText: 'Max Weight (kg) *',
                                labelStyle: TextStyle(color: colors.textSecondary),
                                prefixIcon: Icon(Icons.scale_outlined, size: 20, color: colors.textSecondary),
                                filled: true,
                                fillColor: colors.inputFill,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: colors.inputBorder),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: colors.inputBorder),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _bundlePriceController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              style: TextStyle(color: colors.textPrimary),
                              decoration: InputDecoration(
                                labelText: 'Bundle Price (₱) *',
                                labelStyle: TextStyle(color: colors.textSecondary),
                                prefixText: '₱ ',
                                prefixStyle: TextStyle(color: colors.textPrimary),
                                filled: true,
                                fillColor: colors.inputFill,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: colors.inputBorder),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: colors.inputBorder),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _descriptionController,
                        maxLines: 2,
                        style: TextStyle(color: colors.textPrimary),
                        decoration: InputDecoration(
                          labelText: 'Description',
                          labelStyle: TextStyle(color: colors.textSecondary),
                          prefixIcon: Icon(Icons.notes_outlined, size: 20, color: colors.textSecondary),
                          filled: true,
                          fillColor: colors.inputFill,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: colors.inputBorder),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: colors.inputBorder),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: selectedStatus,
                        dropdownColor: colors.cardBg,
                        style: TextStyle(color: colors.textPrimary),
                        decoration: InputDecoration(
                          labelText: 'Status',
                          labelStyle: TextStyle(color: colors.textSecondary),
                          prefixIcon: Icon(Icons.toggle_on_outlined, size: 20, color: colors.textSecondary),
                          filled: true,
                          fillColor: colors.inputFill,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: colors.inputBorder),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: colors.inputBorder),
                          ),
                        ),
                        items: [
                          DropdownMenuItem(
                            value: 'Active',
                            child: Text('Active', style: TextStyle(color: colors.textPrimary)),
                          ),
                          DropdownMenuItem(
                            value: 'Inactive',
                            child: Text('Inactive', style: TextStyle(color: colors.textPrimary)),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() {
                              selectedStatus = value;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text('Cancel', style: TextStyle(color: colors.textSecondary)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  onPressed: () async {
                    final String name = _nameController.text.trim();
                    final double? maxWeight = double.tryParse(_maxWeightController.text.trim());
                    final double? bundlePrice = double.tryParse(_bundlePriceController.text.trim());
                    final String description = _descriptionController.text.trim();

                    if (name.isEmpty ||
                        maxWeight == null ||
                        maxWeight <= 0 ||
                        bundlePrice == null ||
                        bundlePrice < 0) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter valid service details.'),
                        ),
                      );
                      return;
                    }

                    try {
                      if (isEditing) {
                        await _serviceService.updateService(
                          serviceId: service.serviceId,
                          serviceName: name,
                          maxWeight: maxWeight,
                          bundlePrice: bundlePrice,
                          description: description,
                          status: selectedStatus,
                        );
                      } else {
                        await _serviceService.addService(
                          serviceName: name,
                          maxWeight: maxWeight,
                          bundlePrice: bundlePrice,
                          description: description,
                          status: selectedStatus,
                        );
                      }

                      if (!dialogContext.mounted) return;
                      Navigator.pop(dialogContext);

                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isEditing
                                ? 'Service updated successfully!'
                                : 'Service added successfully!',
                          ),
                        ),
                      );
                    } catch (e) {
                      if (!dialogContext.mounted) return;
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  },
                  child: Text(isEditing ? 'Update' : 'Add Service'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deleteService(LaundryService service) async {
    final colors = ThemeController.colors;
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: colors.cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: colors.border),
          ),
          title: Text(
            'Delete Service',
            style: TextStyle(fontWeight: FontWeight.bold, color: colors.textPrimary),
          ),
          content: Text(
            'Are you sure you want to delete ${service.serviceName}?',
            style: TextStyle(color: colors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text('Cancel', style: TextStyle(color: colors.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.errorText,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await _serviceService.deleteService(service.serviceId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Service deleted successfully!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting service: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.themeModeNotifier,
      builder: (context, currentMode, _) {
        final colors = ThemeController.of(context);

        return Scaffold(
          backgroundColor: colors.pageBg,
          appBar: AppBar(
            backgroundColor: colors.pageBg,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            iconTheme: IconThemeData(color: colors.textPrimary),
            title: Text(
              'Services',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                  onPressed: () => _showServiceDialog(),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text(
                    'Add Service',
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
                  // Search Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: TextField(
                      controller: _searchController,
                      style: TextStyle(color: colors.textPrimary),
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val.trim().toLowerCase();
                          currentPage = 1;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Search services...',
                        hintStyle: TextStyle(color: colors.textMuted),
                        prefixIcon: Icon(Icons.search_rounded, color: colors.textMuted),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.clear_rounded, color: colors.textMuted),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchQuery = '';
                                    currentPage = 1;
                                  });
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: colors.inputFill,
                        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: colors.inputBorder),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: colors.inputBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: colors.primary, width: 1.5),
                        ),
                      ),
                    ),
                  ),

                  // Service Stream List
                  Expanded(
                    child: StreamBuilder<List<LaundryService>>(
                      stream: _serviceService.getServices(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator(color: colors.primary));
                        }

                        if (snapshot.hasError) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                'Error loading services:\n${snapshot.error}',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: colors.errorText),
                              ),
                            ),
                          );
                        }

                        final allServices = snapshot.data ?? [];
                        final filteredServices = allServices.where((s) {
                          if (_searchQuery.isEmpty) return true;
                          return s.serviceName.toLowerCase().contains(_searchQuery) ||
                              s.description.toLowerCase().contains(_searchQuery);
                        }).toList();

                        if (filteredServices.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _searchQuery.isNotEmpty
                                      ? Icons.search_off_rounded
                                      : Icons.local_laundry_service_outlined,
                                  size: 56,
                                  color: colors.textMuted.withValues(alpha: 0.35),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _searchQuery.isNotEmpty
                                      ? 'No services matching "$_searchQuery"'
                                      : 'No services created yet',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: colors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        final int totalPages = filteredServices.isEmpty
                            ? 1
                            : (filteredServices.length / servicesPerPage).ceil();

                        final int effectivePage = currentPage > totalPages
                            ? totalPages
                            : (currentPage < 1 ? 1 : currentPage);

                        final int startIndex =
                            (effectivePage - 1) * servicesPerPage;
                        final int endIndex = (startIndex + servicesPerPage)
                            .clamp(0, filteredServices.length);

                        final paginatedServices = filteredServices.isEmpty
                            ? <LaundryService>[]
                            : filteredServices.sublist(startIndex, endIndex);

                        return Column(
                          children: [
                            Expanded(
                              child: ListView.builder(
                                padding: EdgeInsets.fromLTRB(
                                    16, 0, 16, totalPages > 1 ? 16 : 80),
                                itemCount: paginatedServices.length,
                                itemBuilder: (context, index) {
                                  final service = paginatedServices[index];
                            final isActive = service.status == 'Active';

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
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
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: 44,
                                          height: 44,
                                          decoration: BoxDecoration(
                                            color: colors.primaryLight,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Icon(
                                            Icons.local_laundry_service_rounded,
                                            color: colors.primary,
                                            size: 24,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                service.serviceName,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                  color: colors.textPrimary,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: colors.primaryLight,
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                    child: Text(
                                                      'Up to ${service.maxWeight} kg',
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        color: colors.primary,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: isActive ? colors.successBg : colors.errorBg,
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                    child: Text(
                                                      service.status,
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        color: isActive ? colors.successText : colors.errorText,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        PopupMenuButton<String>(
                                          icon: Icon(Icons.more_vert_rounded, size: 20, color: colors.textSecondary),
                                          color: colors.cardBg,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            side: BorderSide(color: colors.border),
                                          ),
                                          onSelected: (value) {
                                            if (value == 'edit') {
                                              _showServiceDialog(service: service);
                                            } else if (value == 'delete') {
                                              _deleteService(service);
                                            }
                                          },
                                          itemBuilder: (context) => [
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
                                            PopupMenuItem(
                                              value: 'delete',
                                              child: Row(
                                                children: [
                                                  Icon(Icons.delete_outline, size: 18, color: colors.errorText),
                                                  const SizedBox(width: 8),
                                                  Text('Delete', style: TextStyle(color: colors.errorText)),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    if (service.description.isNotEmpty) ...[
                                      const SizedBox(height: 10),
                                      Text(
                                        service.description,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: colors.textSecondary,
                                        ),
                                      ),
                                    ],
                                    Divider(height: 20, color: colors.divider),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Bundle Price',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: colors.textSecondary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        Text(
                                          '₱${service.bundlePrice.toStringAsFixed(2)}',
                                          style: TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.bold,
                                            color: colors.primary,
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
                                color: colors.primary,
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
                                    color: colors.textPrimary,
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
      ),
    ),
    // Action button moved to AppBar for consistency with Orders & Inventory
    // floatingActionButton: FloatingActionButton.extended(
    //   backgroundColor: colors.primary,
    //   foregroundColor: Colors.white,
    //   elevation: 3,
    //   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    //   onPressed: () => _showServiceDialog(),
    //   icon: const Icon(Icons.add_rounded),
    //   label: const Text('Add Service', style: TextStyle(fontWeight: FontWeight.bold)),
    // ),
  );
      },
    );
  }
}