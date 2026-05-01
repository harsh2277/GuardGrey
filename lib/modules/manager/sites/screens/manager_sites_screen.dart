import 'package:flutter/material.dart';

import 'package:guardgrey/core/theme/app_colors.dart';
import 'package:guardgrey/core/theme/app_text_styles.dart';
import 'package:guardgrey/core/widgets/admin_search_bar.dart';
import 'package:guardgrey/data/models/manager_model.dart';
import 'package:guardgrey/data/models/site_model.dart';
import 'package:guardgrey/data/repositories/guard_grey_repository.dart';
import 'package:guardgrey/modules/manager/common/services/manager_session_service.dart';
import 'package:guardgrey/modules/manager/common/widgets/manager_ui.dart';
import 'package:guardgrey/modules/manager/sites/screens/manager_site_detail_screen.dart';

class ManagerSitesScreen extends StatefulWidget {
  const ManagerSitesScreen({super.key, this.showAppBar = false});

  final bool showAppBar;

  @override
  State<ManagerSitesScreen> createState() => _ManagerSitesScreenState();
}

class _ManagerSitesScreenState extends State<ManagerSitesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scaffold = StreamBuilder<ManagerModel?>(
      stream: ManagerSessionService.instance.watchCurrentManager(),
      builder: (context, managerSnapshot) {
        final manager = managerSnapshot.data;
        if (managerSnapshot.connectionState == ConnectionState.waiting &&
            manager == null) {
          return const Center(child: CircularProgressIndicator());
        }
        if (manager == null) {
          return const ManagerEmptyState(
            title: 'No manager workspace data',
            message:
                'Assigned sites will appear after the manager workspace syncs.',
          );
        }
        return StreamBuilder<List<SiteModel>>(
          stream: GuardGreyRepository.instance.watchSites(),
          builder: (context, siteSnapshot) {
            final sites = (siteSnapshot.data ?? const <SiteModel>[])
                .where(
                  (site) =>
                      site.managerId == manager.id ||
                      manager.siteIds.contains(site.id),
                )
                .where((site) {
                  final query = _searchQuery.trim().toLowerCase();
                  if (query.isEmpty) {
                    return true;
                  }
                  return site.name.toLowerCase().contains(query) ||
                      site.address.toLowerCase().contains(query) ||
                      site.location.toLowerCase().contains(query);
                })
                .toList(growable: false);

            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.showAppBar) ...[
                    Text(
                      'Assigned sites',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.neutral500,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  AdminSearchBar(
                    controller: _searchController,
                    hintText: 'Search assigned sites',
                    onChanged: (value) => setState(() => _searchQuery = value),
                  ),
                  const SizedBox(height: 18),
                  Expanded(
                    child: sites.isEmpty
                        ? const ManagerEmptyState(
                            title: 'No assigned sites found',
                            message:
                                'Assigned sites will appear here once they are linked to the manager.',
                          )
                        : ListView.separated(
                            itemCount: sites.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final site = sites[index];
                              return ManagerListCard(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ManagerSiteDetailScreen(
                                      site: site,
                                      managerId: manager.id,
                                    ),
                                  ),
                                ),
                                title: site.name,
                                subtitle: site.address.isEmpty
                                    ? site.location
                                    : site.address,
                                meta:
                                    'Last Visit: ${site.lastUpdated.isEmpty ? 'Not available' : site.lastUpdated}',
                                status: site.isActive ? 'Active' : 'Inactive',
                                icon: Icons.location_city_rounded,
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

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
      body: scaffold,
    );
  }
}
