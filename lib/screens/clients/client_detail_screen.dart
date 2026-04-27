import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../modules/admin/data/admin_dummy_data.dart';
import '../../modules/admin/models/client_model.dart';
import '../../modules/admin/models/site_model.dart';
import '../../modules/admin/widgets/site_assignment_tab.dart';
import '../../modules/admin/widgets/site_selector_bottom_sheet.dart';
import '../../widgets/action_bottom_sheet.dart';
import 'add_client_screen.dart';

class ClientDetailResult {
  const ClientDetailResult({
    this.client,
    this.siteIds = const <String>[],
    this.deleted = false,
  });

  final ClientModel? client;
  final List<String> siteIds;
  final bool deleted;
}

class ClientDetailScreen extends StatefulWidget {
  const ClientDetailScreen({
    super.key,
    required this.client,
    required this.allSites,
  });

  final ClientModel client;
  final List<SiteModel> allSites;

  @override
  State<ClientDetailScreen> createState() => _ClientDetailScreenState();
}

class _ClientDetailScreenState extends State<ClientDetailScreen> {
  late ClientModel _client;
  late final TextEditingController _searchController;
  late List<SiteModel> _allSites;
  String _searchQuery = '';

  String get _branchName =>
      AdminDummyData.getBranchById(_client.branchId)?.name ??
      'Unassigned Branch';

  List<SiteModel> get _assignedSites => _allSites
      .where((site) => site.clientId == _client.id)
      .toList(growable: false);

  List<SiteModel> get _filteredSites {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) {
      return _assignedSites;
    }

    return _assignedSites.where((site) {
      return site.name.toLowerCase().contains(query) ||
          site.location.toLowerCase().contains(query);
    }).toList(growable: false);
  }

  @override
  void initState() {
    super.initState();
    _client = widget.client;
    _searchController = TextEditingController();
    _allSites = widget.allSites.toList(growable: true);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openEditClient() async {
    final updated = await Navigator.push<ClientEditorResult>(
      context,
      MaterialPageRoute(
        builder: (_) => AddClientScreen(
          client: _client,
          allSites: _allSites,
          initialSiteIds: _assignedSites.map((site) => site.id).toList(),
        ),
      ),
    );

    if (updated == null) return;

    setState(() {
      _client = updated.client;
      _applySiteAssignments(updated.siteIds);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Client updated successfully.',
          style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
        ),
        backgroundColor: AppColors.success,
      ),
    );
  }

  Future<void> _deleteClient() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Delete Client?',
            style: AppTextStyles.title.copyWith(fontWeight: FontWeight.w700),
          ),
          content: Text(
            'Are you sure you want to delete this client?',
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
      Navigator.pop(context, const ClientDetailResult(deleted: true));
    }
  }

  Future<void> _openActionsSheet() {
    return ActionBottomSheet.show(
      context,
      items: [
        ActionBottomSheetItem(
          icon: Icons.edit_outlined,
          label: 'Edit Client',
          onTap: _openEditClient,
        ),
        ActionBottomSheetItem(
          icon: Icons.delete_outline_rounded,
          label: 'Delete Client',
          textColor: AppColors.error,
          iconColor: AppColors.error,
          onTap: _deleteClient,
        ),
      ],
    );
  }

  Future<void> _openSiteSelector() async {
    final selectedSites = await SiteSelectorBottomSheet.show(
      context,
      allSites: _branchSites,
      initiallySelectedIds: _assignedSites.map((site) => site.id).toList(),
    );

    if (selectedSites == null) return;

    setState(() {
      _applySiteAssignments(
        selectedSites.map((site) => site.id).toList(growable: false),
      );
    });
  }

  void _removeAssignedSite(String siteId) {
    setState(() {
      _applySiteAssignments(
        _assignedSites
            .where((site) => site.id != siteId)
            .map((site) => site.id)
            .toList(growable: false),
      );
    });
  }

  List<SiteModel> get _branchSites => _allSites
      .where((site) => site.branchId == _client.branchId || site.clientId == _client.id)
      .toList(growable: false);

  void _applySiteAssignments(List<String> selectedSiteIds) {
    final selectedIdSet = selectedSiteIds.toSet();
    _allSites = _allSites.map((site) {
      if (selectedIdSet.contains(site.id)) {
        return site.copyWith(clientId: _client.id);
      }

      if (site.clientId == _client.id) {
        return site.copyWith(clientId: '');
      }

      return site;
    }).toList(growable: true);
  }

  Future<bool> _handleBackNavigation() async {
    Navigator.pop(
      context,
      ClientDetailResult(
        client: _client,
        siteIds: _assignedSites.map((site) => site.id).toList(growable: false),
      ),
    );
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
            backgroundColor: AppColors.neutral50,
            elevation: 0,
            scrolledUnderElevation: 0,
            title: Text(
              'Client Details',
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
                _client.name,
                style: AppTextStyles.headingSmall.copyWith(
                  color: AppColors.neutral900,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _client.email,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.primary700,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _client.phone,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.neutral700,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _branchName,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.neutral500,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
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
              _buildInfoRow('Name', _client.name),
              _buildDivider(),
              _buildInfoRow('Email', _client.email),
              _buildDivider(),
              _buildInfoRow('Mobile', _client.phone),
              _buildDivider(),
              _buildInfoRow('Branch', _branchName),
            ],
          ),
        ),
      ],
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
          '${_assignedSites.length} ${_assignedSites.length == 1 ? 'site' : 'sites'} assigned',
      emptyMessage: _searchQuery.trim().isEmpty
          ? 'No sites assigned to this client yet.'
          : 'No assigned sites match your search.',
      onRemoveSite: _removeAssignedSite,
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

  Widget _buildDivider() {
    return const Divider(
      height: 1,
      thickness: 1,
      color: AppColors.neutral200,
    );
  }
}
