import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../modules/admin/data/admin_dummy_data.dart';
import '../../modules/admin/models/client_model.dart';
import '../../modules/admin/models/site_model.dart';
import '../../modules/admin/widgets/admin_search_bar.dart';

class ClientsScreen extends StatefulWidget {
  const ClientsScreen({super.key});

  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  String _searchQuery = '';

  List<ClientModel> get _filteredClients {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) {
      return AdminDummyData.clients;
    }

    return AdminDummyData.clients.where((client) {
      return client.name.toLowerCase().contains(query);
    }).toList(growable: false);
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
            AdminSearchBar(
              height: 50,
              hintText: 'Search clients...',
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
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
                        final List<SiteModel> sites = AdminDummyData.sites
                            .where((site) => site.clientId == client.id)
                            .toList(growable: false);

                        return Container(
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
                                      borderRadius: BorderRadius.circular(14),
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
                                      style: AppTextStyles.bodyLarge.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.neutral900,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                '${sites.length} site${sites.length == 1 ? '' : 's'} assigned',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.neutral500,
                                ),
                              ),
                            ],
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
