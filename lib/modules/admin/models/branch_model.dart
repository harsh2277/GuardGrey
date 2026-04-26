class BranchModel {
  final String id;
  final String name;
  final String city;
  final String address;
  final List<String> siteIds;

  const BranchModel({
    required this.id,
    required this.name,
    required this.city,
    required this.address,
    required this.siteIds,
  });

  BranchModel copyWith({
    String? id,
    String? name,
    String? city,
    String? address,
    List<String>? siteIds,
  }) {
    return BranchModel(
      id: id ?? this.id,
      name: name ?? this.name,
      city: city ?? this.city,
      address: address ?? this.address,
      siteIds: siteIds ?? this.siteIds,
    );
  }
}
