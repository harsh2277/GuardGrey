import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/site_model.dart';
import 'admin_search_bar.dart';

class SiteSelectorBottomSheet extends StatefulWidget {
  final List<SiteModel> allSites;
  final List<String> initiallySelectedIds;

  const SiteSelectorBottomSheet({
    super.key,
    required this.allSites,
    required this.initiallySelectedIds,
  });

  static Future<List<SiteModel>?> show(
    BuildContext context, {
    required List<SiteModel> allSites,
    required List<String> initiallySelectedIds,
  }) {
    return showModalBottomSheet<List<SiteModel>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SiteSelectorBottomSheet(
        allSites: allSites,
        initiallySelectedIds: initiallySelectedIds,
      ),
    );
  }

  @override
  State<SiteSelectorBottomSheet> createState() =>
      _SiteSelectorBottomSheetState();
}

class _SiteSelectorBottomSheetState extends State<SiteSelectorBottomSheet> {
  late final TextEditingController _searchController;
  late final Set<String> _selectedIds;
  String _query = '';

  List<SiteModel> get _filteredSites {
    final normalized = _query.trim().toLowerCase();
    if (normalized.isEmpty) {
      return widget.allSites;
    }

    return widget.allSites.where((site) {
      return site.name.toLowerCase().contains(normalized) ||
          site.location.toLowerCase().contains(normalized);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _selectedIds = widget.initiallySelectedIds.toSet();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSite(String siteId) {
    setState(() {
      if (_selectedIds.contains(siteId)) {
        _selectedIds.remove(siteId);
      } else {
        _selectedIds.add(siteId);
      }
    });
  }

  void _submit() {
    final selectedSites = widget.allSites
        .where((site) => _selectedIds.contains(site.id))
        .toList(growable: false);
    Navigator.pop(context, selectedSites);
  }

  @override
  Widget build(BuildContext context) {
    final filteredSites = _filteredSites;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.82,
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 52,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.neutral300,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Assign Sites',
                              style: AppTextStyles.title.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${_selectedIds.length} selected',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.neutral500,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: AdminSearchBar(
                    controller: _searchController,
                    hintText: 'Search sites...',
                    onChanged: (value) {
                      setState(() {
                        _query = value;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: filteredSites.isEmpty
                      ? Center(
                          child: Text(
                            'No sites found',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.neutral500,
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                          itemCount: filteredSites.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final site = filteredSites[index];
                            final isSelected = _selectedIds.contains(site.id);

                            return Material(
                              color: isSelected
                                  ? AppColors.primary50
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              child: InkWell(
                                onTap: () => _toggleSite(site.id),
                                borderRadius: BorderRadius.circular(18),
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.primary200
                                          : AppColors.neutral200,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              site.name,
                                              style: AppTextStyles.bodyLarge
                                                  .copyWith(
                                                color: AppColors.neutral900,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              site.location,
                                              style: AppTextStyles.bodySmall
                                                  .copyWith(
                                                color: AppColors.neutral500,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Checkbox(
                                        value: isSelected,
                                        onChanged: (_) => _toggleSite(site.id),
                                        activeColor: AppColors.primary600,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 54),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: const Text('Done'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
