import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:guardgrey/core/theme/app_colors.dart';
import 'package:guardgrey/core/theme/app_text_styles.dart';
import 'package:guardgrey/core/utils/date_time_display.dart';
import 'package:guardgrey/data/models/app_location.dart';
import 'package:guardgrey/data/models/manager_live_location_model.dart';
import 'package:guardgrey/data/models/manager_model.dart';
import 'package:guardgrey/data/models/report_model.dart';
import 'package:guardgrey/data/models/report_question.dart';
import 'package:guardgrey/data/repositories/guard_grey_repository.dart';
import 'package:guardgrey/data/repositories/live_tracking_repository.dart';
import 'package:guardgrey/data/repositories/report_repository.dart';
import 'package:guardgrey/data/services/firebase_storage_service.dart';

class ReportFormScreen extends StatefulWidget {
  const ReportFormScreen({super.key, this.report});

  final ReportModel? report;

  bool get isEditing => report != null;

  @override
  State<ReportFormScreen> createState() => _ReportFormScreenState();
}

class _ReportFormScreenState extends State<ReportFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repository = GuardGreyRepository.instance;
  final _reportRepository = ReportRepository.instance;
  final _storageService = FirebaseStorageService.instance;
  final _picker = ImagePicker();

  late final TextEditingController _reportNameController;
  late DateTime _selectedDateTime;
  String? _selectedManagerId;
  String? _selectedReportType;
  bool _isSaving = false;
  final List<_QuestionDraft> _questions = <_QuestionDraft>[];
  final List<XFile> _pickedImages = <XFile>[];
  late final List<String> _existingImageUrls;

  @override
  void initState() {
    super.initState();
    final report = widget.report;
    _reportNameController = TextEditingController(
      text: report?.reportName ?? '',
    );
    _selectedDateTime = report?.dateTime ?? DateTime.now();
    _selectedManagerId = report?.managerId;
    _selectedReportType = report?.reportType;
    _existingImageUrls = List<String>.from(
      report?.imageUrls ?? const <String>[],
    );
    final questions = report?.questions ?? const <ReportQuestion>[];
    if (questions.isEmpty) {
      _questions.add(_QuestionDraft());
    } else {
      for (final question in questions) {
        _questions.add(
          _QuestionDraft(
            question: question.question,
            description: question.description,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _reportNameController.dispose();
    for (final item in _questions) {
      item.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImages() async {
    final currentCount = _existingImageUrls.length + _pickedImages.length;
    if (currentCount >= FirebaseStorageService.maxImages) {
      _showMessage('You can upload a maximum of 5 images.', isError: true);
      return;
    }
    final files = await _picker.pickMultiImage();
    if (files.isEmpty) {
      return;
    }
    final allowedCount = FirebaseStorageService.maxImages - currentCount;
    setState(() {
      _pickedImages.addAll(files.take(allowedCount));
    });
    if (files.length > allowedCount) {
      _showMessage(
        'Only the first $allowedCount images were added.',
        isError: true,
      );
    }
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
    List<ManagerModel> managers,
    List<ManagerLiveLocationModel> locations,
  ) async {
    if (_isSaving) {
      return;
    }
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) {
      return;
    }
    if (_selectedManagerId == null || _selectedReportType == null) {
      _showMessage('Manager and report type are required.', isError: true);
      return;
    }

    final manager = managers
        .where((item) => item.id == _selectedManagerId)
        .firstOrNull;
    if (manager == null) {
      _showMessage('Selected manager could not be found.', isError: true);
      return;
    }

    final location = locations
        .where((item) => item.managerId == manager.id)
        .firstOrNull;
    if (location == null) {
      _showMessage(
        'Live location is required for the selected manager.',
        isError: true,
      );
      return;
    }

    final questions = _questions
        .map(
          (draft) => ReportQuestion(
            question: draft.questionController.text.trim(),
            description: draft.descriptionController.text.trim(),
          ),
        )
        .where(
          (item) => item.question.isNotEmpty && item.description.isNotEmpty,
        )
        .toList(growable: false);

    if (questions.isEmpty) {
      _showMessage('Add at least one complete question.', isError: true);
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final uploadedUrls = await _storageService.uploadImages(
        folder: 'reports/${manager.id}',
        files: _pickedImages,
      );
      final report = ReportModel(
        id:
            widget.report?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        reportName: _reportNameController.text.trim(),
        reportType: _selectedReportType!,
        managerId: manager.id,
        managerName: manager.name,
        dateTime: _selectedDateTime,
        location: AppLocation(
          lat: location.lat,
          lng: location.lng,
          address: location.checkInLocation.address,
        ),
        questions: questions,
        imageUrls: [..._existingImageUrls, ...uploadedUrls],
      );
      await _reportRepository.saveReport(report);
      if (!mounted) {
        return;
      }
      _showMessage(
        widget.isEditing
            ? 'Report updated successfully.'
            : 'Report created successfully.',
      );
      Navigator.pop(context);
    } catch (_) {
      _showMessage('Unable to save the report right now.', isError: true);
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
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          widget.isEditing ? 'Edit Report' : 'Add Report',
          style: AppTextStyles.title.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      body: FutureBuilder<List<ManagerModel>>(
        future: _repository.fetchManagers(),
        builder: (context, managersSnapshot) {
          if (managersSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final managers = managersSnapshot.data ?? const <ManagerModel>[];
          return StreamBuilder<List<ManagerLiveLocationModel>>(
            stream: LiveTrackingRepository.instance.watchManagerLocations(),
            builder: (context, locationsSnapshot) {
              final locations =
                  locationsSnapshot.data ?? const <ManagerLiveLocationModel>[];
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Report Name'),
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: _reportNameController,
                        hintText: 'Enter report name',
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Report name is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),
                      _buildLabel('Manager'),
                      const SizedBox(height: 8),
                      _buildDropdown<String>(
                        value: _selectedManagerId,
                        hint: 'Select manager',
                        items: managers
                            .map(
                              (manager) => DropdownMenuItem<String>(
                                value: manager.id,
                                child: Text(manager.name),
                              ),
                            )
                            .toList(growable: false),
                        onChanged: (value) {
                          setState(() {
                            _selectedManagerId = value;
                          });
                        },
                      ),
                      const SizedBox(height: 18),
                      _buildLabel('Report Type'),
                      const SizedBox(height: 8),
                      _buildDropdown<String>(
                        value: _selectedReportType,
                        hint: 'Select report type',
                        items: const [
                          DropdownMenuItem(
                            value: 'training',
                            child: Text('Training'),
                          ),
                          DropdownMenuItem(
                            value: 'site_visit',
                            child: Text('Site Visit'),
                          ),
                          DropdownMenuItem(
                            value: 'night_visit',
                            child: Text('Night Visit'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedReportType = value;
                          });
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
                      _buildLabel('Questions'),
                      const SizedBox(height: 8),
                      ..._questions.asMap().entries.map((entry) {
                        final index = entry.key;
                        final draft = entry.value;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: AppColors.neutral200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Question ${index + 1}',
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const Spacer(),
                                    if (_questions.length > 1)
                                      IconButton(
                                        onPressed: () {
                                          setState(() {
                                            final removed = _questions.removeAt(
                                              index,
                                            );
                                            removed.dispose();
                                          });
                                        },
                                        icon: const Icon(
                                          Icons.delete_outline_rounded,
                                          color: AppColors.error,
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                _buildMiniLabel('Question'),
                                const SizedBox(height: 8),
                                _buildTextField(
                                  controller: draft.questionController,
                                  hintText: 'Enter question',
                                ),
                                const SizedBox(height: 10),
                                _buildMiniLabel('Description'),
                                const SizedBox(height: 8),
                                _buildTextField(
                                  controller: draft.descriptionController,
                                  hintText: 'Enter description',
                                  maxLines: 3,
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () =>
                              setState(() => _questions.add(_QuestionDraft())),
                          icon: const Icon(Icons.add_circle_outline_rounded),
                          label: const Text('Add Question'),
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
                      const SizedBox(height: 10),
                      if (_existingImageUrls.isNotEmpty ||
                          _pickedImages.isNotEmpty)
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ..._existingImageUrls.map(
                              (url) => _buildImageChip(
                                label: 'Uploaded',
                                onRemove: () => setState(
                                  () => _existingImageUrls.remove(url),
                                ),
                              ),
                            ),
                            ..._pickedImages.map(
                              (file) => _buildImageChip(
                                label: file.name,
                                onRemove: () =>
                                    setState(() => _pickedImages.remove(file)),
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 24),
                      if (_selectedManagerId != null)
                        _LocationPreviewCard(
                          location: locations
                              .where(
                                (item) => item.managerId == _selectedManagerId,
                              )
                              .firstOrNull,
                        ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSaving
                              ? null
                              : () => _save(managers, locations),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 54),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: Text(_isSaving ? 'Saving...' : 'Save Report'),
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

  Widget _buildMiniLabel(String label) {
    return Text(
      label,
      style: AppTextStyles.bodySmall.copyWith(
        color: AppColors.neutral500,
        fontWeight: FontWeight.w700,
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

  Widget _buildDropdown<T>({
    required T? value,
    required String hint,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      items: items,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
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

  Widget _buildImageChip({
    required String label,
    required VoidCallback onRemove,
  }) {
    return Chip(
      label: Text(label, overflow: TextOverflow.ellipsis),
      deleteIcon: const Icon(Icons.close_rounded, size: 18),
      onDeleted: onRemove,
    );
  }
}

class _LocationPreviewCard extends StatelessWidget {
  const _LocationPreviewCard({required this.location});

  final ManagerLiveLocationModel? location;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Auto-fetched location',
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            location?.checkInLocation.address ??
                'No live location available for this manager.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.neutral600,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionDraft {
  _QuestionDraft({String question = '', String description = ''})
    : questionController = TextEditingController(text: question),
      descriptionController = TextEditingController(text: description);

  final TextEditingController questionController;
  final TextEditingController descriptionController;

  void dispose() {
    questionController.dispose();
    descriptionController.dispose();
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
