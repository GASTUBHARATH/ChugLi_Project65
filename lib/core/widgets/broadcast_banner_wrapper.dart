import 'package:flutter/material.dart';
import '../../data/services/fcm_service.dart';

/// Wraps any widget tree and shows a dismissible in-app banner
/// whenever the server sends a broadcast notification (type: "broadcast").
class BroadcastBannerWrapper extends StatefulWidget {
  final Widget child;

  const BroadcastBannerWrapper({super.key, required this.child});

  @override
  State<BroadcastBannerWrapper> createState() => _BroadcastBannerWrapperState();
}

class _BroadcastBannerWrapperState extends State<BroadcastBannerWrapper>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<Offset> _slideAnimation;

  String? _bannerTitle;
  String? _bannerBody;
  bool _visible = false;

  late void Function(String, String) _listener;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    ));

    // Register to receive broadcast notifications from FCMService
    _listener = (title, body) {
      if (!mounted) return;
      setState(() {
        _bannerTitle = title;
        _bannerBody = body;
        _visible = true;
      });
      _animController.forward(from: 0);

      // Auto-dismiss after 6 seconds
      Future.delayed(const Duration(seconds: 6), _dismiss);
    };

    FCMService.instance.addBroadcastListener(_listener);
  }

  @override
  void dispose() {
    FCMService.instance.removeBroadcastListener(_listener);
    _animController.dispose();
    super.dispose();
  }

  void _dismiss() {
    if (!mounted) return;
    _animController.reverse().then((_) {
      if (mounted) {
        setState(() => _visible = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_visible)
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            right: 16,
            child: SlideTransition(
              position: _slideAnimation,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF7B61FF).withValues(alpha: 0.6),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF7B61FF).withValues(alpha: 0.3),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7B61FF).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Text('📣',
                            style: TextStyle(fontSize: 20)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _bannerTitle ?? 'Announcement',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            if (_bannerBody != null &&
                                _bannerBody!.isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Text(
                                _bannerBody!,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.75),
                                  fontSize: 12,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _dismiss,
                        child: Icon(
                          Icons.close,
                          size: 18,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
