import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:chugli_project65/features/info/community_guidelines_screen.dart';
import 'package:chugli_project65/features/reports/reports_history_screen.dart'; // From existing Reports logic
import 'package:chugli_project65/features/info/privacy_detail_screen.dart';

class PrivacySafetyScreen extends StatelessWidget {
  const PrivacySafetyScreen({super.key});

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
          "Privacy & Safety",
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
              _buildSectionTitle("Safety Hub"),
              _buildSettingsCard(context, children: [
                  _buildActionTile("Community Guidelines", Icons.shield_outlined, onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const CommunityGuidelinesScreen()));
                  }),
                  _buildDivider(),
                  _buildActionTile("Report a Problem", Icons.flag_outlined, color: Colors.orange, onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsHistoryScreen()));
                  }),
                ],
              ),
              SizedBox(height: 24),
              
              _buildSectionTitle("Your Data"),
              _buildSettingsCard(context, children: [
                  _buildActionTile("How We Protect You", Icons.lock_outline_rounded, onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyDetailScreen(
                      title: "How We Protect You",
                      content: "We use state-of-the-art encryption to ensure your data is secure. Because ChugLi is an anonymous platform, we never ask for your real name, phone number, or email. Your IP address is hashed, and location data is only used dynamically to find nearby rooms. We do not store historical location data.",
                    )));
                  }),
                  _buildDivider(),
                  _buildActionTile("Data Deletion Policy", Icons.delete_outline_rounded, onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyDetailScreen(
                      title: "Data Deletion",
                      content: "All messages are securely wiped from our servers the moment a room expires. Your device may cache messages locally while the app is running, but nothing is kept permanently. If you delete your account, any remaining active rooms you created will be immediately ended and deleted.",
                    )));
                  }),
                ],
              ),
              SizedBox(height: 32),

              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF6C47FF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF6C47FF).withOpacity(0.3)),
                ),
                child: Center(
                  child: Text(
                    'Your privacy is our priority. We never sell your data.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF6C47FF), fontWeight: FontWeight.bold, fontSize: 14, height: 1.5),
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

  Widget _buildActionTile(String title, IconData icon, {Color? color, VoidCallback? onTap}) {
    final useColor = color ?? const Color(0xFF6C47FF);
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: useColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: useColor, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1A1A1A),
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
