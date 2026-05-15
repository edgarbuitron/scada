import 'package:flutter/material.dart';

void main() => runApp(const ConexionesGridApp());

const kBg = Color(0xFF0D1321);
const kCard = Color(0xFF131D2E);
const kBorder = Color(0xFF1E2D45);
const kBlue = Color(0xFF3B82F6);
const kGreen = Color(0xFF22C55E);
const kRed = Color(0xFFEF4444);
const kYellow = Color(0xFFF59E0B);
const kText = Color(0xFFE2E8F0);
const kMuted = Color(0xFF64748B);
const kMuted2 = Color(0xFF8B9CBD);

enum ConStatus { conectado, conectando, desconectado }

class MaquetaData {
  final String nombre, subtitulo, ip, latencia, ultimaConexion;
  final ConStatus estado;
  final int senal;
  final IconData icon;
  const MaquetaData({
    required this.nombre,
    required this.subtitulo,
    required this.ip,
    required this.estado,
    required this.senal,
    required this.latencia,
    required this.ultimaConexion,
    required this.icon,
  });
}

final _maquetas = [
  const MaquetaData(
      nombre: 'centro Neumático',
      subtitulo: 'Estación Neumática',
      ip: '192.168.4.1',
      estado: ConStatus.conectado,
      senal: -48,
      latencia: '12 ms',
      ultimaConexion: '10:31 AM',
      icon: Icons.settings_input_component_outlined),
  const MaquetaData(
      nombre: 'centro de maquinados',
      subtitulo: 'Sistema de Banda',
      ip: '192.168.4.2',
      estado: ConStatus.conectado,
      senal: -55,
      latencia: '18 ms',
      ultimaConexion: '10:30 AM',
      icon: Icons.linear_scale_outlined),
  const MaquetaData(
      nombre: 'Robot 3 ejes',
      subtitulo: 'Brazo Robótico',
      ip: '192.168.4.3',
      estado: ConStatus.conectando,
      senal: -62,
      latencia: '18 ms',
      ultimaConexion: '--',
      icon: Icons.precision_manufacturing_outlined),
  const MaquetaData(
      nombre: 'centro de prensado',
      subtitulo: 'Sistema de Prensado',
      ip: '192.168.4.4',
      estado: ConStatus.desconectado,
      senal: 0,
      latencia: '--',
      ultimaConexion: '--',
      icon: Icons.compress_outlined),
  //const MaquetaData(nombre:'Horno Industrial',    subtitulo:'Control de Temperatura',ip:'192.168.4.5', estado:ConStatus.desconectado, senal:0,   latencia:'--',    ultimaConexion:'--',        icon:Icons.whatshot_outlined),
];

// ═════════════════════════════════════════════════════════════════════════════
class ConexionesGridApp extends StatelessWidget {
  const ConexionesGridApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Conexiones',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: kBg,
            fontFamily: 'Roboto'),
        home: const ConexionesGridScreen(),
      );
}

class ConexionesGridScreen extends StatefulWidget {
  const ConexionesGridScreen({super.key});
  @override
  State<ConexionesGridScreen> createState() => _ConexionesGridScreenState();
}

class _ConexionesGridScreenState extends State<ConexionesGridScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // ── Header ──
            Row(children: [
              Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Conexiones',
                        style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: kText)),
                    SizedBox(height: 3),
                    Text('Gestiona y conecta tus maquetas disponibles',
                        style: TextStyle(fontSize: 12, color: kMuted2)),
                  ]),
              const Spacer(),

              /* ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: kBlue,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                icon: const Icon(Icons.sync, size: 16),
                label: const Text('Escanear red', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                onPressed: () {},
              ),
 */
            ]),
            const SizedBox(height: 16),

            // ── Tabs ──
            Container(
              decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: kBorder))),
              child: TabBar(
                controller: _tab,
                isScrollable: true,
                indicatorColor: kBlue,
                indicatorWeight: 2,
                labelColor: kBlue,
                unselectedLabelColor: kMuted2,
                labelStyle:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                unselectedLabelStyle: const TextStyle(fontSize: 14),
                tabAlignment: TabAlignment.start,
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: 'Lista'),
                  Tab(text: 'Mapa de red'),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Contenido ──
            Expanded(
              child: TabBarView(
                controller: _tab,
                children: [
                  _buildGrid(),
                  const Center(
                      child: Text('Mapa de red — próximamente',
                          style: TextStyle(color: kMuted2, fontSize: 16))),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildGrid() {
    return LayoutBuilder(builder: (context, c) {
      final cols = c.maxWidth > 800
          ? 3
          : c.maxWidth > 500
              ? 2
              : 1;
      return GridView.count(
        crossAxisCount: cols,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 1.0,
        children: _maquetas.map((m) => _MaquetaCard(m: m)).toList(),
      );
    });
  }
}

// ─── Tarjeta de maqueta ───────────────────────────────────────────────────────
class _MaquetaCard extends StatelessWidget {
  final MaquetaData m;
  const _MaquetaCard({required this.m});

  @override
  Widget build(BuildContext context) {
    final (statusLabel, statusColor) = switch (m.estado) {
      ConStatus.conectado => ('Conectado', kGreen),
      ConStatus.conectando => ('Conectando', kYellow),
      ConStatus.desconectado => ('Desconectado', kRed),
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorder),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Nombre + estado ──
        Row(children: [
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(m.nombre,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: kText)),
                const SizedBox(height: 2),
                Text(m.subtitulo,
                    style: const TextStyle(fontSize: 11, color: kMuted2)),
              ])),
          Row(children: [
            Container(
                width: 8,
                height: 8,
                decoration:
                    BoxDecoration(color: statusColor, shape: BoxShape.circle)),
            const SizedBox(width: 5),
            Text(statusLabel,
                style: TextStyle(
                    fontSize: 12,
                    color: statusColor,
                    fontWeight: FontWeight.w500)),
          ]),
        ]),
        const SizedBox(height: 14),

        // ── Imagen / ícono de la maqueta ──
        Expanded(
          child: Center(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF0F1825),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(m.icon, size: 56, color: kMuted.withOpacity(.7)),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // ── Stats (IP, señal, latencia) ──
        Row(children: [
          // IP
          Row(children: [
            const Icon(Icons.wifi_outlined, size: 13, color: kMuted2),
            const SizedBox(width: 4),
            Text(m.ip, style: const TextStyle(fontSize: 11, color: kMuted2)),
          ]),
          const SizedBox(width: 12),
          if (m.estado != ConStatus.desconectado) ...[
            // Señal
            Row(children: [
              const Icon(Icons.signal_cellular_alt, size: 13, color: kMuted2),
              const SizedBox(width: 3),
              Text('${m.senal} dBm',
                  style: const TextStyle(fontSize: 11, color: kMuted2)),
            ]),
          ],
        ]),
        const SizedBox(height: 5),

        // ── Latencia + Última conexión ──
        Row(children: [
          const Icon(Icons.timer_outlined, size: 13, color: kMuted2),
          const SizedBox(width: 4),
          Text(m.latencia,
              style: const TextStyle(fontSize: 11, color: kMuted2)),
          const SizedBox(width: 12),
          const Icon(Icons.access_time_outlined, size: 13, color: kMuted2),
          const SizedBox(width: 4),
          Flexible(
              child: Text(
            m.ultimaConexion == '--' ? '--' : 'Última: ${m.ultimaConexion}',
            style: const TextStyle(fontSize: 11, color: kMuted2),
            overflow: TextOverflow.ellipsis,
          )),
        ]),
        const SizedBox(height: 12),

        // ── Botón ──
        SizedBox(
          width: double.infinity,
          child: _buildBtn(),
        ),
      ]),
    );
  }

  Widget _buildBtn() {
    switch (m.estado) {
      case ConStatus.conectado:
        return OutlinedButton(
            style: OutlinedButton.styleFrom(
                foregroundColor: kText,
                side: const BorderSide(color: kBorder),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(7))),
            onPressed: () {},
            child: const Text('Desconectar', style: TextStyle(fontSize: 13)));
      case ConStatus.conectando:
        return OutlinedButton(
            style: OutlinedButton.styleFrom(
                foregroundColor: kMuted2,
                side: const BorderSide(color: kBorder),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(7))),
            onPressed: null,
            child: const Text('Conectando...', style: TextStyle(fontSize: 13)));
      case ConStatus.desconectado:
        return ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: kBlue,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(7))),
            onPressed: () {},
            child: const Text('Conectar',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)));
    }
  }
}
