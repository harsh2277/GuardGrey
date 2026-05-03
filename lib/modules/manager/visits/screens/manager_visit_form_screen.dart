import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:guardgrey/core/theme/app_colors.dart';
import 'package:guardgrey/core/theme/app_text_styles.dart';
import 'package:guardgrey/core/utils/date_time_display.dart';
import 'package:guardgrey/data/models/manager_model.dart';
import 'package:guardgrey/data/models/site_model.dart';
import 'package:guardgrey/data/services/firebase_storage_service.dart';
import 'package:guardgrey/modules/manager/common/widgets/manager_ui.dart';
import 'package:guardgrey/modules/manager/visits/models/manager_visit_entry.dart';
import 'package:guardgrey/modules/manager/visits/repositories/manager_visit_repository.dart';

class ManagerVisitFormScreen extends StatefulWidget {
  const ManagerVisitFormScreen({
    super.key,
    required this.manager,
    required this.sites,
    this.existing,
    this.initialSiteId,
  });

  final ManagerModel manager;
  final List<SiteModel> sites;
  final ManagerVisitEntry? existing;
  final String? initialSiteId;

  @override
  State<ManagerVisitFormScreen> createState() => _ManagerVisitFormScreenState();
}

class _ManagerVisitFormScreenState extends State<ManagerVisitFormScreen> {
  static const List<String> _visitTypes = <String>[
    'Site Visit',
    'Night Visit',
    'Training',
  ];

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _notesController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final FirebaseStorageService _storage = FirebaseStorageService.instance;
  final ManagerVisitRepository _repository = ManagerVisitRepository.instance;

  late DateTime _scheduledAt;
  late String _selectedSiteId;
  late String _selectedVisitType;
  final List<XFile> _newPhotos = <XFile>[];
  late final List<String> _existingPhotos;
  late final List<_ReadOnlyQuestion> _questions;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _scheduledAt = existing?.scheduledAt ?? DateTime.now();
    _selectedSiteId =
        existing?.siteId ??
        widget.initialSiteId ??
        (widget.sites.isEmpty ? '' : widget.sites.first.id);
    _selectedVisitType = existing?.visitType ?? _visitTypes.first;
    _notesController.text = existing?.notes ?? '';
    _existingPhotos = [...(existing?.imageUrls ?? const <String>[])];
    _questions = (existing?.questions ?? _defaultQuestions)
        .map(_ReadOnlyQuestion.fromQuestion)
        .toList(growable: false);
  }

  List<ManagerVisitQuestion> get _defaultQuestions =>
      const <ManagerVisitQuestion>[
        ManagerVisitQuestion(
          question: 'Guard present at assigned post?',
          answer: true,
        ),
        ManagerVisitQuestion(
          question: 'Appearance and uniform satisfactory?',
          answer: true,
        ),
        ManagerVisitQuestion(
          question: 'Logbook and instructions updated?',
          answer: true,
        ),
      ];

  @override
  void dispose() {
    _notesController.dispose();
    for (final question in _questions) {
      question.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _scheduledAt,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) {
      return;
    }
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_scheduledAt),
    );
    if (time == null) {
      return;
    }
    setState(() {
      _scheduledAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _pickPhotos() async {
    final remainingSlots =
        FirebaseStorageService.maxImages -
        (_existingPhotos.length + _newPhotos.length);
    if (remainingSlots <= 0) {
      _showError('You can upload a maximum of 5 photos.');
      return;
    }
    final files = await _picker.pickMultiImage();
    if (files.isEmpty) {
      return;
    }
    setState(() {
      _newPhotos.addAll(files.take(remainingSlots));
    });
  }

  Future<void> _save() async {
    if (_isSaving || !(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final selectedSite = widget.sites
        .where((site) => site.id == _selectedSiteId)
        .firstOrNull;
    if (selectedSite == null) {
      _showError('Site is required.');
      return;
    }
    final totalPhotos = _existingPhotos.length + _newPhotos.length;
    if (totalPhotos < 3) {
      _showError('Please upload at least 3 photos before submitting.');
      return;
    }

    final normalizedQuestions = _questions
        .map(
          (item) => ManagerVisitQuestion(
            question: item.question,
            answer: item.answer,
            note: item.noteController.text.trim(),
          ),
        )
        .toList(growable: false);

    setState(() {
      _isSaving = true;
    });

    try {
      final uploaded = await _storage.uploadImages(
        folder: 'site_visits/${widget.manager.id}',
        files: _newPhotos,
      );
      final visit = ManagerVisitEntry(
        id:
            widget.existing?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        siteId: selectedSite.id,
        siteName: selectedSite.name,
        managerId: widget.manager.id,
        managerName: widget.manager.name,
        visitType: _selectedVisitType,
        scheduledAt: _scheduledAt,
        status: _scheduledAt.isBefore(DateTime.now()) ? 'Completed' : 'Pending',
        notes: _notesController.text.trim(),
        imageUrls: <String>[..._existingPhotos, ...uploaded],
        questions: normalizedQuestions,
        createdAt: widget.existing?.createdAt,
        updatedAt: DateTime.now(),
      );
      await _repository.saveVisit(visit);
      if (!mounted) {
        return;
      }
      Navigator.pop(context, true);
    } catch (_) {
      _showError('Unable to save visit right now.');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.error,
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
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          widget.existing == null ? 'Add Visit' : 'Edit Visit',
          style: AppTextStyles.title.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
          children: [
            const ManagerFormLabel('Select Site'),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _selectedSiteId.isEmpty ? null : _selectedSiteId,
              decoration: const InputDecoration(
                hintText: 'Choose assigned site',
              ),
              items: widget.sites
                  .map(
                    (site) => DropdownMenuItem<String>(
                      value: site.id,
                      child: Text(site.name),
                    ),
                  )
                  .toList(growable: false),
              onChanged: (value) {
                if (value == null) {
                  return;
                }
                setState(() {
                  _selectedSiteId = value;
                });
              },
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? 'Site is required'
                  : null,
            ),
            const SizedBox(height: 12),
            const ManagerFormLabel('Visit Type'),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _selectedVisitType,
              decoration: const InputDecoration(hintText: 'Select visit type'),
              items: _visitTypes
                  .map(
                    (type) => DropdownMenuItem<String>(
                      value: type,
                      child: Text(type),
                    ),
                  )
                  .toList(growable: false),
              onChanged: (value) {
                if (value == null) {
                  return;
                }
                setState(() {
                  _selectedVisitType = value;
                });
              },
            ),
            const SizedBox(height: 12),
            const ManagerFormLabel('Visit Date & Time'),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickDateTime,
              borderRadius: BorderRadius.circular(18),
              child: InputDecorator(
                decoration: const InputDecoration(),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        formatDateTimeLabel(_scheduledAt),
                        style: AppTextStyles.bodyMedium,
                      ),
                    ),
                    const Icon(Icons.schedule_outlined, size: 18),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            const ManagerFormLabel('Visit Notes'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _notesController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText:
                    'Add visit notes, follow-up items, or escalation details',
              ),
            ),
            const SizedBox(height: 18),
            const ManagerFormLabel('Question Review'),
            const SizedBox(height: 10),
            ..._questions.map(
              (question) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ManagerSurfaceCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        question.question,
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _AnswerButton(
                              label: 'Yes',
                              selected: question.answer,
                              onTap: () {
                                setState(() {
                                  question.answer = true;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _AnswerButton(
                              label: 'No',
                              selected: !question.answer,
                              onTap: () {
                                setState(() {
                                  question.answer = false;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: question.noteController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          hintText: 'Optional note',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Expanded(child: ManagerFormLabel('Visit Photos')),
                TextButton.icon(
                  onPressed: _pickPhotos,
                  icon: const Icon(Icons.upload_outlined),
                  label: const Text('Add photos'),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Minimum 3 photos required. Maximum 5 photos allowed.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.neutral500,
              ),
            ),
            const SizedBox(height: 12),
            if (_existingPhotos.isEmpty && _newPhotos.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.neutral200),
                ),
                child: Text(
                  'No photos selected yet.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.neutral500,
                  ),
                ),
              )
            else
              GridView.count(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1,
                children: [
                  ..._existingPhotos.asMap().entries.map(
                    (entry) => _PhotoTile(
                      imageUrl: entry.value,
                      onRemove: () {
                        setState(() {
                          _existingPhotos.removeAt(entry.key);
                        });
                      },
                    ),
                  ),
                  ..._newPhotos.asMap().entries.map(
                    (entry) => _PhotoTile(
                      memoryLoader: entry.value.readAsBytes,
                      onRemove: () {
                        setState(() {
                          _newPhotos.removeAt(entry.key);
                        });
                      },
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isSaving ? null : _save,
                child: Text(_isSaving ? 'Saving...' : 'Save Visit'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReadOnlyQuestion {
  _ReadOnlyQuestion({
    required this.question,
    required this.answer,
    String note = '',
  }) : noteController = TextEditingController(text: note);

  factory _ReadOnlyQuestion.fromQuestion(ManagerVisitQuestion question) {
    return _ReadOnlyQuestion(
      question: question.question,
      answer: question.answer ?? true,
      note: question.note,
    );
  }

  final String question;
  bool answer;
  final TextEditingController noteController;

  void dispose() {
    noteController.dispose();
  }
}

class _AnswerButton extends StatelessWidget {
  const _AnswerButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary600 : AppColors.neutral50,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? AppColors.primary600 : AppColors.neutral200,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              color: selected ? Colors.white : AppColors.neutral700,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({this.imageUrl, this.memoryLoader, required this.onRemove});

  final String? imageUrl;
  final Future<Uint8List> Function()? memoryLoader;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.neutral100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: imageUrl != null
                  ? Image.network(imageUrl!, fit: BoxFit.cover)
                  : FutureBuilder<Uint8List>(
                      future: memoryLoader?.call(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const SizedBox.shrink();
                        }
                        return Image.memory(snapshot.data!, fit: BoxFit.cover);
                      },
                    ),
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
              child: const Icon(Icons.close, color: Colors.white, size: 16),
            ),
          ),
        ),
      ],
    );
  }
}
