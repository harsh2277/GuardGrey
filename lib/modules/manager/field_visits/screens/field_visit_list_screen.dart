import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:guardgrey/core/theme/app_colors.dart';
import 'package:guardgrey/core/theme/app_text_styles.dart';
import 'package:guardgrey/core/utils/date_time_display.dart';
import 'package:guardgrey/core/widgets/admin_search_bar.dart';
import 'package:guardgrey/core/widgets/primary_floating_add_button.dart';
import 'package:guardgrey/data/models/field_visit_model.dart';
import 'package:guardgrey/data/models/manager_model.dart';
import 'package:guardgrey/data/repositories/field_visit_repository.dart';
import 'package:guardgrey/data/repositories/guard_grey_repository.dart';
import 'package:guardgrey/data/repositories/manager_repository.dart';
import 'package:guardgrey/modules/manager/common/widgets/manager_ui.dart';

import 'field_visit_detail_screen.dart';
import 'field_visit_form_screen.dart';

class FieldVisitListScreen extends StatefulWidget {
  const FieldVisitListScreen({super.key, this.initialSiteName});

  final String? initialSiteName;

  @override
  State<FieldVisitListScreen> createState() => _FieldVisitListScreenState();
}

class _FieldVisitListScreenState extends State<FieldVisitListScreen> {
  late final TextEditingController _searchController;
  String _searchQuery = '';
  String? _selectedStatus;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openFilters() async {
    DateTime? tempDate = _selectedDate;
    String? tempStatus = _selectedStatus;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Filter Field Visits',
                    style: AppTextStyles.title.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () async {
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: tempDate ?? DateTime.now(),
                        firstDate: DateTime.now().subtract(
                          const Duration(days: 30),
                        ),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (pickedDate == null) {
                        return;
                      }
                      setModalState(() {
                        tempDate = pickedDate;
                      });
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Date',
                        suffixIcon: tempDate == null
                            ? const Icon(Icons.calendar_today_outlined)
                            : IconButton(
                                onPressed: () {
                                  setModalState(() {
                                    tempDate = null;
                                  });
                                },
                                icon: const Icon(Icons.close_rounded),
                              ),
                      ),
                      child: Text(
                        tempDate == null
                            ? 'All dates'
                            : GuardGreyRepository.formatDate(tempDate),
                        style: AppTextStyles.bodyMedium,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String?>(
                    initialValue: tempStatus,
                    decoration: const InputDecoration(labelText: 'Status'),
                    items: const [
                      DropdownMenuItem<String?>(
                        value: null,
                        child: Text('All status'),
                      ),
                      DropdownMenuItem<String?>(
                        value: 'Submitted',
                        child: Text('Submitted'),
                      ),
                      DropdownMenuItem<String?>(
                        value: 'Completed',
                        child: Text('Completed'),
                      ),
                    ],
                    onChanged: (value) {
                      setModalState(() {
                        tempStatus = value;
                      });
                    },
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _selectedDate = null;
                              _selectedStatus = null;
                            });
                            Navigator.pop(context);
                          },
                          child: const Text('Clear'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () {
                            setState(() {
                              _selectedDate = tempDate;
                              _selectedStatus = tempStatus;
                            });
                            Navigator.pop(context);
                          },
                          child: const Text('Apply'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  List<FieldVisitModel> _filterVisits(
    List<FieldVisitModel> visits, {
    required ManagerModel? manager,
  }) {
    final query = _searchQuery.trim().toLowerCase();
    return visits
        .where((visit) {
          final matchesManager =
              manager == null || visit.managerId == manager.id;
          final matchesSite =
              widget.initialSiteName == null ||
              visit.siteName == widget.initialSiteName;
          final matchesQuery =
              query.isEmpty ||
              visit.siteName.toLowerCase().contains(query) ||
              visit.managerName.toLowerCase().contains(query) ||
              visit.location.address.toLowerCase().contains(query) ||
              visit.notes.toLowerCase().contains(query);
          final matchesStatus =
              _selectedStatus == null || visit.status == _selectedStatus;
          final matchesDate =
              _selectedDate == null ||
              formatDateLabel(visit.dateTime) ==
                  GuardGreyRepository.formatDate(_selectedDate);
          return matchesManager &&
              matchesSite &&
              matchesQuery &&
              matchesStatus &&
              matchesDate;
        })
        .toList(growable: false);
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
          'Field Visits',
          style: AppTextStyles.title.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      body: StreamBuilder<ManagerModel?>(
        stream: ManagerRepository.instance.watchManagerByEmail(email),
        builder: (context, managerSnapshot) {
          final manager = managerSnapshot.data;
          if (managerSnapshot.connectionState == ConnectionState.waiting &&
              manager == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (manager == null) {
            return const ManagerEmptyState(
              title: 'No manager workspace data',
              message:
                  'Field visits will appear after the manager profile is available.',
            );
          }

          return StreamBuilder<List<FieldVisitModel>>(
            stream: FieldVisitRepository.instance.watchFieldVisits(),
            builder: (context, snapshot) {
              final allVisits = snapshot.data ?? const <FieldVisitModel>[];
              if (snapshot.connectionState == ConnectionState.waiting &&
                  allVisits.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              final visits = _filterVisits(allVisits, manager: manager);

              return Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: AdminSearchBar(
                            controller: _searchController,
                            height: 50,
                            hintText: 'Search field visits...',
                            onChanged: (value) {
                              setState(() {
                                _searchQuery = value;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 50,
                          height: 50,
                          child: FilledButton(
                            onPressed: _openFilters,
                            style: FilledButton.styleFrom(
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: const Icon(Icons.tune_rounded),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: visits.isEmpty
                          ? const ManagerEmptyState(
                              title: 'No field visits found',
                              message:
                                  'Completed field visits will appear here after submission.',
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.only(bottom: 96),
                              itemCount: visits.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final visit = visits[index];
                                return ManagerListCard(
                                  onTap: () => Navigator.push<void>(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => FieldVisitDetailScreen(
                                        visitId: visit.id,
                                      ),
                                    ),
                                  ),
                                  title: visit.siteName,
                                  subtitle: formatDateTimeLabel(visit.dateTime),
                                  meta: visit.notes,
                                  status: visit.status,
                                  icon: Icons.pin_drop_outlined,
                                );
                              },
                            ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: managerSnapshotFab(context, email),
    );
  }

  Widget? managerSnapshotFab(BuildContext context, String email) {
    return StreamBuilder<ManagerModel?>(
      stream: ManagerRepository.instance.watchManagerByEmail(email),
      builder: (context, snapshot) {
        final manager = snapshot.data;
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }
        if (manager == null) {
          return const SizedBox.shrink();
        }
        return PrimaryFloatingAddButton(
          heroTag: 'field-visit-add-fab',
          tooltip: 'Add Visit',
          onPressed: () => Navigator.push<void>(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  FieldVisitFormScreen(initialSiteName: widget.initialSiteName),
            ),
          ),
        );
      },
    );
  }
}
