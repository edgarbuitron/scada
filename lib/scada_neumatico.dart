import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'firebase_service.dart';

// ─── Colores y Estilos ────────────────────────────────────────────────────────
const Color kBg = Color(0xFF0A192F);
const Color kPanel = Color(0xFF172A46);
const Color kAccent = Color(0xFF64FFDA);
const Color kGreen = Color(0xFF10B981);
const Color kRed = Color(0xFFF43F5E);
const Color kBorder = Color(0xFF233554);
const Color kText = Color(0xFFD3E0F2);
const Color kMuted = Color(0xFF8892B0);

// ─── Modelos de Datos ────────────────────────────────────────────────────────
class LogEntry {
  final String time, user, message;
  final String type; // 'Info', 'Audit', 'Error', 'Success'

  LogEntry({required this.time, required this.user, required this.message, required this.type});

  Color get color {
    switch (type) {
      case 'Error': return kRed;
      case 'Success': return kGreen;
      case 'Audit': return kAccent;
      default: return kText;
    }
  }
}

class Actuator {
  final String id, name;
  bool isOn;
  Actuator({required this.id, required this.name, this.isOn = false});
}

class Sensor {
  final String id, name;
  bool isActive;
  Sensor({required this.id, required this.name, this.isActive = false});
}

// ─── Pantalla Principal ─────────────────────────────────────────────────────
class ScadaNeumaticoScreen extends StatefulWidget {
  const ScadaNeumaticoScreen({super.key});
  @override
  State<ScadaNeumaticoScreen> createState() => _ScadaNeumaticoScreenState();
}

class _ScadaNeumaticoScreenState extends State<ScadaNeumaticoScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final String _maquetaId = 'neumatico';

  // Estado del SCADA
  bool _isCycleRunning = false;
  String _mode = 'manual';
  String _role = 'Operador';
  int _piezas = 0;
  final List<LogEntry> _logs = [];
  final ScrollController _logScrollController = ScrollController();

  final List<Actuator> _actuators = [Actuator(id: '1', name: 'Válvula A'), Actuator(id: '2', name: 'Válvula B')];
  final List<Sensor> _sensors = [Sensor(id: 'A0', name: 'Cilindro A en Home'), Sensor(id: 'A1', name: 'Cilindro A Extendido'), Sensor(id: 'B0', name: 'Cilindro B en Home'), Sensor(id: 'B1', name: 'Cilindro B Extendido')];

  @override
  void initState() {
    super.initState();
    _firebaseService.initializeMaqueta(_maquetaId);
    _resetToHome(log: false);
    _logAudit('Sistema Neumático Inicializado', 'Info');
  }

  @override
  void dispose() {
    _logScrollController.dispose();
    super.dispose();
  }

  void _logAudit(String message, String type) {
    final now = DateTime.now();
    final time = DateFormat('HH:mm:ss').format(now);
    if (mounted) {
      setState(() => _logs.add(LogEntry(time: time, user: _role, message: message, type: type)));
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_logScrollController.hasClients) _logScrollController.jumpTo(_logScrollController.position.maxScrollExtent);
      });

      String logTypeForHistory;
      switch(type) {
        case 'Error': logTypeForHistory = 'Critico'; break;
        case 'Audit': logTypeForHistory = 'Advertencia'; break;
        default: logTypeForHistory = 'Info';
      }
      _firebaseService.guardarLog(_maquetaId, {'role': _role, 'message': message, 'type': logTypeForHistory});
    }
  }

  void _setMode(String? newMode) {
    if (newMode != null && !_isCycleRunning) {
      setState(() => _mode = newMode);
      _logAudit('Modo cambiado a $newMode', 'Audit');
    }
  }

  void _toggleActuator(String id, bool value) {
    if (_mode == 'manual' && !_isCycleRunning) {
      setState(() => _actuators.firstWhere((a) => a.id == id).isOn = value);
      _logAudit('Actuador $id ${value ? 'activado' : 'desactivado'} manualmente', 'Audit');
      _firebaseService.registrarAccionComponente(_maquetaId, 'actuador_${id}_${value ? 'on' : 'off'}');
    }
  }

  void _resetToHome({bool log = true}) {
    if(log) _logAudit('Sistema reseteado a HOME', 'Audit');
    setState(() {
      _actuators.forEach((a) => a.isOn = false);
      _sensors.forEach((s) => s.isActive = s.id.endsWith('0'));
      _isCycleRunning = false;
    });
    if(log) _firebaseService.registrarReset(_maquetaId);
  }

  void _emergencyStop() {
    _logAudit('¡PARO DE EMERGENCIA ACTIVADO!', 'Error');
    _firebaseService.registrarParoEmergencia(_maquetaId);
    _firebaseService.registrarAccionComponente(_maquetaId, 'paro_emergencia');
    _resetToHome(log: false);
  }

  Future<void> _startCycle() async {
    if (_isCycleRunning) return;
    setState(() => _isCycleRunning = true);
    _logAudit('Iniciando ciclo automático: A+ B+ B- A-', 'Info');

    await _executeStep('A+', () => _actuators[0].isOn = true, () => _sensors[1].isActive);
    await _executeStep('B+', () => _actuators[1].isOn = true, () => _sensors[3].isActive);
    await _executeStep('B-', () => _actuators[1].isOn = false, () => _sensors[2].isActive);
    await _executeStep('A-', () => _actuators[0].isOn = false, () => _sensors[0].isActive);

    if (_isCycleRunning) {
      setState(() => _piezas++);
      _logAudit('Ciclo completado. Pieza #${_piezas}', 'Success');
      _firebaseService.incrementarPiezas(_maquetaId);
    }
    setState(() => _isCycleRunning = false);
  }

  Future<void> _executeStep(String stepName, VoidCallback action, bool Function() condition) async {
    if (!_isCycleRunning) return;
    _logAudit('Ejecutando: $stepName', 'Info');
    setState(action);
    await Future.delayed(const Duration(milliseconds: 500)); // Simulación de movimiento
    // Lógica de simulación para sensores
    if(stepName == 'A+') { setState(() { _sensors[0].isActive = false; _sensors[1].isActive = true; }); }
    if(stepName == 'B+') { setState(() { _sensors[2].isActive = false; _sensors[3].isActive = true; }); }
    if(stepName == 'B-') { setState(() { _sensors[3].isActive = false; _sensors[2].isActive = true; }); }
    if(stepName == 'A-') { setState(() { _sensors[1].isActive = false; _sensors[0].isActive = true; }); }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: kBg,
      body: Padding(padding: const EdgeInsets.all(16.0), child: Column(children: [ _buildHeader(), const SizedBox(height: 16), Expanded(child: _buildBody()) ])),
    );

  Widget _buildHeader() => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      const Text('SCADA - Centro Neumático', style: TextStyle(color: kText, fontSize: 24, fontWeight: FontWeight.bold)),
      Row(children: [
        _kpiBox('Piezas', '$_piezas', kGreen),
        const SizedBox(width: 16),
        ElevatedButton.icon(onPressed: _emergencyStop, icon: const Icon(Icons.warning, color: kRed), label: const Text('Paro Emergencia'), style: ElevatedButton.styleFrom(backgroundColor: kRed.withOpacity(0.2))),
      ]),
    ],
  );

  Widget _buildBody() => Row(
    children: [
      Expanded(flex: 2, child: _buildControlPanel()),
      const SizedBox(width: 16),
      Expanded(flex: 3, child: _buildVisualPanel()),
    ],
  );

  Widget _buildControlPanel() => _panel(
    title: 'Panel de Control',
    child: Column(children: [
      _buildModeSelector(), const SizedBox(height: 16),
      ..._actuators.map(_buildActuatorSwitch), const SizedBox(height: 16),
      ..._sensors.map(_buildSensorIndicator), const SizedBox(height: 16),
      const Spacer(),
      ElevatedButton.icon(onPressed: (_mode == 'auto' && !_isCycleRunning) ? _startCycle : null, icon: const Icon(Icons.play_arrow), label: const Text('Iniciar Ciclo'), style: ElevatedButton.styleFrom(backgroundColor: kGreen, foregroundColor: Colors.black)),
      const SizedBox(height: 8),
      ElevatedButton.icon(onPressed: _resetToHome, icon: const Icon(Icons.refresh), label: const Text('Resetear a Home'), style: ElevatedButton.styleFrom(backgroundColor: kAccent, foregroundColor: Colors.black)),
    ]),
  );

  Widget _buildModeSelector() => Row(mainAxisAlignment: MainAxisAlignment.center, children: [
    const Text('Modo:', style: TextStyle(color: kText)), const SizedBox(width: 10),
    DropdownButton<String>(value: _mode, items: const [DropdownMenuItem(value: 'manual', child: Text('Manual')), DropdownMenuItem(value: 'auto', child: Text('Automático'))], onChanged: _setMode, style: const TextStyle(color: kAccent), dropdownColor: kPanel),
  ]);

  Widget _buildActuatorSwitch(Actuator actuator) => SwitchListTile(
    title: Text(actuator.name, style: const TextStyle(color: kText)),
    value: actuator.isOn, 
    onChanged: (v) => _toggleActuator(actuator.id, v),
    activeColor: kAccent,
    inactiveTrackColor: kMuted.withOpacity(0.3),
    activeTrackColor: kAccent.withOpacity(0.5),
  );

  Widget _buildSensorIndicator(Sensor sensor) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4.0),
    child: Row(children: [
      Icon(Icons.circle, color: sensor.isActive ? kGreen : kMuted, size: 12),
      const SizedBox(width: 8),
      Text(sensor.name, style: TextStyle(color: sensor.isActive ? kText : kMuted)),
    ]),
  );

  Widget _buildVisualPanel() => _panel(
    title: 'Visualización y Auditoría',
    child: Column(children: [
      _buildPiston('A', _sensors[1].isActive), const SizedBox(height: 16),
      _buildPiston('B', _sensors[3].isActive), const Spacer(),
      _buildLogConsole(),
    ]),
  );

  Widget _buildPiston(String label, bool isExtended) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Cilindro $label', style: const TextStyle(color: kMuted)),
      const SizedBox(height: 8),
      Container(
        height: 40,
        decoration: BoxDecoration(border: Border.all(color: kBorder), borderRadius: BorderRadius.circular(4)),
        child: Stack(children: [
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            left: isExtended ? 150 : 0,
            child: Container(width: 50, color: kAccent, child: Center(child: Text(label, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)))),
          ),
        ]),
      ),
    ],
  );

  Widget _buildLogConsole() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('Consola de Eventos', style: TextStyle(color: kMuted)),
      const SizedBox(height: 8),
      Container(
        height: 150, width: double.infinity,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: kBg.withOpacity(0.5), borderRadius: BorderRadius.circular(4)),
        child: ListView.builder(
          controller: _logScrollController,
          itemCount: _logs.length,
          itemBuilder: (context, index) {
            final log = _logs[index];
            return RichText(text: TextSpan(
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              children: [ TextSpan(text: '[${log.time}] ', style: const TextStyle(color: kMuted)), TextSpan(text: log.message, style: TextStyle(color: log.color)) ]
            ));
          },
        ),
      ),
    ],
  );

  Widget _kpiBox(String label, String value, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
    child: Column(children: [
      Text(label, style: const TextStyle(color: kText, fontSize: 10)),
      Text(value, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.bold)),
    ]),
  );

  Widget _panel({required String title, required Widget child}) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: kPanel, borderRadius: BorderRadius.circular(12), border: Border.all(color: kBorder)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [ Text(title, style: const TextStyle(color: kAccent, fontSize: 18, fontWeight: FontWeight.bold)), const Divider(color: kBorder, height: 24), Expanded(child: child) ]),
  );
}
