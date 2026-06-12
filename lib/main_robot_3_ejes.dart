import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'usage_monitor.dart';

// ── Paleta Unificada (Basada en Neumático) ──────────────────────────────────
const Color kBg = Color(0xFF081014);
const Color kPanel = Color(0xFF11222C);
const Color kMachine = Color(0xFF00EAFF); // Color principal de acento
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

  final String _role = 'Ingeniero';
  String _mode = 'manual';

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
    ActuatorModel('RLY01', 'RLY01', 'Base CW'),
    ActuatorModel('RLY02', 'RLY02', 'Base CCW'),
    ActuatorModel('RLY03', 'RLY03', 'Expandir Brazo'),
    ActuatorModel('RLY04', 'RLY04', 'Retraer Brazo'),
    ActuatorModel('RLY05', 'RLY05', 'Eje Z Arriba'),
    ActuatorModel('RLY06', 'RLY06', 'Eje Z Abajo'),
    ActuatorModel('RLY07', 'RLY07', 'Abrir Gripper'),
    ActuatorModel('RLY08', 'RLY08', 'Cerrar Gripper'),
  ];

  final List<LogEntry> _logs = [];
  final ScrollController _logScroll = ScrollController();

  SensorModel _sensor(String id) => _sensors.firstWhere((s) => s.id == id);
  ActuatorModel _act(String id) => _actuators.firstWhere((a) => a.id == id);

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
    _logScroll.dispose();
    _rotAnim.dispose();
    _piezasController.dispose();
    super.dispose();
  }

  void _logAudit(String msg, LogType type) {
    final n = DateTime.now();
    final t =
        '${n.hour.toString().padLeft(2, '0')}:${n.minute.toString().padLeft(2, '0')}:${n.second.toString().padLeft(2, '0')}';

    // Clasificación para Historial General
    String severity = 'informatico';
    if (type == LogType.error) severity = 'critico';
    if (type == LogType.audit) severity = 'ejecucion';
    if (msg.contains('EXITOSO') || msg.contains('FINALIZADO')) severity = 'terminado';

    final monitor = Provider.of<UsageMonitor>(context, listen: false);
    monitor.logEvent(
      maqueta: 'robot',
      message: msg,
      role: _role,
      type: severity,
    );

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
    final monitor = Provider.of<UsageMonitor>(context, listen: false);
    bool isRunning = monitor.isStationActive('robot');
    for (final a in _actuators) {
      a.disabled = (_role == 'Operador' || _mode == 'auto' || isRunning);
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
    final monitor = Provider.of<UsageMonitor>(context, listen: false);
    if(mounted) {
      setState(() => s.active = !s.active);
      monitor.incrementComponentInteraction('robot', 'sensor', id);
    }
    _logAudit(
        'Simulación Manual: Sensor ${s.id} forzado a ${s.active ? 'DETECTANDO' : 'LIBRE'}',
        LogType.audit);
  }

  void _toggleActuator(String id, bool val) {
    final monitor = Provider.of<UsageMonitor>(context, listen: false);
    if(mounted) {
      setState(() => _act(id).on = val);
      _updateRobotVisuals(id, val);
      if (!monitor.isStationActive('robot')) {
        monitor.incrementComponentInteraction('robot', 'actuador', id);
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
    final monitor = Provider.of<UsageMonitor>(context, listen: false);
    if(log) _logAudit('Restableciendo sistema a estado inicial...', LogType.audit);
    if(mounted) {
      setState(() {
        monitor.setStationActive('robot', false);
        for (final a in _actuators) { a.on = false; }
        for (final s in _sensors) { s.active = false; }
        _sensor('S3').active = true;
        _sensor('S6').active = true;
        _sensor('S8').active = true;
        _baseAngle = 0;
        _armExtend = 0;
        _zPosition = 0;
        _gripperClosed = false;
        monitor.resetCyclePieces('robot');
      });
    }
    if(log) {
      _logAudit('Sistema restablecido a la posición HOME.', LogType.success);
    }
  }

  void _triggerEmergency() {
    final monitor = Provider.of<UsageMonitor>(context, listen: false);
    if (mounted) {
      setState(() {
        monitor.setStationActive('robot', false);
        for (final a in _actuators) { a.on = false; }
      });
    }

    monitor.addFailure('robot');

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
    final monitor = Provider.of<UsageMonitor>(context, listen: false);
    if (monitor.isStationActive('robot')) return;

    final int numPiezas = int.tryParse(_piezasController.text) ?? 0;
    if (numPiezas <= 0) {
      _logAudit('ERROR: El número de ciclos debe ser mayor a 0.', LogType.error);
      return;
    }

    monitor.setStationActive('robot', true);
    _updatePermissions();

    _logAudit('══ INICIANDO CICLO AUTOMÁTICO PARA $numPiezas CICLOS ══', LogType.info);
    for (int i = 0; i < numPiezas; i++) {
      if (!monitor.isStationActive('robot')) break;
      _logAudit('--- Ejecutando Pick & Place ${i + 1} de $numPiezas ---', LogType.info);
      await _runSingleCycle();
      if (!monitor.isStationActive('robot')) {
        _logAudit('Ciclo interrumpido por PARO DE EMERGENCIA.', LogType.error);
        break;
      }

      monitor.addProduction('robot');
    }

    monitor.setStationActive('robot', false);
    _updatePermissions();
    _logAudit('══ CICLO AUTOMÁTICO FINALIZADO ══', LogType.info);
    monitor.syncStationAuditoria('robot'); // Sincronizar
  }

  Future<void> _runSingleCycle() async {
    final monitor = Provider.of<UsageMonitor>(context, listen: false);
    try {
      if (!monitor.isStationActive('robot') || !mounted) return;
      _toggleActuator('RLY01', true); await Future.delayed(const Duration(seconds: 1));
      if (!monitor.isStationActive('robot') || !mounted) return; _toggleActuator('RLY01', false);
      _toggleActuator('RLY06', true); await Future.delayed(const Duration(milliseconds: 800));
      if (!monitor.isStationActive('robot') || !mounted) return; _toggleActuator('RLY06', false);
      _toggleActuator('RLY08', true); await Future.delayed(const Duration(milliseconds: 500));
      if (!monitor.isStationActive('robot') || !mounted) return;
      _toggleActuator('RLY05', true); await Future.delayed(const Duration(milliseconds: 800));
      if (!monitor.isStationActive('robot') || !mounted) return; _toggleActuator('RLY05', false);
      _toggleActuator('RLY02', true); await Future.delayed(const Duration(seconds: 1));
      if (!monitor.isStationActive('robot') || !mounted) return; _toggleActuator('RLY02', false);
      _toggleActuator('RLY07', true); await Future.delayed(const Duration(milliseconds: 500));
      _logAudit('CICLO EXITOSO. Robot regresando a HOME.', LogType.success);
    } catch (_) {
      _logAudit('Error en la secuencia del Robot.', LogType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final monitor = Provider.of<UsageMonitor>(context);
    final bool isRunning = monitor.isStationActive('robot');
    final int piezasTerminadas = monitor.getCycleFinishedPieces('robot');

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
              _buildTopBar(isRunning, piezasTerminadas),
              const SizedBox(height: 12),
              _buildDigitalTwin(),
              const SizedBox(height: 12),
              _buildAuditPanel(),
              const SizedBox(height: 12),
              _buildControlRow(),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() => Container(
    padding: const EdgeInsets.only(bottom: 10),
    decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: kMachine, width: 2))),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: const [
        Text('ROBOT 3 EJES', style: TextStyle(color: kMachine, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.4)),
      ],
    ),
  );

  Widget _buildTopBar(bool isRunning, int piezas) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: kPanel, border: Border.all(color: kBorder), borderRadius: BorderRadius.circular(8)),
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
          icon: Icon(isRunning ? Icons.hourglass_top_rounded : Icons.smart_toy_rounded, size: 16),
          label: Text(isRunning ? 'PROCESANDO...' : 'INICIAR CICLO'),
          style: ElevatedButton.styleFrom(
            backgroundColor: kGreen, foregroundColor: Colors.black,
            disabledBackgroundColor: const Color(0xFF333333), disabledForegroundColor: const Color(0xFF666666),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
        ElevatedButton.icon(
          onPressed: _triggerEmergency,
          icon: const Icon(Icons.warning_amber_rounded, size: 16),
          label: const Text('PARO EMERGENCIA'),
          style: ElevatedButton.styleFrom(
            backgroundColor: kRed, foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
        ElevatedButton.icon(
          onPressed: isRunning ? null : () => _resetToHome(),
          icon: const Icon(Icons.replay_circle_filled_rounded, size: 16),
          label: const Text('RESTABLECER'),
          style: ElevatedButton.styleFrom(
            backgroundColor: kMachine, foregroundColor: Colors.black,
            disabledBackgroundColor: const Color(0xFF333333), disabledForegroundColor: const Color(0xFF666666),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
        _kpiBox('Ciclos Completados', '$piezas'),
      ],
    ),
  );

  Widget _buildPiezasInput(bool isRunning) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      const Text("Ciclos:", style: TextStyle(color: kText, fontSize: 12)),
      const SizedBox(width: 8),
      SizedBox(
        width: 60, height: 38,
        child: TextField(
          controller: _piezasController,
          enabled: _mode == 'auto' && !isRunning,
          keyboardType: TextInputType.number,
          inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
          textAlign: TextAlign.center,
          style: const TextStyle(color: kMachine, fontSize: 16, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            filled: true, fillColor: kBg,
            contentPadding: EdgeInsets.zero,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: kBorder)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: kBorder)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: kMachine, width: 2)),
          ),
        ),
      ),
    ],
  );

  Widget _labeledSelect(String lbl, String val, Map<String, String> items, ValueChanged<String?> onChanged) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Text(lbl, style: const TextStyle(color: kText, fontSize: 13)),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(color: kBg, border: Border.all(color: kMachine), borderRadius: BorderRadius.circular(4)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: val, dropdownColor: kPanel,
              style: const TextStyle(color: kMachine, fontSize: 12, fontWeight: FontWeight.bold),
              icon: const Icon(Icons.arrow_drop_down, color: kMachine, size: 18),
              isDense: true,
              items: items.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ]);

  Widget _kpiBox(String label, String value) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
    decoration: BoxDecoration(color: kGreen.withValues(alpha: 0.1), border: Border.all(color: kGreen), borderRadius: BorderRadius.circular(6)),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Text(label, style: const TextStyle(color: kText, fontSize: 10)),
      const SizedBox(height: 2),
      Text(value, style: const TextStyle(color: kGreen, fontSize: 24, fontWeight: FontWeight.bold)),
    ]),
  );

  Widget _buildDigitalTwin() => _panel(
    title: 'Gemelo Digital 2D · Robot 3 Ejes (Vista Superior / Frontal)',
    child: Container(
      height: 280,
      child: Row(
        children: [
          Expanded(child: _buildTopView()),
          VerticalDivider(color: kBorder.withValues(alpha: 0.5), width: 1),
          Expanded(child: _buildFrontView()),
        ],
      ),
    ),
  );

  Widget _buildTopView() => Stack(
    alignment: Alignment.center,
    children: [
      const Positioned(top: 10, child: Text('Vista Superior', style: TextStyle(color: Colors.white38, fontSize: 9))),
      _buildGrid(10),
      Transform.rotate(
        angle: _baseAngle * pi / 180,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(width: 100, height: 100, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: kMachine.withValues(alpha: 0.3), width: 2))),
            Positioned(top: 50, child: Container(width: 4, height: 60, color: kMachine)),
            Positioned(top: 110, child: Container(width: 20, height: 20, decoration: BoxDecoration(color: _gripperClosed ? kRed : kGreen, shape: BoxShape.circle))),
          ],
        ),
      ),
      Positioned(bottom: 10, child: Text('Base: ${_baseAngle.toInt()}°', style: const TextStyle(color: kText, fontSize: 11))),
    ],
  );

  Widget _buildFrontView() => Stack(
    alignment: Alignment.center,
    children: [
      const Positioned(top: 10, child: Text('Vista Frontal', style: TextStyle(color: Colors.white38, fontSize: 9))),
      _buildGrid(10),
      Positioned(bottom: 20, child: Container(width: 80, height: 10, color: kBorder)),
      Positioned(bottom: 30, child: Container(width: 6, height: 180, color: kMachine.withValues(alpha: 0.5))),
      Positioned(
        bottom: 30 + (1 - _zPosition) * 150,
        child: Container(
          width: 50, height: 30,
          decoration: BoxDecoration(color: kPanel, border: Border.all(color: kMachine)),
          child: Center(child: Text('M3', style: TextStyle(color: kMachine, fontSize: 8))),
        ),
      ),
      Positioned(bottom: 10, child: Text('Eje Z: ${(_zPosition * 100).toInt()}%  Gripper: ${_gripperClosed ? 'CERRADO' : 'ABIERTO'}', style: const TextStyle(color: kText, fontSize: 11))),
    ],
  );

  Widget _buildGrid(int divisions) => LayoutBuilder(builder: (context, c) {
    return CustomPaint(size: Size(c.maxWidth, c.maxHeight), painter: _GridPainter(divisions));
  });

  Widget _buildAuditPanel() => _panel(
    title: 'Auditoría (Audit Trail) y Alertas',
    child: Container(
      height: 180, decoration: BoxDecoration(color: kBg, border: Border.all(color: kBorder), borderRadius: BorderRadius.circular(4)),
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

  Widget _buildControlRow() => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(child: _buildActuatorsPanel()),
      const SizedBox(width: 12),
      Expanded(child: _buildSensorsPanel()),
    ],
  );

  Widget _buildSensorsPanel() => SizedBox(
    height: 280,
    child: _panel(
      title: 'Sensores (6)', 
      child: Expanded(
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: _sensors.map(_sensorRow).toList()),
        ),
      )
    )
  );

  Widget _sensorRow(SensorModel s) {
    final Color color = s.active ? kGreen : const Color(0xFF333333);
    return GestureDetector(
      onTap: () => _toggleSensor(s.id),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
        decoration: BoxDecoration(
          color: s.active ? kGreen.withValues(alpha: 0.07) : Colors.black.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: s.active ? kGreen.withValues(alpha: 0.4) : kBorder),
        ),
        child: Row(children: [
          Container(
            width: 10, height: 10,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color, boxShadow: s.active ? [BoxShadow(color: color.withValues(alpha: 0.8), blurRadius: 8)] : null),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text('${s.id}: ${s.label}', style: const TextStyle(color: kText, fontSize: 13, fontWeight: FontWeight.w500))),
        ]),
      ),
    );
  }

  Widget _buildActuatorsPanel() => SizedBox(
    height: 280,
    child: _panel(
      title: 'Actuadores (RLY01–RLY08)', 
      child: Expanded(
        child: GridView.count(
          crossAxisCount: 2, 
          crossAxisSpacing: 8, 
          mainAxisSpacing: 8, 
          shrinkWrap: true, 
          physics: const BouncingScrollPhysics(), 
          childAspectRatio: 2.2, 
          children: _actuators.map(_actuatorCard).toList()
        ),
      )
    )
  );

  Widget _actuatorCard(ActuatorModel a) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8),
    decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(6), border: Border.all(color: a.on ? kMachine.withValues(alpha: 0.4) : kBorder)),
    child: Row(children: [
      Expanded(child: Text(a.id, style: TextStyle(color: a.on ? kMachine : kText, fontSize: 10, fontWeight: FontWeight.bold))),
      Transform.scale(scale: 0.7, child: Switch(value: a.on, onChanged: a.disabled ? null : (v) => _toggleActuator(a.id, v), activeTrackColor: kMachine, activeThumbColor: Colors.white, inactiveTrackColor: const Color(0xFF333333))),
    ]),
  );

  Widget _panel({required String title, required Widget child}) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: kPanel, border: Border.all(color: kBorder), borderRadius: BorderRadius.circular(8)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
      Container(padding: const EdgeInsets.only(bottom: 6), decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: kBorder))), child: Text(title, style: const TextStyle(color: kMachine, fontSize: 12, fontWeight: FontWeight.bold))),
      const SizedBox(height: 8),
      child,
    ]),
  );
}

class _GridPainter extends CustomPainter {
  final int divisions;
  _GridPainter(this.divisions);
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = kBorder.withValues(alpha: 0.1)..strokeWidth = 1;
    for (int i = 0; i <= divisions; i++) {
      double x = (size.width / divisions) * i;
      double y = (size.height / divisions) * i;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}