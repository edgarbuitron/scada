// ============================================================
// HITECH INGENIUM -- SCADA MASTER -- Flutter
// Dashboard General + 4 Estaciones + Chatbot IA
// ============================================================

import 'dart:async';
import 'package:flutter/material.dart';

// ── IMPORTS ──
import 'scada_neumatico.dart';
import 'main_prensado.dart';
import 'main_robot_3_ejes.dart';
import 'main_maquinados.dart';

void main() {
  runApp(const MyApp());
}

// ─── Paleta (variables CSS del HTML) ─────────────────────────────────────────
const Color kBgDark    = Color(0xFF0F172A);
const Color kPanelBg   = Color(0xFF1E293B);
const Color kSidebar   = Color(0xFF0B1120);
const Color kCyan      = Color(0xFF38BDF8);
const Color kGreen     = Color(0xFF10B981);
const Color kRed       = Color(0xFFF43F5E);
const Color kPurple    = Color(0xFFA855F7);
const Color kOrange    = Color(0xFFF59E0B);
const Color kTextMain  = Color(0xFFF8FAFC);
const Color kTextMuted = Color(0xFF94A3B8);
const Color kBorder    = Color(0xFF334155);

// ─── App ─────────────────────────────────────────────────────────────────────
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SCADA 4.0',
      theme: ThemeData.dark(),
      home: const ScadaMasterHome(), // ← Punto de entrada correcto
    );
  }
}

// ─── Modelos ─────────────────────────────────────────────────────────────────
enum LogType { info, audit, error }
enum AppView  { dashboard, neumatico, robot, maquinado, prensado }

class LogEntry {
  final String time, message;
  final LogType type;
  LogEntry(this.time, this.message, this.type);
  Color get color => type == LogType.error
      ? kRed
      : type == LogType.audit ? kCyan : kTextMain;
}

class SensorState {
  final String id, label;
  bool active;
  SensorState(this.id, this.label, {this.active = false});
}

class ActuatorState {
  final String id, label;
  bool on;
  bool disabled;
  ActuatorState(this.id, this.label, {this.on = false, this.disabled = false});
}

// ─── Home con Sidebar ─────────────────────────────────────────────────────────
class ScadaMasterHome extends StatefulWidget {
  const ScadaMasterHome({super.key});

  @override
  State<ScadaMasterHome> createState() => _ScadaMasterHomeState();
}

class _ScadaMasterHomeState extends State<ScadaMasterHome> {
  AppView _currentView = AppView.dashboard;
  String  _role  = 'Ingeniero';
  String  _mode  = 'manual';
  String  _clock = '';
  bool    _chatOpen = false;
  late Timer _clockTimer;

  // Contadores globales
  int _piezasNeumatico = 0;
  int _piezasMaquinado = 0;

  // Ciclos corriendo
  final Map<AppView, bool> _running = {
    AppView.neumatico: false,
    AppView.robot:     false,
    AppView.maquinado: false,
    AppView.prensado:  false,
  };

  // ── Sensores por estación ────────────────────────────────────────────────
  final Map<AppView, List<SensorState>> _sensors = {
    AppView.neumatico: [
      SensorState('p1', 'P1: Input Storage (Pieza)'),
      SensorState('p2', 'P2: Conveyor Final (Llegada)'),
      SensorState('s1', 'S1: Punching Machine Pos.'),
    ],
    AppView.robot: [
      SensorState('s_base', 'LS1: Límite Base Centro',  active: true),
      SensorState('s_z',    'LS2: Límite Eje Z (Arriba)', active: true),
      SensorState('s_arm',  'LS3: Límite Brazo Retraído', active: true),
    ],
    AppView.maquinado: [
      SensorState('p1', 'P1: Entrada a Línea'),
      SensorState('p3', 'P3: Pieza en Fresadora'),
      SensorState('p5', 'P5: Pieza Terminada (Salida)'),
    ],
    AppView.prensado: [
      SensorState('shome',  'S_HOME: Prensa Arriba',    active: true),
      SensorState('swork',  'S_WORK: Prensa Abajo'),
      SensorState('spiece', 'Barrera: Pieza Detectada'),
    ],
  };

  // ── Actuadores por estación ──────────────────────────────────────────────
  final Map<AppView, List<ActuatorState>> _actuators = {
    AppView.neumatico: [
      ActuatorState('m1', 'M1: Compresor Neumático'),
      ActuatorState('m3', 'M3: Banda Transportadora'),
      ActuatorState('m2', 'M2: Mesa Giratoria'),
      ActuatorState('v1', 'V1: Pistón Entrada'),
      ActuatorState('v3', 'V3: Perforadora (Bajar)'),
    ],
    AppView.robot: [
      ActuatorState('m1', 'M1: Base Rotatoria (CW)'),
      ActuatorState('m3', 'M3: Eje Vertical (Bajar)'),
      ActuatorState('m2', 'M2: Brazo (Expandir)'),
      ActuatorState('m4', 'M4: Gripper (Cerrar)'),
    ],
    AppView.maquinado: [
      ActuatorState('m1', 'M1: Banda Entrada Fwd'),
      ActuatorState('m2', 'M2: Motor Fresadora (Milling)'),
      ActuatorState('m4', 'M4: Motor Taladro (Drilling)'),
      ActuatorState('m8', 'M8: Banda Salida Fwd'),
    ],
    AppView.prensado: [
      ActuatorState('rly01', 'RLY01: Prensa a Home'),
      ActuatorState('rly02', 'RLY02: Prensa a Trabajo (Bajar)'),
      ActuatorState('rly03', 'RLY03: Banda Hacia Adelante'),
    ],
  };

  // ── Logs por estación ────────────────────────────────────────────────────
  final Map<AppView, List<LogEntry>> _logs = {
    AppView.neumatico: [],
    AppView.robot:     [],
    AppView.maquinado: [],
    AppView.prensado:  [],
  };

  // ── Scroll controllers ───────────────────────────────────────────────────
  final Map<AppView, ScrollController> _logScrolls = {
    AppView.neumatico: ScrollController(),
    AppView.robot:     ScrollController(),
    AppView.maquinado: ScrollController(),
    AppView.prensado:  ScrollController(),
  };

  // ── Chat ─────────────────────────────────────────────────────────────────
  final List<_ChatMsg> _chatMessages = [
    _ChatMsg('¡Hola! Soy el asistente virtual de Hitech. ¿Qué datos necesitas?', false),
  ];
  final TextEditingController _chatCtrl   = TextEditingController();
  final ScrollController      _chatScroll = ScrollController();
  bool _chatLoading = false;

  // ── Gráfica ──────────────────────────────────────────────────────────────
  final List<double> _chartNeumatico = [120, 150, 140, 160, 170, 165, 180];
  final List<double> _chartMaquinado = [90,  110, 105, 120, 130, 125, 140];
  final List<String> _chartLabels    = ['08:00','09:00','10:00','11:00','12:00','13:00','14:00'];

  // ── Helpers ──────────────────────────────────────────────────────────────
  SensorState   _sensor(AppView v, String id) => _sensors[v]!.firstWhere((s) => s.id == id);
  ActuatorState _act   (AppView v, String id) => _actuators[v]!.firstWhere((a) => a.id == id);
  bool get _autoEnabled => _mode == 'auto';

  String _now() {
    final n = DateTime.now();
    return '${n.hour.toString().padLeft(2,'0')}:${n.minute.toString().padLeft(2,'0')}:${n.second.toString().padLeft(2,'0')}';
  }

  void _log(AppView v, String msg, LogType type) {
    setState(() => _logs[v]!.add(LogEntry(_now(), msg, type)));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final sc = _logScrolls[v]!;
      if (sc.hasClients) sc.animateTo(sc.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
    });
  }

  void _updatePermissions() {
    for (final v in [AppView.neumatico, AppView.robot, AppView.maquinado, AppView.prensado]) {
      for (final a in _actuators[v]!) {
        a.disabled = (_role == 'Operador' || _mode == 'auto' || _running[v]!);
      }
    }
  }

  void _toggleSensor(AppView v, String id) {
    if (_mode != 'manual') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Cambia el modo a 'Manual' para forzar sensores."),
        backgroundColor: kOrange,
      ));
      return;
    }
    final s = _sensor(v, id);
    setState(() => s.active = !s.active);
    _log(v, 'Sensor ${id.toUpperCase()} forzado a ${s.active ? 'ON' : 'OFF'}', LogType.audit);
  }

  void _toggleActuator(AppView v, String id, bool val) {
    setState(() => _act(v, id).on = val);
    if (!_running[v]!) {
      _log(v, 'Actuador ${id.toUpperCase()} → ${val ? 'ON' : 'OFF'}', LogType.audit);
    }
  }

  // ── Ciclos automáticos ───────────────────────────────────────────────────
  Future<void> _startCycle(AppView v) async {
    if (_running[v]!) return;
    setState(() { _running[v] = true; _updatePermissions(); });
    _log(v, '--- INICIANDO SECUENCIA AUTOMÁTICA ---', LogType.info);
    try {
      if (v == AppView.neumatico) {
        _toggleActuator(v, 'v1', true);  await Future.delayed(const Duration(seconds: 1));
        _toggleActuator(v, 'v1', false);
        _toggleActuator(v, 'm2', true);  await Future.delayed(const Duration(milliseconds: 1500));
        _toggleActuator(v, 'm2', false);
        _toggleActuator(v, 'v3', true);  await Future.delayed(const Duration(seconds: 1));
        _toggleActuator(v, 'v3', false);
        _toggleActuator(v, 'm3', true);  await Future.delayed(const Duration(milliseconds: 1500));
        _toggleActuator(v, 'm3', false);
        setState(() => _piezasNeumatico++);
      } else if (v == AppView.robot) {
        _toggleActuator(v, 'm1', true);  await Future.delayed(const Duration(milliseconds: 1500));
        _toggleActuator(v, 'm1', false);
        _toggleActuator(v, 'm3', true);  await Future.delayed(const Duration(seconds: 1));
        _toggleActuator(v, 'm4', true);  await Future.delayed(const Duration(milliseconds: 800));
        _toggleActuator(v, 'm3', false); await Future.delayed(const Duration(seconds: 1));
        _toggleActuator(v, 'm4', false);
      } else if (v == AppView.maquinado) {
        _toggleActuator(v, 'm1', true);  await Future.delayed(const Duration(seconds: 1));
        _toggleActuator(v, 'm1', false);
        _toggleActuator(v, 'm2', true);  await Future.delayed(const Duration(seconds: 2));
        _toggleActuator(v, 'm2', false);
        _toggleActuator(v, 'm8', true);  await Future.delayed(const Duration(seconds: 1));
        _toggleActuator(v, 'm8', false);
        setState(() => _piezasMaquinado++);
      } else if (v == AppView.prensado) {
        _toggleActuator(v, 'rly03', true);  await Future.delayed(const Duration(milliseconds: 1500));
        _toggleActuator(v, 'rly03', false);
        _toggleActuator(v, 'rly02', true);  await Future.delayed(const Duration(seconds: 1));
        _toggleActuator(v, 'rly02', false);
        _toggleActuator(v, 'rly01', true);  await Future.delayed(const Duration(seconds: 1));
        _toggleActuator(v, 'rly01', false);
      }
      _log(v, '--- CICLO COMPLETADO ---', LogType.audit);
    } catch (e) {
      _log(v, 'Error en secuencia: $e', LogType.error);
    }
    setState(() { _running[v] = false; _updatePermissions(); });
  }

  // ── Chat IA ──────────────────────────────────────────────────────────────
  Future<void> _sendChat() async {
    final text = _chatCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _chatMessages.add(_ChatMsg(text, true));
      _chatLoading = true;
      _chatCtrl.clear();
    });
    _scrollChat();
    await Future.delayed(const Duration(seconds: 1));
    String respuesta;
    try {
      respuesta = _mockBotResponse(text);
    } catch (_) {
      respuesta = '🚫 Error de conexión con el servidor.';
    }
    setState(() {
      _chatLoading = false;
      _chatMessages.add(_ChatMsg(respuesta, false));
    });
    _scrollChat();
  }

  String _mockBotResponse(String q) {
    q = q.toLowerCase();
    if (q.contains('oee'))     return 'OEE de la planta: 87.5%\nCentro Neumático y Maquinados operando dentro de parámetros.';
    if (q.contains('piezas'))  return 'Producción actual:\n• Centro Neumático: $_piezasNeumatico piezas\n• Centro Maquinados: $_piezasMaquinado piezas\n• Total: ${_piezasNeumatico + _piezasMaquinado} piezas';
    if (q.contains('estado'))  return 'Estado del sistema:\n• Modo: $_mode\n• Rol activo: $_role\n• Vista activa: ${_viewTitle(_currentView)}';
    if (q.contains('sensor'))  return 'Todos los sensores están siendo monitoreados en tiempo real.';
    if (q.contains('alarma') || q.contains('alerta')) return '✅ Sin alarmas activas en este momento.';
    return 'Consulta recibida: "$q"\n\nPuedo darte datos de producción, OEE, estado de sensores y actuadores de las 4 estaciones. ¿Qué necesitas?';
  }

  void _scrollChat() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScroll.hasClients) {
        _chatScroll.animateTo(_chatScroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _updateClock();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(_updateClock);
    });
  }

  void _updateClock() {
    final n = DateTime.now();
    _clock = '${n.hour.toString().padLeft(2,'0')}:${n.minute.toString().padLeft(2,'0')}:${n.second.toString().padLeft(2,'0')}';
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    for (final sc in _logScrolls.values) sc.dispose();
    _chatCtrl.dispose();
    _chatScroll.dispose();
    super.dispose();
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 800;
    return Scaffold(
      backgroundColor: kBgDark,
      body: Stack(
        children: [
          Row(
            children: [
              // ── Sidebar ──────────────────────────────────────────────────
              if (isWide) _buildSidebar(),
              // ── Main content ─────────────────────────────────────────────
              Expanded(
                child: Column(
                  children: [
                    _buildTopBar(),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 350),
                        transitionBuilder: (child, anim) => FadeTransition(
                          opacity: anim,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.03),
                              end: Offset.zero,
                            ).animate(anim),
                            child: child,
                          ),
                        ),
                        child: KeyedSubtree(
                          key: ValueKey(_currentView),
                          child: _buildCurrentView(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // ── Chatbot FAB ──────────────────────────────────────────────────
          _buildChatbot(),
        ],
      ),
      drawer: isWide
          ? null
          : Drawer(
              backgroundColor: kSidebar,
              child: _buildSidebarContent(),
            ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SIDEBAR
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildSidebar() => Container(
        width: 250,
        decoration: const BoxDecoration(
          color: kSidebar,
          border: Border(right: BorderSide(color: kBorder)),
        ),
        child: _buildSidebarContent(),
      );

  Widget _buildSidebarContent() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: const Column(children: [
              Text('HITECH INGENIUM',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: kCyan, fontSize: 18,
                      fontWeight: FontWeight.bold, letterSpacing: 1)),
              SizedBox(height: 4),
              Text('SCADA MASTER',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: kTextMuted, fontSize: 12, letterSpacing: 2)),
            ]),
          ),
          const Divider(color: kBorder, height: 1),
          const SizedBox(height: 8),
          _navItem('📊', 'Dashboard General', AppView.dashboard),
          _navItem('⚙️', 'Centro Neumático',  AppView.neumatico),
          _navItem('🤖', 'Robot 3 Ejes',       AppView.robot),
          _navItem('🛠️', 'Centro Maquinados',  AppView.maquinado),
          _navItem('🛑', 'Centro de Prensado', AppView.prensado),
        ],
      );

  Widget _navItem(String emoji, String label, AppView view) {
    final active = _currentView == view;
    Color dotColor;
    switch (view) {
      case AppView.neumatico: dotColor = kCyan;   break;
      case AppView.robot:     dotColor = kPurple; break;
      case AppView.maquinado: dotColor = kGreen;  break;
      case AppView.prensado:  dotColor = kRed;    break;
      default:                dotColor = kCyan;
    }
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: active ? kCyan.withOpacity(0.12) : Colors.transparent,
        border: Border(left: BorderSide(
          color: active ? dotColor : Colors.transparent,
          width: 3,
        )),
      ),
      child: InkWell(
        onTap: () {
          setState(() => _currentView = view);
          // Solo cerrar drawer en móvil
          if (MediaQuery.of(context).size.width <= 800) {
            Navigator.pop(context);
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          child: Row(children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 10),
            Text(label,
                style: TextStyle(
                  color: active ? dotColor : kTextMuted,
                  fontWeight: active ? FontWeight.bold : FontWeight.normal,
                  fontSize: 14,
                )),
          ]),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // TOP BAR
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildTopBar() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: const BoxDecoration(
          color: kPanelBg,
          border: Border(bottom: BorderSide(color: kBorder)),
        ),
        child: Row(
          children: [
            if (MediaQuery.of(context).size.width <= 800)
              Builder(builder: (ctx) => IconButton(
                icon: const Icon(Icons.menu, color: kCyan),
                onPressed: () => Scaffold.of(ctx).openDrawer(),
              )),
            Expanded(
              child: Text(_viewTitle(_currentView),
                  style: const TextStyle(
                      color: kCyan, fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            Text(_clock,
                style: const TextStyle(
                    color: kCyan, fontSize: 15, fontFamily: 'monospace')),
            const SizedBox(width: 20),
            const Text('Rol:', style: TextStyle(color: kTextMuted, fontSize: 12)),
            const SizedBox(width: 6),
            _topSelect(_role, {
              'Ingeniero': 'Ingeniero (Control Total)',
              'Operador':  'Operador (Solo Lectura/Auto)',
            }, (v) { setState(() { _role = v!; _updatePermissions(); }); }),
            const SizedBox(width: 16),
            const Text('Modo de Planta:', style: TextStyle(color: kTextMuted, fontSize: 12)),
            const SizedBox(width: 6),
            _topSelect(_mode, {
              'manual': 'Manual (Forzar/Simular)',
              'auto':   'Automático',
            }, (v) { setState(() { _mode = v!; _updatePermissions(); }); }),
          ],
        ),
      );

  Widget _topSelect(String val, Map<String, String> items, ValueChanged<String?> fn) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: kBgDark,
          border: Border.all(color: kCyan),
          borderRadius: BorderRadius.circular(4),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: val,
            dropdownColor: kPanelBg,
            style: const TextStyle(color: kCyan, fontSize: 12),
            icon: const Icon(Icons.arrow_drop_down, color: kCyan, size: 18),
            isDense: true,
            items: items.entries
                .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                .toList(),
            onChanged: fn,
          ),
        ),
      );

  String _viewTitle(AppView v) {
    switch (v) {
      case AppView.dashboard: return 'Dashboard General de Planta';
      case AppView.neumatico: return 'Estación 1: Centro Neumático';
      case AppView.robot:     return 'Estación 2: Robot 3 Ejes';
      case AppView.maquinado: return 'Estación 3: Centro Maquinados';
      case AppView.prensado:  return 'Estación 4: Centro Prensado';
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ROUTER DE VISTAS  ← aquí se enlaza con scada_neumatico.dart
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildCurrentView() {
    switch (_currentView) {
      case AppView.dashboard:
        return _buildDashboard();
      case AppView.neumatico:
        return const ScadaNeumaticoBoard(); // ← Widget exportado por scada_neumatico.dart
      case AppView.robot:
        return ScadaRobot3EjesScreen();
      case AppView.maquinado:
        return ScadaMaquinadosScreen();
      case AppView.prensado:
        return ScadaPrensadoScreen();
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // DASHBOARD GENERAL
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildDashboard() => SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          LayoutBuilder(builder: (_, box) {
            final cols = box.maxWidth > 700 ? 4 : 2;
            return Wrap(
              spacing: 16, runSpacing: 16,
              children: [
                _kpiCard('OEE Planta',         '87.5%',             kGreen, width: (box.maxWidth - 16*(cols-1)) / cols),
                _kpiCard('Producción Total',    '1,240',             kCyan,  width: (box.maxWidth - 16*(cols-1)) / cols),
                _kpiCard('Piezas Neumático',    '$_piezasNeumatico', kGreen, width: (box.maxWidth - 16*(cols-1)) / cols),
                _kpiCard('Piezas Maquinado',    '$_piezasMaquinado', kGreen, width: (box.maxWidth - 16*(cols-1)) / cols),
              ],
            );
          }),
          const SizedBox(height: 24),
          _panel(
            title: 'Rendimiento de Línea (Tiempo Real)',
            height: 340,
            child: CustomPaint(
              painter: _LineChartPainter(
                dataSets:     [_chartNeumatico, _chartMaquinado],
                labels:       _chartLabels,
                colors:       [kCyan, kGreen],
                seriesLabels: ['Centro Neumático', 'Centro Maquinados'],
              ),
            ),
          ),
        ]),
      );

  Widget _kpiCard(String title, String value, Color color, {required double width}) =>
      SizedBox(
        width: width,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: kPanelBg,
            border: Border.all(color: kBorder),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(children: [
            Text(title, textAlign: TextAlign.center,
                style: const TextStyle(color: kTextMuted, fontSize: 12, letterSpacing: 1)),
            const SizedBox(height: 10),
            Text(value,
                style: TextStyle(color: color, fontSize: 30, fontWeight: FontWeight.bold)),
          ]),
        ),
      );

  // ─────────────────────────────────────────────────────────────────────────
  // VISTA DE ESTACIÓN (Genérica — usada solo si alguna pantalla hija no existe aún)
  // ─────────────────────────────────────────────────────────────────────────
  // ignore: unused_element
  Widget _buildStationView(AppView v) {
    final color  = _stationColor(v);
    final isWide = MediaQuery.of(context).size.width > 700;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        SizedBox(
          height: 46,
          child: ElevatedButton.icon(
            onPressed: (_autoEnabled && !_running[v]!) ? () => _startCycle(v) : null,
            icon: Icon(_running[v]! ? Icons.stop_circle : Icons.play_circle, size: 20),
            label: Text(_running[v]! ? 'EJECUTANDO...' : _cycleLabel(v),
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
            style: ElevatedButton.styleFrom(
              backgroundColor:         color,
              foregroundColor:         kBgDark,
              disabledBackgroundColor: const Color(0xFF334155),
              disabledForegroundColor: kTextMuted,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildDigitalTwin(v),
        const SizedBox(height: 16),
        isWide
            ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: _buildSensorsPanel(v)),
                const SizedBox(width: 16),
                Expanded(child: _buildActuatorsPanel(v)),
              ])
            : Column(children: [
                _buildSensorsPanel(v),
                const SizedBox(height: 12),
                _buildActuatorsPanel(v),
              ]),
        const SizedBox(height: 12),
        _buildLogBox(v),
      ]),
    );
  }

  String _cycleLabel(AppView v) {
    switch (v) {
      case AppView.neumatico: return '▶ INICIAR CICLO AUTOMÁTICO - NEUMÁTICO';
      case AppView.robot:     return '▶ INICIAR RUTINA ROBOT - 3 EJES';
      case AppView.maquinado: return '▶ INICIAR LÍNEA DE MAQUINADO';
      case AppView.prensado:  return '▶ INICIAR ESTAMPADO / PRENSA';
      default:                return '▶ INICIAR';
    }
  }

  Color _stationColor(AppView v) {
    switch (v) {
      case AppView.neumatico: return kCyan;
      case AppView.robot:     return kPurple;
      case AppView.maquinado: return kGreen;
      case AppView.prensado:  return kRed;
      default:                return kCyan;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // GEMELOS DIGITALES
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildDigitalTwin(AppView v) => Container(
        height: 250,
        decoration: BoxDecoration(
          color: const Color(0xFF0C1820),
          border: Border.all(color: kBorder),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(children: [
          Positioned(
            top: 10, left: 10,
            child: Text('Gemelo Digital: ${_stationTwinLabel(v)}',
                style: const TextStyle(color: kTextMuted, fontSize: 12)),
          ),
          ..._buildTwinParts(v),
        ]),
      );

  String _stationTwinLabel(AppView v) {
    switch (v) {
      case AppView.neumatico: return 'Centro Neumático';
      case AppView.robot:     return 'Robot Manipulador';
      case AppView.maquinado: return 'Línea Indexada';
      case AppView.prensado:  return 'Máquina de Prensado';
      default:                return '';
    }
  }

  List<Widget> _buildTwinParts(AppView v) {
    switch (v) {
      case AppView.neumatico: return _twinNeumatico();
      case AppView.robot:     return _twinRobot();
      case AppView.maquinado: return _twinMaquinado();
      case AppView.prensado:  return _twinPrensado();
      default:                return [];
    }
  }

  List<Widget> _twinNeumatico() {
    final m1 = _act(AppView.neumatico, 'm1').on;
    final m2 = _act(AppView.neumatico, 'm2').on;
    final m3 = _act(AppView.neumatico, 'm3').on;
    final v1 = _act(AppView.neumatico, 'v1').on;
    final v3 = _act(AppView.neumatico, 'v3').on;
    return [
      _dtPart(top: 40,  left: 20,  w: 60,  h: 60,  label: 'Comp.\n(M1)',                active: m1, circle: true),
      _dtPart(top: 150, left: 120, w: 200, h: 30,  label: 'Banda Transportadora (M3)', active: m3),
      _dtPart(top: 110, left: 120, w: 40,  h: 40,  label: 'V1',                         active: v1),
      _dtPartRight(top: 100, right: 60, w: 80, h: 80, label: 'Mesa\n(M2)',               active: m2, circle: true),
      _dtPartRight(top: 40,  right: 80, w: 40, h: 40, label: 'V3',                       active: v3),
    ];
  }

  List<Widget> _twinRobot() {
    final m1 = _act(AppView.robot, 'm1').on;
    final m2 = _act(AppView.robot, 'm2').on;
    final m3 = _act(AppView.robot, 'm3').on;
    final m4 = _act(AppView.robot, 'm4').on;
    return [
      _dtPartBottom(bottom: 20, leftFrac: 0.4,  w: 100, h: 40,  label: 'Base Giratoria\n(M1)', active: m1),
      _dtPartBottom(bottom: 60, leftFrac: 0.45, w: 40,  h: 120, label: 'Eje Z\n(M3)',           active: m3, extraOffset: m3 ? 30.0 : 0.0),
      _dtPartTop   (top: 70,   leftFrac: 0.5,  w: 120, h: 20,  label: 'Brazo Ext. (M2)',        active: m2),
      _dtPartTop   (top: 60,   leftFrac: 0.5,  w: 30,  h: 40,  label: 'Gripper\n(M4)',           active: m4, extraLeftOffset: 120),
    ];
  }

  List<Widget> _twinMaquinado() {
    final m1 = _act(AppView.maquinado, 'm1').on;
    final m2 = _act(AppView.maquinado, 'm2').on;
    final m4 = _act(AppView.maquinado, 'm4').on;
    final m8 = _act(AppView.maquinado, 'm8').on;
    return [
      _dtPart(top: 100, left: 20,  w: 100, h: 30, label: 'Banda Ent (M1)',      active: m1),
      _dtPart(top: 40,  left: 150, w: 60,  h: 60, label: 'Fresa\n(M2)',          active: m2, circle: true, activeColor: kGreen),
      _dtPart(top: 40,  left: 240, w: 60,  h: 60, label: 'Taladro\n(M4)',        active: m4, circle: true, activeColor: kGreen),
      _dtPart(top: 100, left: 330, w: 100, h: 30, label: 'Banda Sal (M8)',      active: m8),
    ];
  }

  List<Widget> _twinPrensado() {
    final rly01 = _act(AppView.prensado, 'rly01').on;
    final rly02 = _act(AppView.prensado, 'rly02').on;
    final rly03 = _act(AppView.prensado, 'rly03').on;
    return [
      _dtPartBottom(bottom: 40, leftFrac: 0.05, w: 300, h: 40,
          label: 'Cinta Transportadora (RLY03)', active: rly03),
      AnimatedPositioned(
        duration: const Duration(milliseconds: 400),
        top: rly02 ? 60 : 20,
        left: 150,
        child: _dtBox(100, 80, 'Cabezal Prensa\n(RLY02)', rly01 || rly02),
      ),
    ];
  }

  // ── DT Widget helpers ────────────────────────────────────────────────────
  Widget _dtPart({required double top, required double left,
    required double w, required double h, required String label,
    required bool active, bool circle = false, Color activeColor = kCyan}) =>
      Positioned(top: top, left: left,
          child: _dtBox(w, h, label, active, circle: circle, color: activeColor));

  Widget _dtPartRight({required double top, required double right,
    required double w, required double h, required String label,
    required bool active, bool circle = false}) =>
      Positioned(top: top, right: right,
          child: _dtBox(w, h, label, active, circle: circle));

  Widget _dtPartBottom({required double bottom, required double leftFrac,
    required double w, required double h, required String label,
    required bool active, double extraOffset = 0}) =>
      LayoutBuilder(builder: (ctx, _) => Positioned(
        bottom: bottom + extraOffset,
        left: MediaQuery.of(ctx).size.width * 0.0,
        child: _dtBox(w, h, label, active),
      ));

  Widget _dtPartTop({required double top, required double leftFrac,
    required double w, required double h, required String label,
    required bool active, double extraLeftOffset = 0}) =>
      LayoutBuilder(builder: (ctx, box) => Positioned(
        top: top,
        left: box.maxWidth * leftFrac + extraLeftOffset,
        child: _dtBox(w, h, label, active),
      ));

  Widget _dtBox(double w, double h, String label, bool active,
      {bool circle = false, Color color = kCyan}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: w, height: h,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: active ? color.withOpacity(0.25) : const Color(0xFF334155),
        border: Border.all(
            color: active ? Colors.white : const Color(0xFF475569), width: 2),
        borderRadius: BorderRadius.circular(circle ? h / 2 : 4),
        boxShadow: active
            ? [BoxShadow(color: color.withOpacity(0.5), blurRadius: 15)]
            : null,
      ),
      child: Text(label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: active ? kBgDark : kTextMain,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          )),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SENSORES
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildSensorsPanel(AppView v) => _panel(
        title: _sensorPanelTitle(v),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: _sensors[v]!.map((s) => _sensorRow(v, s)).toList(),
        ),
      );

  String _sensorPanelTitle(AppView v) {
    switch (v) {
      case AppView.robot:    return 'Sensores (Límites de Ejes)';
      case AppView.prensado: return 'Sensores de Seguridad';
      default:               return 'Sensores (Entradas)';
    }
  }

  Widget _sensorRow(AppView v, SensorState s) => GestureDetector(
        onTap: () => _toggleSensor(v, s.id),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: s.active ? kGreen.withOpacity(0.06) : Colors.black.withOpacity(0.2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(children: [
            Expanded(child: Text(s.label, style: const TextStyle(color: kTextMain, fontSize: 13))),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 12, height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: s.active ? kGreen : const Color(0xFF334155),
                boxShadow: s.active
                    ? [BoxShadow(color: kGreen.withOpacity(0.7), blurRadius: 8)]
                    : null,
              ),
            ),
          ]),
        ),
      );

  // ─────────────────────────────────────────────────────────────────────────
  // ACTUADORES
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildActuatorsPanel(AppView v) {
    final title = v == AppView.robot
        ? 'Motores de Ejes (Actuadores)'
        : v == AppView.prensado
            ? 'Relés de Potencia (Salidas)'
            : 'Actuadores (Salidas)';
    return _panel(
      title: title,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: _actuators[v]!.map((a) => _actuatorRow(v, a)).toList(),
      ),
    );
  }

  Widget _actuatorRow(AppView v, ActuatorState a) => Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.2),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(children: [
          Expanded(child: Text(a.label, style: const TextStyle(color: kTextMain, fontSize: 13))),
          Transform.scale(
            scale: 0.8,
            child: Switch(
              value: a.on,
              onChanged: a.disabled ? null : (val) => _toggleActuator(v, a.id, val),
              activeColor:         Colors.white,
              activeTrackColor:    kCyan,
              inactiveThumbColor:  Colors.white,
              inactiveTrackColor:  const Color(0xFF334155),
            ),
          ),
        ]),
      );

  // ─────────────────────────────────────────────────────────────────────────
  // LOG BOX
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildLogBox(AppView v) => Container(
        height: 140,
        decoration: BoxDecoration(
          color: kBgDark,
          border: Border.all(color: kBorder),
          borderRadius: BorderRadius.circular(4),
        ),
        padding: const EdgeInsets.all(8),
        child: ListView.builder(
          controller: _logScrolls[v],
          itemCount: _logs[v]!.length,
          itemBuilder: (_, i) {
            final l = _logs[v]![i];
            return Text('[${l.time}] ${l.message}',
                style: TextStyle(color: l.color, fontSize: 11, fontFamily: 'monospace'));
          },
        ),
      );

  // ─────────────────────────────────────────────────────────────────────────
  // CHATBOT
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildChatbot() => Positioned(
        bottom: 20, right: 20,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (_chatOpen)
              Container(
                width: 340, height: 440,
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: kPanelBg,
                  border: Border.all(color: kBorder),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [BoxShadow(
                      color: Colors.black54, blurRadius: 20, offset: Offset(0, 8))],
                ),
                child: Column(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: const BoxDecoration(
                      color: kCyan,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(12), topRight: Radius.circular(12)),
                    ),
                    child: Row(children: [
                      const Text('Hitech Bot 🤖',
                          style: TextStyle(color: kBgDark, fontWeight: FontWeight.bold, fontSize: 14)),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => setState(() => _chatOpen = false),
                        child: const Icon(Icons.close, color: kBgDark, size: 18),
                      ),
                    ]),
                  ),
                  Expanded(
                    child: Container(
                      color: kSidebar,
                      child: ListView.builder(
                        controller: _chatScroll,
                        padding: const EdgeInsets.all(12),
                        itemCount: _chatMessages.length + (_chatLoading ? 1 : 0),
                        itemBuilder: (_, i) {
                          if (_chatLoading && i == _chatMessages.length) {
                            return _chatBubble('Consultando SCADA...', false, typing: true);
                          }
                          final m = _chatMessages[i];
                          return _chatBubble(m.text, m.isUser);
                        },
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: kPanelBg,
                      border: Border(top: BorderSide(color: kBorder)),
                    ),
                    child: Row(children: [
                      Expanded(
                        child: TextField(
                          controller: _chatCtrl,
                          style: const TextStyle(color: kTextMain, fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'Pregunta algo...',
                            hintStyle: const TextStyle(color: kTextMuted, fontSize: 12),
                            filled: true, fillColor: kBgDark,
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                                borderSide: const BorderSide(color: kBorder)),
                            enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                                borderSide: const BorderSide(color: kBorder)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          ),
                          onSubmitted: (_) => _sendChat(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _sendChat,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                              color: kCyan, borderRadius: BorderRadius.circular(6)),
                          child: const Icon(Icons.send, color: kBgDark, size: 16),
                        ),
                      ),
                    ]),
                  ),
                ]),
              ),
            ElevatedButton.icon(
              onPressed: () => setState(() => _chatOpen = !_chatOpen),
              icon: const Text('💬', style: TextStyle(fontSize: 16)),
              label: const Text('Asistente IA',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              style: ElevatedButton.styleFrom(
                backgroundColor: kCyan,
                foregroundColor: kBgDark,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                elevation: 8,
              ),
            ),
          ],
        ),
      );

  Widget _chatBubble(String text, bool isUser, {bool typing = false}) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 260),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isUser ? kCyan : kPanelBg,
          border: isUser ? null : Border.all(color: kBorder),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(8),
            topRight: const Radius.circular(8),
            bottomLeft: Radius.circular(isUser ? 8 : 0),
            bottomRight: Radius.circular(isUser ? 0 : 8),
          ),
        ),
        child: typing
            ? const _TypingIndicator()
            : Text(text,
                style: TextStyle(
                    color: isUser ? kBgDark : kTextMain, fontSize: 13, height: 1.4)),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Panel base
  // ─────────────────────────────────────────────────────────────────────────
  Widget _panel({required String title, required Widget child, double? height}) =>
      Container(
        height: height,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kPanelBg,
          border: Border.all(color: kBorder),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: height != null ? MainAxisSize.max : MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.only(bottom: 10),
              decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: kBorder))),
              child: Text(title,
                  style: const TextStyle(
                      color: kCyan, fontSize: 14, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 10),
            height != null ? Expanded(child: child) : child,
          ],
        ),
      );
}

// ─── Chat message model ────────────────────────────────────────────────────
class _ChatMsg {
  final String text;
  final bool isUser;
  const _ChatMsg(this.text, this.isUser);
}

// ─── Typing indicator animado ──────────────────────────────────────────────
class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();
  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: _anim,
        child: const Text('Consultando SCADA...',
            style: TextStyle(
                color: kTextMuted, fontSize: 12, fontStyle: FontStyle.italic)),
      );
}

// ─── Gráfica de líneas ─────────────────────────────────────────────────────
class _LineChartPainter extends CustomPainter {
  final List<List<double>> dataSets;
  final List<String> labels;
  final List<Color> colors;
  final List<String> seriesLabels;

  _LineChartPainter({
    required this.dataSets,
    required this.labels,
    required this.colors,
    required this.seriesLabels,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const double padL = 40, padR = 20, padT = 40, padB = 30;
    final chartW = size.width  - padL - padR;
    final chartH = size.height - padT - padB;

    double minV = double.infinity, maxV = double.negativeInfinity;
    for (final ds in dataSets) {
      for (final v in ds) {
        if (v < minV) minV = v;
        if (v > maxV) maxV = v;
      }
    }
    minV = (minV - 10).floorToDouble();
    maxV = (maxV + 10).ceilToDouble();

    final gridPaint  = Paint()..color = kBorder..strokeWidth = 0.5;
    const labelStyle = TextStyle(color: kTextMuted, fontSize: 9);
    const steps      = 5;

    for (int i = 0; i <= steps; i++) {
      final y   = padT + chartH - (i / steps) * chartH;
      canvas.drawLine(Offset(padL, y), Offset(padL + chartW, y), gridPaint);
      final val = (minV + (maxV - minV) * i / steps).toInt();
      final tp  = TextPainter(
          text: TextSpan(text: '$val', style: labelStyle),
          textDirection: TextDirection.ltr)..layout();
      tp.paint(canvas, Offset(padL - tp.width - 4, y - 6));
    }

    final n = labels.length;
    for (int i = 0; i < n; i++) {
      final x = padL + (i / (n - 1)) * chartW;
      canvas.drawLine(Offset(x, padT), Offset(x, padT + chartH), gridPaint);
      final tp = TextPainter(
          text: TextSpan(text: labels[i], style: labelStyle),
          textDirection: TextDirection.ltr)..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, padT + chartH + 4));
    }

    for (int s = 0; s < dataSets.length; s++) {
      final data     = dataSets[s];
      final color    = colors[s];
      final path     = Path();
      final fillPath = Path();

      for (int i = 0; i < data.length; i++) {
        final x = padL + (i / (data.length - 1)) * chartW;
        final y = padT + chartH - ((data[i] - minV) / (maxV - minV)) * chartH;
        if (i == 0) {
          path.moveTo(x, y);
          fillPath.moveTo(x, padT + chartH);
          fillPath.lineTo(x, y);
        } else {
          final px  = padL + ((i - 1) / (data.length - 1)) * chartW;
          final py  = padT + chartH - ((data[i - 1] - minV) / (maxV - minV)) * chartH;
          final cx1 = px + (x - px) * 0.4;
          final cx2 = x  - (x - px) * 0.4;
          path.cubicTo(cx1, py, cx2, y, x, y);
          fillPath.cubicTo(cx1, py, cx2, y, x, y);
        }
      }

      fillPath.lineTo(padL + chartW, padT + chartH);
      fillPath.close();
      canvas.drawPath(fillPath, Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [color.withOpacity(0.15), Colors.transparent],
        ).createShader(Rect.fromLTWH(0, padT, size.width, chartH))
        ..style = PaintingStyle.fill);

      canvas.drawPath(path, Paint()
        ..color       = color
        ..strokeWidth = 2
        ..style       = PaintingStyle.stroke
        ..strokeCap   = StrokeCap.round
        ..strokeJoin  = StrokeJoin.round);

      final lastX = padL + chartW;
      final lastY = padT + chartH - ((data.last - minV) / (maxV - minV)) * chartH;
      canvas.drawCircle(Offset(lastX, lastY), 4,
          Paint()..color = color..style = PaintingStyle.fill);
    }

    for (int i = 0; i < seriesLabels.length; i++) {
      final lx = padL + i * 150.0;
      canvas.drawLine(Offset(lx, 18), Offset(lx + 30, 18),
          Paint()..color = colors[i]..strokeWidth = 2);
      final tp = TextPainter(
          text: TextSpan(
              text: seriesLabels[i],
              style: TextStyle(color: kTextMuted, fontSize: 10)),
          textDirection: TextDirection.ltr)..layout();
      tp.paint(canvas, Offset(lx + 34, 12));
    }
  }

  @override
  bool shouldRepaint(_) => false;
}