import 'package:flutter/material.dart';

import 'package:guardgrey/core/theme/app_colors.dart';
import 'package:guardgrey/core/theme/app_text_styles.dart';
import 'package:guardgrey/core/widgets/selected_site_chip.dart';
import 'package:guardgrey/core/widgets/site_selector_bottom_sheet.dart';
import 'package:guardgrey/modules/managers/models/manager_model.dart';
import 'package:guardgrey/modules/sites/models/site_model.dart';
import 'package:guardgrey/services/firebase/firestore_admin_repository.dart';

class AddManagerScreen extends StatefulWidget {
  const AddManagerScreen({super.key, this.manager});

  final ManagerModel? manager;

  bool get isEditing => manager != null;

  @override
  State<AddManagerScreen> createState() => _AddManagerScreenState();
}

class _AddManagerScreenState extends State<AddManagerScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirestoreAdminRepository _repository =
      FirestoreAdminRepository.instance;
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final Set<String> _selectedSiteIds;
  late final Future<List<SiteModel>> _sitesFuture;

  @override
  void initState() {
    super.initState();
    final manager = widget.manager;
    _nameController = TextEditingController(text: manager?.name ?? '');
    _emailController = TextEditingController(text: manager?.email ?? '');
    _phoneController = TextEditingController(text: manager?.phone ?? '');
    _selectedSiteIds = (manager?.siteIds ?? const <String>[]).toSet();
    _sitesFuture = _repository.fetchSites();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _openSiteSelector(List<SiteModel> allSites) async {
    final selectedSites = await SiteSelectorBottomSheet.show(
      context,
      allSites: allSites,
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

  Future<void> _saveManager() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      return;
    }

    final manager = ManagerModel(
      id:
          widget.manager?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      siteIds: _selectedSiteIds.toList(growable: false),
    );

    try {
      await _repository.saveManager(manager);
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isEditing
                ? 'Manager updated successfully.'
                : 'Manager created successfully.',
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
            'Unable to save manager. Please try again.',
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
          widget.isEditing ? 'Edit Manager' : 'Add Manager',
          style: AppTextStyles.title.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      body: FutureBuilder<List<SiteModel>>(
        future: _sitesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _buildErrorState();
          }

          final allSites = snapshot.data ?? const <SiteModel>[];
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
                  _buildFieldLabel('Manager Name'),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _nameController,
                    hintText: 'Enter manager name',
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Manager name is required';
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
                            onPressed: () => _openSiteSelector(allSites),
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
                        if (selectedSites.isEmpty)
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
                      onPressed: _saveManager,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 54),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: const Text('Save Manager'),
                    ),
                  ),
                ],
              ),
            ),
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
        'Unable to load manager form data.',
        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.neutral500),
      ),
    );
  }
}
