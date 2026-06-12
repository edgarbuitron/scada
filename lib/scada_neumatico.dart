import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'usage_monitor.dart';
import 'schedule_guard.dart';
import 'horario_fuera.dart';

// ── Paleta propia ──
const Color kBg = Color(0xFF081014);
const Color kPanel = Color(0xFF11222C);
const Color kCyanN = Color(0xFF00EAFF);
const Color kGreenN = Color(0xFF00FF88);
const Color kRedN = Color(0xFFFF3366);
const Color kBorderN = Color(0xFF1A3644);
const Color kText = Color(0xFFC5D1D8);
const Color kAudit = Color(0xFFFFAA00);
const Color kDark = Color(0xFF0C1820);

// ── Modelos internos ────────────────────────────
enum _NLogType { info, audit, error, success }

class _NLogEntry {
  final String time, role, message;
  final _NLogType type;
  const _NLogEntry(this.time, this.role, this.message, this.type);
  Color get color => type == _NLogType.error
      ? kRedN
      : type == _NLogType.audit
      ? kAudit
      : type == _NLogType.success
      ? kGreenN
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
  final String _role = 'Ingeniero';
  String _mode = 'manual';
  double _pressure = 1.0;

  final TextEditingController _piezasController = TextEditingController(text: '1');
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

  _SensorModel _sensor(String id) => _sensors.firstWhere((s) => s.id == id);
  _ActuatorModel _act(String id) => _actuators.firstWhere((a) => a.id == id);

  @override
  void initState() {
    super.initState();
    _updateClock();
    _clockTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if(mounted) {
        setState(() {
          _updateClock();
          _simulatePressure();
        });
      }
    });
    _logAudit('Configuración cambiada a Modo: $_mode', _NLogType.audit);
    _resetToHome(log: false);
  }

  void _updateClock() {
    final n = DateTime.now();
    _clock =
    '${n.hour.toString().padLeft(2, '0')}:${n.minute.toString().padLeft(2, '0')}:${n.second.toString().padLeft(2, '0')}';
  }

  void _simulatePressure() {
    if (_act('M1').on) _pressure += 0.2;
    else _pressure -= 0.05;
    _pressure += (Random().nextDouble() - 0.5) * 0.1;
    _pressure = _pressure.clamp(1.0, 5.0);
    if(mounted) {
      setState(() {
        _chartData.removeAt(0);
        _chartData.add(_pressure);
      });
    }
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    _logScroll.dispose();
    _piezasController.dispose();
    super.dispose();
  }

  void _logAudit(String message, _NLogType type) {
    final n = DateTime.now();
    final time =
        '${n.hour.toString().padLeft(2, '0')}:${n.minute.toString().padLeft(2, '0')}:${n.second.toString().padLeft(2, '0')}';
    
    // Clasificación para Historial General
    String severity = 'informatico';
    if (type == _NLogType.error) severity = 'critico';
    if (type == _NLogType.audit) severity = 'ejecucion';
    if (message.contains('EXITOSO') || message.contains('FINALIZADO')) severity = 'terminado';

    final monitor = Provider.of<UsageMonitor>(context, listen: false);
    monitor.logEvent(
      maqueta: 'neumatico',
      message: message,
      role: _role,
      type: severity,
    );

    if(mounted) {
      setState(() => _logs.add(_NLogEntry(time, _role, message, type)));
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
    bool isRunning = monitor.isStationActive('neumatico');
    for (final a in _actuators) {
      a.disabled = (_role == 'Operador' || _mode == 'auto' || isRunning);
    }
    _logAudit('Configuración cambiada a Modo: $_mode', _NLogType.audit);
  }

  void _toggleActuator(String id, bool val) async {
    // VALIDACIÓN DE HORARIO INDUSTRIAL
    final bool canOperate = await ScheduleGuard.canConnectToHardware();
    if (!canOperate) {
      if (mounted) mostrarBloqueoHorario(context);
      return;
    }

    final monitor = Provider.of<UsageMonitor>(context, listen: false);
    if(mounted) setState(() => _act(id).on = val);
    if (!monitor.isStationActive('neumatico')) {
      monitor.incrementComponentInteraction('neumatico', 'actuador', id);
      _logAudit('Forzó $id a ${val ? 'ENCENDIDO' : 'APAGADO'}', _NLogType.audit);
    }
  }

  void _resetToHome({bool log = true}){
    final monitor = Provider.of<UsageMonitor>(context, listen: false);
    if(log) _logAudit('Restableciendo sistema a estado inicial...', _NLogType.audit);
    if(mounted) {
      setState(() {
        monitor.setStationActive('neumatico', false);
        for (final a in _actuators) { a.on = false; }
        for (final s in _sensors) { s.active = false; }
        _sensor('P1').active = true;
        monitor.resetCyclePieces('neumatico');
      });
    }
    if(log) _logAudit('Sistema restablecido a la posición HOME.', _NLogType.success);
  }

  Future<void> _startAutoCycle() async {
    final monitor = Provider.of<UsageMonitor>(context, listen: false);
    if (monitor.isStationActive('neumatico')) return;

    final int numPiezas = int.tryParse(_piezasController.text) ?? 0;
    if (numPiezas <= 0) {
      _logAudit('ERROR: El número de ciclos debe ser mayor a 0.', _NLogType.error);
      return;
    }
    if (_pressure < 2.5) {
      _logAudit('Falla de arranque: Presión neumática insuficiente.', _NLogType.error);
      return;
    }
    
    monitor.setStationActive('neumatico', true);
    _updatePermissions();

    _logAudit('══ INICIANDO CICLO AUTOMÁTICO PARA $numPiezas CICLOS ══', _NLogType.info);

    for (int i = 0; i < numPiezas; i++) {
      if (!monitor.isStationActive('neumatico')) break;
      _logAudit('--- Procesando pieza ${i + 1} de $numPiezas ---', _NLogType.info);
      await _runSingleCycle();
      if (!monitor.isStationActive('neumatico')) {
        _logAudit('Ciclo interrumpido por PARO DE EMERGENCIA.', _NLogType.error);
        break;
      }
      // Incrementar producción real
      monitor.addProduction('neumatico');
    }

    monitor.setStationActive('neumatico', false);
    _updatePermissions();
    _logAudit('══ CICLO AUTOMÁTICO FINALIZADO ══', _NLogType.info);
    monitor.syncStationAuditoria('neumatico'); // Sincronizar al finalizar ciclo
  }

  Future<void> _runSingleCycle() async {
    final monitor = Provider.of<UsageMonitor>(context, listen: false);
    try {
      if (!monitor.isStationActive('neumatico') || !mounted) return;
      _toggleActuator('V1', true); setState(() => _sensor('P1').active = false);
      await Future.delayed(const Duration(seconds: 1));
      if (!monitor.isStationActive('neumatico') || !mounted) return; _toggleActuator('V1', false);
      _toggleActuator('M3', true); await Future.delayed(const Duration(milliseconds: 1500));
      if (!monitor.isStationActive('neumatico') || !mounted) return; setState(() => _sensor('P2').active = true);
      _toggleActuator('M3', false); _toggleActuator('M2', true);
      await Future.delayed(const Duration(seconds: 1));
      if (!monitor.isStationActive('neumatico') || !mounted) return; setState(() => _sensor('S1').active = true);
      _toggleActuator('M2', false); _toggleActuator('V3', true);
      await Future.delayed(const Duration(milliseconds: 1500));
      if (!monitor.isStationActive('neumatico') || !mounted) return; _toggleActuator('V3', false);
      _toggleActuator('V4', true); await Future.delayed(const Duration(seconds: 1));
      if (!monitor.isStationActive('neumatico') || !mounted) return; _toggleActuator('V4', false);
      if(mounted) setState(() { _sensor('P2').active = false; _sensor('S1').active = false; _sensor('P1').active = true; });
      _logAudit('CICLO EXITOSO. Pieza terminada.', _NLogType.success);
    } catch (_) {
      _logAudit('Error en la secuencia automática.', _NLogType.error);
    }
  }

  void _triggerEmergency() {
    final monitor = Provider.of<UsageMonitor>(context, listen: false);
    if(mounted) {
      setState(() {
        monitor.setStationActive('neumatico', false);
        for (final a in _actuators) { a.on = false; }
      });
    }
    // Registrar falla real en monitor
    monitor.addFailure('neumatico');

    _logAudit('¡PARO DE EMERGENCIA (S2) ACTIVADO! Desconectando energía...', _NLogType.error);
    if(mounted) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: kPanel,
          title: const Text('⚠ ALERTA DE SEGURIDAD', style: TextStyle(color: kRedN, fontSize: 14)),
          content: const Text('Paro de Emergencia presionado. Todos los actuadores detenidos.', style: TextStyle(color: kText)),
          actions: [ TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK', style: TextStyle(color: kCyanN))) ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final monitor = Provider.of<UsageMonitor>(context);
    final bool isRunning = monitor.isStationActive('neumatico');
    final int piezas = monitor.getCycleFinishedPieces('neumatico');

    return Scaffold(
      backgroundColor: kBg,
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              _buildTopBar(isRunning, piezas),
              const SizedBox(height: 10),
              _buildDigitalTwin(), 
              const SizedBox(height: 16),
              _buildAuditPanel(), 
              const SizedBox(height: 16),
              _buildBottomRow(),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() => Container(
    padding: const EdgeInsets.only(bottom: 10),
    decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: kCyanN, width: 2))),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('CENTRO NEUMÁTICO SCADA', style: TextStyle(color: kCyanN, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1.4)),
      ],
    ),
  );

  Widget _buildTopBar(bool isRunning, int piezas) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: kPanel, border: Border.all(color: kBorderN), borderRadius: BorderRadius.circular(8)),
    child: Wrap(
      spacing: 16,
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
        _buildPiezasInput(isRunning),
        ElevatedButton.icon(
          onPressed: (_mode == 'auto' && !isRunning) ? _startAutoCycle : null,
          icon: Icon(isRunning ? Icons.stop_circle_rounded : Icons.play_circle_fill_rounded, size: 16),
          label: Text(isRunning ? 'PROCESANDO...' : 'INICIAR CICLO'),
          style: ElevatedButton.styleFrom(
            backgroundColor: kGreenN, foregroundColor: Colors.black,
            disabledBackgroundColor: const Color(0xFF333333), disabledForegroundColor: const Color(0xFF666666),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),
        ElevatedButton.icon(
          onPressed: _triggerEmergency,
          icon: const Icon(Icons.warning_amber_rounded, size: 16),
          label: const Text('PARO EMERGENCIA'),
          style: ElevatedButton.styleFrom(
            backgroundColor: kRedN, foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),
        ElevatedButton.icon(
          onPressed: isRunning ? null : () => _resetToHome(),
          icon: const Icon(Icons.replay_circle_filled_rounded, size: 16),
          label: const Text('RESTABLECER'),
          style: ElevatedButton.styleFrom(
            backgroundColor: kCyanN, foregroundColor: Colors.black,
            disabledBackgroundColor: const Color(0xFF333333), disabledForegroundColor: const Color(0xFF666666),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),
        _kpiBox('Piezas Terminadas', '$piezas'),
      ],
    ),
  );

  Widget _buildPiezasInput(bool isRunning) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      const Text("Piezas:", style: TextStyle(color: kText, fontSize: 12)),
      const SizedBox(width: 8),
      SizedBox(
        width: 60,
        height: 38,
        child: TextField(
          controller: _piezasController,
          enabled: _mode == 'auto' && !isRunning,
          keyboardType: TextInputType.number,
          inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
          textAlign: TextAlign.center,
          style: TextStyle(color: (_mode == 'auto' && !isRunning) ? kCyanN : Colors.grey, fontSize: 16, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            filled: true,
            fillColor: kBg,
            contentPadding: const EdgeInsets.symmetric(vertical: 8.0),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide(color: (_mode == 'auto' && !isRunning) ? kCyanN : kBorderN)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide(color: (_mode == 'auto' && !isRunning) ? kCyanN : kBorderN)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: kCyanN, width: 2)),
            disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide(color: kBorderN)),
          ),
        ),
      ),
    ],
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
              items: items.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ]);

  Widget _kpiBox(String label, String value) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
    decoration: BoxDecoration(
      color: kGreenN.withValues(alpha: 0.1),
      border: Border.all(color: kGreenN),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Text(label, style: const TextStyle(color: kText, fontSize: 11)),
      const SizedBox(height: 2),
      Text(value, style: const TextStyle(color: kGreenN, fontSize: 24, fontWeight: FontWeight.bold)),
    ]),
  );

  Widget _buildDigitalTwin() => Container(
    height: 350,
    decoration: BoxDecoration(
      color: kDark,
      border: Border.all(color: kCyanN),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Stack(children: [
      const Positioned(
        top: 15, right: 20,
        child: Text('Gemelo Digital 2D', style: TextStyle(color: kCyanN, fontWeight: FontWeight.bold, fontSize: 14)),
      ),
      Center(
        child: Container(
          width: 800,
          child: Stack(
            children: [
              Positioned(top: 40, left: 50, child: _dtPart('M1', 'Compresor\n(M1)', w: 90, h: 90, circle: true)),
              Positioned(top: 130, left: 200, child: _dtPart('V1', 'V1', w: 45, h: 45)),
              Positioned(top: 190, left: 200, child: _dtPart('M3', 'Banda Transportadora (M3)', w: 300, h: 45)),
              Positioned(top: 80, right: 150, child: _dtPart('V3', 'V3', w: 45, h: 45)),
              Positioned(top: 150, right: 80, child: _dtPart('M2', 'Mesa\nGiratoria\n(M2)', w: 120, h: 120, circle: true)),
              Positioned(top: 280, right: 150, child: _dtPart('V4', 'V4', w: 45, h: 45)),
            ],
          ),
        ),
      ),
    ]),
  );

  Widget _dtPart(String id, String label, {required double w, required double h, bool circle = false}) {
    bool active = false;
    try { active = _actuators.firstWhere((a) => a.id == id).on; } catch (_) {}
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: w, height: h, alignment: Alignment.center,
      decoration: BoxDecoration(
        color: active ? kGreenN : const Color(0xFF333333),
        border: Border.all(color: active ? Colors.white : const Color(0xFF555555), width: 2),
        borderRadius: BorderRadius.circular(circle ? h / 2 : 4),
        boxShadow: active ? [BoxShadow(color: kGreenN.withValues(alpha: 0.6), blurRadius: 15)] : null,
      ),
      child: Text(label, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildAuditPanel() => _panel(
    title: 'Auditoría (Audit Trail) y Alertas',
    child: Container(
      height: 250,
      decoration: BoxDecoration(color: kBg, border: Border.all(color: kBorderN), borderRadius: BorderRadius.circular(4)),
      padding: const EdgeInsets.all(10),
      child: ListView.builder(
        controller: _logScroll,
        itemCount: _logs.length,
        itemBuilder: (_, i) {
          final l = _logs[i];
          return Text(
            '[${l.time}] [${l.role}] - ${l.message}',
            style: TextStyle(color: l.color, fontSize: 11, fontFamily: 'monospace', fontWeight: l.type == _NLogType.audit ? FontWeight.bold : FontWeight.normal),
          );
        },
      ),
    ),
  );

  Widget _buildBottomRow() => SizedBox(
    height: 380,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: _buildSensorsPanel()),
        const SizedBox(width: 12),
        Expanded(child: _buildActuatorsPanel()),
      ],
    ),
  );

  Widget _buildSensorsPanel() => _panel(
    title: 'Sensores (5)',
    child: Expanded(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: _sensors.map(_sensorRow).toList(),
        ),
      ),
    ),
  );

  Widget _sensorRow(_SensorModel s) {
    final Color color = s.active ? kGreenN : const Color(0xFF333333);
    return GestureDetector(
      onTap: () {
        if (_mode == 'manual') {
          setState(() => s.active = !s.active);
          final monitor = Provider.of<UsageMonitor>(context, listen: false);
          monitor.incrementComponentInteraction('neumatico', 'sensor', s.id);
          _logAudit('Simulación Manual: Sensor ${s.id} forzado a ${s.active ? 'DETECTANDO' : 'LIBRE'}', _NLogType.audit);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Cambia el Modo a 'Manual' para simular sensores."), backgroundColor: kAudit));
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
        decoration: BoxDecoration(
          color: s.active ? kGreenN.withValues(alpha: 0.07) : Colors.black.withValues(alpha: 0.3),
          border: Border.all(color: s.active ? kGreenN.withValues(alpha: 0.4) : kBorderN),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(children: [
          Container(
            width: 10, height: 10,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color, boxShadow: s.active ? [BoxShadow(color: color.withValues(alpha: 0.8), blurRadius: 8)] : null),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(s.label, style: const TextStyle(color: kText, fontSize: 12, fontWeight: FontWeight.w500))),
        ]),
      ),
    );
  }

  Widget _buildActuatorsPanel() => _panel(
    title: 'Actuadores (M1-V4)',
    child: Expanded(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: _actuators.map(_actuatorRow).toList(),
        ),
      ),
    ),
  );

  Widget _actuatorRow(_ActuatorModel a) => Container(
    margin: const EdgeInsets.symmetric(vertical: 4),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(
      color: a.on ? kCyanN.withValues(alpha: 0.07) : Colors.black.withValues(alpha: 0.3),
      border: Border.all(color: a.on ? kCyanN.withValues(alpha: 0.4) : kBorderN),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Row(children: [
      Expanded(child: Text(a.label, style: const TextStyle(color: kText, fontSize: 12, fontWeight: FontWeight.bold))),
      Transform.scale(
        scale: 0.8,
        child: Switch(value: a.on, onChanged: a.disabled ? null : (v) => _toggleActuator(a.id, v), activeThumbColor: Colors.white, activeTrackColor: kCyanN, inactiveThumbColor: Colors.white, inactiveTrackColor: const Color(0xFF333333)),
      ),
    ]),
  );

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
          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: kBorderN))),
          child: Text(title, style: const TextStyle(color: kCyanN, fontSize: 13, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 8),
        child,
      ],
    ),
  );
}
