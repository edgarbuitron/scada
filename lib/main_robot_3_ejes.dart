import 'dart:async';
import 'package:flutter/material.dart';

// --- Importar el servicio de Firebase ---
import 'firebase_service.dart';

// ── Paleta de Colores y Estilos ──────────────────────────────────
const Color kBgDark = Color(0xFF0A0E1A);
const Color kPanel = Color(0xFF141A2E);
const Color kAccent = Color(0xFF8A2BE2); // Violeta azulado
const Color kGreen = Color(0xFF32CD32);
const Color kRed = Color(0xFFDC143C);
const Color kBorder = Color(0xFF2D3B59);
const Color kText = Colors.white;
const Color kMuted = Colors.white60;

// ── Modelos ───────────────────────────────────────────────
enum _Axis { X, Y, Z }

enum _RLogType { info, audit, error, success }

class _RLogEntry {
  final String time, message;
  final _RLogType type;
  const _RLogEntry(this.time, this.message, this.type);

  Color get color {
    switch (type) {
      case _RLogType.error: return kRed;
      case _RLogType.audit: return kAccent;
      case _RLogType.success: return kGreen;
      default: return kText;
    }
  }
}

// ── Pantalla Principal ─────────────────────────────────
class ScadaRobotDashboard extends StatefulWidget {
  const ScadaRobotDashboard({super.key});
  @override
  State<ScadaRobotDashboard> createState() => _ScadaRobotDashboardState();
}

class _ScadaRobotDashboardState extends State<ScadaRobotDashboard> {
  // --- Servicio de Firebase y ID de Maqueta ---
  final FirebaseService _firebaseService = FirebaseService();
  final String _maquetaId = 'robot_3_ejes';

  // --- Estado del Robot ---
  Map<String, double> _pos = {'X': 0, 'Y': 0, 'Z': 0};
  Map<String, bool> _limitSwitches = {'X0': true, 'X1': false, 'Y0': true, 'Y1': false, 'Z0': true, 'Z1': false};
  bool _gripper = false;
  bool _isCycleRunning = false;
  String _mode = 'manual';
  int _piezas = 0;
  final List<_RLogEntry> _logs = [];
  final ScrollController _logScroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _firebaseService.initializeMaqueta(_maquetaId);
    _log('Sistema Robot 3 Ejes TMINL24-C inicializado.', _RLogType.info);
  }

  @override
  void dispose() {
    _logScroll.dispose();
    super.dispose();
  }

  // --- Lógica del SCADA ---
  void _log(String msg, _RLogType type) {
    final t = DateTime.now();
    final timeStr = '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:${t.second.toString().padLeft(2, '0')}';
    if (mounted) {
      setState(() => _logs.insert(0, _RLogEntry(timeStr, msg, type)));
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_logScroll.hasClients) _logScroll.jumpTo(0);
      });

      // --- Traducción y guardado en Firebase ---
      String logTypeForHistory;
      switch (type) {
        case _RLogType.error: logTypeForHistory = 'Critico'; break;
        case _RLogType.audit: logTypeForHistory = 'Advertencia'; break;
        default: logTypeForHistory = 'Info';
      }
      _firebaseService.guardarLog(_maquetaId, {
        'role': 'Operador', // Rol fijo para este ejemplo
        'message': msg,
        'type': logTypeForHistory,
      });
    }
  }

  void _setMode(String? newMode) {
    if (newMode == null || _isCycleRunning) return;
    setState(() => _mode = newMode);
    _log('Modo de operación cambiado a: $newMode', _RLogType.audit);
  }

  Future<void> _moveAxis(_Axis axis, double target, {bool manual = false}) async {
    if (_isCycleRunning && manual) return;
    if (manual) _log('Moviendo Eje ${axis.name} a $target manualmente.', _RLogType.audit);

    final axisName = axis.name;
    final initialPos = _pos[axisName]!;
    final distance = (target - initialPos).abs();
    final duration = (distance * 10).toInt();
    final steps = (distance * 20).toInt().clamp(1, 1000);

    for (int i = 1; i <= steps; i++) {
      if ((_isCycleRunning == false && !manual) || !mounted) break;
      await Future.delayed(Duration(milliseconds: duration ~/ steps));
      setState(() {
        _pos[axisName] = initialPos + (target - initialPos) * (i / steps);
        // Simulación de switches de límite
        if (_pos[axisName]! <= 0.1) { _limitSwitches['${axisName}0'] = true; _limitSwitches['${axisName}1'] = false; } 
        else if (_pos[axisName]! >= 99.9) { _limitSwitches['${axisName}0'] = false; _limitSwitches['${axisName}1'] = true; }
        else { _limitSwitches['${axisName}0'] = false; _limitSwitches['${axisName}1'] = false; }
      });
    }
    if (mounted) setState(() => _pos[axisName] = target);
  }

  Future<void> _toggleGripper(bool open, {bool manual = false}) async {
    if (_isCycleRunning && manual) return;
    if (manual) _log('Operando Gripper a ${open ? 'ABIERTO' : 'CERRADO'}', _RLogType.audit);
    setState(() => _gripper = open);
    _firebaseService.registrarAccionComponente(_maquetaId, 'gripper_${open ? 'on' : 'off'}');
    await Future.delayed(const Duration(milliseconds: 500));
  }

  Future<void> _goToHome({bool log = true}) async {
    if (_isCycleRunning) return;
    if (log) _log('Enviando Robot a posición HOME...', _RLogType.audit);
    await _moveAxis(_Axis.Z, 0);
    await _moveAxis(_Axis.Y, 0);
    await _moveAxis(_Axis.X, 0);
    if (log) {
      _log('Robot en HOME.', _RLogType.success);
       _firebaseService.registrarReset(_maquetaId);
    }
  }

  void _emergencyStop() {
    setState(() => _isCycleRunning = false);
    _log('¡PARO DE EMERGENCIA ACTIVADO!', _RLogType.error);
    _firebaseService.registrarParoEmergencia(_maquetaId);
    _firebaseService.registrarAccionComponente(_maquetaId, 'paro_emergencia');
  }

  Future<void> _startCycle() async {
    if (_isCycleRunning) return;
    await _goToHome(log: false);
    setState(() { _isCycleRunning = true; _piezas = 0; });
    _log('══ INICIANDO CICLO DE PICK & PLACE ══', _RLogType.info);

    const pickPos = {'X': 80.0, 'Y': 20.0, 'Z': 75.0};
    const placePos = {'X': 20.0, 'Y': 80.0, 'Z': 75.0};

    for (int i = 1; i <= 5; i++) { // 5 ciclos de ejemplo
      if (!_isCycleRunning) {
        _log('Ciclo interrumpido.', _RLogType.audit);
        break;
      }
      _log('--- Iniciando ciclo #${i} ---', _RLogType.info);
      // Ir a recoger
      await _toggleGripper(true); // Abrir gripper
      await _moveAxis(_Axis.Z, 0);
      await _moveAxis(_Axis.X, pickPos['X']!);
      await _moveAxis(_Axis.Y, pickPos['Y']!);
      await _moveAxis(_Axis.Z, pickPos['Z']!); 
      await _toggleGripper(false); // Cerrar gripper
      _log('Pieza recogida de la posición de Pick.', _RLogType.success);

      // Ir a dejar
      await _moveAxis(_Axis.Z, 0);
      await _moveAxis(_Axis.X, placePos['X']!);
      await _moveAxis(_Axis.Y, placePos['Y']!);
      await _moveAxis(_Axis.Z, placePos['Z']!); 
      await _toggleGripper(true); // Abrir gripper
      _log('Pieza dejada en la posición de Place.', _RLogType.success);
      
      if (mounted) setState(() => _piezas = i);
      _firebaseService.incrementarPiezas(_maquetaId);
    }
    
    await _goToHome(log: false);
    setState(() => _isCycleRunning = false);
    _log('══ CICLO FINALIZADO ══', _RLogType.info);
  }

  // --- Widgets de la UI ---
  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 900;
    return Scaffold(
      backgroundColor: kBgDark,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: isMobile ? _buildMobileLayout() : _buildDesktopLayout(),
      ),
    );
  }

  Widget _buildDesktopLayout() => Column(children: [
    _buildHeader(),
    const SizedBox(height: 16),
    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(flex: 3, child: _buildControlPanel()),
      const SizedBox(width: 16),
      Expanded(flex: 2, child: _buildLogPanel()),
    ])
  ]);

  Widget _buildMobileLayout() => Column(children: [
    _buildHeader(),
    const SizedBox(height: 16),
    _buildControlPanel(),
    const SizedBox(height: 16),
    _buildLogPanel(),
  ]);

  Widget _buildHeader() => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
    const Text('SCADA: Robot 3 Ejes (Pick & Place)', style: TextStyle(color: kText, fontSize: 20, fontWeight: FontWeight.bold)),
    _buildModeSelector(),
  ]);

  Widget _buildModeSelector() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10),
    decoration: BoxDecoration(color: kPanel, borderRadius: BorderRadius.circular(8)),
    child: DropdownButton<String>(
      value: _mode, isDense: true, underline: const SizedBox(),
      dropdownColor: kPanel, style: const TextStyle(color: kAccent, fontSize: 13),
      icon: const Icon(Icons.arrow_drop_down, color: kAccent),
      items: const [ DropdownMenuItem(value: 'manual', child: Text('Modo Manual')), DropdownMenuItem(value: 'auto', child: Text('Modo Automático')) ],
      onChanged: _setMode,
    ),
  );

  Widget _buildControlPanel() => Column(children: [
    _panel(title: 'Posición de Ejes y Gripper', child: _buildAxesStatus()),
    const SizedBox(height: 16),
    _panel(title: 'Controles y Ciclo', child: _buildCycleControls()),
  ]);

  Widget _buildAxesStatus() => Column(children: [
    _axisSlider(_Axis.X), _axisSlider(_Axis.Y), _axisSlider(_Axis.Z),
    const SizedBox(height: 10),
    Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
      _limitSwitchIndicator('X0'), _limitSwitchIndicator('X1'),
      _limitSwitchIndicator('Y0'), _limitSwitchIndicator('Y1'),
      _limitSwitchIndicator('Z0'), _limitSwitchIndicator('Z1'),
      _gripperIndicator(),
    ]),
  ]);

  Widget _axisSlider(_Axis axis) {
    final axisName = axis.name;
    return Row(children: [
      Text('Eje $axisName', style: const TextStyle(color: kText, fontWeight: FontWeight.bold, fontSize: 16)),
      Expanded(
        child: Slider(
          value: _pos[axisName]!, min: 0, max: 100,
          activeColor: kAccent,
          onChanged: (_mode == 'manual') ? (v) => _moveAxis(axis, v, manual: true) : null,
        ),
      ),
      Text('${_pos[axisName]!.toStringAsFixed(1)}%', style: const TextStyle(color: kMuted, fontSize: 14)),
    ]);
  }

  Widget _limitSwitchIndicator(String id) => Column(children: [
    Container(width: 20, height: 20, decoration: BoxDecoration(color: _limitSwitches[id]! ? kGreen : kMuted, shape: BoxShape.circle)),
    const SizedBox(height: 4), Text(id, style: const TextStyle(color: kText, fontSize: 10)),
  ]);

  Widget _gripperIndicator() => Column(children: [
    GestureDetector(
      onTap: (_mode == 'manual') ? () => _toggleGripper(!_gripper, manual: true) : null,
      child: Container(
        width: 40, height: 20, alignment: Alignment.center,
        decoration: BoxDecoration(color: _gripper ? kGreen : kMuted, borderRadius: BorderRadius.circular(4)),
        child: Text(_gripper ? 'ON' : 'OFF', style: const TextStyle(color: kBgDark, fontSize: 10, fontWeight: FontWeight.bold)),
      ),
    ),
    const SizedBox(height: 4), const Text('Gripper', style: TextStyle(color: kText, fontSize: 10)),
  ]);

  Widget _buildCycleControls() => Column(children: [
    Text('Piezas ciclo actual: $_piezas', style: const TextStyle(color: kText, fontSize: 16)),
    const SizedBox(height: 16),
    Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
      ElevatedButton.icon(icon: const Icon(Icons.home), label: const Text('Ir a HOME'), onPressed: _goToHome, style: ElevatedButton.styleFrom(backgroundColor: kAccent, foregroundColor: kText)),
      ElevatedButton.icon(icon: Icon(_isCycleRunning ? Icons.stop : Icons.play_arrow), label: Text(_isCycleRunning ? 'DETENER CICLO' : 'INICIAR CICLO'), onPressed: () => _isCycleRunning ? setState(()=>_isCycleRunning = false) : _startCycle(), style: ElevatedButton.styleFrom(backgroundColor: _isCycleRunning ? kMuted : kGreen, foregroundColor: kBgDark)),
      ElevatedButton.icon(icon: const Icon(Icons.error), label: const Text('PARO DE EMERGENCIA'), onPressed: _emergencyStop, style: ElevatedButton.styleFrom(backgroundColor: kRed, foregroundColor: kText)),
    ]),
  ]);

  Widget _buildLogPanel() => _panel(
    height: 400,
    title: 'Consola de Eventos del Robot',
    child: ListView.builder(
      controller: _logScroll,
      itemCount: _logs.length,
      itemBuilder: (context, index) {
        final log = _logs[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 4.0),
          child: RichText(text: TextSpan(
            style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
            children: [ TextSpan(text: '[${log.time}] ', style: const TextStyle(color: kMuted)), TextSpan(text: log.message, style: TextStyle(color: log.color)) ]
          )),
        );
      },
    ),
  );

  Widget _panel({required String title, required Widget child, double? height}) => Container(
    height: height, padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: kPanel, borderRadius: BorderRadius.circular(8), border: Border.all(color: kBorder)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(title, style: const TextStyle(color: kAccent, fontWeight: FontWeight.bold))),
      const Divider(color: kBorder, height: 1), const SizedBox(height: 8), child,
    ]),
  );
}
