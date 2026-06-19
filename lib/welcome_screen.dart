import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'location_permission_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _backgroundController;
  late AnimationController _fadeController;

  late Animation<Alignment> _topAlignment;
  late Animation<Alignment> _bottomAlignment;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Background Gradient Animation
    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat(reverse: true);

    _topAlignment = TweenSequence<Alignment>([
      TweenSequenceItem(
          tween: AlignmentTween(begin: Alignment.topLeft, end: Alignment.topRight),
          weight: 1),
      TweenSequenceItem(
          tween: AlignmentTween(begin: Alignment.topRight, end: Alignment.bottomRight),
          weight: 1),
      TweenSequenceItem(
          tween: AlignmentTween(begin: Alignment.bottomRight, end: Alignment.bottomLeft),
          weight: 1),
      TweenSequenceItem(
          tween: AlignmentTween(begin: Alignment.bottomLeft, end: Alignment.topLeft),
          weight: 1),
    ]).animate(_backgroundController);

    _bottomAlignment = TweenSequence<Alignment>([
      TweenSequenceItem(
          tween: AlignmentTween(begin: Alignment.bottomRight, end: Alignment.bottomLeft),
          weight: 1),
      TweenSequenceItem(
          tween: AlignmentTween(begin: Alignment.bottomLeft, end: Alignment.topLeft),
          weight: 1),
      TweenSequenceItem(
          tween: AlignmentTween(begin: Alignment.topLeft, end: Alignment.topRight),
          weight: 1),
      TweenSequenceItem(
          tween: AlignmentTween(begin: Alignment.topRight, end: Alignment.bottomRight),
          weight: 1),
    ]).animate(_backgroundController);

    // Fade-in Content Animation
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Animated Gradient Background
          AnimatedBuilder(
            animation: _backgroundController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: _topAlignment.value,
                    end: _bottomAlignment.value,
                    colors: const [
                      Color(0xFF6C47FF), // Deep Purple
                      Color(0xFF1B1464), // Midnight Blue
                    ],
                  ),
                ),
              );
            },
          ),
          
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 2. App Logo
                    Padding(
                      padding: EdgeInsets.only(top: 20.0),
                      child: Text(
                        "ChugLi",
                        style: TextStyle(
                          color: Theme.of(context).cardColor,
                          fontSize: 38,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -1,
                        ),
                      ),
                    ),

                    const Spacer(),

                    // 3. New Location Network Illustration
                    const LocationNetworkIllustration(),

                    SizedBox(height: 40),

                    // 4. Headline
                    Center(
                      child: Text(
                        "Discover conversations happening around you.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(context).cardColor,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                      ),
                    ),

                    SizedBox(height: 16),

                    // 5. Subtext
                    Center(
                      child: Text(
                        "No phone number. No email.\nNo real name required.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 16,
                          fontWeight: FontWeight.normal,
                          height: 1.5,
                        ),
                      ),
                    ),

                    const Spacer(),

                    // 6. Bottom CTA Button
                    const _StartNearbyButton(),

                    SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LocationNetworkIllustration extends StatefulWidget {
  const LocationNetworkIllustration({super.key});

  @override
  State<LocationNetworkIllustration> createState() => _LocationNetworkIllustrationState();
}

class _LocationNetworkIllustrationState extends State<LocationNetworkIllustration> with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _ringController;
  
  @override
  void initState() {
    super.initState();
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    
    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _mainController.dispose();
    _ringController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final illustrationHeight = size.height * 0.35;

    return SizedBox(
      height: illustrationHeight,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Futuristic Grid / Radar Circles
          CustomPaint(
            size: Size(size.width, illustrationHeight),
            painter: _RadarBackgroundPainter(),
          ),

          // Expanding Radar Rings
          ...List.generate(3, (index) {
             return _RadarRing(
               controller: _ringController,
               delay: index * 0.33,
             );
          }),
          
          // Small Floating Pins in Network
          _SmallNetworkPin(
            alignment: const Alignment(-0.6, -0.4),
            color: const Color(0xFF6C47FF), // Purple
            delay: 0.2,
            mainController: _mainController,
          ),
          _SmallNetworkPin(
            alignment: const Alignment(0.7, -0.5),
            color: const Color(0xFF4CAF50), // Green
            delay: 0.5,
            mainController: _mainController,
          ),
          _SmallNetworkPin(
            alignment: const Alignment(-0.5, 0.6),
            color: const Color(0xFFFF9800), // Orange
            delay: 0.8,
            mainController: _mainController,
          ),
          _SmallNetworkPin(
            alignment: const Alignment(0.5, 0.4),
            color: const Color(0xFF2196F3), // Blue
            delay: 1.1,
            mainController: _mainController,
          ),

          // Main Center Glow
          AnimatedBuilder(
            animation: _mainController,
            builder: (context, child) {
              final scale = 1.0 + (_mainController.value * 0.15);
              return Container(
                width: 140 * scale,
                height: 140 * scale,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF6B6B).withOpacity(0.2 * (1 - _mainController.value)),
                      blurRadius: 50,
                      spreadRadius: 20,
                    ),
                  ],
                ),
              );
            },
          ),

          // Main Large Pin
          AnimatedBuilder(
            animation: _mainController,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, -15 + (30 * _mainController.value)),
                child: child,
              );
            },
            child: const _MainPin(),
          ),
        ],
      ),
    );
  }
}

class _RadarBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final center = Offset(size.width / 2, size.height / 2);

    // Draw perspective rings
    for (int i = 1; i <= 4; i++) {
      canvas.drawOval(
        Rect.fromCenter(
          center: center,
          width: i * 80.0,
          height: i * 40.0,
        ),
        paint,
      );
    }

    // Draw network lines
    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..strokeWidth = 1;

    canvas.drawLine(center, Offset(center.dx - 100, center.dy - 60), linePaint);
    canvas.drawLine(center, Offset(center.dx + 120, center.dy - 40), linePaint);
    canvas.drawLine(center, Offset(center.dx - 80, center.dy + 80), linePaint);
    canvas.drawLine(center, Offset(center.dx + 90, center.dy + 50), linePaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class _RadarRing extends StatelessWidget {
  final AnimationController controller;
  final double delay;

  const _RadarRing({required this.controller, required this.delay});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        double progress = (controller.value + delay) % 1.0;
        double opacity = (1.0 - progress).clamp(0.0, 1.0);
        double scale = 0.5 + (progress * 2.0);
        
        return Transform.scale(
          scale: scale,
          child: Opacity(
            opacity: opacity,
            child: Container(
              width: 200,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF6C47FF).withOpacity(0.3),
                  width: 2,
                ),
                gradient: RadialGradient(
                   colors: [
                     const Color(0xFF6C47FF).withOpacity(0.1),
                     const Color(0xFF2196F3).withOpacity(0.05),
                     Colors.transparent,
                   ],
                )
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MainPin extends StatelessWidget {
  const _MainPin();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Pin Shadow on ground
        Transform(
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateX(1.2),
          alignment: Alignment.bottomCenter,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
        ),
        // Neon Pin
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF6B6B).withOpacity(0.5),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Icon(
                Icons.location_on,
                size: 90,
                color: Color(0xFFFF6B6B),
              ),
            ),
            // Floating dot
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SmallNetworkPin extends StatelessWidget {
  final Alignment alignment;
  final Color color;
  final double delay;
  final AnimationController mainController;

  const _SmallNetworkPin({
    required this.alignment,
    required this.color,
    required this.delay,
    required this.mainController,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: AnimatedBuilder(
        animation: mainController,
        builder: (context, child) {
          final animationValue = math.sin((mainController.value * 2 * math.pi) + (delay * 10));
          final floatingOffset = animationValue * 8.0;
          
          return Transform.translate(
            offset: Offset(0, floatingOffset),
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.6),
                    blurRadius: 12,
                    spreadRadius: 3,
                  ),
                ],
              ),
              child: Center(
                child: Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _StartNearbyButton extends StatefulWidget {
  const _StartNearbyButton();

  @override
  State<_StartNearbyButton> createState() => _StartNearbyButtonState();
}

class _StartNearbyButtonState extends State<_StartNearbyButton>
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
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
    HapticFeedback.lightImpact();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const LocationPermissionScreen()),
        );
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            color: const Color(0xFFFF6B6B),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF6B6B).withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Center(
            child: Text(
              "Start Nearby",
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
