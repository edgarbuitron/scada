import 'package:flutter/material.dart';
import 'usuarios.dart' show Usuario;

// ─── Paleta ───────────────────────────────────────────────────────────────────
const kBg = Color(0xFF0D1321);
const kCard = Color(0xFF131D2E);
const kBorder = Color(0xFF1E2D45);
const kText = Color(0xFFE2E8F0);
const kMuted = Color(0xFF8B9CBD);

// ─── Modelo Interno ──────────────────────────────────────────────────────────
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

// ═════════════════════════════════════════════════════════════════════════════
class ActividadesScreen extends StatelessWidget {
  final Usuario user;
  const ActividadesScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Material(
        color: Colors.transparent,
        child: Center(
          child: GestureDetector(
            onTap: () {},
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 650,
                maxHeight: 450,
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: ActividadesCard(user: user),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ActividadesCard extends StatelessWidget {
  final Usuario user;
  const ActividadesCard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    // Generamos las actividades dinámicamente basadas en el usuario real
    final List<Actividad> acts = [
      Actividad(
        titulo: 'Inicio de sesión',
        descripcion: 'El usuario inició sesión en el sistema',
        fecha: user.ultimoAcceso.isNotEmpty ? user.ultimoAcceso : 'Sin datos de fecha',
        icon: Icons.login_rounded,
        color: const Color(0xFF3B82F6),
      ),
      Actividad(
        titulo: 'Generó reporte',
        descripcion: 'Generó el reporte de producción en PDF',
        fecha: 'Sin datos de fecha', // Simulado por ahora hasta tener log de reportes en Firestore
        icon: Icons.description_outlined,
        color: const Color(0xFFA855F7),
      ),
      Actividad(
        titulo: 'Exportó datos',
        descripcion: 'Exportó datos de sensores a Excel',
        fecha: 'Sin datos de fecha', // Simulado por ahora hasta tener log de exportación en Firestore
        icon: Icons.insert_drive_file_outlined,
        color: const Color(0xFFF59E0B),
      ),
    ];

    return Container(
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: kBorder),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Actividades recientes',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: kText),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Usuario: ${user.nombre}',
                    style: const TextStyle(fontSize: 12, color: kMuted),
                  ),
                ],
              ),
            ),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: acts.length,
                separatorBuilder: (_, __) => const Divider(
                  height: 1,
                  color: kBorder,
                  indent: 20,
                  endIndent: 20,
                ),
                itemBuilder: (_, i) => _ActividadTile(act: acts[i]),
              ),
            ),
            const SizedBox(height: 15),
          ],
        ));
  }
}

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
    final bool hasData = a.fecha != 'Sin datos de fecha';

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        color: _hover ? const Color(0xFF182336) : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: a.color.withValues(alpha: .15),
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  a.fecha,
                  style: TextStyle(
                    fontSize: 12,
                    color: hasData ? kText : kMuted,
                    fontWeight: hasData ? FontWeight.w500 : FontWeight.normal,
                    fontStyle: hasData ? FontStyle.normal : FontStyle.italic,
                  ),
                ),
                if (hasData && a.titulo != 'Inicio de sesión')
                  const Text(
                    '1 vez',
                    style: TextStyle(fontSize: 10, color: kMuted),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
