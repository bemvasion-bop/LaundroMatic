import 'package:flutter/material.dart';

import '../controllers/theme_controller.dart';
import '../models/customer.dart';
import '../services/customer_service.dart';

class CustomerPage extends StatefulWidget {
  const CustomerPage({super.key});

  @override
  State<CustomerPage> createState() => _CustomerPageState();
}

class _CustomerPageState extends State<CustomerPage> {
  final CustomerService _customerService = CustomerService();

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  String _searchQuery = '';
  int currentPage = 1;
  static const int customersPerPage = 15;

  @override
  void dispose() {
    _searchController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _showCustomerDialog({Customer? customer}) {
    final bool isEditing = customer != null;

    if (isEditing) {
      _nameController.text = customer.name;
      _phoneController.text = customer.phone;
      _emailController.text = customer.email;
      _addressController.text = customer.address;
    } else {
      _nameController.clear();
      _phoneController.clear();
      _emailController.clear();
      _addressController.clear();
    }

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            isEditing ? 'Edit Customer' : 'Add New Customer',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
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
                    decoration: InputDecoration(
                      labelText: 'Full Name *',
                      prefixIcon: const Icon(Icons.person_outline, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Phone Number *',
                      prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email Address',
                      prefixIcon: const Icon(Icons.email_outlined, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _addressController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Address',
                      prefixIcon: const Icon(Icons.location_on_outlined, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E64D4),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              onPressed: () async {
                final name = _nameController.text.trim();
                final phone = _phoneController.text.trim();
                final email = _emailController.text.trim();
                final address = _addressController.text.trim();

                if (name.isEmpty || phone.isEmpty) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text('Name and phone number are required.'),
                    ),
                  );
                  return;
                }

                try {
                  if (isEditing) {
                    await _customerService.updateCustomer(
                      customerId: customer.customerId,
                      name: name,
                      phone: phone,
                      email: email,
                      address: address,
                    );
                  } else {
                    await _customerService.addCustomer(
                      name: name,
                      phone: phone,
                      email: email,
                      address: address,
                    );
                  }

                  if (!dialogContext.mounted) return;
                  Navigator.pop(dialogContext);

                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isEditing
                            ? 'Customer updated successfully!'
                            : 'Customer added successfully!',
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
              child: Text(isEditing ? 'Update' : 'Add Customer'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteCustomer(Customer customer) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Delete Customer',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Are you sure you want to delete ${customer.name}? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
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
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await _customerService.deleteCustomer(customer.customerId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Customer deleted successfully!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting customer: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.themeModeNotifier,
      builder: (context, themeMode, _) {
        final colors = ThemeController.of(context);
        final isDark = colors.isDark;

        return Scaffold(
          backgroundColor: colors.pageBg,
          appBar: AppBar(
            backgroundColor: colors.pageBg,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            leading: Navigator.canPop(context)
                ? IconButton(
                    icon: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 19,
                      color: colors.textPrimary,
                    ),
                    onPressed: () => Navigator.pop(context),
                  )
                : null,
            title: Text(
              'Customers',
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
                  onPressed: () => _showCustomerDialog(),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text(
                    'Add Customer',
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
                  // Search Bar & Filter Header
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
                        hintText: 'Search by name, phone, or email...',
                        hintStyle: TextStyle(color: colors.textMuted),
                        prefixIcon:
                            Icon(Icons.search_rounded, color: colors.textMuted),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.clear_rounded,
                                    color: colors.textMuted),
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
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 0, horizontal: 16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: colors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: colors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                              color: colors.primary, width: 1.5),
                        ),
                      ),
                    ),
                  ),

              // Customer List
              Expanded(
                child: StreamBuilder<List<Customer>>(
                  stream: _customerService.getCustomers(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            'Error loading customers:\n${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      );
                    }

                    final allCustomers = snapshot.data ?? [];
                    final filteredCustomers = allCustomers.where((c) {
                      if (_searchQuery.isEmpty) return true;
                      return c.name.toLowerCase().contains(_searchQuery) ||
                          c.phone.toLowerCase().contains(_searchQuery) ||
                          c.email.toLowerCase().contains(_searchQuery) ||
                          c.address.toLowerCase().contains(_searchQuery);
                    }).toList();

                    if (filteredCustomers.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _searchQuery.isNotEmpty
                                  ? Icons.search_off_rounded
                                  : Icons.people_outline_rounded,
                              size: 56,
                              color: Colors.grey.shade300,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? 'No customers matching "$_searchQuery"'
                                  : 'No customers added yet',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final int totalPages = filteredCustomers.isEmpty
                        ? 1
                        : (filteredCustomers.length / customersPerPage).ceil();

                    final int effectivePage = currentPage > totalPages
                        ? totalPages
                        : (currentPage < 1 ? 1 : currentPage);

                    final int startIndex =
                        (effectivePage - 1) * customersPerPage;
                    final int endIndex = (startIndex + customersPerPage)
                        .clamp(0, filteredCustomers.length);

                    final paginatedCustomers = filteredCustomers.isEmpty
                        ? <Customer>[]
                        : filteredCustomers.sublist(startIndex, endIndex);

                    return Column(
                      children: [
                        Expanded(
                          child: ListView.builder(
                            padding: EdgeInsets.fromLTRB(
                                16, 0, 16, totalPages > 1 ? 16 : 80),
                            itemCount: paginatedCustomers.length,
                            itemBuilder: (context, index) {
                              final customer = paginatedCustomers[index];
                        final initial = customer.name.isNotEmpty
                            ? customer.name[0].toUpperCase()
                            : '?';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: colors.cardBg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: colors.border),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black
                                    .withValues(alpha: isDark ? 0.25 : 0.02),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 22,
                                  backgroundColor: colors.primaryLight,
                                  child: Text(
                                    initial,
                                    style: TextStyle(
                                      color: colors.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
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
                                        customer.name,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: colors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Icon(Icons.phone_outlined,
                                              size: 14,
                                              color: colors.textMuted),
                                          const SizedBox(width: 6),
                                          Text(
                                            customer.phone,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: colors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (customer.email.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(Icons.email_outlined,
                                                size: 14,
                                                color: colors.textMuted),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                customer.email,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: colors.textSecondary,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                      if (customer.address.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(Icons.location_on_outlined,
                                                size: 14,
                                                color: colors.textMuted),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                customer.address,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: colors.textSecondary,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                PopupMenuButton<String>(
                                  icon: Icon(Icons.more_vert_rounded,
                                      size: 20, color: colors.textMuted),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  onSelected: (value) {
                                    if (value == 'edit') {
                                      _showCustomerDialog(customer: customer);
                                    } else if (value == 'delete') {
                                      _deleteCustomer(customer);
                                    }
                                  },
                                  itemBuilder: (context) => const [
                                    PopupMenuItem(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit_outlined, size: 18),
                                          SizedBox(width: 8),
                                          Text('Edit'),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete_outline,
                                              size: 18, color: Colors.red),
                                          SizedBox(width: 8),
                                          Text('Delete',
                                              style: TextStyle(color: Colors.red)),
                                        ],
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
      // floatingActionButton: FloatingActionButton.extended(
      //   backgroundColor: colors.primary,
      //   foregroundColor: Colors.white,
      //   elevation: 3,
      //   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      //   onPressed: () => _showCustomerDialog(),
      //   icon: const Icon(Icons.person_add_rounded),
      //   label: const Text('Add Customer',
      //       style: TextStyle(fontWeight: FontWeight.bold)),
      // ),
    );
      },
    );
  }
}