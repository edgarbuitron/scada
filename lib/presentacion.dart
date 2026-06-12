import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

// ───────────────── APP PRINCIPAL ─────────────────
class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
  late AnimationController gearTopController;
  late AnimationController gearBottomController;
  late AnimationController beltController;

  String loadingText = "Preparando sistema industrial...";

  @override
  void initState() {
    super.initState();

    // PALPITEO SUAVE
    pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
      lowerBound: 0.97,
      upperBound: 1.02,
    )..repeat(reverse: true);

    // ENGRANAJE SUPERIOR
    gearTopController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    // ENGRANAJE INFERIOR
    gearBottomController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    // BANDA TRANSPORTADORA
    beltController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();

    startLoading();
  }

  // ───────────────── CARGA ─────────────────
  void startLoading() {
    Timer.periodic(const Duration(milliseconds: 85), (timer) {
      if (!mounted) return;

      setState(() {
        progress += 0.01;
      });

      // TEXTOS DINAMICOS
      if (progress < 0.30) {
        loadingText = "Empaquetando datos...";
      } else if (progress < 0.70) {
        loadingText = "Transportando módulos...";
      } else if (progress < 1.0) {
        loadingText = "Inicializando SCADA...";
      } else {
        loadingText = "Sistema completado";
      }

      if (progress >= 1) {
        progress = 1;
        timer.cancel();
        beltController.stop();
      }
    });
  }

  @override
  void dispose() {
    pulseController.dispose();
    gearTopController.dispose();
    gearBottomController.dispose();
    beltController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double packagePosition = progress * 260;

    return Scaffold(
      backgroundColor: const Color(0xFF020611),
      body: Stack(
        children: [
          // ───────────────── FONDO ─────────────────
          const CircuitBackground(),

          // ───────────────── CONTENIDO ─────────────────
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(25),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // ───────────────── ENGRANAJES ─────────────────
                    ScaleTransition(
                      scale: pulseController,
                      child: SizedBox(
                        width: 180,
                        height: 180,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // CIRCULO
                            Container(
                              width: 180,
                              height: 180,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.blueAccent.withOpacity(0.4),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.blueAccent.withOpacity(0.25),
                                    blurRadius: 25,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                            ),

                            // ENGRANAJE SUPERIOR
                            Positioned(
                              top: 35,
                              left: 40,
                              child: RotationTransition(
                                turns: Tween<double>(
                                  begin: 0,
                                  end: -1,
                                ).animate(gearTopController),
                                child: Icon(
                                  Icons.settings,
                                  size: 70,
                                  color: Colors.lightBlueAccent.shade200,
                                ),
                              ),
                            ),

                            // ENGRANAJE INFERIOR
                            Positioned(
                              bottom: 30,
                              right: 35,
                              child: RotationTransition(
                                turns: Tween<double>(
                                  begin: 0,
                                  end: 1,
                                ).animate(gearBottomController),
                                child: Icon(
                                  Icons.settings,
                                  size: 85,
                                  color: Colors.blueAccent.shade100,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ───────────────── TITULO ─────────────────
                    const Text(
                      "INDUSTRIAL CONTROL",
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.5,
                        color: Colors.white,
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

                    const SizedBox(height: 30),

                    // ───────────────── BANDA TRANSPORTADORA ─────────────────
                    SizedBox(
                      width: 320,
                      height: 90,
                      child: Stack(
                        alignment: Alignment.bottomCenter,
                        children: [
                          // SOPORTE IZQUIERDO
                          Positioned(
                            left: 0,
                            bottom: 12,
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.grey.shade600,
                                border: Border.all(
                                  color: Colors.blueAccent,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),

                          // SOPORTE DERECHO
                          Positioned(
                            right: 0,
                            bottom: 12,
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.grey.shade600,
                                border: Border.all(
                                  color: Colors.blueAccent,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                          
                          // BANDA
                          Positioned(
                            bottom: 20,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                width: 300,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF596170),
                                  border: Border.all(
                                    color: Colors.blueGrey.shade900,
                                    width: 2,
                                  ),
                                ),
                                child: Stack(
                                  children: [
                                    // Progreso coloreado de la banda
                                    AnimatedContainer(
                                      duration: const Duration(milliseconds: 80),
                                      width: 300 * progress,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.blueAccent.shade700,
                                            Colors.lightBlueAccent,
                                          ],
                                        ),
                                      ),
                                    ),
                                    // Patrón de la banda
                                    AnimatedBuilder(
                                      animation: beltController,
                                      builder: (context, child) {
                                        return Transform.translate(
                                          offset: Offset(
                                            -30 * beltController.value,
                                            0,
                                          ),
                                          child: CustomPaint(
                                            painter: BeltPainter(),
                                            size: const Size(600, 20),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // PAQUETE
                          Positioned(
                            left: packagePosition,
                            bottom: 28,
                            child: Container(
                              width: 45,
                              height: 45,
                              decoration: BoxDecoration(
                                color: const Color(0xFFd39a52),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: const Color(0xFF8f5d24),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.35),
                                    blurRadius: 8,
                                    offset: const Offset(2, 4),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Container(
                                  width: 10,
                                  color: const Color(0xFF8f5d24),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 15),

                    // ───────────────── TEXTO PROGRESO ─────────────────
                    Text(
                      "${(progress * 100).toInt()}%",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),

                    const SizedBox(height: 10),

                    // ───────────────── TEXTO ESTADO ─────────────────
                    Text(
                      loadingText,
                      style: TextStyle(
                        color: progress >= 1
                            ? Colors.lightBlueAccent
                            : Colors.grey[400],
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 30),

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
        ],
      ),
    );
  }
}

// ───────────────── PINTOR BANDA ─────────────────
class BeltPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.18);

    for (double i = 0; i < size.width; i += 30) {
      canvas.drawRect(
        Rect.fromLTWH(i, 0, 15, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

// ───────────────── FONDO TECNOLOGICO ─────────────────
class CircuitBackground extends StatelessWidget {
  const CircuitBackground({super.key});

  Widget buildLine({
    double? left,
    double? right,
    required double top,
    required double width,
    required double height,
    bool vertical = false,
  }) {
    return Positioned(
      left: left,
      right: right,
      top: top,
      child: Container(
        width: vertical ? 2 : width,
        height: vertical ? height : 2,
        decoration: BoxDecoration(
          color: Colors.blueAccent.withOpacity(0.22),
          boxShadow: [
            BoxShadow(
              color: Colors.blueAccent.withOpacity(0.15),
              blurRadius: 8,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          buildLine(left: 0, top: 80, width: 180, height: 2),
          buildLine(left: 120, top: 80, width: 2, height: 140, vertical: true),
          buildLine(left: 120, top: 220, width: 180, height: 2),

          buildLine(left: 250, top: 40, width: 2, height: 180, vertical: true),
          buildLine(left: 250, top: 220, width: 120, height: 2),

          buildLine(left: 20, top: 420, width: 200, height: 2),
          buildLine(left: 220, top: 420, width: 2, height: 160, vertical: true),

          buildLine(left: 60, top: 620, width: 220, height: 2),
          buildLine(left: 280, top: 620, width: 2, height: 140, vertical: true),

          buildLine(left: 40, top: 850, width: 180, height: 2),
          buildLine(left: 220, top: 850, width: 2, height: 120, vertical: true),

          buildLine(left: 180, top: 1000, width: 180, height: 2),
          buildLine(left: 340, top: 930, width: 2, height: 160, vertical: true),

          // Right lines
          buildLine(right: 0, top: 80, width: 180, height: 2),
          buildLine(right: 120, top: 80, width: 2, height: 140, vertical: true),
          buildLine(right: 120, top: 220, width: 180, height: 2),

          buildLine(right: 250, top: 40, width: 2, height: 180, vertical: true),
          buildLine(right: 250, top: 220, width: 120, height: 2),

          buildLine(right: 20, top: 420, width: 200, height: 2),
          buildLine(right: 220, top: 420, width: 2, height: 160, vertical: true),

          buildLine(right: 60, top: 620, width: 220, height: 2),
          buildLine(right: 280, top: 620, width: 2, height: 140, vertical: true),

          buildLine(right: 40, top: 850, width: 180, height: 2),
          buildLine(right: 220, top: 850, width: 2, height: 120, vertical: true),

          buildLine(right: 180, top: 1000, width: 180, height: 2),
          buildLine(right: 340, top: 930, width: 2, height: 160, vertical: true),
        ],
      ),
    );
  }
}