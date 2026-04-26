import '../models/site_model.dart';

class AdminDummyData {
  AdminDummyData._();

  static const List<SiteModel> sites = [
    SiteModel(
      id: 'site_1',
      name: 'Mall Security',
      location: 'Satellite, Ahmedabad',
    ),
    SiteModel(
      id: 'site_2',
      name: 'Office Building',
      location: 'Prahlad Nagar, Ahmedabad',
    ),
    SiteModel(
      id: 'site_3',
      name: 'Warehouse Gate',
      location: 'Naroda, Ahmedabad',
    ),
    SiteModel(
      id: 'site_4',
      name: 'Corporate Park',
      location: 'Kalawad Road, Rajkot',
    ),
    SiteModel(
      id: 'site_5',
      name: 'Hospital Campus',
      location: '150 Feet Ring Road, Rajkot',
    ),
    SiteModel(
      id: 'site_6',
      name: 'Logistics Hub',
      location: 'Sachin, Surat',
    ),
    SiteModel(
      id: 'site_7',
      name: 'Industrial Plant',
      location: 'Makarpura, Vadodara',
    ),
  ];

  static List<SiteModel> getSitesByIds(List<String> siteIds) {
    final lookup = {for (final site in sites) site.id: site};
    return siteIds
        .map((id) => lookup[id])
        .whereType<SiteModel>()
        .toList(growable: false);
  }
}
