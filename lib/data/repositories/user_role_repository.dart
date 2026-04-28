import 'package:firebase_auth/firebase_auth.dart';

import 'package:guardgrey/data/repositories/guard_grey_repository.dart';
import 'package:guardgrey/features/auth/models/app_role.dart';

class UserRoleRepository {
  UserRoleRepository._();

  static final UserRoleRepository instance = UserRoleRepository._();

  final GuardGreyRepository _repository = GuardGreyRepository.instance;

  Future<AppRole> resolveRole(User user) async {
    final tokenResult = await user.getIdTokenResult();
    final claimRole = tokenResult.claims?['role']?.toString();
    if (claimRole != null && claimRole.trim().isNotEmpty) {
      return AppRole.fromValue(claimRole);
    }

    final email = user.email?.trim().toLowerCase() ?? '';
    if (email.isEmpty) {
      return AppRole.admin;
    }

    final manager = await _repository.fetchManagerByEmail(email);
    if (manager != null) {
      return AppRole.manager;
    }

    return AppRole.admin;
  }
}
