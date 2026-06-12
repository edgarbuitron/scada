import 'dart:async';
import 'package:flutter/material.dart';
import 'schedule_guard.dart';
import 'horario_fuera.dart';

// ─── Paleta de Colores ────────────────────────────────────────────────────────
const kBg = Color(0xFF0D1321);
const kCard = Color(0xFF131D2E);
const kBorder = Color(0xFF1E2D45);
const kBlue = Color(0xFF3B82F6);
const kGreen = Color(0xFF22C55E);
const kRed = Color(0xFFEF4444);
const kYellow = Color(0xFFF59E0B);
const kCyan = Color(0xFF00EAFF); // Definido explícitamente
const kText = Color(0xFFE2E8F0);
const kMuted = Color(0xFF64748B);
const kMuted2 = Color(0xFF8B9CBD);

// ─── Modelos ──────────────────────────────────────────────────────────────────
enum ConStatus { conectado, conectando, desconectado }

class Maqueta {
  final String nombre;
  final String ip;
  final String ssid;
  final int senal;
  final String latencia;
  final String ultimaConexion;
  ConStatus estado;

  Maqueta({
    required this.nombre,
    required this.ip,
    required this.ssid,
    required this.senal,
    required this.latencia,
    required this.ultimaConexion,
    this.estado = ConStatus.desconectado,
  });
}

// ═════════════════════════════════════════════════════════════════════════════
class ConexionesScreen extends StatefulWidget {
  const ConexionesScreen({super.key});
  @override
  State<ConexionesScreen> createState() => _ConexionesScreenState();
}

class _ConexionesScreenState extends State<ConexionesScreen> {
  final List<Maqueta> _listaMaquetas = [
    Maqueta(
        nombre: 'Centro Neumático',
        ip: '192.168.1.45',
        ssid: 'LAB-SCADA-01',
        senal: -52,
        latencia: '12 ms',
        ultimaConexion: 'Hoy, 10:32 AM'),
    Maqueta(
        nombre: 'Centro de Maquinados',
        ip: '192.168.1.48',
        ssid: 'LAB-SCADA-01',
        senal: -65,
        latencia: '18 ms',
        ultimaConexion: 'Hoy, 09:15 AM'),
    Maqueta(
        nombre: 'Robot 3 Ejes',
        ip: '192.168.1.52',
        ssid: 'LAB-SCADA-02',
        senal: -78,
        latencia: '--',
        ultimaConexion: 'Ayer, 04:40 PM'),
    Maqueta(
        nombre: 'Centro de Prensado',
        ip: '192.168.1.55',
        ssid: 'LAB-SCADA-02',
        senal: -85,
        latencia: '--',
        ultimaConexion: 'Ayer, 02:10 PM'),
  ];

  void _toggleEstado(Maqueta m) async {
    if (m.estado == ConStatus.desconectado) {
      final bool canConnect = await ScheduleGuard.canConnectToHardware();
      if (!canConnect) {
        if (mounted) mostrarBloqueoHorario(context);
        return;
      }
    }

    setState(() {
      if (m.estado == ConStatus.conectado) {
        m.estado = ConStatus.desconectado;
      } else if (m.estado == ConStatus.desconectado) {
        m.estado = ConStatus.conectando;
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              m.estado = ConStatus.conectado;
            });
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildResponsiveLayout(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: const [
      Text('Conexiones',
          style: TextStyle(
              fontSize: 26, fontWeight: FontWeight.bold, color: kText)),
      SizedBox(height: 4),
      Text('Gestiona y conecta tus maquetas disponibles',
          style: TextStyle(fontSize: 13, color: kMuted2)),
    ],
  );

  Widget _buildResponsiveLayout() {
    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth > 950) {
        return _buildDesktopTable();
      } else {
        return _buildMobileCards();
      }
    });
  }

  Widget _buildDesktopTable() {
    return Container(
      decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kBorder)),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: const BoxDecoration(
              color: Color(0xFF1A2540),
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12), topRight: Radius.circular(12))),
          child: Row(children: const [
            Expanded(flex: 4, child: _TH('Nombre Dispositivo')),
            Expanded(flex: 3, child: _TH('IP Local')),
            Expanded(flex: 4, child: _TH('SSID / Red')),
            Expanded(flex: 3, child: _TH('Estado')),
            Expanded(flex: 3, child: _TH('Señal')),
            Expanded(flex: 2, child: _TH('Lat')),
            Expanded(flex: 3, child: _TH('Últ. Conexión')),
            Expanded(flex: 3, child: _TH('Acción', center: true)),
          ]),
        ),
        ..._listaMaquetas.map((m) => _MaquetaRowDesktop(m: m, onAction: () => _toggleEstado(m))),
      ]),
    );
  }

  Widget _buildMobileCards() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _listaMaquetas.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) => _MaquetaCardMobile(
        m: _listaMaquetas[index], 
        onAction: () => _toggleEstado(_listaMaquetas[index])
      ),
    );
  }
}

// ─── VISTA DESKTOP: FILA DE TABLA ─────────────────────────────────────────────
class _MaquetaRowDesktop extends StatelessWidget {
  final Maqueta m;
  final VoidCallback onAction;
  const _MaquetaRowDesktop({required this.m, required this.onAction});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: kBorder, width: 0.5))),
      child: Row(children: [
        Expanded(
            flex: 4,
            child: Row(children: [
              Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                      color: const Color(0xFF1A2540),
                      borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.memory_outlined,
                      size: 16, color: kMuted2)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(m.nombre,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: kText),
                    overflow: TextOverflow.ellipsis),
              ),
            ])),
        Expanded(
            flex: 3,
            child: Text(m.ip, style: const TextStyle(fontSize: 12, color: kMuted2))),
        Expanded(
            flex: 4,
            child: Text(m.ssid, style: const TextStyle(fontSize: 12, color: kMuted2))),
        Expanded(flex: 3, child: _StatusBadge(status: m.estado)),
        Expanded(
            flex: 3, child: _SignalWidget(dbm: m.senal, status: m.estado)),
        Expanded(
            flex: 2,
            child: Text(m.latencia,
                style: const TextStyle(fontSize: 12, color: kMuted2))),
        Expanded(
            flex: 3,
            child: Text(m.ultimaConexion,
                style: const TextStyle(fontSize: 12, color: kMuted2))),
        Expanded(
            flex: 3,
            child: Center(child: _ActionButton(status: m.estado, onPressed: onAction))),
      ]),
    );
  }
}

// ─── VISTA MOBILE: TARJETA ────────────────────────────────────────────────────
class _MaquetaCardMobile extends StatelessWidget {
  final Maqueta m;
  final VoidCallback onAction;
  const _MaquetaCardMobile({required this.m, required this.onAction});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                      color: const Color(0xFF1A2540),
                      borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.memory_outlined,
                      size: 20, color: kCyan)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(m.nombre,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: kText)),
                    Text(m.ip, style: const TextStyle(fontSize: 12, color: kMuted2)),
                  ],
                ),
              ),
              _StatusBadge(status: m.estado),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: kBorder, height: 1),
          const SizedBox(height: 16),
          Wrap(
            spacing: 24,
            runSpacing: 12,
            children: [
              _InfoItem(label: 'SSID / RED', value: m.ssid),
              _InfoItem(label: 'LATENCIA', value: m.latencia),
              _InfoItem(label: 'ÚLT. CONEXIÓN', value: m.ultimaConexion),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('SEÑAL', style: TextStyle(fontSize: 10, color: kMuted2, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  _SignalWidget(dbm: m.senal, status: m.estado),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: _ActionButton(status: m.estado, onPressed: onAction, large: true),
          ),
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final String label, value;
  const _InfoItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: kMuted2, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 12, color: kText)),
      ],
    );
  }
}

// ─── Widgets Auxiliares ──────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final ConStatus status;
  final VoidCallback onPressed;
  final bool large;

  const _ActionButton({required this.status, required this.onPressed, this.large = false});

  @override
  Widget build(BuildContext context) {
    if (status == ConStatus.conectado) {
      return OutlinedButton(
          style: OutlinedButton.styleFrom(
              foregroundColor: kText,
              side: const BorderSide(color: kBorder),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: large ? 14 : 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
          onPressed: onPressed,
          child: const Text('Desconectar', style: TextStyle(fontSize: 12)));
    } else {
      return ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: status == ConStatus.conectando ? kYellow : kBlue,
              foregroundColor: status == ConStatus.conectando ? Colors.black : Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: large ? 14 : 10),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
          onPressed: status == ConStatus.conectando ? null : onPressed,
          child: Text(status == ConStatus.conectando ? 'Conectando' : 'Conectar',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)));
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final ConStatus status;
  const _StatusBadge({required this.status});
  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      ConStatus.conectado => ('Conectado', kGreen),
      ConStatus.conectando => ('Conectando', kYellow),
      ConStatus.desconectado => ('Desconectado', kRed),
    };
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color, 
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 4, spreadRadius: 1)]
          )),
      const SizedBox(width: 8),
      Text(label,
          style: TextStyle(
              fontSize: 12, color: color, fontWeight: FontWeight.bold)),
    ]);
  }
}

class _SignalWidget extends StatelessWidget {
  final int dbm;
  final ConStatus status;
  const _SignalWidget({required this.dbm, required this.status});

  @override
  Widget build(BuildContext context) {
    if (status == ConStatus.desconectado) {
      return const Text('--', style: TextStyle(fontSize: 12, color: kMuted2));
    }
    final bars = dbm >= -55 ? 4 : dbm >= -67 ? 3 : dbm >= -80 ? 2 : 1;
    final color = dbm >= -67 ? kGreen : dbm >= -80 ? kYellow : kRed;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Text('$dbm dBm', style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold)),
      const SizedBox(width: 8),
      Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(
              4,
              (i) => Container(
                    width: 3.5,
                    height: 4.0 + i * 2.5,
                    margin: const EdgeInsets.only(right: 2),
                    decoration: BoxDecoration(
                      color: i < bars ? color : kMuted.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ))),
    ]);
  }
}

class _TH extends StatelessWidget {
  final String text;
  final bool center;
  const _TH(this.text, {this.center = false});
  @override
  Widget build(BuildContext context) => Text(text,
      textAlign: center ? TextAlign.center : TextAlign.left,
      style: const TextStyle(
          fontSize: 11, fontWeight: FontWeight.bold, color: kMuted2, letterSpacing: 0.5));
}
