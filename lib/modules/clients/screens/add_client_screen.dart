import 'package:flutter/material.dart';

import 'package:guardgrey/core/theme/app_colors.dart';
import 'package:guardgrey/core/theme/app_text_styles.dart';
import 'package:guardgrey/core/widgets/dropdown_selector.dart';
import 'package:guardgrey/core/widgets/selected_site_chip.dart';
import 'package:guardgrey/core/widgets/site_selector_bottom_sheet.dart';
import 'package:guardgrey/modules/branches/models/branch_model.dart';
import 'package:guardgrey/modules/clients/models/client_model.dart';
import 'package:guardgrey/modules/sites/models/site_model.dart';
import 'package:guardgrey/services/firebase/firestore_admin_repository.dart';

class AddClientScreen extends StatefulWidget {
  const AddClientScreen({super.key, this.client});

  final ClientModel? client;

  bool get isEditing => client != null;

  @override
  State<AddClientScreen> createState() => _AddClientScreenState();
}

class _AddClientScreenState extends State<AddClientScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirestoreAdminRepository _repository =
      FirestoreAdminRepository.instance;
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late String? _selectedBranchId;
  late final Set<String> _selectedSiteIds;
  late final Future<List<BranchModel>> _branchesFuture;
  late final Future<List<SiteModel>> _sitesFuture;

  @override
  void initState() {
    super.initState();
    final client = widget.client;
    _nameController = TextEditingController(text: client?.name ?? '');
    _emailController = TextEditingController(text: client?.email ?? '');
    _phoneController = TextEditingController(text: client?.phone ?? '');
    _selectedBranchId = client?.branchId;
    _selectedSiteIds = (client?.siteIds ?? const <String>[]).toSet();
    _branchesFuture = _repository.fetchBranches();
    _sitesFuture = _repository.fetchSites();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  List<SiteModel> _branchSites(List<SiteModel> allSites) {
    final branchId = _selectedBranchId;
    if (branchId == null || branchId.isEmpty) {
      return allSites;
    }

    return allSites
        .where((site) => site.branchId == branchId)
        .toList(growable: false);
  }

  Future<void> _openSiteSelector(List<SiteModel> allSites) async {
    final selectedSites = await SiteSelectorBottomSheet.show(
      context,
      allSites: _branchSites(allSites),
      initiallySelectedIds: _selectedSiteIds.toList(growable: false),
    );

    if (selectedSites != null) {
      setState(() {
        _selectedSiteIds
          ..clear()
          ..addAll(selectedSites.map((site) => site.id));
      });
    }
  }

  void _handleBranchChanged(String? value, List<SiteModel> allSites) {
    final availableSiteIds = allSites
        .where((site) => value != null && site.branchId == value)
        .map((site) => site.id)
        .toSet();

    setState(() {
      _selectedBranchId = value;
      if (value == null || value.isEmpty) {
        _selectedSiteIds.clear();
      } else {
        _selectedSiteIds.removeWhere(
          (siteId) => !availableSiteIds.contains(siteId),
        );
      }
    });
  }

  Future<void> _saveClient() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      return;
    }

    final client = ClientModel(
      id: widget.client?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      branchId: _selectedBranchId!,
      siteIds: _selectedSiteIds.toList(growable: false),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
    );

    try {
      await _repository.saveClient(client);
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isEditing
                ? 'Client updated successfully.'
                : 'Client created successfully.',
            style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
          ),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to save client. Please try again.',
            style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          widget.isEditing ? 'Edit Client' : 'Add Client',
          style: AppTextStyles.title.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      body: FutureBuilder<List<BranchModel>>(
        future: _branchesFuture,
        builder: (context, branchesSnapshot) {
          if (branchesSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (branchesSnapshot.hasError) {
            return _buildErrorState();
          }

          return FutureBuilder<List<SiteModel>>(
            future: _sitesFuture,
            builder: (context, sitesSnapshot) {
              if (sitesSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (sitesSnapshot.hasError) {
                return _buildErrorState();
              }

              final branches = branchesSnapshot.data ?? const <BranchModel>[];
              final allSites = sitesSnapshot.data ?? const <SiteModel>[];
              final selectedSites = allSites
                  .where((site) => _selectedSiteIds.contains(site.id))
                  .toList(growable: false);

              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFieldLabel('Client Name'),
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: _nameController,
                        hintText: 'Enter client name',
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Client name is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),
                      _buildFieldLabel('Email ID'),
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: _emailController,
                        hintText: 'Enter email ID',
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Email ID is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),
                      _buildFieldLabel('Mobile Number'),
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: _phoneController,
                        hintText: 'Enter mobile number',
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Mobile number is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),
                      _buildFieldLabel('Assign Branch'),
                      const SizedBox(height: 8),
                      DropdownSelector(
                        value: _selectedBranchId,
                        hintText: 'Select branch',
                        items: branches
                            .map(
                              (branch) => DropdownSelectorItem(
                                id: branch.id,
                                label: branch.name,
                              ),
                            )
                            .toList(growable: false),
                        onChanged: (value) =>
                            _handleBranchChanged(value, allSites),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Branch is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),
                      _buildFieldLabel('Assign Sites'),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.neutral200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: _selectedBranchId == null
                                    ? null
                                    : () => _openSiteSelector(allSites),
                                icon: const Icon(
                                  Icons.add_business_outlined,
                                  size: 18,
                                ),
                                label: const Text('Assign Sites'),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(double.infinity, 52),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (_selectedBranchId == null)
                              Text(
                                'Select a branch before assigning sites.',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.neutral500,
                                ),
                              )
                            else if (selectedSites.isEmpty)
                              Text(
                                'No sites assigned yet.',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.neutral500,
                                ),
                              )
                            else
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: selectedSites
                                    .map(
                                      (site) => SelectedSiteChip(
                                        site: site,
                                        onRemove: () {
                                          setState(() {
                                            _selectedSiteIds.remove(site.id);
                                          });
                                        },
                                      ),
                                    )
                                    .toList(growable: false),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _saveClient,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 54),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: const Text('Save Client'),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: AppTextStyles.bodyMedium.copyWith(
        fontWeight: FontWeight.w600,
        color: AppColors.neutral800,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.neutral400,
        ),
        filled: true,
        fillColor: AppColors.neutral50,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.neutral200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.neutral200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary500, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Text(
        'Unable to load client form data.',
        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.neutral500),
      ),
    );
  }
}
