import 'package:flutter/material.dart';

// ── IMPORTS ──
import 'scada_neumatico.dart';
import 'main_prensado.dart';

// 🔴 FUTUROS MÓDULOS
import 'main_robot_3_ejes.dart';
// ignore: unused_import
import 'main_maquinados.dart';

void main() => runApp(const ScadaMasterApp());

// ── COLORES ──
const Color kBg      = Color(0xFF0F172A);
const Color kPanel   = Color(0xFF1E293B);
const Color kSidebar = Color(0xFF0B1120);
const Color kCyan    = Color(0xFF38BDF8);
const Color kGreen   = Color(0xFF10B981);
const Color kRed     = Color(0xFFF43F5E);
const Color kText    = Color(0xFFF8FAFC);
const Color kBorder  = Color(0xFF334155);

// ── APP ──
class ScadaMasterApp extends StatelessWidget {
  const ScadaMasterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SCADA Planta - Hitech',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: kBg,
        colorScheme: const ColorScheme.dark(primary: kCyan),
      ),
      home: const ScadaMasterHome(),
    );
  }
}

// ── ENUM ──
enum AppView { dashboard, neumatico, robot, maquinado, prensado }

// ── HOME ──
class ScadaMasterHome extends StatefulWidget {
  const ScadaMasterHome({super.key});

  @override
  State<ScadaMasterHome> createState() => _ScadaMasterHomeState();
}

class _ScadaMasterHomeState extends State<ScadaMasterHome> {

  AppView _currentView = AppView.dashboard;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          _buildSidebar(),
          Expanded(child: _buildCurrentView()),
        ],
      ),
    );
  }

  // ── ROUTER ──
  Widget _buildCurrentView() {
    switch (_currentView) {

      case AppView.dashboard:
        return _buildDashboard();

      case AppView.neumatico:
        return const ScadaNeumaticoScreen();

      case AppView.prensado:
        return const ScadaPrensadoScreen();

      // 🔴 FUTUROS MÓDULOS
      case AppView.robot:
        return const ScadaRobot3EjesScreen();

      case AppView.maquinado:
        return const ScadaMaquinadosScreen();
    }
  }

  // ── SIDEBAR ──
  Widget _buildSidebar() {
    return Container(
      width: 260,
      color: kSidebar,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              'HITECH INGENIUM',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: kCyan,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Divider(color: kBorder),

          _navItem(AppView.dashboard, '📊', 'Dashboard'),
          _navItem(AppView.neumatico, '⚙️', 'Neumático'),
          _navItem(AppView.prensado, '🛑', 'Prensado'),
          _navItem(AppView.maquinado, '🛠️', 'Maquinado'),

          // 🔴 FUTUROS
          _navItem(AppView.robot, '🤖', 'Robot'),
        ],
      ),
    );
  }

  Widget _navItem(AppView target, String emoji, String label) {
    final active = _currentView == target;

    return InkWell(
      onTap: () => setState(() => _currentView = target),
      child: Container(
        color: active ? kCyan.withOpacity(0.1) : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 15),
            Text(
              label,
              style: TextStyle(
                color: active ? kCyan : kText,
                fontWeight: active ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── DASHBOARD ──
  Widget _buildDashboard() {
    return const Center(
      child: Text(
        "Dashboard SCADA",
        style: TextStyle(color: Colors.white, fontSize: 22),
      ),
    );
  }
}