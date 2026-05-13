import 'package:flutter/material.dart';

//void main() => runApp(const ActividadesApp());

// ─── Paleta ───────────────────────────────────────────────────────────────────
const kBg = Color(0xFF0D1321);
const kCard = Color(0xFF131D2E);
const kBorder = Color(0xFF1E2D45);
const kText = Color(0xFFE2E8F0);
const kMuted = Color(0xFF8B9CBD);

// ─── Modelo ───────────────────────────────────────────────────────────────────
class Actividad {
  final String titulo, descripcion, fecha;
  final IconData icon;
  final Color color;

  const Actividad({
    required this.titulo,
    required this.descripcion,
    required this.fecha,
    required this.icon,
    required this.color,
  });
}

const _actividades = [
Actividad(
  titulo: 'Inicio de sesión',
  descripcion: 'El usuario inició sesión en el sistema',
  fecha: '19/05/2025 05:28 PM',
  icon: Icons.login_rounded,
  color: Color(0xFF3B82F6),
),
  Actividad(
    titulo: 'Cambio de configuración',
    descripcion: 'Actualizó la configuración de alarmas',
    fecha: '20/05/2025 09:15 AM',
    icon: Icons.settings_outlined,
    color: Color(0xFF22C55E),
  ),
  Actividad(
    titulo: 'Generó reporte',
    descripcion: 'Generó el reporte de producción en PDF',
    fecha: '20/05/2025 08:50 AM',
    icon: Icons.description_outlined,
    color: Color(0xFFA855F7),
  ),
  Actividad(
    titulo: 'Exportó datos',
    descripcion: 'Exportó datos de sensores a Excel',
    fecha: '19/05/2025 05:30 PM',
    icon: Icons.insert_drive_file_outlined,
    color: Color(0xFFF59E0B),
  ),
  Actividad(
    titulo: 'Cierre de sesión',
    descripcion: 'El usuario salió del sistema correctamente',
    fecha: '19/05/2025 05:28 PM',
    icon: Icons.logout_rounded,
    color: Color(0xFFEF4444),
  ),
];

// ═════════════════════════════════════════════════════════════════════════════
class ActividadesApp extends StatelessWidget {
  const ActividadesApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Actividades Recientes',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: kBg,
        ),
        home: const ActividadesScreen(),
      );
}






class ActividadesScreen extends StatelessWidget {
  const ActividadesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pop(context), // cerrar al tocar afuera
      child: Material(
        color: Colors.transparent,
        child: Center(
          child: GestureDetector(
            onTap: () {}, // evita cerrar al tocar dentro
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 650,
                maxHeight: 500,
              ),
              child: const Padding(
                padding: EdgeInsets.all(20),
                child: ActividadesCard(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}








// ─── Widget principal ────────────────────────────────────────────────────────
class ActividadesCard extends StatelessWidget {
  const ActividadesCard({super.key});

  @override
  Widget build(BuildContext context) {





    return Container(
  decoration: BoxDecoration(
    color: kCard,
    borderRadius: BorderRadius.circular(14),
    border: Border.all(color: kBorder),
  ),
  child: SingleChildScrollView(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Text(
            'Actividades recientes',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: kText,
            ),
          ),
        ),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _actividades.length,
          separatorBuilder: (_, __) => const Divider(
            height: 1,
            color: kBorder,
            indent: 20,
            endIndent: 20,
          ),
          itemBuilder: (_, i) => _ActividadTile(act: _actividades[i]),
        ),
        const SizedBox(height: 10),
      ],
    ),
  )
  );
  }
  }












// ─── Fila actividad ──────────────────────────────────────────────────────────
class _ActividadTile extends StatefulWidget {
  final Actividad act;
  const _ActividadTile({required this.act});

  @override
  State<_ActividadTile> createState() => _ActividadTileState();
}

class _ActividadTileState extends State<_ActividadTile> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final a = widget.act;

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        color: _hover ? const Color(0xFF182336) : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: a.color.withOpacity(.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(a.icon, color: a.color, size: 20),
            ),
            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    a.titulo,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: kText,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    a.descripcion,
                    style: const TextStyle(
                      fontSize: 12,
                      color: kMuted,
                    ),
                  ),
                ],
              ),
            ),

            Text(
              a.fecha,
              style: const TextStyle(
                fontSize: 12,
                color: kMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}