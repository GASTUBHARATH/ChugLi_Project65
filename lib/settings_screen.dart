import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'change_handle_screen.dart';
import 'interests_screen.dart';
import 'notifications_screen.dart';
import 'language_screen.dart';
import 'help_support_screen.dart';
import 'about_chugli_screen.dart';
import 'welcome_screen.dart';
import 'theme_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  void _logout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Log Out', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Log Out', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showEmptyMutedBlocked() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Empty', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('You have no blocked users or muted rooms.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Close', style: TextStyle(color: Color(0xFF6C47FF), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
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
          "Settings",
          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge!.color, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle("Account"),
              _buildSettingsCard(context, children: [
                  _buildActionTile("Change Handle", Icons.person_outline, onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ChangeHandleScreen()));
                  }),
                  _buildDivider(),
                  _buildActionTile("Interests", Icons.favorite_border_rounded, onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const InterestsScreen()));
                  }),
                ],
              ),
              SizedBox(height: 24),
              
              _buildSectionTitle("Preferences"),
              _buildSettingsCard(context, children: [
                  _buildActionTile("Notifications", Icons.notifications_none_rounded, onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()));
                  }),
                  _buildDivider(),
                  _buildActionTile("Language", Icons.language_rounded, onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const LanguageScreen()));
                  }),
                  _buildDivider(),
                  _buildSwitchTile("Dark Mode", Icons.dark_mode_outlined, globalThemeProvider.isDarkMode, (val) {
                    globalThemeProvider.toggleTheme(val);
                  }),
                ],
              ),
              SizedBox(height: 24),

              _buildSectionTitle("Privacy Control"),
              _buildSettingsCard(context, children: [
                  _buildActionTile("Muted Rooms", Icons.volume_off_outlined, onTap: _showEmptyMutedBlocked),
                  _buildDivider(),
                  _buildActionTile("Blocked Users", Icons.block, onTap: _showEmptyMutedBlocked),
                ],
              ),
              SizedBox(height: 24),

              _buildSectionTitle("Support"),
              _buildSettingsCard(context, children: [
                  _buildActionTile("Help & Support", Icons.help_outline_rounded, onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpSupportScreen()));
                  }),
                  _buildDivider(),
                  _buildActionTile("About ChugLi", Icons.info_outline_rounded, onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutChugliScreen()));
                  }),
                ],
              ),
              SizedBox(height: 32),

              Center(
                child: TextButton.icon(
                  onPressed: _logout,
                  icon: Icon(Icons.logout_rounded, color: Colors.redAccent),
                  label: Text(
                    "Log Out",
                    style: TextStyle(color: Colors.redAccent, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    backgroundColor: Colors.redAccent.withOpacity(0.1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                ),
              ),
              SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
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
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildActionTile(String title, IconData icon, {VoidCallback? onTap}) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF6C47FF).withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: const Color(0xFF6C47FF), size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).textTheme.bodyLarge!.color,
        ),
      ),
      trailing: Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 20),
      onTap: () {
        HapticFeedback.selectionClick();
        onTap?.call();
      },
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  Widget _buildSwitchTile(String title, IconData icon, bool value, ValueChanged<bool> onChanged) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF6C47FF).withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: const Color(0xFF6C47FF), size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).textTheme.bodyLarge!.color,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: Colors.white,
        activeTrackColor: const Color(0xFF6C47FF),
        inactiveThumbColor: Colors.white,
        inactiveTrackColor: Colors.grey[300],
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: Colors.grey[100],
      indent: 60,
      endIndent: 20,
    );
  }
}
