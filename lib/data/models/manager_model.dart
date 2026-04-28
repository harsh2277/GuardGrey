class ManagerModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final List<String> siteIds;

  const ManagerModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.siteIds,
  });

  ManagerModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    List<String>? siteIds,
  }) {
    return ManagerModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      siteIds: siteIds ?? this.siteIds,
    );
  }
}
