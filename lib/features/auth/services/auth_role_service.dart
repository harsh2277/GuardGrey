import 'package:firebase_auth/firebase_auth.dart';

import 'package:guardgrey/data/repositories/user_role_repository.dart';
import 'package:guardgrey/features/auth/models/app_role.dart';

class AuthRoleService {
  AuthRoleService._();

  static final AuthRoleService instance = AuthRoleService._();

  final UserRoleRepository _roleRepository = UserRoleRepository.instance;

  Future<AppRole> resolveRole(User user) {
    return _roleRepository.resolveRole(user);
  }
}
