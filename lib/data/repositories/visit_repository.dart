import 'package:guardgrey/data/models/visit_model.dart';
import 'package:guardgrey/data/repositories/guard_grey_repository.dart';

class VisitRepository {
  VisitRepository._();

  static final VisitRepository instance = VisitRepository._();

  final GuardGreyRepository _repository = GuardGreyRepository.instance;

  Stream<List<VisitModel>> watchVisits() => _repository.watchVisits();
  Stream<List<VisitModel>> watchSiteVisits(String siteId) =>
      _repository.watchSiteVisits(siteId);
}
