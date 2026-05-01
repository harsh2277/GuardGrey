import 'package:firebase_auth/firebase_auth.dart';

import 'package:guardgrey/data/models/manager_model.dart';
import 'package:guardgrey/data/repositories/manager_repository.dart';

class ManagerSessionService {
  ManagerSessionService._();

  static final ManagerSessionService instance = ManagerSessionService._();

  final ManagerRepository _managerRepository = ManagerRepository.instance;

  String get currentEmail =>
      FirebaseAuth.instance.currentUser?.email?.trim().toLowerCase() ?? '';

  Stream<ManagerModel?> watchCurrentManager() {
    if (currentEmail.isEmpty) {
      return Stream<ManagerModel?>.value(null);
    }
    return _managerRepository.watchManagerByEmail(currentEmail);
  }

  Future<ManagerModel?> fetchCurrentManager() async {
    if (currentEmail.isEmpty) {
      return null;
    }
    return _managerRepository.fetchManagerByEmail(currentEmail);
  }
}
