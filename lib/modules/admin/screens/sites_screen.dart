import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/branch_model.dart';
import '../models/client_model.dart';
import '../models/manager_model.dart';
import '../models/site_model.dart';
import '../services/firestore_admin_repository.dart';
import '../widgets/admin_search_bar.dart';
import '../widgets/site_card.dart';
import 'add_site_screen.dart';
import 'site_detail_screen.dart';

class SitesScreen extends StatefulWidget {
  const SitesScreen({super.key});

  @override
  State<SitesScreen> createState() => _SitesScreenState();
}

class _SitesScreenState extends State<SitesScreen> {
  final FirestoreAdminRepository _repository = FirestoreAdminRepository.instance;
  String _searchQuery = '';

  Future<void> _openAddSite() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => const AddSiteScreen()),
    );
  }

  Future<void> _openSiteDetail(SiteModel site) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => SiteDetailScreen(site: site),
      ),
    );
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
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: AdminSearchBar(
                    height: 50,
                    hintText: 'Search sites...',
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _openAddSite,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Add Site'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(118, 50),
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<List<SiteModel>>(
                stream: _repository.watchSites(),
                builder: (context, sitesSnapshot) {
                  if (sitesSnapshot.connectionState == ConnectionState.waiting &&
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
                                      itemCount: sites.length,
                                      separatorBuilder: (_, __) =>
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
    if (query.isEmpty) {
      return sites;
    }

    return sites.where((site) {
      final branchName = _branchName(branches, site.branchId);
      final clientName = _clientName(clients, site.clientId);
      final managerName = _managerName(managers, site.managerId);
      return site.name.toLowerCase().contains(query) ||
          branchName.toLowerCase().contains(query) ||
          clientName.toLowerCase().contains(query) ||
          managerName.toLowerCase().contains(query) ||
          site.location.toLowerCase().contains(query);
    }).toList(growable: false);
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
        style: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.neutral500,
        ),
      ),
    );
  }
}
