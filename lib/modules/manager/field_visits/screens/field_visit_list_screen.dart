import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:guardgrey/core/theme/app_colors.dart';
import 'package:guardgrey/core/theme/app_text_styles.dart';
import 'package:guardgrey/core/utils/date_time_display.dart';
import 'package:guardgrey/core/widgets/admin_search_bar.dart';
import 'package:guardgrey/core/widgets/list_filter_bottom_sheet.dart';
import 'package:guardgrey/core/widgets/primary_floating_add_button.dart';
import 'package:guardgrey/core/widgets/surface_icon_button.dart';
import 'package:guardgrey/data/models/field_visit_model.dart';
import 'package:guardgrey/data/models/manager_model.dart';
import 'package:guardgrey/data/repositories/field_visit_repository.dart';
import 'package:guardgrey/data/repositories/guard_grey_repository.dart';
import 'package:guardgrey/data/repositories/manager_repository.dart';

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
  String? _selectedManagerName;
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

  Future<void> _openFilters(List<FieldVisitModel> visits) async {
    final managerOptions =
        visits.map((visit) => visit.managerName).toSet().toList()..sort();

    final filters = await ListFilterBottomSheet.show(
      context,
      title: 'Filter Field Visits',
      initialDate: _selectedDate,
      showDateFilter: true,
      extraDropdowns: [
        ListFilterDropdownField(
          key: 'managerName',
          label: 'Manager',
          options: managerOptions,
          initialValue: _selectedManagerName,
        ),
      ],
    );

    if (filters == null) {
      return;
    }

    setState(() {
      _selectedManagerName = filters.extraSelections['managerName'];
      _selectedDate = filters.date;
    });
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
              visit.description.toLowerCase().contains(query);
          final matchesManagerFilter =
              _selectedManagerName == null ||
              visit.managerName == _selectedManagerName;
          final matchesDate =
              _selectedDate == null ||
              formatDateLabel(visit.dateTime) ==
                  GuardGreyRepository.formatDate(_selectedDate);
          return matchesManager &&
              matchesSite &&
              matchesQuery &&
              matchesManagerFilter &&
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

          final canAddVisit = manager != null;

          return StreamBuilder<List<FieldVisitModel>>(
            stream: FieldVisitRepository.instance.watchFieldVisits(),
            builder: (context, snapshot) {
              final allVisits = snapshot.data ?? const <FieldVisitModel>[];
              final visits = _filterVisits(allVisits, manager: manager);

              return Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
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
                        SurfaceIconButton(
                          icon: Icons.tune_rounded,
                          onTap: () => _openFilters(allVisits),
                          backgroundColor: AppColors.primary600,
                          borderColor: AppColors.primary600,
                          iconColor: Colors.white,
                          borderRadius: 25,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: visits.isEmpty
                          ? Center(
                              child: Text(
                                'No field visits match the current search or filters.',
                                textAlign: TextAlign.center,
                                style: AppTextStyles.bodyLarge.copyWith(
                                  color: AppColors.neutral500,
                                ),
                              ),
                            )
                          : ListView.separated(
                              padding: EdgeInsets.only(
                                bottom: canAddVisit ? 96 : 0,
                              ),
                              itemCount: visits.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final visit = visits[index];
                                return Material(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(18),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(18),
                                    onTap: () => Navigator.push<void>(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => FieldVisitDetailScreen(
                                          visitId: visit.id,
                                        ),
                                      ),
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(18),
                                        border: Border.all(
                                          color: AppColors.neutral200,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            visit.siteName,
                                            style: AppTextStyles.bodyLarge
                                                .copyWith(
                                                  fontWeight: FontWeight.w700,
                                                ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            visit.managerName,
                                            style: AppTextStyles.bodySmall
                                                .copyWith(
                                                  color: AppColors.primary700,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            formatDateTimeLabel(visit.dateTime),
                                            style: AppTextStyles.bodyMedium
                                                .copyWith(
                                                  color: AppColors.neutral500,
                                                ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            visit.description,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: AppTextStyles.bodyMedium
                                                .copyWith(
                                                  color: AppColors.neutral700,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
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
