import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:guardgrey/core/theme/app_colors.dart';
import 'package:guardgrey/core/theme/app_text_styles.dart';
import 'package:guardgrey/core/utils/date_time_display.dart';
import 'package:guardgrey/core/widgets/section_header.dart';
import 'package:guardgrey/data/models/client_model.dart';
import 'package:guardgrey/data/models/site_model.dart';
import 'package:guardgrey/data/repositories/client_repository.dart';
import 'package:guardgrey/modules/manager/common/widgets/manager_ui.dart';
import 'package:guardgrey/modules/manager/visits/models/manager_visit_entry.dart';
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
    return StreamBuilder<List<ClientModel>>(
      stream: ClientRepository.instance.watchClients(),
      builder: (context, clientSnapshot) {
        final client = (clientSnapshot.data ?? const <ClientModel>[])
            .where((item) => item.id == site.clientId)
            .firstOrNull;

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
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
            children: [
              ManagerSurfaceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      site.name,
                      style: AppTextStyles.title.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _InfoRow(
                      label: 'Client',
                      value: client?.name.isNotEmpty == true
                          ? client!.name
                          : 'Not assigned',
                    ),
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
                      value: site.buildingFloor.isEmpty
                          ? '-'
                          : site.buildingFloor,
                    ),
                    _InfoRow(
                      label: 'Last Updated',
                      value: site.lastUpdated.isEmpty ? '-' : site.lastUpdated,
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed:
                            site.latitude == null || site.longitude == null
                            ? null
                            : () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => _SiteMapScreen(site: site),
                                ),
                              ),
                        icon: const Icon(Icons.map_outlined),
                        label: const Text('View on Map'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const SectionHeader(title: 'Visit History'),
              const SizedBox(height: 12),
              StreamBuilder<List<ManagerVisitEntry>>(
                stream: ManagerVisitRepository.instance.watchSiteVisits(
                  managerId: managerId,
                  siteId: site.id,
                ),
                builder: (context, snapshot) {
                  final visits = snapshot.data ?? const <ManagerVisitEntry>[];
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
                                visit.visitType,
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.primary700,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 6),
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
      },
    );
  }
}

class _SiteMapScreen extends StatelessWidget {
  const _SiteMapScreen({required this.site});

  final SiteModel site;

  @override
  Widget build(BuildContext context) {
    final position = LatLng(site.latitude!, site.longitude!);
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Site Map',
          style: AppTextStyles.title.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: FlutterMap(
                  options: MapOptions(initialCenter: position, initialZoom: 16),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.guardgrey.guardgrey',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: position,
                          width: 44,
                          height: 44,
                          child: const Icon(
                            Icons.location_on_rounded,
                            color: AppColors.error,
                            size: 40,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            ManagerSurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    site.name,
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    site.address.isEmpty ? site.location : site.address,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.neutral600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
