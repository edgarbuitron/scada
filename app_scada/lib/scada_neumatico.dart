// ============================================================
// CENTRO NEUMÁTICO SCADA 4.0 -- Flutter
// Exporta: ScadaNeumaticoBoard  (usado por main.dart)
// ============================================================

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

// ── Paleta propia (nombres distintos a main.dart para evitar conflictos) ──
const Color kBg     = Color(0xFF081014);
const Color kPanel  = Color(0xFF11222C);
const Color kCyanN  = Color(0xFF00EAFF);
const Color kGreenN = Color(0xFF00FF88);
const Color kRedN   = Color(0xFFFF3366);
const Color kBorderN= Color(0xFF1A3644);
const Color kText   = Color(0xFFC5D1D8);
const Color kAudit  = Color(0xFFFFAA00);
const Color kDark   = Color(0xFF0C1820);

// ── Modelos internos (privados a este archivo) ────────────────────────────
enum _NLogType { info, audit, error }

class _NLogEntry {
  final String time, role, message;
  final _NLogType type;
  const _NLogEntry(this.time, this.role, this.message, this.type);
  Color get color => type == _NLogType.error
      ? kRedN
      : type == _NLogType.audit
          ? kAudit
          : kText;
}

class _SensorModel {
  final String id, label;
  bool active;
  _SensorModel(this.id, this.label, {this.active = false});
}

class _ActuatorModel {
  final String id, label;
  bool on;
  bool disabled;
  _ActuatorModel(this.id, this.label, {this.on = false, this.disabled = false});
}

// ── Widget público exportado ──────────────────────────────────────────────
class ScadaNeumaticoBoard extends StatefulWidget {
  const ScadaNeumaticoBoard({super.key});

  @override
  State<ScadaNeumaticoBoard> createState() => _ScadaNeumaticoScreenState();
}

class _ScadaNeumaticoScreenState extends State<ScadaNeumaticoBoard> {
  String _clock = '';
  late Timer _clockTimer;
  String _role = 'Ingeniero';
  String _mode = 'manual';
  String _conn = 'sim';
  bool   _isCycleRunning = false;
  double _pressure = 1.0;
  int    _piezas   = 0;

  final List<double> _chartData = List.filled(40, 1.0);

  final List<_SensorModel> _sensors = [
    _SensorModel('P1', 'P1: Input Storage (Pieza)'),
    _SensorModel('P2', 'P2: Conveyor Final (Llegada)'),
    _SensorModel('S1', 'S1: Punching Machine (Pos.)'),
    _SensorModel('S3', 'S3: Turntable Load'),
    _SensorModel('S2', 'S2: PARO EMERGENCIA'),
  ];

  final List<_ActuatorModel> _actuators = [
    _ActuatorModel('M1', 'M1: Compresor Neumático'),
    _ActuatorModel('M2', 'M2: Mesa Giratoria'),
    _ActuatorModel('M3', 'M3: Banda Transportadora'),
    _ActuatorModel('V1', 'V1: Pistón Entrada'),
    _ActuatorModel('V3', 'V3: Perforadora'),
    _ActuatorModel('V4', 'V4: Expulsión'),
  ];

  final List<_NLogEntry> _logs = [];
  final ScrollController _logScroll = ScrollController();

  _SensorModel   _sensor(String id) => _sensors.firstWhere((s) => s.id == id);
  _ActuatorModel _act   (String id) => _actuators.firstWhere((a) => a.id == id);
  bool get _btnAutoEnabled => _mode == 'auto' && !_isCycleRunning;

  @override
  void initState() {
    super.initState();
    _updateClock();
    _clockTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      setState(() {
        _updateClock();
        _simulatePressure();
      });
    });
    _logAudit('Configuración cambiada a Modo: $_mode', _NLogType.audit);
  }

  void _updateClock() {
    final n = DateTime.now();
    _clock = '${n.hour.toString().padLeft(2,'0')}:${n.minute.toString().padLeft(2,'0')}:${n.second.toString().padLeft(2,'0')}';
  }

  void _simulatePressure() {
    if (_act('M1').on) {
      _pressure += 0.2;
    } else {
      _pressure -= 0.05;
    }
    _pressure += (Random().nextDouble() - 0.5) * 0.1;
    _pressure = _pressure.clamp(1.0, 5.0);
    _chartData.removeAt(0);
    _chartData.add(_pressure);
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    _logScroll.dispose();
    super.dispose();
  }

  void _logAudit(String message, _NLogType type) {
    final n    = DateTime.now();
    final time = '${n.hour.toString().padLeft(2,'0')}:${n.minute.toString().padLeft(2,'0')}:${n.second.toString().padLeft(2,'0')}';
    setState(() => _logs.add(_NLogEntry(time, _role, message, type)));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_logScroll.hasClients) {
        _logScroll.animateTo(_logScroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
      }
    });
  }

  void _updatePermissions() {
    for (final a in _actuators) {
      a.disabled = (_role == 'Operador' || _mode == 'auto' || _isCycleRunning);
    }
    _logAudit('Configuración cambiada a Modo: $_mode', _NLogType.audit);
  }

  void _toggleSensor(String id) {
    if (_mode != 'manual') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Cambia el Modo a 'Manual' para simular sensores."),
        backgroundColor: kAudit,
      ));
      return;
    }
    final s = _sensor(id);
    setState(() => s.active = !s.active);
    _logAudit(
        'Simulación Manual: Sensor $id forzado a ${s.active ? 'DETECTANDO' : 'LIBRE'}',
        _NLogType.audit);
  }

  void _toggleActuator(String id, bool val) {
    setState(() => _act(id).on = val);
    if (!_isCycleRunning) {
      _logAudit('Forzó $id a ${val ? 'ENCENDIDO' : 'APAGADO'}', _NLogType.audit);
    }
  }

  Future<void> _startAutoCycle() async {
    if (_isCycleRunning) return;
    if (_pressure < 2.5) {
      _logAudit('Falla de arranque: Presión neumática insuficiente.', _NLogType.error);
      return;
    }
    setState(() { _isCycleRunning = true; _updatePermissions(); });
    _logAudit('INICIANDO PRODUCCIÓN AUTOMÁTICA...', _NLogType.info);
    try {
      _toggleActuator('V1', true);
      setState(() => _sensor('P1').active = false);
      await Future.delayed(const Duration(seconds: 1));
      _toggleActuator('V1', false);
      _toggleActuator('M3', true);
      await Future.delayed(const Duration(milliseconds: 1500));
      setState(() => _sensor('P2').active = true);
      _toggleActuator('M3', false);
      _toggleActuator('M2', true);
      await Future.delayed(const Duration(seconds: 1));
      setState(() => _sensor('S1').active = true);
      _toggleActuator('M2', false);
      _toggleActuator('V3', true);
      await Future.delayed(const Duration(milliseconds: 1500));
      _toggleActuator('V3', false);
      _toggleActuator('V4', true);
      await Future.delayed(const Duration(seconds: 1));
      _toggleActuator('V4', false);
      setState(() {
        _sensor('P2').active = false;
        _sensor('S1').active = false;
        _sensor('P1').active = true;
        _piezas++;
      });
      _logAudit('CICLO EXITOSO. Pieza terminada y contabilizada.', _NLogType.info);
    } catch (_) {
      _logAudit('Error en la secuencia automática.', _NLogType.error);
    }
    setState(() { _isCycleRunning = false; _updatePermissions(); });
  }

  void _triggerEmergency() {
    for (final a in _actuators) {
      setState(() => a.on = false);
    }
    _logAudit('¡PARO DE EMERGENCIA (S2) ACTIVADO! Desconectando energía...', _NLogType.error);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: kPanel,
        title: const Text('📲 NOTIFICACIÓN PUSH AL SUPERVISOR',
            style: TextStyle(color: kRedN, fontSize: 14)),
        content: const Text(
            'Alerta Crítica: Paro de Emergencia presionado en Línea 1.',
            style: TextStyle(color: kText)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: kCyanN)),
          )
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: kBg,
    body: Padding(
      padding: const EdgeInsets.all(12),
      child: SingleChildScrollView( // ✅ TODO SE MUEVE
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            const SizedBox(height: 12),
            _buildTopBar(),
            const SizedBox(height: 12),
            _buildRow1(),
            const SizedBox(height: 12),
            _buildRow2(),
            const SizedBox(height: 12),
            _buildChartPanel(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    ),
  );
}

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader() => Container(
        padding: const EdgeInsets.only(bottom: 10),
        decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: kCyanN, width: 2))),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('CENTRO NEUMÁTICO SCADA 4.0',
                style: TextStyle(
                    color: kCyanN, fontSize: 20,
                    fontWeight: FontWeight.bold, letterSpacing: 1.4)),
            Text(_clock,
                style: const TextStyle(
                    color: kText, fontSize: 14, fontFamily: 'monospace')),
          ],
        ),
      );

  // ── Top bar ───────────────────────────────────────────────────────────────
  Widget _buildTopBar() => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: kPanel,
          border: Border.all(color: kBorderN),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Wrap(
          spacing: 16, runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _labeledSelect('Rol:', _role, {
              'Ingeniero': 'Ingeniero (Control Total)',
              'Operador':  'Operador (Auto/Lectura)',
            }, (v) { setState(() => _role = v!); _updatePermissions(); }),
            _labeledSelect('Modo:', _mode, {
              'manual': 'Manual (Simulación Física)',
              'auto':   'Automático',
            }, (v) { setState(() => _mode = v!); _updatePermissions(); }),
            _labeledSelect('Conexión:', _conn, {
              'sim': 'Simulación Local',
              'ws':  'Hardware Real (WebSocket)',
            }, (v) { setState(() => _conn = v!); }),
            ElevatedButton(
              onPressed: _btnAutoEnabled ? _startAutoCycle : null,
              style: ElevatedButton.styleFrom(
                backgroundColor:         kGreenN,
                disabledBackgroundColor: const Color(0xFF333333),
                disabledForegroundColor: const Color(0xFF666666),
                foregroundColor:         Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              child: const Text('Iniciar Ciclo Automático'),
            ),
            ElevatedButton(
              onPressed: () => _logAudit('Auditoría exportada por el usuario.', _NLogType.audit),
              style: ElevatedButton.styleFrom(
                backgroundColor: kAudit,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              child: const Text('Exportar Auditoría CSV'),
            ),
            _kpiBox('Piezas Terminadas', '$_piezas'),
            _kpiBox('Eficiencia (OEE)',  '100%'),
          ],
        ),
      );

  Widget _labeledSelect(String lbl, String val, Map<String, String> items,
      ValueChanged<String?> onChanged) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Text(lbl, style: const TextStyle(color: kText, fontSize: 13)),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: kBg,
            border: Border.all(color: kCyanN),
            borderRadius: BorderRadius.circular(4),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: val,
              dropdownColor: kPanel,
              style: const TextStyle(color: kCyanN, fontSize: 12),
              icon: const Icon(Icons.arrow_drop_down, color: kCyanN, size: 18),
              isDense: true,
              items: items.entries
                  .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ]);

  Widget _kpiBox(String label, String value) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: kGreenN.withOpacity(0.1),
          border: Border.all(color: kGreenN),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(label, style: const TextStyle(color: kText, fontSize: 11)),
          const SizedBox(height: 2),
          Text(value,
              style: const TextStyle(
                  color: kGreenN, fontSize: 24, fontWeight: FontWeight.bold)),
        ]),
      );

  // ── Row 1: Digital Twin + Sensores ────────────────────────────────────────
  Widget _buildRow1() => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 2, child: _buildDigitalTwin()),
          const SizedBox(width: 12),
          Expanded(child: _buildSensorsPanel()),
        ],
      );

  Widget _buildDigitalTwin() => Container(
        height: 300,
        decoration: BoxDecoration(
          color: kDark,
          border: Border.all(color: kCyanN),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(children: [
          const Positioned(
            top: 10, right: 10,
            child: Text('Gemelo Digital 2D',
                style: TextStyle(
                    color: kCyanN, fontWeight: FontWeight.bold, fontSize: 13)),
          ),
          Positioned(top: 20,  left: 20,  child: _dtPart('M1', 'Compresor\n(M1)',              w: 80,  h: 80,  circle: true)),
          Positioned(top: 100, left: 150, child: _dtPart('V1', 'V1',                            w: 40,  h: 40)),
          Positioned(top: 150, left: 150, child: _dtPart('M3', 'Banda Transportadora (M3)',     w: 200, h: 40)),
          Positioned(top: 60,  right: 80, child: _dtPart('V3', 'V3',                            w: 40,  h: 40)),
          Positioned(top: 120, right: 50, child: _dtPart('M2', 'Mesa\n(M2)',                    w: 100, h: 100, circle: true)),
          Positioned(top: 230, right: 80, child: _dtPart('V4', 'V4',                            w: 40,  h: 40)),
        ]),
      );

  Widget _dtPart(String id, String label, {required double w, required double h, bool circle = false}) {
    bool active = false;
    try { active = _actuators.firstWhere((a) => a.id == id).on; } catch (_) {}
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: w, height: h,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: active ? kGreenN : const Color(0xFF333333),
        border: Border.all(
            color: active ? Colors.white : const Color(0xFF555555), width: 2),
        borderRadius: BorderRadius.circular(circle ? h / 2 : 4),
        boxShadow: active
            ? [BoxShadow(color: kGreenN.withOpacity(0.6), blurRadius: 15)]
            : null,
      ),
      child: Text(label,
          textAlign: TextAlign.center,
          style: TextStyle(
              color: active ? Colors.black : Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildSensorsPanel() => _panel(
        title: 'Sensores (Click para simular en Manual)',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: _sensors.map(_sensorRow).toList(),
        ),
      );

  Widget _sensorRow(_SensorModel s) {
    final bool isEmergency = s.id == 'S2';
    final Color ledColor   = isEmergency && s.active
        ? kRedN
        : (!isEmergency && s.active)
            ? kGreenN
            : const Color(0xFF333333);
    return GestureDetector(
      onTap: () => isEmergency ? _triggerEmergency() : _toggleSensor(s.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(children: [
          Expanded(child: Text(s.label, style: const TextStyle(color: kText, fontSize: 12))),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 14, height: 14,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ledColor,
              boxShadow: s.active
                  ? [BoxShadow(color: ledColor.withOpacity(0.8), blurRadius: 10)]
                  : null,
            ),
          ),
        ]),
      ),
    );
  }

  // ── Row 2: Actuadores + Audit ─────────────────────────────────────────────
  Widget _buildRow2() => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _buildActuatorsPanel()),
          const SizedBox(width: 12),
          Expanded(flex: 2, child: _buildAuditPanel()),
        ],
      );

  Widget _buildActuatorsPanel() => _panel(
        title: 'Actuadores (Motores y Válvulas)',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ..._actuators.sublist(0, 3).map(_actuatorRow),
            const SizedBox(height: 8),
            ..._actuators.sublist(3).map(_actuatorRow),
          ],
        ),
      );

  Widget _actuatorRow(_ActuatorModel a) => Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(children: [
          Expanded(child: Text(a.label, style: const TextStyle(color: kText, fontSize: 12))),
          Transform.scale(
            scale: 0.75,
            child: Switch(
              value: a.on,
              onChanged: a.disabled ? null : (v) => _toggleActuator(a.id, v),
              activeColor:        Colors.white,
              activeTrackColor:   kCyanN,
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: const Color(0xFF333333),
            ),
          ),
        ]),
      );

  Widget _buildAuditPanel() => _panel(
        title: 'Auditoría (Audit Trail) y Alertas',
        child: Container(
          height: 180,
          decoration: BoxDecoration(
            color: kBg,
            border: Border.all(color: kBorderN),
            borderRadius: BorderRadius.circular(4),
          ),
          padding: const EdgeInsets.all(10),
          child: ListView.builder(
            controller: _logScroll,
            itemCount: _logs.length,
            itemBuilder: (_, i) {
              final l = _logs[i];
              return Text(
                '[${l.time}] [${l.role}] - ${l.message}',
                style: TextStyle(
                  color: l.color,
                  fontSize: 11,
                  fontFamily: 'monospace',
                  fontWeight: l.type == _NLogType.audit ? FontWeight.bold : FontWeight.normal,
                ),
              );
            },
          ),
        ),
      );

  // ── Chart ──────────────────────────────────────────────────────────────────
  Widget _buildChartPanel() => _panel(
        title: 'Presión Neumática (Voltaje Analógico)',
        child: SizedBox(
          height: 160,
          child: CustomPaint(painter: _ChartPainter(List.from(_chartData))),
        ),
      );

  // ── Panel wrapper ──────────────────────────────────────────────────────────
  Widget _panel({required String title, required Widget child}) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: kPanel,
          border: Border.all(color: kBorderN),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.only(bottom: 8),
              decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: kBorderN))),
              child: Text(title,
                  style: const TextStyle(
                      color: kCyanN, fontSize: 13, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      );
}

// ── Chart Painter ──────────────────────────────────────────────────────────
class _ChartPainter extends CustomPainter {
  final List<double> data;
  _ChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    const double maxY = 6;
    final gridPaint = Paint()
      ..color      = const Color(0xFF1A3644)
      ..strokeWidth = 0.5;

    for (int i = 0; i <= 6; i++) {
      final y = size.height - (i / maxY) * size.height;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
      final tp = TextPainter(
        text: TextSpan(
            text: '$i',
            style: const TextStyle(color: Color(0xFF546E7A), fontSize: 9)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(2, y - 10));
    }

    if (data.length < 2) return;

    final path = Path();
    for (int i = 0; i < data.length; i++) {
      final x = i / (data.length - 1) * size.width;
      final y = size.height - (data[i] / maxY) * size.height;
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }

    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF00EAFF).withOpacity(0.25),
            const Color(0xFF00EAFF).withOpacity(0.0),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
        ..style = PaintingStyle.fill,
    );

    canvas.drawPath(
      path,
      Paint()
        ..color       = const Color(0xFF00EAFF)
        ..strokeWidth = 2
        ..style       = PaintingStyle.stroke
        ..strokeCap   = StrokeCap.round
        ..strokeJoin  = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _ChartPainter old) => true;
}