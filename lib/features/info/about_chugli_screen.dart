import 'package:flutter/material.dart';

class AboutChugliScreen extends StatelessWidget {
  const AboutChugliScreen({super.key});

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
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 20),
              Container(
                width: 100,
                height: 100,
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
                child: Center(
                  child: Text("C", style: TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold)),
                ),
              ),
              SizedBox(height: 24),
              Text(
                "ChugLi",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
              ),
              SizedBox(height: 4),
              Text(
                "Version 1.0.0",
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              SizedBox(height: 40),
              
              _buildListTile("Terms of Service", () {}),
              const Divider(height: 1),
              _buildListTile("Privacy Policy", () {}),
              const Divider(height: 1),
              _buildListTile("Open Source Licenses", () {}),
              
              SizedBox(height: 60),
              Text(
                "Made with ❤️ for the community",
                style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 8),
              Text(
                "© 2026 ChugLi Inc.",
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListTile(String title, VoidCallback onTap) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      title: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A)),
      ),
      trailing: Icon(Icons.open_in_new_rounded, color: Colors.grey, size: 20),
      onTap: onTap,
    );
  }
}
