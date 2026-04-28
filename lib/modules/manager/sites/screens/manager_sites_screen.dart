import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:guardgrey/core/theme/app_colors.dart';
import 'package:guardgrey/core/theme/app_text_styles.dart';
import 'package:guardgrey/core/utils/filter_resettable.dart';
import 'package:guardgrey/core/widgets/admin_search_bar.dart';
import 'package:guardgrey/data/models/manager_model.dart';
import 'package:guardgrey/data/models/site_model.dart';
import 'package:guardgrey/data/repositories/guard_grey_repository.dart';
import 'package:guardgrey/modules/manager/visits/screens/manager_visits_screen.dart';

class ManagerSitesScreen extends StatefulWidget {
  const ManagerSitesScreen({super.key});

  @override
  State<ManagerSitesScreen> createState() => _ManagerSitesScreenState();
}

class _ManagerSitesScreenState extends State<ManagerSitesScreen>
    implements FilterResettable {
  final GuardGreyRepository _repository = GuardGreyRepository.instance;
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void resetFilters() {
    setState(() {
      _query = '';
      _searchController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final email = FirebaseAuth.instance.currentUser?.email ?? '';

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Assigned Sites',
          style: AppTextStyles.title.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      body: StreamBuilder<ManagerModel?>(
        stream: _repository.watchManagerByEmail(email),
        builder: (context, managerSnapshot) {
          final manager = managerSnapshot.data;
          if (managerSnapshot.connectionState == ConnectionState.waiting &&
              manager == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (manager == null) {
            return const _EmptyState(message: 'No assigned sites found.');
          }

          return StreamBuilder<List<SiteModel>>(
            stream: _repository.watchSites(),
            builder: (context, sitesSnapshot) {
              final sites = (sitesSnapshot.data ?? const <SiteModel>[])
                  .where(
                    (site) =>
                        site.managerId == manager.id ||
                        manager.siteIds.contains(site.id),
                  )
                  .where((site) {
                    final query = _query.trim().toLowerCase();
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
                  children: [
                    AdminSearchBar(
                      controller: _searchController,
                      hintText: 'Search assigned sites...',
                      onChanged: (value) => setState(() => _query = value),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: sites.isEmpty
                          ? const _EmptyState(
                              message: 'No assigned sites match your search.',
                            )
                          : ListView.separated(
                              itemCount: sites.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final site = sites[index];
                                return _ManagerSiteCard(
                                  site: site,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ManagerVisitsScreen(
                                        initialSiteId: site.id,
                                        initialSiteName: site.name,
                                      ),
                                    ),
                                  ),
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
      ),
    );
  }
}

class _ManagerSiteCard extends StatelessWidget {
  const _ManagerSiteCard({required this.site, required this.onTap});

  final SiteModel site;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.neutral200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                site.name,
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                site.address,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.neutral500,
                ),
              ),
              if (site.buildingFloor.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  site.buildingFloor,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.neutral500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyLarge.copyWith(color: AppColors.neutral500),
        ),
      ),
    );
  }
}
