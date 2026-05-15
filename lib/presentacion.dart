import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  runApp(const PresentationApp());
}

class PresentationApp extends StatelessWidget {
  const PresentationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Industrial Control',
      theme: ThemeData.dark(),
      home: const SplashScreen(),
    );
  }
}

// ───────────────── SPLASH SCREEN ─────────────────
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  double progress = 0;

  late AnimationController pulseController;
  late AnimationController rotationController;
  late AnimationController particleController;

  String loadingText = "Inicializando";

  @override
  void initState() {
    super.initState();

    pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    startLoading();
    animateLoadingText();
  }

  void animateLoadingText() {
    Timer.periodic(const Duration(milliseconds: 450), (timer) {
      if (!mounted) return;

      setState(() {
        if (loadingText == "Inicializando") {
          loadingText = "Inicializando.";
        } else if (loadingText == "Inicializando.") {
          loadingText = "Inicializando..";
        } else if (loadingText == "Inicializando..") {
          loadingText = "Inicializando...";
        } else {
          loadingText = "Inicializando";
        }
      });

      if (progress >= 1) timer.cancel();
    });
  }

  void startLoading() {
    Timer.periodic(const Duration(milliseconds: 90), (timer) {
      if (!mounted) return;

      setState(() {
        progress += 0.02;
      });

      if (progress >= 1) {
        progress = 1;
        timer.cancel();
        // ── La barra llega al 100 % y la app se queda aquí ──
      }
    });
  }

  @override
  void dispose() {
    pulseController.dispose();
    rotationController.dispose();
    particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050A14),
      body: Stack(
        children: [
          AnimatedBuilder(
            animation: particleController,
            builder: (_, __) => CustomPaint(
              painter: ParticlePainter(particleController.value),
              size: Size.infinite,
            ),
          ),
          const CircuitOverlay(),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(25),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      RotationTransition(
                        turns: rotationController,
                        child: ScaleTransition(
                          scale: Tween<double>(
                            begin: 1,
                            end: 1.08,
                          ).animate(pulseController),
                          child: Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.blueAccent.withValues(alpha: 0.5),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      Colors.blueAccent.withValues(alpha: 0.3),
                                  blurRadius: 30,
                                  spreadRadius: 8,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.precision_manufacturing,
                              size: 90,
                              color: Colors.blueAccent,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      const Text(
                        "INDUSTRIAL CONTROL",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Sistema de monitoreo industrial",
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 35),
                      SizedBox(
                        width: 300,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 10,
                            color: Colors.blueAccent,
                            backgroundColor: Colors.white10,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        "${(progress * 100).toInt()}%",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Text(
                          // Cuando llega al 100 % muestra "Completado"
                          progress >= 1 ? "Completado" : loadingText,
                          key: ValueKey(progress >= 1 ? "done" : loadingText),
                          style: TextStyle(
                            color: progress >= 1
                                ? Colors.blueAccent
                                : Colors.grey[400],
                            fontWeight: progress >= 1
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                      const SizedBox(height: 45),
                      Text(
                        "Proyecto SCADA Industrial",
                        style: TextStyle(
                          color: Colors.grey[500],
                        ),
                      ),
                      Text(
                        "Versión 1.0.0",
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────── PARTICLES ─────────────────
class ParticlePainter extends CustomPainter {
  final double animationValue;

  ParticlePainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(1);

    for (int i = 0; i < 45; i++) {
      final x = random.nextDouble() * size.width;
      final y = ((random.nextDouble() * size.height) + (animationValue * 300)) %
          size.height;

      final radius = random.nextDouble() * 2.5 + 1;

      final paint = Paint()..color = Colors.blueAccent.withValues(alpha: 0.35);

      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ───────────────── CIRCUIT LINES ─────────────────
class CircuitOverlay extends StatelessWidget {
  const CircuitOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            left: 40,
            top: 100,
            child: Container(
              width: 140,
              height: 2,
              color: Colors.blueAccent.withValues(alpha: 0.25),
            ),
          ),
          Positioned(
            right: 50,
            top: 180,
            child: Container(
              width: 2,
              height: 120,
              color: Colors.blueAccent.withValues(alpha: 0.25),
            ),
          ),
          Positioned(
            left: 80,
            bottom: 120,
            child: Container(
              width: 180,
              height: 2,
              color: Colors.blueAccent.withValues(alpha: 0.25),
            ),
          ),
          Positioned(
            right: 100,
            bottom: 180,
            child: Container(
              width: 2,
              height: 90,
              color: Colors.blueAccent.withValues(alpha: 0.25),
            ),
          ),
        ],
      ),
    );
  }
}
