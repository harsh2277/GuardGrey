import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:guardgrey/core/theme/app_colors.dart';
import 'package:guardgrey/core/theme/app_text_styles.dart';
import 'package:guardgrey/core/utils/date_time_display.dart';
import 'package:guardgrey/data/models/app_location.dart';
import 'package:guardgrey/data/models/field_visit_model.dart';
import 'package:guardgrey/data/models/manager_live_location_model.dart';
import 'package:guardgrey/data/models/manager_model.dart';
import 'package:guardgrey/data/repositories/field_visit_repository.dart';
import 'package:guardgrey/data/repositories/live_tracking_repository.dart';
import 'package:guardgrey/data/repositories/manager_repository.dart';
import 'package:guardgrey/data/services/firebase_storage_service.dart';
import 'package:guardgrey/features/location/models/location_picker_result.dart';
import 'package:guardgrey/features/location/screens/location_picker_screen.dart';

class FieldVisitFormScreen extends StatefulWidget {
  const FieldVisitFormScreen({super.key, this.initialSiteName});

  final String? initialSiteName;

  @override
  State<FieldVisitFormScreen> createState() => _FieldVisitFormScreenState();
}

class _FieldVisitFormScreenState extends State<FieldVisitFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _siteNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _picker = ImagePicker();
  final _storage = FirebaseStorageService.instance;
  final _repository = FieldVisitRepository.instance;
  final _managerRepository = ManagerRepository.instance;
  bool _isSaving = false;
  DateTime _selectedDateTime = DateTime.now();
  final List<XFile> _pickedImages = <XFile>[];
  double? _latitude;
  double? _longitude;
  String _address = '';

  @override
  void initState() {
    super.initState();
    _siteNameController.text = widget.initialSiteName ?? '';
  }

  @override
  void dispose() {
    _siteNameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _openLocationPicker() async {
    final result = await Navigator.push<LocationPickerResult>(
      context,
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(
          initialAddress: _address,
          initialLatitude: _latitude,
          initialLongitude: _longitude,
          initialLocationTitle: _siteNameController.text.trim(),
        ),
      ),
    );
    if (result == null) {
      return;
    }
    setState(() {
      _latitude = result.latitude;
      _longitude = result.longitude;
      _address = result.address;
      if (_siteNameController.text.trim().isEmpty &&
          result.locationTitle.isNotEmpty) {
        _siteNameController.text = result.locationTitle;
      }
    });
  }

  Future<void> _pickImages() async {
    if (_pickedImages.length >= FirebaseStorageService.maxImages) {
      _showMessage('You can upload a maximum of 5 images.', isError: true);
      return;
    }
    final files = await _picker.pickMultiImage();
    if (files.isEmpty) {
      return;
    }
    final remaining = FirebaseStorageService.maxImages - _pickedImages.length;
    setState(() {
      _pickedImages.addAll(files.take(remaining));
    });
  }

  Future<void> _selectDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime(2024),
      lastDate: DateTime(2035),
    );
    if (date == null || !mounted) {
      return;
    }
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
    );
    if (time == null) {
      return;
    }
    setState(() {
      _selectedDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _save(
    ManagerModel manager,
    ManagerLiveLocationModel? currentLocation,
  ) async {
    if (_isSaving) {
      return;
    }
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) {
      return;
    }
    if (_latitude == null || _longitude == null || _address.trim().isEmpty) {
      _showMessage('Location is required.', isError: true);
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final imageUrls = await _storage.uploadImages(
        folder: 'field_visits/${manager.id}',
        files: _pickedImages,
      );
      final visit = FieldVisitModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        managerId: manager.id,
        managerName: manager.name,
        phone: manager.phone,
        profileImage: manager.profileImage,
        siteName: _siteNameController.text.trim(),
        description: _descriptionController.text.trim(),
        location: AppLocation(
          lat: _latitude!,
          lng: _longitude!,
          address: _address,
        ),
        imageUrls: imageUrls,
        dateTime: _selectedDateTime,
      );
      await _repository.saveFieldVisit(visit);
      await _repository.saveManagerLiveLocation(
        ManagerLiveLocationModel(
          managerId: manager.id,
          managerName: manager.name,
          lat: _latitude!,
          lng: _longitude!,
          lastUpdated: DateTime.now(),
          checkInLocation: AppLocation(
            lat: _latitude!,
            lng: _longitude!,
            address: _address,
          ),
          branchImage: currentLocation?.branchImage ?? '',
          helplineNumber:
              currentLocation?.helplineNumber ?? '+91 1800 123 4455',
          whatsappNumber: currentLocation?.whatsappNumber ?? manager.phone,
        ),
      );
      if (!mounted) {
        return;
      }
      _showMessage('Field visit saved successfully.');
      Navigator.pop(context);
    } catch (_) {
      _showMessage('Unable to save field visit right now.', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: isError ? AppColors.error : AppColors.success,
        content: Text(
          message,
          style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final email = FirebaseAuth.instance.currentUser?.email ?? '';
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          'Add Field Visit',
          style: AppTextStyles.title.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      body: FutureBuilder<ManagerModel?>(
        future: _managerRepository.fetchManagerByEmail(email),
        builder: (context, managerSnapshot) {
          if (managerSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final manager = managerSnapshot.data;
          if (manager == null) {
            return Center(
              child: Text(
                'Manager profile is not available.',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.neutral500,
                ),
              ),
            );
          }
          return StreamBuilder<List<ManagerLiveLocationModel>>(
            stream: LiveTrackingRepository.instance.watchManagerLocations(),
            builder: (context, locationSnapshot) {
              final currentLocation =
                  (locationSnapshot.data ?? const <ManagerLiveLocationModel>[])
                      .where((item) => item.managerId == manager.id)
                      .firstOrNull;
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Site Name'),
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: _siteNameController,
                        hintText: 'Enter site name',
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Site name is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),
                      _buildLabel('Description'),
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: _descriptionController,
                        hintText: 'Describe this field visit',
                        maxLines: 4,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Description is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),
                      _buildLabel('Date & Time'),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: _selectDateTime,
                        borderRadius: BorderRadius.circular(18),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: AppColors.neutral200),
                          ),
                          child: Text(
                            formatDateTimeLabel(_selectedDateTime),
                            style: AppTextStyles.bodyLarge,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      _buildLabel('Location'),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: _openLocationPicker,
                        borderRadius: BorderRadius.circular(18),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: AppColors.neutral200),
                          ),
                          child: Text(
                            _address.isEmpty
                                ? 'Pick location on map'
                                : _address,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: _address.isEmpty
                                  ? AppColors.neutral500
                                  : AppColors.neutral800,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      _buildLabel('Images (max 5)'),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: _pickImages,
                        icon: const Icon(Icons.photo_library_outlined),
                        label: const Text('Select Images'),
                      ),
                      if (_pickedImages.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _pickedImages
                              .map(
                                (file) => Chip(
                                  label: Text(file.name),
                                  onDeleted: () => setState(
                                    () => _pickedImages.remove(file),
                                  ),
                                ),
                              )
                              .toList(growable: false),
                        ),
                      ],
                      const SizedBox(height: 18),
                      if (currentLocation != null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.primary50,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Text(
                            'Current live location: ${currentLocation.checkInLocation.address}',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.primary700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSaving
                              ? null
                              : () => _save(manager, currentLocation),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 54),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: Text(
                            _isSaving ? 'Saving...' : 'Save Field Visit',
                          ),
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

  Widget _buildLabel(String label) {
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
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.neutral200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.neutral200),
        ),
      ),
    );
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
