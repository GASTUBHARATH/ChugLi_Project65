import 'package:flutter/material.dart';
import 'package:chugli_project65/data/services/firestore_room_service.dart';

/// View-only reports history screen.
/// Shows all reports the current user has submitted, pulled from Firestore.
/// Reports can ONLY be created from inside a chat room by long-pressing a message.
class ReportsHistoryScreen extends StatelessWidget {
  const ReportsHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).cardColor,
        elevation: 1,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: Theme.of(context).textTheme.bodyLarge?.color),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'My Reports',
          style: TextStyle(
              color: Theme.of(context).textTheme.bodyLarge?.color,
              fontWeight: FontWeight.bold,
              fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Informational banner
          Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF6C47FF).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF6C47FF).withValues(alpha: 0.2)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline_rounded, color: Color(0xFF6C47FF), size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'To report someone, long-press any message in a chat room and tap "Report User".',
                    style: TextStyle(
                        color: Color(0xFF6C47FF), fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Live Firestore stream of submitted reports
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: FirestoreRoomService.instance.myReportsStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Could not load reports.\n${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF6C47FF)),
                  );
                }

                final reports = snapshot.data ?? [];

                if (reports.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shield_outlined, size: 72, color: Colors.grey.shade300),
                        const SizedBox(height: 20),
                        Text(
                          'No reports yet',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade500),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          child: Text(
                            'Reports you submit in chat rooms will appear here.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: reports.length,
                  itemBuilder: (context, index) =>
                      _buildReportCard(context, reports[index]),
                );
              },
            ),
          ),
        ],
      ),
      // NO FloatingActionButton — reports can only be created from chat
    );
  }

  Widget _buildReportCard(BuildContext context, Map<String, dynamic> report) {
    Color statusColor;
    String statusText = report['status'] ?? 'Pending';
    IconData statusIcon;

    switch (statusText) {
      case 'Resolved':
        statusColor = const Color(0xFF00C48C);
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'Rejected':
        statusColor = const Color(0xFFFF6B6B);
        statusIcon = Icons.cancel_rounded;
        statusText = 'Rejected';
        break;
      case 'Pending':
      default:
        statusColor = const Color(0xFFFFC83D);
        statusIcon = Icons.pending_rounded;
        statusText = 'Under Review';
        break;
    }

    final DateTime submittedAt = report['submittedAt'] is DateTime
        ? report['submittedAt'] as DateTime
        : DateTime.now();
    final String formattedDate =
        '${submittedAt.day}/${submittedAt.month}/${submittedAt.year}';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status badge + date row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 14, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        statusText,
                        style: TextStyle(
                            color: statusColor, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Icon(Icons.calendar_today_rounded, size: 13, color: Colors.grey.shade400),
                    const SizedBox(width: 4),
                    Text(formattedDate,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Reported user
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person_outline_rounded,
                      color: Colors.redAccent, size: 16),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Reported: ${report['reportedHandle'] ?? 'Unknown'}',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Reason
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Reason',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade500)),
                  const SizedBox(height: 4),
                  Text(
                    report['reason'] ?? '—',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
            // Message snippet (if available)
            if ((report['messageText'] as String?)?.isNotEmpty == true) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.12)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Reported message',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade500)),
                    const SizedBox(height: 4),
                    Text(
                      '"${report['messageText']}"',
                      style: const TextStyle(
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                          color: Colors.grey),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
            // Room info
            if ((report['roomId'] as String?)?.isNotEmpty == true) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.meeting_room_rounded,
                      size: 14, color: Colors.grey.shade400),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Room: ${report['roomId']}',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
