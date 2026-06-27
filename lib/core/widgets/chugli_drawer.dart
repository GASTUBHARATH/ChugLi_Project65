import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chugli_project65/features/onboarding/welcome_screen.dart';
import 'package:chugli_project65/features/profile/change_handle_screen.dart';
import 'package:chugli_project65/features/profile/interests_screen.dart';
import 'package:chugli_project65/features/notifications/notifications_screen.dart';
import 'package:chugli_project65/features/reports/reports_history_screen.dart';
import 'package:chugli_project65/features/rooms/my_rooms_screen.dart';
import 'package:chugli_project65/features/info/how_chugli_works_screen.dart';
import 'package:chugli_project65/features/info/privacy_safety_screen.dart';
import 'package:chugli_project65/features/settings/settings_screen.dart';
import 'package:chugli_project65/features/profile/change_radius_screen.dart';
import 'package:chugli_project65/data/services/firestore_room_service.dart';
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
                    icon: '🚩',
                    title: 'My Reports',
                    subtitle: 'View your report history',
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
          } else if (index == 10) {
            // Delete Account from drawer
            _showDeleteAccountDialog();
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

  void _showDeleteAccountDialog() {
    Navigator.pop(context); // Close drawer first
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 26),
            SizedBox(width: 8),
            Text('Delete Account', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'This will permanently delete your account and all your data. This cannot be undone.',
          style: TextStyle(color: Colors.grey[700]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _performDeleteAccount();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _performDeleteAccount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
          child: CircularProgressIndicator(color: Color(0xFF6C47FF)),
        ),
      );
    }

    try {
      await FirestoreRoomService.instance.deleteAccountData();

      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      await user.delete();

      if (mounted) {
        Navigator.pop(context); // Dismiss loading
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => const WelcomeScreen(showAccountDeletedMessage: true),
          ),
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) Navigator.pop(context); // Dismiss loading
      if (e.code == 'requires-recent-login') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please log out and log back in before deleting.'),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.message}'),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete account: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
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
