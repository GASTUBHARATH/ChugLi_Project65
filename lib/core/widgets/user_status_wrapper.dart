import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserStatusWrapper extends StatelessWidget {
  final Widget child;

  const UserStatusWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        final user = authSnapshot.data;
        if (user == null) return child;

        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return child;
            }

            if (snapshot.hasData && snapshot.data!.exists) {
              final data = snapshot.data!.data() as Map<String, dynamic>;
              final isBanned = data['isBanned'] == true;
              final isSuspended = data['isSuspended'] == true;

              if (isBanned) {
                return _buildOverlay(
                  context,
                  title: 'Account Banned',
                  message:
                      'Your account has been permanently banned due to severe or repeated violations of our community guidelines. You can no longer access Bolbro.',
                  icon: Icons.gavel_rounded,
                  color: Colors.redAccent,
                );
              }

              if (isSuspended) {
                return _buildOverlay(
                  context,
                  title: 'Account Suspended',
                  message:
                      'Your account is temporarily suspended for violating our community guidelines. Please check back later.',
                  icon: Icons.timer_off_outlined,
                  color: Colors.orangeAccent,
                );
              }
            }

            return child;
          },
        );
      },
    );
  }

  Widget _buildOverlay(
    BuildContext context, {
    required String title,
    required String message,
    required IconData icon,
    required Color color,
  }) {
    // We create a standalone scaffold on top of everything
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFF131313),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 80, color: color),
                ),
                const SizedBox(height: 32),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: color,
                    decoration: TextDecoration.none,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                    height: 1.5,
                    decoration: TextDecoration.none,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                Text(
                  'If you think this was a mistake, please contact support.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.5),
                    decoration: TextDecoration.none,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
