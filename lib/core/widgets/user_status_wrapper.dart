import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Listens to the current user's Firestore document for ban/suspend status.
///
/// Converted from nested StreamBuilders to a StatefulWidget with manual
/// subscriptions so that regular document updates (handle, location, etc.)
/// do NOT cause the child widget tree to rebuild — only actual changes to
/// `isBanned` or `isSuspended` trigger a rebuild.
class UserStatusWrapper extends StatefulWidget {
  final Widget child;

  const UserStatusWrapper({super.key, required this.child});

  @override
  State<UserStatusWrapper> createState() => _UserStatusWrapperState();
}

class _UserStatusWrapperState extends State<UserStatusWrapper> {
  StreamSubscription<User?>? _authSub;
  StreamSubscription<DocumentSnapshot>? _userDocSub;

  bool _isBanned = false;
  bool _isSuspended = false;

  @override
  void initState() {
    super.initState();
    _authSub = FirebaseAuth.instance.authStateChanges().listen(_onAuthChanged);
  }

  void _onAuthChanged(User? user) {
    // Cancel any previous Firestore subscription.
    _userDocSub?.cancel();
    _userDocSub = null;

    if (user == null) {
      // No user — reset to normal state.
      if (_isBanned || _isSuspended) {
        setState(() {
          _isBanned = false;
          _isSuspended = false;
        });
      }
      return;
    }

    // Listen to the user's Firestore document.
    _userDocSub = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .listen((snapshot) {
      if (!mounted) return;

      bool banned = false;
      bool suspended = false;

      if (snapshot.exists) {
        final data = snapshot.data();
        if (data != null) {
          banned = data['isBanned'] == true;
          suspended = data['isSuspended'] == true;
        }
      }

      // Only call setState when the ban/suspend status actually changes.
      if (banned != _isBanned || suspended != _isSuspended) {
        setState(() {
          _isBanned = banned;
          _isSuspended = suspended;
        });
      }
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _userDocSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isBanned) {
      return _buildOverlay(
        context,
        title: 'Account Banned',
        message:
            'Your account has been permanently banned due to severe or repeated violations of our community guidelines. You can no longer access Bolbro.',
        icon: Icons.gavel_rounded,
        color: Colors.redAccent,
      );
    }

    if (_isSuspended) {
      return _buildOverlay(
        context,
        title: 'Account Suspended',
        message:
            'Your account is temporarily suspended for violating our community guidelines. Please check back later.',
        icon: Icons.timer_off_outlined,
        color: Colors.orangeAccent,
      );
    }

    return widget.child;
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
