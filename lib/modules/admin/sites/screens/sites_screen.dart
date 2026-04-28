import 'package:flutter/material.dart';

import 'package:guardgrey/core/theme/app_colors.dart';
import 'package:guardgrey/core/theme/app_text_styles.dart';
import 'package:guardgrey/core/utils/filter_resettable.dart';
import 'package:guardgrey/core/widgets/admin_search_bar.dart';
import 'package:guardgrey/core/widgets/list_filter_bottom_sheet.dart';
import 'package:guardgrey/core/widgets/primary_floating_add_button.dart';
import 'package:guardgrey/core/widgets/surface_icon_button.dart';
import 'package:guardgrey/data/models/branch_model.dart';
import 'package:guardgrey/data/models/client_model.dart';
import 'package:guardgrey/data/models/manager_model.dart';
import 'package:guardgrey/data/models/site_model.dart';
import 'package:guardgrey/data/repositories/guard_grey_repository.dart';
import 'package:guardgrey/modules/admin/sites/widgets/site_card.dart';
import 'add_site_screen.dart';
import 'site_detail_screen.dart';

class SitesScreen extends StatefulWidget {
  const SitesScreen({super.key});

  @override
  State<SitesScreen> createState() => _SitesScreenState();
}

class _SitesScreenState extends State<SitesScreen> implements FilterResettable {
  final GuardGreyRepository _repository = GuardGreyRepository.instance;
  late final TextEditingController _searchController;
  String _searchQuery = '';
  String? _selectedBranchName;

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

  Future<void> _openAddSite() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => const AddSiteScreen()),
    );
    if (mounted) {
      resetFilters();
    }
  }

  Future<void> _openSiteDetail(SiteModel site) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => SiteDetailScreen(site: site)),
    );
    if (mounted) {
      resetFilters();
    }
  }

  Future<void> _openFilters(List<BranchModel> branches) async {
    final filters = await ListFilterBottomSheet.show(
      context,
      title: 'Filter Sites',
      searchHint: 'Refine by site, branch, manager...',
      initialSearchQuery: _searchQuery,
      extraDropdowns: [
        ListFilterDropdownField(
          key: 'branchName',
          label: 'Branch',
          options: branches.map((branch) => branch.name).toSet().toList()
            ..sort(),
          initialValue: _selectedBranchName,
        ),
      ],
    );

    if (filters == null) {
      return;
    }

    _searchController.text = filters.searchQuery;
    setState(() {
      _searchQuery = filters.searchQuery;
      _selectedBranchName = filters.extraSelections['branchName'];
    });
  }

  @override
  void resetFilters() {
    if (_searchQuery.isEmpty &&
        _selectedBranchName == null &&
        _searchController.text.isEmpty) {
      return;
    }

    setState(() {
      _searchQuery = '';
      _selectedBranchName = null;
      _searchController.clear();
    });
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
          'Sites',
          style: AppTextStyles.title.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: PrimaryFloatingAddButton(
        heroTag: 'sites-add-fab',
        tooltip: 'Add Site',
        onPressed: _openAddSite,
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: AdminSearchBar(
                    controller: _searchController,
                    height: 50,
                    hintText: 'Search sites...',
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),
                StreamBuilder<List<BranchModel>>(
                  stream: _repository.watchBranches(),
                  builder: (context, branchesSnapshot) {
                    final branches =
                        branchesSnapshot.data ?? const <BranchModel>[];
                    return Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: SurfaceIconButton(
                        icon: Icons.tune_rounded,
                        onTap: () => _openFilters(branches),
                        backgroundColor: AppColors.primary600,
                        borderColor: AppColors.primary600,
                        iconColor: Colors.white,
                        borderRadius: 25,
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<List<SiteModel>>(
                stream: _repository.watchSites(),
                builder: (context, sitesSnapshot) {
                  if (sitesSnapshot.connectionState ==
                          ConnectionState.waiting &&
                      !sitesSnapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (sitesSnapshot.hasError) {
                    return _buildErrorState();
                  }

                  return StreamBuilder<List<BranchModel>>(
                    stream: _repository.watchBranches(),
                    builder: (context, branchesSnapshot) {
                      final branches = branchesSnapshot.data ?? const [];
                      return StreamBuilder<List<ClientModel>>(
                        stream: _repository.watchClients(),
                        builder: (context, clientsSnapshot) {
                          final clients = clientsSnapshot.data ?? const [];
                          return StreamBuilder<List<ManagerModel>>(
                            stream: _repository.watchManagers(),
                            builder: (context, managersSnapshot) {
                              final managers =
                                  managersSnapshot.data ?? const [];
                              final sites = _filterSites(
                                sitesSnapshot.data ?? const [],
                                branches: branches,
                                clients: clients,
                                managers: managers,
                              );

                              return sites.isEmpty
                                  ? _buildEmptyState()
                                  : ListView.separated(
                                      padding: const EdgeInsets.only(
                                        bottom: 120,
                                      ),
                                      itemCount: sites.length,
                                      separatorBuilder: (context, index) =>
                                          const SizedBox(height: 12),
                                      itemBuilder: (context, index) {
                                        final site = sites[index];
                                        return SiteCard(
                                          site: site,
                                          branchName: _branchName(
                                            branches,
                                            site.branchId,
                                          ),
                                          onTap: () => _openSiteDetail(site),
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
          ],
        ),
      ),
    );
  }

  List<SiteModel> _filterSites(
    List<SiteModel> sites, {
    required List<BranchModel> branches,
    required List<ClientModel> clients,
    required List<ManagerModel> managers,
  }) {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty && _selectedBranchName == null) {
      return sites;
    }

    return sites
        .where((site) {
          final branchName = _branchName(branches, site.branchId);
          final clientName = _clientName(clients, site.clientId);
          final managerName = _managerName(managers, site.managerId);
          final matchesQuery =
              site.name.toLowerCase().contains(query) ||
              branchName.toLowerCase().contains(query) ||
              clientName.toLowerCase().contains(query) ||
              managerName.toLowerCase().contains(query) ||
              site.location.toLowerCase().contains(query);
          final matchesBranch =
              _selectedBranchName == null || branchName == _selectedBranchName;
          return matchesQuery && matchesBranch;
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

  String _clientName(List<ClientModel> clients, String clientId) {
    for (final client in clients) {
      if (client.id == clientId) {
        return client.name;
      }
    }
    return 'Unassigned Client';
  }

  String _managerName(List<ManagerModel> managers, String managerId) {
    for (final manager in managers) {
      if (manager.id == managerId) {
        return manager.name;
      }
    }
    return '';
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.primary50,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.location_city_outlined,
              color: AppColors.primary600,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No data available',
            style: AppTextStyles.title.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'Site records will appear here once data is available.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.neutral500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Text(
        'Unable to load sites.',
        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.neutral500),
      ),
    );
  }
}
