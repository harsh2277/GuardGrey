import 'package:flutter/material.dart';
import 'package:guardgrey/core/theme/app_colors.dart';
import 'package:guardgrey/core/theme/app_text_styles.dart';
import 'package:guardgrey/core/utils/filter_resettable.dart';
import 'package:guardgrey/core/widgets/admin_search_bar.dart';
import 'package:guardgrey/core/widgets/list_filter_bottom_sheet.dart';
import 'package:guardgrey/core/widgets/primary_floating_add_button.dart';
import 'package:guardgrey/core/widgets/surface_icon_button.dart';
import 'package:guardgrey/modules/branches/models/branch_model.dart';
import 'package:guardgrey/modules/branches/widgets/branch_card.dart';
import 'package:guardgrey/modules/clients/models/client_model.dart';
import 'package:guardgrey/modules/sites/models/site_model.dart';
import 'package:guardgrey/services/firebase/firestore_admin_repository.dart';
import 'add_branch_screen.dart';
import 'branch_detail_screen.dart';

class BranchesScreen extends StatefulWidget {
  const BranchesScreen({super.key});

  @override
  State<BranchesScreen> createState() => _BranchesScreenState();
}

class _BranchesScreenState extends State<BranchesScreen>
    implements FilterResettable {
  final FirestoreAdminRepository _repository =
      FirestoreAdminRepository.instance;
  late final TextEditingController _searchController;
  String _searchQuery = '';
  String? _selectedClientName;

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

  Future<void> _openAddBranch() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => const AddBranchScreen()),
    );
    if (mounted) {
      resetFilters();
    }
  }

  Future<void> _openEditBranch(BranchModel branch) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => AddBranchScreen(branch: branch)),
    );
    if (mounted) {
      resetFilters();
    }
  }

  Future<void> _openBranchDetails(BranchModel branch) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => BranchDetailScreen(branch: branch)),
    );
    if (mounted) {
      resetFilters();
    }
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
            'Delete Branch',
            style: AppTextStyles.title.copyWith(fontWeight: FontWeight.w700),
          ),
          content: Text(
            'Are you sure you want to delete ${branch.name}?',
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

    if (confirmed == true) {
      await _repository.deleteBranch(branch.id);
    }
  }

  Future<void> _openFilters(List<String> clientNames) async {
    final filters = await ListFilterBottomSheet.show(
      context,
      title: 'Filter Branches',
      searchHint: 'Refine by branch, city, address...',
      initialSearchQuery: _searchQuery,
      extraDropdowns: [
        ListFilterDropdownField(
          key: 'clientName',
          label: 'Client Name',
          options: clientNames,
          initialValue: _selectedClientName,
        ),
      ],
    );

    if (filters == null) {
      return;
    }

    _searchController.text = filters.searchQuery;
    setState(() {
      _searchQuery = filters.searchQuery;
      _selectedClientName = filters.extraSelections['clientName'];
    });
  }

  @override
  void resetFilters() {
    if (_searchQuery.isEmpty &&
        _selectedClientName == null &&
        _searchController.text.isEmpty) {
      return;
    }

    setState(() {
      _searchQuery = '';
      _selectedClientName = null;
      _searchController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          'Branches',
          style: AppTextStyles.title.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: PrimaryFloatingAddButton(
        heroTag: 'branches-add-fab',
        tooltip: 'Add Branch',
        onPressed: _openAddBranch,
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
                    hintText: 'Search by branch location...',
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),
                FutureBuilder<List<String>>(
                  future: _branchClientNames(),
                  builder: (context, snapshot) {
                    final clientNames = snapshot.data ?? const <String>[];
                    return Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: SurfaceIconButton(
                        icon: Icons.tune_rounded,
                        onTap: () => _openFilters(clientNames),
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
              child: StreamBuilder<List<BranchModel>>(
                stream: _repository.watchBranches(),
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
                      return StreamBuilder<List<ClientModel>>(
                        stream: _repository.watchClients(),
                        builder: (context, clientsSnapshot) {
                          final clients =
                              clientsSnapshot.data ?? const <ClientModel>[];
                          final branches = _filterBranches(
                            snapshot.data ?? const [],
                            sites: sites,
                            clients: clients,
                          );
                          return branches.isEmpty
                              ? _buildEmptyState()
                              : ListView.separated(
                                  padding: const EdgeInsets.only(bottom: 120),
                                  itemCount: branches.length,
                                  separatorBuilder: (context, index) =>
                                      const SizedBox(height: 12),
                                  itemBuilder: (context, index) {
                                    final branch = branches[index];
                                    return BranchCard(
                                      branch: branch,
                                      onTap: () => _openBranchDetails(branch),
                                      onEdit: () => _openEditBranch(branch),
                                      onDelete: () => _deleteBranch(branch),
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

  List<BranchModel> _filterBranches(
    List<BranchModel> branches, {
    required List<SiteModel> sites,
    required List<ClientModel> clients,
  }) {
    if (_searchQuery.trim().isEmpty && _selectedClientName == null) {
      return branches;
    }

    final query = _searchQuery.toLowerCase();
    return branches
        .where((branch) {
          final branchClientNames = _branchClientNamesFor(
            branch.id,
            sites: sites,
            clients: clients,
          );
          final matchesQuery =
              branch.name.toLowerCase().contains(query) ||
              branch.city.toLowerCase().contains(query) ||
              branch.address.toLowerCase().contains(query) ||
              branchClientNames.any(
                (clientName) => clientName.toLowerCase().contains(query),
              );
          final matchesClient =
              _selectedClientName == null ||
              branchClientNames.contains(_selectedClientName);
          return matchesQuery && matchesClient;
        })
        .toList(growable: false);
  }

  Future<List<String>> _branchClientNames() async {
    final sites = await _repository.fetchSites();
    final clients = await _repository.fetchClients();
    final names = <String>{};
    for (final site in sites) {
      for (final client in clients) {
        if (site.clientId == client.id) {
          names.add(client.name);
        }
      }
    }
    final sortedNames = names.toList()..sort();
    return sortedNames;
  }

  List<String> _branchClientNamesFor(
    String branchId, {
    required List<SiteModel> sites,
    required List<ClientModel> clients,
  }) {
    final clientById = {for (final client in clients) client.id: client.name};
    return sites
        .where((site) => site.branchId == branchId)
        .map((site) => clientById[site.clientId] ?? '')
        .where((name) => name.trim().isNotEmpty)
        .toSet()
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
              Icons.account_tree_outlined,
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
            'Branch records will appear here once data is available.',
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
        'Unable to load branches.',
        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.neutral500),
      ),
    );
  }
}
