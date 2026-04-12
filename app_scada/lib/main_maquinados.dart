// ============================================================
//  CENTRO DE MAQUINADOS SCADA 4.0  –  Flutter
//  Art. No. TMINL24-A  –  Indexed Line 24V
//  7 Estados · 7 Sensores · 8 Actuadores (M1-M8)
// ============================================================
import 'dart:async';
import 'package:flutter/material.dart';

//void main() => runApp(const ScadaMaquinadosScreen());

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
const Color kMachine = Color(0xFF00FF88); // verde para maquinados

// ── App ───────────────────────────────────────────────────
class ScadaMaquinadosScreen extends StatelessWidget {
  const ScadaMaquinadosScreen({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Centro de Maquinados SCADA 4.0',
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: kBg,
          colorScheme: const ColorScheme.dark(primary: kCyan),
        ),
        home: const ScadaMaquinadosDashboard(),
      );
}

// ── Modelos ───────────────────────────────────────────────
enum LogType { info, audit, error, success }

class LogEntry {
  final String time, user, message;
  final LogType type;
  const LogEntry(this.time, this.user, this.message, this.type);
  Color get color => type == LogType.error
      ? kRed
      : type == LogType.audit
          ? kAudit
          : type == LogType.success
              ? kGreen
              : kText;
}

class SensorModel {
  final String id, label, description;
  bool active;
  SensorModel(this.id, this.label, this.description, {this.active = false});
}

class ActuatorModel {
  final String id, label, description;
  bool on;
  bool disabled;
  ActuatorModel(this.id, this.label, this.description,
      {this.on = false, this.disabled = false});
}

// ── Estados del ciclo (del código MicroPython) ────────────
// EST1: P1 bit0 (val 1)  → M1 enciende banda entrada
// EST2: P2 bit1 (val 2)  → M1 apaga, M2 empuja pieza
// EST3: R1 bit2 (val 4)  → M2 apaga, M3 mueve banda 2
// EST4: P3 bit3 (val 8)  → M3 apaga, M4 fresadora, M3+M6 bandas
// EST5: P4 bit4 (val 16) → M6 apaga, M5 taladro, M7 empuja salida
// EST6: R2 bit5 (val 32) → M7 apaga, M8 banda salida
// EST7: P5 bit6 (val 64) → M8 apaga, ciclo completo
const List<String> kEstados = [
  'Sin iniciar',
  'EST1 · Pieza nueva detectada en P1',
  'EST2 · Pieza en P2 · Empujador 1 activado',
  'EST3 · R1 en reposo · Avanzando a fresadora',
  'EST4 · Pieza en fresadora (P3) · Fresando',
  'EST5 · Pieza en taladradora (P4) · Taladrando',
  'EST6 · R2 en reposo · Banda de salida activa',
  'EST7 · Pieza en salida (P5) · Ciclo completo',
];

// ── Dashboard ─────────────────────────────────────────────
class ScadaMaquinadosDashboard extends StatefulWidget {
  const ScadaMaquinadosDashboard({super.key});
  @override
  State<ScadaMaquinadosDashboard> createState() => _ScadaMaquinadosDashboardState();
}

class _ScadaMaquinadosDashboardState extends State<ScadaMaquinadosDashboard> {
  String _clock = '';
  late Timer _clockTimer;

  String _role = 'Ingeniero';
  String _mode = 'manual';

  bool _isCycleRunning = false;
  int _currentState = 0;
  int _piezas = 0;

  // Sensores (del PDF TMINL24-A Engine Inputs)
  final List<SensorModel> _sensors = [
    SensorModel('P1', 'P1', 'Pieza entrando a línea indexada'),
    SensorModel('P2', 'P2', 'Pieza lista para empujador 1'),
    SensorModel('R1', 'R1', 'Empujador 1 en reposo (home)'),
    SensorModel('P3', 'P3', 'Pieza presente en fresadora'),
    SensorModel('P4', 'P4', 'Pieza presente en taladradora'),
    SensorModel('R2', 'R2', 'Empujador 2 en reposo (home)'),
    SensorModel('P5', 'P5', 'Pieza en área de producto terminado'),
  ];

  // Actuadores (del PDF TMINL24-A Engine Outputs)
  final List<ActuatorModel> _actuators = [
    ActuatorModel('M1', 'M1', 'Banda entrada (Entrance conveyor)'),
    ActuatorModel('M2', 'M2', 'Empujador 1 · Pusher 1 activate'),
    ActuatorModel('M3', 'M3', 'Banda fresadora (Milling conveyor)'),
    ActuatorModel('M4', 'M4', 'Motor fresadora (Milling motor)'),
    ActuatorModel('M5', 'M5', 'Motor taladradora (Drilling motor)'),
    ActuatorModel('M6', 'M6', 'Banda taladradora (Drilling conveyor)'),
    ActuatorModel('M7', 'M7', 'Empujador 2 · Pusher 2 activate'),
    ActuatorModel('M8', 'M8', 'Banda salida (Finished product conveyor)'),
  ];

  final List<LogEntry> _logs = [];
  final ScrollController _logScroll = ScrollController();

  SensorModel _sensor(String id) => _sensors.firstWhere((s) => s.id == id);
  ActuatorModel _act(String id) => _actuators.firstWhere((a) => a.id == id);
  bool get _btnAutoEnabled => _mode == 'auto' && !_isCycleRunning;

  @override
  void initState() {
    super.initState();
    _updateClock();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(_updateClock);
    });
    _logAudit('Sistema iniciado · Centro de Maquinados TMINL24-A', LogType.info);
    _logAudit('Configuración cambiada a Modo: $_mode', LogType.audit);
    // R1 y R2 inician en home (activos)
    _sensor('R1').active = true;
    _sensor('R2').active = true;
  }

  void _updateClock() {
    final n = DateTime.now();
    _clock =
        '${n.hour.toString().padLeft(2, '0')}:${n.minute.toString().padLeft(2, '0')}:${n.second.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    _logScroll.dispose();
    super.dispose();
  }

  void _logAudit(String msg, LogType type) {
    final n = DateTime.now();
    final t =
        '${n.hour.toString().padLeft(2, '0')}:${n.minute.toString().padLeft(2, '0')}:${n.second.toString().padLeft(2, '0')}';
    setState(() => _logs.add(LogEntry(t, _role, msg, type)));
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
    _logAudit('Configuración cambiada a Modo: $_mode', LogType.audit);
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
        'Simulación Manual: Sensor ${s.id} forzado a ${s.active ? 'DETECTANDO' : 'LIBRE'}',
        LogType.audit);
  }

  void _toggleActuator(String id, bool val) {
    setState(() => _act(id).on = val);
    if (!_isCycleRunning) {
      _logAudit('Forzó $id a ${val ? 'ENCENDIDO' : 'APAGADO'}', LogType.audit);
    }
  }

  Future<void> _startAutoCycle() async {
    if (_isCycleRunning) return;
    setState(() { _isCycleRunning = true; _currentState = 0; _updatePermissions(); });
    _logAudit('INICIANDO CICLO AUTOMÁTICO DE MAQUINADOS...', LogType.info);

    try {
      // EST1: P1 detectado → M1 banda entrada
      setState(() { _currentState = 1; _sensor('P1').active = true; });
      _logAudit('EST1 · P1 detectado · M1 enciende banda entrada', LogType.info);
      _toggleActuator('M1', true);
      await Future.delayed(const Duration(seconds: 2));
      setState(() => _sensor('P1').active = false);

      // EST2: P2 detectado → M1 apaga, M2 empuja
      setState(() { _currentState = 2; _sensor('P2').active = true; });
      _logAudit('EST2 · P2 detectado · M1 apaga · M2 empuja pieza', LogType.info);
      _toggleActuator('M1', false);
      await Future.delayed(const Duration(milliseconds: 500));
      _toggleActuator('M2', true);
      setState(() => _sensor('R1').active = false);
      _logAudit('M2 ON · Empujador 1 activado', LogType.success);
      await Future.delayed(const Duration(seconds: 2));

      // EST3: R1 detectado → M2 apaga, M3 mueve banda 2
      setState(() { _currentState = 3; _sensor('P2').active = false; });
      _logAudit('EST3 · R1 en reposo · M2 apaga · M3 banda 2 activa', LogType.info);
      _toggleActuator('M2', false);
      setState(() => _sensor('R1').active = true);
      await Future.delayed(const Duration(milliseconds: 500));
      _toggleActuator('M3', true);
      _logAudit('M3 ON · Banda 2 moviendo pieza hacia fresadora', LogType.success);
      await Future.delayed(const Duration(seconds: 2));

      // EST4: P3 detectado → M3 apaga, M4 fresar, M3+M6 avanzar
      setState(() { _currentState = 4; _sensor('P3').active = true; });
      _logAudit('EST4 · P3 detectado · Pieza en fresadora · Fresando...', LogType.info);
      _toggleActuator('M3', false);
      await Future.delayed(const Duration(milliseconds: 500));
      _toggleActuator('M4', true);
      _logAudit('M4 ON · Motor fresadora activo · Fresando pieza', LogType.success);
      await Future.delayed(const Duration(seconds: 2));
      _toggleActuator('M4', false);
      _logAudit('M4 OFF · Fresado completado', LogType.audit);
      await Future.delayed(const Duration(milliseconds: 500));
      _toggleActuator('M3', true);
      _toggleActuator('M6', true);
      setState(() => _sensor('P3').active = false);
      _logAudit('M3+M6 ON · Avanzando pieza hacia taladradora', LogType.success);
      await Future.delayed(const Duration(seconds: 2));

      // EST5: P4 detectado → M5 taladro, M7 empuja salida
      setState(() { _currentState = 5; _sensor('P4').active = true; });
      _logAudit('EST5 · P4 detectado · Pieza en taladradora · Taladrando...', LogType.info);
      _toggleActuator('M3', false);
      _toggleActuator('M6', false);
      await Future.delayed(const Duration(milliseconds: 500));
      _toggleActuator('M5', true);
      _logAudit('M5 ON · Motor taladradora activo · Taladrando pieza', LogType.success);
      await Future.delayed(const Duration(seconds: 2));
      _toggleActuator('M5', false);
      _logAudit('M5 OFF · Taladrado completado', LogType.audit);
      await Future.delayed(const Duration(milliseconds: 500));
      _toggleActuator('M6', true);
      await Future.delayed(const Duration(seconds: 1));
      _toggleActuator('M6', false);
      setState(() { _sensor('P4').active = false; _sensor('R2').active = false; });
      _toggleActuator('M7', true);
      _logAudit('M7 ON · Empujador 2 activado → salida', LogType.success);
      await Future.delayed(const Duration(seconds: 2));

      // EST6: R2 → M7 apaga, M8 banda salida
      setState(() { _currentState = 6; _sensor('R2').active = true; });
      _logAudit('EST6 · R2 en reposo · M7 apaga · M8 banda salida activa', LogType.info);
      _toggleActuator('M7', false);
      await Future.delayed(const Duration(milliseconds: 500));
      _toggleActuator('M8', true);
      _logAudit('M8 ON · Banda de producto terminado activa', LogType.success);
      await Future.delayed(const Duration(seconds: 2));

      // EST7: P5 → M8 apaga, ciclo completo
      setState(() { _currentState = 7; _sensor('P5').active = true; });
      _logAudit('EST7 · P5 detectado · Pieza en área de salida', LogType.info);
      await Future.delayed(const Duration(seconds: 1));
      _toggleActuator('M8', false);
      setState(() { _sensor('P5').active = false; _piezas++; });
      _logAudit('✔ CICLO EXITOSO · Pieza maquinada y contabilizada', LogType.success);

    } catch (e) {
      _logAudit('ERROR en la secuencia automática: $e', LogType.error);
    }

    setState(() { _isCycleRunning = false; _currentState = 0; _updatePermissions(); });
  }

@override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        // 1. Movemos el ScrollView para que envuelva a TODO
        child: SingleChildScrollView( 
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 2. El Header ahora es el primer hijo del scroll
              _buildHeader(), 
              const SizedBox(height: 16),
              
              // 3. Ya NO usamos Expanded aquí
              _buildTopBar(),
              const SizedBox(height: 10),
              //_buildRow1(),
              //const SizedBox(height: 10),
              _buildRow2(),
              const SizedBox(height: 10),
              _buildStateProgress(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() => Container(
        padding: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: kMachine, width: 2))),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('CENTRO DE MAQUINADOS SCADA 4.0',
                  style: TextStyle(color: kMachine, fontSize: 18,
                      fontWeight: FontWeight.bold, letterSpacing: 1.4)),
              Text('Art. No. TMINL24-A  ·  Indexed Line 24V',
                  style: TextStyle(color: kText.withOpacity(0.5), fontSize: 10,
                      letterSpacing: 1)),
            ]),
            Text(_clock, style: const TextStyle(color: kText, fontSize: 14,
                fontFamily: 'monospace')),
          ],
        ),
      );

  Widget _buildTopBar() => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: kPanel, border: Border.all(color: kBorder),
            borderRadius: BorderRadius.circular(8)),
        child: Wrap(spacing: 14, runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _labeledSelect('Rol:', _role, {
              'Ingeniero': 'Ingeniero (Control Total)',
              'Operador': 'Operador',
            }, (v) { setState(() => _role = v!); _updatePermissions(); }),
            _labeledSelect('Modo:', _mode, {
              'manual': 'Manual (Simulación Física)',
              'auto': 'Automático',
            }, (v) { setState(() => _mode = v!); _updatePermissions(); }),
            _labeledSelect('Conexión:', 'sim', {
              'sim': 'Simulación Local',
              'lan': 'Red Local (KC868)',
            }, (_) {}),
            ElevatedButton.icon(
              onPressed: _btnAutoEnabled ? _startAutoCycle : null,
              icon: Icon(_isCycleRunning ? Icons.stop : Icons.play_arrow, size: 16),
              label: Text(_isCycleRunning ? 'Ejecutando...' : 'Iniciar Ciclo Automático'),
              style: ElevatedButton.styleFrom(
                backgroundColor: kGreen, foregroundColor: kBg,
                disabledBackgroundColor: const Color(0xFF333333),
                disabledForegroundColor: const Color(0xFF666666),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => _logAudit('Auditoría exportada.', LogType.audit),
              icon: const Icon(Icons.download, size: 16),
              label: const Text('Exportar Auditoría CSV'),
              style: ElevatedButton.styleFrom(
                backgroundColor: kAudit, foregroundColor: kBg,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
            ),
            _kpiBox('Piezas Terminadas', '$_piezas', kGreen),
            _kpiBox('Eficiencia (OEE)', '100%', kMachine),
          ],
        ),
      );

  Widget _labeledSelect(String lbl, String val, Map<String, String> items,
      ValueChanged<String?> fn) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Text(lbl, style: const TextStyle(color: kText, fontSize: 12)),
        const SizedBox(width: 5),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(color: kBg, border: Border.all(color: kCyan),
              borderRadius: BorderRadius.circular(4)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: val, dropdownColor: kPanel,
              style: const TextStyle(color: kCyan, fontSize: 12),
              icon: const Icon(Icons.arrow_drop_down, color: kCyan, size: 18),
              isDense: true,
              items: items.entries.map((e) =>
                  DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
              onChanged: fn,
            ),
          ),
        ),
      ]);

  Widget _kpiBox(String label, String value, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
            color: color.withOpacity(0.08), border: Border.all(color: color),
            borderRadius: BorderRadius.circular(6)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(label, style: const TextStyle(color: kText, fontSize: 10)),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(color: color, fontSize: 22,
              fontWeight: FontWeight.bold)),
        ]),
      );

  // ── Gemelo Digital (línea de producción horizontal) ────
  Widget _buildDigitalTwin() {
    return _panel(
      title: 'Gemelo Digital 2D  ·  Línea Indexada',
      titleColor: kMachine,
      height: 230,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: 900,
          height: 170,
          child: Stack(children: [
            // ── Banda entrada ─────────────────────────────
            _dtBand('M1\nEntrada', _act('M1').on, left: 10, top: 100, w: 100),
            _dtSensorDot('P1', _sensor('P1').active, left: 50, top: 80),

            // ── Empujador 1 ───────────────────────────────
            _dtPusher('M2\nEmpujador 1', _act('M2').on, left: 120, top: 50),
            _dtSensorDot('R1', _sensor('R1').active, left: 155, top: 30),

            // ── Banda 2 ───────────────────────────────────
            _dtBand('M3\nBanda 2', _act('M3').on, left: 210, top: 100, w: 110),
            _dtSensorDot('P2', _sensor('P2').active, left: 255, top: 80),

            // ── Fresadora ─────────────────────────────────
            _dtMachine('M4\nFresadora', _act('M4').on, left: 330, top: 30),
            _dtSensorDot('P3', _sensor('P3').active, left: 372, top: 80),

            // ── Banda 3 ───────────────────────────────────
            _dtBand('M6\nBanda 3', _act('M6').on, left: 440, top: 100, w: 100),

            // ── Taladradora ───────────────────────────────
            _dtMachine('M5\nTaladradora', _act('M5').on, left: 550, top: 30),
            _dtSensorDot('P4', _sensor('P4').active, left: 592, top: 80),

            // ── Empujador 2 ───────────────────────────────
            _dtPusher('M7\nEmpujador 2', _act('M7').on, left: 660, top: 50),
            _dtSensorDot('R2', _sensor('R2').active, left: 695, top: 30),

            // ── Banda salida ──────────────────────────────
            _dtBand('M8\nSalida', _act('M8').on, left: 760, top: 100, w: 100),
            _dtSensorDot('P5', _sensor('P5').active, left: 805, top: 80),

            // ── Línea de flujo base ───────────────────────
            Positioned(
              left: 10, top: 130, right: 10,
              child: Container(height: 2, color: kBorder),
            ),

            // ── Flecha dirección ──────────────────────────
            Positioned(
              left: 420, top: 126,
              child: const Icon(Icons.arrow_forward, color: kMachine, size: 18),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _dtBand(String label, bool active, {required double left,
      required double top, double w = 80}) =>
      Positioned(
        left: left, top: top,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: w, height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? kMachine.withOpacity(0.2) : const Color(0xFF1A2233),
            border: Border.all(
                color: active ? kMachine : const Color(0xFF334455), width: 1.5),
            borderRadius: BorderRadius.circular(4),
            boxShadow: active
                ? [BoxShadow(color: kMachine.withOpacity(0.4), blurRadius: 8)]
                : null,
          ),
          child: Text(label, textAlign: TextAlign.center,
              style: TextStyle(
                  color: active ? kMachine : kText.withOpacity(0.4),
                  fontSize: 9, fontWeight: FontWeight.bold)),
        ),
      );

  Widget _dtMachine(String label, bool active,
      {required double left, required double top}) =>
      Positioned(
        left: left, top: top,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 80, height: 70,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? kMachine.withOpacity(0.15) : const Color(0xFF1A2233),
            border: Border.all(
                color: active ? kMachine : const Color(0xFF334455), width: 2),
            borderRadius: BorderRadius.circular(6),
            boxShadow: active
                ? [BoxShadow(color: kMachine.withOpacity(0.5), blurRadius: 12)]
                : null,
          ),
          child: Text(label, textAlign: TextAlign.center,
              style: TextStyle(
                  color: active ? kMachine : kText.withOpacity(0.4),
                  fontSize: 9, fontWeight: FontWeight.bold)),
        ),
      );

  Widget _dtPusher(String label, bool active,
      {required double left, required double top}) =>
      Positioned(
        left: left, top: top,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 55, height: 55,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? kCyan.withOpacity(0.15) : const Color(0xFF1A2233),
            border: Border.all(
                color: active ? kCyan : const Color(0xFF334455), width: 1.5),
            borderRadius: BorderRadius.circular(4),
            boxShadow: active
                ? [BoxShadow(color: kCyan.withOpacity(0.4), blurRadius: 8)]
                : null,
          ),
          child: Text(label, textAlign: TextAlign.center,
              style: TextStyle(
                  color: active ? kCyan : kText.withOpacity(0.4),
                  fontSize: 8, fontWeight: FontWeight.bold)),
        ),
      );

  Widget _dtSensorDot(String id, bool active,
      {required double left, required double top}) =>
      Positioned(
        left: left, top: top,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 24, height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? kGreen.withOpacity(0.2) : Colors.transparent,
            border: Border.all(color: active ? kGreen : const Color(0xFF334455)),
            boxShadow: active
                ? [BoxShadow(color: kGreen.withOpacity(0.7), blurRadius: 8)]
                : null,
          ),
          child: Text(id,
              style: TextStyle(
                  color: active ? kGreen : const Color(0xFF546E7A),
                  fontSize: 7, fontWeight: FontWeight.bold)),
        ),
      );

  // ── Row 2: Sensores + Actuadores + Audit ──────────────
  Widget _buildRow2() => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 220, child: _buildSensorsPanel()),
          const SizedBox(width: 10),
          SizedBox(width: 240, child: _buildActuatorsPanel()),
          const SizedBox(width: 10),
          Expanded(child: _buildAuditPanel()),
        ],
      );

  Widget _buildSensorsPanel() => _panel(
        title: 'Sensores (7)',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: _sensors.map((s) => _sensorRow(s)).toList(),
        ),
      );

  Widget _sensorRow(SensorModel s) {
    final color = s.active ? kGreen : const Color(0xFF333333);
    return GestureDetector(
      onTap: () => _toggleSensor(s.id),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: s.active ? kGreen.withOpacity(0.07) : Colors.black.withOpacity(0.3),
          border: Border.all(
              color: s.active ? kGreen.withOpacity(0.4) : kBorder),
          borderRadius: BorderRadius.circular(4)),
        child: Row(children: [
          Container(width: 8, height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle, color: color,
                boxShadow: s.active
                    ? [BoxShadow(color: color.withOpacity(0.8), blurRadius: 6)]
                    : null)),
          const SizedBox(width: 8),
          Expanded(child: Text('${s.id}: ${s.label}',
              style: TextStyle(color: s.active ? kGreen : kText, fontSize: 11))),
        ]),
      ),
    );
  }

  Widget _buildActuatorsPanel() => _panel(
        title: 'Actuadores (M1–M8)',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: _actuators.map(_actuatorRow).toList(),
        ),
      );

  Widget _actuatorRow(ActuatorModel a) => Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: a.on ? kMachine.withOpacity(0.07) : Colors.black.withOpacity(0.3),
          border: Border.all(color: a.on ? kMachine.withOpacity(0.5) : kBorder),
          borderRadius: BorderRadius.circular(4)),
        child: Row(children: [
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(a.id, style: TextStyle(color: a.on ? kMachine : kText,
                  fontSize: 11, fontWeight: FontWeight.bold)),
              Text(a.description,
                  style: const TextStyle(color: Color(0xFF546E7A), fontSize: 9)),
            ],
          )),
          Transform.scale(
            scale: 0.7,
            child: Switch(
              value: a.on,
              onChanged: a.disabled ? null : (v) => _toggleActuator(a.id, v),
              activeColor: Colors.white,
              activeTrackColor: kMachine,
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: const Color(0xFF333333),
            ),
          ),
        ]),
      );

  Widget _buildAuditPanel() => _panel(
        title: 'Auditoría (Audit Trail) y Alertas',
        child: Container(
          height: 250,
          decoration: BoxDecoration(
              color: kBg, border: Border.all(color: kBorder),
              borderRadius: BorderRadius.circular(4)),
          padding: const EdgeInsets.all(8),
          child: ListView.builder(
            controller: _logScroll,
            itemCount: _logs.length,
            itemBuilder: (_, i) {
              final l = _logs[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: RichText(text: TextSpan(
                  style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                  children: [
                    TextSpan(text: '[${l.time}] ',
                        style: const TextStyle(color: Color(0xFF546E7A))),
                    TextSpan(text: '[${l.user}] - ',
                        style: const TextStyle(color: kCyan)),
                    TextSpan(text: l.message,
                        style: TextStyle(color: l.color)),
                  ],
                )),
              );
            },
          ),
        ),
      );

  // ── Progreso de estados (7 estados) ───────────────────
  Widget _buildStateProgress() => _panel(
        title: 'Progreso del Ciclo  ·  ${kEstados[_currentState]}',
        titleColor: _currentState > 0 ? kMachine : kText,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(
            children: List.generate(7, (i) {
              final state = i + 1;
              final done   = _currentState > state;
              final active = _currentState == state;
              return Expanded(
                child: Column(children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: done ? kGreen : active ? kMachine : kBorder,
                      borderRadius: BorderRadius.circular(3),
                      boxShadow: active
                          ? [BoxShadow(color: kMachine.withOpacity(0.6), blurRadius: 6)]
                          : null),
                  ),
                  const SizedBox(height: 4),
                  Text('E$state',
                      style: TextStyle(
                          color: done ? kGreen : active ? kMachine : const Color(0xFF546E7A),
                          fontSize: 9, fontWeight: FontWeight.bold)),
                ]),
              );
            }),
          ),
        ]),
      );

  Widget _panel({
    required String title,
    required Widget child,
    double? height,
    Color titleColor = kCyan,
  }) =>
      Container(
        height: height,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: kPanel, border: Border.all(color: kBorder),
            borderRadius: BorderRadius.circular(8)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.only(bottom: 8),
              decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: kBorder))),
              child: Text(title, style: TextStyle(color: titleColor,
                  fontSize: 12, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      );
}