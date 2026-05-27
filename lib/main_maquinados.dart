import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'firebase_service.dart'; // Importa el servicio de Firebase

// ── Paleta Unificada ──────────────────────────────────
const Color kBg = Color(0xFF081014);
const Color kPanel = Color(0xFF11222C);
const Color kMachine = Color(0xFF00EAFF);
const Color kGreen = Color(0xFF00FF88);
const Color kRed = Color(0xFFFF3366);
const Color kBorder = Color(0xFF1A3644);
const Color kText = Color(0xFFC5D1D8);
const Color kAudit = Color(0xFFFFAA00);

// ── Modelos ───────────────────────────────────────────────
enum LogType { info, audit, error, success }

class LogEntry {
  final String time, user, message;
  final LogType type;
  const LogEntry(this.time, this.user, this.message, this.type);
  Color get color => type == LogType.error ? kRed : type == LogType.audit ? kAudit : type == LogType.success ? kGreen : kText;
}

class SensorModel {
  final String id, label, description;
  bool active;
  SensorModel(this.id, this.label, this.description, {this.active = false});
}

class ActuatorModel {
  final String id, label, description;
  bool on; bool disabled;
  ActuatorModel(this.id, this.label, this.description, {this.on = false, this.disabled = false});
}

class ScadaMaquinadosScreen extends StatelessWidget {
  const ScadaMaquinadosScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const ScadaMaquinadosDashboard();
  }
}

// ── Dashboard ─────────────────────────────────────────────
class ScadaMaquinadosDashboard extends StatefulWidget {
  const ScadaMaquinadosDashboard({super.key});
  @override
  State<ScadaMaquinadosDashboard> createState() => _ScadaMaquinadosDashboardState();
}

class _ScadaMaquinadosDashboardState extends State<ScadaMaquinadosDashboard> {
  // --- Variables de Estado ---
  String _clock = '';
  late Timer _clockTimer;
  final String _role = 'Ingeniero';
  String _mode = 'manual';
  bool _isCycleRunning = false;
  int _piezas = 0;
  final TextEditingController _piezasController = TextEditingController(text: '1');
  final ScrollController _logScroll = ScrollController();
  final List<LogEntry> _logs = [];

  final List<SensorModel> _sensors = [
    SensorModel('P1', 'P1', 'Pieza entrando a línea indexada'),
    SensorModel('P2', 'P2', 'Pieza lista para empujador 1'),
    SensorModel('R1', 'R1', 'Empujador 1 en reposo (home)'),
    SensorModel('P3', 'P3', 'Pieza presente en fresadora'),
    SensorModel('P4', 'P4', 'Pieza presente en taladradora'),
    SensorModel('R2', 'R2', 'Empujador 2 en reposo (home)'),
    SensorModel('P5', 'P5', 'Pieza en área de producto terminado'),
  ];

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

  // --- Servicio de Firebase ---
  final FirebaseService _firebaseService = FirebaseService();
  final String _maquetaId = 'maquinados';

  SensorModel _sensor(String id) => _sensors.firstWhere((s) => s.id == id);
  ActuatorModel _act(String id) => _actuators.firstWhere((a) => a.id == id);
  bool get _btnAutoEnabled => _mode == 'auto' && !_isCycleRunning;

  @override
  void initState() {
    super.initState();
    _firebaseService.initializeMaqueta(_maquetaId);
    _updateClock();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) { if(mounted) setState(_updateClock); });
    _logAudit('Sistema iniciado · Centro de Maquinados TMINL24-A', LogType.info);
    _logAudit('Configuración cambiada a Modo: $_mode', LogType.audit);
    _resetToHome(log: false);
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    _logScroll.dispose();
    _piezasController.dispose();
    super.dispose();
  }

  void _updateClock() {
    final n = DateTime.now();
    _clock = '${n.hour.toString().padLeft(2, '0')}:${n.minute.toString().padLeft(2, '0')}:${n.second.toString().padLeft(2, '0')}';
  }

  void _logAudit(String msg, LogType type) {
    final n = DateTime.now();
    final t = '${n.hour.toString().padLeft(2, '0')}:${n.minute.toString().padLeft(2, '0')}:${n.second.toString().padLeft(2, '0')}';
    if(mounted) {
      setState(() => _logs.add(LogEntry(t, _role, msg, type)));
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_logScroll.hasClients) {
          _logScroll.animateTo(_logScroll.position.maxScrollExtent, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
        }
      });
      
      String logTypeForHistory;
      switch (type) {
        case LogType.error: logTypeForHistory = 'Critico'; break;
        case LogType.audit: logTypeForHistory = 'Advertencia'; break;
        default: logTypeForHistory = 'Info';
      }

      _firebaseService.guardarLog(_maquetaId, {'role': _role, 'message': msg, 'type': logTypeForHistory});
    }
  }

  void _updatePermissions() {
    for (final a in _actuators) { a.disabled = (_role == 'Operador' || _mode == 'auto' || _isCycleRunning); }
    _logAudit('Configuración cambiada a Modo: $_mode', LogType.audit);
  }

  void _toggleSensor(String id) {
    if (_mode != 'manual') { 
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Cambia el Modo a 'Manual' para simular sensores."), backgroundColor: kAudit));
      return; 
    }
    final s = _sensor(id);
    if(mounted) setState(() => s.active = !s.active);
    _logAudit('Simulación Manual: Sensor ${s.id} forzado a ${s.active ? 'DETECTANDO' : 'LIBRE'}', LogType.audit);
    _firebaseService.registrarAccionComponente(_maquetaId, 'sensor_${s.id}');
  }

  void _toggleActuator(String id, bool val) {
    if(mounted) {
      setState(() => _act(id).on = val);
      if (!_isCycleRunning) {
        _logAudit('Forzó $id a ${val ? 'ENCENDIDO' : 'APAGADO'}', LogType.audit);
        _firebaseService.registrarAccionComponente(_maquetaId, 'actuador_$id');
      }
    }
  }
  
  void _resetToHome({bool log = true}) {
    if (log) _logAudit('Restableciendo sistema a estado inicial...', LogType.audit);
    if (mounted) {
      setState(() {
        _isCycleRunning = false; 
        for (final a in _actuators) { a.on = false; }
        for (final s in _sensors) { s.active = false; }
        _sensor('R1').active = true; _sensor('R2').active = true; 
      });
    }
    if (log) {
      _logAudit('Sistema restablecido a la posición HOME.', LogType.success);
      _firebaseService.registrarReset(_maquetaId);
    }
  }

  void _triggerEmergency() {
    if (mounted) {
      setState(() { 
        _isCycleRunning = false; 
        for (final a in _actuators) { a.on = false; } 
      });
    }
    _logAudit('¡PARO DE EMERGENCIA ACTIVADO! Todos los actuadores apagados.', LogType.error);
    _firebaseService.registrarParoEmergencia(_maquetaId);
    _firebaseService.registrarAccionComponente(_maquetaId, 'paro_emergencia');
    if (mounted) {
      showDialog(
        context: context, 
        builder: (_) => AlertDialog(
          backgroundColor: kPanel, 
          title: const Text('⚠ PARO DE EMERGENCIA', style: TextStyle(color: kRed, fontSize: 15)), 
          content: const Text('Todos los actuadores han sido desactivados.\nRevise la máquina antes de reiniciar.', style: TextStyle(color: kText)), 
          actions: [ TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK', style: TextStyle(color: kMachine))) ],
        ),
      );
    }
  }

  Future<void> _startAutoCycle() async {
    if (_isCycleRunning) return;
    final int numPiezas = int.tryParse(_piezasController.text) ?? 0;
    if (numPiezas <= 0) { _logAudit('ERROR: El número de piezas debe ser mayor a 0.', LogType.error); return; }
    if(mounted) setState(() { _isCycleRunning = true; _updatePermissions(); });
    _logAudit('══ INICIANDO CICLO AUTOMÁTICO PARA $numPiezas PIEZAS ══', LogType.info);
    for (int i = 0; i < numPiezas; i++) {
      if (!_isCycleRunning) break;
      _logAudit('--- Procesando pieza ${i + 1} de $numPiezas ---', LogType.info);
      await _runSingleCycle();
      if (!_isCycleRunning) { _logAudit('Ciclo interrumpido por PARO DE EMERGENCIA.', LogType.error); break; }
    }
    if(mounted) setState(() { _isCycleRunning = false; _updatePermissions(); });
    _logAudit('══ CICLO AUTOMÁTICO FINALIZADO ══', LogType.info);
  }

  Future<void> _runSingleCycle() async {
     try {
      if (!_isCycleRunning || !mounted) return;
      setState(() { _sensor('P1').active = true; }); _logAudit('EST1 · P1 detectado · M1 enciende banda entrada', LogType.info);
      _toggleActuator('M1', true); await Future.delayed(const Duration(seconds: 2));
      if (!_isCycleRunning || !mounted) return; setState(() => _sensor('P1').active = false);
      setState(() { _sensor('P2').active = true; }); _logAudit('EST2 · P2 detectado · M1 apaga · M2 empuja pieza', LogType.info);
      _toggleActuator('M1', false); await Future.delayed(const Duration(milliseconds: 500));
      if (!_isCycleRunning || !mounted) return; _toggleActuator('M2', true); setState(() => _sensor('R1').active = false);
      _logAudit('M2 ON · Empujador 1 activado', LogType.success); await Future.delayed(const Duration(seconds: 2));
      if (!_isCycleRunning || !mounted) return; setState(() { _sensor('P2').active = false; });
      _logAudit('EST3 · R1 en reposo · M2 apaga · M3 banda 2 activa', LogType.info); _toggleActuator('M2', false);
      setState(() => _sensor('R1').active = true); await Future.delayed(const Duration(milliseconds: 500));
      if (!_isCycleRunning || !mounted) return; _toggleActuator('M3', true);
      _logAudit('M3 ON · Banda 2 moviendo pieza hacia fresadora', LogType.success); await Future.delayed(const Duration(seconds: 2));
      if (!_isCycleRunning || !mounted) return; setState(() { _sensor('P3').active = true; });
      _logAudit('EST4 · P3 detectado · Fresando...', LogType.info); _toggleActuator('M3', false); await Future.delayed(const Duration(milliseconds: 500));
      if (!_isCycleRunning || !mounted) return; _toggleActuator('M4', true);
      _logAudit('M4 ON · Fresando pieza', LogType.success); await Future.delayed(const Duration(seconds: 2));
      if (!_isCycleRunning || !mounted) return; _toggleActuator('M4', false); _logAudit('M4 OFF · Fresado completado', LogType.audit); await Future.delayed(const Duration(milliseconds: 500));
      if (!_isCycleRunning || !mounted) return; _toggleActuator('M3', true); _toggleActuator('M6', true); setState(() => _sensor('P3').active = false);
      _logAudit('M3+M6 ON · Avanzando pieza hacia taladradora', LogType.success); await Future.delayed(const Duration(seconds: 2));
      if (!_isCycleRunning || !mounted) return; setState(() { _sensor('P4').active = true; });
      _logAudit('EST5 · P4 detectado · Taladrando...', LogType.info); _toggleActuator('M3', false); _toggleActuator('M6', false); await Future.delayed(const Duration(milliseconds: 500));
      if (!_isCycleRunning || !mounted) return; _toggleActuator('M5', true);
      _logAudit('M5 ON · Taladrando pieza', LogType.success); await Future.delayed(const Duration(seconds: 2));
      if (!_isCycleRunning || !mounted) return; _toggleActuator('M5', false); _logAudit('M5 OFF · Taladrado completado', LogType.audit); await Future.delayed(const Duration(milliseconds: 500));
      if (!_isCycleRunning || !mounted) return; _toggleActuator('M6', true); await Future.delayed(const Duration(seconds: 1));
      if (!_isCycleRunning || !mounted) return; _toggleActuator('M6', false); setState(() { _sensor('P4').active = false; _sensor('R2').active = false; });
      _toggleActuator('M7', true); _logAudit('M7 ON · Empujador 2 activado → salida', LogType.success); await Future.delayed(const Duration(seconds: 2));
      if (!_isCycleRunning || !mounted) return; setState(() { _sensor('R2').active = true; });
      _logAudit('EST6 · R2 en reposo · M8 banda salida activa', LogType.info); _toggleActuator('M7', false); await Future.delayed(const Duration(milliseconds: 500));
      if (!_isCycleRunning || !mounted) return; _toggleActuator('M8', true);
      _logAudit('M8 ON · Banda de producto terminado activa', LogType.success); await Future.delayed(const Duration(seconds: 2));
      if (!_isCycleRunning || !mounted) return; setState(() { _sensor('P5').active = true; });
      _logAudit('EST7 · P5 detectado · Pieza en área de salida', LogType.info); await Future.delayed(const Duration(seconds: 1));
      if (!_isCycleRunning || !mounted) return; _toggleActuator('M8', false);
      setState(() { _sensor('P5').active = false; _piezas++; });
      _logAudit('✔ CICLO EXITOSO · Pieza #$_piezas maquinada', LogType.success);
      _firebaseService.incrementarPiezas(_maquetaId);
    } catch (e) { _logAudit('ERROR en la secuencia automática: $e', LogType.error); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              _buildHeader(),
              const SizedBox(height: 16),
              _buildTopBar(),
              const SizedBox(height: 10),
              _buildDigitalTwin(),
              const SizedBox(height: 10),
              _buildRow2(),
              const SizedBox(height: 10),
            ],),
        ),
      ),
    );
  }

  Widget _buildHeader() => Container(
        padding: const EdgeInsets.only(bottom: 10),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: kMachine, width: 2))),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [ Text('CENTRO DE MAQUINADOS', style: TextStyle(color: kMachine, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.4)) ]),
            Text(_clock, style: const TextStyle(color: kText, fontSize: 14, fontFamily: 'monospace')),
          ],),
      );

  Widget _buildTopBar() => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: kPanel, border: Border.all(color: kBorder), borderRadius: BorderRadius.circular(8)),
        child: Wrap(spacing: 14, runSpacing: 10, crossAxisAlignment: WrapCrossAlignment.center, children: [
            _labeledSelect('Modo:', _mode, {'manual': 'Manual (Simulación Física)', 'auto': 'Automático',}, (v) { if(mounted) setState(() => _mode = v!); _updatePermissions(); }),
            _buildPiezasInput(),
            ElevatedButton.icon(onPressed: _btnAutoEnabled ? _startAutoCycle : null, icon: Icon(_isCycleRunning ? Icons.stop_circle_rounded : Icons.play_circle_fill_rounded, size: 16), label: Text(_isCycleRunning ? 'EJECUTANDO...' : 'INICIAR CICLO'), style: ElevatedButton.styleFrom(backgroundColor: kGreen, foregroundColor: Colors.black, disabledBackgroundColor: const Color(0xFF333333), disabledForegroundColor: const Color(0xFF666666), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10))),
            ElevatedButton.icon(onPressed: _triggerEmergency, icon: const Icon(Icons.warning_amber_rounded, size: 16), label: const Text('PARO EMERGENCIA'), style: ElevatedButton.styleFrom(backgroundColor: kRed, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10))),
            ElevatedButton.icon(onPressed: _isCycleRunning ? null : _resetToHome, icon: const Icon(Icons.replay_circle_filled_rounded, size: 16), label: const Text('RESTABLECER'), style: ElevatedButton.styleFrom(backgroundColor: kMachine, foregroundColor: Colors.black, disabledBackgroundColor: const Color(0xFF333333), disabledForegroundColor: const Color(0xFF666666), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10))),
            _kpiBox('Piezas Terminadas', '$_piezas', kGreen),
          ],),);
      
   Widget _buildPiezasInput() => Row(mainAxisSize: MainAxisSize.min, children: [
      const Text("Piezas:", style: TextStyle(color: kText, fontSize: 12)),
      const SizedBox(width: 8),
      SizedBox(width: 60, height: 38, child: TextField(controller: _piezasController, enabled: _mode == 'auto', keyboardType: TextInputType.number, inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly], textAlign: TextAlign.center, style: TextStyle(color: _mode == 'auto' ? kMachine : Colors.grey, fontSize: 16, fontWeight: FontWeight.bold), decoration: InputDecoration(filled: true, fillColor: kBg, contentPadding: const EdgeInsets.symmetric(vertical: 8.0), border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide(color: _mode == 'auto' ? kMachine : kBorder)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide(color: _mode == 'auto' ? kMachine : kBorder)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: kMachine, width: 2)), disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: kBorder))))),
    ],);

  Widget _labeledSelect(String lbl, String val, Map<String, String> items, ValueChanged<String?> fn) => Row(mainAxisSize: MainAxisSize.min, children: [
        Text(lbl, style: const TextStyle(color: kText, fontSize: 12)),
        const SizedBox(width: 5),
        Container(padding: const EdgeInsets.symmetric(horizontal: 8), decoration: BoxDecoration(color: kBg, border: Border.all(color: kMachine), borderRadius: BorderRadius.circular(4)), child: DropdownButtonHideUnderline(child: DropdownButton<String>(value: val, dropdownColor: kPanel, style: const TextStyle(color: kMachine, fontSize: 12), icon: const Icon(Icons.arrow_drop_down, color: kMachine, size: 18), isDense: true, items: items.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(), onChanged: fn))),
      ]);

  Widget _kpiBox(String label, String value, Color color) => Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(color: color.withValues(alpha: 0.08), border: Border.all(color: color), borderRadius: BorderRadius.circular(6)), child: Column(mainAxisSize: MainAxisSize.min, children: [ Text(label, style: const TextStyle(color: kText, fontSize: 10)), const SizedBox(height: 2), Text(value, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.bold))]),);

  Widget _buildDigitalTwin() => _panel(title: 'Gemelo Digital 2D  ·  Línea Indexada', titleColor: kMachine, height: 230, child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: SizedBox(width: 900, height: 170, child: Stack(children: [ _dtBand('M1\nEntrada', _act('M1').on, left: 10, top: 100, w: 100), _dtSensorDot('P1', _sensor('P1').active, left: 50, top: 80), _dtPusher('M2\nEmpujador 1', _act('M2').on, left: 120, top: 50), _dtSensorDot('R1', _sensor('R1').active, left: 155, top: 30), _dtBand('M3\nBanda 2', _act('M3').on, left: 210, top: 100, w: 110), _dtSensorDot('P2', _sensor('P2').active, left: 255, top: 80), _dtMachine('M4\nFresadora', _act('M4').on, left: 330, top: 30), _dtSensorDot('P3', _sensor('P3').active, left: 372, top: 80), _dtBand('M6\nBanda 3', _act('M6').on, left: 440, top: 100, w: 100), _dtMachine('M5\nTaladradora', _act('M5').on, left: 550, top: 30), _dtSensorDot('P4', _sensor('P4').active, left: 592, top: 80), _dtPusher('M7\nEmpujador 2', _act('M7').on, left: 660, top: 50), _dtSensorDot('R2', _sensor('R2').active, left: 695, top: 30), _dtBand('M8\nSalida', _act('M8').on, left: 760, top: 100, w: 100), _dtSensorDot('P5', _sensor('P5').active, left: 805, top: 80), Positioned(left: 10, top: 130, right: 10, child: Container(height: 2, color: kBorder)), const Positioned(left: 420, top: 126, child: Icon(Icons.arrow_forward, color: kMachine, size: 18))]))));

  Widget _dtBand(String label, bool active, {required double left, required double top, double w = 80}) => Positioned(left: left, top: top, child: AnimatedContainer(duration: const Duration(milliseconds: 300), width: w, height: 40, alignment: Alignment.center, decoration: BoxDecoration(color: active ? kMachine.withValues(alpha: 0.2) : const Color(0xFF1A2233), border: Border.all(color: active ? kMachine : const Color(0xFF334455), width: 1.5), borderRadius: BorderRadius.circular(4), boxShadow: active ? [BoxShadow(color: kMachine.withValues(alpha: 0.4), blurRadius: 8)] : null), child: Text(label, textAlign: TextAlign.center, style: TextStyle(color: active ? kMachine : kText.withValues(alpha: 0.4), fontSize: 9, fontWeight: FontWeight.bold))));

  Widget _dtMachine(String label, bool active, {required double left, required double top}) => Positioned(left: left, top: top, child: AnimatedContainer(duration: const Duration(milliseconds: 300), width: 80, height: 70, alignment: Alignment.center, decoration: BoxDecoration(color: active ? kMachine.withValues(alpha: 0.15) : const Color(0xFF1A2233), border: Border.all(color: active ? kMachine : const Color(0xFF334455), width: 2), borderRadius: BorderRadius.circular(6), boxShadow: active ? [BoxShadow(color: kMachine.withValues(alpha: 0.5), blurRadius: 12)] : null), child: Text(label, textAlign: TextAlign.center, style: TextStyle(color: active ? kMachine : kText.withValues(alpha: 0.4), fontSize: 9, fontWeight: FontWeight.bold))));

  Widget _dtPusher(String label, bool active, {required double left, required double top}) => Positioned(left: left, top: top, child: AnimatedContainer(duration: const Duration(milliseconds: 300), width: 55, height: 55, alignment: Alignment.center, decoration: BoxDecoration(color: active ? kMachine.withValues(alpha: 0.15) : const Color(0xFF1A2233), border: Border.all(color: active ? kMachine : const Color(0xFF334455), width: 1.5), borderRadius: BorderRadius.circular(4), boxShadow: active ? [BoxShadow(color: kMachine.withValues(alpha: 0.4), blurRadius: 8)] : null), child: Text(label, textAlign: TextAlign.center, style: TextStyle(color: active ? kMachine : kText.withValues(alpha: 0.4), fontSize: 8, fontWeight: FontWeight.bold))));

  Widget _dtSensorDot(String id, bool active, {required double left, required double top}) => Positioned(left: left, top: top, child: AnimatedContainer(duration: const Duration(milliseconds: 200), width: 24, height: 24, alignment: Alignment.center, decoration: BoxDecoration(shape: BoxShape.circle, color: active ? kGreen.withValues(alpha: 0.2) : Colors.transparent, border: Border.all(color: active ? kGreen : const Color(0xFF334455)), boxShadow: active ? [BoxShadow(color: kGreen.withValues(alpha: 0.7), blurRadius: 8)] : null), child: Text(id, style: TextStyle(color: active ? kGreen : const Color(0xFF546E7A), fontSize: 7, fontWeight: FontWeight.bold))));

  Widget _buildRow2() => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [ SizedBox(width: 220, child: _buildSensorsPanel()), const SizedBox(width: 10), SizedBox(width: 240, child: _buildActuatorsPanel()), const SizedBox(width: 10), Expanded(child: _buildAuditPanel()) ]);

  Widget _buildSensorsPanel() => _panel(title: 'Sensores (7)', child: Column(mainAxisSize: MainAxisSize.min, children: _sensors.map((s) => _sensorRow(s)).toList()));

  Widget _sensorRow(SensorModel s) {
    final Color color = s.active ? kGreen : const Color(0xFF333333);
    return GestureDetector(
        onTap: () => _toggleSensor(s.id),
        child: Container(
            margin: const EdgeInsets.symmetric(vertical: 3),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
                color: s.active
                    ? kGreen.withValues(alpha: 0.07)
                    : Colors.black.withValues(alpha: 0.3),
                border: Border.all(
                    color: s.active ? kGreen.withValues(alpha: 0.4) : kBorder),
                borderRadius: BorderRadius.circular(4)),
            child: Row(children: [
              Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color,
                      boxShadow: s.active
                          ? [
                              BoxShadow(
                                  color: color.withValues(alpha: 0.8),
                                  blurRadius: 6)
                            ]
                          : null)),
              const SizedBox(width: 8),
              Expanded(
                  child: Text('${s.id}: ${s.label}',
                      style: const TextStyle(color: kText, fontSize: 11)))
            ])));
  }

  Widget _buildActuatorsPanel() => _panel(
      title: 'Actuadores (M1–M8)',
      child: Column(
          mainAxisSize: MainAxisSize.min,
          children: _actuators.map(_actuatorRow).toList()));

  Widget _actuatorRow(ActuatorModel a) => Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: a.on ? kMachine.withValues(alpha: 0.07) : Colors.black.withValues(alpha: 0.3),
          border: Border.all(color: a.on ? kMachine.withValues(alpha: 0.5) : kBorder),
          borderRadius: BorderRadius.circular(4)),
      child: Row(children: [
        Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text(a.id,
                  style: TextStyle(
                      color: a.on ? kMachine : kText,
                      fontSize: 11,
                      fontWeight: FontWeight.bold)),
              Text(a.description,
                  style: const TextStyle(color: Color(0xFF546E7A), fontSize: 9))
            ])),
        Transform.scale(
            scale: 0.7,
            child: Switch(
                value: a.on,
                onChanged: a.disabled ? null : (v) => _toggleActuator(a.id, v),
                activeThumbColor: kMachine,
                inactiveTrackColor: const Color(0xFF333333)))
      ]));

  Widget _buildAuditPanel() => _panel(title: 'Auditoría (Audit Trail) y Alertas', child: Container(height: 250, decoration: BoxDecoration(color: kBg, border: Border.all(color: kBorder), borderRadius: BorderRadius.circular(4)), padding: const EdgeInsets.all(8), child: ListView.builder(controller: _logScroll, itemCount: _logs.length, itemBuilder: (_, i) { final l = _logs[i]; return Padding(padding: const EdgeInsets.only(bottom: 2), child: RichText(text: TextSpan(style: const TextStyle(fontSize: 11, fontFamily: 'monospace'), children: [ TextSpan(text: '[${l.time}] ', style: const TextStyle(color: Color(0xFF546E7A))), TextSpan(text: '[${l.user}] - ', style: const TextStyle(color: kMachine)), TextSpan(text: l.message, style: TextStyle(color: l.color)) ]))); })));

  Widget _panel({ required String title, required Widget child, double? height, Color titleColor = kMachine }) => Container(height: height, padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: kPanel, border: Border.all(color: kBorder), borderRadius: BorderRadius.circular(8)), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [ Container(padding: const EdgeInsets.only(bottom: 8), decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: kBorder))), child: Text(title, style: TextStyle(color: titleColor, fontSize: 12, fontWeight: FontWeight.bold))), const SizedBox(height: 8), child ]));
}
