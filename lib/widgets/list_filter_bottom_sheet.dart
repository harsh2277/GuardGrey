import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../modules/admin/services/firestore_admin_repository.dart';

class ListFilterData {
  const ListFilterData({
    required this.searchQuery,
    this.status,
    this.date,
    this.extraSelections = const <String, String?>{},
  });

  final String searchQuery;
  final String? status;
  final DateTime? date;
  final Map<String, String?> extraSelections;
}

class ListFilterDropdownField {
  const ListFilterDropdownField({
    required this.key,
    required this.label,
    required this.options,
    this.initialValue,
  });

  final String key;
  final String label;
  final List<String> options;
  final String? initialValue;
}

class ListFilterBottomSheet extends StatefulWidget {
  const ListFilterBottomSheet({
    super.key,
    required this.title,
    required this.searchHint,
    required this.initialSearchQuery,
    this.statusLabel = 'Status',
    this.statusOptions = const <String>[],
    this.initialStatus,
    this.initialDate,
    this.showDateFilter = false,
    this.extraDropdowns = const <ListFilterDropdownField>[],
  });

  final String title;
  final String searchHint;
  final String initialSearchQuery;
  final String statusLabel;
  final List<String> statusOptions;
  final String? initialStatus;
  final DateTime? initialDate;
  final bool showDateFilter;
  final List<ListFilterDropdownField> extraDropdowns;

  static Future<ListFilterData?> show(
    BuildContext context, {
    required String title,
    required String searchHint,
    required String initialSearchQuery,
    String statusLabel = 'Status',
    List<String> statusOptions = const <String>[],
    String? initialStatus,
    DateTime? initialDate,
    bool showDateFilter = false,
    List<ListFilterDropdownField> extraDropdowns = const [],
  }) {
    return showModalBottomSheet<ListFilterData>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: ListFilterBottomSheet(
            title: title,
            searchHint: searchHint,
            initialSearchQuery: initialSearchQuery,
            statusLabel: statusLabel,
            statusOptions: statusOptions,
            initialStatus: initialStatus,
            initialDate: initialDate,
            showDateFilter: showDateFilter,
            extraDropdowns: extraDropdowns,
          ),
        );
      },
    );
  }

  @override
  State<ListFilterBottomSheet> createState() => _ListFilterBottomSheetState();
}

class _ListFilterBottomSheetState extends State<ListFilterBottomSheet> {
  late final TextEditingController _searchController;
  late String? _selectedStatus;
  late DateTime? _selectedDate;
  late final Map<String, String?> _extraSelections;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialSearchQuery);
    _selectedStatus = widget.initialStatus;
    _selectedDate = widget.initialDate;
    _extraSelections = {
      for (final field in widget.extraDropdowns) field.key: field.initialValue,
    };
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedStatus = null;
      _selectedDate = null;
      for (final field in widget.extraDropdowns) {
        _extraSelections[field.key] = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      top: false,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.neutral200,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              widget.title,
              style: AppTextStyles.title.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              style: AppTextStyles.bodyMedium,
              decoration: InputDecoration(
                labelText: 'Search refinement',
                hintText: widget.searchHint,
                filled: true,
                fillColor: AppColors.neutral50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(color: AppColors.neutral200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(color: AppColors.neutral200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide(color: theme.colorScheme.primary),
                ),
              ),
            ),
            if (widget.statusOptions.isNotEmpty) ...[
              const SizedBox(height: 18),
              DropdownButtonFormField<String>(
                initialValue: _selectedStatus,
                hint: const Text('All'),
                decoration: InputDecoration(
                  labelText: widget.statusLabel,
                  filled: true,
                  fillColor: AppColors.neutral50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: const BorderSide(color: AppColors.neutral200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: const BorderSide(color: AppColors.neutral200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide(color: theme.colorScheme.primary),
                  ),
                ),
                items: widget.statusOptions
                    .map(
                      (option) => DropdownMenuItem<String>(
                        value: option,
                        child: Text(option),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) {
                  setState(() {
                    _selectedStatus = value;
                  });
                },
              ),
            ],
            for (final field in widget.extraDropdowns) ...[
              const SizedBox(height: 18),
              DropdownButtonFormField<String>(
                initialValue: _extraSelections[field.key],
                hint: const Text('All'),
                decoration: InputDecoration(
                  labelText: field.label,
                  filled: true,
                  fillColor: AppColors.neutral50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: const BorderSide(color: AppColors.neutral200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: const BorderSide(color: AppColors.neutral200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide(color: theme.colorScheme.primary),
                  ),
                ),
                items: field.options
                    .map(
                      (option) => DropdownMenuItem<String>(
                        value: option,
                        child: Text(option),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) {
                  setState(() {
                    _extraSelections[field.key] = value;
                  });
                },
              ),
            ],
            if (widget.showDateFilter) ...[
              const SizedBox(height: 18),
              Text(
                'Date',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.neutral500,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(18),
                child: Ink(
                  width: double.infinity,
                  child: InputDecorator(
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.neutral50,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: const BorderSide(
                          color: AppColors.neutral200,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: const BorderSide(
                          color: AppColors.neutral200,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 18,
                          color: AppColors.neutral600,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _selectedDate == null
                                ? 'All dates'
                                : FirestoreAdminRepository.formatDate(
                                    _selectedDate,
                                  ),
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: _selectedDate == null
                                  ? AppColors.neutral500
                                  : AppColors.neutral800,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (_selectedDate != null)
                          IconButton(
                            onPressed: () {
                              setState(() {
                                _selectedDate = null;
                              });
                            },
                            icon: const Icon(
                              Icons.close_rounded,
                              size: 18,
                              color: AppColors.neutral500,
                            ),
                            splashRadius: 18,
                          )
                        else
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: AppColors.neutral500,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _clearFilters,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      side: const BorderSide(color: AppColors.neutral200),
                    ),
                    child: const Text('Reset'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(
                        context,
                        ListFilterData(
                          searchQuery: _searchController.text.trim(),
                          status: _selectedStatus,
                          date: _selectedDate,
                          extraSelections: Map<String, String?>.from(
                            _extraSelections,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: const Text('Apply'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
