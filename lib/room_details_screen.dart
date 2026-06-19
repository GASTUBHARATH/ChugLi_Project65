import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'room_data_service.dart';
import 'room_conversation_screen.dart';
import 'new_report_issue_screen.dart';
import 'notifications_screen.dart';

class RoomDetailsScreen extends StatefulWidget {
  final String roomId;
  const RoomDetailsScreen({super.key, required this.roomId});

  @override
  State<RoomDetailsScreen> createState() => _RoomDetailsScreenState();
}

class _RoomDetailsScreenState extends State<RoomDetailsScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _confirmEndRoom() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('End Room Early?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to end this room? It will be marked as expired immediately and no new messages can be sent.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              RoomDataService.instance.endRoomEarly(widget.roomId);
              HapticFeedback.heavyImpact();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('End Room', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showRoomAnalytics(Map<String, dynamic> room, int messagesCount) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Room Analytics', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              SizedBox(height: 24),
              Row(
                children: [
                  Expanded(child: _buildAnalyticCard('Total Participants', '${room['participants']}', Icons.people)),
                  SizedBox(width: 16),
                  Expanded(child: _buildAnalyticCard('Total Messages', '$messagesCount', Icons.message)),
                ],
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildAnalyticCard('Engagement %', '87%', Icons.trending_up)),
                  SizedBox(width: 16),
                  Expanded(child: _buildAnalyticCard('Avg Time Spent', '14m', Icons.timer)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnalyticCard(String title, String value, IconData icon) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF6C47FF), size: 24),
          SizedBox(height: 12),
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
          SizedBox(height: 4),
          Text(title, style: TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<Map<String, dynamic>>>(
      valueListenable: RoomDataService.instance.roomsNotifier,
      builder: (context, rooms, child) {
        final roomIdx = rooms.indexWhere((r) => r['id'] == widget.roomId);
        if (roomIdx == -1) {
          return const Scaffold(body: Center(child: Text('Room not found')));
        }
        
        final room = rooms[roomIdx];
        
        DateTime createdAt = room['createdAt'] ?? DateTime.now();
        Duration expiryTime = room['expiryTime'] ?? const Duration(hours: 2);
        Duration remaining = createdAt.add(expiryTime).difference(DateTime.now());
        bool isExpired = remaining.isNegative;

        String remainingText = isExpired
            ? 'Expired'
            : remaining.inHours > 0
                ? '${remaining.inHours}h ${remaining.inMinutes.remainder(60)}m'
                : '${remaining.inMinutes}m';

        String category = room['category'] ?? 'Active';
        String emoji = '🔥';
        Color iconBgColor = const Color(0xFFFF7A59);
        
        switch (category) {
          case 'Question': emoji = '❓'; iconBgColor = const Color(0xFF5B8CFF); break;
          case 'Funny': emoji = '😂'; iconBgColor = const Color(0xFFFFC83D); break;
          case 'Help': emoji = '🆘'; iconBgColor = const Color(0xFFFF6B6B); break;
          case 'Networking': emoji = '🤝'; iconBgColor = const Color(0xFF00C48C); break;
          case 'Confession': emoji = '🎤'; iconBgColor = const Color(0xFF8B5CF6); break;
          case 'Food': emoji = '🍕'; iconBgColor = const Color(0xFFFF9F43); break;
        }

        final messages = List.from(room['messages'] ?? []);
        final formattedDate = '${createdAt.day}/${createdAt.month}/${createdAt.year}';
        
        bool isCreator = room['createdBy'] == 'current_user';

        return Scaffold(
          appBar: AppBar(
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_rounded, color: Colors.black87),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text('Room Details', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 20)),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Card
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: iconBgColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Center(child: Text(emoji, style: TextStyle(fontSize: 32))),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              room['title'] ?? 'Room',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87),
                            ),
                            SizedBox(height: 6),
                            Row(
                              children: [
                                Text(category, style: TextStyle(color: iconBgColor, fontSize: 13, fontWeight: FontWeight.bold)),
                                SizedBox(width: 12),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isExpired ? Colors.grey.withOpacity(0.1) : const Color(0xFF00C48C).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    isExpired ? 'Expired' : 'Active',
                                    style: TextStyle(color: isExpired ? Colors.grey.shade700 : const Color(0xFF00C48C), fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
                SizedBox(height: 24),
                
                // Room Info Grid
                Text('Room Info', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                SizedBox(height: 16),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 2.2,
                  children: [
                    _buildInfoTile('Participants', '${room['participants']}', Icons.people_alt_rounded),
                    _buildInfoTile('Messages', '${messages.length}', Icons.chat_bubble_rounded),
                    _buildInfoTile('Time Left', remainingText, Icons.timer_rounded, color: isExpired ? Colors.red : null),
                    _buildInfoTile('Created On', formattedDate, Icons.calendar_today_rounded),
                  ],
                ),
                SizedBox(height: 24),

                // About this room
                Text('About this room', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    room['description']?.isNotEmpty == true ? room['description'] : 'No description provided.',
                    style: TextStyle(color: Colors.black87, fontSize: 14, height: 1.5),
                  ),
                ),
                SizedBox(height: 24),

                // Actions
                Text('Actions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      if (!isExpired)
                        _buildActionTile('Open Room', Icons.open_in_new_rounded, onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => RoomConversationScreen(roomId: widget.roomId)));
                        }),
                      if (isExpired)
                        _buildActionTile('View Summary', Icons.analytics_outlined, color: const Color(0xFF6C47FF), onTap: () {
                          _showRoomAnalytics(room, messages.length);
                        }),
                      const Divider(height: 1),
                      _buildActionTile('Room Analytics', Icons.bar_chart_rounded, onTap: () {
                        _showRoomAnalytics(room, messages.length);
                      }),
                      const Divider(height: 1),
                      _buildActionTile('Mute Notifications', Icons.notifications_off_outlined, onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => NotificationsScreen(
                              roomId: room['id'],
                              roomTitle: room['title'],
                            ),
                          ),
                        );
                      }),
                      const Divider(height: 1),
                      _buildActionTile('Share Room', Icons.share_rounded),
                      const Divider(height: 1),
                      _buildActionTile('Report Room', Icons.flag_rounded, color: Colors.orange, onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => NewReportIssueScreen(room: room),
                          ),
                        );
                      }),
                      if (isCreator && !isExpired) ...[
                        const Divider(height: 1),
                        _buildActionTile('End Room Early', Icons.power_settings_new_rounded, color: Colors.redAccent, onTap: _confirmEndRoom),
                      ]
                    ],
                  ),
                ),
                SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoTile(String title, String value, IconData icon, {Color? color}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: color ?? const Color(0xFF6C47FF), size: 20),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
                Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color ?? Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildActionTile(String title, IconData icon, {Color? color, VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: color ?? Colors.black87),
      title: Text(title, style: TextStyle(color: color ?? Colors.black87, fontWeight: FontWeight.w600)),
      trailing: Icon(Icons.chevron_right_rounded, color: Colors.grey),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      onTap: onTap ?? () {
        HapticFeedback.selectionClick();
      },
    );
  }
}
