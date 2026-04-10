// ============================================================
//  CENTRO DE PRENSADO SCADA 4.0  –  Flutter
//  Art. No. TMPUM24-A  –  Punching Machine 24V
//  4 Estados · 4 Sensores · 4 Actuadores (RLY01-RLY04)
// ============================================================
import 'dart:async';
//import 'dart:math';
import 'package:flutter/material.dart';

void main() => runApp(const ScadaPrensadoScreen());

// ── Paleta ────────────────────────────────────────────────
const Color kBg     = Color(0xFF081014);
const Color kPanel  = Color(0xFF11222C);
const Color kCyan   = Color(0xFF00EAFF);
const Color kGreen  = Color(0xFF00FF88);
const Color kRed    = Color(0xFFFF3366);
const Color kBorder = Color(0xFF1A3644);
const Color kText   = Color(0xFFC5D1D8);
const Color kAudit  = Color(0xFFFFAA00);
const Color kDark   = Color(0xFF0C1820);
const Color kMachine = Color(0xFFFFAA00); // naranja para prensado

// ── App ───────────────────────────────────────────────────
class ScadaPrensadoScreen extends StatelessWidget {
  const ScadaPrensadoScreen({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Centro de Prensado SCADA 4.0',
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
  SensorModel(this.id, this.label, this.description, {this.active = false});
}

class ActuatorModel {
  final String id, label, description;
  bool on;
  bool disabled;
  ActuatorModel(this.id, this.label, this.description,
      {this.on = false, this.disabled = false});
}

// ── Estados del ciclo (del código MicroPython) ────────────
// EST1: P1+S1 detectados (valor 5) → Enciende banda hacia adelante
// EST2: P2+S1 detectados (valor 6) → Apaga banda → Baja prensa (RLY02)
// EST3: P2+S2 detectados (valor 10) → Sube prensa (RLY01)
// EST4: P2+S1 detectados (valor 6) → Apaga subida → Banda expulsa
const List<String> kEstados = [
  'Sin iniciar',
  'EST1 · Pieza en P1 + Prensa arriba (S1)',
  'EST2 · Pieza llegó a prensa (P2+S1) · Bajando',
  'EST3 · Prensa en tope inferior (S2) · Subiendo',
  'EST4 · Prensa arriba (S1) · Expulsando pieza',
];

// ── Dashboard ─────────────────────────────────────────────
class ScadaDashboard extends StatefulWidget {
  const ScadaDashboard({super.key});
  @override
  State<ScadaDashboard> createState() => _ScadaDashboardState();
}

class _ScadaDashboardState extends State<ScadaDashboard> {
  String _clock = '';
  late Timer _clockTimer;
  Timer? _cycleTimer;

  // Selects
  String _role = 'Ingeniero';
  String _mode = 'manual';

  // Estado SCADA
  bool _isCycleRunning = false;
  int _currentState = 0; // 0 = sin iniciar
  int _piezas = 0;

  // Sensores (del PDF TMPUM24-A Engine Inputs)
  final List<SensorModel> _sensors = [
    SensorModel('P1', 'P1', 'Pieza en área de entrada'),
    SensorModel('P2', 'P2', 'Pieza presente en prensa'),
    SensorModel('S1', 'S1', 'Prensa en posición inicial (arriba)'),
    SensorModel('S2', 'S2', 'Prensa en posición de trabajo (abajo)'),
  ];

  // Actuadores (del PDF TMPUM24-A Engine Outputs)
  final List<ActuatorModel> _actuators = [
    ActuatorModel('RLY01', 'RLY01', 'Motor prensa → Posición arriba'),
    ActuatorModel('RLY02', 'RLY02', 'Motor prensa → Posición abajo'),
    ActuatorModel('RLY03', 'RLY03', 'Banda transportadora → Forward'),
    ActuatorModel('RLY04', 'RLY04', 'Banda transportadora → Backward'),
  ];

  final List<LogEntry> _logs = [];
  final ScrollController _logScroll = ScrollController();

  // Helpers
  SensorModel _sensor(String id) => _sensors.firstWhere((s) => s.id == id);
  ActuatorModel _act(String id) => _actuators.firstWhere((a) => a.id == id);
  bool get _btnAutoEnabled => _mode == 'auto' && !_isCycleRunning;
  //String get _roleLabel => _role == 'Ingeniero' ? 'Ingeniero (Control Total)' : 'Operador';

  @override
  void initState() {
    super.initState();
    _updateClock();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(_updateClock);
    });
    _logAudit('Sistema iniciado · Centro de Prensado TMPUM24-A', LogType.info);
    _logAudit('Configuración cambiada a Modo: $_mode', LogType.audit);
  }

  void _updateClock() {
    final n = DateTime.now();
    _clock =
        '${n.hour.toString().padLeft(2, '0')}:${n.minute.toString().padLeft(2, '0')}:${n.second.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    _cycleTimer?.cancel();
    _logScroll.dispose();
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
    if (!_isCycleRunning) {
      _logAudit('Forzó $id a ${val ? 'ENCENDIDO' : 'APAGADO'}', LogType.audit);
    }
  }

  // ── Ciclo automático (replica lógica del MicroPython) ─────────────────
  Future<void> _startAutoCycle() async {
    if (_isCycleRunning) return;
    setState(() {
      _isCycleRunning = true;
      _currentState = 0;
      _updatePermissions();
    });
    _logAudit('INICIANDO CICLO AUTOMÁTICO DE PRENSADO...', LogType.info);

    try {
      // ── EST1: Esperar pieza en P1 + Prensa arriba S1 ──────────────
      setState(() => _currentState = 1);
      _logAudit('EST1 · Esperando pieza en P1 y prensa arriba (S1)...', LogType.info);
      setState(() {
        _sensor('P1').active = true;
        _sensor('S1').active = true;
      });
      await Future.delayed(const Duration(milliseconds: 800));

      // Paso 1: Enciende RLY03 (banda hacia adelante)
      _toggleActuator('RLY03', true);
      _logAudit('RLY03 ON · Banda transportadora hacia adelante', LogType.success);
      await Future.delayed(const Duration(seconds: 2));
      setState(() => _sensor('P1').active = false);

      // ── EST2: Pieza llegó a P2 + S1 aún activo ───────────────────
      setState(() => _currentState = 2);
      _logAudit('EST2 · Pieza detectada en prensa (P2+S1) · Iniciando prensado', LogType.info);
      setState(() => _sensor('P2').active = true);
      await Future.delayed(const Duration(milliseconds: 500));

      // Apaga banda
      _toggleActuator('RLY03', false);
      _logAudit('RLY03 OFF · Banda detenida', LogType.audit);
      await Future.delayed(const Duration(milliseconds: 500));

      // Baja prensa RLY02
      _toggleActuator('RLY02', true);
      _logAudit('RLY02 ON · Motor prensa bajando...', LogType.success);
      setState(() => _sensor('S1').active = false);
      await Future.delayed(const Duration(seconds: 2));

      // ── EST3: Prensa en tope inferior S2 ─────────────────────────
      setState(() => _currentState = 3);
      _logAudit('EST3 · Prensa en posición de trabajo (S2) · Troquelado!', LogType.success);
      setState(() => _sensor('S2').active = true);
      await Future.delayed(const Duration(milliseconds: 500));

      // Apaga bajada
      _toggleActuator('RLY02', false);
      _logAudit('RLY02 OFF · Motor prensa detenido', LogType.audit);
      await Future.delayed(const Duration(milliseconds: 500));

      // Sube prensa RLY01
      _toggleActuator('RLY01', true);
      _logAudit('RLY01 ON · Motor prensa subiendo...', LogType.success);
      setState(() => _sensor('S2').active = false);
      await Future.delayed(const Duration(seconds: 2));

      // ── EST4: Prensa arriba → expulsar pieza ──────────────────────
      setState(() => _currentState = 4);
      _logAudit('EST4 · Prensa en origen (S1) · Expulsando pieza...', LogType.info);
      setState(() => _sensor('S1').active = true);
      await Future.delayed(const Duration(milliseconds: 500));

      _toggleActuator('RLY01', false);
      _logAudit('RLY01 OFF · Prensa guardada de forma segura', LogType.audit);
      await Future.delayed(const Duration(milliseconds: 500));

      // Banda expulsa pieza
      _toggleActuator('RLY03', true);
      _logAudit('RLY03 ON · Expulsando pieza terminada...', LogType.success);
      await Future.delayed(const Duration(seconds: 3));

      _toggleActuator('RLY03', false);
      setState(() {
        _sensor('P2').active = false;
        _piezas++;
      });
      _logAudit('RLY03 OFF · Banda detenida', LogType.audit);
      _logAudit('✔ CICLO EXITOSO · Pieza troquelada y contabilizada', LogType.success);

    } catch (e) {
      _logAudit('ERROR en la secuencia automática: $e', LogType.error);
    }

    setState(() {
      _isCycleRunning = false;
      _currentState = 0;
      _updatePermissions();
    });
  }

  // ── BUILD ─────────────────────────────────────────────
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

  // ── Header ─────────────────────────────────────────────
  Widget _buildHeader() => Container(
        padding: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: kMachine, width: 2))),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('CENTRO DE PRENSADO SCADA 4.0',
                    style: TextStyle(color: kMachine, fontSize: 18,
                        fontWeight: FontWeight.bold, letterSpacing: 1.4)),
                Text('Art. No. TMPUM24-A  ·  Punching Machine 24V',
                    style: TextStyle(color: kText.withOpacity(0.5), fontSize: 10,
                        letterSpacing: 1)),
              ],
            ),
            Text(_clock,
                style: const TextStyle(color: kText, fontSize: 14,
                    fontFamily: 'monospace')),
          ],
        ),
      );

  // ── Top bar ────────────────────────────────────────────
  Widget _buildTopBar() => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: kPanel,
          border: Border.all(color: kBorder),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Wrap(
          spacing: 14, runSpacing: 10,
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
              icon: Icon(_isCycleRunning ? Icons.stop : Icons.play_arrow, size: 16),
              label: Text(_isCycleRunning ? 'Ejecutando...' : 'Iniciar Ciclo Automático'),
              style: ElevatedButton.styleFrom(
                backgroundColor: kGreen, foregroundColor: kBg,
                disabledBackgroundColor: const Color(0xFF333333),
                disabledForegroundColor: const Color(0xFF666666),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => _logAudit('Auditoría exportada por el usuario.', LogType.audit),
              icon: const Icon(Icons.download, size: 16),
              label: const Text('Exportar Auditoría CSV'),
              style: ElevatedButton.styleFrom(
                backgroundColor: kAudit, foregroundColor: kBg,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
            ),
            _kpiBox('Piezas Terminadas', '$_piezas', kGreen),
            _kpiBox('Eficiencia (OEE)', '${_piezas == 0 ? 100 : 100}%', kMachine),
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
          decoration: BoxDecoration(
            color: kBg, border: Border.all(color: kCyan),
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
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          border: Border.all(color: color),
          borderRadius: BorderRadius.circular(6)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(label, style: const TextStyle(color: kText, fontSize: 10)),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(color: color, fontSize: 22,
              fontWeight: FontWeight.bold)),
        ]),
      );

  // ── Row 1: Gemelo Digital + Sensores ───────────────────
  Widget _buildRow1() => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 2, child: _buildDigitalTwin()),
          const SizedBox(width: 10),
          Expanded(child: _buildSensorsPanel()),
        ],
      );

  Widget _buildDigitalTwin() {
    final rly01 = _act('RLY01').on;
    final rly02 = _act('RLY02').on;
    final rly03 = _act('RLY03').on;

    return _panel(
      title: 'Gemelo Digital 2D  ·  Punching Machine',
      titleColor: kMachine,
      height: 300,
      child: Stack(children: [
        // ── Banda transportadora (base) ────────────────────
        Positioned(
          left: 20, right: 20, top: 200,
          child: _dtRect('M2 · Banda Transportadora', rly03, kMachine,
              w: double.infinity, h: 36),
        ),

        // ── Sensor P1 (entrada de banda) ──────────────────
        Positioned(
          right: 30, top: 216,
          child: _sensorIndicator('P1', _sensor('P1').active),
        ),

        // ── Sensor P2 (bajo la prensa) ────────────────────
        Positioned(
          left: 120, top: 216,
          child: _sensorIndicator('P2', _sensor('P2').active),
        ),

        // ── Columna de la prensa (estructura) ─────────────
        Positioned(
          left: 90, top: 40,
          child: Container(
            width: 8, height: 150,
            color: const Color(0xFF334455),
          ),
        ),
        Positioned(
          left: 190, top: 40,
          child: Container(
            width: 8, height: 150,
            color: const Color(0xFF334455),
          ),
        ),
        // Tope superior
        Positioned(
          left: 80, top: 30,
          child: Container(
            width: 128, height: 16,
            decoration: BoxDecoration(
              color: const Color(0xFF445566),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),

        // ── Motor prensa (M1) ─────────────────────────────
        Positioned(
          left: 100, top: 20,
          child: _dtCircle('M1', rly01 || rly02, kMachine, 55),
        ),

        // ── Cabezal de la prensa (animado) ────────────────
        AnimatedPositioned(
          duration: const Duration(milliseconds: 500),
          left: 100,
          top: rly02 ? 155 : rly01 ? 80 : 110,
          child: Container(
            width: 88, height: 22,
            decoration: BoxDecoration(
              color: (rly01 || rly02)
                  ? kMachine.withOpacity(0.8)
                  : const Color(0xFF445566),
              borderRadius: BorderRadius.circular(4),
              boxShadow: (rly01 || rly02)
                  ? [BoxShadow(color: kMachine.withOpacity(0.5), blurRadius: 10)]
                  : null,
            ),
            alignment: Alignment.center,
            child: Text('CABEZAL',
                style: TextStyle(
                    color: (rly01 || rly02) ? kBg : kText,
                    fontSize: 9, fontWeight: FontWeight.bold)),
          ),
        ),

        // ── Etiqueta dirección prensa ──────────────────────
        Positioned(
          left: 10, top: 120,
          child: Column(
            children: [
              Icon(Icons.arrow_upward,
                  color: rly01 ? kGreen : kText.withOpacity(0.2), size: 14),
              Text('Arriba', style: TextStyle(
                  color: rly01 ? kGreen : kText.withOpacity(0.3),
                  fontSize: 8)),
              const SizedBox(height: 4),
              Icon(Icons.arrow_downward,
                  color: rly02 ? kRed : kText.withOpacity(0.2), size: 14),
              Text('Abajo', style: TextStyle(
                  color: rly02 ? kRed : kText.withOpacity(0.3),
                  fontSize: 8)),
            ],
          ),
        ),

        // ── Sensores de fin de carrera ─────────────────────
        Positioned(
          left: 200, top: 90,
          child: _sensorIndicator('S1', _sensor('S1').active),
        ),
        Positioned(
          left: 200, top: 185,
          child: _sensorIndicator('S2', _sensor('S2').active),
        ),

        // ── Pieza simulada ────────────────────────────────
        if (_sensor('P2').active)
          Positioned(
            left: 120, top: 180,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 40, height: 20,
              decoration: BoxDecoration(
                color: kGreen.withOpacity(0.6),
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: kGreen),
              ),
              alignment: Alignment.center,
              child: const Text('PIEZA', style: TextStyle(
                  color: kBg, fontSize: 7, fontWeight: FontWeight.bold)),
            ),
          ),
      ]),
    );
  }

  Widget _buildSensorsPanel() => _panel(
        title: 'Sensores (Toca para simular en Manual)',
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
          color: s.active ? kGreen.withOpacity(0.08) : Colors.black.withOpacity(0.3),
          border: Border.all(color: s.active ? kGreen.withOpacity(0.5) : kBorder),
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
                  style: TextStyle(color: s.active ? kGreen : kText,
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

  // ── Row 2: Actuadores + Audit ──────────────────────────
  Widget _buildRow2() => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _buildActuatorsPanel()),
          const SizedBox(width: 10),
          Expanded(flex: 2, child: _buildAuditPanel()),
        ],
      );

  Widget _buildActuatorsPanel() => _panel(
        title: 'Actuadores · Relés (RLY)',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: _actuators.map(_actuatorRow).toList(),
        ),
      );

  Widget _actuatorRow(ActuatorModel a) => Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: a.on
              ? kMachine.withOpacity(0.08)
              : Colors.black.withOpacity(0.3),
          border: Border.all(color: a.on ? kMachine.withOpacity(0.5) : kBorder),
          borderRadius: BorderRadius.circular(4)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(child: Text(a.id,
                  style: TextStyle(
                      color: a.on ? kMachine : kText,
                      fontSize: 13, fontWeight: FontWeight.bold))),
              Transform.scale(
                scale: 0.8,
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
          ],
        ),
      );

  Widget _buildAuditPanel() => _panel(
        title: 'Auditoría (Audit Trail) y Alertas',
        child: Container(
          height: 200,
          decoration: BoxDecoration(
            color: kBg, border: Border.all(color: kBorder),
            borderRadius: BorderRadius.circular(4)),
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
                      TextSpan(text: '[${l.time}] ',
                          style: const TextStyle(color: Color(0xFF546E7A))),
                      TextSpan(text: '[${l.user}] - ',
                          style: const TextStyle(color: kCyan)),
                      TextSpan(text: l.message,
                          style: TextStyle(color: l.color)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      );

  // ── Progreso de estados ────────────────────────────────
  Widget _buildStateProgress() => _panel(
        title: 'Progreso del Ciclo  ·  ${kEstados[_currentState]}',
        titleColor: _currentState > 0 ? kMachine : kText,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: List.generate(4, (i) {
                final state = i + 1;
                final done   = _currentState > state;
                final active = _currentState == state;
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: 6,
                        decoration: BoxDecoration(
                          color: done
                              ? kGreen
                              : active
                                  ? kMachine
                                  : kBorder,
                          borderRadius: BorderRadius.circular(3),
                          boxShadow: active
                              ? [BoxShadow(color: kMachine.withOpacity(0.6), blurRadius: 6)]
                              : null,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text('EST$state',
                          style: TextStyle(
                              color: done ? kGreen : active ? kMachine : const Color(0xFF546E7A),
                              fontSize: 9, fontWeight: FontWeight.bold)),
                    ]),
                  ),
                );
              }),
            ),
          ],
        ),
      );

  // ── Gemelo Digital helpers ─────────────────────────────
  Widget _dtRect(String label, bool active, Color color,
      {required double w, required double h}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: w, height: h,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: active ? color.withOpacity(0.25) : const Color(0xFF1A2233),
        border: Border.all(color: active ? color : const Color(0xFF334455), width: 1.5),
        borderRadius: BorderRadius.circular(4),
        boxShadow: active
            ? [BoxShadow(color: color.withOpacity(0.4), blurRadius: 10)]
            : null,
      ),
      child: Text(label,
          textAlign: TextAlign.center,
          style: TextStyle(
              color: active ? color : kText.withOpacity(0.5),
              fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _dtCircle(String label, bool active, Color color, double size) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: size, height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? color.withOpacity(0.2) : const Color(0xFF1A2233),
        border: Border.all(color: active ? color : const Color(0xFF334455), width: 2),
        boxShadow: active
            ? [BoxShadow(color: color.withOpacity(0.5), blurRadius: 14)]
            : null,
      ),
      child: Text(label,
          textAlign: TextAlign.center,
          style: TextStyle(
              color: active ? color : kText.withOpacity(0.5),
              fontSize: 9, fontWeight: FontWeight.bold)),
    );
  }

  Widget _sensorIndicator(String id, bool active) => AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 28, height: 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active ? kGreen.withOpacity(0.2) : Colors.transparent,
          border: Border.all(color: active ? kGreen : const Color(0xFF334455)),
          boxShadow: active
              ? [BoxShadow(color: kGreen.withOpacity(0.6), blurRadius: 8)]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(id,
            style: TextStyle(
                color: active ? kGreen : const Color(0xFF546E7A),
                fontSize: 7, fontWeight: FontWeight.bold)),
      );

  // ── Panel wrapper ──────────────────────────────────────
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
          color: kPanel,
          border: Border.all(color: kBorder),
          borderRadius: BorderRadius.circular(8)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.only(bottom: 8),
              decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: kBorder))),
              child: Text(title,
                  style: TextStyle(color: titleColor, fontSize: 12,
                      fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      );
}
