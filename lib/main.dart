
// ============================================================
//  HITECH INGENIUM  ·  SCADA MASTER  ·  main.dart
//  Layout responsivo + nuevas secciones del menú lateral
// ============================================================
import 'dart:async';
import 'package:flutter/material.dart';

// ── Importaciones de los módulos del sistema ──────────────────────────────────
import 'nube.dart' show CloudSyncDashboard;
import 'analitycs.dart' show AnalyticsDashboard;
import 'usuarios.dart' show UsuariosScreen;
import 'historialylogs.dart' show LogsScreen;
import 'conexiones_tablas.dart' show ConexionesScreen;
import 'diagnostico_conexiones.dart' show DiagnosticoScreen;
import 'scada_neumatico.dart' show ScadaNeumaticoBoard;
import 'main_robot_3_ejes.dart' show ScadaRobotDashboard;
import 'main_maquinados.dart' show ScadaMaquinadosDashboard;
import 'main_prensado.dart' show ScadaPrensadoScreen;




void main() => runApp(const MyApp());

// ── Paleta ────────────────────────────────────────────────────────────────────
const Color kBgDark = Color(0xFF0F172A);
const Color kPanelBg = Color(0xFF1E293B);
const Color kSidebar = Color(0xFF0B1120);
const Color kCyan = Color(0xFF38BDF8);
const Color kGreen = Color(0xFF10B981);
const Color kRed = Color(0xFFF43F5E);
const Color kPurple = Color(0xFFA855F7);
const Color kOrange = Color(0xFFF59E0B);
const Color kTeal = Color(0xFF14B8A6);
const Color kIndigo = Color(0xFF6366F1);
const Color kPink = Color(0xFFEC4899);
const Color kTextMain = Color(0xFFF8FAFC);
const Color kTextMuted = Color(0xFF94A3B8);
const Color kBorder = Color(0xFF334155);

// ── Breakpoints ───────────────────────────────────────────────────────────────
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

// AppView incluye estaciones SCADA + nuevas secciones del sistema
enum AppView {
  // ── Estaciones SCADA ──
  dashboard,
  neumatico,
  robot,
  maquinado,
  prensado,
  // ── Herramientas del sistema ──
  conexiones,
  diagnostico_conexiones,
  historial,
  usuarios,
  nube,
  chatbot,
}

class LogEntry {
  final String time, message;
  final LogType type;
  LogEntry(this.time, this.message, this.type);
  Color get color => type == LogType.error
      ? kRed
      : type == LogType.audit
          ? kCyan
          : kTextMain;
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
  @override
  State<ScadaMasterHome> createState() => _ScadaMasterHomeState();
}

class _ScadaMasterHomeState extends State<ScadaMasterHome> {
  AppView _view = AppView.dashboard;
  String _role = 'Ingeniero';
  String _mode = 'manual';
  String _clock = '';
  bool _chatLoading = false;
  late Timer _clockTimer;

  int _piezasN = 0, _piezasM = 0;

  final List<_ChatMsg> _chatMsgs = [
    const _ChatMsg(
        '¡Hola! Soy el asistente de Hitech INGENIUM. ¿Qué necesitas?', false),
  ];
  final TextEditingController _chatCtrl = TextEditingController();
  final ScrollController _chatSc = ScrollController();

  final List<double> _cN = [120, 150, 140, 160, 170, 165, 180];
  final List<double> _cM = [90, 110, 105, 120, 130, 125, 140];
  final List<String> _cL = [
    '08:00',
    '09:00',
    '10:00',
    '11:00',
    '12:00',
    '13:00',
    '14:00'
  ];

  @override
  void initState() {
    super.initState();
    _updateClock();
    _clockTimer = Timer.periodic(
        const Duration(seconds: 1), (_) => setState(_updateClock));
  }

  void _updateClock() {
    final n = DateTime.now();
    _clock =
        '${n.hour.toString().padLeft(2, '0')}:${n.minute.toString().padLeft(2, '0')}:${n.second.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    _chatCtrl.dispose();
    _chatSc.dispose();
    super.dispose();
  }

  // ── Chat ────────────────────────────────────────────────────────────────────
  Future<void> _sendChat() async {
    final txt = _chatCtrl.text.trim();
    if (txt.isEmpty) return;
    setState(() {
      _chatMsgs.add(_ChatMsg(txt, true));
      _chatLoading = true;
      _chatCtrl.clear();
    });
    _scrollChat();
    await Future.delayed(const Duration(milliseconds: 900));
    final r = _botReply(txt);
    setState(() {
      _chatLoading = false;
      _chatMsgs.add(_ChatMsg(r, false));
    });
    _scrollChat();
  }

  String _botReply(String q) {
    final ql = q.toLowerCase();
    if (ql.contains('oee'))
      return 'OEE actual de la planta: 87.5%\nTodas las estaciones operando dentro de parámetros.';
    if (ql.contains('pieza') || ql.contains('producción'))
      return 'Producción total: 1,240 piezas\n• Neumático: $_piezasN\n• Maquinados: $_piezasM';
    if (ql.contains('modo')) return 'Modo activo: $_mode\nRol: $_role';
    if (ql.contains('alarma') || ql.contains('alerta'))
      return '✅ Sin alarmas activas. Sistema nominal.';
    if (ql.contains('robot'))
      return 'Robot 3 Ejes (TM3DR24-A)\n• 8 estados de ciclo Pick & Place';
    if (ql.contains('neumatico') || ql.contains('neumático'))
      return 'Centro Neumático (TMPPC24-A)\n• Compresor + 5 válvulas solenoides';
    if (ql.contains('maquinado'))
      return 'Centro Maquinados (TMINL24-A)\n• Fresadora + Taladradora';
    if (ql.contains('prensado') || ql.contains('prensa'))
      return 'Centro Prensado (TMPUM24-A)\n• Motor prensa bidireccional';
    if (ql.contains('conexion') || ql.contains('red'))
      return 'Módulo Conexiones: gestiona y monitorea las maquetas disponibles en la red.';
    if (ql.contains('diagnostico'))
        return 'Diagnóstico de Conexiones: visualiza el flujo y estado de la red en tiempo real.';
    if (ql.contains('historial') || ql.contains('log'))
      return 'Historial de Eventos: consulta y filtra todos los eventos del sistema.';
    if (ql.contains('analytic') || ql.contains('reporte'))
      return 'Analytics: KPIs de producción, tiempo activo, fallas y consumo energético.';
    if (ql.contains('usuario'))
      return 'Usuarios: gestión con roles y permisos del sistema SCADA.';
    if (ql.contains('nube') || ql.contains('cloud'))
      return 'Cloud Sync: sincronización y respaldo en la nube.';
    return 'Puedo darte datos de:\n• OEE y producción\n• Estado de estaciones\n• Alarmas activas\n\n¿Qué necesitas?';
  }

  void _scrollChat() => WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_chatSc.hasClients)
          _chatSc.animateTo(_chatSc.position.maxScrollExtent,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut);
      });

  String _viewTitle(AppView v) {
    switch (v) {
      case AppView.dashboard:
        return 'Dashboard General de Planta';
      case AppView.neumatico:
        return 'Estación 1: Centro Neumático';
      case AppView.robot:
        return 'Estación 2: Robot 3 Ejes';
      case AppView.maquinado:
        return 'Estación 3: Centro Maquinados';
      case AppView.prensado:
        return 'Estación 4: Centro Prensado';
      case AppView.conexiones:
        return 'Conexiones de Red';

         case AppView.diagnostico_conexiones:
        return 'flujo de Red';



      case AppView.historial:
        return 'Historial de Eventos';
      case AppView.usuarios:
        return 'Gestión de Usuarios';
      case AppView.nube:
        return 'Cloud Sync';
      case AppView.chatbot:
        return 'Asistente IA Chatbot';
    }
  }

  // ── BUILD ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final layout = _getLayout(w);
    final showSidebar = layout != _Layout.mobile;

    return Scaffold(
      backgroundColor: kBgDark,
      drawer: showSidebar
          ? null
          : Drawer(
              backgroundColor: kSidebar,
              child: SafeArea(child: _sidebarContent(layout)),
            ),
      body: SafeArea(
        child: Row(children: [
            if (showSidebar)
              Container(
                width: layout == _Layout.tablet ? 200 : 248,
                decoration: const BoxDecoration(
                  color: kSidebar,
                  border: Border(right: BorderSide(color: kBorder)),
                ),
                child: _sidebarContent(layout),
              ),
            Expanded(
              child: Column(children: [
                //_topBar(layout),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child:
                        KeyedSubtree(key: ValueKey(_view), child: _buildView()),
                  ),
                ),
              ]),
            ),
          ]),
      ),
    );
  }

  // ── Sidebar ────────────────────────────────────────────────────────────────
  Widget _sidebarContent(_Layout layout) {
    final compact = layout == _Layout.tablet;
    return SingleChildScrollView(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        // Brand
        Container(
          padding: EdgeInsets.symmetric(vertical: compact ? 16 : 22),
          child: Column(children: [
            Text('HITECH INGENIUM',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: kCyan,
                    fontSize: compact ? 13 : 17,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1)),
            const SizedBox(height: 3),
            Text('SCADA MASTER',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: kTextMuted,
                    fontSize: compact ? 9 : 11,
                    letterSpacing: 2)),
          ]),
        ),
        const Divider(color: kBorder, height: 1),
        const SizedBox(height: 4),

        // ── Sección: Estaciones SCADA ──
        _sectionLabel('ESTACIONES SCADA', compact),
        _navTile('📊', 'Dashboard General', AppView.dashboard, kCyan, compact),
        _navTile('⚙️', 'Centro Neumático', AppView.neumatico, kCyan, compact),
        _navTile('🤖', 'Robot 3 Ejes', AppView.robot, kPurple, compact),
        _navTile(
            '🛠️', 'Centro Maquinados', AppView.maquinado, kGreen, compact),
        _navTile('🛑', 'Centro de Prensado', AppView.prensado, kRed, compact),

        const SizedBox(height: 6),
        const Divider(color: kBorder, height: 1),
        const SizedBox(height: 4),

        // ── Sección: Herramientas del sistema ──
        _sectionLabel('SISTEMA', compact),
        _navTile('🔌', 'Conexiones', AppView.conexiones, kTeal, compact),
         _navTile('💻', 'diagnostico_Conexiones', AppView.diagnostico_conexiones, const Color.fromARGB(255, 58, 145, 226), compact),

        _navTile('📋', 'Historial / Logs', AppView.historial, kOrange, compact),
        _navTile('👥', 'Usuarios', AppView.usuarios, kPink, compact),
        _navTile('☁️', 'Cloud Sync', AppView.nube, kCyan, compact),
        _navTile('🤖', 'Chatbot', AppView.chatbot, kIndigo, compact),
        const SizedBox(height: 12),
      ]),
    );
  }

  Widget _sectionLabel(String text, bool compact) => Padding(
        padding: EdgeInsets.fromLTRB(compact ? 12 : 20, 8, 0, 4),
        child: Text(text,
            style: TextStyle(
                color: kTextMuted,
                fontSize: compact ? 8 : 9,
                letterSpacing: 1.4,
                fontWeight: FontWeight.w600)),
      );

  Widget _navTile(String em, String lbl, AppView v, Color col, bool compact) {
    final active = _view == v;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: active ? col.withOpacity(0.12) : Colors.transparent,
        border: Border(
            left:
                BorderSide(color: active ? col : Colors.transparent, width: 3)),
      ),
      child: InkWell(
        onTap: () {
          setState(() => _view = v);
          if (MediaQuery.of(context).size.width <= 600) Navigator.pop(context);
        },
        child: Padding(
          padding: EdgeInsets.symmetric(
              horizontal: compact ? 12 : 20, vertical: compact ? 10 : 13),
          child: Row(children: [
            Text(em, style: TextStyle(fontSize: compact ? 13 : 15)),
            const SizedBox(width: 8),
            Flexible(
                child: Text(lbl,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: active ? col : kTextMuted,
                        fontWeight:
                            active ? FontWeight.bold : FontWeight.normal,
                        fontSize: compact ? 11 : 13))),
          ]),
        ),
      ),
    );
  }















  // ── Top Bar ────────────────────────────────────────────────────────────────
 /*  Widget _topBar(_Layout layout) {
    if (layout == _Layout.desktop) return _topBarDesktop();
    if (layout == _Layout.tablet) return _topBarTablet();
    return _topBarMobile();
  }









  Widget _topBarDesktop() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: const BoxDecoration(
            color: kPanelBg,
            border: Border(bottom: BorderSide(color: kBorder))),
        child: Row(children: [
          Expanded(
              child: Text(_viewTitle(_view),
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: kCyan,
                      fontSize: 16,
                      fontWeight: FontWeight.bold))),
          const SizedBox(width: 12),
          Text(_clock,
              style: const TextStyle(
                  color: kCyan, fontSize: 13, fontFamily: 'monospace')),
          const SizedBox(width: 16),
          const Text('Rol:', style: TextStyle(color: kTextMuted, fontSize: 11)),
          const SizedBox(width: 4),
          _sel(_role, {
            'Ingeniero': 'Ingeniero (Control Total)',
            'Operador': 'Operador'
          }, (v) {
            setState(() {
              _role = v!;
            });
          }, 110),
          const SizedBox(width: 12),
          const Text('Modo de Planta:',
              style: TextStyle(color: kTextMuted, fontSize: 11)),
          const SizedBox(width: 4),
          _sel(_mode,
              {'manual': 'Manual (Forzar/Simular)', 'auto': 'Automático'}, (v) {
            setState(() {
              _mode = v!;
            });
          }, 130),
        ]),
      );
















  Widget _topBarTablet() => Container(
        decoration: const BoxDecoration(
            color: kPanelBg,
            border: Border(bottom: BorderSide(color: kBorder))),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Row(children: [
              Expanded(
                  child: Text(_viewTitle(_view),
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: kCyan,
                          fontSize: 14,
                          fontWeight: FontWeight.bold))),
              Text(_clock,
                  style: const TextStyle(
                      color: kCyan, fontSize: 12, fontFamily: 'monospace')),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Row(children: [
              const Text('Rol:',
                  style: TextStyle(color: kTextMuted, fontSize: 10)),
              const SizedBox(width: 4),
              _sel(_role, {
                'Ingeniero': 'Ingeniero (Control Total)',
                'Operador': 'Operador'
              }, (v) {
                setState(() {
                  _role = v!;
                });
              }, 130),
              const SizedBox(width: 10),
              const Text('Modo:',
                  style: TextStyle(color: kTextMuted, fontSize: 10)),
              const SizedBox(width: 4),
              _sel(_mode, {
                'manual': 'Manual (Forzar/Simular)',
                'auto': 'Automático'
              }, (v) {
                setState(() {
                  _mode = v!;
                });
              }, 120),
            ]),
          ),
        ]),
      );



 */


















  Widget _topBarMobile() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        decoration: const BoxDecoration(
            color: kPanelBg,
            border: Border(bottom: BorderSide(color: kBorder))),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(children: [
            Builder(
                builder: (ctx) => IconButton(
                      icon: const Icon(Icons.menu, color: kCyan, size: 22),
                      onPressed: () => Scaffold.of(ctx).openDrawer(),
                      padding: const EdgeInsets.all(6),
                    )),
            Expanded(
                child: Text(_viewTitle(_view),
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: kCyan,
                        fontSize: 13,
                        fontWeight: FontWeight.bold))),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(_clock,
                  style: const TextStyle(
                      color: kCyan, fontSize: 11, fontFamily: 'monospace')),
            ),
          ]),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
            child: Row(children: [
              const Text('Rol:',
                  style: TextStyle(color: kTextMuted, fontSize: 9)),
              const SizedBox(width: 3),
              Flexible(
                  child: _sel(
                      _role, {'Ingeniero': 'Ingeniero', 'Operador': 'Operador'},
                      (v) {
                setState(() {
                  _role = v!;
                });
              }, 100)),
              const SizedBox(width: 8),
              const Text('Modo:',
                  style: TextStyle(color: kTextMuted, fontSize: 9)),
              const SizedBox(width: 3),
              Flexible(
                  child: _sel(_mode, {'manual': 'Manual', 'auto': 'Automático'},
                      (v) {
                setState(() {
                  _mode = v!;
                });
              }, 100)),
            ]),
          ),
        ]),
      );

  Widget _sel(String val, Map<String, String> items, ValueChanged<String?> fn,
          double w) =>
      Container(
        width: w,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
            color: kBgDark,
            border: Border.all(color: kCyan),
            borderRadius: BorderRadius.circular(4)),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: val,
            dropdownColor: kPanelBg,
            style: const TextStyle(color: kCyan, fontSize: 11),
            icon: const Icon(Icons.arrow_drop_down, color: kCyan, size: 15),
            isDense: true,
            isExpanded: true,
            items: items.entries
                .map((e) => DropdownMenuItem(
                    value: e.key,
                    child: Text(e.value, overflow: TextOverflow.ellipsis)))
                .toList(),
            onChanged: fn,
          ),
        ),
      );

  // ── Vista actual ──────────────────────────────────────────────────────────
  Widget _buildView() {
    switch (_view) {

      
      // ── Estaciones SCADA (paneles vacíos por ahora) ───────────────────────
      case AppView.dashboard:
  return const AnalyticsDashboard();


      case AppView.neumatico:
      return const ScadaNeumaticoBoard();

      case AppView.robot:
      return const ScadaRobotDashboard();


      case AppView.maquinado:
      return const ScadaMaquinadosDashboard();


     case AppView.prensado:
      return const ScadaPrensadoScreen();
      

        //return _emptyStation('Centro Neumático', '⚙️', kCyan,
            //'TMPPC24-A · Punching Machine 24V');

/* 

      case AppView.robot:
        return _emptyStation('Robot 3 Ejes', '🤖', kPurple,
            'TM3DR24-A · 3D Robot 24V · Pick & Place');
      case AppView.maquinado:
        return _emptyStation(
            'Centro Maquinados', '🛠️', kGreen, 'TMINL24-A · Indexed Line 24V');
      case AppView.prensado:
        return _emptyStation('Centro de Prensado', '🛑', kRed,
            'TMPUM24-A · Punching Machine 24V');

 */










      // ── Nuevas secciones del sistema ──────────────────────────────────────
      case AppView.conexiones:
        return const ConexionesScreen();


      case AppView.diagnostico_conexiones:
        return const DiagnosticoScreen();  



      case AppView.historial:
        return const LogsScreen();
      case AppView.usuarios:
        return const UsuariosScreen();
      case AppView.nube:
        return const CloudSyncDashboard();
      case AppView.chatbot:
        return _buildChatbotView();
      case AppView.robot:
        // TODO: Handle this case.
        throw UnimplementedError();
      case AppView.maquinado:
        // TODO: Handle this case.
        throw UnimplementedError();
      case AppView.prensado:
        // TODO: Handle this case.
        throw UnimplementedError();
    }
  }
/* 
  // ── Panel vacío de estación ────────────────────────────────────────────────
  Widget _emptyStation(String name, String emoji, Color col, String subtitle) =>
      Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: col.withOpacity(0.08),
              shape: BoxShape.circle,
              border: Border.all(color: col.withOpacity(0.35), width: 2),
            ),
            child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 40))),
          ),
          const SizedBox(height: 22),
          Text(name.toUpperCase(),
              style: TextStyle(
                  color: col,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5)),
          const SizedBox(height: 6),
          Text(subtitle,
              style: const TextStyle(color: kTextMuted, fontSize: 12)),
          const SizedBox(height: 28),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              border: Border.all(color: col.withOpacity(0.4)),
              borderRadius: BorderRadius.circular(8),
              color: col.withOpacity(0.06),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.construction_rounded, color: col, size: 16),
              const SizedBox(width: 8),
              Text('Panel en construcción',
                  style: TextStyle(
                      color: col, fontSize: 13, fontWeight: FontWeight.w500)),
            ]),
          ),
        ]),
      );


 */






  // ── Dashboard General ──────────────────────────────────────────────────────
  Widget _dashboard() => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          LayoutBuilder(builder: (_, box) {
            final cols = box.maxWidth > 600 ? 4 : 2;
            final w = (box.maxWidth - 12.0 * (cols - 1)) / cols;
            return Wrap(spacing: 12, runSpacing: 12, children: [
              _kpi('OEE Planta', '87.5%', kGreen, w),
              _kpi('Producción Total', '1,240', kCyan, w),
              _kpi('Piezas Neumático', '$_piezasN', kGreen, w),
              _kpi('Piezas Maquinado', '$_piezasM', kGreen, w),
            ]);
          }),
          const SizedBox(height: 18),
          Container(
            height: 300,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: kPanelBg,
                border: Border.all(color: kBorder),
                borderRadius: BorderRadius.circular(8)),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Rendimiento de Línea (Tiempo Real)',
                  style: TextStyle(
                      color: kCyan, fontSize: 13, fontWeight: FontWeight.bold)),
              const Divider(color: kBorder),
              Expanded(
                  child: CustomPaint(
                      painter: _ChartPainter(
                datasets: [_cN, _cM],
                labels: _cL,
                colors: [kCyan, kGreen],
                names: ['Centro Neumático', 'Centro Maquinados'],
              ))),
            ]),
          ),
          const SizedBox(height: 8),
        ]),
      );

  Widget _kpi(String title, String val, Color col, double w) => SizedBox(
        width: w,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: kPanelBg,
              border: Border.all(color: kBorder),
              borderRadius: BorderRadius.circular(8)),
          child: Column(children: [
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: kTextMuted, fontSize: 11, letterSpacing: 0.6)),
            const SizedBox(height: 8),
            Text(val,
                style: TextStyle(
                    color: col, fontSize: 26, fontWeight: FontWeight.bold)),
          ]),
        ),
      );

  // ── Chatbot View ──────────────────────────────────────────────────────────
  Widget _buildChatbotView() {
    _scrollChat();
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: kSidebar,
              border: Border.all(color: kBorder),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListView.builder(
              controller: _chatSc,
              padding: const EdgeInsets.all(10),
              itemCount: _chatMsgs.length + (_chatLoading ? 1 : 0),
              itemBuilder: (_, i) {
                if (_chatLoading && i == _chatMsgs.length) {
                  return _bubble('', false, typing: true);
                }
                final m = _chatMsgs[i];
                return _bubble(m.text, m.isUser);
              },
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: kPanelBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: kBorder)),
          child: Row(children: [
            Expanded(
              child: TextField(
                controller: _chatCtrl,
                style: const TextStyle(color: kTextMain, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Pregunta algo al Asistente IA...',
                  hintStyle: const TextStyle(color: kTextMuted, fontSize: 12),
                  filled: true,
                  fillColor: kBgDark,
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: const BorderSide(color: kBorder)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: const BorderSide(color: kBorder)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: const BorderSide(color: kCyan)),
                ),
                onSubmitted: (_) => _sendChat(),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _sendChat,
              child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                      color: kCyan, borderRadius: BorderRadius.circular(6)),
                  child: const Icon(Icons.send_rounded,
                      color: kBgDark, size: 20)),
            ),
          ]),
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
              topLeft: const Radius.circular(8),
              topRight: const Radius.circular(8),
              bottomLeft: Radius.circular(isUser ? 8 : 0),
              bottomRight: Radius.circular(isUser ? 0 : 8),
            ),
          ),
          child: typing
              ? const _TypingDot()
              : Text(txt,
                  style: TextStyle(
                      color: isUser ? kBgDark : kTextMain,
                      fontSize: 12,
                      height: 1.4)),
        ),
      );
}

// ── Typing dot ────────────────────────────────────────────────────────────────
class _TypingDot extends StatefulWidget {
  const _TypingDot();
  @override
  State<_TypingDot> createState() => _TypingDotState();
}

class _TypingDotState extends State<_TypingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: CurvedAnimation(parent: _c, curve: Curves.easeInOut),
        child: const Text('Consultando SCADA...',
            style: TextStyle(
                color: kTextMuted, fontSize: 11, fontStyle: FontStyle.italic)),
      );
}

// ── Gráfica de líneas ─────────────────────────────────────────────────────────
class _ChartPainter extends CustomPainter {
  final List<List<double>> datasets;
  final List<String> labels;
  final List<Color> colors;
  final List<String> names;
  const _ChartPainter(
      {required this.datasets,
      required this.labels,
      required this.colors,
      required this.names});

  @override
  void paint(Canvas canvas, Size size) {
    const pL = 42.0, pR = 16.0, pT = 36.0, pB = 26.0;
    final cW = size.width - pL - pR, cH = size.height - pT - pB;
    double mn = double.infinity, mx = double.negativeInfinity;
    for (final d in datasets) {
      for (final v in d) {
        if (v < mn) mn = v;
        if (v > mx) mx = v;
      }
    }
    mn -= 14;
    mx += 14;
    final gp = Paint()
      ..color = kBorder
      ..strokeWidth = 0.5;
    const ts = TextStyle(color: kTextMuted, fontSize: 9);
    for (int i = 0; i <= 5; i++) {
      final y = pT + cH * (1 - i / 5);
      canvas.drawLine(Offset(pL, y), Offset(pL + cW, y), gp);
      final tp = TextPainter(
          text:
              TextSpan(text: '${(mn + (mx - mn) * i / 5).toInt()}', style: ts),
          textDirection: TextDirection.ltr)
        ..layout();
      tp.paint(canvas, Offset(pL - tp.width - 4, y - 6));
    }
    for (int i = 0; i < labels.length; i++) {
      final x = pL + (i / (labels.length - 1)) * cW;
      canvas.drawLine(Offset(x, pT), Offset(x, pT + cH), gp);
      final tp = TextPainter(
          text: TextSpan(text: labels[i], style: ts),
          textDirection: TextDirection.ltr)
        ..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, pT + cH + 4));
    }
    for (int s = 0; s < datasets.length; s++) {
      final data = datasets[s];
      final col = colors[s];
      final path = Path();
      final fill = Path();
      for (int i = 0; i < data.length; i++) {
        final x = pL + (i / (data.length - 1)) * cW;
        final y = pT + cH - ((data[i] - mn) / (mx - mn)) * cH;
        if (i == 0) {
          path.moveTo(x, y);
          fill.moveTo(x, pT + cH);
          fill.lineTo(x, y);
        } else {
          final px = pL + ((i - 1) / (data.length - 1)) * cW;
          final py = pT + cH - ((data[i - 1] - mn) / (mx - mn)) * cH;
          path.cubicTo(px + (x - px) * 0.4, py, x - (x - px) * 0.4, y, x, y);
          fill.cubicTo(px + (x - px) * 0.4, py, x - (x - px) * 0.4, y, x, y);
        }
      }
      fill.lineTo(pL + cW, pT + cH);
      fill.close();
      canvas.drawPath(
          fill,
          Paint()
            ..shader = LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [col.withOpacity(0.17), Colors.transparent])
                .createShader(Rect.fromLTWH(0, pT, size.width, cH))
            ..style = PaintingStyle.fill);
      canvas.drawPath(
          path,
          Paint()
            ..color = col
            ..strokeWidth = 2.2
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round);
      canvas.drawCircle(
          Offset(pL + cW, pT + cH - ((data.last - mn) / (mx - mn)) * cH),
          4,
          Paint()..color = col);
      final lx = pL + s * 155.0;
      canvas.drawLine(
          Offset(lx, 20),
          Offset(lx + 26, 20),
          Paint()
            ..color = col
            ..strokeWidth = 2.2);
      canvas.drawCircle(Offset(lx + 13, 20), 3, Paint()..color = col);
      final tp = TextPainter(
          text: TextSpan(
              text: names[s],
              style: const TextStyle(color: kTextMuted, fontSize: 10)),
          textDirection: TextDirection.ltr)
        ..layout();
      tp.paint(canvas, Offset(lx + 30, 14));
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
