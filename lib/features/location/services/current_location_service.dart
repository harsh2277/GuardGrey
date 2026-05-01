import 'package:geolocator/geolocator.dart';

class CurrentLocationService {
  const CurrentLocationService();

  static const LocationSettings trackingSettings = LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 8,
  );

  Future<LocationPermission> checkPermission() {
    return Geolocator.checkPermission();
  }

  Stream<Position> getPositionStream() {
    return Geolocator.getPositionStream(locationSettings: trackingSettings);
  }

  Future<Position> getCurrentPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const CurrentLocationException(
        'Location services are disabled. Turn them on to detect your current location.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw const CurrentLocationException(
        'Location permission was denied. Allow access to use your current location.',
      );
    }

    if (permission == LocationPermission.deniedForever) {
      throw const CurrentLocationException(
        'Location permission is permanently denied. Enable it from device settings.',
      );
    }

    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }
}

class CurrentLocationException implements Exception {
  const CurrentLocationException(this.message);

  final String message;

  @override
  String toString() => message;
}
