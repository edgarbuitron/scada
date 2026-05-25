import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';


// ── Paleta Unificada (Basada en Neumático) ──────────────────────────────────
const Color kBg = Color(0xFF081014);
const Color kPanel = Color(0xFF11222C);
const Color kMachine = Color(0xFF00EAFF); // Color principal de acento (antes era kRed)
const Color kGreen = Color(0xFF00FF88);
const Color kRed = Color(0xFFFF3366);
const Color kBorder = Color(0xFF1A3644);
const Color kText = Color(0xFFC5D1D8);
const Color kAudit = Color(0xFFFFAA00);
const Color kDark = Color(0xFF0C1820);

class ScadaRobot3EjesScreen extends StatelessWidget {
  const ScadaRobot3EjesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ScadaRobotDashboard();
  }
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
class ScadaRobotDashboard extends StatefulWidget {
  const ScadaRobotDashboard({super.key});
  @override
  State<ScadaRobotDashboard> createState() => _ScadaDashboardState();
}

class _ScadaDashboardState extends State<ScadaRobotDashboard>
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

  final TextEditingController _piezasController = TextEditingController(text: '1');

  double _baseAngle = 0;
  double _armExtend = 0;
  double _zPosition = 0;
  bool _gripperClosed = false;

  final List<SensorModel> _sensors = [
    SensorModel('S2', 'Encoder XY', 'Encoder CH-X,Y base giratoria'),
    SensorModel('S3', 'Ref Base', 'Posición referencia base giratoria'),
    SensorModel('S4', 'Cnt Brazo', 'Contador pulsos brazo gripper'),
    SensorModel('S6', 'Ref Eje Z', 'Posición referencia eje vertical Z'),
    SensorModel('S7', 'Enc Eje Z', 'Encoder CH-X,Y eje vertical'),
    SensorModel('S8', 'Ref Grip', 'Posición referencia gripper'),
  ];

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
      if(mounted) setState(_updateClock);
    });
    _rotAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _logAudit('Sistema iniciado · Robot 3 Ejes TM3DR24-A', LogType.info);
    _logAudit('Configuración cambiada a Modo: $_mode', LogType.audit);
    _resetToHome(log: false);
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
    _piezasController.dispose();
    super.dispose();
  }

  void _logAudit(String msg, LogType type) {
    final n = DateTime.now();
    final t =
        '${n.hour.toString().padLeft(2, '0')}:${n.minute.toString().padLeft(2, '0')}:${n.second.toString().padLeft(2, '0')}';
    if(mounted) {
      setState(() => _logs.add(LogEntry(t, _role, msg, type)));
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_logScroll.hasClients) {
          _logScroll.animateTo(_logScroll.position.maxScrollExtent,
              duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
        }
      });
    }
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
    if(mounted) setState(() => s.active = !s.active);
    _logAudit(
        'Simulación Manual: Sensor ${s.id} forzado a ${s.active ? 'DETECTANDO' : 'LIBRE'}',
        LogType.audit);
  }

  void _toggleActuator(String id, bool val) {
    if(mounted) {
      setState(() => _act(id).on = val);
      _updateRobotVisuals(id, val);
      if (!_isCycleRunning) {
        _logAudit('Forzó $id a ${val ? 'ENCENDIDO' : 'APAGADO'}', LogType.audit);
      }
    }
  }

  void _updateRobotVisuals(String id, bool val) {
    if(mounted) {
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
  }

  void _resetToHome({bool log = true}) {
    if(log) _logAudit('Restableciendo sistema a estado inicial...', LogType.audit);
    if(mounted) {
      setState(() {
        _isCycleRunning = false;
        _currentState = 0;
        for (final a in _actuators) { a.on = false; }
        for (final s in _sensors) { s.active = false; }
        _sensor('S3').active = true;
        _sensor('S6').active = true;
        _sensor('S8').active = true;
        _baseAngle = 0;
        _armExtend = 0;
        _zPosition = 0;
        _gripperClosed = false;
      });
    }
    if(log) _logAudit('Sistema restablecido a la posición HOME.', LogType.success);
  }

  void _triggerEmergency() {
    if (mounted) {
      setState(() {
        _isCycleRunning = false;
        _currentState = 0;
        for (final a in _actuators) { a.on = false; }
      });
    }
    _logAudit('¡PARO DE EMERGENCIA ACTIVADO! Todos los actuadores apagados.', LogType.error);
    if(mounted) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: kPanel,
          title: const Text('⚠ PARO DE EMERGENCIA', style: TextStyle(color: kRed, fontSize: 15)),
          content: const Text('Todos los actuadores han sido desactivados.\nRevise el robot antes de reiniciar.', style: TextStyle(color: kText)),
          actions: [ TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK', style: TextStyle(color: kMachine))) ],
        ),
      );
    }
  }


  Future<void> _startAutoCycle() async {
    if (_isCycleRunning) return;
    final int numPiezas = int.tryParse(_piezasController.text) ?? 0;
    if (numPiezas <= 0) {
      _logAudit('ERROR: El número de ciclos debe ser mayor a 0.', LogType.error);
      return;
    }
    if(mounted) setState(() { _isCycleRunning = true; _updatePermissions(); });
    _logAudit('══ INICIANDO CICLO AUTOMÁTICO PARA $numPiezas CICLOS ══', LogType.info);
    for (int i = 0; i < numPiezas; i++) {
      if (!_isCycleRunning) break;
      _logAudit('--- Ejecutando Pick & Place ${i + 1} de $numPiezas ---', LogType.info);
      await _runSingleCycle();
      if (!_isCycleRunning) {
        _logAudit('Ciclo interrumpido por PARO DE EMERGENCIA.', LogType.error);
        break;
      }
    }
    if(mounted) setState(() { _isCycleRunning = false; _currentState = 0; _updatePermissions(); });
    _logAudit('══ CICLO AUTOMÁTICO FINALIZADO ══', LogType.info);
  }

  Future<void> _runSingleCycle() async {
    try {
      if (!_isCycleRunning || !mounted) return;
      setState(() { _currentState = 1; _sensor('S3').active = false; });
      _logAudit('EST1 · RLY01 ON · Base girando CW', LogType.info);
      _toggleActuator('RLY01', true); await Future.delayed(const Duration(milliseconds: 500));
      if(mounted) setState(() => _baseAngle = 90); await Future.delayed(const Duration(seconds: 2));
      if (!_isCycleRunning || !mounted) return; _toggleActuator('RLY01', false);
      setState(() { _sensor('S3').active = true; _sensor('S2').active = true; });

      if (!_isCycleRunning || !mounted) return;
      setState(() { _currentState = 2; _sensor('S4').active = true; });
      _logAudit('EST2 · RLY03 ON · Expandiendo brazo', LogType.info);
      _toggleActuator('RLY03', true); await Future.delayed(const Duration(milliseconds: 100));
      if(mounted) setState(() => _armExtend = 1.0); await Future.delayed(const Duration(seconds: 2));
      if (!_isCycleRunning || !mounted) return; _toggleActuator('RLY03', false);

      if (!_isCycleRunning || !mounted) return;
      setState(() { _currentState = 3; _sensor('S6').active = false; });
      _logAudit('EST3 · RLY06 ON · Eje Z bajando', LogType.info);
      _toggleActuator('RLY06', true); await Future.delayed(const Duration(milliseconds: 100));
      if(mounted) setState(() => _zPosition = 1.0); await Future.delayed(const Duration(seconds: 2));
      if (!_isCycleRunning || !mounted) return; _toggleActuator('RLY06', false);

      if (!_isCycleRunning || !mounted) return;
      setState(() { _currentState = 4; _sensor('S8').active = false; });
      _logAudit('EST4 · RLY08 ON · Cerrando gripper', LogType.success);
      _toggleActuator('RLY08', true); await Future.delayed(const Duration(milliseconds: 100));
      if(mounted) setState(() => _gripperClosed = true); await Future.delayed(const Duration(seconds: 1));
      if (!_isCycleRunning || !mounted) return; _toggleActuator('RLY08', false);

      if (!_isCycleRunning || !mounted) return;
      setState(() => _currentState = 5);
      _logAudit('EST5 · RLY05 ON · Eje Z subiendo', LogType.info);
      _toggleActuator('RLY05', true); await Future.delayed(const Duration(milliseconds: 100));
      if(mounted) setState(() => _zPosition = 0.0); await Future.delayed(const Duration(seconds: 2));
      if (!_isCycleRunning || !mounted) return; _toggleActuator('RLY05', false);
      if(mounted) setState(() => _sensor('S6').active = true);

      if (!_isCycleRunning || !mounted) return;
      setState(() { _currentState = 6; _sensor('S3').active = false; });
      _logAudit('EST6 · RLY02 ON · Base girando CCW', LogType.info);
      _toggleActuator('RLY02', true); await Future.delayed(const Duration(milliseconds: 100));
      if(mounted) setState(() => _baseAngle = 0); await Future.delayed(const Duration(seconds: 2));
      if (!_isCycleRunning || !mounted) return; _toggleActuator('RLY02', false);
      if(mounted) setState(() { _sensor('S3').active = true; _sensor('S2').active = false; });

      if (!_isCycleRunning || !mounted) return;
      setState(() { _currentState = 7; _sensor('S6').active = false; });
      _logAudit('EST7 · RLY06 ON · Eje Z bajando', LogType.info);
      _toggleActuator('RLY06', true); await Future.delayed(const Duration(milliseconds: 100));
      if(mounted) setState(() => _zPosition = 1.0); await Future.delayed(const Duration(seconds: 2));
      if (!_isCycleRunning || !mounted) return; _toggleActuator('RLY06', false);

      if (!_isCycleRunning || !mounted) return;
      setState(() => _currentState = 8);
      _logAudit('EST8 · RLY07 ON · Abriendo gripper', LogType.success);
      _toggleActuator('RLY07', true); await Future.delayed(const Duration(milliseconds: 100));
      if(mounted) setState(() => _gripperClosed = false); await Future.delayed(const Duration(seconds: 1));
      if (!_isCycleRunning || !mounted) return; _toggleActuator('RLY07', false);
      if(mounted) setState(() => _sensor('S8').active = true);

      if (!_isCycleRunning || !mounted) return;
      _toggleActuator('RLY04', true); if(mounted) setState(() => _armExtend = 0.0);
      _logAudit('RLY04 ON · Retrayendo brazo', LogType.audit);
      await Future.delayed(const Duration(seconds: 1));
      if (!_isCycleRunning || !mounted) return; _toggleActuator('RLY04', false);
      _toggleActuator('RLY05', true); if(mounted) setState(() => _zPosition = 0.0);
      await Future.delayed(const Duration(seconds: 1));
      if (!_isCycleRunning || !mounted) return; _toggleActuator('RLY05', false);
      if(mounted) setState(() { _sensor('S6').active = true; _piezas++; });
      _logAudit('✔ CICLO EXITOSO #$_piezas: Pick & Place completado', LogType.success);

    } catch (e) {
      _logAudit('ERROR en secuencia: $e', LogType.error);
    }
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
              _buildTopBar(),
              const SizedBox(height: 10),
              _buildRow1(),
              const SizedBox(height: 10),
              _buildRow2(),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() => Container(
        padding: const EdgeInsets.only(bottom: 10),
        decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: kMachine, width: 2))),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('ROBOT 3 EJES', style: TextStyle(color: kMachine, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.4)),
            ]),
            Text(_clock, style: const TextStyle(color: kText, fontSize: 14, fontFamily: 'monospace')),
          ],
        ),
      );

  Widget _buildTopBar() => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: kPanel,
            border: Border.all(color: kBorder),
            borderRadius: BorderRadius.circular(8)),
        child: Wrap(
          spacing: 14,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _labeledSelect('Modo:', _mode, {
              'manual': 'Manual (Simulación Física)',
              'auto': 'Automático',
            }, (v) {
              if(mounted) setState(() => _mode = v!);
              _updatePermissions();
            }),
            _buildPiezasInput(),
            ElevatedButton.icon(
              onPressed: _btnAutoEnabled ? _startAutoCycle : null,
              icon: Icon(_isCycleRunning ? Icons.stop_circle_rounded : Icons.smart_toy_rounded, size: 16),
              label: Text(_isCycleRunning ? 'EJECUTANDO...' : 'INICIAR CICLO'),
              style: ElevatedButton.styleFrom(
                backgroundColor: kGreen,
                foregroundColor: kBg,
                disabledBackgroundColor: const Color(0xFF333333),
                disabledForegroundColor: const Color(0xFF666666),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
            ),
            ElevatedButton.icon(
              onPressed: _triggerEmergency,
              icon: const Icon(Icons.warning_amber_rounded, size: 16),
              label: const Text('PARO EMERGENCIA'),
              style: ElevatedButton.styleFrom(
                backgroundColor: kRed,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
            ),
            ElevatedButton.icon(
              onPressed: _isCycleRunning ? null : () => _resetToHome(),
              icon: const Icon(Icons.replay_circle_filled_rounded, size: 16),
              label: const Text('RESTABLECER'),
              style: ElevatedButton.styleFrom(
                backgroundColor: kMachine, // Usar el color principal
                foregroundColor: Colors.black,
                disabledBackgroundColor: const Color(0xFF333333),
                disabledForegroundColor: const Color(0xFF666666),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
            ),
            _kpiBox('Ciclos Completados', '$_piezas', kGreen),
          ],
        ),
      );

  Widget _buildPiezasInput() => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      const Text("Ciclos:", style: TextStyle(color: kText, fontSize: 12)),
      const SizedBox(width: 8),
      SizedBox(
        width: 60,
        height: 38,
        child: TextField(
          controller: _piezasController,
          enabled: _mode == 'auto',
          keyboardType: TextInputType.number,
          inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
          textAlign: TextAlign.center,
          style: TextStyle(color: _mode == 'auto' ? kMachine : Colors.grey, fontSize: 16, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            filled: true,
            fillColor: kBg,
            contentPadding: const EdgeInsets.symmetric(vertical: 8.0),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide(color: _mode == 'auto' ? kMachine : kBorder)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide(color: _mode == 'auto' ? kMachine : kBorder)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: kMachine, width: 2)),
            disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide(color: kBorder)),
          ),
        ),
      ),
    ],
  );

  Widget _labeledSelect(String lbl, String val, Map<String, String> items,
          ValueChanged<String?> fn) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Text(lbl, style: const TextStyle(color: kText, fontSize: 12)),
        const SizedBox(width: 5),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
              color: kBg,
              border: Border.all(color: kMachine),
              borderRadius: BorderRadius.circular(4)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: val,
              dropdownColor: kPanel,
              style: const TextStyle(color: kMachine, fontSize: 12),
              icon: const Icon(Icons.arrow_drop_down, color: kMachine, size: 18),
              isDense: true,
              items: items.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
              onChanged: fn,
            ),
          ),
        ),
      ]);

  Widget _kpiBox(String label, String value, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            border: Border.all(color: color),
            borderRadius: BorderRadius.circular(6)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(label, style: const TextStyle(color: kText, fontSize: 10)),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.bold)),
        ]),
      );

  Widget _buildRow1() => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 2, child: _buildRobotTwin()),
          const SizedBox(width: 10),
          Expanded(child: _buildSensorsPanel()),
        ],
      );

  Widget _buildRobotTwin() {
    return _panel(
      title: 'Gemelo Digital 2D  ·  Robot 3 Ejes (Vista Superior / Frontal)',
      titleColor: kMachine,
      height: 320,
      child: Row(
        children: [
          Expanded(
            child: Column(children: [
              const Text('Vista Superior', style: TextStyle(color: Color(0xFF546E7A), fontSize: 10)),
              const SizedBox(height: 8),
              SizedBox(
                width: 180, height: 200,
                child: CustomPaint(
                  painter: _RobotTopViewPainter(
                    baseAngle: _baseAngle, armExtend: _armExtend, gripperClosed: _gripperClosed,
                    rly01: _act('RLY01').on, rly02: _act('RLY02').on, rly03: _act('RLY03').on,
                  ),
                ),
              ),
              Text('Base: ${_baseAngle.toStringAsFixed(0)}°', style: TextStyle(color: _act('RLY01').on || _act('RLY02').on ? kMachine : const Color(0xFF546E7A), fontSize: 10, fontWeight: FontWeight.bold)),
            ]),
          ),
          Container(width: 1, color: kBorder),
          Expanded(
            child: Column(children: [
              const Text('Vista Frontal', style: TextStyle(color: Color(0xFF546E7A), fontSize: 10)),
              const SizedBox(height: 8),
              SizedBox(
                width: 160, height: 200,
                child: CustomPaint(
                  painter: _RobotFrontViewPainter(
                    zPosition: _zPosition, armExtend: _armExtend, gripperClosed: _gripperClosed,
                    rly05: _act('RLY05').on, rly06: _act('RLY06').on, rly07: _act('RLY07').on, rly08: _act('RLY08').on,
                  ),
                ),
              ),
              Text('Eje Z: ${(_zPosition * 100).toStringAsFixed(0)}%  Gripper: ${_gripperClosed ? 'CERRADO' : 'ABIERTO'}', style: TextStyle(color: _gripperClosed ? kGreen : const Color(0xFF546E7A), fontSize: 10, fontWeight: FontWeight.bold)),
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
            border: Border.all(color: s.active ? kGreen.withOpacity(0.4) : kBorder),
            borderRadius: BorderRadius.circular(4)),
        child: Row(children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 10, height: 10,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color, boxShadow: s.active ? [BoxShadow(color: color.withOpacity(0.8), blurRadius: 8)] : null),
          ),
          const SizedBox(width: 10),
          Expanded(
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${s.id}: ${s.label}', style: TextStyle(color: s.active ? kGreen : kText, fontSize: 12, fontWeight: FontWeight.bold)),
              Text(s.description, style: const TextStyle(color: Color(0xFF546E7A), fontSize: 10)),
            ],
          )),
          Text(s.active ? 'ON' : 'OFF', style: TextStyle(color: s.active ? kGreen : const Color(0xFF546E7A), fontSize: 10, fontWeight: FontWeight.bold)),
        ]),
      ),
    );
  }

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
        child: Column(
            mainAxisSize: MainAxisSize.min,
            children: _actuators.sublist(0, 4).map(_actuatorRow).toList()),
      );

  Widget _buildActuatorsPanel2() => _panel(
        title: 'Actuadores · Eje Z y Gripper',
        child: Column(
            mainAxisSize: MainAxisSize.min,
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
            Expanded(child: Text(a.id, style: TextStyle(color: a.on ? kMachine : kText, fontSize: 12, fontWeight: FontWeight.bold))),
            Transform.scale(
              scale: 0.75,
              child: Switch(value: a.on, onChanged: a.disabled ? null : (v) => _toggleActuator(a.id, v), activeColor: Colors.white, activeTrackColor: kMachine, inactiveThumbColor: Colors.white, inactiveTrackColor: const Color(0xFF333333)),
            ),
          ]),
          Text(a.description, style: const TextStyle(color: Color(0xFF546E7A), fontSize: 10)),
        ]),
      );

  Widget _buildAuditPanel() => _panel(
        title: 'Auditoría (Audit Trail) y Alertas',
        child: Container(
          height: 250,
          decoration: BoxDecoration(color: kBg, border: Border.all(color: kBorder), borderRadius: BorderRadius.circular(4)),
          padding: const EdgeInsets.all(8),
          child: ListView.builder(
            controller: _logScroll,
            itemCount: _logs.length,
            itemBuilder: (_, i) {
              final l = _logs[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: RichText(
                    text: TextSpan(
                  style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                  children: [
                    TextSpan(text: '[${l.time}] ', style: const TextStyle(color: Color(0xFF546E7A))),
                    TextSpan(text: '[${l.user}] - ', style: const TextStyle(color: kMachine)), // Usar color principal
                    TextSpan(text: l.message, style: TextStyle(color: l.color)),
                  ],
                )),
              );
            },
          ),
        ),
      );

  Widget _panel({ 
    required String title,
    required Widget child,
    double? height,
    Color titleColor = kMachine, // Usar color principal por defecto
  }) =>
      Container(
        height: height,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: kPanel,
            border: Border.all(color: kBorder),
            borderRadius: BorderRadius.circular(8)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.only(bottom: 8),
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: kBorder))),
              child: Text(title, style: TextStyle(color: titleColor, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      );
}

class _RobotTopViewPainter extends CustomPainter {
  final double baseAngle; final double armExtend; final bool gripperClosed;
  final bool rly01, rly02, rly03;
  _RobotTopViewPainter({ required this.baseAngle, required this.armExtend, required this.gripperClosed, required this.rly01, required this.rly02, required this.rly03 });
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2; final cy = size.height / 2; final rad = baseAngle * pi / 180;
    canvas.drawCircle(Offset(cx, cy), 30, Paint()..color = (rly01 || rly02) ? kMachine.withOpacity(0.3) : const Color(0xFF1A2233)..style = PaintingStyle.fill);
    canvas.drawCircle(Offset(cx, cy), 30, Paint()..color = (rly01 || rly02) ? kMachine : const Color(0xFF334455)..style = PaintingStyle.stroke..strokeWidth = 2);
    final tp = TextPainter(text: TextSpan(text: 'M1', style: TextStyle(color: kText.withOpacity(0.6), fontSize: 10)), textDirection: TextDirection.ltr)..layout();
    tp.paint(canvas, Offset(cx - 9, cy - 6));
    final armLen = 30 + (armExtend * 50); final bx = cx + armLen * cos(rad); final by = cy + armLen * sin(rad);
    canvas.drawLine(Offset(cx, cy), Offset(bx, by), Paint()..color = rly03 ? kMachine : const Color(0xFF334455)..strokeWidth = 6..strokeCap = StrokeCap.round);
    canvas.drawCircle(Offset(bx, by), gripperClosed ? 6 : 10, Paint()..color = gripperClosed ? kGreen.withOpacity(0.5) : const Color(0xFF1A2233)..style = PaintingStyle.fill);
    canvas.drawCircle(Offset(bx, by), gripperClosed ? 6 : 10, Paint()..color = gripperClosed ? kGreen : const Color(0xFF334455)..style = PaintingStyle.stroke..strokeWidth = 2);
    final ap = TextPainter(text: TextSpan(text: '${baseAngle.toStringAsFixed(0)}°', style: TextStyle(color: (rly01 || rly02) ? kMachine : kText.withOpacity(0.3), fontSize: 9)), textDirection: TextDirection.ltr)..layout();
    ap.paint(canvas, Offset(cx - 10, size.height - 18));
  }
  @override
  bool shouldRepaint(covariant _RobotTopViewPainter old) => old.baseAngle != baseAngle || old.armExtend != armExtend || old.gripperClosed != gripperClosed;
}

class _RobotFrontViewPainter extends CustomPainter {
  final double zPosition; final double armExtend; final bool gripperClosed;
  final bool rly05, rly06, rly07, rly08;
  _RobotFrontViewPainter({ required this.zPosition, required this.armExtend, required this.gripperClosed, required this.rly05, required this.rly06, required this.rly07, required this.rly08 });
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2; final colH = size.height - 30;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx - 4, 10, 8, colH), const Radius.circular(4)), Paint()..color = const Color(0xFF334455)..style = PaintingStyle.fill);
    final zY = 10 + zPosition * (colH - 30);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx - 16, zY, 32, 18), const Radius.circular(4)), Paint()..color = (rly05 || rly06) ? kMachine.withOpacity(0.3) : const Color(0xFF1A2233)..style = PaintingStyle.fill);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx - 16, zY, 32, 18), const Radius.circular(4)), Paint()..color = (rly05 || rly06) ? kMachine : const Color(0xFF334455)..style = PaintingStyle.stroke..strokeWidth = 1.5);
    final armEndX = cx + 20 + armExtend * 35;
    canvas.drawLine(Offset(cx + 16, zY + 9), Offset(armEndX, zY + 9), Paint()..color = rly07 || rly08 ? kMachine : const Color(0xFF445566)..strokeWidth = 5..strokeCap = StrokeCap.round);
    final gpW = gripperClosed ? 8.0 : 14.0;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(armEndX - 2, zY + 3, gpW, 13), const Radius.circular(3)), Paint()..color = gripperClosed ? kGreen.withOpacity(0.4) : const Color(0xFF1A2233)..style = PaintingStyle.fill);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(armEndX - 2, zY + 3, gpW, 13), const Radius.circular(3)), Paint()..color = gripperClosed ? kGreen : const Color(0xFF334455)..style = PaintingStyle.stroke..strokeWidth = 1.5);
    final arrColor = rly06 ? kRed : rly05 ? kGreen : kText.withOpacity(0.2);
    canvas.drawLine(Offset(cx - 25, zY + 9), Offset(cx - 25, rly06 ? zY + 20 : rly05 ? zY - 10 : zY + 9), Paint()..color = arrColor..strokeWidth = 2..strokeCap = StrokeCap.round);
    if (rly06 || rly05) {
      final arrowY = rly06 ? zY + 20 : zY - 10; final arrowDir = rly06 ? 1 : -1;
      canvas.drawPath(Path()..moveTo(cx - 25, arrowY)..lineTo(cx - 29, arrowY - arrowDir * 6.0)..lineTo(cx - 21, arrowY - arrowDir * 6.0)..close(), Paint()..color = arrColor..style = PaintingStyle.fill);
    }
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx - 20, size.height - 18, 40, 10), const Radius.circular(4)), Paint()..color = const Color(0xFF334455)..style = PaintingStyle.fill);
    final tp = TextPainter(text: TextSpan(text: 'M3', style: TextStyle(color: kText.withOpacity(0.4), fontSize: 8)), textDirection: TextDirection.ltr)..layout();
    tp.paint(canvas, Offset(cx - 5, zY + 5));
  }
  @override
  bool shouldRepaint(covariant _RobotFrontViewPainter old) => old.zPosition != zPosition || old.gripperClosed != gripperClosed || old.armExtend != armExtend;
}