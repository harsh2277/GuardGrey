import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../modules/admin/data/admin_dummy_data.dart';
import '../../modules/admin/models/client_model.dart';
import '../../modules/admin/models/site_model.dart';
import '../../modules/admin/widgets/dropdown_selector.dart';
import '../../modules/admin/widgets/selected_site_chip.dart';
import '../../modules/admin/widgets/site_selector_bottom_sheet.dart';

class ClientEditorResult {
  const ClientEditorResult({
    required this.client,
    required this.siteIds,
  });

  final ClientModel client;
  final List<String> siteIds;
}

class AddClientScreen extends StatefulWidget {
  const AddClientScreen({
    super.key,
    this.client,
    required this.allSites,
    this.initialSiteIds = const <String>[],
  });

  final ClientModel? client;
  final List<SiteModel> allSites;
  final List<String> initialSiteIds;

  bool get isEditing => client != null;

  @override
  State<AddClientScreen> createState() => _AddClientScreenState();
}

class _AddClientScreenState extends State<AddClientScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late String? _selectedBranchId;
  late List<SiteModel> _selectedSites;

  @override
  void initState() {
    super.initState();
    final client = widget.client;
    _nameController = TextEditingController(text: client?.name ?? '');
    _emailController = TextEditingController(text: client?.email ?? '');
    _phoneController = TextEditingController(text: client?.phone ?? '');
    _selectedBranchId = client?.branchId;
    final initialIds = widget.initialSiteIds.isNotEmpty
        ? widget.initialSiteIds
        : (client?.siteIds ?? const <String>[]);
    _selectedSites = widget.allSites
        .where((site) => initialIds.contains(site.id))
        .toList(growable: false);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  List<SiteModel> get _branchSites {
    final branchId = _selectedBranchId;
    if (branchId == null || branchId.isEmpty) {
      return AdminDummyData.sites;
    }

    return widget.allSites
        .where((site) => site.branchId == branchId)
        .toList(growable: false);
  }

  Future<void> _openSiteSelector() async {
    final selectedSites = await SiteSelectorBottomSheet.show(
      context,
      allSites: _branchSites,
      initiallySelectedIds: _selectedSites.map((site) => site.id).toList(),
    );

    if (selectedSites != null) {
      setState(() {
        _selectedSites = selectedSites;
      });
    }
  }

  void _handleBranchChanged(String? value) {
    setState(() {
      _selectedBranchId = value;
      if (value == null || value.isEmpty) {
        _selectedSites = const <SiteModel>[];
      } else {
        _selectedSites = _selectedSites
            .where((site) => site.branchId == value)
            .toList(growable: false);
      }
    });
  }

  void _saveClient() {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    final client = ClientModel(
      id: widget.client?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      branchId: _selectedBranchId!,
      siteIds: _selectedSites.map((site) => site.id).toList(growable: false),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
    );

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

    Navigator.pop(
      context,
      ClientEditorResult(
        client: client,
        siteIds: _selectedSites.map((site) => site.id).toList(growable: false),
      ),
    );
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
      body: SingleChildScrollView(
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
                items: AdminDummyData.branches
                    .map(
                      (branch) => DropdownSelectorItem(
                        id: branch.id,
                        label: branch.name,
                      ),
                    )
                    .toList(growable: false),
                onChanged: _handleBranchChanged,
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
                            : _openSiteSelector,
                        icon: const Icon(Icons.add_business_outlined, size: 18),
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
                    else if (_selectedSites.isEmpty)
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
                        children: _selectedSites
                            .map(
                              (site) => SelectedSiteChip(
                                site: site,
                                onRemove: () {
                                  setState(() {
                                    _selectedSites = _selectedSites
                                        .where((item) => item.id != site.id)
                                        .toList(growable: false);
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
}
