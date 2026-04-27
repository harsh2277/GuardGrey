class ClientModel {
  final String id;
  final String name;
  final String branchId;
  final List<String> siteIds;
  final String email;
  final String phone;

  const ClientModel({
    required this.id,
    required this.name,
    required this.branchId,
    required this.siteIds,
    required this.email,
    required this.phone,
  });

  ClientModel copyWith({
    String? id,
    String? name,
    String? branchId,
    List<String>? siteIds,
    String? email,
    String? phone,
  }) {
    return ClientModel(
      id: id ?? this.id,
      name: name ?? this.name,
      branchId: branchId ?? this.branchId,
      siteIds: siteIds ?? this.siteIds,
      email: email ?? this.email,
      phone: phone ?? this.phone,
    );
  }
}
