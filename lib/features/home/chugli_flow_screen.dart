import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:chugli_project65/features/info/community_guidelines_screen.dart';

class ChugliFlowScreen extends StatelessWidget {
  const ChugliFlowScreen({super.key});

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
          'The ChugLi Flow',
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
            Text(
              'Flow Timeline',
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
                  _buildTimelineItem(context, '1.', 'Set Your Radius', 'Choose a radius (0.5km–5km) to find people around you.', Icons.my_location_rounded, Colors.orange),
                  _buildTimelineItem(context, '2.', 'Pick Your Interests', 'Select topics you care about.', Icons.favorite_rounded, Colors.pink),
                  _buildTimelineItem(context, '3.', 'Join or Create a Room', 'Join an existing room or create your own.', Icons.add_circle_rounded, Colors.green),
                  _buildTimelineItem(context, '4.', 'Chat Anonymously', 'Talk in real time.\nNo names.\nNo profiles.', Icons.forum_rounded, const Color(0xFF6C47FF)),
                  _buildTimelineItem(context, '5.', 'Room Expires', 'Rooms end when the timer is up.', Icons.timer_rounded, const Color(0xFFFFC83D)),
                  _buildTimelineItem(context, '6.', 'Stay Safe', 'Report issues.\nOur moderators keep ChugLi safe.', Icons.shield_rounded, const Color(0xFF00C48C), isLast: true),
                ],
              ),
            ),
            SizedBox(height: 32),

            Text(
              'Things to Remember',
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
                  _buildRememberItem(context, 'You are anonymous.', 'Others cannot see who you are.'),
                  const Divider(height: 24),
                  _buildRememberItem(context, 'Be kind and respect others.', null),
                  const Divider(height: 24),
                  _buildRememberItem(context, 'You can report inappropriate content.', null),
                  const Divider(height: 24),
                  _buildRememberItem(context, 'We never store personal chat data.', null),
                ],
              ),
            ),
            SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  HapticFeedback.selectionClick();
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const CommunityGuidelinesScreen()));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C47FF),
                  padding: EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 5,
                  shadowColor: const Color(0xFF6C47FF).withValues(alpha: 0.5),
                ),
                child: Text(
                  'Read Community Guidelines',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem(BuildContext context, String number, String title, String subtitle, IconData icon, Color color, {bool isLast = false}) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: Center(child: Icon(icon, color: color, size: 24)),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: Colors.grey.shade200,
                  ),
                )
            ],
          ),
          SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 12),
                  Text('$number $title', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).textTheme.bodyLarge?.color)),
                  SizedBox(height: 6),
                  Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 13, height: 1.4)),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildRememberItem(BuildContext context, String title, String? subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.info_outline_rounded, color: Color(0xFF6C47FF), size: 20),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Theme.of(context).textTheme.bodyLarge?.color)),
              if (subtitle != null) ...[
                SizedBox(height: 4),
                Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              ]
            ],
          ),
        ),
      ],
    );
  }
}
