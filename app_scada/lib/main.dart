// ============================================================
//  HITECH INGENIUM  ·  SCADA MASTER  ·  main.dart
//  VERSIÓN CORREGIDA: Layout responsivo para móvil, tablet y desktop
// ============================================================
import 'dart:async';
import 'package:flutter/material.dart';

// Importaciones limpias
import 'scada_neumatico.dart';
import 'main_prensado.dart';
import 'main_robot_3_ejes.dart'; // Quitamos el "hide", lo necesitábamos
import 'main_maquinados.dart';

// ... (resto del código de paleta y colores)
void main() => runApp(const MyApp());

// ── Paleta ────────────────────────────────────────────────────────────────────
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

// ── Breakpoints ───────────────────────────────────────────────────────────────
// > 900  → desktop:  sidebar fija + top bar 1 fila completa
// > 600  → tablet:   sidebar fija compacta + top bar 2 filas
// ≤ 600  → móvil:    drawer + top bar compacto
enum _Layout { mobile, tablet, desktop }
_Layout _getLayout(double w) {
  if (w > 900) return _Layout.desktop;
  if (w > 600) return _Layout.tablet;
  return _Layout.mobile;
}

// ── App ───────────────────────────────────────────────────────────────────────
class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'SCADA 4.0 · Hitech INGENIUM',
        theme: ThemeData.dark().copyWith(scaffoldBackgroundColor: kBgDark),
        home: const ScadaMasterHome(),
      );
}

// ── Modelos ───────────────────────────────────────────────────────────────────
enum LogType { info, audit, error }
enum AppView  { dashboard, neumatico, robot, maquinado, prensado }

class LogEntry {
  final String time, message;
  final LogType type;
  LogEntry(this.time, this.message, this.type);
  Color get color => type == LogType.error ? kRed
      : type == LogType.audit ? kCyan : kTextMain;
}

class SensorState {
  final String id, label;
  bool active;
  SensorState(this.id, this.label, {this.active = false});
}

class ActuatorState {
  final String id, label;
  bool on, disabled;
  ActuatorState(this.id, this.label, {this.on = false, this.disabled = false});
}

// ── Chat ──────────────────────────────────────────────────────────────────────
class _ChatMsg {
  final String text;
  final bool isUser;
  const _ChatMsg(this.text, this.isUser);
}

// ── Home ──────────────────────────────────────────────────────────────────────
class ScadaMasterHome extends StatefulWidget {
  const ScadaMasterHome({super.key});
  @override State<ScadaMasterHome> createState() => _ScadaMasterHomeState();
}

class _ScadaMasterHomeState extends State<ScadaMasterHome> {
  AppView _view = AppView.dashboard;
  String _role  = 'Ingeniero';
  String _mode  = 'manual';
  String _clock = '';
  bool _chatOpen    = false;
  bool _chatLoading = false;
  late Timer _clockTimer;

  int _piezasN = 0, _piezasM = 0;

  final Map<AppView, bool> _running = {
    AppView.neumatico: false, AppView.robot: false,
    AppView.maquinado: false, AppView.prensado: false,
  };

  final Map<AppView, List<SensorState>> _sensors = {
    AppView.neumatico: [
      SensorState('p1','P1: Input Storage (Pieza)'),
      SensorState('p2','P2: Conveyor Final (Llegada)'),
      SensorState('s1','S1: Punching Machine Pos.'),
    ],
    AppView.robot: [
      SensorState('s_base','LS1: Límite Base Centro',  active: true),
      SensorState('s_z',   'LS2: Límite Eje Z (Arriba)',active: true),
      SensorState('s_arm', 'LS3: Límite Brazo Retraído',active: true),
    ],
    AppView.maquinado: [
      SensorState('p1','P1: Entrada a Línea'),
      SensorState('p3','P3: Pieza en Fresadora'),
      SensorState('p5','P5: Pieza Terminada (Salida)'),
    ],
    AppView.prensado: [
      SensorState('shome', 'S_HOME: Prensa Arriba', active: true),
      SensorState('swork', 'S_WORK: Prensa Abajo'),
      SensorState('spiece','Barrera: Pieza Detectada'),
    ],
  };

  final Map<AppView, List<ActuatorState>> _actuators = {
    AppView.neumatico: [
      ActuatorState('m1','M1: Compresor Neumático'),
      ActuatorState('m3','M3: Banda Transportadora'),
      ActuatorState('m2','M2: Mesa Giratoria'),
      ActuatorState('v1','V1: Pistón Entrada'),
      ActuatorState('v3','V3: Perforadora (Bajar)'),
    ],
    AppView.robot: [
      ActuatorState('m1','M1: Base Rotatoria (CW)'),
      ActuatorState('m3','M3: Eje Vertical (Bajar)'),
      ActuatorState('m2','M2: Brazo (Expandir)'),
      ActuatorState('m4','M4: Gripper (Cerrar)'),
    ],
    AppView.maquinado: [
      ActuatorState('m1','M1: Banda Entrada Fwd'),
      ActuatorState('m2','M2: Motor Fresadora'),
      ActuatorState('m4','M4: Motor Taladro'),
      ActuatorState('m8','M8: Banda Salida Fwd'),
    ],
    AppView.prensado: [
      ActuatorState('rly01','RLY01: Prensa a Home'),
      ActuatorState('rly02','RLY02: Prensa a Trabajo'),
      ActuatorState('rly03','RLY03: Banda Adelante'),
    ],
  };

  final Map<AppView, List<LogEntry>>       _logs      = { AppView.neumatico: [], AppView.robot: [], AppView.maquinado: [], AppView.prensado: [] };
  final Map<AppView, ScrollController>     _logScrolls = { AppView.neumatico: ScrollController(), AppView.robot: ScrollController(), AppView.maquinado: ScrollController(), AppView.prensado: ScrollController() };
  final List<_ChatMsg>                     _chatMsgs  = [ const _ChatMsg('¡Hola! Soy el asistente de Hitech INGENIUM. ¿Qué necesitas?', false) ];
  final TextEditingController              _chatCtrl  = TextEditingController();
  final ScrollController                   _chatSc    = ScrollController();

  final List<double> _cN = [120,150,140,160,170,165,180];
  final List<double> _cM = [90,110,105,120,130,125,140];
  final List<String> _cL = ['08:00','09:00','10:00','11:00','12:00','13:00','14:00'];

  SensorState   _sen(AppView v, String id) => _sensors[v]!.firstWhere((s) => s.id == id);
  ActuatorState _act(AppView v, String id) => _actuators[v]!.firstWhere((a) => a.id == id);
  bool get _autoEnabled => _mode == 'auto';

  String _now() { final n = DateTime.now(); return '${n.hour.toString().padLeft(2,'0')}:${n.minute.toString().padLeft(2,'0')}:${n.second.toString().padLeft(2,'0')}'; }
  void _logEntry(AppView v, String msg, LogType t) {
    setState(() => _logs[v]!.add(LogEntry(_now(), msg, t)));
    WidgetsBinding.instance.addPostFrameCallback((_) { final sc = _logScrolls[v]!; if (sc.hasClients) sc.animateTo(sc.position.maxScrollExtent, duration: const Duration(milliseconds: 200), curve: Curves.easeOut); });
  }
  void _updPerms() { for (final v in AppView.values) { if (v == AppView.dashboard) continue; for (final a in _actuators[v]!) a.disabled = (_role == 'Operador' || _mode == 'auto' || _running[v]!); } }
  void _togSen(AppView v, String id) { if (_mode != 'manual') { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Cambia a Modo Manual para simular."), backgroundColor: kOrange)); return; } final s = _sen(v, id); setState(() => s.active = !s.active); _logEntry(v, 'Sensor $id → ${s.active ? 'ON' : 'OFF'}', LogType.audit); }
  void _togAct(AppView v, String id, bool val) { setState(() => _act(v, id).on = val); if (!_running[v]!) _logEntry(v, 'Actuador $id → ${val ? 'ON' : 'OFF'}', LogType.audit); }

  @override
  void initState() {
    super.initState();
    _updateClock();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) => setState(_updateClock));
  }
  void _updateClock() { final n = DateTime.now(); _clock = '${n.hour.toString().padLeft(2,'0')}:${n.minute.toString().padLeft(2,'0')}:${n.second.toString().padLeft(2,'0')}'; }
  @override void dispose() { _clockTimer.cancel(); for (final sc in _logScrolls.values) sc.dispose(); _chatCtrl.dispose(); _chatSc.dispose(); super.dispose(); }

  Future<void> _startCycle(AppView v) async {
    if (_running[v]!) return;
    setState(() { _running[v] = true; _updPerms(); });
    _logEntry(v, '--- INICIANDO SECUENCIA AUTOMÁTICA ---', LogType.info);
    try {
      if (v == AppView.neumatico) { _togAct(v,'v1',true); await Future.delayed(const Duration(seconds:1)); _togAct(v,'v1',false); _togAct(v,'m2',true); await Future.delayed(const Duration(milliseconds:1500)); _togAct(v,'m2',false); _togAct(v,'v3',true); await Future.delayed(const Duration(seconds:1)); _togAct(v,'v3',false); _togAct(v,'m3',true); await Future.delayed(const Duration(milliseconds:1500)); _togAct(v,'m3',false); setState(()=>_piezasN++); }
      else if (v == AppView.robot) { _togAct(v,'m1',true); await Future.delayed(const Duration(milliseconds:1500)); _togAct(v,'m1',false); _togAct(v,'m3',true); await Future.delayed(const Duration(seconds:1)); _togAct(v,'m4',true); await Future.delayed(const Duration(milliseconds:800)); _togAct(v,'m3',false); await Future.delayed(const Duration(seconds:1)); _togAct(v,'m4',false); }
      else if (v == AppView.maquinado) { _togAct(v,'m1',true); await Future.delayed(const Duration(seconds:1)); _togAct(v,'m1',false); _togAct(v,'m2',true); await Future.delayed(const Duration(seconds:2)); _togAct(v,'m2',false); _togAct(v,'m8',true); await Future.delayed(const Duration(seconds:1)); _togAct(v,'m8',false); setState(()=>_piezasM++); }
      else if (v == AppView.prensado) { _togAct(v,'rly03',true); await Future.delayed(const Duration(milliseconds:1500)); _togAct(v,'rly03',false); _togAct(v,'rly02',true); await Future.delayed(const Duration(seconds:1)); _togAct(v,'rly02',false); _togAct(v,'rly01',true); await Future.delayed(const Duration(seconds:1)); _togAct(v,'rly01',false); }
      _logEntry(v, '--- CICLO COMPLETADO ---', LogType.audit);
    } catch (e) { _logEntry(v, 'Error: $e', LogType.error); }
    setState(() { _running[v] = false; _updPerms(); });
  }

  Future<void> _sendChat() async {
    final txt = _chatCtrl.text.trim(); if (txt.isEmpty) return;
    setState(() { _chatMsgs.add(_ChatMsg(txt, true)); _chatLoading = true; _chatCtrl.clear(); });
    _scrollChat();
    await Future.delayed(const Duration(milliseconds: 900));
    final r = _botReply(txt);
    setState(() { _chatLoading = false; _chatMsgs.add(_ChatMsg(r, false)); });
    _scrollChat();
  }

  String _botReply(String q) {
    final ql = q.toLowerCase();
    if (ql.contains('oee')) return 'OEE actual de la planta: 87.5%\nTodas las estaciones operando dentro de parámetros.';
    if (ql.contains('pieza') || ql.contains('producción')) return 'Producción total: 1,240 piezas\n• Neumático: $_piezasN\n• Maquinados: $_piezasM';
    if (ql.contains('modo')) return 'Modo activo: $_mode\nRol: $_role';
    if (ql.contains('alarma') || ql.contains('alerta')) return '✅ Sin alarmas activas. Sistema nominal.';
    if (ql.contains('robot')) return 'Robot 3 Ejes (TM3DR24-A)\n• 8 estados de ciclo Pick & Place\n• 6 sensores encoder + 8 relés';
    if (ql.contains('neumatico') || ql.contains('neumático')) return 'Centro Neumático (TMPPC24-A)\n• Compresor + 5 válvulas solenoides\n• 4 estados de ciclo automático';
    if (ql.contains('maquinado')) return 'Centro Maquinados (TMINL24-A)\n• Fresadora + Taladradora\n• 7 estados · 8 motores M1-M8';
    if (ql.contains('prensado') || ql.contains('prensa')) return 'Centro Prensado (TMPUM24-A)\n• Motor prensa bidireccional\n• 4 estados · RLY01-RLY04';
    return 'Puedo darte datos de:\n• OEE y producción\n• Estado de estaciones\n• Alarmas activas\n\n¿Qué necesitas?';
  }

  void _scrollChat() => WidgetsBinding.instance.addPostFrameCallback((_) { if (_chatSc.hasClients) _chatSc.animateTo(_chatSc.position.maxScrollExtent, duration: const Duration(milliseconds: 200), curve: Curves.easeOut); });

  String _viewTitle(AppView v) {
    switch (v) {
      case AppView.dashboard:  return 'Dashboard General de Planta';
      case AppView.neumatico:  return 'Estación 1: Centro Neumático';
      case AppView.robot:      return 'Estación 2: Robot 3 Ejes';
      case AppView.maquinado:  return 'Estación 3: Centro Maquinados';
      case AppView.prensado:   return 'Estación 4: Centro Prensado';
    }
  }

  // ── BUILD ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final w      = MediaQuery.of(context).size.width;
    final layout = _getLayout(w);
    final showSidebar = layout != _Layout.mobile;

    return Scaffold(
      backgroundColor: kBgDark,
      // Drawer solo en móvil
      drawer: showSidebar ? null : Drawer(
        backgroundColor: kSidebar,
        child: SafeArea(child: _sidebarContent(layout)),
      ),
      body: SafeArea(
        child: Stack(children: [
          Row(children: [
            if (showSidebar)
              Container(
                // Tablet: sidebar más angosta
                width: layout == _Layout.tablet ? 200 : 248,
                decoration: const BoxDecoration(
                  color: kSidebar,
                  border: Border(right: BorderSide(color: kBorder)),
                ),
                child: _sidebarContent(layout),
              ),
            Expanded(
              child: Column(children: [
                _topBar(layout),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: KeyedSubtree(
                      key: ValueKey(_view),
                      child: _buildView(),
                    ),
                  ),
                ),
              ]),
            ),
          ]),
          // Chatbot FAB
          _chatbot(layout),
        ]),
      ),
    );
  }

  // ── Sidebar ────────────────────────────────────────────────────────────────
  Widget _sidebarContent(_Layout layout) {
    final compact = layout == _Layout.tablet;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      // Brand
      Container(
        padding: EdgeInsets.symmetric(vertical: compact ? 16 : 22),
        child: Column(children: [
          Text('HITECH INGENIUM',
              textAlign: TextAlign.center,
              style: TextStyle(color: kCyan, fontSize: compact ? 13 : 17, fontWeight: FontWeight.bold, letterSpacing: 1)),
          const SizedBox(height: 3),
          Text('SCADA MASTER',
              textAlign: TextAlign.center,
              style: TextStyle(color: kTextMuted, fontSize: compact ? 9 : 11, letterSpacing: 2)),
        ]),
      ),
      const Divider(color: kBorder, height: 1),
      const SizedBox(height: 4),
      _navTile('📊', 'Dashboard General', AppView.dashboard, kCyan,   compact),
      _navTile('⚙️', 'Centro Neumático',  AppView.neumatico, kCyan,   compact),
      _navTile('🤖', 'Robot 3 Ejes',       AppView.robot,     kPurple, compact),
      _navTile('🛠️', 'Centro Maquinados',  AppView.maquinado, kGreen,  compact),
      _navTile('🛑', 'Centro de Prensado', AppView.prensado,  kRed,    compact),
    ]);
  }

  Widget _navTile(String em, String lbl, AppView v, Color col, bool compact) {
    final active = _view == v;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: active ? col.withOpacity(0.12) : Colors.transparent,
        border: Border(left: BorderSide(color: active ? col : Colors.transparent, width: 3)),
      ),
      child: InkWell(
        onTap: () {
          setState(() => _view = v);
          if (MediaQuery.of(context).size.width <= 600) Navigator.pop(context);
        },
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 20, vertical: compact ? 11 : 14),
          child: Row(children: [
            Text(em, style: TextStyle(fontSize: compact ? 14 : 16)),
            const SizedBox(width: 8),
            Flexible(child: Text(lbl,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: active ? col : kTextMuted,
                    fontWeight: active ? FontWeight.bold : FontWeight.normal,
                    fontSize: compact ? 11 : 13))),
          ]),
        ),
      ),
    );
  }

  // ── Top Bar (responsivo) ───────────────────────────────────────────────────
  Widget _topBar(_Layout layout) {
    if (layout == _Layout.desktop) return _topBarDesktop();
    if (layout == _Layout.tablet)  return _topBarTablet();
    return _topBarMobile();
  }

  // Desktop: 1 fila completa
  Widget _topBarDesktop() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: const BoxDecoration(color: kPanelBg, border: Border(bottom: BorderSide(color: kBorder))),
        child: Row(children: [
          Expanded(
            child: Text(_viewTitle(_view),
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: kCyan, fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          Text(_clock, style: const TextStyle(color: kCyan, fontSize: 13, fontFamily: 'monospace')),
          const SizedBox(width: 16),
          const Text('Rol:', style: TextStyle(color: kTextMuted, fontSize: 11)),
          const SizedBox(width: 4),
          _sel(_role, {'Ingeniero':'Ingeniero (Control Total)','Operador':'Operador'}, (v){setState((){_role=v!;_updPerms();});},110),
          const SizedBox(width: 12),
          const Text('Modo de Planta:', style: TextStyle(color: kTextMuted, fontSize: 11)),
          const SizedBox(width: 4),
          _sel(_mode, {'manual':'Manual (Forzar/Simular)','auto':'Automático'}, (v){setState((){_mode=v!;_updPerms();});},130),
        ]),
      );

  // Tablet: 2 filas
  Widget _topBarTablet() => Container(
        decoration: const BoxDecoration(color: kPanelBg, border: Border(bottom: BorderSide(color: kBorder))),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Fila 1: título + reloj
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Row(children: [
              Expanded(child: Text(_viewTitle(_view),
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: kCyan, fontSize: 14, fontWeight: FontWeight.bold))),
              Text(_clock, style: const TextStyle(color: kCyan, fontSize: 12, fontFamily: 'monospace')),
            ]),
          ),
          // Fila 2: controles
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Row(children: [
              const Text('Rol:', style: TextStyle(color: kTextMuted, fontSize: 10)),
              const SizedBox(width: 4),
              _sel(_role, {'Ingeniero':'Ingeniero (Control Total)','Operador':'Operador'}, (v){setState((){_role=v!;_updPerms();});},130),
              const SizedBox(width: 10),
              const Text('Modo:', style: TextStyle(color: kTextMuted, fontSize: 10)),
              const SizedBox(width: 4),
              _sel(_mode, {'manual':'Manual (Forzar/Simular)','auto':'Automático'}, (v){setState((){_mode=v!;_updPerms();});},120),
            ]),
          ),
        ]),
      );

  // Móvil: hamburger + título compacto + reloj icono
  Widget _topBarMobile() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        decoration: const BoxDecoration(color: kPanelBg, border: Border(bottom: BorderSide(color: kBorder))),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Fila 1: hamburger + título + reloj
          Row(children: [
            Builder(builder: (ctx) => IconButton(
              icon: const Icon(Icons.menu, color: kCyan, size: 22),
              onPressed: () => Scaffold.of(ctx).openDrawer(),
              padding: const EdgeInsets.all(6),
            )),
            Expanded(child: Text(_viewTitle(_view),
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: kCyan, fontSize: 13, fontWeight: FontWeight.bold))),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(_clock, style: const TextStyle(color: kCyan, fontSize: 11, fontFamily: 'monospace')),
            ),
          ]),
          // Fila 2: controles compactos
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
            child: Row(children: [
              const Text('Rol:', style: TextStyle(color: kTextMuted, fontSize: 9)),
              const SizedBox(width: 3),
              Flexible(child: _sel(_role, {'Ingeniero':'Ingeniero','Operador':'Operador'}, (v){setState((){_role=v!;_updPerms();});},100)),
              const SizedBox(width: 8),
              const Text('Modo:', style: TextStyle(color: kTextMuted, fontSize: 9)),
              const SizedBox(width: 3),
              Flexible(child: _sel(_mode, {'manual':'Manual','auto':'Automático'}, (v){setState((){_mode=v!;_updPerms();});},100)),
            ]),
          ),
        ]),
      );

  Widget _sel(String val, Map<String,String> items, ValueChanged<String?> fn, double w) =>
      Container(
        width: w,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(color: kBgDark, border: Border.all(color: kCyan), borderRadius: BorderRadius.circular(4)),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: val, dropdownColor: kPanelBg,
            style: const TextStyle(color: kCyan, fontSize: 11),
            icon: const Icon(Icons.arrow_drop_down, color: kCyan, size: 15),
            isDense: true, isExpanded: true,
            items: items.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value, overflow: TextOverflow.ellipsis))).toList(),
            onChanged: fn,
          ),
        ),
      );

  // ── Vista actual ───────────────────────────────────────────────────────────
  Widget _buildView() {
    switch (_view) {
      case AppView.dashboard:  return _dashboard();
      case AppView.neumatico:  return ScadaNeumaticoBoard();
      case AppView.robot:      return ScadaRobot3EjesScreen();
      case AppView.maquinado:  return ScadaMaquinadosScreen();
      case AppView.prensado:   return ScadaPrensadoScreen();
    }
  }

  // ── Dashboard ──────────────────────────────────────────────────────────────
  Widget _dashboard() => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          // KPI cards
          LayoutBuilder(builder: (_, box) {
            final cols = box.maxWidth > 600 ? 4 : 2;
            final w    = (box.maxWidth - 12.0 * (cols - 1)) / cols;
            return Wrap(spacing: 12, runSpacing: 12, children: [
              _kpi('OEE Planta',       '87.5%',       kGreen, w),
              _kpi('Producción Total', '1,240',        kCyan,  w),
              _kpi('Piezas Neumático', '$_piezasN',   kGreen, w),
              _kpi('Piezas Maquinado', '$_piezasM',   kGreen, w),
            ]);
          }),
          const SizedBox(height: 18),
          // Gráfica
          Container(
            height: 300,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: kPanelBg, border: Border.all(color: kBorder), borderRadius: BorderRadius.circular(8)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Rendimiento de Línea (Tiempo Real)',
                  style: TextStyle(color: kCyan, fontSize: 13, fontWeight: FontWeight.bold)),
              const Divider(color: kBorder),
              Expanded(child: CustomPaint(painter: _ChartPainter(
                datasets: [_cN, _cM], labels: _cL,
                colors: [kCyan, kGreen], names: ['Centro Neumático','Centro Maquinados'],
              ))),
            ]),
          ),
          const SizedBox(height: 18),
          // Acceso rápido a estaciones
          const Text('ACCESO RÁPIDO · ESTACIONES',
              style: TextStyle(color: kTextMuted, fontSize: 10, letterSpacing: 1.5)),
          const SizedBox(height: 10),
          LayoutBuilder(builder: (_, box) {
            final cols = box.maxWidth > 600 ? 4 : 2;
            final w    = (box.maxWidth - 10.0 * (cols - 1)) / cols;
            return Wrap(spacing: 10, runSpacing: 10, children: [
              _stCard('⚙️','Centro Neumático', 'TMPPC24-A', kCyan,   AppView.neumatico,  w),
              _stCard('🤖','Robot 3 Ejes',      'TM3DR24-A', kPurple, AppView.robot,      w),
              _stCard('🛠️','Centro Maquinados', 'TMINL24-A', kGreen,  AppView.maquinado,  w),
              _stCard('🛑','Centro Prensado',   'TMPUM24-A', kRed,    AppView.prensado,   w),
            ]);
          }),
          const SizedBox(height: 8),
        ]),
      );

  Widget _kpi(String title, String val, Color col, double w) => SizedBox(
        width: w,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: kPanelBg, border: Border.all(color: kBorder), borderRadius: BorderRadius.circular(8)),
          child: Column(children: [
            Text(title, textAlign: TextAlign.center, style: const TextStyle(color: kTextMuted, fontSize: 11, letterSpacing: 0.6)),
            const SizedBox(height: 8),
            Text(val, style: TextStyle(color: col, fontSize: 26, fontWeight: FontWeight.bold)),
          ]),
        ),
      );

  Widget _stCard(String em, String name, String art, Color col, AppView v, double w) =>
      SizedBox(
        width: w,
        child: GestureDetector(
          onTap: () => setState(() => _view = v),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: kPanelBg, border: Border.all(color: col.withOpacity(0.45)), borderRadius: BorderRadius.circular(8)),
            child: Row(children: [
              Container(width: 34, height: 34,
                  decoration: BoxDecoration(color: col.withOpacity(0.12), borderRadius: BorderRadius.circular(7)),
                  child: Center(child: Text(em, style: const TextStyle(fontSize: 16)))),
              const SizedBox(width: 8),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(name, overflow: TextOverflow.ellipsis, style: TextStyle(color: col, fontSize: 11, fontWeight: FontWeight.bold)),
                Text(art,  style: const TextStyle(color: kTextMuted, fontSize: 9)),
              ])),
              Icon(Icons.arrow_forward_ios, color: col, size: 11),
            ]),
          ),
        ),
      );

  // ── Chatbot ────────────────────────────────────────────────────────────────
  Widget _chatbot(_Layout layout) {
    final fabBottom = layout == _Layout.mobile ? 12.0 : 18.0;
    final fabRight  = layout == _Layout.mobile ? 10.0 : 16.0;
    final chatW     = layout == _Layout.mobile ? MediaQuery.of(context).size.width * 0.88 : 310.0;

    return Positioned(
      bottom: fabBottom, right: fabRight,
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.end, children: [
        if (_chatOpen)
          Container(
            width: chatW, height: 400,
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: kPanelBg, border: Border.all(color: kBorder),
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 16, offset: Offset(0,6))],
            ),
            child: Column(children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: const BoxDecoration(color: kCyan, borderRadius: BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12))),
                child: Row(children: [
                  const Text('Hitech Bot 🤖', style: TextStyle(color: kBgDark, fontWeight: FontWeight.bold, fontSize: 13)),
                  const Spacer(),
                  GestureDetector(onTap: ()=>setState(()=>_chatOpen=false), child: const Icon(Icons.close, color: kBgDark, size: 16)),
                ]),
              ),
              // Mensajes
              Expanded(child: Container(
                color: kSidebar,
                child: ListView.builder(
                  controller: _chatSc,
                  padding: const EdgeInsets.all(10),
                  itemCount: _chatMsgs.length + (_chatLoading ? 1 : 0),
                  itemBuilder: (_, i) {
                    if (_chatLoading && i == _chatMsgs.length) return _bubble('', false, typing: true);
                    final m = _chatMsgs[i];
                    return _bubble(m.text, m.isUser);
                  },
                ),
              )),
              // Input
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(color: kPanelBg, border: Border(top: BorderSide(color: kBorder))),
                child: Row(children: [
                  Expanded(child: TextField(
                    controller: _chatCtrl,
                    style: const TextStyle(color: kTextMain, fontSize: 12),
                    decoration: InputDecoration(
                      hintText: 'Pregunta algo...', hintStyle: const TextStyle(color: kTextMuted, fontSize: 11),
                      filled: true, fillColor: kBgDark,
                      isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: kBorder)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: kBorder)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: kCyan)),
                    ),
                    onSubmitted: (_) => _sendChat(),
                  )),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: _sendChat,
                    child: Container(padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: kCyan, borderRadius: BorderRadius.circular(6)),
                        child: const Icon(Icons.send, color: kBgDark, size: 14)),
                  ),
                ]),
              ),
            ]),
          ),
        // FAB
        ElevatedButton.icon(
          onPressed: () => setState(() => _chatOpen = !_chatOpen),
          icon: const Text('💬', style: TextStyle(fontSize: 14)),
          label: const Text('Asistente IA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          style: ElevatedButton.styleFrom(
            backgroundColor: kCyan, foregroundColor: kBgDark,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            elevation: 6,
          ),
        ),
      ]),
    );
  }

  Widget _bubble(String txt, bool isUser, {bool typing = false}) => Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 230),
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: isUser ? kCyan : kPanelBg,
            border: isUser ? null : Border.all(color: kBorder),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(8), topRight: const Radius.circular(8),
              bottomLeft: Radius.circular(isUser ? 8 : 0),
              bottomRight: Radius.circular(isUser ? 0 : 8),
            ),
          ),
          child: typing
              ? const _TypingDot()
              : Text(txt, style: TextStyle(color: isUser ? kBgDark : kTextMain, fontSize: 12, height: 1.4)),
        ),
      );
}

// ── Typing dot ─────────────────────────────────────────────────────────────────
class _TypingDot extends StatefulWidget {
  const _TypingDot();
  @override State<_TypingDot> createState() => _TypingDotState();
}
class _TypingDotState extends State<_TypingDot> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  @override void initState() { super.initState(); _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..repeat(reverse: true); }
  @override void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: CurvedAnimation(parent: _c, curve: Curves.easeInOut),
        child: const Text('Consultando SCADA...', style: TextStyle(color: kTextMuted, fontSize: 11, fontStyle: FontStyle.italic)),
      );
}

// ── Gráfica de líneas ──────────────────────────────────────────────────────────
class _ChartPainter extends CustomPainter {
  final List<List<double>> datasets;
  final List<String> labels;
  final List<Color> colors;
  final List<String> names;
  const _ChartPainter({required this.datasets, required this.labels, required this.colors, required this.names});

  @override
  void paint(Canvas canvas, Size size) {
    const pL = 42.0, pR = 16.0, pT = 36.0, pB = 26.0;
    final cW = size.width - pL - pR, cH = size.height - pT - pB;
    double mn = double.infinity, mx = double.negativeInfinity;
    for (final d in datasets) { for (final v in d) { if (v < mn) mn = v; if (v > mx) mx = v; } }
    mn -= 14; mx += 14;
    final gp = Paint()..color = kBorder..strokeWidth = 0.5;
    const ts = TextStyle(color: kTextMuted, fontSize: 9);
    for (int i = 0; i <= 5; i++) {
      final y = pT + cH * (1 - i / 5);
      canvas.drawLine(Offset(pL, y), Offset(pL + cW, y), gp);
      final tp = TextPainter(text: TextSpan(text: '${(mn + (mx - mn) * i / 5).toInt()}', style: ts), textDirection: TextDirection.ltr)..layout();
      tp.paint(canvas, Offset(pL - tp.width - 4, y - 6));
    }
    for (int i = 0; i < labels.length; i++) {
      final x = pL + (i / (labels.length - 1)) * cW;
      canvas.drawLine(Offset(x, pT), Offset(x, pT + cH), gp);
      final tp = TextPainter(text: TextSpan(text: labels[i], style: ts), textDirection: TextDirection.ltr)..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, pT + cH + 4));
    }
    for (int s = 0; s < datasets.length; s++) {
      final data = datasets[s]; final col = colors[s];
      final path = Path(); final fill = Path();
      for (int i = 0; i < data.length; i++) {
        final x = pL + (i / (data.length - 1)) * cW;
        final y = pT + cH - ((data[i] - mn) / (mx - mn)) * cH;
        if (i == 0) { path.moveTo(x, y); fill.moveTo(x, pT + cH); fill.lineTo(x, y); }
        else {
          final px = pL + ((i - 1) / (data.length - 1)) * cW;
          final py = pT + cH - ((data[i - 1] - mn) / (mx - mn)) * cH;
          path.cubicTo(px + (x - px) * 0.4, py, x - (x - px) * 0.4, y, x, y);
          fill.cubicTo(px + (x - px) * 0.4, py, x - (x - px) * 0.4, y, x, y);
        }
      }
      fill.lineTo(pL + cW, pT + cH); fill.close();
      canvas.drawPath(fill, Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [col.withOpacity(0.17), Colors.transparent]).createShader(Rect.fromLTWH(0, pT, size.width, cH))..style = PaintingStyle.fill);
      canvas.drawPath(path, Paint()..color = col..strokeWidth = 2.2..style = PaintingStyle.stroke..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round);
      canvas.drawCircle(Offset(pL + cW, pT + cH - ((data.last - mn) / (mx - mn)) * cH), 4, Paint()..color = col);
      // Leyenda
      final lx = pL + s * 155.0;
      canvas.drawLine(Offset(lx, 20), Offset(lx + 26, 20), Paint()..color = col..strokeWidth = 2.2);
      canvas.drawCircle(Offset(lx + 13, 20), 3, Paint()..color = col);
      final tp = TextPainter(text: TextSpan(text: names[s], style: const TextStyle(color: kTextMuted, fontSize: 10)), textDirection: TextDirection.ltr)..layout();
      tp.paint(canvas, Offset(lx + 30, 14));
    }
  }

  @override bool shouldRepaint(_) => false;
}