import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../widgets/location_input_field.dart';
import '../models/branch_model.dart';
import '../models/client_model.dart';
import '../models/location_picker_result.dart';
import '../models/manager_model.dart';
import '../models/site_model.dart';
import '../services/firestore_admin_repository.dart';
import '../widgets/dropdown_selector.dart';
import 'location_picker_screen.dart';

class AddSiteScreen extends StatefulWidget {
  const AddSiteScreen({super.key, this.site});

  final SiteModel? site;

  bool get isEditing => site != null;

  @override
  State<AddSiteScreen> createState() => _AddSiteScreenState();
}

class _AddSiteScreenState extends State<AddSiteScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirestoreAdminRepository _repository =
      FirestoreAdminRepository.instance;
  late final TextEditingController _nameController;
  late final TextEditingController _locationController;
  late final TextEditingController _addressController;
  late final TextEditingController _buildingFloorController;
  late final TextEditingController _descriptionController;
  late final Future<List<ClientModel>> _clientsFuture;
  late final Future<List<BranchModel>> _branchesFuture;
  late final Future<List<ManagerModel>> _managersFuture;
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
    _locationController = TextEditingController(text: site?.location ?? '');
    _addressController = TextEditingController(text: site?.address ?? '');
    _buildingFloorController = TextEditingController(
      text: site?.buildingFloor ?? '',
    );
    _descriptionController = TextEditingController(
      text: site?.description ?? '',
    );
    _selectedLatitude = site?.latitude;
    _selectedLongitude = site?.longitude;
    _selectedClientId = site?.clientId;
    _selectedBranchId = site?.branchId;
    _selectedManagerId = site?.managerId;
    _clientsFuture = _repository.fetchClients();
    _branchesFuture = _repository.fetchBranches();
    _managersFuture = _repository.fetchManagers();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _addressController.dispose();
    _buildingFloorController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _openLocationPicker() async {
    final result = await Navigator.push<LocationPickerResult>(
      context,
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(
          initialAddress: _addressController.text.trim(),
          initialLatitude: _selectedLatitude,
          initialLongitude: _selectedLongitude,
          initialLocationTitle: _locationController.text.trim(),
          initialBuildingFloor: _buildingFloorController.text.trim(),
        ),
      ),
    );

    if (result == null) {
      return;
    }

    setState(() {
      _locationController.text = result.locationTitle.isNotEmpty
          ? result.locationTitle
          : result.address;
      _addressController.text = result.address;
      _buildingFloorController.text = result.buildingFloor;
      _selectedLatitude = result.latitude;
      _selectedLongitude = result.longitude;
    });
  }

  Future<void> _saveSite(List<BranchModel> branches) async {
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) {
      return;
    }

    final clientId = _selectedClientId!;
    final branchId = _selectedBranchId!;
    final managerId = _selectedManagerId!;
    BranchModel? branch;
    for (final item in branches) {
      if (item.id == branchId) {
        branch = item;
        break;
      }
    }

    final location = _locationController.text.trim();
    final address = _addressController.text.trim();
    final site = SiteModel(
      id: widget.site?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      clientId: clientId,
      branchId: branchId,
      managerId: managerId,
      location: location.isEmpty ? branch?.city ?? '' : location,
      address: address,
      buildingFloor: _buildingFloorController.text.trim(),
      latitude: _selectedLatitude,
      longitude: _selectedLongitude,
      description: _descriptionController.text.trim(),
      createdDate: widget.site?.createdDate ?? '',
      lastUpdated: '',
      isActive: widget.site?.isActive ?? true,
    );

    try {
      await _repository.saveSite(site);
      if (!mounted) {
        return;
      }

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
      Navigator.pop(context);
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to save site. Please try again.',
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
          widget.isEditing ? 'Edit Site' : 'Add Site',
          style: AppTextStyles.title.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      body: FutureBuilder<List<ClientModel>>(
        future: _clientsFuture,
        builder: (context, clientsSnapshot) {
          if (clientsSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (clientsSnapshot.hasError) {
            return _buildErrorState();
          }

          return FutureBuilder<List<BranchModel>>(
            future: _branchesFuture,
            builder: (context, branchesSnapshot) {
              if (branchesSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (branchesSnapshot.hasError) {
                return _buildErrorState();
              }

              return FutureBuilder<List<ManagerModel>>(
                future: _managersFuture,
                builder: (context, managersSnapshot) {
                  if (managersSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (managersSnapshot.hasError) {
                    return _buildErrorState();
                  }

                  final clients = clientsSnapshot.data ?? const <ClientModel>[];
                  final branches =
                      branchesSnapshot.data ?? const <BranchModel>[];
                  final managers =
                      managersSnapshot.data ?? const <ManagerModel>[];

                  return SingleChildScrollView(
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
                            items: clients
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
                            items: branches
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
                            items: managers
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
                          _buildFieldLabel('Location'),
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
                          _buildFieldLabel('Building / Floor'),
                          const SizedBox(height: 8),
                          _buildTextField(
                            controller: _buildingFloorController,
                            hintText: 'Enter building / floor details',
                          ),
                          const SizedBox(height: 18),
                          _buildFieldLabel('Address'),
                          const SizedBox(height: 8),
                          _buildTextField(
                            controller: _addressController,
                            hintText: 'Add address details',
                            maxLines: 3,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Address is required';
                              }
                              return null;
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
                              onPressed: () => _saveSite(branches),
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
                  );
                },
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

  Widget _buildErrorState() {
    return Center(
      child: Text(
        'Unable to load site form data.',
        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.neutral500),
      ),
    );
  }
}
