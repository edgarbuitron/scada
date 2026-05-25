import 'package:flutter/material.dart';

void main() => runApp(const ConexionesApp());

// ─── Paleta de Colores ────────────────────────────────────────────────────────
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

// ─── Modelo de Datos ──────────────────────────────────────────────────────────
enum ConStatus { conectado, conectando, desconectado }

class Maqueta {
  final String nombre, subtitulo, ip, ssid, latencia, ultimaConexion;
  ConStatus estado; // IMPORTANTE: Sin 'final' para poder cambiar su valor
  final int senal;

  Maqueta({
    required this.nombre,
    required this.subtitulo,
    required this.ip,
    required this.ssid,
    required this.estado,
    required this.senal,
    required this.latencia,
    required this.ultimaConexion,
  });
}

// ═════════════════════════════════════════════════════════════════════════════
class ConexionesApp extends StatelessWidget {
  const ConexionesApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Conexiones SCADA',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: kBg,
            fontFamily: 'Roboto'),
        home: const ConexionesScreen(),
      );
}

class ConexionesScreen extends StatefulWidget {
  const ConexionesScreen({super.key});
  @override
  State<ConexionesScreen> createState() => _ConexionesScreenState();
}

class _ConexionesScreenState extends State<ConexionesScreen> {
  // Lista de maquetas
  final List<Maqueta> _listaMaquetas = [
    Maqueta(
        nombre: 'Centro Neumático',
        subtitulo: 'Estación Neumática',
        ip: '192.168.4.1',
        ssid: 'ESP32_NEUMATICA',
        estado: ConStatus.conectado,
        senal: -48,
        latencia: '12 ms',
        ultimaConexion: '10:31 AM'),
    Maqueta(
        nombre: 'Centro de Maquinados',
        subtitulo: 'Sistema de Banda',
        ip: '192.168.4.2',
        ssid: 'ESP32_BANDA',
        estado: ConStatus.conectado,
        senal: -55,
        latencia: '18 ms',
        ultimaConexion: '10:30 AM'),
    Maqueta(
        nombre: 'Robot 3 Ejes',
        subtitulo: 'Brazo Robótico',
        ip: '192.168.4.3',
        ssid: 'ESP32_ROBOT',
        estado: ConStatus.conectando,
        senal: -62,
        latencia: '--',
        ultimaConexion: '--'),
    Maqueta(
        nombre: 'Centro de Prensado',
        subtitulo: 'Sistema de Prensado',
        ip: '192.168.4.4',
        ssid: 'ESP32_PRENSA',
        estado: ConStatus.desconectado,
        senal: 0,
        latencia: '--',
        ultimaConexion: '--'),
  ];

  void _toggleEstado(Maqueta m) {
    setState(() {
      if (m.estado == ConStatus.conectado) {
        m.estado = ConStatus.desconectado;
      } else if (m.estado == ConStatus.desconectado) {
        m.estado = ConStatus.conectando;
        // Simula un tiempo de conexión
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
    int total = _listaMaquetas.length;
    int conectados =
        _listaMaquetas.where((m) => m.estado == ConStatus.conectado).length;
    int desconectados = total - conectados;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _buildHeader(),
            const SizedBox(height: 22),
            _buildKpis(total, conectados, desconectados),
            const SizedBox(height: 26),
            _buildTableSection(),
          ]),
        ),
      ),
    );
  }

  Widget _buildHeader() => Row(children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
          Text('Conexiones',
              style: TextStyle(
                  fontSize: 26, fontWeight: FontWeight.bold, color: kText)),
          SizedBox(height: 3),
          Text('Gestiona y conecta tus maquetas disponibles',
              style: TextStyle(fontSize: 13, color: kMuted2)),
        ]),
      ]);

  Widget _buildKpis(int total, int conect, int desc) => LayoutBuilder(
    builder: (context, constraints) {
      if (constraints.maxWidth < 600) {
        // Vista para pantallas pequeñas (vertical)
        return Column(
          children: [
            _KpiCard(label: 'Maquetas detectadas', value: '$total', sub: 'dispositivos', valueColor: kText),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _KpiCard(label: 'Conectadas', value: '$conect', sub: '🟢 online', valueColor: kGreen)),
                const SizedBox(width: 12),
                Expanded(child: _KpiCard(label: 'Desconectadas', value: '$desc', sub: 'offline', valueColor: kRed)),
              ],
            ),
          ],
        );
      } else {
        // Vista para pantallas grandes (horizontal)
        return Row(children: [
          Expanded(child: _KpiCard(label: 'Maquetas detectadas', value: '$total', sub: 'dispositivos', valueColor: kText)),
          const SizedBox(width: 12),
          Expanded(child: _KpiCard(label: 'Conectadas', value: '$conect', sub: '🟢 online', valueColor: kGreen)),
          const SizedBox(width: 12),
          Expanded(child: _KpiCard(label: 'Desconectadas', value: '$desc', sub: 'offline', valueColor: kRed)),
          const SizedBox(width: 12),
          Expanded(child: _KpiCard(label: 'Último escaneo', value: '10:32 AM', sub: '20/05/2025', valueColor: kText, smallValue: true)),
        ]);
      }
    },
  );


  Widget _buildTableSection() =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Maquetas disponibles',
            style: TextStyle(
                fontSize: 17, fontWeight: FontWeight.bold, color: kText)),
        const SizedBox(height: 14),
        Container(
          decoration: BoxDecoration(
              color: kCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kBorder)),
          child: Column(children: [
            // El header solo se muestra en pantallas anchas
             LayoutBuilder(builder: (context, constraints) {
                if (constraints.maxWidth > 720) {
                  return _tableHeader();
                } else {
                  return const SizedBox.shrink(); // No mostrar nada en pantallas pequeñas
                }
              }),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _listaMaquetas.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: kBorder),
              itemBuilder: (_, i) => _MaquetaRow(
                m: _listaMaquetas[i],
                onAction: () => _toggleEstado(_listaMaquetas[i]),
              ),
            ),
          ]),
        ),
      ]);

  Widget _tableHeader() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(children: const [
          Expanded(flex: 5, child: _TH('Maqueta')),
          Expanded(flex: 3, child: _TH('IP Local')),
          Expanded(flex: 4, child: _TH('SSID / Red')),
          Expanded(flex: 3, child: _TH('Estado')),
          Expanded(flex: 3, child: _TH('Señal (RSSI)')),
          Expanded(flex: 2, child: _TH('Latencia')),
          Expanded(flex: 3, child: _TH('Última conexión')),
          Expanded(flex: 3, child: _TH('Acciones', center: true)),
        ]),
      );
}

// ─── Fila Maqueta (AHORA RESPONSIVE) ──────────────────────────────────────────
class _MaquetaRow extends StatefulWidget {
  final Maqueta m;
  final VoidCallback onAction;
  const _MaquetaRow({required this.m, required this.onAction});
  @override
  State<_MaquetaRow> createState() => _MaquetaRowState();
}

class _MaquetaRowState extends State<_MaquetaRow> {
  bool _hover = false;
  
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        color: _hover ? const Color(0xFF182336) : Colors.transparent,
        // Usamos LayoutBuilder para decidir qué vista mostrar
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Define un punto de quiebre. Si la pantalla es muy estrecha, cambia la vista.
            if (constraints.maxWidth < 720) {
              return _buildNarrowLayout();
            } else {
              return _buildWideLayout();
            }
          },
        ),
      ),
    );
  }

  // == VISTA ANCHA (TABLA ORIGINAL) ==
  Widget _buildWideLayout() {
    final m = widget.m;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(children: [
        Expanded(
            flex: 5,
            child: Row(children: [
              Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                      color: const Color(0xFF1A2540),
                      borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.memory_outlined,
                      size: 18, color: kMuted2)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(m.nombre,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: kText)),
                ]),
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
            child: Center(child: _ActionButton(status: m.estado, onPressed: widget.onAction))),
      ]),
    );
  }

  // == VISTA ESTRECHA (NUEVO DISEÑO EN TARJETA) ==
  Widget _buildNarrowLayout() {
    final m = widget.m;
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
               Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                      color: const Color(0xFF1A2540),
                      borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.memory_outlined,
                      size: 18, color: kMuted2)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(m.nombre,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: kText)),
              ),
              const SizedBox(width: 12),
              _ActionButton(status: m.estado, onPressed: widget.onAction),
            ],
          ),
          const SizedBox(height: 16),
           Padding(
            padding: const EdgeInsets.only(left: 4.0),
            child: _StatusBadge(status: m.estado),
          ),
          const Divider(height: 24, color: kBorder),
          // Usamos Wrap para que los elementos se acomoden solos
          Wrap(
            spacing: 20.0, // Espacio horizontal entre elementos
            runSpacing: 12.0, // Espacio vertical entre filas
            children: [
              _InfoChip(label: 'IP Local', value: m.ip),
              _InfoChip(label: 'SSID / Red', value: m.ssid),
              _InfoChip(label: 'Latencia', value: m.latencia),
              _InfoChip(label: 'Última conexión', value: m.ultimaConexion),
              // Ponemos el widget de señal en un chip también
               Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   const _TH('Señal (RSSI)'),
                   const SizedBox(height: 4),
                  _SignalWidget(dbm: m.senal, status: m.estado),
                 ],
               ),
            ],
          )
        ],
      ),
    );
  }
}

// ─── Widgets Auxiliares ──────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final ConStatus status;
  final VoidCallback onPressed;

  const _ActionButton({required this.status, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    if (status == ConStatus.conectado) {
      return OutlinedButton(
          style: OutlinedButton.styleFrom(
              foregroundColor: kText,
              side: const BorderSide(color: kBorder),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))),
          onPressed: onPressed,
          child: const Text('Desconectar', style: TextStyle(fontSize: 12)));
    } else {
      return ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: status == ConStatus.conectando ? kYellow : kBlue,
              foregroundColor: status == ConStatus.conectando ? Colors.black : Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))),
          onPressed: status == ConStatus.conectando ? null : onPressed,
          child: Text(status == ConStatus.conectando ? 'Conectando' : 'Conectar',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)));
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
          decoration: BoxDecoration(color: color, shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: color.withOpacity(0.5), blurRadius: 4, spreadRadius: 1)]
          ),
      ),
      const SizedBox(width: 6),
      Text(label,
          style: TextStyle(
              fontSize: 12, color: color, fontWeight: FontWeight.w500)),
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

    return Row(children: [
      Text('$dbm dBm', style: TextStyle(fontSize: 11, color: color)),
      const SizedBox(width: 5),
      Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(
              4,
              (i) => Container(
                    width: 3.5,
                    height: 4.0 + i * 2.5,
                    margin: const EdgeInsets.only(right: 1.5),
                    decoration: BoxDecoration(
                      color: i < bars ? color : kMuted.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ))),
    ]);
  }
}

class _KpiCard extends StatelessWidget {
  final String label, value, sub;
  final Color valueColor;
  final bool smallValue;
  const _KpiCard(
      {required this.label,
      required this.value,
      required this.sub,
      required this.valueColor,
      this.smallValue = false});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: kCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kBorder)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 12, color: kMuted2)),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  fontSize: smallValue ? 20 : 28,
                  fontWeight: FontWeight.bold,
                  color: valueColor)),
          const SizedBox(height: 4),
          Text(sub, style: const TextStyle(fontSize: 12, color: kMuted)),
        ]),
      );
}

class _TH extends StatelessWidget {
  final String text;
  final bool center;
  const _TH(this.text, {this.center = false});
  @override
  Widget build(BuildContext context) => Text(text,
      textAlign: center ? TextAlign.center : TextAlign.left,
      style: const TextStyle(
          fontSize: 12, fontWeight: FontWeight.w600, color: kMuted2));
}

// Widget para mostrar info en la vista estrecha
class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  const _InfoChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TH(label), // Reutilizamos el estilo del header
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 12, color: kMuted2)),
      ],
    );
  }
}
