import 'package:flutter/material.dart';

import 'package:guardgrey/core/theme/app_colors.dart';
import 'package:guardgrey/core/theme/app_text_styles.dart';
import 'package:guardgrey/core/widgets/action_bottom_sheet.dart';
import 'package:guardgrey/core/widgets/admin_search_bar.dart';
import 'package:guardgrey/core/widgets/attendance_table.dart';
import 'package:guardgrey/core/widgets/list_filter_bottom_sheet.dart';
import 'package:guardgrey/core/widgets/site_assignment_tab.dart';
import 'package:guardgrey/core/widgets/site_selector_bottom_sheet.dart';
import 'package:guardgrey/core/widgets/surface_icon_button.dart';
import 'package:guardgrey/data/models/attendance_record.dart';
import 'package:guardgrey/data/models/manager_model.dart';
import 'package:guardgrey/data/models/site_model.dart';
import 'package:guardgrey/data/repositories/guard_grey_repository.dart';
import 'add_manager_screen.dart';

class ManagerDetailScreen extends StatefulWidget {
  const ManagerDetailScreen({super.key, required this.manager});

  final ManagerModel manager;

  @override
  State<ManagerDetailScreen> createState() => _ManagerDetailScreenState();
}

class _ManagerDetailScreenState extends State<ManagerDetailScreen> {
  final GuardGreyRepository _repository = GuardGreyRepository.instance;
  late final TextEditingController _siteSearchController;
  late final TextEditingController _attendanceSearchController;
  String _siteSearchQuery = '';
  String _attendanceSearchQuery = '';
  String? _attendanceStatus;
  DateTime? _attendanceDate;

  @override
  void initState() {
    super.initState();
    _siteSearchController = TextEditingController();
    _attendanceSearchController = TextEditingController();
  }

  @override
  void dispose() {
    _siteSearchController.dispose();
    _attendanceSearchController.dispose();
    super.dispose();
  }

  Future<void> _openAttendanceFilters() async {
    final filters = await ListFilterBottomSheet.show(
      context,
      title: 'Filter Attendance',
      statusOptions: const ['Present', 'Absent', 'Late'],
      initialStatus: _attendanceStatus,
      initialDate: _attendanceDate,
      showDateFilter: true,
    );

    if (filters == null) {
      return;
    }

    setState(() {
      _attendanceStatus = filters.status;
      _attendanceDate = filters.date;
    });
  }

  Future<void> _openEditManager(ManagerModel manager) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => AddManagerScreen(manager: manager)),
    );
  }

  Future<void> _deleteManager(ManagerModel manager) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Delete Manager?',
            style: AppTextStyles.title.copyWith(fontWeight: FontWeight.w700),
          ),
          content: Text(
            'Are you sure you want to delete this manager?',
            style: AppTextStyles.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                'Delete',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await _repository.deleteManager(manager.id);
    if (!mounted) {
      return;
    }
    Navigator.pop(context);
  }

  Future<void> _openActionsSheet(ManagerModel manager) {
    return ActionBottomSheet.show(
      context,
      items: [
        ActionBottomSheetItem(
          icon: Icons.edit_outlined,
          label: 'Edit Manager',
          onTap: () => _openEditManager(manager),
        ),
        ActionBottomSheetItem(
          icon: Icons.delete_outline_rounded,
          label: 'Delete Manager',
          textColor: AppColors.error,
          iconColor: AppColors.error,
          onTap: () => _deleteManager(manager),
        ),
      ],
    );
  }

  Future<void> _openSiteSelector({
    required ManagerModel manager,
    required List<SiteModel> allSites,
    required List<SiteModel> assignedSites,
  }) async {
    final selectedSites = await SiteSelectorBottomSheet.show(
      context,
      allSites: allSites,
      initiallySelectedIds: assignedSites
          .map((site) => site.id)
          .toList(growable: false),
    );

    if (selectedSites == null) {
      return;
    }

    await _repository.saveManager(
      manager.copyWith(
        siteIds: selectedSites.map((site) => site.id).toList(growable: false),
      ),
    );
  }

  Future<void> _removeAssignedSite({
    required ManagerModel manager,
    required List<SiteModel> assignedSites,
    required String siteId,
  }) {
    final updatedIds = assignedSites
        .where((site) => site.id != siteId)
        .map((site) => site.id)
        .toList(growable: false);
    return _repository.saveManager(manager.copyWith(siteIds: updatedIds));
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.backgroundLight,
        appBar: AppBar(
          backgroundColor: AppColors.neutral50,
          elevation: 0,
          scrolledUnderElevation: 0,
          title: Text(
            'Manager Details',
            style: AppTextStyles.title.copyWith(fontWeight: FontWeight.w700),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 20),
              child: Center(
                child: SurfaceIconButton(
                  icon: Icons.more_vert_rounded,
                  size: 40,
                  iconSize: 20,
                  borderRadius: 20,
                  onTap: () => _openActionsSheet(widget.manager),
                ),
              ),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(68),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.neutral100,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.neutral200),
                ),
                child: TabBar(
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: AppColors.primary700,
                  unselectedLabelColor: AppColors.neutral500,
                  labelStyle: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  unselectedLabelStyle: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  indicator: BoxDecoration(
                    color: AppColors.primary100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  overlayColor: WidgetStateProperty.all(Colors.transparent),
                  tabs: const [
                    Tab(text: 'Info'),
                    Tab(text: 'Sites'),
                    Tab(text: 'Attendance'),
                  ],
                ),
              ),
            ),
          ),
        ),
        body: StreamBuilder<ManagerModel?>(
          stream: _repository.watchManager(widget.manager.id),
          builder: (context, managerSnapshot) {
            if (managerSnapshot.connectionState == ConnectionState.waiting &&
                !managerSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final manager = managerSnapshot.data;
            if (manager == null) {
              return _buildUnavailableState('Manager no longer exists.');
            }

            return StreamBuilder<List<SiteModel>>(
              stream: _repository.watchSites(),
              builder: (context, sitesSnapshot) {
                final allSites = sitesSnapshot.data ?? const <SiteModel>[];
                final assignedSites = allSites
                    .where((site) => manager.siteIds.contains(site.id))
                    .toList(growable: false);
                final filteredSites = _filterSites(assignedSites);

                return StreamBuilder<List<AttendanceRecord>>(
                  stream: _repository.watchAttendance(),
                  builder: (context, attendanceSnapshot) {
                    final allAttendance =
                        attendanceSnapshot.data ?? const <AttendanceRecord>[];
                    final filteredAttendance = _filterAttendance(
                      allAttendance
                          .where((record) {
                            return record.managerId == manager.id ||
                                record.name == manager.name;
                          })
                          .toList(growable: false),
                    );

                    return TabBarView(
                      children: [
                        _buildInfoTab(manager),
                        SiteAssignmentTab(
                          searchController: _siteSearchController,
                          onSearchChanged: (value) {
                            setState(() {
                              _siteSearchQuery = value;
                            });
                          },
                          onAddPressed: () => _openSiteSelector(
                            manager: manager,
                            allSites: allSites,
                            assignedSites: assignedSites,
                          ),
                          addButtonLabel: 'Add Site',
                          sites: filteredSites,
                          countLabel:
                              '${assignedSites.length} ${assignedSites.length == 1 ? 'site' : 'sites'} assigned',
                          emptyMessage: _siteSearchQuery.trim().isEmpty
                              ? 'No sites assigned to this manager yet.'
                              : 'No assigned sites match your search.',
                          onRemoveSite: (siteId) => _removeAssignedSite(
                            manager: manager,
                            assignedSites: assignedSites,
                            siteId: siteId,
                          ),
                        ),
                        _buildAttendanceTab(filteredAttendance),
                      ],
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  List<SiteModel> _filterSites(List<SiteModel> sites) {
    final query = _siteSearchQuery.trim().toLowerCase();
    if (query.isEmpty) {
      return sites;
    }

    return sites
        .where((site) {
          return site.name.toLowerCase().contains(query) ||
              site.location.toLowerCase().contains(query);
        })
        .toList(growable: false);
  }

  List<AttendanceRecord> _filterAttendance(List<AttendanceRecord> records) {
    final query = _attendanceSearchQuery.trim().toLowerCase();
    if (query.isEmpty && _attendanceStatus == null && _attendanceDate == null) {
      return records;
    }

    return records
        .where((record) {
          final matchesQuery =
              query.isEmpty ||
              record.status.toLowerCase().contains(query) ||
              record.date.toLowerCase().contains(query) ||
              record.checkIn.toLowerCase().contains(query) ||
              record.checkOut.toLowerCase().contains(query) ||
              record.siteName.toLowerCase().contains(query);
          final matchesStatus =
              _attendanceStatus == null ||
              record.status.toLowerCase() == _attendanceStatus!.toLowerCase();
          final matchesDate =
              _attendanceDate == null ||
              record.date == GuardGreyRepository.formatDate(_attendanceDate);
          return matchesQuery && matchesStatus && matchesDate;
        })
        .toList(growable: false);
  }

  Widget _buildInfoTab(ManagerModel manager) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.primary50,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.primary100),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                manager.name,
                style: AppTextStyles.headingSmall.copyWith(
                  color: AppColors.neutral900,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                manager.email,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.primary700,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                manager.phone,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.neutral700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Last Location',
          style: AppTextStyles.title.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        Container(
          height: 112,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.neutral200),
          ),
          alignment: Alignment.center,
          child: Text(
            'Location preview unavailable',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.neutral500,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Detailed Info',
          style: AppTextStyles.title.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.neutral200),
          ),
          child: Column(
            children: [
              _buildInfoRow('Name', manager.name),
              _buildDivider(),
              _buildInfoRow('Email', manager.email),
              _buildDivider(),
              _buildInfoRow('Mobile', manager.phone),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.neutral500,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.neutral900,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceTab(List<AttendanceRecord> records) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: AdminSearchBar(
                  controller: _attendanceSearchController,
                  height: 50,
                  hintText: 'Search attendance...',
                  onChanged: (value) {
                    setState(() {
                      _attendanceSearchQuery = value;
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              SurfaceIconButton(
                icon: Icons.tune_rounded,
                onTap: _openAttendanceFilters,
                backgroundColor: AppColors.primary600,
                borderColor: AppColors.primary600,
                iconColor: Colors.white,
                borderRadius: 25,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: records.isEmpty
                ? _buildUnavailableState('No attendance records available.')
                : AttendanceTable(
                    records: records,
                    profileImageForRecord: (record) =>
                        widget.manager.profileImage,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, thickness: 1, color: AppColors.neutral200);
  }

  Widget _buildUnavailableState(String message) {
    return Center(
      child: Text(
        message,
        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.neutral500),
      ),
    );
  }
}
