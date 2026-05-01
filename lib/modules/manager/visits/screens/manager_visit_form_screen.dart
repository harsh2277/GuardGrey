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
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _notesController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final FirebaseStorageService _storage = FirebaseStorageService.instance;
  final ManagerVisitRepository _repository = ManagerVisitRepository.instance;
  final Map<String, bool> _checklist = <String, bool>{
    'Uniform checked': true,
    'Logbook reviewed': true,
    'Supervisor briefing done': false,
  };
  late DateTime _scheduledAt;
  late String _selectedSiteId;
  final List<XFile> _newPhotos = <XFile>[];
  late final List<String> _existingPhotos;
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
    _notesController.text = existing?.notes ?? '';
    _existingPhotos = [...(existing?.imageUrls ?? const <String>[])];
    if (existing != null) {
      for (final item in existing.checklist) {
        _checklist[item] = true;
      }
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
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
    final files = await _picker.pickMultiImage();
    if (files.isEmpty) {
      return;
    }
    setState(() {
      _newPhotos.addAll(files);
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          content: Text(
            'Site is required.',
            style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
          ),
        ),
      );
      return;
    }
    if (_existingPhotos.isEmpty && _newPhotos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          content: Text(
            'At least one photo is required.',
            style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
          ),
        ),
      );
      return;
    }

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
        scheduledAt: _scheduledAt,
        status: _scheduledAt.isBefore(DateTime.now()) ? 'Completed' : 'Pending',
        notes: _notesController.text.trim(),
        imageUrls: <String>[..._existingPhotos, ...uploaded],
        checklist: _checklist.entries
            .where((entry) => entry.value)
            .map((entry) => entry.key)
            .toList(growable: false),
        createdAt: widget.existing?.createdAt,
        updatedAt: DateTime.now(),
      );
      await _repository.saveVisit(visit);
      if (!mounted) {
        return;
      }
      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          content: Text(
            'Unable to save visit right now.',
            style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
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
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
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
            const ManagerFormLabel('Visit Date & Time'),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickDateTime,
              borderRadius: BorderRadius.circular(14),
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
            const ManagerFormLabel('Notes'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _notesController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Add visit notes or escalation details',
              ),
            ),
            const SizedBox(height: 12),
            const ManagerFormLabel('Checklist'),
            const SizedBox(height: 8),
            ManagerSurfaceCard(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                children: _checklist.entries
                    .map(
                      (entry) => CheckboxListTile(
                        value: entry.value,
                        contentPadding: EdgeInsets.zero,
                        activeColor: AppColors.primary600,
                        title: Text(entry.key, style: AppTextStyles.bodyMedium),
                        onChanged: (value) {
                          setState(() {
                            _checklist[entry.key] = value ?? false;
                          });
                        },
                      ),
                    )
                    .toList(growable: false),
              ),
            ),
            const SizedBox(height: 12),
            const ManagerFormLabel('Visit Photos'),
            const SizedBox(height: 8),
            Row(
              children: [
                const Spacer(),
                TextButton.icon(
                  onPressed: _pickPhotos,
                  icon: const Icon(Icons.upload_outlined),
                  label: const Text('Add Photo'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_existingPhotos.isEmpty && _newPhotos.isEmpty)
              Text(
                'At least one photo is required.',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.neutral500,
                ),
              )
            else
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final photo in _existingPhotos)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        photo,
                        width: 88,
                        height: 88,
                        fit: BoxFit.cover,
                      ),
                    ),
                  for (final photo in _newPhotos)
                    FutureBuilder(
                      future: photo.readAsBytes(),
                      builder: (context, snapshot) {
                        final bytes = snapshot.data;
                        if (bytes == null) {
                          return Container(
                            width: 88,
                            height: 88,
                            decoration: BoxDecoration(
                              color: AppColors.neutral100,
                              borderRadius: BorderRadius.circular(16),
                            ),
                          );
                        }
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.memory(
                            bytes,
                            width: 88,
                            height: 88,
                            fit: BoxFit.cover,
                          ),
                        );
                      },
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
