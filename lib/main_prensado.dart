import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'usage_monitor.dart';

// ── Paleta Unificada (Basada en Neumático) ──────────────────────────────────
const Color kBgP = Color(0xFF081014);
const Color kPanelP = Color(0xFF11222C);
const Color kMachineP = Color(0xFF00EAFF);
const Color kGreenP = Color(0xFF00FF88);
const Color kRedP = Color(0xFFFF3366);
const Color kBorderP = Color(0xFF1A3644);
const Color kTextP = Color(0xFFC5D1D8);
const Color kAuditP = Color(0xFFFFAA00);
const Color kDarkP = Color(0xFF0C1820);

// ── Modelos internos ────────────────────────────────
enum _PLogType { info, audit, error, success }

class _PLogEntry {
  final String time, user, message;
  final _PLogType type;
  const _PLogEntry(this.time, this.user, this.message, this.type);
  Color get color => type == _PLogType.error
      ? kRedP
      : type == _PLogType.audit
      ? kAuditP
      : type == _PLogType.success
      ? kGreenP
      : kTextP;
}

class _PSensorModel {
  final String id, label, description;
  bool active;
  _PSensorModel(this.id, this.label, this.description, {this.active = false});
}

class _PActuatorModel {
  final String id, label, description;
  bool on;
  bool disabled;
  _PActuatorModel(this.id, this.label, this.description,
      {this.on = false, this.disabled = false});
}

// ── Widget público exportado ──────────────────────────────────────────────
class ScadaPrensadoScreen extends StatefulWidget {
  const ScadaPrensadoScreen({super.key});

  @override
  State<ScadaPrensadoScreen> createState() => _ScadaPrensadoState();
}

class _ScadaPrensadoState extends State<ScadaPrensadoScreen> {
  String _clock = '';
  late Timer _clockTimer;

  final String _role = 'Ingeniero';
  String _mode = 'manual';

  final TextEditingController _piezasController = TextEditingController(text: '1');

  final List<_PSensorModel> _sensors = [
    _PSensorModel('P1', 'P1', 'Work Piece Present at Entrance Area',
        active: false),
    _PSensorModel('P2', 'P2', 'Work Piece Present at Punching Machine',
        active: false),
    _PSensorModel('S1', 'S1', 'Punching Machine at Home Position',
        active: true),
    _PSensorModel('S2', 'S2', 'Punching Machine at Work Position',
        active: false),
  ];

  final List<_PActuatorModel> _actuators = [
    _PActuatorModel('RLY01', 'RLY01', 'Punching Machine → Home Position (M1↑)'),
    _PActuatorModel('RLY02', 'RLY02', 'Punching Machine → Work Position (M1↓)'),
    _PActuatorModel('RLY03', 'RLY03', 'Conveyor Belt → Forward (M2)'),
    _PActuatorModel('RLY04', 'RLY04', 'Conveyor Belt → Backward (M2)'),
  ];

  final List<_PLogEntry> _logs = [];
  final ScrollController _logScroll = ScrollController();

  _PSensorModel _sensor(String id) => _sensors.firstWhere((s) => s.id == id);
  _PActuatorModel _act(String id) => _actuators.firstWhere((a) => a.id == id);

  @override
  void initState() {
    super.initState();
    _updateClock();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(_updateClock);
    });
    _log('Sistema iniciado · Centro de Prensado TMPUM24-A', _PLogType.info);
    _log('Modo: $_mode · Rol: $_role', _PLogType.audit);
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
    _logScroll.dispose();
    _piezasController.dispose();
    super.dispose();
  }

  void _log(String message, _PLogType type) {
    final n = DateTime.now();
    final time =
        '${n.hour.toString().padLeft(2, '0')}:${n.minute.toString().padLeft(2, '0')}:${n.second.toString().padLeft(2, '0')}';
    
    // Clasificación para Historial General
    String severity = 'informatico';
    if (type == _PLogType.error) severity = 'critico';
    if (type == _PLogType.audit) severity = 'ejecucion';
    if (message.contains('EXITOSO') || message.contains('FINALIZADO')) severity = 'terminado';

    final monitor = Provider.of<UsageMonitor>(context, listen: false);
    monitor.logEvent(
      maqueta: 'prensado',
      message: message,
      role: _role,
      type: severity,
    );

    if (mounted) {
      setState(() {
        _logs.add(_PLogEntry(time, _role, message, type));
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_logScroll.hasClients) {
          _logScroll.animateTo(_logScroll.position.maxScrollExtent,
              duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
        }
      });
    }
  }

  void _updatePermissions() {
    final monitor = Provider.of<UsageMonitor>(context, listen: false);
    bool isRunning = monitor.isStationActive('prensado');
    for (final a in _actuators) {
      a.disabled = (_role == 'Operador' || _mode == 'auto' || isRunning);
    }
  }

  void _toggleActuator(String id, bool val) {
    final monitor = Provider.of<UsageMonitor>(context, listen: false);
    if (mounted) {
      setState(() {
        _act(id).on = val;
      });
      if (!monitor.isStationActive('prensado')) {
        monitor.incrementComponentInteraction('prensado', 'actuador', id);
        _log('Forzó $id a ${val ? 'ENCENDIDO' : 'APAGADO'}', _PLogType.audit);
      }
    }
  }

  void _toggleSensor(String id) {
    if (_mode != 'manual') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Cambia el Modo a 'Manual' para simular sensores."),
        backgroundColor: kAuditP,
      ));
      return;
    }
    final s = _sensor(id);
    final monitor = Provider.of<UsageMonitor>(context, listen: false);
    if (mounted) {
      setState(() => s.active = !s.active);
      monitor.incrementComponentInteraction('prensado', 'sensor', id);
    }
    _log('Simulación Manual: Sensor $id forzado a ${s.active ? 'DETECTANDO' : 'LIBRE'}', _PLogType.audit);
  }

  void _resetToHome({bool log = true}) {
    final monitor = Provider.of<UsageMonitor>(context, listen: false);
    if (log) _log('Restableciendo sistema a estado inicial...', _PLogType.audit);
    if (mounted) {
      setState(() {
        monitor.setStationActive('prensado', false);
        for (final a in _actuators) { a.on = false; }
        for (final s in _sensors) { s.active = false; }
        _sensor('S1').active = true;
        monitor.resetCyclePieces('prensado');
      });
    }
    if (log) _log('Sistema restablecido a la posición HOME.', _PLogType.success);
  }

  void _triggerEmergency() {
    final monitor = Provider.of<UsageMonitor>(context, listen: false);
    if (mounted) {
      setState(() {
        monitor.setStationActive('prensado', false);
        for (final a in _actuators) {
          a.on = false;
        }
      });
    }
    
    monitor.addFailure('prensado');

    _log('¡PARO DE EMERGENCIA ACTIVADO! Todos los actuadores apagados.', _PLogType.error);
    if (mounted) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: kPanelP,
          title: const Text('⚠ PARO DE EMERGENCIA', style: TextStyle(color: kRedP, fontSize: 15)),
          content: const Text('Todos los actuadores han sido desactivados.\nRevise la máquina antes de reiniciar.', style: TextStyle(color: kTextP)),
          actions: [ TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK', style: TextStyle(color: kMachineP))) ],
        ),
      );
    }
  }

  Future<void> _startAutoCycle() async {
    final monitor = Provider.of<UsageMonitor>(context, listen: false);
    if (monitor.isStationActive('prensado')) return;

    final int numPiezas = int.tryParse(_piezasController.text) ?? 0;
    if (numPiezas <= 0) {
      _log('ERROR: El número de piezas debe ser mayor a 0.', _PLogType.error);
      return;
    }

    if (!_sensor('S1').active) {
      _log('FALLA ARRANQUE: Punzón no está en posición HOME (S1 inactivo).',
          _PLogType.error);
      return;
    }
    
    monitor.setStationActive('prensado', true);
    _updatePermissions();

    _log('══ INICIANDO CICLO AUTOMÁTICO PARA $numPiezas PIEZAS ══', _PLogType.info);

    for (int i = 0; i < numPiezas; i++) {
      if (!monitor.isStationActive('prensado')) break;
      _log('--- Procesando pieza ${i + 1} de $numPiezas ---', _PLogType.info);
      await _runSingleCycle();
      if (!monitor.isStationActive('prensado')) {
        _log('Ciclo interrumpido por PARO DE EMERGENCIA.', _PLogType.error);
        break;
      }
      
      monitor.addProduction('prensado');
    }

    monitor.setStationActive('prensado', false);
    _updatePermissions();
    _log('══ CICLO AUTOMÁTICO FINALIZADO ══', _PLogType.info);
    monitor.syncStationAuditoria('prensado'); // Sincronizar
  }

  Future<void> _runSingleCycle() async {
    final monitor = Provider.of<UsageMonitor>(context, listen: false);
    try {
      if (!monitor.isStationActive('prensado') || !mounted) return;
      _log('Avanzando banda de entrada...', _PLogType.info);
      setState(() => _sensor('P1').active = true);
      _toggleActuator('RLY03', true); await Future.delayed(const Duration(seconds: 2));
      if (!monitor.isStationActive('prensado') || !mounted) return;
      setState(() { _sensor('P1').active = false; _sensor('P2').active = true; });
      _toggleActuator('RLY03', false); await Future.delayed(const Duration(milliseconds: 500));
      if (!monitor.isStationActive('prensado') || !mounted) return;
      _log('Iniciando prensado (Punzón bajando)...', _PLogType.info);
      setState(() => _sensor('S1').active = false);
      _toggleActuator('RLY02', true); await Future.delayed(const Duration(seconds: 2));
      if (!monitor.isStationActive('prensado') || !mounted) return;
      setState(() => _sensor('S2').active = true);
      _toggleActuator('RLY02', false); await Future.delayed(const Duration(seconds: 1));
      if (!monitor.isStationActive('prensado') || !mounted) return;
      _log('Elevando punzón...', _PLogType.info);
      setState(() => _sensor('S2').active = false);
      _toggleActuator('RLY01', true); await Future.delayed(const Duration(seconds: 2));
      if (!monitor.isStationActive('prensado') || !mounted) return;
      setState(() => _sensor('S1').active = true);
      _toggleActuator('RLY01', false); await Future.delayed(const Duration(milliseconds: 500));
      if (!monitor.isStationActive('prensado') || !mounted) return;
      _log('Expulsando pieza terminada...', _PLogType.info);
      _toggleActuator('RLY03', true); await Future.delayed(const Duration(seconds: 2));
      if (!monitor.isStationActive('prensado') || !mounted) return;
      setState(() => _sensor('P2').active = false);
      _toggleActuator('RLY03', false);
      _log('✔ CICLO EXITOSO.', _PLogType.success);
    } catch (_) {
      _log('Error en secuencia automática.', _PLogType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final monitor = Provider.of<UsageMonitor>(context);
    final bool isRunning = monitor.isStationActive('prensado');
    final int piezas = monitor.getCycleFinishedPieces('prensado');

    return Scaffold(
      backgroundColor: kBgP,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              _buildTopBar(isRunning, piezas),
              const SizedBox(height: 12),
              _buildDigitalTwin(),
              const SizedBox(height: 12),
              _buildAuditPanel(),
              const SizedBox(height: 12),
              _buildControlRow(),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() => Container(
    padding: const EdgeInsets.only(bottom: 10),
    decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: kMachineP, width: 2))),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: const [
        Text('CENTRO DE PRENSADO SCADA', style: TextStyle(color: kMachineP, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.4)),
      ],
    ),
  );

  Widget _buildTopBar(bool isRunning, int piezas) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: kPanelP, border: Border.all(color: kBorderP), borderRadius: BorderRadius.circular(8)),
    child: Wrap(
      spacing: 16,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _labeledSelect('Modo:', _mode, {
          'manual': 'Manual (Simulación Física)',
          'auto': 'Automático',
        }, (v) {
          if(mounted) setState(() => _mode = v!);
          _updatePermissions();
        }),
        _buildPiezasInput(isRunning),
        ElevatedButton.icon(
          onPressed: (_mode == 'auto' && !isRunning) ? _startAutoCycle : null,
          icon: Icon(isRunning ? Icons.hourglass_top_rounded : Icons.play_circle_filled_rounded, size: 16),
          label: Text(isRunning ? 'PROCESANDO...' : 'INICIAR CICLO'),
          style: ElevatedButton.styleFrom(
            backgroundColor: kGreenP, foregroundColor: Colors.black,
            disabledBackgroundColor: const Color(0xFF333333), disabledForegroundColor: const Color(0xFF666666),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
        ElevatedButton.icon(
          onPressed: _triggerEmergency,
          icon: const Icon(Icons.warning_amber_rounded, size: 16),
          label: const Text('PARO EMERGENCIA'),
          style: ElevatedButton.styleFrom(
            backgroundColor: kRedP, foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
        ElevatedButton.icon(
          onPressed: isRunning ? null : () => _resetToHome(),
          icon: const Icon(Icons.replay_circle_filled_rounded, size: 16),
          label: const Text('RESTABLECER'),
          style: ElevatedButton.styleFrom(
            backgroundColor: kMachineP, foregroundColor: Colors.black,
            disabledBackgroundColor: const Color(0xFF333333), disabledForegroundColor: const Color(0xFF666666),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
        _kpiBox('Piezas Terminadas', '$piezas'),
      ],
    ),
  );

  Widget _buildPiezasInput(bool isRunning) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      const Text("Piezas:", style: TextStyle(color: kTextP, fontSize: 12)),
      const SizedBox(width: 8),
      SizedBox(
        width: 60, height: 38,
        child: TextField(
          controller: _piezasController,
          enabled: _mode == 'auto' && !isRunning,
          keyboardType: TextInputType.number,
          inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
          textAlign: TextAlign.center,
          style: const TextStyle(color: kMachineP, fontSize: 16, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            filled: true, fillColor: kBgP,
            contentPadding: EdgeInsets.zero,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: kBorderP)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: kBorderP)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: kMachineP, width: 2)),
          ),
        ),
      ),
    ],
  );

  Widget _labeledSelect(String lbl, String val, Map<String, String> items, ValueChanged<String?> onChanged) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Text(lbl, style: const TextStyle(color: kTextP, fontSize: 13)),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(color: kBgP, border: Border.all(color: kMachineP), borderRadius: BorderRadius.circular(4)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: val, dropdownColor: kPanelP,
              style: const TextStyle(color: kMachineP, fontSize: 12, fontWeight: FontWeight.bold),
              icon: const Icon(Icons.arrow_drop_down, color: kMachineP, size: 18),
              isDense: true,
              items: items.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ]);

  Widget _kpiBox(String label, String value) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
    decoration: BoxDecoration(color: kGreenP.withValues(alpha: 0.1), border: Border.all(color: kGreenP), borderRadius: BorderRadius.circular(6)),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Text(label, style: const TextStyle(color: kTextP, fontSize: 10)),
      const SizedBox(height: 2),
      Text(value, style: const TextStyle(color: kGreenP, fontSize: 24, fontWeight: FontWeight.bold)),
    ]),
  );

  Widget _buildDigitalTwin() => _panel(
    title: 'Gemelo Digital 2D · Centro de Prensado',
    child: Container(
      height: 320,
      decoration: BoxDecoration(color: kDarkP, border: Border.all(color: kBorderP.withValues(alpha: 0.3)), borderRadius: BorderRadius.circular(4)),
      child: Stack(
        children: [
          Positioned(top: 15, right: 15, child: Text('VISTA LATERAL', style: TextStyle(color: kMachineP.withValues(alpha: 0.5), fontSize: 10, fontWeight: FontWeight.bold))),
          Center(child: Container(width: 500, child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(left: 50, top: 220, right: 50, child: Container(height: 15, decoration: BoxDecoration(color: kBorderP, borderRadius: BorderRadius.circular(2)))),
              Positioned(left: 80, bottom: 85, child: AnimatedContainer(duration: const Duration(milliseconds: 300), width: 340, height: 10, decoration: BoxDecoration(color: _act('RLY03').on ? kMachineP : Colors.grey[800], borderRadius: BorderRadius.circular(5)))),
              Positioned(top: 30, child: Container(width: 120, height: 10, color: kBorderP)),
              Positioned(top: 40, child: Container(width: 10, height: 180, color: kBorderP)),
              Positioned(top: 40 + (1 - (_sensor('S1').active ? 1 : (_sensor('S2').active ? 0 : 0.5))) * 120, child: AnimatedContainer(duration: const Duration(milliseconds: 500), width: 80, height: 40, decoration: BoxDecoration(color: kPanelP, border: Border.all(color: kMachineP, width: 2), borderRadius: BorderRadius.circular(4)), child: Center(child: Text('M1', style: TextStyle(color: kMachineP, fontWeight: FontWeight.bold))))),
            ],
          ))),
        ],
      ),
    ),
  );

  Widget _buildAuditPanel() => _panel(
    title: 'Auditoría (Audit Trail) y Alertas',
    child: Container(
      height: 180, decoration: BoxDecoration(color: kBgP, border: Border.all(color: kBorderP), borderRadius: BorderRadius.circular(4)),
      padding: const EdgeInsets.all(10),
      child: ListView.builder(
        controller: _logScroll, itemCount: _logs.length,
        itemBuilder: (_, i) {
          final l = _logs[i];
          return Text('[${l.time}] [${l.user}] - ${l.message}', style: TextStyle(color: l.color, fontSize: 11, fontFamily: 'monospace'));
        },
      ),
    ),
  );

  Widget _buildControlRow() => SizedBox(
    height: 300,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: _buildActuatorsPanel()),
        const SizedBox(width: 12),
        Expanded(child: _buildSensorsPanel()),
      ],
    ),
  );

  Widget _buildSensorsPanel() => _panel(
    title: 'Sensores (4)', 
    child: Expanded(
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: _sensors.map(_sensorRow).toList()),
      ),
    )
  );

  Widget _sensorRow(_PSensorModel s) {
    final Color color = s.active ? kGreenP : const Color(0xFF333333);
    return GestureDetector(
      onTap: () => _toggleSensor(s.id),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
        decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(6), border: Border.all(color: s.active ? kGreenP.withValues(alpha: 0.4) : Colors.transparent)),
        child: Row(children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(shape: BoxShape.circle, color: color, boxShadow: s.active ? [BoxShadow(color: color.withValues(alpha: 0.8), blurRadius: 8)] : null)),
          const SizedBox(width: 12),
          Expanded(child: Text('${s.id}: ${s.label}', style: const TextStyle(color: kTextP, fontSize: 13, fontWeight: FontWeight.w500))),
        ]),
      ),
    );
  }

  Widget _buildActuatorsPanel() => _panel(
    title: 'Actuadores (RLY01–RLY04)', 
    child: Expanded(
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: _actuators.map(_actuatorRow).toList()),
      ),
    )
  );

  Widget _actuatorRow(_PActuatorModel a) => Container(
    margin: const EdgeInsets.symmetric(vertical: 4),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(6), border: Border.all(color: a.on ? kMachineP.withValues(alpha: 0.4) : Colors.transparent)),
    child: Row(children: [
      Expanded(child: Text(a.id, style: TextStyle(color: a.on ? kMachineP : kTextP, fontSize: 12, fontWeight: FontWeight.bold))),
      Transform.scale(scale: 0.8, child: Switch(value: a.on, onChanged: a.disabled ? null : (v) => _toggleActuator(a.id, v), activeTrackColor: kMachineP, activeThumbColor: Colors.white, inactiveTrackColor: const Color(0xFF333333))),
    ]),
  );

  Widget _panel({required String title, required Widget child}) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: kPanelP, border: Border.all(color: kBorderP), borderRadius: BorderRadius.circular(8)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
      Container(padding: const EdgeInsets.only(bottom: 6), decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: kBorderP))), child: Text(title, style: const TextStyle(color: kMachineP, fontSize: 12, fontWeight: FontWeight.bold))),
      const SizedBox(height: 8),
      child,
    ]),
  );
}
