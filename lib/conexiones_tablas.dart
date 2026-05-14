import 'package:flutter/material.dart';

void main() => runApp(const ConexionesApp());

// ─── Paleta de Colores ────────────────────────────────────────────────────────
const kBg      = Color(0xFF0D1321);
const kCard    = Color(0xFF131D2E);
const kBorder  = Color(0xFF1E2D45);
const kBlue    = Color(0xFF3B82F6);
const kGreen   = Color(0xFF22C55E);
const kRed     = Color(0xFFEF4444);
const kYellow  = Color(0xFFF59E0B);
const kText    = Color(0xFFE2E8F0);
const kMuted   = Color(0xFF64748B);
const kMuted2  = Color(0xFF8B9CBD);

// ─── Modelo de Datos ──────────────────────────────────────────────────────────
enum ConStatus { conectado, conectando, desconectado }

class Maqueta {
  final String nombre, subtitulo, ip, ssid, latencia, ultimaConexion;
  ConStatus estado; // IMPORTANTE: Sin 'final' para poder cambiar su valor
  final int senal; 

  Maqueta({
    required this.nombre, required this.subtitulo,
    required this.ip, required this.ssid, required this.estado,
    required this.senal, required this.latencia, required this.ultimaConexion,
  });
}

// ═════════════════════════════════════════════════════════════════════════════
class ConexionesApp extends StatelessWidget {
  const ConexionesApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Conexiones SCADA',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(brightness: Brightness.dark, scaffoldBackgroundColor: kBg, fontFamily: 'Roboto'),
        home: const ConexionesScreen(),
      );
}

// Cambiado a StatefulWidget para que los números puedan actualizarse
class ConexionesScreen extends StatefulWidget {
  const ConexionesScreen({super.key});
  @override
  State<ConexionesScreen> createState() => _ConexionesScreenState();
}

class _ConexionesScreenState extends State<ConexionesScreen> {
  // Lista de maquetas
  final List<Maqueta> _listaMaquetas = [
    Maqueta(nombre:'centro Neumático', subtitulo:'Estación Neumática', ip:'192.168.4.1', ssid:'ESP32_NEUMATICA', estado:ConStatus.conectado, senal:-48, latencia:'12 ms', ultimaConexion:'10:31 AM'),
    Maqueta(nombre:'centro de maquinados',subtitulo:'Sistema de Banda', ip:'192.168.4.2', ssid:'ESP32_BANDA', estado:ConStatus.conectado, senal:-55, latencia:'18 ms', ultimaConexion:'10:30 AM'),
    Maqueta(nombre:'Robot 3 ejes', subtitulo:'Brazo Robótico', ip:'192.168.4.3', ssid:'ESP32_ROBOT', estado:ConStatus.conectando, senal:-62, latencia:'--', ultimaConexion:'--'),
    Maqueta(nombre:'centro de prensado', subtitulo:'Sistema de Prensado', ip:'192.168.4.4', ssid:'ESP32_PRENSA', estado:ConStatus.desconectado, senal: 0, latencia:'--', ultimaConexion:'--'),
    //Maqueta(nombre:'Horno Industrial', subtitulo:'Control de Temperatura',ip:'192.168.4.5', ssid:'ESP32_HORNO', estado:ConStatus.desconectado, senal: 0, latencia:'--', ultimaConexion:'--'),
  ];

  // Función que detecta el clic y cambia el estado
  void _toggleEstado(Maqueta m) {
    setState(() {
      if (m.estado == ConStatus.conectado) {
        m.estado = ConStatus.desconectado;
      } else {
        m.estado = ConStatus.conectado;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Cálculos dinámicos en tiempo real
    int total = _listaMaquetas.length;
    int conectados = _listaMaquetas.where((m) => m.estado == ConStatus.conectado).length;
    int desconectados = _listaMaquetas.where((m) => m.estado == ConStatus.desconectado).length;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _buildHeader(),
            const SizedBox(height: 22),
            _buildKpis(total, conectados, desconectados), // Pasamos los valores calculados
            const SizedBox(height: 26),
            _buildTableSection(),
          ]),
        ),
      ),
    );
  }

  Widget _buildHeader() => Row(children: [
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
      Text('Conexiones', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: kText)),
      SizedBox(height: 3),
      Text('Gestiona y conecta tus maquetas disponibles', style: TextStyle(fontSize: 13, color: kMuted2)),
    ]),
    const Spacer(),



   /*  ElevatedButton.icon(
      style: ElevatedButton.styleFrom(backgroundColor: kBlue,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
      icon: const Icon(Icons.sync, size: 16),
      label: const Text('Escanear red', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      onPressed: () {},
    ),
 */






  ]);

  Widget _buildKpis(int total, int conect, int desc) => Row(children: [
    Expanded(child: _KpiCard(label: 'Maquetas detectadas', value: '$total', sub: 'dispositivos', valueColor: kText)),
    const SizedBox(width: 12),
    Expanded(child: _KpiCard(label: 'Conectadas', value: '$conect', sub: '🟢 online', valueColor: kGreen)),
    const SizedBox(width: 12),
    Expanded(child: _KpiCard(label: 'Desconectadas', value: '$desc', sub: 'offline', valueColor: kRed)),
    const SizedBox(width: 12),
    Expanded(child: _KpiCard(label: 'Último escaneo', value: '10:32 AM', sub: '20/05/2025', valueColor: kText, smallValue: true)),
  ]);

  Widget _buildTableSection() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Text('Maquetas disponibles', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: kText)),
    const SizedBox(height: 14),
    Container(
      decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: kBorder)),
      child: Column(children: [
        _tableHeader(),
        const Divider(height: 1, color: kBorder),
        ListView.separated(
          shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          itemCount: _listaMaquetas.length,
          separatorBuilder: (_, __) => const Divider(height: 1, color: kBorder),
          itemBuilder: (_, i) => _MaquetaRow(
            m: _listaMaquetas[i],
            onAction: () => _toggleEstado(_listaMaquetas[i]), // Pasamos la función al botón
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

// ─── Fila Maqueta ─────────────────────────────────────────────────────────────
class _MaquetaRow extends StatefulWidget {
  final Maqueta m;
  final VoidCallback onAction; // Variable para recibir la acción del clic
  const _MaquetaRow({required this.m, required this.onAction});
  @override State<_MaquetaRow> createState() => _MaquetaRowState();
}

class _MaquetaRowState extends State<_MaquetaRow> {
  bool _hover = false;
  @override
  Widget build(BuildContext context) {
    final m = widget.m;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit:  (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        color: _hover ? const Color(0xFF182336) : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(children: [
          Expanded(flex: 5, child: Row(children: [
            Container(width: 36, height: 36,
                decoration: BoxDecoration(color: const Color(0xFF1A2540), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.memory_outlined, size: 18, color: kMuted2)),
            const SizedBox(width: 10),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(m.nombre, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kText)),
              // Text(m.subtitulo, style: const TextStyle(fontSize: 11, color: kMuted2)),
            ]),
          ])),
          Expanded(flex: 3, child: Text(m.ip, style: const TextStyle(fontSize: 12, color: kMuted2))),
          Expanded(flex: 4, child: Text(m.ssid, style: const TextStyle(fontSize: 12, color: kMuted2))),
          Expanded(flex: 3, child: _StatusBadge(status: m.estado)),
          Expanded(flex: 3, child: _SignalWidget(dbm: m.senal, status: m.estado)),
          Expanded(flex: 2, child: Text(m.latencia, style: const TextStyle(fontSize: 12, color: kMuted2))),
          Expanded(flex: 3, child: Text(m.ultimaConexion, style: const TextStyle(fontSize: 12, color: kMuted2))),
          
          // AQUÍ ELIMINAMOS LOS 3 PUNTOS Y ASIGNAMOS LA FUNCIÓN AL BOTÓN
          Expanded(flex: 3, child: Center(
            child: m.estado == ConStatus.conectado
              ? OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: kText, side: const BorderSide(color: kBorder),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))
                  ),
                  onPressed: widget.onAction, // Ejecuta la función de desconectar
                  child: const Text('Desconectar', style: TextStyle(fontSize: 12)))
              : ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: m.estado == ConStatus.conectando ? kYellow : kBlue,
                    foregroundColor: m.estado == ConStatus.conectando ? Colors.black : Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))
                  ),
                  onPressed: widget.onAction, // Ejecuta la función de conectar
                  child: Text(m.estado == ConStatus.conectando ? 'Conectando' : 'Conectar', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
          )),
        ]),
      ),
    );
  }
}

// ─── Widgets Auxiliares ───────────────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final ConStatus status;
  const _StatusBadge({required this.status});
  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      ConStatus.conectado    => ('Conectado',    kGreen),
      ConStatus.conectando   => ('Conectando',   kYellow),
      ConStatus.desconectado => ('Desconectado', kRed),
    };
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 5),
      Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500)),
    ]);
  }
}

class _SignalWidget extends StatelessWidget {
  final int dbm;
  final ConStatus status;
  const _SignalWidget({required this.dbm, required this.status});
  @override
  Widget build(BuildContext context) {
    if (status == ConStatus.desconectado) return const Text('-', style: TextStyle(fontSize: 12, color: kMuted2));
    final bars = dbm > -50 ? 4 : dbm > -60 ? 3 : dbm > -70 ? 2 : 1;
    return Row(children: [
      Text('$dbm dBm', style: const TextStyle(fontSize: 11, color: kMuted2)),
      const SizedBox(width: 4),
      Row(crossAxisAlignment: CrossAxisAlignment.end, children: List.generate(4, (i) => Container(
        width: 3, height: 4.0 + i * 3, margin: const EdgeInsets.only(right: 1),
        color: i < bars ? kBlue : kMuted,
      ))),
    ]);
  }
}

class _KpiCard extends StatelessWidget {
  final String label, value, sub;
  final Color valueColor;
  final bool smallValue;
  const _KpiCard({required this.label, required this.value, required this.sub, required this.valueColor, this.smallValue = false});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: kBorder)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 12, color: kMuted2)),
      const SizedBox(height: 8),
      Text(value, style: TextStyle(fontSize: smallValue ? 22 : 32, fontWeight: FontWeight.bold, color: valueColor)),
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
  Widget build(BuildContext context) => Text(text, textAlign: center ? TextAlign.center : TextAlign.left,
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kMuted2));
}