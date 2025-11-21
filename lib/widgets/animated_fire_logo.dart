import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'dart:async';

class AnimatedFireLogo extends StatefulWidget {
  final String imagePath;
  final double height;
  final BoxFit fit;

  const AnimatedFireLogo({
    super.key,
    required this.imagePath,
    this.height = 32,
    this.fit = BoxFit.contain,
  });

  @override
  State<AnimatedFireLogo> createState() => _AnimatedFireLogoState();
}

class _AnimatedFireLogoState extends State<AnimatedFireLogo>
    with TickerProviderStateMixin {
  final List<_SparkleParticle> _particles = [];
  Timer? _particleTimer;
  late AnimationController _scaleController;
  late AnimationController _rotationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();

    // Bouncy scale animation - more playful
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.9).chain(
        CurveTween(curve: Curves.easeOut),
      ), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.9, end: 1.05).chain(
        CurveTween(curve: Curves.easeOut),
      ), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.05, end: 1.0).chain(
        CurveTween(curve: Curves.elasticOut),
      ), weight: 1),
    ]).animate(_scaleController);

    // Rotation animation for extra playfulness
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _rotationAnimation = Tween<double>(begin: 0.0, end: 0.1).animate(
      CurvedAnimation(
        parent: _rotationController,
        curve: Curves.elasticOut,
      ),
    );

    // Start particle update timer
    _startParticleTimer();
  }

  void _startParticleTimer() {
    _particleTimer?.cancel();
    _particleTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (mounted) {
        setState(() {
          _particles.removeWhere((particle) => particle.progress >= 1.0);
          for (var particle in _particles) {
            particle.progress += particle.speed * 0.02;
            particle.rotation += particle.rotationSpeed * 0.1;
          }
        });
        
        if (_particles.isEmpty) {
          timer.cancel();
        }
      } else {
        timer.cancel();
      }
    });
  }

  Color _getSparkleColor(double angle) {
    // Create a gradient of colors based on angle for variety
    final normalized = (angle / (2 * math.pi)) % 1.0;
    if (normalized < 0.33) {
      return Colors.orange.shade400;
    } else if (normalized < 0.66) {
      return Colors.amber.shade400;
    } else {
      return Colors.deepOrange.shade400;
    }
  }

  void _triggerAnimation() {
    // Haptic feedback for satisfying tactile response
    HapticFeedback.lightImpact();

    // Bouncy scale animation
    _scaleController.stop();
    _scaleController.reset();
    _scaleController.forward();

    // Playful rotation
    _rotationController.stop();
    _rotationController.reset();
    _rotationController.forward().then((_) {
      if (mounted) {
        _rotationController.reverse();
      }
    });

    // Create cute sparkle particles
    final random = math.Random();
    final particleCount = 8 + random.nextInt(6); // 8-14 sparkles
    
    for (int i = 0; i < particleCount; i++) {
      // Sparkles in all directions
      final angle = random.nextDouble() * 2 * math.pi;
      final distance = 20 + random.nextDouble() * 40;
      final speed = 0.6 + random.nextDouble() * 0.4;
      final rotationSpeed = (random.nextDouble() - 0.5) * 0.3; // Random rotation
      
      _particles.add(_SparkleParticle(
        angle: angle,
        distance: distance,
        speed: speed,
        size: 4 + random.nextDouble() * 5,
        rotationSpeed: rotationSpeed,
        delay: random.nextDouble() * 0.2, // Staggered appearance
      ));
    }

    // Ensure particle timer is running
    if (_particleTimer == null || !_particleTimer!.isActive) {
      _startParticleTimer();
    }
    
    setState(() {});
  }

  @override
  void dispose() {
    _particleTimer?.cancel();
    _particleTimer = null;
    _scaleController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _triggerAnimation,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: Listenable.merge([_scaleController, _rotationController]),
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              // Cute sparkle particles
              ..._particles.map((particle) {
                if (particle.progress < particle.delay) {
                  return const SizedBox.shrink();
                }
                
                final adjustedProgress = (particle.progress - particle.delay) / (1.0 - particle.delay);
                final x = math.cos(particle.angle) * 
                    particle.distance * adjustedProgress;
                final y = math.sin(particle.angle) * 
                    particle.distance * adjustedProgress;
                
                // Twinkling effect
                final opacity = (math.sin(adjustedProgress * math.pi * 4) * 0.3 + 0.7) * 
                    (1.0 - adjustedProgress).clamp(0.0, 1.0);
                final size = particle.size * (1 - adjustedProgress * 0.3);
                final rotation = particle.rotationSpeed * adjustedProgress * math.pi * 2;
                
                return Positioned(
                  left: x - (size / 2),
                  top: y - (size / 2),
                  child: IgnorePointer(
                    child: Opacity(
                      opacity: opacity,
                      child: Transform.rotate(
                        angle: rotation,
                        child: CustomPaint(
                          size: Size(size, size),
                          painter: _SparklePainter(
                            color: _getSparkleColor(particle.angle),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),

              // Logo with bouncy scale and rotation animation
              Transform.rotate(
                angle: _rotationAnimation.value,
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8), // Rounded corners to match container
                    child: Image.asset(
                      widget.imagePath,
                      height: widget.height,
                      fit: widget.fit,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: widget.height,
                          width: widget.height * 2,
                          color: Colors.grey[300],
                          child: const Icon(Icons.image),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SparkleParticle {
  final double angle;
  final double distance;
  final double speed;
  final double size;
  final double rotationSpeed;
  final double delay;
  double progress = 0.0;
  double rotation = 0.0;

  _SparkleParticle({
    required this.angle,
    required this.distance,
    required this.speed,
    required this.size,
    required this.rotationSpeed,
    required this.delay,
  });
}

class _SparklePainter extends CustomPainter {
  final Color color;

  _SparklePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    // Draw a cute star/sparkle shape
    final path = Path();
    final points = 8; // 8-pointed star
    for (int i = 0; i < points * 2; i++) {
      final angle = (i * math.pi) / points;
      final r = i.isEven ? radius : radius * 0.5;
      final x = center.dx + math.cos(angle) * r;
      final y = center.dy + math.sin(angle) * r;
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    
    canvas.drawPath(path, paint);
    
    // Add a bright center
    canvas.drawCircle(center, radius * 0.3, Paint()..color = Colors.white.withOpacity(0.8));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

