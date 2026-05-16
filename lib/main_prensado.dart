
// ============================================================
// CENTRO DE PRENSADO SCADA 4.0 -- Flutter
// Art. No. TMPUM24-A -- Punching Machine 24V
// Sensores: P1, P2, S1, S2
// Actuadores: RLY01 (M1-Home), RLY02 (M1-Work),
//             RLY03 (M2-Fwd),  RLY04 (M2-Bwd)
// ============================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ── Paleta ────────────────────────────────────────────────────────────────
const Color _kBg = Color(0xFF081014);
const Color _kPanel = Color(0xFF11222C);
const Color _kCyan = Color(0xFF00EAFF);
const Color _kGreen = Color(0xFF00FF88);
const Color _kRed = Color(0xFFFF3366);
const Color _kBorder = Color(0xFF1A3644);
const Color _kText = Color(0xFFC5D1D8);
const Color _kAudit = Color(0xFFFFAA00);
const Color _kDark = Color(0xFF0C1820);
const Color _kOrange = Color(0xFFFFAA00); // color característico de prensado

// ── Estados del ciclo (fiel al proceso real TMPUM24-A) ────────────────────
const List<String> _kEstados = [
  'Sin iniciar',
  'EST1 · Pieza en P1 (entrada) · Banda avanzando',
  'EST2 · Pieza en P2 (prensa) · Bajando punzón',
  'EST3 · Punzón en trabajo (S2) · Subiendo a home',
  'EST4 · Punzón en home (S1) · Expulsando pieza',
];

// ── Modelos internos (privados al archivo) ────────────────────────────────
enum _PLogType { info, audit, error, success }

class _PLogEntry {
  final String time, user, message;
  final _PLogType type;
  const _PLogEntry(this.time, this.user, this.message, this.type);
  Color get color => type == _PLogType.error
      ? _kRed
      : type == _PLogType.audit
          ? _kAudit
          : type == _PLogType.success
              ? _kGreen
              : _kText;
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

  String _role = 'Ingeniero';
  String _mode = 'manual';
  String _conn = 'sim';

  bool _isCycleRunning = false;
  int _currentState = 0;
  int _piezas = 0;

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

  bool get _btnAutoEnabled => _mode == 'auto' && !_isCycleRunning;

  @override
  void initState() {
    super.initState();
    _updateClock();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(_updateClock);
    });
    _log('Sistema iniciado · Centro de Prensado TMPUM24-A', _PLogType.info);
    _log('Modo: $_mode · Rol: $_role', _PLogType.audit);
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
    _clock =
        '${n.hour.toString().padLeft(2, '0')}:${n.minute.toString().padLeft(2, '0')}:${n.second.toString().padLeft(2, '0')}';
  }

  void _log(String msg, _PLogType type) {
    final n = DateTime.now();
    final t =
        '${n.hour.toString().padLeft(2, '0')}:${n.minute.toString().padLeft(2, '0')}:${n.second.toString().padLeft(2, '0')}';
    if (mounted) {
      setState(() => _logs.add(_PLogEntry(t, _role, msg, type)));
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
    _log('Configuración cambiada a Modo: $_mode', _PLogType.audit);
  }

  void _toggleSensor(String id) {
    if (_mode != 'manual') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Cambia el Modo a 'Manual' para simular sensores."),
        backgroundColor: _kAudit,
      ));
      return;
    }
    final s = _sensor(id);
    if (mounted) setState(() => s.active = !s.active);
    _log('Simulación Manual: Sensor $id → ${s.active ? 'ACTIVO' : 'LIBRE'}',
        _PLogType.audit);
  }

  void _toggleActuator(String id, bool val) {
    if (mounted) {
      setState(() {
        _act(id).on = val;
        if (!_isCycleRunning) {
          if (val && id == 'RLY01') _act('RLY02').on = false;
          if (val && id == 'RLY02') _act('RLY01').on = false;
          if (val && id == 'RLY03') _act('RLY04').on = false;
          if (val && id == 'RLY04') _act('RLY03').on = false;
          _log('Forzó $id a ${val ? 'ENCENDIDO' : 'APAGADO'}', _PLogType.audit);
        }
      });
    }
  }

  Future<void> _startAutoCycle() async {
    if (_isCycleRunning) return;

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
    if (mounted) {
      setState(() {
        _isCycleRunning = true;
        _updatePermissions();
      });
    }

    _log('══ INICIANDO CICLO AUTOMÁTICO PARA $numPiezas PIEZAS ══', _PLogType.info);

    for (int i = 0; i < numPiezas; i++) {
      if (!_isCycleRunning) break;
      _log('--- Procesando pieza ${i + 1} de $numPiezas ---', _PLogType.info);
      await _runSingleCycle();
      if (!_isCycleRunning) {
        _log('Ciclo interrumpido por PARO DE EMERGENCIA.', _PLogType.error);
        break;
      }
    }
    
    if (mounted) {
      setState(() {
        _isCycleRunning = false;
        _currentState = 0;
        _updatePermissions();
      });
    }
    _log('══ CICLO AUTOMÁTICO FINALIZADO ══', _PLogType.info);
  }

  Future<void> _runSingleCycle() async {
    try {
      if (!_isCycleRunning || !mounted) return;
      setState(() {
        _currentState = 1;
        _sensor('P1').active = true;
      });
      _log('EST1 · P1: Pieza detectada.', _PLogType.info);
      setState(() => _act('RLY03').on = true);
      _log('EST1 · RLY03 ON → Banda avanza.', _PLogType.audit);
      await Future.delayed(const Duration(milliseconds: 1800));

      if (!_isCycleRunning || !mounted) return;
      setState(() {
        _currentState = 2;
        _act('RLY03').on = false;
        _sensor('P1').active = false;
        _sensor('P2').active = true;
      });
      _log('EST2 · P2: Pieza en prensa.', _PLogType.info);
      await Future.delayed(const Duration(milliseconds: 400));

      if (!_isCycleRunning || !mounted) return;
      setState(() => _act('RLY02').on = true);
      _log('EST2 · RLY02 ON → Punzón bajando.', _PLogType.audit);
      await Future.delayed(const Duration(milliseconds: 200));
      setState(() => _sensor('S1').active = false);
      await Future.delayed(const Duration(milliseconds: 1400));

      if (!_isCycleRunning || !mounted) return;
      setState(() {
        _currentState = 3;
        _sensor('S2').active = true;
        _act('RLY02').on = false;
      });
      _log('EST3 · S2: Punzón en trabajo.', _PLogType.info);
      await Future.delayed(const Duration(milliseconds: 600));
      setState(() => _act('RLY01').on = true);
      _log('EST3 · RLY01 ON → Punzón subiendo.', _PLogType.audit);
      await Future.delayed(const Duration(milliseconds: 200));
      setState(() => _sensor('S2').active = false);
      await Future.delayed(const Duration(milliseconds: 1400));

      if (!_isCycleRunning || !mounted) return;
      setState(() {
        _currentState = 4;
        _sensor('S1').active = true;
        _act('RLY01').on = false;
      });
      _log('EST4 · S1: Punzón en HOME.', _PLogType.info);
      await Future.delayed(const Duration(milliseconds: 400));
      setState(() => _act('RLY03').on = true);
      _log('EST4 · RLY03 ON → Expulsando pieza.', _PLogType.audit);
      await Future.delayed(const Duration(milliseconds: 1800));

      if (!_isCycleRunning || !mounted) return;
      setState(() {
        _act('RLY03').on = false;
        _sensor('P2').active = false;
        _piezas++;
      });
      _log('══ CICLO EXITOSO · Pieza #$_piezas completada ══', _PLogType.success);
    } catch (e) {
      _log('ERROR en secuencia: $e', _PLogType.error);
    }
  }

  void _triggerEmergency() {
    if (mounted) {
      setState(() {
        _isCycleRunning = false;
        _currentState = 0;
        for (final a in _actuators) {
          a.on = false;
        }
      });
    }
    _log('¡PARO DE EMERGENCIA ACTIVADO! Todos los actuadores apagados.', _PLogType.error);
    if (mounted) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: _kPanel,
          title: const Text('⚠ PARO DE EMERGENCIA',
              style: TextStyle(color: _kRed, fontSize: 15)),
          content: const Text(
              'Todos los relés han sido desactivados.\nRevise la máquina antes de reiniciar.',
              style: TextStyle(color: _kText)),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK', style: TextStyle(color: _kCyan)))
          ],
        ),
      );
    }
  }
  void _resetToHome() {
    _log('Restableciendo sistema a estado inicial...', _PLogType.audit);
    if (mounted) {
      setState(() {
        _isCycleRunning = false;
        _currentState = 0;
        // Apagar todos los actuadores
        for (final a in _actuators) {
          a.on = false;
        }
        // Restablecer sensores a su estado inicial
        _sensor('P1').active = false;
        _sensor('P2').active = false;
        _sensor('S1').active = true; // Punzón en home
        _sensor('S2').active = false;
      });
    }
    _log('Sistema restablecido a la posición HOME.', _PLogType.success);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
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
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() => Container(
        padding: const EdgeInsets.only(bottom: 10),
        decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: _kOrange, width: 2))),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('CENTRO DE PRENSADO',
                    style: TextStyle(
                        color: _kOrange,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.4)),
              ],
            ),
            Text(_clock,
                style: const TextStyle(
                    color: _kText, fontSize: 14, fontFamily: 'monospace')),
          ],
        ),
      );

  Widget _buildTopBar() => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _kPanel,
          border: Border.all(color: _kBorder),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Wrap(
          spacing: 16,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _labeledSelect('Modo:', _mode, {
              'manual': 'Manual (Simulación Física)',
              'auto': 'Automático',
            }, (v) {
              if (mounted) setState(() => _mode = v!);
              _updatePermissions();
            }),
            _buildPiezasInput(),
            ElevatedButton.icon(
              onPressed: _btnAutoEnabled ? _startAutoCycle : null,
              icon: Icon(
                  _isCycleRunning ? Icons.stop_circle : Icons.play_circle,
                  size: 18),
              label: Text(
                _isCycleRunning ? 'EJECUTANDO...' : '▶ INICIAR CICLO AUTO',
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kOrange,
                foregroundColor: Colors.black,
                disabledBackgroundColor: const Color(0xFF333333),
                disabledForegroundColor: const Color(0xFF666666),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
            ),
            ElevatedButton.icon(
              onPressed: _triggerEmergency,
              icon: const Icon(Icons.warning_amber_rounded, size: 18),
              label: const Text('PARO EMERGENCIA',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kRed,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
            ),
            ElevatedButton.icon(
              onPressed: _isCycleRunning ? null : _resetToHome, 
              icon: const Icon(Icons.replay_circle_filled_rounded, size: 18),
              label: const Text('RESTABLECER',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kCyan,
                foregroundColor: Colors.black,
                disabledBackgroundColor: const Color(0xFF333333),
                disabledForegroundColor: const Color(0xFF666666),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
            ),
            _kpiBox('Piezas Prensadas', '$_piezas'),
          ],
        ),
      );

  Widget _buildPiezasInput() => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      const Text("Piezas:", style: TextStyle(color: _kText, fontSize: 13)),
      const SizedBox(width: 8),
      SizedBox(
        width: 60,
        height: 38,
        child: TextField(
          controller: _piezasController,
          enabled: _mode == 'auto',
          keyboardType: TextInputType.number,
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.digitsOnly
          ],
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _mode == 'auto' ? _kOrange : Colors.grey,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: _kBg,
            contentPadding: const EdgeInsets.symmetric(vertical: 8.0),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(color: _mode == 'auto' ? _kOrange : _kBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(color: _mode == 'auto' ? _kOrange : _kBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: _kOrange, width: 2),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(color: _kBorder),
            ),
          ),
        ),
      ),
    ],
  );

  Widget _labeledSelect(String lbl, String val, Map<String, String> items,
          ValueChanged<String?> onChanged) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Text(lbl, style: const TextStyle(color: _kText, fontSize: 13)),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: _kBg,
            border: Border.all(color: _kOrange),
            borderRadius: BorderRadius.circular(4),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: val,
              dropdownColor: _kPanel,
              style: const TextStyle(color: _kOrange, fontSize: 12),
              icon:
                  const Icon(Icons.arrow_drop_down, color: _kOrange, size: 18),
              isDense: true,
              items: items.entries
                  .map((e) =>
                      DropdownMenuItem(value: e.key, child: Text(e.value)))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ]);

  Widget _kpiBox(String label, String value) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: _kOrange.withOpacity(0.1),
          border: Border.all(color: _kOrange),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(label, style: const TextStyle(color: _kText, fontSize: 11)),
          const SizedBox(height: 2),
          Text(value,
              style: const TextStyle(
                  color: _kOrange, fontSize: 24, fontWeight: FontWeight.bold)),
        ]),
      );

  Widget _buildRow1() => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 2, child: _buildDigitalTwin()),
          const SizedBox(width: 12),
          Expanded(child: _buildSensorsPanel()),
        ],
      );

  Widget _buildDigitalTwin() => Container(
        height: 320,
        decoration: BoxDecoration(
          color: _kDark,
          border: Border.all(color: _kOrange),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(children: [
          const Positioned(
            top: 10,
            right: 10,
            child: Text('Gemelo Digital 2D — TMPUM24-A',
                style: TextStyle(
                    color: _kOrange,
                    fontWeight: FontWeight.bold,
                    fontSize: 12)),
          ),

          Positioned(
            bottom: 40,
            left: 30,
            child: _dtRect(
              'M2\nBanda\nTransportadora',
              _act('RLY03').on || _act('RLY04').on,
              _act('RLY04').on ? _kAudit : _kCyan,
              w: 280,
              h: 40,
            ),
          ),

          if (_act('RLY03').on || _act('RLY04').on)
            Positioned(
              bottom: 48,
              left: 140,
              child: Text(
                _act('RLY03').on ? '→ Forward' : '← Backward',
                style: TextStyle(
                  color: _act('RLY03').on ? _kCyan : _kAudit,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

          Positioned(
            bottom: 82,
            left: 38,
            child: _sensorDot('P1', _sensor('P1').active),
          ),

          Positioned(
            bottom: 82,
            left: 158,
            child: _sensorDot('P2', _sensor('P2').active),
          ),

          Positioned(
            bottom: 78,
            left: 150,
            child: Container(
              width: 40,
              height: 180,
              decoration: BoxDecoration(
                color: const Color(0xFF1A2A1A),
                border: Border.all(color: const Color(0xFF334433)),
                borderRadius: BorderRadius.circular(3),
              ),
              child: const Center(
                child: Text('GUÍA\nPUNZÓN',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF446644), fontSize: 8)),
              ),
            ),
          ),

          AnimatedPositioned(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
            bottom: _act('RLY02').on
                ? 82
                : _act('RLY01').on || _sensor('S1').active
                    ? 200
                    : 145,
            left: 135,
            child: _dtRect(
              'M1\nPunzón',
              _act('RLY01').on || _act('RLY02').on,
              _act('RLY02').on ? _kOrange : _kGreen,
              w: 70,
              h: 55,
            ),
          ),

          Positioned(
            top: 60,
            left: 220,
            child: Column(children: [
              _sensorDot('S1', _sensor('S1').active),
              const SizedBox(height: 2),
              const Text('HOME', style: TextStyle(color: _kGreen, fontSize: 8)),
            ]),
          ),

          Positioned(
            bottom: 92,
            left: 220,
            child: Column(children: [
              _sensorDot('S2', _sensor('S2').active),
              const SizedBox(height: 2),
              const Text('WORK',
                  style: TextStyle(color: _kOrange, fontSize: 8)),
            ]),
          ),

          Positioned(
            top: 14,
            left: 14,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _relayIndicator('RLY01', '↑ Home', _act('RLY01').on),
                _relayIndicator('RLY02', '↓ Work', _act('RLY02').on),
                _relayIndicator('RLY03', '→ Fwd', _act('RLY03').on),
                _relayIndicator('RLY04', '← Bwd', _act('RLY04').on),
              ],
            ),
          ),
        ]),
      );

  Widget _dtRect(String label, bool active, Color color,
      {required double w, required double h}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: w,
      height: h,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: active ? color.withOpacity(0.22) : const Color(0xFF1A2233),
        border: Border.all(
            color: active ? color : const Color(0xFF334455), width: 1.5),
        borderRadius: BorderRadius.circular(4),
        boxShadow: active
            ? [BoxShadow(color: color.withOpacity(0.45), blurRadius: 12)]
            : null,
      ),
      child: Text(label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: active ? color : _kText.withOpacity(0.4),
            fontSize: 10,
            fontWeight: FontWeight.bold,
          )),
    );
  }

  Widget _sensorDot(String id, bool active) => AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active ? _kGreen.withOpacity(0.2) : Colors.transparent,
          border: Border.all(
              color: active ? _kGreen : const Color(0xFF334455), width: 2),
          boxShadow: active
              ? [BoxShadow(color: _kGreen.withOpacity(0.6), blurRadius: 10)]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(id,
            style: TextStyle(
              color: active ? _kGreen : const Color(0xFF546E7A),
              fontSize: 8,
              fontWeight: FontWeight.bold,
            )),
      );

  Widget _relayIndicator(String id, String desc, bool active) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active ? _kOrange : const Color(0xFF334455),
              boxShadow: active
                  ? [BoxShadow(color: _kOrange.withOpacity(0.7), blurRadius: 6)]
                  : null,
            ),
          ),
          const SizedBox(width: 5),
          Text('$id $desc',
              style: TextStyle(
                color: active ? _kOrange : const Color(0xFF546E7A),
                fontSize: 9,
                fontWeight: active ? FontWeight.bold : FontWeight.normal,
              )),
        ]),
      );

  Widget _buildSensorsPanel() => _panel(
        title: 'Sensores / Entradas (Engine Inputs)',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: _sensors.map(_sensorRow).toList(),
        ),
      );

  Widget _sensorRow(_PSensorModel s) => GestureDetector(
        onTap: () => _toggleSensor(s.id),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: s.active
                ? _kGreen.withOpacity(0.07)
                : Colors.black.withOpacity(0.3),
            border: Border.all(
                color: s.active ? _kGreen.withOpacity(0.4) : _kBorder),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.label,
                      style: TextStyle(
                          color: s.active ? _kGreen : _kText,
                          fontSize: 13,
                          fontWeight: FontWeight.bold)),
                  Text(s.description,
                      style: const TextStyle(
                          color: Color(0xFF546E7A), fontSize: 10)),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: s.active ? _kGreen : const Color(0xFF334455),
                boxShadow: s.active
                    ? [
                        BoxShadow(
                            color: _kGreen.withOpacity(0.7), blurRadius: 8)
                      ]
                    : null,
              ),
            ),
          ]),
        ),
      );

  Widget _buildRow2() => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _buildActuatorsPanel()),
          const SizedBox(width: 12),
          Expanded(flex: 2, child: _buildAuditPanel()),
        ],
      );

  Widget _buildActuatorsPanel() => _panel(
        title: 'Actuadores / Relés (Engine Outputs)',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _groupLabel('Motor M1 — Punzón (H-Bridge)'),
            _actuatorRow(_act('RLY01')),
            _actuatorRow(_act('RLY02')),
            const SizedBox(height: 8),
            _groupLabel('Motor M2 — Banda Transportadora (H-Bridge)'),
            _actuatorRow(_act('RLY03')),
            _actuatorRow(_act('RLY04')),
          ],
        ),
      );
      
  Widget _buildAuditPanel() => _panel(
        title: 'Auditoría (Audit Trail) y Alertas',
        child: Container(
          height: 180,
          decoration: BoxDecoration(
              color: _kBg,
              border: Border.all(color: _kBorder),
              borderRadius: BorderRadius.circular(4)),
          padding: const EdgeInsets.all(10),
          child: ListView.builder(
            controller: _logScroll,
            itemCount: _logs.length,
            itemBuilder: (_, i) {
              final l = _logs[i];
              return Text(
                '[${l.time}] [${l.user}] - ${l.message}',
                style: TextStyle(
                    color: l.color,
                    fontSize: 11,
                    fontFamily: 'monospace',
                    fontWeight: l.type == _PLogType.audit
                        ? FontWeight.bold
                        : FontWeight.normal),
              );
            },
          ),
        ),
      );

  Widget _groupLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 4, top: 2),
        child: Text(text,
            style: const TextStyle(
                color: _kAudit, fontSize: 10, fontWeight: FontWeight.bold)),
      );

  Widget _actuatorRow(_PActuatorModel a) => Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color:
              a.on ? _kOrange.withOpacity(0.08) : Colors.black.withOpacity(0.3),
          border:
              Border.all(color: a.on ? _kOrange.withOpacity(0.5) : _kBorder),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(a.id,
                    style: TextStyle(
                        color: a.on ? _kOrange : _kText,
                        fontSize: 13,
                        fontWeight: FontWeight.bold)),
                Text(a.description,
                    style: const TextStyle(
                        color: Color(0xFF546E7A), fontSize: 10)),
              ],
            ),
          ),
          Transform.scale(
            scale: 0.8,
            child: Switch(
              value: a.on,
              onChanged: a.disabled ? null : (v) => _toggleActuator(a.id, v),
              activeColor: Colors.white,
              activeTrackColor: _kOrange,
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: const Color(0xFF333333),
            ),
          ),
        ]),
      );

  Widget _panel({
    required String title,
    required Widget child,
    double? height,
    Color titleColor = _kOrange,
  }) =>
      Container(
        height: height,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _kPanel,
          border: Border.all(color: _kBorder),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: height != null ? MainAxisSize.max : MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.only(bottom: 8),
              decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: _kBorder))),
              child: Text(title,
                  style: TextStyle(
                      color: titleColor,
                      fontSize: 13,
                      fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 8),
            height != null ? Expanded(child: child) : child,
          ],
        ),
      );
}
