import 'package:guardgrey/data/models/site_model.dart';
import 'package:guardgrey/data/repositories/guard_grey_repository.dart';

class SiteRepository {
  SiteRepository._();

  static final SiteRepository instance = SiteRepository._();

  final GuardGreyRepository _repository = GuardGreyRepository.instance;

  Stream<List<SiteModel>> watchSites() => _repository.watchSites();
  Stream<SiteModel?> watchSite(String id) => _repository.watchSite(id);
  Future<List<SiteModel>> fetchSites() => _repository.fetchSites();
  Future<void> saveSite(SiteModel site) => _repository.saveSite(site);
  Future<void> deleteSite(String siteId) => _repository.deleteSite(siteId);
}
