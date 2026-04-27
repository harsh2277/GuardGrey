import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/site_model.dart';
import 'admin_search_bar.dart';
import 'site_list_item.dart';

class SiteAssignmentTab extends StatelessWidget {
  const SiteAssignmentTab({
    super.key,
    required this.searchController,
    required this.onSearchChanged,
    required this.onAddPressed,
    required this.addButtonLabel,
    required this.sites,
    required this.emptyMessage,
    this.countLabel,
    this.onRemoveSite,
    this.onTapSite,
  });

  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onAddPressed;
  final String addButtonLabel;
  final List<SiteModel> sites;
  final String emptyMessage;
  final String? countLabel;
  final ValueChanged<String>? onRemoveSite;
  final ValueChanged<SiteModel>? onTapSite;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        Row(
          children: [
            Expanded(
              child: AdminSearchBar(
                controller: searchController,
                height: 50,
                hintText: 'Search sites...',
                onChanged: onSearchChanged,
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: onAddPressed,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(addButtonLabel),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(122, 50),
                padding: const EdgeInsets.symmetric(horizontal: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
            ),
          ],
        ),
        if (countLabel != null) ...[
          const SizedBox(height: 16),
          Text(
            countLabel!,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.neutral500,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
        const SizedBox(height: 16),
        if (sites.isEmpty)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.neutral200),
            ),
            child: Text(
              emptyMessage,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.neutral500,
              ),
            ),
          )
        else
          ...sites.map(
            (site) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SiteListItem(
                siteName: site.name,
                subtitle: site.location,
                onTap: onTapSite == null ? null : () => onTapSite!(site),
                trailing: IconButton(
                  onPressed: onRemoveSite == null
                      ? null
                      : () => onRemoveSite!(site.id),
                  icon: const Icon(
                    Icons.close_rounded,
                    color: AppColors.error,
                    size: 20,
                  ),
                  splashRadius: 20,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
