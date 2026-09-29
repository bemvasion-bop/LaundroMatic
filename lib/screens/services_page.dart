import 'package:flutter/material.dart';

import '../models/service.dart';
import '../services/service_service.dart';

class ServicesPage extends StatefulWidget {
  const ServicesPage({super.key});

  @override
  State<ServicesPage> createState() => _ServicesPageState();
}

class _ServicesPageState extends State<ServicesPage> {
  final ServiceService _serviceService = ServiceService();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _maxWeightController = TextEditingController();
  final TextEditingController _bundlePriceController = TextEditingController();
  final TextEditingController _descriptionController =
      TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _maxWeightController.dispose();
    _bundlePriceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // Show Add/Edit Service dialog
  void _showServiceDialog({LaundryService? service}) {
    final bool isEditing = service != null;

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
              title: Text(
                isEditing ? 'Edit Service' : 'Add Service',
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Service Name',
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 12),

                    TextField(
                      controller: _maxWeightController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Maximum Weight (kg)',
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 12),

                    TextField(
                      controller: _bundlePriceController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Bundle Price (₱)',
                        prefixText: '₱ ',
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 12),

                    TextField(
                      controller: _descriptionController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 12),

                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: selectedStatus,
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Active',
                          child: Text('Active'),
                        ),
                        DropdownMenuItem(
                          value: 'Inactive',
                          child: Text('Inactive'),
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
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Cancel'),
                ),

                ElevatedButton(
                  onPressed: () async {
                    final String name = _nameController.text.trim();
                    final double? maxWeight = double.tryParse(
                      _maxWeightController.text.trim(),
                    );
                    final double? bundlePrice = double.tryParse(
                      _bundlePriceController.text.trim(),
                    );
                    final String description =
                        _descriptionController.text.trim();

                    if (name.isEmpty ||
                        maxWeight == null ||
                        maxWeight <= 0 ||
                        bundlePrice == null ||
                        bundlePrice < 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Please enter valid service details.',
                          ),
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

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: $e'),
                        ),
                      );
                    }
                  },
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

  // Delete service
  Future<void> _deleteService(LaundryService service) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Service'),
          content: Text(
            'Are you sure you want to delete ${service.serviceName}?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
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
        const SnackBar(
          content: Text('Service deleted successfully!'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting service: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Services'),
      ),

      body: StreamBuilder<List<LaundryService>>(
        stream: _serviceService.getServices(),
        builder: (context, snapshot) {
          // Loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // Error
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Error loading services:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final List<LaundryService> services = snapshot.data ?? [];

          // Empty
          if (services.isEmpty) {
            return const Center(
              child: Text(
                'No services found.',
                style: TextStyle(
                  fontSize: 16,
                ),
              ),
            );
          }

          // Service list
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: services.length,
            itemBuilder: (context, index) {
              final LaundryService service = services[index];

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(
                      Icons.local_laundry_service,
                    ),
                  ),

                  title: Text(
                    service.serviceName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Up to ${service.maxWeight} kg',
                        ),

                        Text(
                          'Bundle Price: ₱${service.bundlePrice.toStringAsFixed(2)}',
                        ),

                        if (service.description.isNotEmpty)
                          Text(
                            service.description,
                          ),

                        const SizedBox(height: 4),

                        Text(
                          'Status: ${service.status}',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: service.status == 'Active'
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),

                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        _showServiceDialog(
                          service: service,
                        );
                      }

                      if (value == 'delete') {
                        _deleteService(service);
                      }
                    },
                    itemBuilder: (context) {
                      return const [
                        PopupMenuItem(
                          value: 'edit',
                          child: Text('Edit'),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Text('Delete'),
                        ),
                      ];
                    },
                  ),
                ),
              );
            },
          );
        },
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showServiceDialog();
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Service'),
      ),
    );
  }
}