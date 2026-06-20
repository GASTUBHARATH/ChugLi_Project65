import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:chugli_project65/features/home/chugli_flow_screen.dart';

class HowChugLiWorksScreen extends StatelessWidget {
  const HowChugLiWorksScreen({super.key});

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
          'How ChugLi Works',
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
            // Header Card
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
                  BoxShadow(color: const Color(0xFF6C47FF).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'An anonymous, real-time chatting experience with people around you.',
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, height: 1.3),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No names.\nNo profiles.\nJust real conversations.',
                          style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14, fontWeight: FontWeight.w600, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 16),
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.chat_bubble_outline_rounded, color: Colors.white, size: 48),
                  )
                ],
              ),
            ),
            SizedBox(height: 32),

            // The ChugLi Flow
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'The ChugLi Flow',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Theme.of(context).textTheme.bodyLarge?.color),
                ),
                TextButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChugliFlowScreen())),
                  child: Text('Learn More', style: TextStyle(color: Color(0xFF6C47FF), fontWeight: FontWeight.bold)),
                )
              ],
            ),
            SizedBox(height: 16),
            GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ChugliFlowScreen()));
              },
              child: Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Column(
                  children: [
                    _buildFlowStep(context, '1', 'Set Radius', 'Choose how far you want to connect.', Icons.location_on_rounded, Colors.orange),
                    _buildFlowArrow(),
                    _buildFlowStep(context, '2', 'Pick Interests', 'We show rooms based on your interests.', Icons.favorite_rounded, Colors.pink),
                    _buildFlowArrow(),
                    _buildFlowStep(context, '3', 'Join / Create', 'Enter a room or create your own.', Icons.add_circle_rounded, Colors.green),
                    _buildFlowArrow(),
                    _buildFlowStep(context, '4', 'Chat & Connect', 'Have real-time anonymous conversations.', Icons.forum_rounded, const Color(0xFF6C47FF)),
                  ],
                ),
              ),
            ),
            SizedBox(height: 32),

            // Why ChugLi Section
            Text(
              'Why ChugLi',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Theme.of(context).textTheme.bodyLarge?.color),
            ),
            SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.85,
              children: [
                _buildWhyCard(context, '100% Anonymous', 'No names, no profiles, no pressure.', Icons.person_off, const Color(0xFF5B8CFF)),
                _buildWhyCard(context, 'Real-time Rooms', 'Every room expires. Stay in the moment.', Icons.timer_rounded, const Color(0xFFFFC83D)),
                _buildWhyCard(context, 'Location Based', 'Connect with people near you.', Icons.my_location_rounded, const Color(0xFFFF7A59)),
                _buildWhyCard(context, 'Safe & Moderated', 'We keep ChugLi safe for everyone.', Icons.shield_rounded, const Color(0xFF00C48C)),
              ],
            ),
            SizedBox(height: 32),

            // Key Features
            Text(
              'Key Features',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Theme.of(context).textTheme.bodyLarge?.color),
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(
                children: [
                  _buildFeatureRow(context, 'Create or join real-time chat rooms'),
                  const Divider(height: 24),
                  _buildFeatureRow(context, 'Rooms auto-expire after the timer ends'),
                  const Divider(height: 24),
                  _buildFeatureRow(context, 'Report issues and help keep ChugLi safe'),
                  const Divider(height: 24),
                  _buildFeatureRow(context, 'Custom radius & interest-based discovery'),
                  const Divider(height: 24),
                  _buildFeatureRow(context, 'No personal data. Your privacy is our priority.'),
                ],
              ),
            ),
            SizedBox(height: 32),

            // Bottom Card
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF6C47FF).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF6C47FF).withOpacity(0.3)),
              ),
              child: Center(
                child: Text(
                  'ChugLi is built to help you have meaningful conversations — anonymously, safely, and locally.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF6C47FF), fontWeight: FontWeight.bold, fontSize: 14, height: 1.5),
                ),
              ),
            ),
            SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildFlowStep(BuildContext context, String number, String title, String subtitle, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
          child: Center(child: Icon(icon, color: color, size: 24)),
        ),
        SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$number. $title', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).textTheme.bodyLarge?.color)),
              SizedBox(height: 4),
              Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFlowArrow() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(width: 23),
          Icon(Icons.arrow_downward_rounded, color: Colors.grey.shade300, size: 20),
        ],
      ),
    );
  }

  Widget _buildWhyCard(BuildContext context, String title, String subtitle, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 24),
          ),
          const Spacer(),
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Theme.of(context).textTheme.bodyLarge?.color)),
          SizedBox(height: 6),
          Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 12, height: 1.3)),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(BuildContext context, String text) {
    return Row(
      children: [
        Icon(Icons.check_circle_rounded, color: Color(0xFF00C48C), size: 20),
        SizedBox(width: 12),
        Expanded(
          child: Text(text, style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 14, fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }
}
