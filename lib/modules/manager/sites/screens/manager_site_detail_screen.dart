import 'package:flutter/material.dart';

import 'package:guardgrey/core/theme/app_colors.dart';
import 'package:guardgrey/core/theme/app_text_styles.dart';
import 'package:guardgrey/core/utils/date_time_display.dart';
import 'package:guardgrey/core/widgets/section_header.dart';
import 'package:guardgrey/data/models/site_model.dart';
import 'package:guardgrey/modules/manager/common/widgets/manager_ui.dart';
import 'package:guardgrey/modules/manager/visits/repositories/manager_visit_repository.dart';

class ManagerSiteDetailScreen extends StatelessWidget {
  const ManagerSiteDetailScreen({
    super.key,
    required this.site,
    required this.managerId,
  });

  final SiteModel site;
  final String managerId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          site.name,
          style: AppTextStyles.title.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          ManagerSurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        site.name,
                        style: AppTextStyles.title.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    ManagerStatusChip(
                      label: site.isActive ? 'Active' : 'Inactive',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _InfoRow(
                  label: 'Address',
                  value: site.address.isEmpty ? '-' : site.address,
                ),
                _InfoRow(
                  label: 'Location',
                  value: site.location.isEmpty ? '-' : site.location,
                ),
                _InfoRow(
                  label: 'Building / Floor',
                  value: site.buildingFloor.isEmpty ? '-' : site.buildingFloor,
                ),
                _InfoRow(
                  label: 'Last Updated',
                  value: site.lastUpdated.isEmpty ? '-' : site.lastUpdated,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const SectionHeader(title: 'Visit History'),
          const SizedBox(height: 12),
          StreamBuilder(
            stream: ManagerVisitRepository.instance.watchSiteVisits(
              managerId: managerId,
              siteId: site.id,
            ),
            builder: (context, snapshot) {
              final visits = snapshot.data ?? const [];
              if (snapshot.connectionState == ConnectionState.waiting &&
                  visits.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              if (visits.isEmpty) {
                return const ManagerEmptyState(
                  title: 'No visits yet',
                  message:
                      'This site has not been visited by the signed-in manager yet.',
                );
              }
              return Column(
                children: [
                  for (final visit in visits) ...[
                    ManagerSurfaceCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  formatDateTimeLabel(visit.scheduledAt),
                                  style: AppTextStyles.bodyLarge.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              ManagerStatusChip(label: visit.status),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            visit.notes.isEmpty
                                ? 'No notes added.'
                                : visit.notes,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.neutral600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.neutral500,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(child: Text(value, style: AppTextStyles.bodyMedium)),
        ],
      ),
    );
  }
}
