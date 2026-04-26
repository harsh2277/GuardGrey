import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../data/admin_dummy_data.dart';
import '../models/site_model.dart';
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
  late final List<SiteModel> _sites;
  String _searchQuery = '';

  List<SiteModel> get _filteredSites {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) {
      return _sites;
    }

    return _sites.where((site) {
      final branchName = AdminDummyData.getBranchName(site.branchId);
      final clientName = AdminDummyData.getClientName(site.clientId);
      final managerName =
          AdminDummyData.getManagerById(site.managerId)?.name ?? '';
      return site.name.toLowerCase().contains(query) ||
          branchName.toLowerCase().contains(query) ||
          clientName.toLowerCase().contains(query) ||
          managerName.toLowerCase().contains(query) ||
          site.location.toLowerCase().contains(query);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _sites = AdminDummyData.sites.toList(growable: true);
  }

  Future<void> _openAddSite() async {
    final created = await Navigator.push<SiteModel>(
      context,
      MaterialPageRoute(builder: (_) => const AddSiteScreen()),
    );

    if (created != null) {
      setState(() {
        _sites.insert(0, created);
      });
    }
  }

  Future<void> _openSiteDetail(SiteModel site) async {
    final result = await Navigator.push<SiteDetailResult>(
      context,
      MaterialPageRoute(
        builder: (_) => SiteDetailScreen(site: site),
      ),
    );

    if (result == null) return;

    if (result.deleted) {
      setState(() {
        _sites.removeWhere((item) => item.id == site.id);
      });
      return;
    }

    if (result.site != null) {
      setState(() {
        final index = _sites.indexWhere((item) => item.id == site.id);
        if (index != -1) {
          _sites[index] = result.site!;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final sites = _filteredSites;

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
              child: sites.isEmpty
                  ? _buildEmptyState()
                  : ListView.separated(
                      itemCount: sites.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final site = sites[index];
                        return SiteCard(
                          site: site,
                          branchName: AdminDummyData.getBranchName(site.branchId),
                          onTap: () => _openSiteDetail(site),
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
              Icons.location_city_outlined,
              color: AppColors.primary600,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No sites available',
            style: AppTextStyles.title.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'Create your first site to start tracking branch operations.',
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
