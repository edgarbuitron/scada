// ============================================================
//  ROBOT 3 EJES SCADA 4.0  –  Flutter
//  Art. No. TM3DR24-A  –  3D Robot 24V
//  8 Relés de salida · 6 Sensores (encoders + referencias)
//  Secuencia: Rotar Base → Expandir Brazo → Eje Z → Gripper
// ============================================================
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

void main() => runApp(const ScadaApp());

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
const Color kMachine = Color(0xFFFF3366); // rojo para robot

// ── App ───────────────────────────────────────────────────
class ScadaApp extends StatelessWidget {
  const ScadaApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Robot 3 Ejes SCADA 4.0',
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: kBg,
          colorScheme: const ColorScheme.dark(primary: kCyan),
        ),
        home: const ScadaDashboard(),
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
  int pulseCount;
  SensorModel(this.id, this.label, this.description,
      {this.active = false, this.pulseCount = 0});
}

class ActuatorModel {
  final String id, label, description;
  bool on;
  bool disabled;
  ActuatorModel(this.id, this.label, this.description,
      {this.on = false, this.disabled = false});
}

// ── Secuencia del robot (TM3DR24-A)
// RLY01 Base CW / RLY02 Base CCW
// RLY03 Expandir brazo / RLY04 Retraer brazo
// RLY05 Eje Z arriba / RLY06 Eje Z abajo
// RLY07 Abrir gripper / RLY08 Cerrar gripper
const List<String> kEstados = [
  'Sin iniciar',
  'EST1 · Girando base (CW) a posición objetivo',
  'EST2 · Expandiendo brazo gripper',
  'EST3 · Eje Z bajando a posición de agarre',
  'EST4 · Cerrando gripper · Tomando pieza',
  'EST5 · Eje Z subiendo con pieza',
  'EST6 · Girando base (CCW) a posición destino',
  'EST7 · Eje Z bajando · Depositando pieza',
  'EST8 · Abriendo gripper · Liberando pieza',
];

// ── Dashboard ─────────────────────────────────────────────
class ScadaDashboard extends StatefulWidget {
  const ScadaDashboard({super.key});
  @override
  State<ScadaDashboard> createState() => _ScadaDashboardState();
}

class _ScadaDashboardState extends State<ScadaDashboard>
    with SingleTickerProviderStateMixin {
  String _clock = '';
  late Timer _clockTimer;
  late AnimationController _rotAnim;
  Timer? _pulseTimer;

  String _role = 'Ingeniero';
  String _mode = 'manual';

  bool _isCycleRunning = false;
  int _currentState = 0;
  int _piezas = 0;

  // Posición animada del robot (grados de rotación base)
  double _baseAngle = 0;
  double _armExtend = 0; // 0.0 = retractado, 1.0 = extendido
  double _zPosition = 0; // 0.0 = arriba, 1.0 = abajo
  bool _gripperClosed = false;

  // Sensores (del PDF TM3DR24-A Engine Inputs)
  final List<SensorModel> _sensors = [
    SensorModel('S2', 'Encoder XY', 'Encoder CH-X,Y base giratoria'),
    SensorModel('S3', 'Ref Base',   'Posición referencia base giratoria'),
    SensorModel('S4', 'Cnt Brazo',  'Contador pulsos brazo gripper'),
    SensorModel('S6', 'Ref Eje Z',  'Posición referencia eje vertical Z'),
    SensorModel('S7', 'Enc Eje Z',  'Encoder CH-X,Y eje vertical'),
    SensorModel('S8', 'Ref Grip',   'Posición referencia gripper'),
  ];

  // Actuadores (del PDF TM3DR24-A Engine Outputs / Relay Modules)
  final List<ActuatorModel> _actuators = [
    ActuatorModel('RLY01', 'RLY01', 'Base giratoria → CW (horario)'),
    ActuatorModel('RLY02', 'RLY02', 'Base giratoria → CCW (antihorario)'),
    ActuatorModel('RLY03', 'RLY03', 'Expandir brazo gripper'),
    ActuatorModel('RLY04', 'RLY04', 'Retraer brazo gripper'),
    ActuatorModel('RLY05', 'RLY05', 'Eje vertical Z → Posición arriba'),
    ActuatorModel('RLY06', 'RLY06', 'Eje vertical Z → Posición abajo'),
    ActuatorModel('RLY07', 'RLY07', 'Abrir gripper'),
    ActuatorModel('RLY08', 'RLY08', 'Cerrar gripper'),
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
    _rotAnim = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 800));
    _logAudit('Sistema iniciado · Robot 3 Ejes TM3DR24-A', LogType.info);
    _logAudit('Configuración cambiada a Modo: $_mode', LogType.audit);
    // S3, S6, S8 inician en posición de referencia
    _sensor('S3').active = true;
    _sensor('S6').active = true;
    _sensor('S8').active = true;
  }

  void _updateClock() {
    final n = DateTime.now();
    _clock =
        '${n.hour.toString().padLeft(2, '0')}:${n.minute.toString().padLeft(2, '0')}:${n.second.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    _pulseTimer?.cancel();
    _logScroll.dispose();
    _rotAnim.dispose();
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
    _updateRobotVisuals(id, val);
    if (!_isCycleRunning) {
      _logAudit('Forzó $id a ${val ? 'ENCENDIDO' : 'APAGADO'}', LogType.audit);
    }
  }

  // Actualiza la animación del robot según el actuador
  void _updateRobotVisuals(String id, bool val) {
    setState(() {
      switch (id) {
        case 'RLY01': if (val) _baseAngle = (_baseAngle + 45) % 360; break;
        case 'RLY02': if (val) _baseAngle = (_baseAngle - 45 + 360) % 360; break;
        case 'RLY03': _armExtend = val ? 1.0 : _armExtend; break;
        case 'RLY04': _armExtend = val ? 0.0 : _armExtend; break;
        case 'RLY05': _zPosition = val ? 0.0 : _zPosition; break;
        case 'RLY06': _zPosition = val ? 1.0 : _zPosition; break;
        case 'RLY07': _gripperClosed = false; break;
        case 'RLY08': _gripperClosed = true; break;
      }
    });
  }

  // ── Ciclo automático pick & place ──────────────────────
  Future<void> _startAutoCycle() async {
    if (_isCycleRunning) return;
    setState(() { _isCycleRunning = true; _currentState = 0; _updatePermissions(); });
    _logAudit('INICIANDO CICLO AUTOMÁTICO · Pick & Place', LogType.info);

    try {
      // EST1: Girar base CW
      setState(() { _currentState = 1; _sensor('S3').active = false; });
      _logAudit('EST1 · RLY01 ON · Base girando CW a posición objetivo', LogType.info);
      _toggleActuator('RLY01', true);
      await Future.delayed(const Duration(milliseconds: 500));
      setState(() => _baseAngle = 90);
      await Future.delayed(const Duration(seconds: 2));
      _toggleActuator('RLY01', false);
      setState(() { _sensor('S3').active = true; _sensor('S2').active = true; });
      _logAudit('RLY01 OFF · Base en posición objetivo', LogType.audit);

      // EST2: Expandir brazo
      setState(() { _currentState = 2; _sensor('S4').active = true; });
      _logAudit('EST2 · RLY03 ON · Expandiendo brazo gripper', LogType.info);
      _toggleActuator('RLY03', true);
      setState(() => _armExtend = 1.0);
      await Future.delayed(const Duration(seconds: 2));
      _toggleActuator('RLY03', false);
      _logAudit('RLY03 OFF · Brazo extendido', LogType.audit);

      // EST3: Eje Z bajar
      setState(() { _currentState = 3; _sensor('S6').active = false; });
      _logAudit('EST3 · RLY06 ON · Eje Z bajando a posición de agarre', LogType.info);
      _toggleActuator('RLY06', true);
      setState(() => _zPosition = 1.0);
      await Future.delayed(const Duration(seconds: 2));
      _toggleActuator('RLY06', false);
      _logAudit('RLY06 OFF · Eje Z en posición de agarre', LogType.audit);

      // EST4: Cerrar gripper
      setState(() { _currentState = 4; _sensor('S8').active = false; });
      _logAudit('EST4 · RLY08 ON · Cerrando gripper · Tomando pieza', LogType.success);
      _toggleActuator('RLY08', true);
      setState(() => _gripperClosed = true);
      await Future.delayed(const Duration(seconds: 1));
      _toggleActuator('RLY08', false);
      _logAudit('Gripper cerrado · Pieza asegurada', LogType.success);

      // EST5: Eje Z subir
      setState(() { _currentState = 5; });
      _logAudit('EST5 · RLY05 ON · Eje Z subiendo con pieza', LogType.info);
      _toggleActuator('RLY05', true);
      setState(() => _zPosition = 0.0);
      await Future.delayed(const Duration(seconds: 2));
      _toggleActuator('RLY05', false);
      setState(() => _sensor('S6').active = true);
      _logAudit('RLY05 OFF · Eje Z en posición alta', LogType.audit);

      // EST6: Girar base CCW a destino
      setState(() { _currentState = 6; _sensor('S3').active = false; });
      _logAudit('EST6 · RLY02 ON · Base girando CCW a posición destino', LogType.info);
      _toggleActuator('RLY02', true);
      setState(() => _baseAngle = 0);
      await Future.delayed(const Duration(seconds: 2));
      _toggleActuator('RLY02', false);
      setState(() { _sensor('S3').active = true; _sensor('S2').active = false; });
      _logAudit('RLY02 OFF · Base en posición de depósito', LogType.audit);

      // EST7: Eje Z bajar para depositar
      setState(() { _currentState = 7; _sensor('S6').active = false; });
      _logAudit('EST7 · RLY06 ON · Eje Z bajando · Depositando pieza', LogType.info);
      _toggleActuator('RLY06', true);
      setState(() => _zPosition = 1.0);
      await Future.delayed(const Duration(seconds: 2));
      _toggleActuator('RLY06', false);
      _logAudit('RLY06 OFF · Pieza en posición de depósito', LogType.audit);

      // EST8: Abrir gripper
      setState(() { _currentState = 8; });
      _logAudit('EST8 · RLY07 ON · Abriendo gripper · Liberando pieza', LogType.success);
      _toggleActuator('RLY07', true);
      setState(() => _gripperClosed = false);
      await Future.delayed(const Duration(seconds: 1));
      _toggleActuator('RLY07', false);
      setState(() { _sensor('S8').active = true; });

      // Retraer y regresar a home
      _toggleActuator('RLY04', true);
      setState(() => _armExtend = 0.0);
      _logAudit('RLY04 ON · Retrayendo brazo', LogType.audit);
      await Future.delayed(const Duration(seconds: 1));
      _toggleActuator('RLY04', false);
      _toggleActuator('RLY05', true);
      setState(() => _zPosition = 0.0);
      await Future.delayed(const Duration(seconds: 1));
      _toggleActuator('RLY05', false);
      setState(() { _sensor('S6').active = true; _piezas++; });
      _logAudit('✔ CICLO EXITOSO · Pick & Place completado · Pieza transportada', LogType.success);

    } catch (e) {
      _logAudit('ERROR en la secuencia automática: $e', LogType.error);
    }

    setState(() { _isCycleRunning = false; _currentState = 0; _updatePermissions(); });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            const SizedBox(height: 10),
            _buildTopBar(),
            const SizedBox(height: 10),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildRow1(),
                    const SizedBox(height: 10),
                    _buildRow2(),
                    const SizedBox(height: 10),
                    _buildStateProgress(),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ],
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
              const Text('ROBOT 3 EJES SCADA 4.0',
                  style: TextStyle(color: kMachine, fontSize: 18,
                      fontWeight: FontWeight.bold, letterSpacing: 1.4)),
              Text('Art. No. TM3DR24-A  ·  3D Robot 24V  ·  Pick & Place',
                  style: TextStyle(color: kText.withOpacity(0.5),
                      fontSize: 10, letterSpacing: 1)),
            ]),
            Text(_clock, style: const TextStyle(
                color: kText, fontSize: 14, fontFamily: 'monospace')),
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
              icon: Icon(_isCycleRunning ? Icons.stop : Icons.smart_toy, size: 16),
              label: Text(_isCycleRunning ? 'Ejecutando Pick & Place...' : 'Iniciar Ciclo Automático'),
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
            _kpiBox('Ciclos Completados', '$_piezas', kGreen),
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

  // ── Row 1: Gemelo Digital Robot + Sensores ─────────────
  Widget _buildRow1() => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 2, child: _buildRobotTwin()),
          const SizedBox(width: 10),
          Expanded(child: _buildSensorsPanel()),
        ],
      );

  // ── Gemelo Digital del robot ───────────────────────────
  Widget _buildRobotTwin() {
    return _panel(
      title: 'Gemelo Digital 2D  ·  Robot 3 Ejes (Vista Superior / Frontal)',
      titleColor: kMachine,
      height: 320,
      child: Row(
        children: [
          // Vista superior (rotación base)
          Expanded(
            child: Column(children: [
              const Text('Vista Superior', style: TextStyle(
                  color: Color(0xFF546E7A), fontSize: 10)),
              const SizedBox(height: 8),
              SizedBox(
                width: 180, height: 200,
                child: CustomPaint(
                  painter: _RobotTopViewPainter(
                    baseAngle: _baseAngle,
                    armExtend: _armExtend,
                    gripperClosed: _gripperClosed,
                    rly01: _act('RLY01').on,
                    rly02: _act('RLY02').on,
                    rly03: _act('RLY03').on,
                  ),
                ),
              ),
              Text('Base: ${_baseAngle.toStringAsFixed(0)}°',
                  style: TextStyle(
                      color: _act('RLY01').on || _act('RLY02').on
                          ? kMachine : const Color(0xFF546E7A),
                      fontSize: 10, fontWeight: FontWeight.bold)),
            ]),
          ),
          Container(width: 1, color: kBorder),
          // Vista frontal (eje Z + gripper)
          Expanded(
            child: Column(children: [
              const Text('Vista Frontal', style: TextStyle(
                  color: Color(0xFF546E7A), fontSize: 10)),
              const SizedBox(height: 8),
              SizedBox(
                width: 160, height: 200,
                child: CustomPaint(
                  painter: _RobotFrontViewPainter(
                    zPosition: _zPosition,
                    armExtend: _armExtend,
                    gripperClosed: _gripperClosed,
                    rly05: _act('RLY05').on,
                    rly06: _act('RLY06').on,
                    rly07: _act('RLY07').on,
                    rly08: _act('RLY08').on,
                  ),
                ),
              ),
              Text('Eje Z: ${(_zPosition * 100).toStringAsFixed(0)}%  '
                   'Gripper: ${_gripperClosed ? 'CERRADO' : 'ABIERTO'}',
                  style: TextStyle(
                      color: _gripperClosed ? kGreen : const Color(0xFF546E7A),
                      fontSize: 10, fontWeight: FontWeight.bold)),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildSensorsPanel() => _panel(
        title: 'Sensores · Encoders y Referencias',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: _sensors.map((s) => _sensorRow(s)).toList(),
        ),
      );

  Widget _sensorRow(SensorModel s) {
    final color = s.active ? kGreen : const Color(0xFF333333);
    return GestureDetector(
      onTap: () => _toggleSensor(s.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: s.active ? kGreen.withOpacity(0.07) : Colors.black.withOpacity(0.3),
          border: Border.all(
              color: s.active ? kGreen.withOpacity(0.4) : kBorder),
          borderRadius: BorderRadius.circular(4)),
        child: Row(children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 10, height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle, color: color,
              boxShadow: s.active
                  ? [BoxShadow(color: color.withOpacity(0.8), blurRadius: 8)]
                  : null),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${s.id}: ${s.label}',
                  style: TextStyle(
                      color: s.active ? kGreen : kText,
                      fontSize: 12, fontWeight: FontWeight.bold)),
              Text(s.description,
                  style: const TextStyle(color: Color(0xFF546E7A), fontSize: 10)),
            ],
          )),
          Text(s.active ? 'ON' : 'OFF',
              style: TextStyle(
                  color: s.active ? kGreen : const Color(0xFF546E7A),
                  fontSize: 10, fontWeight: FontWeight.bold)),
        ]),
      ),
    );
  }

  // ── Row 2: Actuadores (8 relés) + Audit ───────────────
  Widget _buildRow2() => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _buildActuatorsPanel()),
          const SizedBox(width: 10),
          Expanded(child: _buildActuatorsPanel2()),
          const SizedBox(width: 10),
          Expanded(child: _buildAuditPanel()),
        ],
      );

  Widget _buildActuatorsPanel() => _panel(
        title: 'Actuadores · Base y Brazo',
        child: Column(mainAxisSize: MainAxisSize.min,
          children: _actuators.sublist(0, 4).map(_actuatorRow).toList()),
      );

  Widget _buildActuatorsPanel2() => _panel(
        title: 'Actuadores · Eje Z y Gripper',
        child: Column(mainAxisSize: MainAxisSize.min,
          children: _actuators.sublist(4).map(_actuatorRow).toList()),
      );

  Widget _actuatorRow(ActuatorModel a) => Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: a.on ? kMachine.withOpacity(0.08) : Colors.black.withOpacity(0.3),
          border: Border.all(color: a.on ? kMachine.withOpacity(0.5) : kBorder),
          borderRadius: BorderRadius.circular(4)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(a.id,
                style: TextStyle(
                    color: a.on ? kMachine : kText,
                    fontSize: 12, fontWeight: FontWeight.bold))),
            Transform.scale(
              scale: 0.75,
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
          Text(a.description,
              style: const TextStyle(color: Color(0xFF546E7A), fontSize: 10)),
        ]),
      );

  Widget _buildAuditPanel() => _panel(
        title: 'Auditoría (Audit Trail) y Alertas',
        child: Container(
          height: 250,
          decoration: BoxDecoration(color: kBg,
              border: Border.all(color: kBorder),
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
                    TextSpan(text: l.message, style: TextStyle(color: l.color)),
                  ],
                )),
              );
            },
          ),
        ),
      );

  // ── Barra de estados (8 estados) ──────────────────────
  Widget _buildStateProgress() => _panel(
        title: 'Progreso del Ciclo  ·  ${kEstados[_currentState]}',
        titleColor: _currentState > 0 ? kMachine : kText,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(
            children: List.generate(8, (i) {
              final state = i + 1;
              final done   = _currentState > state;
              final active = _currentState == state;
              return Expanded(child: Column(children: [
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
                        fontSize: 8, fontWeight: FontWeight.bold)),
              ]));
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

// ─── Gemelo Digital Painters ───────────────────────────────

// Vista superior del robot (rotación base + brazo)
class _RobotTopViewPainter extends CustomPainter {
  final double baseAngle;
  final double armExtend;
  final bool gripperClosed;
  final bool rly01, rly02, rly03;

  _RobotTopViewPainter({
    required this.baseAngle,
    required this.armExtend,
    required this.gripperClosed,
    required this.rly01,
    required this.rly02,
    required this.rly03,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final rad = baseAngle * pi / 180;

    // Base circular
    canvas.drawCircle(Offset(cx, cy), 30,
        Paint()
          ..color = (rly01 || rly02)
              ? kMachine.withOpacity(0.3)
              : const Color(0xFF1A2233)
          ..style = PaintingStyle.fill);
    canvas.drawCircle(Offset(cx, cy), 30,
        Paint()
          ..color = (rly01 || rly02) ? kMachine : const Color(0xFF334455)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);

    // Texto M1
    final tp = TextPainter(
      text: TextSpan(text: 'M1',
          style: TextStyle(color: kText.withOpacity(0.6), fontSize: 10)),
      textDirection: TextDirection.ltr)..layout();
    tp.paint(canvas, Offset(cx - 9, cy - 6));

    // Brazo extendido
    final armLen = 30 + (armExtend * 50);
    final bx = cx + armLen * cos(rad);
    final by = cy + armLen * sin(rad);

    canvas.drawLine(
      Offset(cx, cy), Offset(bx, by),
      Paint()
        ..color = rly03 ? kMachine : const Color(0xFF334455)
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round);

    // Gripper
    canvas.drawCircle(
      Offset(bx, by), gripperClosed ? 6 : 10,
      Paint()
        ..color = gripperClosed
            ? kGreen.withOpacity(0.5)
            : const Color(0xFF1A2233)
        ..style = PaintingStyle.fill);
    canvas.drawCircle(
      Offset(bx, by), gripperClosed ? 6 : 10,
      Paint()
        ..color = gripperClosed ? kGreen : const Color(0xFF334455)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2);

    // Ángulo referencia
    final ap = TextPainter(
      text: TextSpan(
          text: '${baseAngle.toStringAsFixed(0)}°',
          style: TextStyle(
              color: (rly01 || rly02) ? kMachine : kText.withOpacity(0.3),
              fontSize: 9)),
      textDirection: TextDirection.ltr)..layout();
    ap.paint(canvas, Offset(cx - 10, size.height - 18));
  }

  @override
  bool shouldRepaint(covariant _RobotTopViewPainter old) =>
      old.baseAngle != baseAngle || old.armExtend != armExtend ||
      old.gripperClosed != gripperClosed;
}

// Vista frontal (eje Z + brazo + gripper)
class _RobotFrontViewPainter extends CustomPainter {
  final double zPosition;
  final double armExtend;
  final bool gripperClosed;
  final bool rly05, rly06, rly07, rly08;

  _RobotFrontViewPainter({
    required this.zPosition,
    required this.armExtend,
    required this.gripperClosed,
    required this.rly05,
    required this.rly06,
    required this.rly07,
    required this.rly08,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final colH = size.height - 30;

    // Columna vertical
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(cx - 4, 10, 8, colH),
          const Radius.circular(4)),
      Paint()..color = const Color(0xFF334455)..style = PaintingStyle.fill,
    );

    // Soporte del brazo (M3 / eje Z)
    final zY = 10 + zPosition * (colH - 30);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(cx - 16, zY, 32, 18),
          const Radius.circular(4)),
      Paint()
        ..color = (rly05 || rly06)
            ? kMachine.withOpacity(0.3)
            : const Color(0xFF1A2233)
        ..style = PaintingStyle.fill,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(cx - 16, zY, 32, 18),
          const Radius.circular(4)),
      Paint()
        ..color = (rly05 || rly06) ? kMachine : const Color(0xFF334455)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Brazo horizontal
    final armEndX = cx + 20 + armExtend * 35;
    canvas.drawLine(
      Offset(cx + 16, zY + 9),
      Offset(armEndX, zY + 9),
      Paint()
        ..color = rly07 || rly08 ? kMachine : const Color(0xFF445566)
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round,
    );

    // Gripper (vista frontal)
    final gpW = gripperClosed ? 8.0 : 14.0;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(armEndX - 2, zY + 3, gpW, 13),
          const Radius.circular(3)),
      Paint()
        ..color = gripperClosed ? kGreen.withOpacity(0.4) : const Color(0xFF1A2233)
        ..style = PaintingStyle.fill,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(armEndX - 2, zY + 3, gpW, 13),
          const Radius.circular(3)),
      Paint()
        ..color = gripperClosed ? kGreen : const Color(0xFF334455)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Flecha dirección Z
    final arrColor = rly06 ? kRed : rly05 ? kGreen : kText.withOpacity(0.2);
    canvas.drawLine(
      Offset(cx - 25, zY + 9),
      Offset(cx - 25, rly06 ? zY + 20 : rly05 ? zY - 10 : zY + 9),
      Paint()..color = arrColor..strokeWidth = 2..strokeCap = StrokeCap.round,
    );
    if (rly06 || rly05) {
      final arrowY = rly06 ? zY + 20 : zY - 10;
      final arrowDir = rly06 ? 1 : -1;
      canvas.drawPath(
        Path()
          ..moveTo(cx - 25, arrowY)
          ..lineTo(cx - 29, arrowY - arrowDir * 6.0)
          ..lineTo(cx - 21, arrowY - arrowDir * 6.0)
          ..close(),
        Paint()..color = arrColor..style = PaintingStyle.fill,
      );
    }

    // Base
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(cx - 20, size.height - 18, 40, 10),
          const Radius.circular(4)),
      Paint()..color = const Color(0xFF334455)..style = PaintingStyle.fill,
    );

    // Etiqueta M3
    final tp = TextPainter(
      text: TextSpan(
          text: 'M3', style: TextStyle(color: kText.withOpacity(0.4), fontSize: 8)),
      textDirection: TextDirection.ltr)..layout();
    tp.paint(canvas, Offset(cx - 5, zY + 5));
  }

  @override
  bool shouldRepaint(covariant _RobotFrontViewPainter old) =>
      old.zPosition != zPosition || old.gripperClosed != gripperClosed ||
      old.armExtend != armExtend;
}
