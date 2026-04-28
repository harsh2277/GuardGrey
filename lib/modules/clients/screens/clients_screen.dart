import 'package:flutter/material.dart';

import 'package:guardgrey/core/theme/app_colors.dart';
import 'package:guardgrey/core/theme/app_text_styles.dart';
import 'package:guardgrey/core/utils/filter_resettable.dart';
import 'package:guardgrey/core/widgets/admin_search_bar.dart';
import 'package:guardgrey/core/widgets/list_filter_bottom_sheet.dart';
import 'package:guardgrey/core/widgets/primary_floating_add_button.dart';
import 'package:guardgrey/core/widgets/surface_icon_button.dart';
import 'package:guardgrey/modules/branches/models/branch_model.dart';
import 'package:guardgrey/modules/clients/models/client_model.dart';
import 'package:guardgrey/modules/sites/models/site_model.dart';
import 'package:guardgrey/services/firebase/firestore_admin_repository.dart';
import 'add_client_screen.dart';
import 'client_detail_screen.dart';

class ClientsScreen extends StatefulWidget {
  const ClientsScreen({super.key});

  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen>
    implements FilterResettable {
  final FirestoreAdminRepository _repository =
      FirestoreAdminRepository.instance;
  late final TextEditingController _searchController;
  String _searchQuery = '';
  String? _selectedSiteName;

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

  Future<void> _openAddClient() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => const AddClientScreen()),
    );
    if (mounted) {
      resetFilters();
    }
  }

  Future<void> _openClientDetail(ClientModel client) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => ClientDetailScreen(client: client)),
    );
    if (mounted) {
      resetFilters();
    }
  }

  Future<void> _openFilters(List<SiteModel> sites) async {
    final filters = await ListFilterBottomSheet.show(
      context,
      title: 'Filter Clients',
      searchHint: 'Refine by client, branch, phone...',
      initialSearchQuery: _searchQuery,
      extraDropdowns: [
        ListFilterDropdownField(
          key: 'siteName',
          label: 'Site Name',
          options: sites.map((site) => site.name).toSet().toList()..sort(),
          initialValue: _selectedSiteName,
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
    });
  }

  @override
  void resetFilters() {
    if (_searchQuery.isEmpty &&
        _selectedSiteName == null &&
        _searchController.text.isEmpty) {
      return;
    }

    setState(() {
      _searchQuery = '';
      _selectedSiteName = null;
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
          'Clients',
          style: AppTextStyles.title.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: PrimaryFloatingAddButton(
        heroTag: 'clients-add-fab',
        tooltip: 'Add Client',
        onPressed: _openAddClient,
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
                    hintText: 'Search clients...',
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
                    return Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: SurfaceIconButton(
                        icon: Icons.tune_rounded,
                        onTap: () => _openFilters(sites),
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
              child: StreamBuilder<List<ClientModel>>(
                stream: _repository.watchClients(),
                builder: (context, clientsSnapshot) {
                  if (clientsSnapshot.connectionState ==
                          ConnectionState.waiting &&
                      !clientsSnapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (clientsSnapshot.hasError) {
                    return _buildErrorState();
                  }

                  return StreamBuilder<List<SiteModel>>(
                    stream: _repository.watchSites(),
                    builder: (context, sitesSnapshot) {
                      final sites = sitesSnapshot.data ?? const [];
                      return StreamBuilder<List<BranchModel>>(
                        stream: _repository.watchBranches(),
                        builder: (context, branchesSnapshot) {
                          final branches = branchesSnapshot.data ?? const [];
                          final clients = _filterClients(
                            clientsSnapshot.data ?? const [],
                            branches: branches,
                            sites: sites,
                          );

                          return clients.isEmpty
                              ? _buildEmptyState()
                              : ListView.separated(
                                  padding: const EdgeInsets.only(bottom: 120),
                                  itemCount: clients.length,
                                  separatorBuilder: (context, index) =>
                                      const SizedBox(height: 12),
                                  itemBuilder: (context, index) {
                                    final client = clients[index];
                                    final assignedSites = sites
                                        .where(
                                          (site) => site.clientId == client.id,
                                        )
                                        .toList(growable: false);
                                    final branchName = _branchName(
                                      branches,
                                      client.branchId,
                                    );

                                    return Material(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(18),
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(18),
                                        onTap: () => _openClientDetail(client),
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
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Container(
                                                    width: 44,
                                                    height: 44,
                                                    decoration: BoxDecoration(
                                                      color:
                                                          AppColors.primary50,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            14,
                                                          ),
                                                    ),
                                                    child: const Icon(
                                                      Icons.business_outlined,
                                                      color:
                                                          AppColors.primary600,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: Text(
                                                      client.name,
                                                      style: AppTextStyles
                                                          .bodyLarge
                                                          .copyWith(
                                                            fontWeight:
                                                                FontWeight.w700,
                                                            color: AppColors
                                                                .neutral900,
                                                          ),
                                                    ),
                                                  ),
                                                  const Icon(
                                                    Icons.chevron_right_rounded,
                                                    color: AppColors.neutral400,
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 12),
                                              Text(
                                                client.email,
                                                style: AppTextStyles.bodyMedium
                                                    .copyWith(
                                                      color:
                                                          AppColors.neutral600,
                                                    ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                client.phone,
                                                style: AppTextStyles.bodySmall
                                                    .copyWith(
                                                      color:
                                                          AppColors.neutral500,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                              ),
                                              const SizedBox(height: 10),
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      branchName,
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: AppTextStyles
                                                          .bodySmall
                                                          .copyWith(
                                                            color: AppColors
                                                                .neutral500,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Text(
                                                    '${assignedSites.length} ${assignedSites.length == 1 ? 'Site' : 'Sites'}',
                                                    style: AppTextStyles
                                                        .bodySmall
                                                        .copyWith(
                                                          color: AppColors
                                                              .primary600,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                        ),
                                                  ),
                                                ],
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

  List<ClientModel> _filterClients(
    List<ClientModel> clients, {
    required List<BranchModel> branches,
    required List<SiteModel> sites,
  }) {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty && _selectedSiteName == null) {
      return clients;
    }

    return clients
        .where((client) {
          final branchName = _branchName(branches, client.branchId);
          final assignedSiteNames = sites
              .where((site) => site.clientId == client.id)
              .map((site) => site.name)
              .toList(growable: false);
          final matchesQuery =
              client.name.toLowerCase().contains(query) ||
              client.email.toLowerCase().contains(query) ||
              client.phone.toLowerCase().contains(query) ||
              branchName.toLowerCase().contains(query) ||
              assignedSiteNames.any(
                (siteName) => siteName.toLowerCase().contains(query),
              );
          final matchesSite =
              _selectedSiteName == null ||
              assignedSiteNames.contains(_selectedSiteName);
          return matchesQuery && matchesSite;
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
              Icons.business_outlined,
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
            'Client records will appear here once data is available.',
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
        'Unable to load clients.',
        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.neutral500),
      ),
    );
  }
}
