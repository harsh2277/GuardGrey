class AppLocation {
  const AppLocation({
    required this.lat,
    required this.lng,
    required this.address,
  });

  final double lat;
  final double lng;
  final String address;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{'lat': lat, 'lng': lng, 'address': address};
  }

  factory AppLocation.fromMap(Map<String, dynamic> map) {
    return AppLocation(
      lat: (map['lat'] as num?)?.toDouble() ?? 0,
      lng: (map['lng'] as num?)?.toDouble() ?? 0,
      address: (map['address'] as String? ?? '').trim(),
    );
  }
}
