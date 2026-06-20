import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chugli_project65/features/profile/change_handle_screen.dart';
import 'package:chugli_project65/features/profile/interests_screen.dart';
import 'package:chugli_project65/features/notifications/notifications_screen.dart';
import 'package:chugli_project65/features/reports/reports_history_screen.dart';
import 'package:chugli_project65/features/rooms/my_rooms_screen.dart';
import 'package:chugli_project65/features/info/how_chugli_works_screen.dart';
import 'package:chugli_project65/features/info/privacy_safety_screen.dart';
import 'package:chugli_project65/features/settings/settings_screen.dart';
import 'package:chugli_project65/features/profile/change_radius_screen.dart';
import 'package:chugli_project65/features/activity/recent_activity_screen.dart';

class ChugliDrawer extends StatefulWidget {
  final VoidCallback? onRadiusChanged;

  ChugliDrawer({super.key, this.onRadiusChanged});

  @override
  State<ChugliDrawer> createState() => _ChugliDrawerState();
}

class _ChugliDrawerState extends State<ChugliDrawer> {
  // 1. selectedDrawerIndex variable
  int _selectedDrawerIndex = -1;
  String _userHandle = "Anonymous User";
  String _interestsSubtitle = "None Selected";

  @override
  void initState() {
    super.initState();
    _loadHandle();
  }

  Future<void> _loadHandle() async {
    final prefs = await SharedPreferences.getInstance();
    final handle = prefs.getString('userHandle');
    final interests = prefs.getStringList('selected_interests');
    debugPrint("When loading from drawer: $interests");
    debugPrint("Loaded interests: $interests");
    
    if (mounted) {
      setState(() {
        if (handle != null && handle.isNotEmpty) {
          _userHandle = handle;
        }
        if (interests != null && interests.isNotEmpty) {
          _interestsSubtitle = interests.take(3).join(', ');
        } else {
          _interestsSubtitle = "None Selected";
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.85,
      decoration: BoxDecoration(
        color: Theme.of(context).canvasColor,
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Profile Section
            _buildProfileSection(),
            const Divider(height: 1, color: Color(0xFFF0F0F0)),
            
            // Drawer Items
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                children: [
                  _buildDrawerItem(
                    index: 0,
                    icon: "🎭",
                    title: "Change Handle",
                    subtitle: "Once every 24 hours",
                  ),
                  _buildDrawerItem(
                    index: 1,
                    icon: "📍",
                    title: "Change Radius",
                    subtitle: "0.5km • 1km • 2km • 5km",
                    onTapOverride: () async {
                      final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const ChangeRadiusScreen()));
                      if (result == true && widget.onRadiusChanged != null) {
                        widget.onRadiusChanged!();
                      }
                    },
                  ),
                  _buildDrawerItem(
                    index: 2,
                    icon: "🏷️",
                    title: "Interests",
                    subtitle: _interestsSubtitle,
                  ),
                  _buildDrawerItem(
                    index: 3,
                    icon: "🔔",
                    title: "Notifications",
                  ),
                  _buildDrawerItem(
                    index: 4,
                    icon: "🚪",
                    title: "My Rooms",
                    subtitle: "Created & Joined rooms",
                  ),
                  SizedBox(height: 5),
                  _buildDrawerItem(
                    index: 5,
                    icon: "🚩",
                    title: "Report a Problem",
                    subtitle: "Report content or issues",
                  ),
                  SizedBox(height: 5),
                  _buildDrawerItem(
                    index: 6,
                    icon: "🕒",
                    title: "Recent Activity",
                  ),
                  _buildDrawerItem(
                    index: 7,
                    icon: "❓",
                    title: "How ChugLi Works",
                  ),
                  _buildDrawerItem(
                    index: 8,
                    icon: "🛡️",
                    title: "Privacy & Safety",
                  ),
                  _buildDrawerItem(
                    index: 9,
                    icon: "⚙️",
                    title: "Settings",
                  ),
                  _buildDrawerItem(
                    index: 10,
                    icon: "🗑️",
                    title: "Delete Account",
                    subtitle: "Permanently delete your account",
                    isDestructive: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 2. Drawer item widget with 3. Selection styling logic
  Widget _buildDrawerItem({
    required int index,
    required String icon,
    required String title,
    String? subtitle,
    bool isDestructive = false,
    VoidCallback? onTapOverride,
  }) {
    bool isSelected = _selectedDrawerIndex == index;
    Color primaryColor = const Color(0xFF6C47FF);
    
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        // 4. onTap implementation
        onTap: () {
          if (onTapOverride != null) {
            onTapOverride();
            return;
          }
          setState(() {
            _selectedDrawerIndex = index;
          });
          if (index == 0) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const ChangeHandleScreen())).then((_) => _loadHandle());
          } else if (index == 2) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const InterestsScreen())).then((_) => _loadHandle());
          } else if (index == 3) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()));
          } else if (index == 4) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const MyRoomsScreen()));
          } else if (index == 5) {
            Navigator.push(
              context, 
              MaterialPageRoute(
                builder: (_) => const ReportsHistoryScreen(),
                settings: const RouteSettings(name: '/ReportsHistoryScreen'),
              ),
            );
          } else if (index == 6) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const RecentActivityScreen()));
          } else if (index == 7) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const HowChugLiWorksScreen()));
          } else if (index == 8) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacySafetyScreen()));
          } else if (index == 9) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
          }
        },
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 70,
          padding: EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isSelected ? primaryColor.withOpacity(0.08) : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: isSelected 
                ? Border.all(color: primaryColor, width: 1.5) 
                : Border.all(color: Colors.transparent, width: 1.5),
            boxShadow: isSelected ? [
              BoxShadow(
                color: primaryColor.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ] : [],
          ),
          child: Row(
            children: [
              Text(
                icon,
                style: TextStyle(fontSize: 24),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDestructive 
                            ? (isSelected ? primaryColor : Colors.red) 
                            : (isSelected ? primaryColor : Theme.of(context).textTheme.bodyLarge!.color),
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: isSelected ? primaryColor.withOpacity(0.7) : Colors.grey,
                        ),
                      ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: isSelected ? primaryColor : const Color(0xFFD1D1D1),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
    return Container(
      padding: EdgeInsets.all(20),
      margin: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFF6C47FF), Color(0xFFB39DFF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Center(
              child: Text(
                "👤",
                style: TextStyle(fontSize: 30),
              ),
            ),
          ),
          SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _userHandle,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge!.color,
                ),
              ),
              SizedBox(height: 4),
              Text(
                "Member since Jun 2025",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
