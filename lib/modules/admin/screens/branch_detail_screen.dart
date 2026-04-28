import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../widgets/surface_icon_button.dart';
import '../../../widgets/action_bottom_sheet.dart';
import '../models/branch_model.dart';
import '../models/site_model.dart';
import '../services/firestore_admin_repository.dart';
import '../widgets/site_assignment_tab.dart';
import '../widgets/site_selector_bottom_sheet.dart';
import 'add_branch_screen.dart';

class BranchDetailScreen extends StatefulWidget {
  const BranchDetailScreen({super.key, required this.branch});

  final BranchModel branch;

  @override
  State<BranchDetailScreen> createState() => _BranchDetailScreenState();
}

class _BranchDetailScreenState extends State<BranchDetailScreen> {
  final FirestoreAdminRepository _repository =
      FirestoreAdminRepository.instance;
  late final TextEditingController _searchController;
  String _searchQuery = '';

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

  Future<void> _openEditBranch(BranchModel branch) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => AddBranchScreen(branch: branch)),
    );
  }

  Future<void> _deleteBranch(BranchModel branch) async {
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

    if (confirmed != true) {
      return;
    }

    await _repository.deleteBranch(branch.id);
    if (!mounted) {
      return;
    }
    Navigator.pop(context);
  }

  Future<void> _openActionsSheet(BranchModel branch) {
    return ActionBottomSheet.show(
      context,
      items: [
        ActionBottomSheetItem(
          icon: Icons.edit_outlined,
          label: 'Edit Branch',
          onTap: () => _openEditBranch(branch),
        ),
        ActionBottomSheetItem(
          icon: Icons.delete_outline_rounded,
          label: 'Delete Branch',
          textColor: AppColors.error,
          iconColor: AppColors.error,
          onTap: () => _deleteBranch(branch),
        ),
      ],
    );
  }

  Future<void> _openSiteSelector({
    required BranchModel branch,
    required List<SiteModel> allSites,
  }) async {
    final selectedSites = await SiteSelectorBottomSheet.show(
      context,
      allSites: allSites,
      initiallySelectedIds: branch.siteIds,
    );

    if (selectedSites == null) {
      return;
    }

    await _repository.saveBranch(
      branch.copyWith(
        siteIds: selectedSites.map((site) => site.id).toList(growable: false),
      ),
    );
  }

  Future<void> _removeAssignedSite({
    required BranchModel branch,
    required List<SiteModel> assignedSites,
    required String siteId,
  }) {
    final updatedIds = assignedSites
        .where((site) => site.id != siteId)
        .map((site) => site.id)
        .toList(growable: false);
    return _repository.saveBranch(branch.copyWith(siteIds: updatedIds));
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.backgroundLight,
        appBar: AppBar(
          toolbarHeight: 72,
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
              child: Center(
                child: SurfaceIconButton(
                  icon: Icons.more_vert_rounded,
                  size: 40,
                  iconSize: 20,
                  borderRadius: 20,
                  onTap: () => _openActionsSheet(widget.branch),
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
                  tabs: const [
                    Tab(text: 'Info'),
                    Tab(text: 'Sites'),
                  ],
                ),
              ),
            ),
          ),
        ),
        body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: _repository.watchBranchDocument(widget.branch.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final rawDoc = snapshot.data;
            if (rawDoc == null || !rawDoc.exists) {
              return _buildUnavailableState('Branch no longer exists.');
            }

            final branch = _branchFromDoc(rawDoc);
            final data = rawDoc.data() ?? const <String, dynamic>{};
            final createdAt = data['createdAt'] is Timestamp
                ? (data['createdAt'] as Timestamp).toDate()
                : null;
            final updatedAt = data['updatedAt'] is Timestamp
                ? (data['updatedAt'] as Timestamp).toDate()
                : null;

            return StreamBuilder<List<SiteModel>>(
              stream: _repository.watchSites(),
              builder: (context, sitesSnapshot) {
                final allSites = sitesSnapshot.data ?? const <SiteModel>[];
                final assignedSites = allSites
                    .where((site) => branch.siteIds.contains(site.id))
                    .toList(growable: false);
                final filteredSites = _filterSites(assignedSites);
                final totalManagersCount = assignedSites
                    .map((site) => site.managerId)
                    .where((id) => id.trim().isNotEmpty)
                    .toSet()
                    .length;

                return TabBarView(
                  children: [
                    _buildInfoTab(
                      branch: branch,
                      assignedSites: assignedSites,
                      createdAt: createdAt,
                      updatedAt: updatedAt,
                      totalManagersCount: totalManagersCount,
                    ),
                    SiteAssignmentTab(
                      searchController: _searchController,
                      onSearchChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                      onAddPressed: () =>
                          _openSiteSelector(branch: branch, allSites: allSites),
                      addButtonLabel: 'Add Site',
                      sites: filteredSites,
                      countLabel:
                          '${assignedSites.length} ${assignedSites.length == 1 ? 'site' : 'sites'} assigned',
                      emptyMessage: _searchQuery.trim().isEmpty
                          ? 'No sites assigned to this branch yet.'
                          : 'No assigned sites match your search.',
                      onRemoveSite: (siteId) => _removeAssignedSite(
                        branch: branch,
                        assignedSites: assignedSites,
                        siteId: siteId,
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  BranchModel _branchFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    final siteIds = (data['siteIds'] as List<dynamic>? ?? const [])
        .map((item) => '$item'.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);

    return BranchModel(
      id: doc.id,
      name: (data['name'] as String? ?? '').trim(),
      city: (data['city'] as String? ?? '').trim(),
      address: (data['address'] as String? ?? '').trim(),
      buildingFloor:
          (data['buildingFloor'] as String? ??
                  data['buildingName'] as String? ??
                  data['floor'] as String? ??
                  '')
              .trim(),
      siteIds: siteIds,
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
    );
  }

  List<SiteModel> _filterSites(List<SiteModel> sites) {
    final query = _searchQuery.trim().toLowerCase();
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

  Widget _buildInfoTab({
    required BranchModel branch,
    required List<SiteModel> assignedSites,
    required DateTime? createdAt,
    required DateTime? updatedAt,
    required int totalManagersCount,
  }) {
    final createdLabel = FirestoreAdminRepository.formatDate(createdAt);
    final updatedLabel = FirestoreAdminRepository.formatDate(updatedAt);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        _buildHeaderCard(branch, assignedSites.length, createdLabel),
        const SizedBox(height: 24),
        Text(
          'Quick Stats',
          style: AppTextStyles.title.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 16),
        _buildKpiSummaryCard(
          totalSites: assignedSites.length,
          totalManagersCount: totalManagersCount,
          updatedLabel: updatedLabel,
        ),
        const SizedBox(height: 24),
        Text(
          'Detailed Info',
          style: AppTextStyles.title.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 14),
        _buildDetailedInfoCard(
          branch: branch,
          createdLabel: createdLabel,
          updatedLabel: updatedLabel,
        ),
      ],
    );
  }

  Widget _buildHeaderCard(
    BranchModel branch,
    int totalSites,
    String createdLabel,
  ) {
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
            branch.name,
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
                  branch.city,
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
            branch.address.trim().isEmpty ? 'Not provided' : branch.address,
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
                label: '$totalSites ${totalSites == 1 ? 'Site' : 'Sites'}',
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  createdLabel.isEmpty ? '' : 'Created $createdLabel',
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

  Widget _buildHeaderMetaChip({required IconData icon, required String label}) {
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
          Icon(icon, size: 16, color: AppColors.primary700),
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

  Widget _buildKpiSummaryCard({
    required int totalSites,
    required int totalManagersCount,
    required String updatedLabel,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.neutral50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.neutral200),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: _buildKpiItem(
                value: '$totalSites',
                label: 'Total Sites',
                valueColor: AppColors.primary600,
              ),
            ),
            _buildVerticalDivider(),
            Expanded(
              child: _buildKpiItem(
                value: '$totalManagersCount',
                label: 'Total\nManagers',
                valueColor: AppColors.error,
              ),
            ),
            _buildVerticalDivider(),
            Expanded(
              child: _buildKpiItem(
                value: updatedLabel,
                label: 'Last Update\nDate',
                valueColor: AppColors.warning,
                compactValue: true,
              ),
            ),
          ],
        ),
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
          style:
              (compactValue
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

  Widget _buildDetailedInfoCard({
    required BranchModel branch,
    required String createdLabel,
    required String updatedLabel,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Column(
        children: [
          _buildInfoRow('Branch Name', branch.name),
          _buildInfoDivider(),
          _buildInfoRow('City', branch.city),
          _buildInfoDivider(),
          _buildInfoRow(
            'Address',
            branch.address.trim().isEmpty ? 'Not provided' : branch.address,
          ),
          _buildInfoDivider(),
          _buildInfoRow(
            'Building / Floor',
            branch.buildingFloor.trim().isEmpty
                ? 'Not provided'
                : branch.buildingFloor,
          ),
          _buildInfoDivider(),
          _buildInfoRow('Created Date', createdLabel),
          _buildInfoDivider(),
          _buildInfoRow('Last Updated', updatedLabel),
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
