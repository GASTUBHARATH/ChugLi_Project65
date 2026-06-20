import 'package:flutter/foundation.dart';
import 'package:chugli_project65/data/services/activity_data_service.dart';

class ReportDataService {
  ReportDataService._privateConstructor();
  static final ReportDataService instance = ReportDataService._privateConstructor();

  final ValueNotifier<List<Map<String, dynamic>>> reportsNotifier = ValueNotifier([
    {
      'reportId': 'r1',
      'issueType': 'Spam Content',
      'description': 'Someone is constantly posting spam links in the local active room.',
      'screenshots': <String>[],
      'status': 'Pending',
      'submittedAt': DateTime.now().subtract(const Duration(hours: 2)),
      'submittedBy': 'Anonymous User',
      'roomId': '1',
      'rejectionReason': null,
    },
    {
      'reportId': 'r2',
      'issueType': 'Fake Room',
      'description': 'This room claims to be official college announcements but it is not.',
      'screenshots': <String>[],
      'status': 'Resolved',
      'submittedAt': DateTime.now().subtract(const Duration(days: 1)),
      'submittedBy': 'Anonymous User',
      'roomId': null,
      'rejectionReason': null,
    },
    {
      'reportId': 'r3',
      'issueType': 'Abuse / Harassment',
      'description': 'User was using offensive language towards others.',
      'screenshots': <String>[],
      'status': 'Rejected',
      'submittedAt': DateTime.now().subtract(const Duration(days: 3)),
      'submittedBy': 'Anonymous User',
      'roomId': '2',
      'rejectionReason': 'Insufficient evidence. Please provide screenshots if it happens again.',
    },
  ]);

  void addReport(Map<String, dynamic> report) {
    final currentReports = List<Map<String, dynamic>>.from(reportsNotifier.value);
    currentReports.insert(0, report);
    reportsNotifier.value = currentReports;
    
    ActivityDataService.instance.addActivity(
      title: 'Report Submitted',
      type: 'Report',
      action: 'Report Submitted',
      reportId: report['reportId'],
      roomId: report['roomId'],
      preview: report['issueType'] ?? 'Unknown Issue',
      handle: report['submittedBy'],
    );
  }
}
