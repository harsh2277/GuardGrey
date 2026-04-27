import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../data/admin_dummy_data.dart';
import '../models/manager_model.dart';
import '../models/site_model.dart';
import '../models/visit_model.dart';
import '../widgets/admin_search_bar.dart';
import '../widgets/manager_card.dart';
import '../widgets/visit_table.dart';
import 'add_site_screen.dart';

class SiteDetailResult {
  final SiteModel? site;
  final bool deleted;

  const SiteDetailResult({
    this.site,
    this.deleted = false,
  });
}

class SiteDetailScreen extends StatefulWidget {
  final SiteModel site;

  const SiteDetailScreen({
    super.key,
    required this.site,
  });

  @override
  State<SiteDetailScreen> createState() => _SiteDetailScreenState();
}

class _SiteDetailScreenState extends State<SiteDetailScreen> {
  late SiteModel _site;
  late final TextEditingController _searchController;
  String _searchQuery = '';

  String get _clientName => AdminDummyData.getClientName(_site.clientId);
  String get _branchName => AdminDummyData.getBranchName(_site.branchId);
  ManagerModel? get _manager => AdminDummyData.getManagerById(_site.managerId);

  List<VisitModel> get _visits {
    final visits = AdminDummyData.getVisitsBySiteId(_site.id);
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) {
      return visits;
    }

    return visits.where((visit) {
      return visit.managerName.toLowerCase().contains(query) ||
          visit.date.toLowerCase().contains(query) ||
          visit.day.toLowerCase().contains(query) ||
          visit.time.toLowerCase().contains(query) ||
          visit.status.toLowerCase().contains(query) ||
          visit.notes.toLowerCase().contains(query);
    }).toList(growable: false);
  }

  @override
  void initState() {
    super.initState();
    _site = widget.site;
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openEditSite() async {
    final updated = await Navigator.push<SiteModel>(
      context,
      MaterialPageRoute(builder: (_) => AddSiteScreen(site: _site)),
    );

    if (updated != null) {
      setState(() {
        _site = updated;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Site updated successfully.',
              style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  Future<void> _deleteSite() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Delete Site?',
            style: AppTextStyles.title.copyWith(fontWeight: FontWeight.w700),
          ),
          content: Text(
            'This action cannot be undone.',
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

    if (confirmed == true && mounted) {
      Navigator.pop(context, const SiteDetailResult(deleted: true));
    }
  }

  Future<void> _openActionsSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildActionSheetItem(
                  icon: Icons.edit_outlined,
                  label: 'Edit Site',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _openEditSite();
                  },
                ),
                const SizedBox(height: 12),
                _buildActionSheetItem(
                  icon: Icons.delete_outline_rounded,
                  label: 'Delete Site',
                  textColor: AppColors.error,
                  iconColor: AppColors.error,
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _deleteSite();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<bool> _handleBackNavigation() async {
    Navigator.pop(context, SiteDetailResult(site: _site));
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final visits = _visits;

    return WillPopScope(
      onWillPop: _handleBackNavigation,
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          backgroundColor: AppColors.backgroundLight,
          appBar: AppBar(
            backgroundColor: AppColors.neutral50,
            elevation: 0,
            scrolledUnderElevation: 0,
            title: Text(
              'Site Details',
              style: AppTextStyles.title.copyWith(fontWeight: FontWeight.w700),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 20),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _openActionsSheet,
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.neutral100,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.neutral200),
                      ),
                      child: const Icon(
                        Icons.more_vert_rounded,
                        color: AppColors.neutral700,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(68),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
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
                    overlayColor:
                        WidgetStateProperty.all(Colors.transparent),
                    tabs: const [
                      Tab(text: 'Info'),
                      Tab(text: 'Visit History'),
                    ],
                  ),
                ),
              ),
            ),
          ),
          body: TabBarView(
            children: [
              _buildInfoTab(),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                child: Column(
                  children: [
                    AdminSearchBar(
                      height: 50,
                      hintText: 'Search visits...',
                      controller: _searchController,
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: visits.isEmpty
                          ? _buildVisitsEmptyState()
                          : VisitTable(visits: visits),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoTab() {
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
                _site.name,
                style: AppTextStyles.headingSmall.copyWith(
                  color: AppColors.neutral900,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _clientName,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.primary700,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _branchName,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.neutral700,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _site.address.trim().isEmpty ? _site.location : _site.address,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.neutral700,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Created ${_site.createdDate}',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.neutral500,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Assigned Manager',
          style: AppTextStyles.title.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        if (_manager != null)
          ManagerCard(manager: _manager!)
        else
          _buildFallbackCard('No manager assigned'),
        const SizedBox(height: 20),
        Text(
          'Detailed Info',
          style: AppTextStyles.title.copyWith(
            fontWeight: FontWeight.w700,
          ),
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
              _buildInfoRow('Site Name', _site.name),
              _buildDivider(),
              _buildInfoRow('Client', _clientName),
              _buildDivider(),
              _buildInfoRow('Branch', _branchName),
              _buildDivider(),
              _buildInfoRow(
                'Address',
                _site.address.trim().isEmpty ? _site.location : _site.address,
              ),
              _buildDivider(),
              _buildInfoRow(
                'Description',
                _site.description.trim().isEmpty
                    ? 'No description added'
                    : _site.description,
              ),
              _buildDivider(),
              _buildInfoRow('Created Date', _site.createdDate),
              _buildDivider(),
              _buildInfoRow('Last Updated', _site.lastUpdated),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFallbackCard(String text) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Text(
        text,
        style: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.neutral500,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
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

  Widget _buildDivider() {
    return const Divider(
      height: 1,
      thickness: 1,
      color: AppColors.neutral200,
    );
  }

  Widget _buildActionSheetItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color textColor = AppColors.neutral900,
    Color iconColor = AppColors.neutral700,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.neutral50,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.neutral200),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: iconColor),
              const SizedBox(width: 12),
              Text(
                label,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVisitsEmptyState() {
    return Center(
      child: Text(
        'No visits available',
        style: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.neutral500,
        ),
      ),
    );
  }
}
