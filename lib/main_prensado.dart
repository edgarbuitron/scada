import 'dart:async';
import 'package:flutter/material.dart';

// --- NUEVO: Importar el servicio de Firebase ---
import 'firebase_service.dart';

// ── Paleta de Colores ──────────────────────────────────
const Color kBg = Color(0xFF0F172A);
const Color kPanel = Color(0xFF1E293B);
const Color kAccent = Color(0xFFF59E0B); // Naranja
const Color kGreen = Color(0xFF10B981);
const Color kRed = Color(0xFFF43F5E);
const Color kBorder = Color(0xFF334155);
const Color kText = Color(0xFFF8FAFC);
const Color kMuted = Color(0xFF94A3B8);

// ── Modelos ──────────────────────────────────────────
enum _PLogType { info, audit, error, success }

class _PLogEntry {
  final String time, message;
  final _PLogType type;
  const _PLogEntry(this.time, this.message, this.type);

  Color get color {
    switch (type) {
      case _PLogType.error: return kRed;
      case _PLogType.audit: return kAccent;
      case _PLogType.success: return kGreen;
      default: return kText;
    }
  }
}

class _SensorModel {
  final String id, label;
  bool active;
  _SensorModel(this.id, this.label, {this.active = false});
}

// ── Pantalla Principal ─────────────────────────────────
class ScadaPrensadoScreen extends StatefulWidget {
  const ScadaPrensadoScreen({super.key});
  @override
  State<ScadaPrensadoScreen> createState() => _ScadaPrensadoScreenState();
}

class _ScadaPrensadoScreenState extends State<ScadaPrensadoScreen> {
  // --- NUEVO: ID de maqueta y servicio de Firebase ---
  final String _maquetaId = 'prensado';
  final FirebaseService _firebaseService = FirebaseService();

  // --- Estado del SCADA ---
  String _role = 'Operador';
  String _mode = 'manual';
  bool _isCycleRunning = false;
  double _motorPos = 0.0; // 0.0 = home, 1.0 = final
  int _piezas = 0;

  final TextEditingController _piezasController = TextEditingController(text: '5');
  final ScrollController _logScroll = ScrollController();
  final List<_PLogEntry> _logs = [];

  final List<_SensorModel> _sensors = [
    _SensorModel('S1', 'Punzón en HOME'),
    _SensorModel('S2', 'Punzón en FIN DE CARRERA'),
    _SensorModel('S3', 'Pieza posicionada'),
    _SensorModel('S4', 'PARO DE EMERGENCIA'),
  ];

  _SensorModel _sensor(String id) => _sensors.firstWhere((s) => s.id == id);

  @override
  void initState() {
    super.initState();
    _firebaseService.initializeMaqueta(_maquetaId);
    _resetToHome(log: false);
    _log('Panel de Control de Prensado Inicializado', _PLogType.info);
    _updatePermissions();
  }

  @override
  void dispose() {
    _logScroll.dispose();
    _piezasController.dispose();
    super.dispose();
  }

  // --- Lógica del SCADA ---
  void _log(String msg, _PLogType type) {
    final t = DateTime.now();
    final timeStr = '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:${t.second.toString().padLeft(2, '0')}';
    if (mounted) {
      setState(() => _logs.insert(0, _PLogEntry(timeStr, msg, type)));
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_logScroll.hasClients) {
          _logScroll.jumpTo(0);
        }
      });

      // --- NUEVO: Traducción y guardado en Firebase ---
      String logTypeForHistory;
      switch (type) {
        case _PLogType.error:
          logTypeForHistory = 'Critico';
          break;
        case _PLogType.audit:
          logTypeForHistory = 'Advertencia';
          break;
        default:
          logTypeForHistory = 'Info';
      }
      _firebaseService.guardarLog(_maquetaId, {
        'role': _role,
        'message': msg,
        'type': logTypeForHistory,
      });
    }
  }

  void _updatePermissions() {
    _log('Configuración cambiada a Modo: $_mode. Rol: $_role', _PLogType.audit);
  }

  void _toggleSensor(String id) {
    if (id == 'S4' || (_mode != 'manual' && _role != 'Admin')) {
      _log('Simulación de sensor $id no permitida en modo automático.', _PLogType.error);
      return;
    }
    final s = _sensor(id);
    if (mounted) setState(() => s.active = !s.active);
    _log('Simulación Manual: Sensor ${s.id} forzado a ${s.active ? 'ACTIVO' : 'INACTIVO'}', _PLogType.audit);
    _firebaseService.registrarAccionComponente(_maquetaId, 'sensor_${s.id}_${s.active ? 'on' : 'off'}');
  }

  void _triggerEmergency() {
    final s4 = _sensor('S4');
    if (mounted) {
      setState(() {
        s4.active = true;
        _isCycleRunning = false;
      });
    }
    _log('¡PARO DE EMERGENCIA (S4) ACTIVADO! Energía cortada.', _PLogType.error);
    _firebaseService.registrarParoEmergencia(_maquetaId);
    _firebaseService.registrarAccionComponente(_maquetaId, 'paro_emergencia');
  }

  void _resetToHome({bool log = true}) {
    if (log) {
      _log('Restableciendo sistema a estado inicial...', _PLogType.audit);
    }
    if (mounted) {
      setState(() {
        for (final s in _sensors) {
          s.active = false;
        }
        _sensor('S1').active = true;
        _isCycleRunning = false;
        _motorPos = 0.0;
      });
    }
    if (log) {
      _log('Sistema restablecido a la posición HOME.', _PLogType.success);
      _firebaseService.registrarReset(_maquetaId);
    }
  }

  Future<void> _moveMotor(double targetPos, int durationMs, String logMsg) async {
    if (!_isCycleRunning || _sensor('S4').active) return;
    _log(logMsg, _PLogType.info);
    final startPos = _motorPos;
    final steps = 30;
    for (int i = 1; i <= steps; i++) {
      if (!_isCycleRunning || _sensor('S4').active) break;
      await Future.delayed(Duration(milliseconds: durationMs ~/ steps));
      if(mounted) setState(() => _motorPos = startPos + (targetPos - startPos) * (i / steps));
    }
    if(mounted) setState(() => _motorPos = targetPos);
  }

  Future<void> _startAutoCycle() async {
    if (_isCycleRunning) return;
    final int numPiezas = int.tryParse(_piezasController.text) ?? 0;
    if (numPiezas <= 0) { _log('ERROR: El número de piezas debe ser mayor a 0.', _PLogType.error); return; }
    if (!_sensor('S1').active) { _log('FALLA ARRANQUE: Punzón no está en posición HOME (S1 inactivo).', _PLogType.error); return; }
    if (mounted) setState(() { _isCycleRunning = true; _updatePermissions(); });
    _log('══ INICIANDO CICLO AUTOMÁTICO PARA $numPiezas PIEZAS ══', _PLogType.info);
    for (int i = 0; i < numPiezas; i++) {
      if (!_isCycleRunning) break;
      _log('--- Procesando pieza ${i + 1} de $numPiezas ---', _PLogType.info);
      await _runSingleCycle();
      if (!_isCycleRunning) { _log('Ciclo interrumpido por PARO DE EMERGENCIA.', _PLogType.error); break; }
    }
    if (mounted) {
      setState(() {
        _isCycleRunning = false;
        _updatePermissions();
      });
    }
     _log('══ CICLO AUTOMÁTICO FINALIZADO ══', _PLogType.info);
  }

  Future<void> _runSingleCycle() async {
    // 1. Esperando pieza
    await Future.delayed(const Duration(seconds: 1)); // Simula llegada de pieza
    if (!_isCycleRunning) return;
    
    if (mounted) setState(() => _sensor('S3').active = true);
    _log('Pieza detectada (S3). Bajando punzón...', _PLogType.info);

    // 2. Prensando
    await _moveMotor(1.0, 2000, 'Motor M1 descendiendo...');
    if (!_isCycleRunning) return;

    if (mounted) setState(() => _sensor('S2').active = true); // Fin de carrera
    _log('Prensado completado (S2). Manteniendo presión...', _PLogType.success);
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) setState(() => _sensor('S2').active = false);
    
    // 3. Subiendo
    await _moveMotor(0.0, 1500, 'Motor M1 ascendiendo...');
    if (!_isCycleRunning) return;

    if (mounted) {
      setState(() {
        _sensor('S1').active = true; // HOME
        _sensor('S3').active = false; // Pieza sale
        _piezas++;
      });
    }
    _log('✔ CICLO EXITOSO · Pieza #$_piezas prensada.', _PLogType.success);
    _firebaseService.incrementarPiezas(_maquetaId);
  }
  
  // --- Widgets de la UI ---
  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 750;
    return Scaffold(
      backgroundColor: kBg,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: isMobile ? _buildMobileLayout() : _buildDesktopLayout(),
      ),
    );
  }

  Widget _buildDesktopLayout() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _buildHeader(),
      const SizedBox(height: 16),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 3, child: _buildMainContent()),
          const SizedBox(width: 16),
          Expanded(flex: 2, child: _buildLogPanel()),
        ],
      )
    ],
  );

  Widget _buildMobileLayout() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _buildHeader(),
      const SizedBox(height: 16),
      _buildMainContent(),
      const SizedBox(height: 16),
      _buildLogPanel(),
    ],
  );

  Widget _buildHeader() => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      const Text('SCADA: Centro de Prensado', style: TextStyle(color: kText, fontSize: 22, fontWeight: FontWeight.bold)),
      Wrap(alignment: WrapAlignment.end, spacing: 12, runSpacing: 8, children: [
        _buildDropdown('Rol', _role, ['Operador', 'Ingeniero', 'Admin'], (v) => setState(() { _role = v!; _updatePermissions(); })),
        _buildDropdown('Modo', _mode, ['manual', 'auto'], (v) => setState(() { _mode = v!; _updatePermissions(); })),
      ]),
    ],
  );
  
  Widget _buildMainContent() => Column(
    children: [
      _buildControlPanel(),
      const SizedBox(height: 16),
      _buildMachineStatus(),
    ],
  );

  Widget _buildControlPanel() => _panel(
    child: Wrap(alignment: WrapAlignment.spaceAround, runAlignment: WrapAlignment.center, spacing: 16, runSpacing: 12, children: [
      Row(mainAxisSize: MainAxisSize.min, children: [
        const Text("Piezas a procesar:", style: TextStyle(color: kText)),
        const SizedBox(width: 8),
        SizedBox(width: 60, child: TextField(controller: _piezasController, enabled: !_isCycleRunning, keyboardType: TextInputType.number, textAlign: TextAlign.center, style: const TextStyle(color: kText), decoration: const InputDecoration(isDense: true, filled: true, fillColor: kBg, border: OutlineInputBorder()))),
      ]),
      ElevatedButton.icon(onPressed: _isCycleRunning ? null : _startAutoCycle, icon: const Icon(Icons.play_arrow), label: const Text('INICIAR CICLO'), style: ElevatedButton.styleFrom(backgroundColor: kGreen, foregroundColor: Colors.black, disabledBackgroundColor: kBorder)),
      ElevatedButton.icon(onPressed: _triggerEmergency, icon: const Icon(Icons.warning), label: const Text('PARO EMERGENCIA'), style: ElevatedButton.styleFrom(backgroundColor: kRed, foregroundColor: kText)),
      ElevatedButton.icon(onPressed: _isCycleRunning ? null : _resetToHome, icon: const Icon(Icons.refresh), label: const Text('RESETEAR'), style: ElevatedButton.styleFrom(backgroundColor: kAccent, foregroundColor: Colors.black, disabledBackgroundColor: kBorder)),
    ]),
  );

  Widget _buildMachineStatus() => _panel(
    child: Row(children: [
      Expanded(flex: 2, child: _buildSensorsPanel()),
      const VerticalDivider(color: kBorder, width: 32),
      Expanded(flex: 3, child: _buildMotorPanel()),
    ]),
  );

  Widget _buildSensorsPanel() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('Sensores', style: TextStyle(color: kAccent, fontWeight: FontWeight.bold, fontSize: 16)),
      const Divider(color: kBorder),
      ..._sensors.map((s) => 
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: GestureDetector(
            onTap: () => _toggleSensor(s.id),
            child: Row(children: [
              Icon(s.active ? Icons.check_box : Icons.check_box_outline_blank, color: s.active ? (s.id == 'S4' ? kRed : kGreen) : kMuted, size: 20),
              const SizedBox(width: 8),
              Text('${s.id}: ${s.label}', style: TextStyle(color: s.active ? kText : kMuted, fontSize: 13)),
            ]),
          ),
        )
      ),
    ],
  );

  Widget _buildMotorPanel() => Column(
    children: [
      const Text('Estado del Punzón (Motor M1)', style: TextStyle(color: kAccent, fontWeight: FontWeight.bold, fontSize: 16)),
      const SizedBox(height: 20),
      SizedBox(
        height: 100,
        child: Stack(children: [
          Positioned.fill(child: RotatedBox(quarterTurns: 1, child: LinearProgressIndicator(value: _motorPos, backgroundColor: kBorder, valueColor: const AlwaysStoppedAnimation(kAccent)))),
          Align(alignment: Alignment.topCenter, child: Text('HOME (S1)', style: TextStyle(color: _motorPos == 0.0 ? kGreen : kMuted, fontSize: 12))),
          Align(alignment: Alignment.bottomCenter, child: Text('FIN (S2)', style: TextStyle(color: _motorPos == 1.0 ? kGreen : kMuted, fontSize: 12))),
        ]),
      ),
      const SizedBox(height: 12),
      Text('Posición: ${(_motorPos * 100).toStringAsFixed(0)}%', style: const TextStyle(color: kText, fontSize: 14, fontWeight: FontWeight.bold)),
    ],
  );

  Widget _buildLogPanel() => _panel(
    height: 300,
    child: Column(children: [
      const Text('Consola de Eventos', style: TextStyle(color: kAccent, fontWeight: FontWeight.bold, fontSize: 16)),
      const Divider(color: kBorder),
      Expanded(
        child: ListView.builder(
          controller: _logScroll,
          itemCount: _logs.length,
          itemBuilder: (context, index) {
            final log = _logs[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: RichText(text: TextSpan(
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                children: [
                  TextSpan(text: '[${log.time}] ', style: const TextStyle(color: kMuted)),
                  TextSpan(text: log.message, style: TextStyle(color: log.color)),
                ]
              )),
            );
          },
        ),
      ),
    ]),
  );

  Widget _buildDropdown(String label, String value, List<String> items, ValueChanged<String?> onChanged) => Row(mainAxisSize: MainAxisSize.min, children: [
    Text('$label:', style: const TextStyle(color: kMuted, fontSize: 12)),
    const SizedBox(width: 8),
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(color: kPanel, borderRadius: BorderRadius.circular(4), border: Border.all(color: kBorder)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(value: value, items: items.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(), onChanged: (_isCycleRunning) ? null : onChanged, style: const TextStyle(color: kAccent, fontSize: 13), dropdownColor: kPanel, icon: const Icon(Icons.arrow_drop_down, color: kAccent)),
      ),
    ),
  ]);

  Widget _panel({required Widget child, double? height}) => Container(
    height: height,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: kPanel, borderRadius: BorderRadius.circular(8), border: Border.all(color: kBorder)),
    child: child,
  );
}
