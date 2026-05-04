import 'dart:typed_data';

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
import 'package:guardgrey/features/notifications/services/notification_module.dart';
import 'package:guardgrey/features/location/models/location_picker_result.dart';
import 'package:guardgrey/features/location/screens/location_picker_screen.dart';
import 'package:guardgrey/modules/manager/common/widgets/manager_ui.dart';

class FieldVisitFormScreen extends StatefulWidget {
  const FieldVisitFormScreen({super.key, this.initialSiteName});

  final String? initialSiteName;

  @override
  State<FieldVisitFormScreen> createState() => _FieldVisitFormScreenState();
}

class _FieldVisitFormScreenState extends State<FieldVisitFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _siteNameController = TextEditingController();
  final _notesController = TextEditingController();
  final _picker = ImagePicker();
  final _storage = FirebaseStorageService.instance;
  final _repository = FieldVisitRepository.instance;
  final _managerRepository = ManagerRepository.instance;

  bool _isSaving = false;
  bool _didAutofillLocation = false;
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
    _notesController.dispose();
    super.dispose();
  }

  void _autofillLocation(ManagerLiveLocationModel? currentLocation) {
    if (_didAutofillLocation || currentLocation == null) {
      return;
    }
    _didAutofillLocation = true;
    _latitude = currentLocation.checkInLocation.lat;
    _longitude = currentLocation.checkInLocation.lng;
    _address = currentLocation.checkInLocation.address;
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
      final siteName = _siteNameController.text.trim();
      final imageUrls = await _storage.uploadImages(
        folder: 'field_visits/${manager.id}',
        files: _pickedImages,
      );
      final visit = FieldVisitModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        managerId: manager.id,
        managerName: manager.name,
        clientEmail: '',
        phone: manager.phone,
        profileImage: manager.profileImage,
        visitType: 'Field Visit',
        siteName: siteName,
        notes: _notesController.text.trim(),
        status: 'Submitted',
        location: AppLocation(
          lat: _latitude!,
          lng: _longitude!,
          address: _address,
        ),
        imageUrls: imageUrls,
        dateTime: _selectedDateTime,
      );
      await _repository.saveFieldVisit(visit);
      await NotificationModule.pushNotificationService
          .notifyAdminsVisitSubmitted(
            managerName: manager.name,
            siteName: visit.siteName,
          );
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
    } catch (error) {
      _showMessage(
        'Unable to save field visit right now. $error',
        isError: true,
      );
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
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        scrolledUnderElevation: 0,
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
            return const ManagerEmptyState(
              title: 'Manager profile unavailable',
              message:
                  'Field visits can be created after manager data is synced.',
            );
          }
          return StreamBuilder<List<ManagerLiveLocationModel>>(
            stream: LiveTrackingRepository.instance.watchManagerLocations(),
            builder: (context, locationSnapshot) {
              final currentLocation =
                  (locationSnapshot.data ?? const <ManagerLiveLocationModel>[])
                      .where((item) => item.managerId == manager.id)
                      .firstOrNull;
              _autofillLocation(currentLocation);

              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const ManagerFormLabel('Site / Visit Name'),
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: _siteNameController,
                        hintText: 'Enter site or visit location name',
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Visit location is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      const ManagerFormLabel('Visit Date & Time'),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: _selectDateTime,
                        borderRadius: BorderRadius.circular(20),
                        child: InputDecorator(
                          decoration: const InputDecoration(),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  formatDateTimeLabel(_selectedDateTime),
                                  style: AppTextStyles.bodyMedium,
                                ),
                              ),
                              const Icon(Icons.schedule_outlined, size: 18),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const ManagerFormLabel('Location'),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: _openLocationPicker,
                        borderRadius: BorderRadius.circular(20),
                        child: InputDecorator(
                          decoration: const InputDecoration(),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  _address.isEmpty
                                      ? 'Location will auto-fill from your latest live location'
                                      : _address,
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: _address.isEmpty
                                        ? AppColors.neutral500
                                        : AppColors.neutral800,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Icon(Icons.edit_location_alt_outlined),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const ManagerFormLabel('Notes'),
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: _notesController,
                        hintText: 'Add inspection notes or follow-up details',
                        maxLines: 4,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Notes are required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Expanded(
                            child: ManagerFormLabel('Photo Upload'),
                          ),
                          TextButton.icon(
                            onPressed: _pickImages,
                            icon: const Icon(Icons.photo_library_outlined),
                            label: const Text('Add photos'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (_pickedImages.isEmpty)
                        Text(
                          'Photos are optional but recommended for proof.',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.neutral500,
                          ),
                        )
                      else
                        GridView.count(
                          crossAxisCount: 3,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          children: _pickedImages
                              .asMap()
                              .entries
                              .map(
                                (entry) => _PickedImageTile(
                                  bytesFuture: entry.value.readAsBytes(),
                                  onRemove: () {
                                    setState(() {
                                      _pickedImages.removeAt(entry.key);
                                    });
                                  },
                                ),
                              )
                              .toList(growable: false),
                        ),
                      const SizedBox(height: 18),
                      if (_address.isNotEmpty)
                        ManagerSurfaceCard(
                          padding: const EdgeInsets.all(14),
                          child: Text(
                            'Auto-filled location: $_address',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.primary700,
                              fontWeight: FontWeight.w700,
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
      decoration: InputDecoration(hintText: hintText),
    );
  }
}

class _PickedImageTile extends StatelessWidget {
  const _PickedImageTile({required this.bytesFuture, required this.onRemove});

  final Future<Uint8List> bytesFuture;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: FutureBuilder<Uint8List>(
              future: bytesFuture,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Container(color: AppColors.neutral100);
                }
                return Image.memory(snapshot.data!, fit: BoxFit.cover);
              },
            ),
          ),
        ),
        Positioned(
          top: 6,
          right: 6,
          child: InkWell(
            onTap: onRemove,
            child: Container(
              width: 26,
              height: 26,
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 16, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}
