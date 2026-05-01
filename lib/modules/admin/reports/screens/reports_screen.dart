import 'package:flutter/material.dart';

import 'package:guardgrey/core/theme/app_colors.dart';
import 'package:guardgrey/core/theme/app_text_styles.dart';
import 'package:guardgrey/core/utils/date_time_display.dart';
import 'package:guardgrey/core/widgets/admin_search_bar.dart';
import 'package:guardgrey/core/widgets/list_filter_bottom_sheet.dart';
import 'package:guardgrey/core/widgets/primary_floating_add_button.dart';
import 'package:guardgrey/core/widgets/surface_icon_button.dart';
import 'package:guardgrey/data/models/report_model.dart';
import 'package:guardgrey/data/repositories/report_repository.dart';
import 'package:guardgrey/data/repositories/guard_grey_repository.dart';

import 'report_detail_screen.dart';
import 'report_form_screen.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  late final TextEditingController _searchController;
  String _searchQuery = '';
  String? _selectedType;
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
    final filters = await ListFilterBottomSheet.show(
      context,
      title: 'Filter Reports',
      statusLabel: 'Report Type',
      statusOptions: const ['training', 'site_visit', 'night_visit'],
      initialStatus: _selectedType,
      initialDate: _selectedDate,
      showDateFilter: true,
    );

    if (filters == null) {
      return;
    }

    setState(() {
      _selectedType = filters.status;
      _selectedDate = filters.date;
    });
  }

  List<ReportModel> _filterReports(List<ReportModel> reports) {
    final query = _searchQuery.trim().toLowerCase();
    return reports
        .where((report) {
          final matchesQuery =
              query.isEmpty ||
              report.reportName.toLowerCase().contains(query) ||
              report.managerName.toLowerCase().contains(query) ||
              report.location.address.toLowerCase().contains(query) ||
              report.reportType.toLowerCase().contains(query);
          final matchesType =
              _selectedType == null || report.reportType == _selectedType;
          final matchesDate =
              _selectedDate == null ||
              formatDateLabel(report.dateTime) ==
                  GuardGreyRepository.formatDate(_selectedDate);
          return matchesQuery && matchesType && matchesDate;
        })
        .toList(growable: false);
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
          'Reports',
          style: AppTextStyles.title.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      floatingActionButton: PrimaryFloatingAddButton(
        heroTag: 'reports-add-fab',
        tooltip: 'Add Report',
        onPressed: () => Navigator.push<void>(
          context,
          MaterialPageRoute(builder: (_) => const ReportFormScreen()),
        ),
      ),
      body: StreamBuilder<List<ReportModel>>(
        stream: ReportRepository.instance.watchReports(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final reports = _filterReports(
            snapshot.data ?? const <ReportModel>[],
          );

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
                        hintText: 'Search reports...',
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
                      onTap: _openFilters,
                      backgroundColor: AppColors.primary600,
                      borderColor: AppColors.primary600,
                      iconColor: Colors.white,
                      borderRadius: 25,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: reports.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Text(
                              'No reports match the current search or filters.',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.bodyLarge.copyWith(
                                color: AppColors.neutral500,
                              ),
                            ),
                          ),
                        )
                      : ListView.separated(
                          itemCount: reports.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final report = reports[index];
                            return Material(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(18),
                                onTap: () => Navigator.push<void>(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        ReportDetailScreen(reportId: report.id),
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
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          color: AppColors.primary50,
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.assignment_outlined,
                                          color: AppColors.primary600,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              report.reportName,
                                              style: AppTextStyles.bodyLarge
                                                  .copyWith(
                                                    fontWeight: FontWeight.w700,
                                                    color: AppColors.neutral900,
                                                  ),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              report.managerName,
                                              style: AppTextStyles.bodySmall
                                                  .copyWith(
                                                    color: AppColors.neutral500,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${report.reportType.replaceAll('_', ' ')} • ${formatDateLabel(report.dateTime)}',
                                              style: AppTextStyles.bodyMedium
                                                  .copyWith(
                                                    color: AppColors.primary700,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      PopupMenuButton<String>(
                                        onSelected: (value) {
                                          if (value == 'edit') {
                                            Navigator.push<void>(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    ReportFormScreen(
                                                      report: report,
                                                    ),
                                              ),
                                            );
                                            return;
                                          }
                                          if (value == 'delete') {
                                            _deleteReport(context, report);
                                          }
                                        },
                                        itemBuilder: (context) => const [
                                          PopupMenuItem<String>(
                                            value: 'edit',
                                            child: Text('Edit'),
                                          ),
                                          PopupMenuItem<String>(
                                            value: 'delete',
                                            child: Text('Delete'),
                                          ),
                                        ],
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
      ),
    );
  }

  Future<void> _deleteReport(BuildContext context, ReportModel report) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete Report?',
          style: AppTextStyles.title.copyWith(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'This will remove ${report.reportName} permanently.',
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
      ),
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    await ReportRepository.instance.deleteReport(report.id);
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.success,
        content: Text(
          'Report deleted successfully.',
          style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
        ),
      ),
    );
  }
}
