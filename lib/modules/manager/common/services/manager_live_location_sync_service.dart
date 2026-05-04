import 'package:guardgrey/data/models/app_location.dart';
import 'package:guardgrey/data/models/manager_live_location_model.dart';
import 'package:guardgrey/data/models/manager_model.dart';
import 'package:guardgrey/data/repositories/live_tracking_repository.dart';
import 'package:guardgrey/features/location/services/current_location_service.dart';
import 'package:guardgrey/features/location/services/nominatim_location_service.dart';

class ManagerLiveLocationSyncService {
  ManagerLiveLocationSyncService._({
    CurrentLocationService? currentLocationService,
    NominatimLocationService? nominatimLocationService,
    LiveTrackingRepository? liveTrackingRepository,
  }) : _currentLocationService =
           currentLocationService ?? const CurrentLocationService(),
       _nominatimLocationService =
           nominatimLocationService ?? NominatimLocationService(),
       _liveTrackingRepository =
           liveTrackingRepository ?? LiveTrackingRepository.instance;

  static final ManagerLiveLocationSyncService instance =
      ManagerLiveLocationSyncService._();

  final CurrentLocationService _currentLocationService;
  final NominatimLocationService _nominatimLocationService;
  final LiveTrackingRepository _liveTrackingRepository;

  Future<void> syncCurrentManagerLocation(ManagerModel manager) async {
    final position = await _currentLocationService.getCurrentPosition();
    final address = await _resolveAddress(
      latitude: position.latitude,
      longitude: position.longitude,
    );

    final liveLocation = ManagerLiveLocationModel(
      managerId: manager.id,
      managerName: manager.name,
      lat: position.latitude,
      lng: position.longitude,
      lastUpdated: DateTime.now(),
      checkInLocation: AppLocation(
        lat: position.latitude,
        lng: position.longitude,
        address: address,
      ),
      branchImage: manager.profileImage,
      helplineNumber: '+91 1800 123 4455',
      whatsappNumber: manager.phone,
    );

    await _liveTrackingRepository.saveManagerLiveLocation(liveLocation);
  }

  Future<String> _resolveAddress({
    required double latitude,
    required double longitude,
  }) async {
    try {
      return await _nominatimLocationService.reverseGeocode(
        latitude: latitude,
        longitude: longitude,
      );
    } catch (_) {
      return 'Lat: ${latitude.toStringAsFixed(6)}, Lng: ${longitude.toStringAsFixed(6)}';
    }
  }
}
