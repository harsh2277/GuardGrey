import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../widgets/location_input_field.dart';
import '../data/admin_dummy_data.dart';
import '../models/branch_model.dart';
import '../models/location_picker_result.dart';
import '../models/site_model.dart';
import '../widgets/selected_site_chip.dart';
import '../widgets/site_selector_bottom_sheet.dart';
import 'location_picker_screen.dart';

class AddBranchScreen extends StatefulWidget {
  final BranchModel? branch;

  const AddBranchScreen({
    super.key,
    this.branch,
  });

  bool get isEditing => branch != null;

  @override
  State<AddBranchScreen> createState() => _AddBranchScreenState();
}

class _AddBranchScreenState extends State<AddBranchScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _branchNameController;
  late final TextEditingController _cityController;
  late final TextEditingController _addressController;
  late List<SiteModel> _selectedSites;
  double? _selectedLatitude;
  double? _selectedLongitude;

  @override
  void initState() {
    super.initState();
    final branch = widget.branch;
    _branchNameController = TextEditingController(text: branch?.name ?? '');
    _cityController = TextEditingController(text: branch?.city ?? '');
    _addressController = TextEditingController(text: branch?.address ?? '');
    _selectedLatitude = branch?.latitude;
    _selectedLongitude = branch?.longitude;
    _selectedSites =
        AdminDummyData.getSitesByIds(branch?.siteIds ?? const <String>[]);
  }

  @override
  void dispose() {
    _branchNameController.dispose();
    _cityController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _openSiteSelector() async {
    final selectedSites = await SiteSelectorBottomSheet.show(
      context,
      allSites: AdminDummyData.sites,
      initiallySelectedIds: _selectedSites.map((site) => site.id).toList(),
    );

    if (selectedSites != null) {
      setState(() {
        _selectedSites = selectedSites;
      });
    }
  }

  Future<void> _openLocationPicker() async {
    final result = await Navigator.push<LocationPickerResult>(
      context,
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(
          initialAddress: _addressController.text.trim(),
          initialLatitude: _selectedLatitude,
          initialLongitude: _selectedLongitude,
        ),
      ),
    );

    if (result == null) return;

    setState(() {
      _addressController.text = result.address;
      _cityController.text = _extractLocationLabel(result.address);
      _selectedLatitude = result.latitude;
      _selectedLongitude = result.longitude;
    });
  }

  void _saveBranch() {
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) return;

    final branch = BranchModel(
      id: widget.branch?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: _branchNameController.text.trim(),
      city: _cityController.text.trim(),
      address: _addressController.text.trim(),
      siteIds: _selectedSites.map((site) => site.id).toList(growable: false),
      latitude: _selectedLatitude,
      longitude: _selectedLongitude,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.isEditing
              ? 'Branch updated successfully.'
              : 'Branch created successfully.',
          style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
        ),
        backgroundColor: AppColors.success,
      ),
    );

    Navigator.pop(context, branch);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          widget.isEditing ? 'Edit Branch' : 'Add Branch',
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
              _buildFieldLabel('Branch Name'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _branchNameController,
                hintText: 'Enter branch name',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Branch name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 18),
              _buildFieldLabel('City / Location'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _cityController,
                hintText: 'Enter city or location',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'City / Location is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 18),
              _buildFieldLabel('Location'),
              const SizedBox(height: 8),
              FormField<String>(
                initialValue: _addressController.text,
                validator: (value) {
                  if (_addressController.text.trim().isEmpty) {
                    return 'Location is required';
                  }
                  return null;
                },
                builder: (field) {
                  return LocationInputField(
                    address: _addressController.text,
                    errorText: field.errorText,
                    onTap: () async {
                      await _openLocationPicker();
                      if (mounted) {
                        field.didChange(_addressController.text);
                      }
                    },
                  );
                },
              ),
              if (_selectedLatitude != null && _selectedLongitude != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.neutral200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Lat / Lng',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.neutral500,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_selectedLatitude!.toStringAsFixed(6)}, ${_selectedLongitude!.toStringAsFixed(6)}',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.neutral800,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 22),
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
                    Row(
                      children: [
                        Text(
                          'Assigned Sites',
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.neutral900,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${_selectedSites.length} selected',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.neutral500,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _openSiteSelector,
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
                    if (_selectedSites.isEmpty)
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
                            .toList(),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveBranch,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 54),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Text('Save Branch'),
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
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hintText,
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

  String _extractLocationLabel(String address) {
    final parts = address
        .split(',')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList(growable: false);

    if (parts.isEmpty) {
      return '';
    }

    if (parts.length >= 2) {
      return parts[1];
    }

    return parts.first;
  }
}
