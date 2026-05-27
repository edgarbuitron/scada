import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'login.dart';
import 'nube.dart' show NubeScreen;
import 'analitycs.dart' show AnalyticsDashboard;
import 'usuarios.dart' show UsuariosScreen;
// CORRECCIÓN: El nombre correcto de la clase en el archivo es LogsScreen
import 'historialylogs.dart' show LogsScreen; 
import 'conexiones_tablas.dart' show ConexionesScreen;
import 'diagnostico_conexiones.dart' show DiagnosticoScreen;
import 'scada_neumatico.dart' show ScadaNeumaticoScreen;
import 'main_robot_3_ejes.dart' show ScadaRobotDashboard;
import 'main_maquinados.dart' show ScadaMaquinadosDashboard;
import 'main_prensado.dart' show ScadaPrensadoScreen;

// ... (Constantes de color y enums se mantienen igual)
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
  neumatico,
  robot,
  maquinado,
  prensado,
  conexiones,
  diagnostico_conexiones,
  historial,
  usuarios,
  nube,
  chatbot,
}

class ScadaMasterHome extends StatefulWidget {
  const ScadaMasterHome({super.key});
  @override
  State<ScadaMasterHome> createState() => _ScadaMasterHomeState();
}

class _ScadaMasterHomeState extends State<ScadaMasterHome> {
  AppView _view = AppView.dashboard;
  String _clock = '';
  late Timer _clockTimer;

  @override
  void initState() {
    super.initState();
    _updateClock();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) => setState(_updateClock));
  }

  void _updateClock() {
    final n = DateTime.now();
    _clock = '${n.hour.toString().padLeft(2, '0')}:${n.minute.toString().padLeft(2, '0')}:${n.second.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    super.dispose();
  }

  Future<void> _logout() async {
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
      body: SafeArea(
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
    );
  }

  Widget _sidebarContent(_Layout layout) {
    final compact = layout == _Layout.tablet;
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
        _navTile('📊', 'Dashboard General', AppView.dashboard, kCyan, compact),
        _navTile('⚙️', 'Centro Neumático', AppView.neumatico, kCyan, compact),
        _navTile('🤖', 'Robot 3 Ejes', AppView.robot, kPurple, compact),
        _navTile('🛠️', 'Centro Maquinados', AppView.maquinado, kGreen, compact),
        _navTile('🛑', 'Centro de Prensado', AppView.prensado, kRed, compact),

        const SizedBox(height: 6),
        const Divider(color: kBorder, height: 1),
        const SizedBox(height: 4),

        _sectionLabel('SISTEMA', compact),
        _navTile('🔌', 'Conexiones', AppView.conexiones, kTeal, compact),
        _navTile('💻', 'Diagnóstico de Conexiones', AppView.diagnostico_conexiones, const Color.fromARGB(255, 58, 145, 226), compact),
        _navTile('📋', 'Historial / Logs', AppView.historial, kOrange, compact),
        _navTile('👥', 'Usuarios', AppView.usuarios, kPink, compact),
        _navTile('☁️', 'Cloud Sync', AppView.nube, kCyan, compact),
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
          padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 20, vertical: compact ? 10 : 13),
          child: Row(children: [
            Text(em, style: TextStyle(fontSize: compact ? 13 : 15)),
            const SizedBox(width: 8),
            Flexible(child: Text(lbl, overflow: TextOverflow.ellipsis, style: TextStyle(color: active ? col : kTextMuted, fontWeight: active ? FontWeight.bold : FontWeight.normal, fontSize: compact ? 11 : 13))),
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
      case AppView.neumatico: return const ScadaNeumaticoScreen();
      case AppView.robot: return const ScadaRobotDashboard();
      case AppView.maquinado: return const ScadaMaquinadosDashboard();
      case AppView.prensado: return const ScadaPrensadoScreen();
      case AppView.conexiones: return const ConexionesScreen();
      case AppView.diagnostico_conexiones: return const DiagnosticoScreen();
      // CORRECCIÓN FINAL: Usar el nombre de clase correcto que es LogsScreen
      case AppView.historial: return const LogsScreen(); 
      case AppView.usuarios: return const UsuariosScreen();
      case AppView.nube: return const NubeScreen();
      case AppView.chatbot: return Container(); // Placeholder
    }
  }
}
