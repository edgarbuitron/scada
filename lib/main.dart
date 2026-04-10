import 'package:flutter/material.dart';
import 'dart:async';

// ── IMPORTAMOS TUS 4 MAQUETAS ──
import 'scada_neumatico.dart';
import 'scada_robot.dart';
import 'scada_maquinados.dart';
import 'scada_prensado.dart';

void main() => runApp(const ScadaMasterApp());

// ── PALETA DE COLORES UNIFICADA PARA TODA LA APP ──
const Color kBg      = Color(0xFF0F172A);
const Color kPanel   = Color(0xFF1E293B);
const Color kSidebar = Color(0xFF0B1120);
const Color kCyan    = Color(0xFF38BDF8);
const Color kGreen   = Color(0xFF10B981);
const Color kRed     = Color(0xFFF43F5E);
const Color kPurple  = Color(0xFFA855F7);
const Color kOrange  = Color(0xFFF59E0B);
const Color kText    = Color(0xFFF8FAFC);
const Color kTextMuted= Color(0xFF94A3B8);
const Color kBorder  = Color(0xFF334155);

class ScadaMasterApp extends StatelessWidget {
  const ScadaMasterApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'SCADA Planta - Hitech',
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: kBg,
          colorScheme: const ColorScheme.dark(primary: kCyan),
        ),
        home: const ScadaMasterHome(),
      );
}

enum AppView { dashboard, neumatico, robot, maquinado, prensado }

class _ChatMsg {
  final String text;
  final bool isUser;
  _ChatMsg(this.text, this.isUser);
}

class ScadaMasterHome extends StatefulWidget {
  const ScadaMasterHome({super.key});
  @override
  State<ScadaMasterHome> createState() => _ScadaMasterHomeState();
}

class _ScadaMasterHomeState extends State<ScadaMasterHome> {
  AppView _currentView = AppView.dashboard;
  
  // Chatbot State
  bool _chatOpen = false;
  final TextEditingController _chatCtrl = TextEditingController();
  final ScrollController _chatScroll = ScrollController();
  final List<_ChatMsg> _chatMessages = [
    _ChatMsg('¡Hola! Soy el asistente virtual de Hitech. ¿Qué maqueta revisamos hoy?', false),
  ];

  void _sendChat() {
    final text = _chatCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _chatMessages.add(_ChatMsg(text, true));
      _chatCtrl.clear();
      Future.delayed(const Duration(seconds: 1), () {
        setState(() => _chatMessages.add(_ChatMsg('Consultando SCADA sobre: "$text"...', false)));
        _scrollChat();
      });
    });
    _scrollChat();
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
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          _buildSidebar(),
          Expanded(child: _buildCurrentView()),
        ],
      ),
      floatingActionButton: _buildChatbot(),
    );
  }

  // ── ROUTER INTERNO (Cambia la pantalla sin borrar el menú) ──
  Widget _buildCurrentView() {
    switch (_currentView) {
      case AppView.dashboard: return _buildDashboard();
      case AppView.neumatico: return const MaquetaNeumaticaScreen();
      case AppView.robot:     return const MaquetaRobotScreen();
      case AppView.maquinado: return const MaquetaMaquinadosScreen();
      case AppView.prensado:  return const MaquetaPrensadoScreen();
    }
  }

  Widget _buildSidebar() {
    return Container(
      width: 260,
      color: kSidebar,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text('HITECH INGENIUM', textAlign: TextAlign.center, style: TextStyle(color: kCyan, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1)),
          ),
          const Divider(color: kBorder, height: 1),
          _navItem(AppView.dashboard, '📊', 'Dashboard Global'),
          _navItem(AppView.neumatico, '⚙️', 'Centro Neumático'),
          _navItem(AppView.robot,     '🤖', 'Robot 3 Ejes'),
          _navItem(AppView.maquinado, '🛠️', 'Centro Maquinados'),
          _navItem(AppView.prensado,  '🛑', 'Centro Prensado'),
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
            Text(label, style: TextStyle(color: active ? kCyan : kText, fontWeight: active ? FontWeight.bold : FontWeight.normal)),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboard() {
    return Padding(
      padding: const EdgeInsets.all(30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('DASHBOARD GENERAL', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 30),
          Row(
            children: [
              Expanded(child: _kpiCard('Estado Red SCADA', 'CONECTADO', kGreen)),
              const SizedBox(width: 20),
              Expanded(child: _kpiCard('Piezas Totales', '1,452', kCyan)),
              const SizedBox(width: 20),
              Expanded(child: _kpiCard('Alarmas', '0 Activas', kTextMuted)),
            ],
          ),
          const Spacer(),
          const Center(child: Text('👈 Selecciona una estación en el menú lateral para entrar a su control interactivo.', style: TextStyle(color: kTextMuted, fontSize: 18))),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _kpiCard(String title, String val, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: kPanel, borderRadius: BorderRadius.circular(8), border: Border.all(color: kBorder)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: kTextMuted, fontSize: 14)),
          const SizedBox(height: 10),
          Text(val, style: TextStyle(color: color, fontSize: 28, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildChatbot() => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      if (_chatOpen)
        Container(
          width: 320, height: 400,
          margin: const EdgeInsets.only(bottom: 10, right: 10),
          decoration: BoxDecoration(color: kPanel, borderRadius: BorderRadius.circular(10), border: Border.all(color: kCyan.withOpacity(0.5)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10)]),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(color: kCyan, borderRadius: BorderRadius.only(topLeft: Radius.circular(9), topRight: Radius.circular(9))),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('🤖 Asistente SCADA', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                    InkWell(onTap: () => setState(() => _chatOpen = false), child: const Icon(Icons.close, color: Colors.black, size: 20)),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: _chatScroll, padding: const EdgeInsets.all(10), itemCount: _chatMessages.length,
                  itemBuilder: (c, i) {
                    final msg = _chatMessages[i];
                    return Align(
                      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: msg.isUser ? kCyan.withOpacity(0.2) : kBg, borderRadius: BorderRadius.circular(8), border: Border.all(color: msg.isUser ? kCyan : kBorder)),
                        child: Text(msg.text, style: TextStyle(color: msg.isUser ? kCyan : kText)),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _chatCtrl, style: const TextStyle(color: kText, fontSize: 13),
                        decoration: InputDecoration(hintText: 'Preguntar...', hintStyle: const TextStyle(color: kTextMuted), filled: true, fillColor: kBg, contentPadding: const EdgeInsets.symmetric(horizontal: 10), border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none)),
                        onSubmitted: (_) => _sendChat(),
                      ),
                    ),
                    IconButton(icon: const Icon(Icons.send, color: kCyan, size: 20), onPressed: _sendChat)
                  ],
                ),
              )
            ],
          ),
        ),
      FloatingActionButton(backgroundColor: kCyan, child: const Icon(Icons.chat, color: Colors.black), onPressed: () => setState(() => _chatOpen = !_chatOpen)),
    ],
  );
}