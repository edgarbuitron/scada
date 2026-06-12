import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'usage_monitor.dart';

import 'nube.dart' show CloudSyncDashboard;
import 'analytics.dart' show AnalyticsDashboard;
import 'usuarios.dart' show UsuariosScreen;
import 'historialylogs.dart' show LogsScreen; 
import 'conexiones_tablas.dart' show ConexionesScreen;
import 'diagnostico_conexiones.dart' show DiagnosticoScreen;
import 'scada_neumatico.dart' show ScadaNeumaticoBoard;
import 'main_robot_3_ejes.dart' show ScadaRobotDashboard;
import 'main_maquinados.dart' show ScadaMaquinadosDashboard;
import 'main_prensado.dart' show ScadaPrensadoScreen;
import 'panel_general.dart' show PanelGeneralScreen;
import 'chat.dart' show ChatScreen;
import 'horarios.dart' show HorariosScreen;
import 'perfil.dart' show PerfilScreen;

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

enum _Layout { mobile, tablet, desktop }

_Layout _getLayout(double w) {
  if (w > 900) return _Layout.desktop;
  if (w > 600) return _Layout.tablet;
  return _Layout.mobile;
}

enum AppView {
  dashboard,
  panelGeneral,
  neumatico,
  robot,
  maquinado,
  prensado,
  conexiones,
  diagnosticoConexiones,
  historial,
  usuarios,
  horarios,
  chatbot,
  nube,
  perfil,
}

class ScadaMasterHome extends StatefulWidget {
  const ScadaMasterHome({super.key});
  @override
  State<ScadaMasterHome> createState() => _ScadaMasterHomeState();
}

class _ScadaMasterHomeState extends State<ScadaMasterHome> {
  AppView _view = AppView.dashboard;
  late Timer _clockTimer;
  String? _userName;
  String _userRol = 'Alumno'; 
  bool _showWelcome = false;

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
    _checkWelcome();
    _setUserOnlineStatus(true);
  }

  Future<void> _checkWelcome() async {
    final prefs = await SharedPreferences.getInstance();
    final bool shouldShow = prefs.getBool('showWelcome') ?? false;
    
    setState(() {
      _userRol = prefs.getString('userRole') ?? 'Alumno';
      if (_userRol == 'Operador') _userRol = 'Alumno';
    });

    if (shouldShow) {
      setState(() {
        _userName = prefs.getString('userName') ?? 'Usuario';
        _showWelcome = true;
      });
      await prefs.setBool('showWelcome', false);
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => _showWelcome = false);
      });
    }
  }

  Future<void> _setUserOnlineStatus(bool online) async {
    final prefs = await SharedPreferences.getInstance();
    final String? email = prefs.getString('userEmail');
    if (email != null) {
      try {
        final query = await FirebaseFirestore.instance
            .collection('usuarios')
            .where('correo', isEqualTo: email)
            .limit(1)
            .get();
        if (query.docs.isNotEmpty) {
          await query.docs.first.reference.update({
            'enLinea': online,
            'ultimoAcceso': DateFormat('dd/MM/yyyy HH:mm:ss').format(DateTime.now()),
          });
        }
      } catch (e) {
        debugPrint("Error updating online status: $e");
      }
    }
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    _setUserOnlineStatus(false);
    super.dispose();
  }

  Future<void> _logout() async {
    await _setUserOnlineStatus(false);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    if (mounted) Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final layout = _getLayout(w);
    final showSidebar = layout != _Layout.mobile;

    return Scaffold(
      backgroundColor: kBgDark,
      drawer: showSidebar ? null : Drawer(backgroundColor: kSidebar, child: SafeArea(child: _sidebarContent(layout))),
      body: Stack(
        children: [
          SafeArea(
            child: Row(children: [
              if (showSidebar)
                Container(
                  width: layout == _Layout.tablet ? 200 : 248,
                  decoration: const BoxDecoration(color: kSidebar, border: Border(right: BorderSide(color: kBorder))),
                  child: _sidebarContent(layout),
                ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: KeyedSubtree(key: ValueKey(_view), child: _buildView()),
                ),
              ),
            ]),
          ),
          if (_showWelcome)
            Positioned(
              top: 40,
              left: 0,
              right: 0,
              child: Center(
                child: _WelcomeToast(name: _userName ?? 'Usuario'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _sidebarContent(_Layout layout) {
    final compact = layout == _Layout.tablet;
    final monitor = Provider.of<UsageMonitor>(context); 

    return SingleChildScrollView(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Container(
          padding: EdgeInsets.symmetric(vertical: compact ? 16 : 22),
          child: Column(children: [
            Text('HITECH INGENIUM', textAlign: TextAlign.center, style: TextStyle(color: kCyan, fontSize: compact ? 13 : 17, fontWeight: FontWeight.bold, letterSpacing: 1)),
            const SizedBox(height: 3),
            Text('SCADA MASTER', textAlign: TextAlign.center, style: TextStyle(color: kTextMuted, fontSize: compact ? 9 : 11, letterSpacing: 2)),
          ]),
        ),
        const Divider(color: kBorder, height: 1),
        const SizedBox(height: 4),

        _sectionLabel('ESTACIONES SCADA', compact),
        _navTile('📊', 'Dashboard General', AppView.dashboard, kCyan, compact, false),
        _navTile('🎛️', 'Panel General', AppView.panelGeneral, kTeal, compact, monitor.isStationActive('general')),
        _navTile('⚙️', 'Centro Neumático', AppView.neumatico, kCyan, compact, monitor.isStationActive('neumatico')),
        _navTile('🤖', 'Robot 3 Ejes', AppView.robot, kPurple, compact, monitor.isStationActive('robot')),
        _navTile('🛠️', 'Centro Maquinados', AppView.maquinado, kGreen, compact, monitor.isStationActive('maquinados')),
        _navTile('🛑', 'Centro de Prensado', AppView.prensado, kRed, compact, monitor.isStationActive('prensado')),

        const SizedBox(height: 6),
        const Divider(color: kBorder, height: 1),
        const SizedBox(height: 4),

        _sectionLabel('SISTEMA', compact),
        if (_userRol == 'Administrador') ...[
          _navTile('🔌', 'Conexiones', AppView.conexiones, kTeal, compact, false),
          _navTile('💻', 'Diagnóstico de Conexiones', AppView.diagnosticoConexiones, const Color.fromARGB(255, 58, 145, 226), compact, false),
        ],
        
        if (_userRol == 'Administrador' || _userRol == 'Ingeniero')
          _navTile('📋', 'Historial / Logs', AppView.historial, kOrange, compact, false),
        
        if (_userRol == 'Administrador')
          _navTile('👥', 'Usuarios', AppView.usuarios, kPink, compact, false, 
            hasAlert: monitor.pendingUsersCount > 0),
          
        if (_userRol == 'Administrador')
          _navTile('📅', 'Horarios de Uso', AppView.horarios, Colors.blue, compact, false),
          
        _navTile('🤖', 'Chatbot AI', AppView.chatbot, kCyan, compact, false),
        
        if (_userRol == 'Administrador')
          _navTile('☁️', 'Cloud Sync', AppView.nube, kCyan, compact, false),

        _navTile('👤', 'Mi Perfil', AppView.perfil, kCyan, compact, false),

        const SizedBox(height: 12),
        const Divider(color: kBorder, height: 1),
        const SizedBox(height: 4),
        _logoutTile(compact),
      ]),
    );
  }

  Widget _sectionLabel(String text, bool compact) => Padding(
        padding: EdgeInsets.fromLTRB(compact ? 12 : 20, 8, 0, 4),
        child: Text(text, style: TextStyle(color: kTextMuted, fontSize: compact ? 8 : 9, letterSpacing: 1.4, fontWeight: FontWeight.w600)),
      );

  Widget _navTile(String em, String lbl, AppView v, Color col, bool compact, bool isProcessing, {bool hasAlert = false}) {
    final active = _view == v;
    final bool showAlert = hasAlert && !active;
    final highlightCol = isProcessing ? Colors.yellowAccent : (active ? kCyan : (showAlert ? Colors.orangeAccent : col));
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: active ? highlightCol.withValues(alpha: 0.12) : Colors.transparent,
        border: Border(left: BorderSide(color: active ? highlightCol : Colors.transparent, width: 3)),
      ),
      child: InkWell(
        onTap: () {
          setState(() => _view = v);
          if (MediaQuery.of(context).size.width <= 600) Navigator.pop(context);
        },
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 20, vertical: compact ? 10 : 13),
          child: Row(children: [
            isProcessing 
              ? const SizedBox(
                  width: 15, height: 15, 
                  child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.yellowAccent))
                )
              : Text(em, style: TextStyle(fontSize: compact ? 13 : 15)),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                lbl, 
                overflow: TextOverflow.ellipsis, 
                style: TextStyle(
                  color: isProcessing ? Colors.yellowAccent : (active ? kCyan : (showAlert ? Colors.orangeAccent : kTextMuted)), 
                  fontWeight: (active || isProcessing || showAlert) ? FontWeight.bold : FontWeight.normal, 
                  fontSize: compact ? 11 : 13
                )
              )
            ),
            if (isProcessing) ...[
              const SizedBox(width: 5),
              const Icon(Icons.settings_suggest, color: Colors.yellowAccent, size: 14),
            ],
            if (showAlert) ...[
              const SizedBox(width: 5),
              const Icon(Icons.priority_high_rounded, color: Colors.orangeAccent, size: 16),
            ]
          ]),
        ),
      ),
    );
  }

  Widget _logoutTile(bool compact) => InkWell(
      onTap: _logout,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 20, vertical: compact ? 10 : 13),
        child: Row(children: [
          Icon(Icons.logout, color: kRed, size: compact ? 18 : 20),
          const SizedBox(width: 8),
          Flexible(child: Text('Cerrar Sesión', overflow: TextOverflow.ellipsis, style: TextStyle(color: kRed, fontWeight: FontWeight.bold, fontSize: compact ? 11 : 13))),
        ]),
      ),
    );

  Widget _buildView() {
    switch (_view) {
      case AppView.dashboard: return const AnalyticsDashboard();
      case AppView.panelGeneral: return const PanelGeneralScreen();
      case AppView.neumatico: return const ScadaNeumaticoBoard();
      case AppView.robot: return const ScadaRobotDashboard();
      case AppView.maquinado: return const ScadaMaquinadosDashboard();
      case AppView.prensado: return const ScadaPrensadoScreen();
      case AppView.conexiones: return const ConexionesScreen();
      case AppView.diagnosticoConexiones: return const DiagnosticoScreen();
      case AppView.historial: return const LogsScreen(); 
      case AppView.usuarios: return const UsuariosScreen();
      case AppView.horarios: return const HorariosScreen();
      case AppView.chatbot: return const ChatScreen();
      case AppView.nube: return const CloudSyncDashboard();
      case AppView.perfil: return const PerfilScreen();
    }
  }
}

class _WelcomeToast extends StatefulWidget {
  final String name;
  const _WelcomeToast({required this.name});
  @override
  State<_WelcomeToast> createState() => _WelcomeToastState();
}

class _WelcomeToastState extends State<_WelcomeToast> with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  late Animation<double> _scale;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _scale = Tween<double>(begin: 0.5, end: 1.0).animate(CurvedAnimation(parent: _anim, curve: Curves.elasticOut));
    _fade = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _anim, curve: Curves.easeIn));
    _anim.forward();

    Future.delayed(const Duration(milliseconds: 2400), () {
      if (mounted) _anim.reverse();
    });
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: kCyan,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [BoxShadow(color: kCyan.withValues(alpha: 0.4), blurRadius: 20, spreadRadius: 2)],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.waving_hand_rounded, color: Colors.black87, size: 20),
              const SizedBox(width: 12),
              Text(
                'Bienvenido, ${widget.name}',
                style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
