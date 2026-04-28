import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../widgets/action_bottom_sheet.dart';
import '../../../widgets/surface_icon_button.dart';
import '../models/branch_model.dart';
import '../models/client_model.dart';
import '../models/manager_model.dart';
import '../models/site_model.dart';
import '../models/visit_model.dart';
import '../services/firestore_admin_repository.dart';
import '../widgets/admin_search_bar.dart';
import '../widgets/manager_card.dart';
import '../widgets/visit_table.dart';
import 'add_site_screen.dart';

class SiteDetailScreen extends StatefulWidget {
  const SiteDetailScreen({super.key, required this.site});

  final SiteModel site;

  @override
  State<SiteDetailScreen> createState() => _SiteDetailScreenState();
}

class _SiteDetailScreenState extends State<SiteDetailScreen> {
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

  Future<void> _openEditSite(SiteModel site) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => AddSiteScreen(site: site)),
    );
  }

  Future<void> _deleteSite(SiteModel site) async {
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

    if (confirmed != true) {
      return;
    }

    await _repository.deleteSite(site.id);
    if (!mounted) {
      return;
    }
    Navigator.pop(context);
  }

  Future<void> _openActionsSheet(SiteModel site) {
    return ActionBottomSheet.show(
      context,
      items: [
        ActionBottomSheetItem(
          icon: Icons.edit_outlined,
          label: 'Edit Site',
          onTap: () => _openEditSite(site),
        ),
        ActionBottomSheetItem(
          icon: Icons.delete_outline_rounded,
          label: 'Delete Site',
          textColor: AppColors.error,
          iconColor: AppColors.error,
          onTap: () => _deleteSite(site),
        ),
      ],
    );
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
            'Site Details',
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
                  onTap: () => _openActionsSheet(widget.site),
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
                    Tab(text: 'Visit History'),
                  ],
                ),
              ),
            ),
          ),
        ),
        body: StreamBuilder<SiteModel?>(
          stream: _repository.watchSite(widget.site.id),
          builder: (context, siteSnapshot) {
            if (siteSnapshot.connectionState == ConnectionState.waiting &&
                !siteSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final site = siteSnapshot.data;
            if (site == null) {
              return _buildUnavailableState('Site no longer exists.');
            }

            return StreamBuilder<List<ClientModel>>(
              stream: _repository.watchClients(),
              builder: (context, clientsSnapshot) {
                final clients = clientsSnapshot.data ?? const <ClientModel>[];
                return StreamBuilder<List<BranchModel>>(
                  stream: _repository.watchBranches(),
                  builder: (context, branchesSnapshot) {
                    final branches =
                        branchesSnapshot.data ?? const <BranchModel>[];
                    return StreamBuilder<List<ManagerModel>>(
                      stream: _repository.watchManagers(),
                      builder: (context, managersSnapshot) {
                        final managers =
                            managersSnapshot.data ?? const <ManagerModel>[];
                        final manager = _managerById(managers, site.managerId);
                        final clientName = _clientName(clients, site.clientId);
                        final branchName = _branchName(branches, site.branchId);

                        return StreamBuilder<List<VisitModel>>(
                          stream: _repository.watchSiteVisits(site.id),
                          builder: (context, visitsSnapshot) {
                            final visits = _filterVisits(
                              visitsSnapshot.data ?? const [],
                            );

                            return TabBarView(
                              children: [
                                _buildInfoTab(
                                  site: site,
                                  clientName: clientName,
                                  branchName: branchName,
                                  manager: manager,
                                ),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    20,
                                    16,
                                    20,
                                    32,
                                  ),
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
                            );
                          },
                        );
                      },
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

  List<VisitModel> _filterVisits(List<VisitModel> visits) {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) {
      return visits;
    }

    return visits
        .where((visit) {
          return visit.managerName.toLowerCase().contains(query) ||
              visit.date.toLowerCase().contains(query) ||
              visit.day.toLowerCase().contains(query) ||
              visit.time.toLowerCase().contains(query) ||
              visit.status.toLowerCase().contains(query) ||
              visit.notes.toLowerCase().contains(query);
        })
        .toList(growable: false);
  }

  String _clientName(List<ClientModel> clients, String clientId) {
    for (final client in clients) {
      if (client.id == clientId) {
        return client.name;
      }
    }
    return 'Unassigned Client';
  }

  String _branchName(List<BranchModel> branches, String branchId) {
    for (final branch in branches) {
      if (branch.id == branchId) {
        return branch.name;
      }
    }
    return 'Unassigned Branch';
  }

  ManagerModel? _managerById(List<ManagerModel> managers, String managerId) {
    for (final manager in managers) {
      if (manager.id == managerId) {
        return manager;
      }
    }
    return null;
  }

  Widget _buildInfoTab({
    required SiteModel site,
    required String clientName,
    required String branchName,
    required ManagerModel? manager,
  }) {
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
                site.name,
                style: AppTextStyles.headingSmall.copyWith(
                  color: AppColors.neutral900,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                clientName,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.primary700,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                branchName,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.neutral700,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                site.address.trim().isEmpty ? site.location : site.address,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.neutral700,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                site.createdDate.isEmpty ? '' : 'Created ${site.createdDate}',
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
          style: AppTextStyles.title.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        if (manager != null)
          ManagerCard(manager: manager)
        else
          _buildFallbackCard('No manager assigned'),
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
              _buildInfoRow('Site Name', site.name),
              _buildDivider(),
              _buildInfoRow('Client', clientName),
              _buildDivider(),
              _buildInfoRow('Branch', branchName),
              _buildDivider(),
              _buildInfoRow(
                'Address',
                site.address.trim().isEmpty ? site.location : site.address,
              ),
              _buildDivider(),
              _buildInfoRow(
                'Building / Floor',
                site.buildingFloor.trim().isEmpty
                    ? 'Not provided'
                    : site.buildingFloor,
              ),
              _buildDivider(),
              _buildInfoRow(
                'Description',
                site.description.trim().isEmpty
                    ? 'No description added'
                    : site.description,
              ),
              _buildDivider(),
              _buildInfoRow('Created Date', site.createdDate),
              _buildDivider(),
              _buildInfoRow('Last Updated', site.lastUpdated),
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
        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.neutral500),
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
    return const Divider(height: 1, thickness: 1, color: AppColors.neutral200);
  }

  Widget _buildVisitsEmptyState() {
    return Center(
      child: Text(
        'No visits available',
        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.neutral500),
      ),
    );
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
