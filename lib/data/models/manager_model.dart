class ManagerModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String profileImage;
  final List<String> siteIds;

  const ManagerModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.profileImage = '',
    required this.siteIds,
  });

  ManagerModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? profileImage,
    List<String>? siteIds,
  }) {
    return ManagerModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      profileImage: profileImage ?? this.profileImage,
      siteIds: siteIds ?? this.siteIds,
    );
  }
}
