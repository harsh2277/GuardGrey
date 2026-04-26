import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../data/admin_dummy_data.dart';
import '../models/branch_model.dart';
import '../models/site_model.dart';
import 'add_branch_screen.dart';
import '../widgets/admin_search_bar.dart';
import '../widgets/site_list_item.dart';
import '../widgets/site_selector_bottom_sheet.dart';

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
  bool _isEditMode = false;
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
    final sites = _isEditMode ? _editableAssignedSites : _assignedSites;
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
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleEditMode() {
    if (_isEditMode) {
      final hadChanges = _draftSiteIds.length != _branch.siteIds.length ||
          !_draftSiteIds.containsAll(_branch.siteIds);

      setState(() {
        _draftSiteIds
          ..clear()
          ..addAll(_branch.siteIds);
        _isEditMode = false;
        _searchController.clear();
        _searchQuery = '';
      });

      if (hadChanges) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Site assignment changes discarded.',
              style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
            ),
            backgroundColor: AppColors.neutral800,
          ),
        );
      }

      return;
    }

    setState(() {
      _draftSiteIds
        ..clear()
        ..addAll(_branch.siteIds);
      _isEditMode = true;
    });
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
    });
  }

  void _removeAssignedSite(String siteId) {
    setState(() {
      _draftSiteIds.remove(siteId);
    });
  }

  void _saveSiteAssignments() {
    setState(() {
      _branch = _branch.copyWith(
        siteIds: _draftSiteIds.toList(growable: false),
      );
      _isEditMode = false;
      _searchController.clear();
      _searchQuery = '';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Branch site assignments updated.',
          style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
        ),
        backgroundColor: AppColors.success,
      ),
    );
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
      if (_isEditMode) {
        _draftSiteIds
          ..clear()
          ..addAll(updated.siteIds);
      }
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
                child: PopupMenuButton<String>(
                  tooltip: 'More actions',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(
                    width: 40,
                    height: 40,
                  ),
                  borderRadius: BorderRadius.circular(999),
                  color: Colors.white,
                  surfaceTintColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: AppColors.neutral200),
                  ),
                  onSelected: (value) {
                    if (value == 'edit') {
                      _openEditBranch();
                    }
                    if (value == 'delete') {
                      _deleteBranch();
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem<String>(
                      value: 'edit',
                      child: Row(
                        children: [
                          const Icon(
                            Icons.edit_outlined,
                            size: 18,
                            color: AppColors.neutral700,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Edit Branch',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.neutral800,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'delete',
                      child: Row(
                        children: [
                          const Icon(
                            Icons.delete_outline_rounded,
                            size: 18,
                            color: AppColors.error,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Delete Branch',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
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
    final assignedCount =
        _isEditMode ? _draftSiteIds.length : _branch.siteIds.length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        AdminSearchBar(
          controller: _searchController,
          hintText: 'Search sites...',
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Assigned Sites',
                    style: AppTextStyles.title.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$assignedCount ${assignedCount == 1 ? 'site' : 'sites'} assigned',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.neutral500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (_isEditMode) ...[
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: _toggleEditMode,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 46),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _openSiteSelector,
                icon: const Icon(Icons.add_business_outlined, size: 18),
                label: const Text('Assign Sites'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 46),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ] else
              OutlinedButton(
                onPressed: _toggleEditMode,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 46),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: const Text('Manage Sites'),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (sites.isEmpty)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.neutral200),
            ),
            child: Text(
              _searchQuery.trim().isEmpty
                  ? 'No sites assigned to this branch yet.'
                  : 'No assigned sites match your search.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.neutral500,
              ),
            ),
          )
        else
          ...sites.map(
            (site) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SiteListItem(
                siteName: site.name,
                subtitle: site.location,
                onTap: _isEditMode
                    ? null
                    : () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Site details will be added soon.',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: Colors.white,
                              ),
                            ),
                            backgroundColor: AppColors.primary600,
                          ),
                        );
                      },
                trailing: _isEditMode
                    ? IconButton(
                        onPressed: () => _removeAssignedSite(site.id),
                        icon: const Icon(
                          Icons.close_rounded,
                          color: AppColors.error,
                          size: 20,
                        ),
                        splashRadius: 20,
                      )
                    : const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 16,
                        color: AppColors.neutral400,
                      ),
              ),
            ),
          ),
        if (_isEditMode) ...[
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _saveSiteAssignments,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: const Text('Save Changes'),
          ),
        ],
      ],
    );
  }

  Widget _buildFieldTitle(String title) {
    return Text(
      title,
      style: AppTextStyles.bodySmall.copyWith(
        color: AppColors.neutral500,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildFieldValue(String value) {
    return Text(
      value,
      style: AppTextStyles.bodyLarge.copyWith(
        color: AppColors.neutral800,
      ),
    );
  }
}
