import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../widgets/location_input_field.dart';
import '../data/admin_dummy_data.dart';
import '../models/location_picker_result.dart';
import '../models/site_model.dart';
import '../widgets/dropdown_selector.dart';
import 'location_picker_screen.dart';

class AddSiteScreen extends StatefulWidget {
  final SiteModel? site;

  const AddSiteScreen({
    super.key,
    this.site,
  });

  bool get isEditing => site != null;

  @override
  State<AddSiteScreen> createState() => _AddSiteScreenState();
}

class _AddSiteScreenState extends State<AddSiteScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _locationController;
  late final TextEditingController _descriptionController;
  double? _selectedLatitude;
  double? _selectedLongitude;
  String? _selectedClientId;
  String? _selectedBranchId;
  String? _selectedManagerId;

  @override
  void initState() {
    super.initState();
    final site = widget.site;
    _nameController = TextEditingController(text: site?.name ?? '');
    _locationController = TextEditingController(
      text: site?.address.isNotEmpty == true
          ? site!.address
          : site?.location ?? '',
    );
    _descriptionController = TextEditingController(text: site?.description ?? '');
    _selectedLatitude = site?.latitude;
    _selectedLongitude = site?.longitude;
    _selectedClientId = site?.clientId;
    _selectedBranchId = site?.branchId;
    _selectedManagerId = site?.managerId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _openLocationPicker() async {
    final result = await Navigator.push<LocationPickerResult>(
      context,
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(
          initialAddress: _locationController.text.trim(),
          initialLatitude: _selectedLatitude,
          initialLongitude: _selectedLongitude,
        ),
      ),
    );

    if (result == null) return;

    setState(() {
      _locationController.text = result.address;
      _selectedLatitude = result.latitude;
      _selectedLongitude = result.longitude;
    });
  }

  void _saveSite() {
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) return;

    final clientId = _selectedClientId!;
    final branchId = _selectedBranchId!;
    final managerId = _selectedManagerId!;
    final branch = AdminDummyData.getBranchById(branchId);
    final address = _locationController.text.trim();
    final location = address.isEmpty
        ? branch?.city ?? ''
        : address;

    final site = SiteModel(
      id: widget.site?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      clientId: clientId,
      branchId: branchId,
      managerId: managerId,
      location: location,
      address: address,
      latitude: _selectedLatitude,
      longitude: _selectedLongitude,
      description: _descriptionController.text.trim(),
      createdDate: widget.site?.createdDate ?? '26 Apr 2026',
      lastUpdated: '26 Apr 2026',
      isActive: widget.site?.isActive ?? true,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.isEditing
              ? 'Site updated successfully.'
              : 'Site created successfully.',
          style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
        ),
        backgroundColor: AppColors.success,
      ),
    );

    Navigator.pop(context, site);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          widget.isEditing ? 'Edit Site' : 'Add Site',
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
              _buildFieldLabel('Site Name'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _nameController,
                hintText: 'Enter site name',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Site name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 18),
              _buildFieldLabel('Select Client'),
              const SizedBox(height: 8),
              DropdownSelector(
                value: _selectedClientId,
                hintText: 'Select client',
                items: AdminDummyData.clients
                    .map(
                      (client) => DropdownSelectorItem(
                        id: client.id,
                        label: client.name,
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) {
                  setState(() {
                    _selectedClientId = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Client is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 18),
              _buildFieldLabel('Select Branch'),
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
                onChanged: (value) {
                  setState(() {
                    _selectedBranchId = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Branch is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 18),
              _buildFieldLabel('Assign Manager'),
              const SizedBox(height: 8),
              DropdownSelector(
                value: _selectedManagerId,
                hintText: 'Select manager',
                items: AdminDummyData.managers
                    .map(
                      (manager) => DropdownSelectorItem(
                        id: manager.id,
                        label: manager.name,
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) {
                  setState(() {
                    _selectedManagerId = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Manager is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 18),
              _buildFieldLabel('Location / Address'),
              const SizedBox(height: 8),
              FormField<String>(
                initialValue: _locationController.text,
                validator: (value) {
                  if (_locationController.text.trim().isEmpty) {
                    return 'Location is required';
                  }
                  return null;
                },
                builder: (field) {
                  return LocationInputField(
                    address: _locationController.text,
                    errorText: field.errorText,
                    onTap: () async {
                      await _openLocationPicker();
                      if (mounted) {
                        field.didChange(_locationController.text);
                      }
                    },
                  );
                },
              ),
              const SizedBox(height: 18),
              _buildFieldLabel('Description'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _descriptionController,
                hintText: 'Add notes about this site',
                maxLines: 4,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveSite,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 54),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Text('Save Site'),
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
    int maxLines = 1,
    bool readOnly = false,
    VoidCallback? onTap,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      maxLines: maxLines,
      readOnly: readOnly,
      onTap: onTap,
      decoration: InputDecoration(
        hintText: hintText,
        suffixIcon: suffixIcon,
        hintStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.neutral400,
        ),
        filled: true,
        fillColor: AppColors.neutral50,
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: maxLines > 1 ? 16 : 14,
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
