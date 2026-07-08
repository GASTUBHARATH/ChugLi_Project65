import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chugli_project65/core/utils/handle_generator.dart';
import 'package:chugli_project65/features/profile/change_handle_screen.dart';
import 'package:chugli_project65/features/profile/interests_screen.dart';
import 'package:chugli_project65/features/notifications/notifications_screen.dart';

import 'package:chugli_project65/features/settings/muted_rooms_screen.dart';
import 'package:chugli_project65/features/info/help_support_screen.dart';
import 'package:chugli_project65/features/info/about_chugli_screen.dart';
import 'package:chugli_project65/features/onboarding/welcome_screen.dart';
import 'package:chugli_project65/core/theme/theme_provider.dart';
import 'package:chugli_project65/data/services/firestore_room_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _currentHandle = 'Loading...';

  @override
  void initState() {
    super.initState();
    _loadCurrentHandle();
  }

  Future<void> _loadCurrentHandle() async {
    try {
      final firestoreHandle =
          await FirestoreRoomService.instance.getUserHandle();
      if (firestoreHandle != null && firestoreHandle.isNotEmpty) {
        if (mounted) setState(() => _currentHandle = firestoreHandle);
        return;
      }
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    final local = prefs.getString('userHandle');
    if (mounted) {
      setState(() =>
          _currentHandle = (local != null && local.isNotEmpty) ? local : 'Anonymous');
    }
  }

  Future<void> _generateNewHandle() async {
    final newHandles = HandleGenerator.generateHandles(1);
    if (newHandles.isEmpty) return;
    final handle = HandleGenerator.textOnly(newHandles.first);

    // Show the new handle with a confirmation snackbar
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('New Handle Generated',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF6C47FF).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                handle,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6C47FF),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Use this as your new anonymous handle?',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C47FF),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Use This Handle',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userHandle', handle);
    try {
      await FirestoreRoomService.instance.saveUserProfile(handle: handle);
    } catch (e) {
      debugPrint('Error saving handle: $e');
    }
    if (mounted) {
      setState(() => _currentHandle = handle);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white),
            const SizedBox(width: 8),
            Text('Handle set to "$handle"'),
          ]),
          backgroundColor: const Color(0xFF6C47FF),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }
  void _deleteAccount() {
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
          'This will permanently delete your account and all data. This action cannot be undone.',
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

    // Show loading
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
      // 1. Delete Firestore Data via Service
      await FirestoreRoomService.instance.deleteAccountData();

      // 2. Clear local SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      // 3. Delete Firebase Auth account
      await user.delete();

      // 4. Ensure a new anonymous session is established
      await FirestoreRoomService.instance.ensureSignedIn();

      if (mounted) {
        // Dismiss loading
        Navigator.pop(context);
        // Navigate to WelcomeScreen
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
        // Anonymous users don't need re-auth, but just in case
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
              _buildSectionTitle('Account'),
              // Current Handle badge
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF6C47FF).withValues(alpha: 0.08),
                      const Color(0xFF7A5CFF).withValues(alpha: 0.04),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: const Color(0xFF6C47FF).withValues(alpha: 0.15)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6C47FF).withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.person_rounded,
                          color: Color(0xFF6C47FF), size: 18),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Your Anonymous Handle',
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                                fontWeight: FontWeight.w500)),
                        Text(
                          _currentHandle,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF6C47FF),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              _buildSettingsCard(context, children: [
                  _buildActionTile('Change Handle', Icons.edit_rounded, onTap: () {
                    Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const ChangeHandleScreen()),
                    ).then((_) => _loadCurrentHandle());
                  }),
                  _buildDivider(),
                  _buildActionTile('Generate New Handle', Icons.auto_awesome_rounded,
                      onTap: _generateNewHandle),
                  _buildDivider(),
                  _buildActionTile('Interests', Icons.favorite_border_rounded, onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const InterestsScreen()));
                  }),
                ],
              ),
              const SizedBox(height: 24),
              
              _buildSectionTitle("Preferences"),
              _buildSettingsCard(context, children: [
                  _buildActionTile("Notifications", Icons.notifications_none_rounded, onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()));
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
                  _buildActionTile("Muted Rooms", Icons.volume_off_outlined, onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const MutedRoomsScreen()));
                  }),
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
                  onPressed: _deleteAccount,
                  icon: Icon(Icons.delete_forever_rounded, color: Colors.red),
                  label: Text(
                    "Delete Account",
                    style: TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    backgroundColor: Colors.red.withValues(alpha: 0.08),
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
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: Column(
          children: children,
        ),
      ),
    );
  }

  Widget _buildActionTile(String title, IconData icon, {VoidCallback? onTap}) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF6C47FF).withValues(alpha: 0.1),
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
          color: const Color(0xFF6C47FF).withValues(alpha: 0.1),
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
        activeThumbColor: Colors.white,
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
