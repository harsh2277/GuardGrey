import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../modules/admin/data/admin_dummy_data.dart';
import '../../modules/admin/models/client_model.dart';
import '../../modules/admin/models/site_model.dart';
import '../../modules/admin/widgets/admin_search_bar.dart';
import 'add_client_screen.dart';
import 'client_detail_screen.dart';

class ClientsScreen extends StatefulWidget {
  const ClientsScreen({super.key});

  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  late final List<ClientModel> _clients;
  late List<SiteModel> _sites;
  String _searchQuery = '';

  List<ClientModel> get _filteredClients {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) {
      return _clients;
    }

    return _clients.where((client) {
      final branchName = AdminDummyData.getBranchName(client.branchId);
      return client.name.toLowerCase().contains(query) ||
          client.email.toLowerCase().contains(query) ||
          client.phone.toLowerCase().contains(query) ||
          branchName.toLowerCase().contains(query);
    }).toList(growable: false);
  }

  @override
  void initState() {
    super.initState();
    _clients = AdminDummyData.clients.toList(growable: true);
    _sites = AdminDummyData.sites.toList(growable: true);
  }

  Future<void> _openAddClient() async {
    final result = await Navigator.push<ClientEditorResult>(
      context,
      MaterialPageRoute(
        builder: (_) => AddClientScreen(
          allSites: _sites,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _clients.insert(0, result.client);
        _applyClientSiteAssignments(
          clientId: result.client.id,
          selectedSiteIds: result.siteIds,
        );
      });
    }
  }

  Future<void> _openClientDetail(ClientModel client) async {
    final result = await Navigator.push<ClientDetailResult>(
      context,
      MaterialPageRoute(
        builder: (_) => ClientDetailScreen(
          client: client,
          allSites: _sites,
        ),
      ),
    );

    if (result == null) return;

    if (result.deleted) {
      setState(() {
        _clients.removeWhere((item) => item.id == client.id);
        _applyClientSiteAssignments(
          clientId: client.id,
          selectedSiteIds: const <String>[],
        );
      });
      return;
    }

    if (result.client != null) {
      setState(() {
        final index = _clients.indexWhere((item) => item.id == client.id);
        if (index != -1) {
          _clients[index] = result.client!;
        }
        _applyClientSiteAssignments(
          clientId: client.id,
          selectedSiteIds: result.siteIds,
        );
      });
    }
  }

  void _applyClientSiteAssignments({
    required String clientId,
    required List<String> selectedSiteIds,
  }) {
    final selectedIdSet = selectedSiteIds.toSet();
    _sites = _sites.map((site) {
      if (selectedIdSet.contains(site.id)) {
        return site.copyWith(clientId: clientId);
      }

      if (site.clientId == clientId) {
        return site.copyWith(clientId: '');
      }

      return site;
    }).toList(growable: true);
  }

  @override
  Widget build(BuildContext context) {
    final clients = _filteredClients;

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
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: AdminSearchBar(
                    height: 50,
                    hintText: 'Search clients...',
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _openAddClient,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Add Client'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(126, 50),
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
              child: clients.isEmpty
                  ? _buildEmptyState()
                  : ListView.separated(
                      itemCount: clients.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final client = clients[index];
                        final List<SiteModel> sites = _sites
                            .where((site) => site.clientId == client.id)
                            .toList(growable: false);
                        final branchName =
                            AdminDummyData.getBranchName(client.branchId);

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
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: AppColors.neutral200),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: AppColors.primary50,
                                          borderRadius:
                                              BorderRadius.circular(14),
                                        ),
                                        child: const Icon(
                                          Icons.business_outlined,
                                          color: AppColors.primary600,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          client.name,
                                          style:
                                              AppTextStyles.bodyLarge.copyWith(
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.neutral900,
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
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: AppColors.neutral600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    client.phone,
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.neutral500,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          branchName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style:
                                              AppTextStyles.bodySmall.copyWith(
                                            color: AppColors.neutral500,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        '${sites.length} ${sites.length == 1 ? 'Site' : 'Sites'}',
                                        style:
                                            AppTextStyles.bodySmall.copyWith(
                                          color: AppColors.primary600,
                                          fontWeight: FontWeight.w700,
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
                    ),
            ),
          ],
        ),
      ),
    );
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
            'No clients found',
            style: AppTextStyles.title.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'Client records will appear here once they are available.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.neutral500,
            ),
          ),
        ],
      ),
    );
  }
}
