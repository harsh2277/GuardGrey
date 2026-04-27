import '../models/attendance_record.dart';
import '../models/branch_model.dart';
import '../models/client_model.dart';
import '../models/manager_model.dart';
import '../models/site_model.dart';
import '../models/visit_model.dart';

class AdminDummyData {
  AdminDummyData._();

  static const List<ClientModel> clients = [
    ClientModel(
      id: 'client_1',
      name: 'Alpha Retail',
      branchId: '1',
      siteIds: ['site_1', 'site_7'],
      email: 'ops@alpharetail.com',
      phone: '+91 98250 22001',
    ),
    ClientModel(
      id: 'client_2',
      name: 'Pinnacle Offices',
      branchId: '1',
      siteIds: ['site_2', 'site_4'],
      email: 'admin@pinnacleoffices.com',
      phone: '+91 98250 22002',
    ),
    ClientModel(
      id: 'client_3',
      name: 'CarePlus Health',
      branchId: '2',
      siteIds: ['site_5'],
      email: 'support@careplushealth.com',
      phone: '+91 98250 22003',
    ),
    ClientModel(
      id: 'client_4',
      name: 'Prime Logistics',
      branchId: '3',
      siteIds: ['site_3', 'site_6'],
      email: 'control@primelogistics.com',
      phone: '+91 98250 22004',
    ),
  ];

  static const List<ManagerModel> managers = [
    ManagerModel(
      id: 'manager_1',
      name: 'Ravi Patel',
      email: 'ravi.patel@guardgrey.com',
      phone: '+91 98765 11001',
      siteIds: ['site_1', 'site_7'],
    ),
    ManagerModel(
      id: 'manager_2',
      name: 'Heena Shah',
      email: 'heena.shah@guardgrey.com',
      phone: '+91 98765 11002',
      siteIds: ['site_2'],
    ),
    ManagerModel(
      id: 'manager_3',
      name: 'Amit Joshi',
      email: 'amit.joshi@guardgrey.com',
      phone: '+91 98765 11003',
      siteIds: ['site_3', 'site_6'],
    ),
    ManagerModel(
      id: 'manager_4',
      name: 'Sneha Trivedi',
      email: 'sneha.trivedi@guardgrey.com',
      phone: '+91 98765 11004',
      siteIds: ['site_4'],
    ),
    ManagerModel(
      id: 'manager_5',
      name: 'Kunal Mehta',
      email: 'kunal.mehta@guardgrey.com',
      phone: '+91 98765 11005',
      siteIds: ['site_5'],
    ),
  ];

  static const List<BranchModel> branches = [
    BranchModel(
      id: '1',
      name: 'Ahmedabad',
      city: 'Ahmedabad',
      address: 'SG Highway, Ahmedabad',
      siteIds: ['site_1', 'site_2', 'site_3'],
      latitude: 23.0395,
      longitude: 72.5315,
    ),
    BranchModel(
      id: '2',
      name: 'Rajkot',
      city: 'Rajkot',
      address: 'Kalawad Road, Rajkot',
      siteIds: ['site_4', 'site_5'],
      latitude: 22.2901,
      longitude: 70.7853,
    ),
    BranchModel(
      id: '3',
      name: 'Surat',
      city: 'Surat',
      address: 'Ring Road, Surat',
      siteIds: ['site_6'],
      latitude: 21.1702,
      longitude: 72.8311,
    ),
    BranchModel(
      id: '4',
      name: 'Vadodara',
      city: 'Vadodara',
      address: 'Alkapuri, Vadodara',
      siteIds: ['site_7'],
      latitude: 22.3072,
      longitude: 73.1812,
    ),
  ];

  static const List<SiteModel> sites = [
    SiteModel(
      id: 'site_1',
      name: 'Mall Security',
      clientId: 'client_1',
      branchId: '1',
      managerId: 'manager_1',
      location: 'Satellite, Ahmedabad',
      address: 'Alpha One Mall, Satellite, Ahmedabad',
      description: 'Retail security point with day and night shift coverage.',
      createdDate: '12 Jan 2026',
      lastUpdated: '26 Apr 2026',
    ),
    SiteModel(
      id: 'site_2',
      name: 'Office Building',
      clientId: 'client_2',
      branchId: '1',
      managerId: 'manager_2',
      location: 'Prahlad Nagar, Ahmedabad',
      address: 'Pinnacle Business Park, Prahlad Nagar, Ahmedabad',
      description: 'Corporate tower access management and patrol supervision.',
      createdDate: '14 Jan 2026',
      lastUpdated: '25 Apr 2026',
    ),
    SiteModel(
      id: 'site_3',
      name: 'Warehouse Gate',
      clientId: 'client_4',
      branchId: '1',
      managerId: 'manager_3',
      location: 'Naroda, Ahmedabad',
      address: 'Naroda GIDC Entry Gate, Ahmedabad',
      description: 'Inbound and outbound vehicle log monitoring.',
      createdDate: '18 Jan 2026',
      lastUpdated: '24 Apr 2026',
      isActive: false,
    ),
    SiteModel(
      id: 'site_4',
      name: 'Corporate Park',
      clientId: 'client_2',
      branchId: '2',
      managerId: 'manager_4',
      location: 'Kalawad Road, Rajkot',
      address: 'Corporate Avenue, Kalawad Road, Rajkot',
      description: 'Corporate campus security desk and visitor control.',
      createdDate: '03 Feb 2026',
      lastUpdated: '26 Apr 2026',
    ),
    SiteModel(
      id: 'site_5',
      name: 'Hospital Campus',
      clientId: 'client_3',
      branchId: '2',
      managerId: 'manager_5',
      location: '150 Feet Ring Road, Rajkot',
      address: 'Lifeline Hospital Campus, Rajkot',
      description: 'Emergency gate and OPD entry coverage with 24/7 staff.',
      createdDate: '06 Feb 2026',
      lastUpdated: '23 Apr 2026',
    ),
    SiteModel(
      id: 'site_6',
      name: 'Logistics Hub',
      clientId: 'client_4',
      branchId: '3',
      managerId: 'manager_3',
      location: 'Sachin, Surat',
      address: 'Freight Terminal, Sachin, Surat',
      description: 'Large dispatch yard with delivery gate checkpoints.',
      createdDate: '18 Mar 2026',
      lastUpdated: '22 Apr 2026',
    ),
    SiteModel(
      id: 'site_7',
      name: 'Industrial Plant',
      clientId: 'client_1',
      branchId: '4',
      managerId: 'manager_1',
      location: 'Makarpura, Vadodara',
      address: 'Plant 4, Makarpura Industrial Estate, Vadodara',
      description: 'Manufacturing floor perimeter and plant gate security.',
      createdDate: '22 Mar 2026',
      lastUpdated: '21 Apr 2026',
    ),
  ];

  static const List<VisitModel> visits = [
    VisitModel(
      id: 'visit_1',
      siteId: 'site_1',
      managerName: 'Ravi Patel',
      date: '26 Apr 2026',
      day: 'Sunday',
      time: '09:15 AM',
      notes: 'Routine morning inspection completed.',
      status: 'Completed',
    ),
    VisitModel(
      id: 'visit_2',
      siteId: 'site_1',
      managerName: 'Heena Shah',
      date: '25 Apr 2026',
      day: 'Saturday',
      time: '06:40 PM',
      notes: 'Shift handoff reviewed with supervisor.',
      status: 'Completed',
    ),
    VisitModel(
      id: 'visit_3',
      siteId: 'site_2',
      managerName: 'Amit Joshi',
      date: '26 Apr 2026',
      day: 'Sunday',
      time: '11:00 AM',
      notes: 'Visitor desk escalation reviewed.',
      status: 'In Progress',
    ),
    VisitModel(
      id: 'visit_4',
      siteId: 'site_4',
      managerName: 'Sneha Trivedi',
      date: '24 Apr 2026',
      day: 'Friday',
      time: '04:20 PM',
      notes: 'Parking access issue resolved.',
      status: 'Completed',
    ),
    VisitModel(
      id: 'visit_5',
      siteId: 'site_5',
      managerName: 'Kunal Mehta',
      date: '23 Apr 2026',
      day: 'Thursday',
      time: '08:10 AM',
      notes: '',
      status: 'Scheduled',
    ),
  ];

  static const List<AttendanceRecord> attendanceRecords = [
    AttendanceRecord(
      id: 'attendance_1',
      name: 'Ravi Patel',
      status: 'Present',
      date: '27 Apr 2026',
      checkIn: '08:55 AM',
      checkOut: '06:10 PM',
    ),
    AttendanceRecord(
      id: 'attendance_2',
      name: 'Heena Shah',
      status: 'Present',
      date: '27 Apr 2026',
      checkIn: '09:05 AM',
      checkOut: '06:00 PM',
    ),
    AttendanceRecord(
      id: 'attendance_3',
      name: 'Amit Joshi',
      status: 'Absent',
      date: '27 Apr 2026',
      checkIn: '-',
      checkOut: '-',
    ),
    AttendanceRecord(
      id: 'attendance_4',
      name: 'Sneha Trivedi',
      status: 'Present',
      date: '27 Apr 2026',
      checkIn: '08:48 AM',
      checkOut: '05:52 PM',
    ),
    AttendanceRecord(
      id: 'attendance_5',
      name: 'Kunal Mehta',
      status: 'Absent',
      date: '27 Apr 2026',
      checkIn: '-',
      checkOut: '-',
    ),
  ];

  static List<SiteModel> getSitesByIds(List<String> siteIds) {
    final lookup = {for (final site in sites) site.id: site};
    return siteIds
        .map((id) => lookup[id])
        .whereType<SiteModel>()
        .toList(growable: false);
  }

  static BranchModel? getBranchById(String branchId) {
    for (final branch in branches) {
      if (branch.id == branchId) return branch;
    }
    return null;
  }

  static String getBranchName(String branchId) {
    return getBranchById(branchId)?.name ?? 'Unassigned Branch';
  }

  static ClientModel? getClientById(String clientId) {
    for (final client in clients) {
      if (client.id == clientId) return client;
    }
    return null;
  }

  static String getClientName(String clientId) {
    return getClientById(clientId)?.name ?? 'Unassigned Client';
  }

  static ManagerModel? getManagerById(String managerId) {
    for (final manager in managers) {
      if (manager.id == managerId) return manager;
    }
    return null;
  }

  static List<SiteModel> getSitesForClient(String clientId) {
    return sites
        .where((site) => site.clientId == clientId)
        .toList(growable: false);
  }

  static List<SiteModel> getSitesForManager(String managerId) {
    final manager = getManagerById(managerId);
    if (manager == null) {
      return const <SiteModel>[];
    }

    return getSitesByIds(manager.siteIds);
  }

  static List<VisitModel> getVisitsBySiteId(String siteId) {
    return visits
        .where((visit) => visit.siteId == siteId)
        .toList(growable: false);
  }
}
