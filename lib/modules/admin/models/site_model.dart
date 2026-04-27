class SiteModel {
  final String id;
  final String name;
  final String clientId;
  final String branchId;
  final String managerId;
  final String location;
  final String address;
  final double? latitude;
  final double? longitude;
  final String description;
  final String createdDate;
  final String lastUpdated;
  final bool isActive;

  const SiteModel({
    required this.id,
    required this.name,
    required this.clientId,
    required this.branchId,
    required this.managerId,
    required this.location,
    this.address = '',
    this.latitude,
    this.longitude,
    this.description = '',
    this.createdDate = '',
    this.lastUpdated = '',
    this.isActive = true,
  });

  SiteModel copyWith({
    String? id,
    String? name,
    String? clientId,
    String? branchId,
    String? managerId,
    String? location,
    String? address,
    double? latitude,
    double? longitude,
    String? description,
    String? createdDate,
    String? lastUpdated,
    bool? isActive,
  }) {
    return SiteModel(
      id: id ?? this.id,
      name: name ?? this.name,
      clientId: clientId ?? this.clientId,
      branchId: branchId ?? this.branchId,
      managerId: managerId ?? this.managerId,
      location: location ?? this.location,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      description: description ?? this.description,
      createdDate: createdDate ?? this.createdDate,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isActive: isActive ?? this.isActive,
    );
  }
}
