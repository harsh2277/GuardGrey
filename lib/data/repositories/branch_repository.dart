import 'package:guardgrey/data/models/branch_model.dart';
import 'package:guardgrey/data/repositories/guard_grey_repository.dart';

class BranchRepository {
  BranchRepository._();

  static final BranchRepository instance = BranchRepository._();

  final GuardGreyRepository _repository = GuardGreyRepository.instance;

  Stream<List<BranchModel>> watchBranches() => _repository.watchBranches();
  Stream<BranchModel?> watchBranch(String id) => _repository.watchBranch(id);
  Future<List<BranchModel>> fetchBranches() => _repository.fetchBranches();
  Future<void> saveBranch(BranchModel branch) => _repository.saveBranch(branch);
  Future<void> deleteBranch(String branchId) =>
      _repository.deleteBranch(branchId);
}
