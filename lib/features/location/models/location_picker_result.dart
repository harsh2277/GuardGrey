class LocationPickerResult {
  const LocationPickerResult({
    required this.address,
    required this.latitude,
    required this.longitude,
    this.locationTitle = '',
    this.buildingFloor = '',
  });

  final String address;
  final double latitude;
  final double longitude;
  final String locationTitle;
  final String buildingFloor;
}
