enum AppRole {
  admin,
  manager;

  static AppRole fromValue(String? value) {
    switch ((value ?? '').trim().toLowerCase()) {
      case 'manager':
        return AppRole.manager;
      case 'admin':
      default:
        return AppRole.admin;
    }
  }
}
