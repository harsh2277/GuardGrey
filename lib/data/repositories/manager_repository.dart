import 'package:guardgrey/data/models/manager_model.dart';
import 'package:guardgrey/data/repositories/guard_grey_repository.dart';

class ManagerRepository {
  ManagerRepository._();

  static final ManagerRepository instance = ManagerRepository._();

  final GuardGreyRepository _repository = GuardGreyRepository.instance;

  Stream<List<ManagerModel>> watchManagers() => _repository.watchManagers();
  Stream<ManagerModel?> watchManager(String id) => _repository.watchManager(id);
  Stream<ManagerModel?> watchManagerByEmail(String email) =>
      _repository.watchManagerByEmail(email);
  Future<List<ManagerModel>> fetchManagers() => _repository.fetchManagers();
  Future<ManagerModel?> fetchManagerByEmail(String email) =>
      _repository.fetchManagerByEmail(email);
  Future<void> saveManager(ManagerModel manager) =>
      _repository.saveManager(manager);
  Future<void> deleteManager(String managerId) =>
      _repository.deleteManager(managerId);
}
