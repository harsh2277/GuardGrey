import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:guardgrey/core/theme/app_colors.dart';
import 'package:guardgrey/core/theme/app_text_styles.dart';
import 'package:guardgrey/core/utils/date_time_display.dart';
import 'package:guardgrey/core/widgets/admin_search_bar.dart';
import 'package:guardgrey/core/widgets/list_filter_bottom_sheet.dart';
import 'package:guardgrey/core/widgets/surface_icon_button.dart';
import 'package:guardgrey/data/models/manager_live_location_model.dart';
import 'package:guardgrey/data/models/manager_model.dart';
import 'package:guardgrey/data/repositories/live_tracking_repository.dart';
import 'package:guardgrey/data/repositories/manager_repository.dart';

class LiveTrackingScreen extends StatefulWidget {
  const LiveTrackingScreen({super.key});

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> {
  late final TextEditingController _searchController;
  String _searchQuery = '';
  String? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openFilters() async {
    final filters = await ListFilterBottomSheet.show(
      context,
      title: 'Filter Live Tracking',
      searchHint: 'Refine by manager or location...',
      initialSearchQuery: _searchQuery,
      statusOptions: const ['Active', 'Stale'],
      initialStatus: _selectedStatus,
    );
    if (filters == null) {
      return;
    }
    _searchController.text = filters.searchQuery;
    setState(() {
      _searchQuery = filters.searchQuery;
      _selectedStatus = filters.status;
    });
  }

  String _statusFor(ManagerLiveLocationModel model) {
    final minutes = DateTime.now().difference(model.lastUpdated).inMinutes;
    return minutes <= 30 ? 'Active' : 'Stale';
  }

  List<ManagerLiveLocationModel> _filterManagers(
    List<ManagerLiveLocationModel> managers,
  ) {
    final query = _searchQuery.trim().toLowerCase();
    return managers
        .where((manager) {
          final status = _statusFor(manager);
          final matchesQuery =
              query.isEmpty ||
              manager.managerName.toLowerCase().contains(query) ||
              manager.checkInLocation.address.toLowerCase().contains(query);
          final matchesStatus =
              _selectedStatus == null || _selectedStatus == status;
          return matchesQuery && matchesStatus;
        })
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: StreamBuilder<List<ManagerLiveLocationModel>>(
          stream: LiveTrackingRepository.instance.watchManagerLocations(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final filteredManagers = _filterManagers(
              snapshot.data ?? const <ManagerLiveLocationModel>[],
            );

            if (filteredManagers.isEmpty) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: Column(
                  children: [
                    _TopControls(
                      controller: _searchController,
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                      onFilterTap: _openFilters,
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          'No live manager locations available.',
                          style: AppTextStyles.bodyLarge.copyWith(
                            color: AppColors.neutral500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            final center = LatLng(
              filteredManagers.first.lat,
              filteredManagers.first.lng,
            );

            return StreamBuilder<List<ManagerModel>>(
              stream: ManagerRepository.instance.watchManagers(),
              builder: (context, managerSnapshot) {
                final managerById = {
                  for (final manager
                      in managerSnapshot.data ?? const <ManagerModel>[])
                    manager.id: manager,
                };

                return Stack(
                  children: [
                    Positioned.fill(
                      child: FlutterMap(
                        options: MapOptions(
                          initialCenter: center,
                          initialZoom: 11.8,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'guardgrey',
                          ),
                          MarkerLayer(
                            markers: filteredManagers
                                .map(
                                  (item) => Marker(
                                    point: LatLng(item.lat, item.lng),
                                    width: 52,
                                    height: 52,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: AppColors.primary600,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 3,
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.person_pin_circle_rounded,
                                        color: Colors.white,
                                        size: 26,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(growable: false),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      left: 20,
                      right: 20,
                      top: 12,
                      child: _TopControls(
                        controller: _searchController,
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                        onFilterTap: _openFilters,
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 12,
                      child: SizedBox(
                        height: 188,
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          scrollDirection: Axis.horizontal,
                          itemCount: filteredManagers.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final item = filteredManagers[index];
                            final manager = managerById[item.managerId];
                            final status = _statusFor(item);
                            return _ManagerLocationCard(
                              location: item,
                              profileImage: manager?.profileImage ?? '',
                              status: status,
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _TopControls extends StatelessWidget {
  const _TopControls({
    required this.controller,
    required this.onChanged,
    required this.onFilterTap,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onFilterTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: AdminSearchBar(
            controller: controller,
            height: 50,
            hintText: 'Search managers...',
            onChanged: onChanged,
          ),
        ),
        const SizedBox(width: 12),
        SurfaceIconButton(
          icon: Icons.tune_rounded,
          onTap: onFilterTap,
          backgroundColor: AppColors.primary600,
          borderColor: AppColors.primary600,
          iconColor: Colors.white,
          borderRadius: 25,
        ),
      ],
    );
  }
}

class _ManagerLocationCard extends StatelessWidget {
  const _ManagerLocationCard({
    required this.location,
    required this.profileImage,
    required this.status,
  });

  final ManagerLiveLocationModel location;
  final String profileImage;
  final String status;

  @override
  Widget build(BuildContext context) {
    final statusColor = status == 'Active'
        ? AppColors.successDark
        : AppColors.warningDark;
    final statusBackground = status == 'Active'
        ? AppColors.successLight
        : AppColors.warningLight;

    return Container(
      width: 272,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.neutral200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.primary50,
                backgroundImage: profileImage.isNotEmpty
                    ? NetworkImage(profileImage)
                    : null,
                child: profileImage.isEmpty
                    ? Text(
                        location.managerName.isEmpty
                            ? 'M'
                            : location.managerName[0].toUpperCase(),
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.primary700,
                          fontWeight: FontWeight.w700,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      location.managerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: statusBackground,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        status,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            formatDateTimeLabel(location.lastUpdated),
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.neutral500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            location.checkInLocation.address,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.neutral700,
            ),
          ),
        ],
      ),
    );
  }
}
