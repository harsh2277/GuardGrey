class BranchModel {
  final String id;
  final String name;
  final String city;
  final String address;
  final List<String> siteIds;
  final double? latitude;
  final double? longitude;

  const BranchModel({
    required this.id,
    required this.name,
    required this.city,
    required this.address,
    required this.siteIds,
    this.latitude,
    this.longitude,
  });

  BranchModel copyWith({
    String? id,
    String? name,
    String? city,
    String? address,
    List<String>? siteIds,
    double? latitude,
    double? longitude,
  }) {
    return BranchModel(
      id: id ?? this.id,
      name: name ?? this.name,
      city: city ?? this.city,
      address: address ?? this.address,
      siteIds: siteIds ?? this.siteIds,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }
}
