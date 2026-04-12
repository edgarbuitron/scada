// ============================================================\n//  CENTRO DE MAQUINADOS SCADA 4.0  –  Flutter
//  FRESADORA CNC DE 3 EJES
// ============================================================\nimport 'dart:async';
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

// ── Paleta ────────────────────────────────────────────────
const Color kBg      = Color(0xFF081014);
const Color kPanel   = Color(0xFF11222C);
const Color kCyan    = Color(0xFF00EAFF);
const Color kGreen   = Color(0xFF00FF88);
const Color kRed     = Color(0xFFFF3366);
const Color kBorder  = Color(0xFF1A3644);
const Color kText    = Color(0xFFC5D1D8);
const Color kAudit   = Color(0xFFFFAA00);
const Color kDark    = Color(0xFF0C1820);
const Color kMachine = Color(0xFF00EAFF); // Cyan para Maquinados

class ScadaMaquinadosScreen extends StatelessWidget {
  const ScadaMaquinadosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ScadaMaquinadosDashboard(); 
  }
}

// ── Modelos ───────────────────────────────────────────────
enum LogType { info, audit, error, success }

class LogEntry {
  final String time, user, message;
  final LogType type;
  const LogEntry(this.time, this.user, this.message, this.type);
  Color get color => type == LogType.error ? kRed : type == LogType.success ? kGreen : type == LogType.audit ? kAudit : kText;
}

class SensorModel {
  final String id, name, desc;
  const SensorModel(this.id, this.name, this.desc);
}

class ActuatorModel {
  final String id, name, desc;
  final bool active;
  const ActuatorModel(this.id, this.name, this.desc, this.active);
}

// ── Pantalla Principal ────────────────────────────────────
class ScadaMaquinadosDashboard extends StatefulWidget {
  const ScadaMaquinadosDashboard({super.key});
  @override
  State<ScadaMaquinadosDashboard> createState() => _ScadaMaquinadosDashboardState();
}

class _ScadaMaquinadosDashboardState extends State<ScadaMaquinadosDashboard> {
  bool autoMode = false;
  bool isRunning = false;
  String currentStatus = 'SISTEMA LISTO - ESPERANDO PIEZA';
  double progress = 0.0;
  Timer? _cycleTimer;

  // Variables de Animación CNC
  double xPos = 0.5; // 0.0 a 1.0
  double yPos = 0.5; // 0.0 a 1.0
  double zPos = 0.0; // 0.0 (arriba) a 1.0 (abajo)
  bool spindleActive = false;

  // Relés
  bool rly01 = false; // X+
  bool rly02 = false; // X-
  bool rly03 = false; // Y+
  bool rly04 = false; // Y-
  bool rly05 = false; // Z+
  bool rly06 = false; // Z-
  bool rly07 = false; // Husillo (Spindle)
  bool rly08 = false; // Compresor/Refrigerante

  // Sensores (Fresadora CNC)
  final List<SensorModel> _sensors = [
    const SensorModel('I1', 'Límite X', 'Sensor final de carrera Eje X'),
    const SensorModel('I2', 'Límite Y', 'Sensor final de carrera Eje Y'),
    const SensorModel('I3', 'Límite Z', 'Sensor final de carrera Eje Z'),
    const SensorModel('I4', 'Presencia', 'Sensor de pieza en mesa'),
  ];

  // Logs
  final List<LogEntry> _logs = [
    LogEntry('08:00:00', 'Sistema', 'Inicio de turno', LogType.info),
    LogEntry('08:05:12', 'Operador', 'Calibración de ejes completada', LogType.success),
  ];

  final List<String> kEstados = [
    'ESPERANDO PIEZA',
    'MOVIENDO A POSICIÓN X/Y',
    'BAJANDO HERRAMIENTA Z',
    'FRESANDO PIEZA...',
    'RETIRANDO HERRAMIENTA',
    'REGRESANDO A HOME',
  ];

  @override
  void dispose() {
    _cycleTimer?.cancel();
    super.dispose();
  }

  void _addLog(String msg, LogType type) {
    setState(() {
      final now = DateTime.now();
      final time = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
      _logs.insert(0, LogEntry(time, autoMode ? 'Auto' : 'Manual', msg, type));
      if (_logs.length > 30) _logs.removeLast();
    });
  }

  void _toggleAuto() {
    setState(() {
      autoMode = !autoMode;
      _addLog(autoMode ? 'Modo AUTO activado' : 'Modo MANUAL activado', LogType.audit);
      if (!autoMode) _stopCycle();
    });
  }

  void _startCycle() {
    if (!autoMode || isRunning) return;
    setState(() {
      isRunning = true;
      progress = 0.0;
      currentStatus = kEstados[1];
      _addLog('Iniciando ciclo de maquinado', LogType.info);
    });
    _runCycle();
  }

  void _stopCycle() {
    _cycleTimer?.cancel();
    setState(() {
      isRunning = false;
      currentStatus = 'PARADA DE EMERGENCIA / CANCELADO';
      rly01 = rly02 = rly03 = rly04 = rly05 = rly06 = rly07 = rly08 = false;
      spindleActive = false;
      _addLog('Ciclo detenido', LogType.error);
    });
  }

  Future<void> _runCycle() async {
    // 1. Mover X/Y
    setState(() { currentStatus = kEstados[1]; rly01 = true; rly03 = true; });
    for (int i = 0; i <= 20; i++) {
      if (!isRunning) return;
      await Future.delayed(const Duration(milliseconds: 100));
      setState(() { xPos = 0.5 + (i * 0.015); yPos = 0.5 - (i * 0.01); progress = 0.2 * (i / 20); });
    }
    setState(() { rly01 = false; rly03 = false; });

    // 2. Bajar Z
    setState(() { currentStatus = kEstados[2]; rly05 = true; spindleActive = true; rly07 = true; });
    for (int i = 0; i <= 20; i++) {
      if (!isRunning) return;
      await Future.delayed(const Duration(milliseconds: 100));
      setState(() { zPos = (i / 20); progress = 0.2 + 0.2 * (i / 20); });
    }
    setState(() { rly05 = false; });

    // 3. Fresando
    setState(() { currentStatus = kEstados[3]; rly08 = true; }); // Activar refrigerante
    for (int i = 0; i <= 30; i++) {
      if (!isRunning) return;
      await Future.delayed(const Duration(milliseconds: 100));
      setState(() { xPos -= 0.01; progress = 0.4 + 0.3 * (i / 30); });
    }
    setState(() { rly08 = false; });

    // 4. Subir Z
    setState(() { currentStatus = kEstados[4]; rly06 = true; spindleActive = false; rly07 = false; });
    for (int i = 0; i <= 20; i++) {
      if (!isRunning) return;
      await Future.delayed(const Duration(milliseconds: 100));
      setState(() { zPos = 1.0 - (i / 20); progress = 0.7 + 0.15 * (i / 20); });
    }
    setState(() { rly06 = false; });

    // 5. Regresar a Home
    setState(() { currentStatus = kEstados[5]; rly02 = true; rly04 = true; });
    for (int i = 0; i <= 20; i++) {
      if (!isRunning) return;
      await Future.delayed(const Duration(milliseconds: 100));
      setState(() { xPos += 0.01; yPos += 0.01; progress = 0.85 + 0.15 * (i / 20); });
    }
    
    setState(() {
      rly02 = false; rly04 = false;
      isRunning = false;
      xPos = 0.5; yPos = 0.5; zPos = 0.0;
      currentStatus = kEstados[0];
      progress = 1.0;
      _addLog('Pieza maquinada exitosamente', LogType.success);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              
              // El Dibujo de la Fresadora
              Container(
                height: 400,
                decoration: BoxDecoration(
                  color: kPanel,
                  border: Border.all(color: kBorder),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: CustomPaint(
                  painter: MaquinadosPainter(
                    xPos: xPos,
                    yPos: yPos,
                    zPos: zPos,
                    spindleActive: spindleActive,
                    rly07: rly07,
                    rly08: rly08,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              _buildTopBar(),
              const SizedBox(height: 10),
              _buildRow1(),
              const SizedBox(height: 10),
              _buildRow2(),
              const SizedBox(height: 10),
              _buildStateProgress(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('CENTRO DE MAQUINADO', style: TextStyle(color: kMachine, fontSize: 18, fontWeight: FontWeight.bold)),
          Text('Fresadora CNC 3 Ejes - Art. No. TMCAM24-A', style: TextStyle(color: kText, fontSize: 12)),
        ],
      ),
      GestureDetector(
        onTap: _toggleAuto,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: autoMode ? kGreen.withOpacity(0.2) : kAudit.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: autoMode ? kGreen : kAudit),
          ),
          child: Text(autoMode ? 'MODO AUTO' : 'MODO MANUAL',
            style: TextStyle(color: autoMode ? kGreen : kAudit, fontWeight: FontWeight.bold, fontSize: 12)),
        ),
      )
    ],
  );

  Widget _buildTopBar() => Row(
    children: [
      Expanded(
        child: ElevatedButton.icon(
          icon: const Icon(Icons.play_arrow, color: kBg),
          label: const Text('INICIAR CICLO', style: TextStyle(color: kBg, fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(backgroundColor: kGreen, padding: const EdgeInsets.symmetric(vertical: 16)),
          onPressed: _startCycle,
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: ElevatedButton.icon(
          icon: const Icon(Icons.stop, color: kText),
          label: const Text('DETENER', style: TextStyle(color: kText, fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(backgroundColor: kRed.withOpacity(0.2), side: const BorderSide(color: kRed), padding: const EdgeInsets.symmetric(vertical: 16)),
          onPressed: _stopCycle,
        ),
      ),
    ],
  );

  Widget _buildRow1() => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        flex: 1,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: kPanel, border: Border.all(color: kBorder), borderRadius: BorderRadius.circular(8)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('SENSORES DE LÍMITE', style: TextStyle(color: kMachine, fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              ..._sensors.map((s) => _buildSensorRow(s.id, s.name, s.id == 'I4' && isRunning)),
            ],
          ),
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        flex: 1,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: kPanel, border: Border.all(color: kBorder), borderRadius: BorderRadius.circular(8)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('MOTORES (ACTUADORES)', style: TextStyle(color: kMachine, fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              _buildActuatorRow('Q1', 'Motor X+', rly01),
              _buildActuatorRow('Q2', 'Motor X-', rly02),
              _buildActuatorRow('Q3', 'Motor Y+', rly03),
              _buildActuatorRow('Q4', 'Motor Y-', rly04),
              _buildActuatorRow('Q5', 'Motor Z Bajando', rly05),
              _buildActuatorRow('Q7', 'Husillo ON', rly07),
            ],
          ),
        ),
      ),
    ],
  );

  Widget _buildRow2() => Container(
    height: 150,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: kPanel, border: Border.all(color: kBorder), borderRadius: BorderRadius.circular(8)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('REGISTRO DE EVENTOS (LOG)', style: TextStyle(color: kMachine, fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            itemCount: _logs.length,
            itemBuilder: (ctx, i) {
              final l = _logs[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                    children: [
                      TextSpan(text: '[${l.time}] ', style: const TextStyle(color: kText)),
                      TextSpan(text: '<${l.user}> ', style: const TextStyle(color: kCyan)),
                      TextSpan(text: l.message, style: TextStyle(color: l.color)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    ),
  );

  Widget _buildStateProgress() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: kPanel, border: Border.all(color: kBorder), borderRadius: BorderRadius.circular(8)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(currentStatus, style: TextStyle(color: isRunning ? kGreen : kText, fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(value: progress, minHeight: 8, backgroundColor: kBg, color: kMachine),
        ),
      ],
    ),
  );

  Widget _buildSensorRow(String id, String label, bool active) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 12, height: 12,
            decoration: BoxDecoration(shape: BoxShape.circle, color: active ? kGreen : kText.withOpacity(0.2)),
          ),
          const SizedBox(width: 8),
          Text('$id - $label', style: const TextStyle(color: kText, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildActuatorRow(String id, String label, bool active) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: active ? kMachine : kBg, borderRadius: BorderRadius.circular(4), border: Border.all(color: active ? kMachine : kBorder)),
            child: Text(id, style: TextStyle(color: active ? kBg : kText, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: active ? Colors.white : kText, fontSize: 12)),
        ],
      ),
    );
  }
}

// ── PINTOR DE LA FRESADORA CNC ─────────────────────────────
class MaquinadosPainter extends CustomPainter {
  final double xPos;
  final double yPos;
  final double zPos;
  final bool spindleActive;
  final bool rly07;
  final bool rly08;

  MaquinadosPainter({
    required this.xPos,
    required this.yPos,
    required this.zPos,
    required this.spindleActive,
    required this.rly07,
    required this.rly08,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2 + 50;

    // Colores
    final basePaint = Paint()..color = const Color(0xFF2A3A4A)..style = PaintingStyle.fill;
    final strokePaint = Paint()..color = kBorder..style = PaintingStyle.stroke..strokeWidth = 2;
    final tablePaint = Paint()..color = const Color(0xFF445566)..style = PaintingStyle.fill;
    final spindlePaint = Paint()..color = const Color(0xFF8899AA)..style = PaintingStyle.fill;
    final bitPaint = Paint()..color = spindleActive ? kGreen : kText..style = PaintingStyle.fill;

    // Dibujar Estructura (Gantry)
    canvas.drawRect(Rect.fromLTWH(cx - 100, cy - 180, 20, 200), basePaint);
    canvas.drawRect(Rect.fromLTWH(cx + 80, cy - 180, 20, 200), basePaint);
    canvas.drawRect(Rect.fromLTWH(cx - 100, cy - 180, 200, 30), basePaint);

    // Calcular movimiento de la mesa (X, Y)
    double tableX = cx - 60 + ((xPos - 0.5) * 80);
    double tableY = cy - 20 + ((yPos - 0.5) * 20);

    // Dibujar Base y Mesa (Ejes X, Y)
    canvas.drawRect(Rect.fromLTWH(cx - 80, cy, 160, 40), Paint()..color = const Color(0xFF1E2A38));
    canvas.drawRect(Rect.fromLTWH(tableX, tableY, 120, 20), tablePaint);
    canvas.drawRect(Rect.fromLTWH(tableX, tableY, 120, 20), strokePaint);

    // Dibujar Husillo (Eje Z)
    double spindleY = cy - 150 + (zPos * 80);
    canvas.drawRect(Rect.fromLTWH(cx - 15, spindleY, 30, 60), spindlePaint);
    canvas.drawRect(Rect.fromLTWH(cx - 15, spindleY, 30, 60), strokePaint);

    // Dibujar Broca (Herramienta)
    canvas.drawRect(Rect.fromLTWH(cx - 3, spindleY + 60, 6, 20), bitPaint);

    // Efecto visual de Fresado (Refrigerante/Chispas si está encendido)
    if (rly07 || rly08) {
      final glowPaint = Paint()..color = kMachine.withOpacity(0.3)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
      canvas.drawCircle(Offset(cx, spindleY + 80), 15 + (Random().nextDouble() * 5), glowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant MaquinadosPainter oldDelegate) => true;
}