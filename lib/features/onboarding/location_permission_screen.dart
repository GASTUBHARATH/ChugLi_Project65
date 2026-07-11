import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'package:chugli_project65/data/services/location_service.dart';
import 'package:chugli_project65/features/onboarding/anonymous_handle_screen.dart';

class LocationPermissionScreen extends StatefulWidget {
  const LocationPermissionScreen({super.key});

  @override
  State<LocationPermissionScreen> createState() => _LocationPermissionScreenState();
}

class _LocationPermissionScreenState extends State<LocationPermissionScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _handlePermissionRequest() async {
    HapticFeedback.mediumImpact();

    final result = await LocationService.instance.getCurrentLocation();

    if (!mounted) return;

    if (result.status == LocationStatus.deniedForever) {
      // Show dialog asking user to open settings
      _showOpenSettingsDialog();
      return;
    }

    if (result.status == LocationStatus.serviceDisabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enable Location Services in your device settings.'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      await LocationService.instance.openSettings();
      return;
    }

    // Whether granted or simply denied, proceed to next screen.
    _navigateToNext();
  }

  void _navigateToNext() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AnonymousHandleScreen()),
    );
  }

  void _showOpenSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          "Location Blocked",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        content: const Text(
          "Location access is blocked. Please go to Settings → Zippi → Location and set it to \"While Using\".",
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _navigateToNext();
            },
            child: const Text(
              "Skip",
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              LocationService.instance.openSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C47FF),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: const Text("Open Settings"),
          ),
        ],
      ),
    );
  }

  void _showSkipDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          "Location Recommended",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        content: Text(
          "Without location access nearby conversations may not be accurate.",
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
        actionsPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _navigateToNext();
            },
            child: Text(
              "Continue Anyway",
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _handlePermissionRequest();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C47FF),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: Text("Allow Location"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                const Spacer(flex: 2),
                
                // 1. Premium Illustration
                const _LocationPermissionIllustration(),
                
                const Spacer(),

                // 2. Text Content
                Text(
                  "See what is happening\nwithin 1 km",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                    height: 1.2,
                    letterSpacing: -0.5,
                  ),
                ),
                
                SizedBox(height: 16),
                
                Text(
                  "Only approximate location is used.\nWe never track your exact position.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                    height: 1.5,
                  ),
                ),

                const Spacer(flex: 2),

                // 3. Action Buttons
                _AnimatedButton(
                  text: "Allow Location",
                  color: const Color(0xFF6C47FF),
                  onPressed: _handlePermissionRequest,
                ),

                SizedBox(height: 8),

                TextButton(
                  onPressed: _showSkipDialog,
                  style: TextButton.styleFrom(foregroundColor: Colors.grey),
                  child: Text(
                    "Maybe Later",
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                  ),
                ),
                
                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LocationPermissionIllustration extends StatefulWidget {
  const _LocationPermissionIllustration();

  @override
  State<_LocationPermissionIllustration> createState() => __LocationPermissionIllustrationState();
}

class __LocationPermissionIllustrationState extends State<_LocationPermissionIllustration>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _mainController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return SizedBox(
      height: size.height * 0.35,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background Map Rings
          CustomPaint(
            size: Size(size.width, size.height * 0.35),
            painter: _MapBasePainter(),
          ),

          // Pulsing Waves
          ...List.generate(3, (index) {
            return _PulseWave(
              controller: _pulseController,
              delay: index * 0.33,
            );
          }),

          // Surrounding Pins
          _NetworkPin(
            alignment: const Alignment(-0.6, -0.4),
            color: const Color(0xFF6C47FF), // Purple
            controller: _mainController,
            delay: 0.0,
          ),
          _NetworkPin(
            alignment: const Alignment(0.65, -0.3),
            color: const Color(0xFF4CAF50), // Green
            controller: _mainController,
            delay: 0.5,
          ),
          _NetworkPin(
            alignment: const Alignment(-0.55, 0.5),
            color: const Color(0xFFFF9800), // Orange
            controller: _mainController,
            delay: 1.0,
          ),
          _NetworkPin(
            alignment: const Alignment(0.7, 0.4),
            color: const Color(0xFF2196F3), // Blue
            controller: _mainController,
            delay: 1.5,
          ),

          // Main Pin Shadow
          Positioned(
            bottom: 60,
            child: AnimatedBuilder(
              animation: _mainController,
              builder: (context, child) {
                return Container(
                  width: 40 + (10 * _mainController.value),
                  height: 10,
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Main Center Pin
          AnimatedBuilder(
            animation: _mainController,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, -10 + (20 * _mainController.value)),
                child: const _MainHeroPin(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _MapBasePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (var i = 1; i <= 4; i++) {
      paint.color = Colors.black.withValues(alpha: 0.02 * i);
      canvas.drawOval(
        Rect.fromCenter(
          center: center,
          width: size.width * (0.2 * i + 0.1),
          height: size.height * (0.15 * i + 0.05),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PulseWave extends StatelessWidget {
  final AnimationController controller;
  final double delay;

  const _PulseWave({required this.controller, required this.delay});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        double progress = (controller.value + delay) % 1.0;
        return Opacity(
          opacity: (1.0 - progress).clamp(0.0, 1.0),
          child: Transform.scale(
            scale: 0.5 + (progress * 2.5),
            child: Container(
              width: 200,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF6C47FF).withValues(alpha: 0.15),
                  width: 1.5,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _NetworkPin extends StatelessWidget {
  final Alignment alignment;
  final Color color;
  final AnimationController controller;
  final double delay;

  const _NetworkPin({
    required this.alignment,
    required this.color,
    required this.controller,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, child) {
          final t = (controller.value + (delay / 4)) % 1.0;
          final offset = math.sin(t * math.pi * 2) * 8.0;
          return Transform.translate(
            offset: Offset(0, offset),
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 8, spreadRadius: 1),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MainHeroPin extends StatelessWidget {
  const _MainHeroPin();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Icon(
          Icons.location_on,
          size: 90,
          color: const Color(0xFFFF6B6B),
          shadows: [
            Shadow(color: const Color(0xFFFF6B6B).withValues(alpha: 0.8), blurRadius: 20),
          ],
        ),
        Positioned(
          top: 24,
          child: Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }
}

class _AnimatedButton extends StatefulWidget {
  final String text;
  final Color color;
  final VoidCallback onPressed;

  const _AnimatedButton({
    required this.text,
    required this.color,
    required this.onPressed,
  });

  @override
  State<_AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<_AnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (details) => _controller.forward(),
      onTapUp: (details) {
        _controller.reverse();
        widget.onPressed();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            color: widget.color,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Center(
            child: Text(
              widget.text,
              style: TextStyle(
                color: Theme.of(context).cardColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
