import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../data/admin_dummy_data.dart';
import '../models/branch_model.dart';
import '../models/site_model.dart';
import 'add_branch_screen.dart';
import '../widgets/site_assignment_tab.dart';
import '../widgets/site_selector_bottom_sheet.dart';
import '../../../widgets/action_bottom_sheet.dart';

class BranchDetailResult {
  final BranchModel? branch;
  final bool deleted;

  const BranchDetailResult({
    this.branch,
    this.deleted = false,
  });
}

class BranchDetailScreen extends StatefulWidget {
  final BranchModel branch;

  const BranchDetailScreen({
    super.key,
    required this.branch,
  });

  @override
  State<BranchDetailScreen> createState() => _BranchDetailScreenState();
}

class _BranchDetailScreenState extends State<BranchDetailScreen> {
  late BranchModel _branch;
  late final TextEditingController _searchController;
  final Set<String> _draftSiteIds = <String>{};
  String _searchQuery = '';

  List<SiteModel> get _assignedSites =>
      AdminDummyData.getSitesByIds(_branch.siteIds);

  List<SiteModel> get _editableAssignedSites =>
      AdminDummyData.getSitesByIds(_draftSiteIds.toList(growable: false));

  String get _createdDate {
    switch (_branch.id) {
      case '1':
        return '12 Jan 2026';
      case '2':
        return '03 Feb 2026';
      default:
        return '18 Mar 2026';
    }
  }

  String get _lastUpdated {
    switch (_branch.id) {
      case '1':
        return 'Today, 10:30 AM';
      case '2':
        return 'Yesterday, 4:15 PM';
      default:
        return 'Today, 2:05 PM';
    }
  }

  String get _totalManagersCount {
    switch (_branch.id) {
      case '1':
        return '12';
      case '2':
        return '09';
      default:
        return '07';
    }
  }

  List<SiteModel> get _filteredSites {
    final sites = _editableAssignedSites;
    final query = _searchQuery.trim().toLowerCase();

    if (query.isEmpty) {
      return sites;
    }

    return sites.where((site) {
      return site.name.toLowerCase().contains(query) ||
          site.location.toLowerCase().contains(query);
    }).toList(growable: false);
  }

  @override
  void initState() {
    super.initState();
    _branch = widget.branch;
    _searchController = TextEditingController();
    _draftSiteIds.addAll(_branch.siteIds);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openSiteSelector() async {
    final selectedSites = await SiteSelectorBottomSheet.show(
      context,
      allSites: AdminDummyData.sites,
      initiallySelectedIds: _draftSiteIds.toList(growable: false),
    );

    if (selectedSites == null) return;

    setState(() {
      _draftSiteIds
        ..clear()
        ..addAll(selectedSites.map((site) => site.id));
      _branch = _branch.copyWith(
        siteIds: _draftSiteIds.toList(growable: false),
      );
    });
  }

  void _removeAssignedSite(String siteId) {
    setState(() {
      _draftSiteIds.remove(siteId);
      _branch = _branch.copyWith(
        siteIds: _draftSiteIds.toList(growable: false),
      );
    });
  }

  Future<void> _openEditBranch() async {
    final updated = await Navigator.push<BranchModel>(
      context,
      MaterialPageRoute(
        builder: (_) => AddBranchScreen(branch: _branch),
      ),
    );

    if (updated == null) return;

    setState(() {
      _branch = updated;
      _draftSiteIds
        ..clear()
        ..addAll(updated.siteIds);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Branch details updated successfully.',
          style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
        ),
        backgroundColor: AppColors.success,
      ),
    );
  }

  Future<void> _openActionsSheet() {
    return ActionBottomSheet.show(
      context,
      items: [
        ActionBottomSheetItem(
          icon: Icons.edit_outlined,
          label: 'Edit Branch',
          onTap: _openEditBranch,
        ),
        ActionBottomSheetItem(
          icon: Icons.delete_outline_rounded,
          label: 'Delete Branch',
          textColor: AppColors.error,
          iconColor: AppColors.error,
          onTap: _deleteBranch,
        ),
      ],
    );
  }

  Future<void> _deleteBranch() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Delete Branch?',
            style: AppTextStyles.title.copyWith(fontWeight: FontWeight.w700),
          ),
          content: Text(
            'Are you sure you want to delete this branch?',
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
      Navigator.pop(context, const BranchDetailResult(deleted: true));
    }
  }

  Future<bool> _handleBackNavigation() async {
    Navigator.pop(context, BranchDetailResult(branch: _branch));
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _handleBackNavigation,
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          backgroundColor: AppColors.backgroundLight,
          appBar: AppBar(
            toolbarHeight: 72,
            leading: IconButton(
              onPressed: () {
                Navigator.pop(context, BranchDetailResult(branch: _branch));
              },
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: AppColors.neutral800,
                size: 20,
              ),
            ),
            backgroundColor: AppColors.neutral50,
            elevation: 0,
            scrolledUnderElevation: 0,
            title: Text(
              'Branch Details',
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
                    splashBorderRadius: BorderRadius.circular(20),
                    overlayColor: WidgetStateProperty.all(Colors.transparent),
                    tabs: [
                      _buildPillTab('Info'),
                      _buildPillTab('Sites'),
                    ],
                    tabAlignment: TabAlignment.fill,
                    isScrollable: false,
                    indicatorPadding: EdgeInsets.zero,
                    labelPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ),
            flexibleSpace: Container(
              color: AppColors.neutral50,
            ),
          ),
          body: TabBarView(
            children: [
              _buildInfoTab(),
              _buildSitesTab(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPillTab(String label) {
    return Container(
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
      ),
      child: Text(label),
    );
  }

  Widget _buildInfoTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        _buildHeaderCard(),
        const SizedBox(height: 24),
        Text(
          'Quick Stats',
          style: AppTextStyles.title.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 16),
        _buildKpiSummaryCard(),
        const SizedBox(height: 24),
        Text(
          'Detailed Info',
          style: AppTextStyles.title.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 14),
        _buildDetailedInfoCard(),
      ],
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
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
            _branch.name,
            style: AppTextStyles.headingSmall.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.neutral900,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 16,
                color: AppColors.primary700,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _branch.city,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.primary800,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _branch.address.trim().isEmpty ? 'Not provided' : _branch.address,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.neutral700,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _buildHeaderMetaChip(
                icon: Icons.apartment_rounded,
                label:
                    '${_assignedSites.length} ${_assignedSites.length == 1 ? 'Site' : 'Sites'}',
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Created $_createdDate',
                  textAlign: TextAlign.right,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.neutral500,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderMetaChip({
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.primary100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: AppColors.primary700,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.primary800,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.neutral50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Column(
        children: [
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: _buildKpiItem(
                    value: '${_assignedSites.length}',
                    label: 'Total Sites',
                    valueColor: AppColors.primary600,
                  ),
                ),
                _buildVerticalDivider(),
                Expanded(
                  child: _buildKpiItem(
                    value: _totalManagersCount,
                    label: 'Total\nManagers',
                    valueColor: AppColors.error,
                  ),
                ),
                _buildVerticalDivider(),
                Expanded(
                  child: _buildKpiItem(
                    value: _createdDate,
                    label: 'Last Update\nDate',
                    valueColor: AppColors.warning,
                    compactValue: true,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiItem({
    required String value,
    required String label,
    required Color valueColor,
    bool compactValue = false,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          value,
          maxLines: compactValue ? 2 : 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: (compactValue
                  ? AppTextStyles.bodyLarge
                  : AppTextStyles.headingSmall)
              .copyWith(
            color: valueColor,
            fontWeight: FontWeight.w700,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          maxLines: 2,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.neutral500,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      color: AppColors.neutral200,
    );
  }

  Widget _buildDetailedInfoCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Column(
        children: [
          _buildInfoRow('Branch Name', _branch.name),
          _buildInfoDivider(),
          _buildInfoRow('City', _branch.city),
          _buildInfoDivider(),
          _buildInfoRow(
            'Address',
            _branch.address.trim().isEmpty ? 'Not provided' : _branch.address,
          ),
          _buildInfoDivider(),
          _buildInfoRow('Created Date', _createdDate),
          _buildInfoDivider(),
          _buildInfoRow('Last Updated', _lastUpdated),
        ],
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
            width: 110,
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

  Widget _buildInfoDivider() {
    return const Divider(
      height: 1,
      thickness: 1,
      color: AppColors.neutral200,
    );
  }

  Widget _buildSitesTab() {
    final sites = _filteredSites;
    return SiteAssignmentTab(
      searchController: _searchController,
      onSearchChanged: (value) {
        setState(() {
          _searchQuery = value;
        });
      },
      onAddPressed: _openSiteSelector,
      addButtonLabel: 'Add Site',
      sites: sites,
      countLabel:
          '${_branch.siteIds.length} ${_branch.siteIds.length == 1 ? 'site' : 'sites'} assigned',
      emptyMessage: _searchQuery.trim().isEmpty
          ? 'No sites assigned to this branch yet.'
          : 'No assigned sites match your search.',
      onRemoveSite: _removeAssignedSite,
    );
  }
}
