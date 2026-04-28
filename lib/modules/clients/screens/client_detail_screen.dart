import 'package:flutter/material.dart';

import 'package:guardgrey/core/theme/app_colors.dart';
import 'package:guardgrey/core/theme/app_text_styles.dart';
import 'package:guardgrey/core/widgets/action_bottom_sheet.dart';
import 'package:guardgrey/core/widgets/site_assignment_tab.dart';
import 'package:guardgrey/core/widgets/site_selector_bottom_sheet.dart';
import 'package:guardgrey/core/widgets/surface_icon_button.dart';
import 'package:guardgrey/modules/branches/models/branch_model.dart';
import 'package:guardgrey/modules/clients/models/client_model.dart';
import 'package:guardgrey/modules/sites/models/site_model.dart';
import 'package:guardgrey/services/firebase/firestore_admin_repository.dart';
import 'add_client_screen.dart';

class ClientDetailScreen extends StatefulWidget {
  const ClientDetailScreen({super.key, required this.client});

  final ClientModel client;

  @override
  State<ClientDetailScreen> createState() => _ClientDetailScreenState();
}

class _ClientDetailScreenState extends State<ClientDetailScreen> {
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

  Future<void> _openEditClient(ClientModel client) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => AddClientScreen(client: client)),
    );
  }

  Future<void> _deleteClient(ClientModel client) async {
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

    if (confirmed != true) {
      return;
    }

    await _repository.deleteClient(client.id);
    if (!mounted) {
      return;
    }
    Navigator.pop(context);
  }

  Future<void> _openActionsSheet(ClientModel client) {
    return ActionBottomSheet.show(
      context,
      items: [
        ActionBottomSheetItem(
          icon: Icons.edit_outlined,
          label: 'Edit Client',
          onTap: () => _openEditClient(client),
        ),
        ActionBottomSheetItem(
          icon: Icons.delete_outline_rounded,
          label: 'Delete Client',
          textColor: AppColors.error,
          iconColor: AppColors.error,
          onTap: () => _deleteClient(client),
        ),
      ],
    );
  }

  Future<void> _openSiteSelector({
    required ClientModel client,
    required List<SiteModel> allSites,
    required List<SiteModel> assignedSites,
  }) async {
    final branchSites = allSites
        .where(
          (site) =>
              site.branchId == client.branchId || site.clientId == client.id,
        )
        .toList(growable: false);

    final selectedSites = await SiteSelectorBottomSheet.show(
      context,
      allSites: branchSites,
      initiallySelectedIds: assignedSites
          .map((site) => site.id)
          .toList(growable: false),
    );

    if (selectedSites == null) {
      return;
    }

    await _repository.saveClient(
      client.copyWith(
        siteIds: selectedSites.map((site) => site.id).toList(growable: false),
      ),
    );
  }

  Future<void> _removeAssignedSite({
    required ClientModel client,
    required List<SiteModel> assignedSites,
    required String siteId,
  }) {
    final updatedIds = assignedSites
        .where((site) => site.id != siteId)
        .map((site) => site.id)
        .toList(growable: false);
    return _repository.saveClient(client.copyWith(siteIds: updatedIds));
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
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
              child: Center(
                child: SurfaceIconButton(
                  icon: Icons.more_vert_rounded,
                  size: 40,
                  iconSize: 20,
                  borderRadius: 20,
                  onTap: () => _openActionsSheet(widget.client),
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
        body: StreamBuilder<ClientModel?>(
          stream: _repository.watchClient(widget.client.id),
          builder: (context, clientSnapshot) {
            if (clientSnapshot.connectionState == ConnectionState.waiting &&
                !clientSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final client = clientSnapshot.data;
            if (client == null) {
              return _buildUnavailableState('Client no longer exists.');
            }

            return StreamBuilder<List<SiteModel>>(
              stream: _repository.watchSites(),
              builder: (context, sitesSnapshot) {
                final allSites = sitesSnapshot.data ?? const <SiteModel>[];
                final assignedSites = allSites
                    .where((site) => site.clientId == client.id)
                    .toList(growable: false);
                final filteredSites = _filterSites(assignedSites);

                return StreamBuilder<List<BranchModel>>(
                  stream: _repository.watchBranches(),
                  builder: (context, branchesSnapshot) {
                    final branches =
                        branchesSnapshot.data ?? const <BranchModel>[];
                    final branchName = _branchName(branches, client.branchId);

                    return TabBarView(
                      children: [
                        _buildInfoTab(client, branchName),
                        SiteAssignmentTab(
                          searchController: _searchController,
                          onSearchChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                            });
                          },
                          onAddPressed: () => _openSiteSelector(
                            client: client,
                            allSites: allSites,
                            assignedSites: assignedSites,
                          ),
                          addButtonLabel: 'Add Site',
                          sites: filteredSites,
                          countLabel:
                              '${assignedSites.length} ${assignedSites.length == 1 ? 'site' : 'sites'} assigned',
                          emptyMessage: _searchQuery.trim().isEmpty
                              ? 'No sites assigned to this client yet.'
                              : 'No assigned sites match your search.',
                          onRemoveSite: (siteId) => _removeAssignedSite(
                            client: client,
                            assignedSites: assignedSites,
                            siteId: siteId,
                          ),
                        ),
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

  String _branchName(List<BranchModel> branches, String branchId) {
    for (final branch in branches) {
      if (branch.id == branchId) {
        return branch.name;
      }
    }
    return 'Unassigned Branch';
  }

  Widget _buildInfoTab(ClientModel client, String branchName) {
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
                client.name,
                style: AppTextStyles.headingSmall.copyWith(
                  color: AppColors.neutral900,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                client.email,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.primary700,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                client.phone,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.neutral700,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                branchName,
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
              _buildInfoRow('Name', client.name),
              _buildDivider(),
              _buildInfoRow('Email', client.email),
              _buildDivider(),
              _buildInfoRow('Mobile', client.phone),
              _buildDivider(),
              _buildInfoRow('Branch', branchName),
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
