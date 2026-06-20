import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:chugli_project65/features/rooms/room_conversation_screen.dart';
import 'package:chugli_project65/features/reports/reports_history_screen.dart';
import 'package:chugli_project65/features/settings/settings_screen.dart';

class ActivityDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> activity;

  const ActivityDetailsScreen({super.key, required this.activity});

  @override
  Widget build(BuildContext context) {
    final DateTime timestamp = activity['timestamp'] as DateTime;
    final String type = activity['type'] ?? 'Unknown';
    final String action = activity['action'] ?? '';
    final String title = activity['title'] ?? 'Activity Detail';
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Color(0xFF6C47FF), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Activity Details",
          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge!.color, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderCard(context, type, title, action, timestamp),
              SizedBox(height: 24),
              _buildDetailsList(context, timestamp),
              SizedBox(height: 32),
              _buildQuickActions(context, type),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard(BuildContext context, String type, String title, String action, DateTime timestamp) {
    IconData icon;
    Color color;
    switch (type) {
      case 'Room':
        icon = Icons.chat_bubble_outline;
        color = const Color(0xFF6C47FF);
        break;
      case 'Message':
        icon = Icons.message_outlined;
        color = const Color(0xFF00C48C);
        break;
      case 'Report':
        icon = Icons.flag_outlined;
        color = Colors.orange;
        break;
      case 'System':
        icon = Icons.settings_outlined;
        color = Colors.grey;
        break;
      default:
        icon = Icons.info_outline;
        color = Colors.blue;
    }

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      action.toUpperCase(),
                      style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    SizedBox(height: 4),
                    Text(
                      title,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Text(
            DateFormat('MMMM d, yyyy • h:mm a').format(timestamp),
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
          if (activity['preview'] != null && activity['preview'].toString().isNotEmpty) ...[
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withOpacity(0.2)),
              ),
              child: Text(
                '“${activity['preview']}”',
                style: TextStyle(fontStyle: FontStyle.italic, fontSize: 14, color: Theme.of(context).textTheme.bodyLarge!.color),
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildDetailsList(BuildContext context, DateTime timestamp) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Details",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
        ),
        SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2)),
            ],
          ),
          child: Column(
            children: [
              if (activity['handle'] != null) _buildDetailRow("Sender Handle", activity['handle']),
              if (activity['category'] != null) _buildDetailRow("Category", activity['category']),
              _buildDetailRow("Activity Type", activity['type'] ?? 'Unknown'),
              if (activity['roomId'] != null) _buildDetailRow("Related Room ID", activity['roomId']),
              if (activity['reportId'] != null) _buildDetailRow("Related Report ID", activity['reportId']),
              _buildDetailRow("Activity ID", activity['id']),
              _buildDetailRow("Date Recorded", DateFormat('yyyy-MM-dd').format(timestamp)),
              _buildDetailRow("Time Recorded", DateFormat('HH:mm:ss').format(timestamp), isLast: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isLast = false}) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Text(label, style: TextStyle(color: Colors.grey, fontSize: 14)),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  value, 
                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ),
        if (!isLast) Divider(height: 1, indent: 16, endIndent: 16, color: Colors.grey.withOpacity(0.2)),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context, String type) {
    List<Widget> actions = [];

    if (type == 'Room') {
      if (activity['roomId'] != null) {
        actions.add(_buildActionBtn(context, "Open Room", Icons.open_in_new, const Color(0xFF6C47FF), () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => RoomConversationScreen(roomId: activity['roomId'])));
        }));
      }
      actions.add(_buildActionBtn(context, "Mute Room", Icons.volume_off, Colors.grey, () => _showDialog(context, "Mute Room", "Room has been muted.")));
      actions.add(_buildActionBtn(context, "Report Room", Icons.flag, Colors.orange, () => _showDialog(context, "Report Room", "Room has been reported.")));
    } else if (type == 'Message') {
      if (activity['roomId'] != null) {
        actions.add(_buildActionBtn(context, "Open Room", Icons.open_in_new, const Color(0xFF6C47FF), () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => RoomConversationScreen(roomId: activity['roomId'])));
        }));
      }
      actions.add(_buildActionBtn(context, "Report Sender", Icons.flag, Colors.orange, () => _showDialog(context, "Report Sender", "Sender has been reported.")));
      actions.add(_buildActionBtn(context, "Block Sender", Icons.block, Colors.red, () => _showDialog(context, "Block Sender", "Sender has been blocked.")));
    } else if (type == 'Report') {
      actions.add(_buildActionBtn(context, "Open Report History", Icons.history, const Color(0xFF6C47FF), () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsHistoryScreen()));
      }));
    } else if (type == 'System') {
      actions.add(_buildActionBtn(context, "View Settings", Icons.settings, Colors.grey, () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
      }));
    }

    if (actions.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Quick Actions",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
        ),
        SizedBox(height: 12),
        ...actions,
      ],
    );
  }

  Widget _buildActionBtn(BuildContext context, String text, IconData icon, Color color, VoidCallback onTap) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 20),
              SizedBox(width: 16),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color),
                ),
              ),
              Icon(Icons.chevron_right, color: color.withOpacity(0.5)),
            ],
          ),
        ),
      ),
    );
  }

  void _showDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("OK", style: TextStyle(color: const Color(0xFF6C47FF), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
