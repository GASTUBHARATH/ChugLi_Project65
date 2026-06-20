import 'package:flutter/material.dart';

class ReportSubmittedScreen extends StatelessWidget {
  const ReportSubmittedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              
              // Success Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: const Color(0xFF00C48C).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF00C48C),
                    size: 80,
                  ),
                ),
              ),
              SizedBox(height: 32),
              
              // Title and Message
              Text(
                'Report Submitted!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Thank you for helping keep ChugLi safe.\nOur moderation team will review this report.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                  height: 1.5,
                ),
              ),
              SizedBox(height: 48),
              
              // Information Card
              Container(
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Column(
                  children: [
                    _buildInfoRow('Report is anonymous'),
                    SizedBox(height: 16),
                    _buildInfoRow('We review reports 24/7'),
                    SizedBox(height: 16),
                    _buildInfoRow('You\'ll be notified of updates'),
                  ],
                ),
              ),
              
              const Spacer(),
              
              // Got It Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Pop back to ReportsHistoryScreen. 
                    // Since the flow is Drawer -> History -> Issue -> Details -> Submitted
                    // We pop until the history screen is the top one.
                    Navigator.popUntil(context, (route) => route.settings.name == '/ReportsHistoryScreen' || route.isFirst);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C47FF),
                    padding: EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 5,
                    shadowColor: const Color(0xFF6C47FF).withOpacity(0.5),
                  ),
                  child: Text(
                    'Got It',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String text) {
    return Row(
      children: [
        Icon(Icons.check_circle_outline_rounded, color: Color(0xFF00C48C), size: 20),
        SizedBox(width: 12),
        Text(
          text,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}
