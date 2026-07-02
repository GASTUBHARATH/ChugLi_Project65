import 'package:flutter/material.dart';

class CommunityGuidelinesScreen extends StatelessWidget {
  const CommunityGuidelinesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: Theme.of(context).textTheme.bodyLarge?.color),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Community Guidelines',
          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6C47FF), Color(0xFFB39DFF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: const Color(0xFF6C47FF).withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8))
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Help us keep ChugLi safe, fun, and respectful for everyone.',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, height: 1.3),
                    ),
                  ),
                  SizedBox(width: 16),
                  Icon(Icons.shield_rounded, color: Colors.white, size: 48),
                ],
              ),
            ),
            SizedBox(height: 32),

            Text(
              'Our Rules',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Theme.of(context).textTheme.bodyLarge?.color),
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(
                children: [
                  _buildGuidelineItem(context, 'Respect Others', 'Treat everyone with kindness.', Icons.people_rounded),
                  const Divider(height: 24),
                  _buildGuidelineItem(context, 'No Harassment', 'Bullying or intimidating behavior will not be tolerated.', Icons.block_rounded),
                  const Divider(height: 24),
                  _buildGuidelineItem(context, 'No Hate Speech', 'Any form of hate speech is strictly prohibited.', Icons.gavel_rounded),
                  const Divider(height: 24),
                  _buildGuidelineItem(context, 'No Spam', 'Do not send unsolicited promotional content.', Icons.report_gmailerrorred_rounded),
                  const Divider(height: 24),
                  _buildGuidelineItem(context, 'No Impersonation', 'Do not pretend to be someone else.', Icons.masks_rounded),
                  const Divider(height: 24),
                  _buildGuidelineItem(context, 'Report Problems Responsibly', 'Use the reporting tools to help moderators.', Icons.flag_rounded),
                  const Divider(height: 24),
                  _buildGuidelineItem(context, 'Stay Anonymous', 'Do not share personal identifying information.', Icons.visibility_off_rounded),
                  const Divider(height: 24),
                  _buildGuidelineItem(context, 'Use ChugLi Respectfully', 'Contribute positively to the community.', Icons.favorite_rounded),
                ],
              ),
            ),
            SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildGuidelineItem(BuildContext context, String title, String subtitle, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF6C47FF).withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: const Color(0xFF6C47FF), size: 20),
        ),
        SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).textTheme.bodyLarge?.color)),
              SizedBox(height: 4),
              Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 13, height: 1.4)),
            ],
          ),
        ),
      ],
    );
  }
}
