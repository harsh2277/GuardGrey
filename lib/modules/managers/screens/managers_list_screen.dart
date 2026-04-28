import 'package:flutter/material.dart';

import 'package:guardgrey/core/theme/app_colors.dart';
import 'package:guardgrey/core/theme/app_text_styles.dart';
import 'package:guardgrey/core/utils/filter_resettable.dart';
import 'package:guardgrey/core/widgets/admin_search_bar.dart';
import 'package:guardgrey/core/widgets/list_filter_bottom_sheet.dart';
import 'package:guardgrey/core/widgets/primary_floating_add_button.dart';
import 'package:guardgrey/core/widgets/surface_icon_button.dart';
import 'package:guardgrey/modules/branches/models/branch_model.dart';
import 'package:guardgrey/modules/managers/models/manager_model.dart';
import 'package:guardgrey/modules/sites/models/site_model.dart';
import 'package:guardgrey/services/firebase/firestore_admin_repository.dart';
import 'add_manager_screen.dart';
import 'manager_detail_screen.dart';

class ManagersListScreen extends StatefulWidget {
  const ManagersListScreen({super.key});

  @override
  State<ManagersListScreen> createState() => _ManagersListScreenState();
}

class _ManagersListScreenState extends State<ManagersListScreen>
    implements FilterResettable {
  final FirestoreAdminRepository _repository =
      FirestoreAdminRepository.instance;
  late final TextEditingController _searchController;
  String _searchQuery = '';
  String? _selectedSiteName;
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

  Future<void> _openAddManager() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => const AddManagerScreen()),
    );
    if (mounted) {
      resetFilters();
    }
  }

  Future<void> _openManagerDetail(ManagerModel manager) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => ManagerDetailScreen(manager: manager)),
    );
    if (mounted) {
      resetFilters();
    }
  }

  Future<void> _openFilters({
    required List<SiteModel> sites,
    required List<BranchModel> branches,
  }) async {
    final filters = await ListFilterBottomSheet.show(
      context,
      title: 'Filter Managers',
      searchHint: 'Refine by manager, email, phone...',
      initialSearchQuery: _searchQuery,
      extraDropdowns: [
        ListFilterDropdownField(
          key: 'siteName',
          label: 'Site',
          options: sites.map((site) => site.name).toSet().toList()..sort(),
          initialValue: _selectedSiteName,
        ),
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
      _selectedSiteName = filters.extraSelections['siteName'];
      _selectedBranchName = filters.extraSelections['branchName'];
    });
  }

  @override
  void resetFilters() {
    if (_searchQuery.isEmpty &&
        _selectedSiteName == null &&
        _selectedBranchName == null &&
        _searchController.text.isEmpty) {
      return;
    }

    setState(() {
      _searchQuery = '';
      _selectedSiteName = null;
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
          'Managers',
          style: AppTextStyles.title.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: PrimaryFloatingAddButton(
        heroTag: 'managers-add-fab',
        tooltip: 'Add Manager',
        onPressed: _openAddManager,
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
                    hintText: 'Search managers...',
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),
                StreamBuilder<List<SiteModel>>(
                  stream: _repository.watchSites(),
                  builder: (context, sitesSnapshot) {
                    final sites = sitesSnapshot.data ?? const <SiteModel>[];
                    return StreamBuilder<List<BranchModel>>(
                      stream: _repository.watchBranches(),
                      builder: (context, branchesSnapshot) {
                        final branches =
                            branchesSnapshot.data ?? const <BranchModel>[];
                        return Padding(
                          padding: const EdgeInsets.only(left: 12),
                          child: SurfaceIconButton(
                            icon: Icons.tune_rounded,
                            onTap: () =>
                                _openFilters(sites: sites, branches: branches),
                            backgroundColor: AppColors.primary600,
                            borderColor: AppColors.primary600,
                            iconColor: Colors.white,
                            borderRadius: 25,
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<List<ManagerModel>>(
                stream: _repository.watchManagers(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return _buildErrorState();
                  }

                  return StreamBuilder<List<SiteModel>>(
                    stream: _repository.watchSites(),
                    builder: (context, sitesSnapshot) {
                      final sites = sitesSnapshot.data ?? const <SiteModel>[];
                      return StreamBuilder<List<BranchModel>>(
                        stream: _repository.watchBranches(),
                        builder: (context, branchesSnapshot) {
                          final branches =
                              branchesSnapshot.data ?? const <BranchModel>[];
                          final managers = _filterManagers(
                            snapshot.data ?? const [],
                            sites: sites,
                            branches: branches,
                          );
                          return managers.isEmpty
                              ? _buildEmptyState()
                              : ListView.separated(
                                  padding: const EdgeInsets.only(bottom: 120),
                                  itemCount: managers.length,
                                  separatorBuilder: (context, index) =>
                                      const SizedBox(height: 12),
                                  itemBuilder: (context, index) {
                                    final manager = managers[index];
                                    final assignedSiteNames = sites
                                        .where(
                                          (site) =>
                                              site.managerId == manager.id ||
                                              manager.siteIds.contains(site.id),
                                        )
                                        .map((site) => site.name)
                                        .toList(growable: false);
                                    return Material(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(18),
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(18),
                                        onTap: () =>
                                            _openManagerDetail(manager),
                                        child: Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              18,
                                            ),
                                            border: Border.all(
                                              color: AppColors.neutral200,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              CircleAvatar(
                                                radius: 24,
                                                backgroundColor:
                                                    AppColors.primary50,
                                                child: Text(
                                                  manager.name.substring(0, 1),
                                                  style: AppTextStyles.bodyLarge
                                                      .copyWith(
                                                        color: AppColors
                                                            .primary600,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                ),
                                              ),
                                              const SizedBox(width: 14),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      manager.name,
                                                      style: AppTextStyles
                                                          .bodyLarge
                                                          .copyWith(
                                                            fontWeight:
                                                                FontWeight.w700,
                                                            color: AppColors
                                                                .neutral900,
                                                          ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      assignedSiteNames.isEmpty
                                                          ? manager.email
                                                          : assignedSiteNames
                                                                .first,
                                                      style: AppTextStyles
                                                          .bodyMedium
                                                          .copyWith(
                                                            color: AppColors
                                                                .neutral600,
                                                          ),
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      manager.phone,
                                                      style: AppTextStyles
                                                          .bodySmall
                                                          .copyWith(
                                                            color: AppColors
                                                                .neutral500,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const Icon(
                                                Icons.chevron_right_rounded,
                                                color: AppColors.neutral400,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
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

  List<ManagerModel> _filterManagers(
    List<ManagerModel> managers, {
    required List<SiteModel> sites,
    required List<BranchModel> branches,
  }) {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty &&
        _selectedSiteName == null &&
        _selectedBranchName == null) {
      return managers;
    }

    return managers
        .where((manager) {
          final assignedSites = sites.where(
            (site) =>
                site.managerId == manager.id ||
                manager.siteIds.contains(site.id),
          );
          final assignedSiteNames = assignedSites
              .map((site) => site.name)
              .toSet()
              .toList();
          final branchById = {
            for (final branch in branches) branch.id: branch.name,
          };
          final assignedBranchNames = assignedSites
              .map((site) => branchById[site.branchId] ?? '')
              .where((branchName) => branchName.isNotEmpty)
              .toSet();
          final matchesQuery =
              manager.name.toLowerCase().contains(query) ||
              manager.email.toLowerCase().contains(query) ||
              manager.phone.toLowerCase().contains(query) ||
              assignedSiteNames.any(
                (siteName) => siteName.toLowerCase().contains(query),
              );
          final matchesSite =
              _selectedSiteName == null ||
              assignedSiteNames.contains(_selectedSiteName);
          final matchesBranch =
              _selectedBranchName == null ||
              assignedBranchNames.contains(_selectedBranchName);
          return matchesQuery && matchesSite && matchesBranch;
        })
        .toList(growable: false);
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
              Icons.groups_outlined,
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
            'Manager profiles will appear here once data is available.',
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
        'Unable to load managers.',
        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.neutral500),
      ),
    );
  }
}
