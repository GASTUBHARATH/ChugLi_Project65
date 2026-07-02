import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chugli_project65/data/services/activity_data_service.dart';

class NotificationsScreen extends StatefulWidget {
  final String? roomId;
  final String? roomTitle;
  
  const NotificationsScreen({super.key, this.roomId, this.roomTitle});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _newMessages = true;
  bool _nearbyRooms = true;
  bool _roomUpdates = true;
  bool _mentionsReplies = true;
  bool _tipsProduct = false;
  bool _quietHours = false;

  // Room Specific Settings
  bool _roomNewMessages = true;
  bool _roomMentions = true;
  bool _roomUpdatesSpecific = true;
  bool _muteRoom = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _newMessages = prefs.getBool('notif_new_messages') ?? true;
      _nearbyRooms = prefs.getBool('notif_nearby_rooms') ?? true;
      _roomUpdates = prefs.getBool('notif_room_updates') ?? true;
      _mentionsReplies = prefs.getBool('notif_mentions') ?? true;
      _tipsProduct = prefs.getBool('notif_tips') ?? false;
      _quietHours = prefs.getBool('notif_quiet_hours') ?? false;
    });
  }

  Future<void> _saveSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
    
    ActivityDataService.instance.addActivity(
      title: 'Notification Settings Changed',
      type: 'System',
      action: 'Settings Updated',
      preview: '$key set to $value',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Color(0xFF6C47FF), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Notifications",
          style: TextStyle(color: Color(0xFF1A1A1A), fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.roomId != null) ...[
                Text(
                  "Room Notifications: ${widget.roomTitle ?? 'Room'}",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                SizedBox(height: 16),
                _buildSettingsCard(context, children: [
                    _buildSwitchTile(
                      "New Messages",
                      _roomNewMessages && !_muteRoom,
                      (val) {
                        if (!_muteRoom) {
                          setState(() => _roomNewMessages = val);
                        }
                      },
                    ),
                    _buildDivider(),
                    _buildSwitchTile(
                      "Mentions & Replies",
                      _roomMentions && !_muteRoom,
                      (val) {
                        if (!_muteRoom) {
                          setState(() => _roomMentions = val);
                        }
                      },
                    ),
                    _buildDivider(),
                    _buildSwitchTile(
                      "Room Updates",
                      _roomUpdatesSpecific && !_muteRoom,
                      (val) {
                        if (!_muteRoom) {
                          setState(() => _roomUpdatesSpecific = val);
                        }
                      },
                    ),
                    _buildDivider(),
                    _buildSwitchTile(
                      "Mute this Room",
                      _muteRoom,
                      (val) {
                        setState(() => _muteRoom = val);
                      },
                    ),
                  ],
                ),
                SizedBox(height: 32),
              ],
              Text(
                "Push Notifications",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              SizedBox(height: 16),
              _buildSettingsCard(context, children: [
                  _buildSwitchTile(
                    "New messages in rooms",
                    _newMessages,
                    (val) {
                      setState(() => _newMessages = val);
                      _saveSetting('notif_new_messages', val);
                    },
                  ),
                  _buildDivider(),
                  _buildSwitchTile(
                    "Nearby rooms",
                    _nearbyRooms,
                    (val) {
                      setState(() => _nearbyRooms = val);
                      _saveSetting('notif_nearby_rooms', val);
                    },
                  ),
                  _buildDivider(),
                  _buildSwitchTile(
                    "Room updates",
                    _roomUpdates,
                    (val) {
                      setState(() => _roomUpdates = val);
                      _saveSetting('notif_room_updates', val);
                    },
                  ),
                  _buildDivider(),
                  _buildSwitchTile(
                    "Mentions & replies",
                    _mentionsReplies,
                    (val) {
                      setState(() => _mentionsReplies = val);
                      _saveSetting('notif_mentions', val);
                    },
                  ),
                  _buildDivider(),
                  _buildSwitchTile(
                    "Tips & product updates",
                    _tipsProduct,
                    (val) {
                      setState(() => _tipsProduct = val);
                      _saveSetting('notif_tips', val);
                    },
                  ),
                ],
              ),
              SizedBox(height: 32),
              Text(
                "Do Not Disturb",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              SizedBox(height: 16),
              _buildSettingsCard(context, children: [
                  _buildSwitchTile(
                    "Quiet Hours",
                    _quietHours,
                    (val) {
                      setState(() => _quietHours = val);
                      _saveSetting('notif_quiet_hours', val);
                    },
                    subtitle: "11:00 PM - 7:00 AM",
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsCard(BuildContext context, {required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildSwitchTile(String title, bool value, ValueChanged<bool> onChanged, {String? subtitle}) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1A1A1A),
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(color: Colors.grey, fontSize: 13),
            )
          : null,
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: Colors.white,
        activeTrackColor: const Color(0xFF6C47FF),
        inactiveThumbColor: Colors.white,
        inactiveTrackColor: Colors.grey[300],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: Colors.grey[100],
      indent: 20,
      endIndent: 20,
    );
  }
}
