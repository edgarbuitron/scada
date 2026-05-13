import 'package:flutter/material.dart';
import 'actividades_recientes.dart';
import 'permisos.dart';

void main() => runApp(const UsuariosApp());

// ─── Paleta ───────────────────────────────────────────────────────────────────
const kBg       = Color(0xFF0D1321);
const kCard     = Color(0xFF131D2E);
const kBorder   = Color(0xFF1E2D45);
const kBlue     = Color(0xFF3B82F6);
const kGreen    = Color(0xFF16A34A);
const kRed      = Color(0xFFDC2626);
const kText     = Color(0xFFE2E8F0);
const kMuted    = Color(0xFF64748B);
const kMuted2   = Color(0xFF8B9CBD);
const kRowHover = Color(0xFF182336);

// ─── Modelo ───────────────────────────────────────────────────────────────────
class Usuario {
  final String id, nombre, numero, correo, rol, ultimoAcceso;
  final bool activo;
  const Usuario({
    required this.id, required this.nombre, required this.numero,
    required this.correo, required this.rol, required this.activo,
    required this.ultimoAcceso,
  });
}

// Lista base (ya no const para poder copiarla en el estado)
final _seedUsers = <Usuario>[
  Usuario(id:'U001',nombre:'Juan Pérez',     numero:'222 123 4567',correo:'juan.perez@tecnm.mx',     rol:'Administrador', activo:true,  ultimoAcceso:'20/05/2025 10:42 AM'),
  Usuario(id:'U002',nombre:'María López',    numero:'222 234 5678',correo:'maria.lopez@tecnm.mx',    rol:'Operador',      activo:true,  ultimoAcceso:'20/05/2025 09:15 AM'),
  Usuario(id:'U003',nombre:'Carlos Ruiz',    numero:'222 345 6789',correo:'carlos.ruiz@tecnm.mx',    rol:'Supervisor',    activo:true,  ultimoAcceso:'19/05/2025 05:30 PM'),
  Usuario(id:'U004',nombre:'Ana Torres',     numero:'222 456 7890',correo:'ana.torres@tecnm.mx',     rol:'Operador',      activo:true,  ultimoAcceso:'20/05/2025 08:20 AM'),
  Usuario(id:'U005',nombre:'Luis Miguel',    numero:'222 567 8901',correo:'luis.miguel@tecnm.mx',    rol:'Mantenimiento', activo:false, ultimoAcceso:'15/05/2025 11:02 AM'),
  Usuario(id:'U006',nombre:'Pedro Sánchez',  numero:'222 678 9012',correo:'pedro.sanchez@tecnm.mx',  rol:'Invitado',      activo:true,  ultimoAcceso:'18/05/2025 02:10 PM'),
  Usuario(id:'U007',nombre:'Sofía Herrera',  numero:'222 789 0123',correo:'sofia.herrera@tecnm.mx',  rol:'Operador',      activo:true,  ultimoAcceso:'20/05/2025 10:10 AM'),
  Usuario(id:'U008',nombre:'Miguel Ángel',   numero:'222 890 1234',correo:'miguel.angel@tecnm.mx',   rol:'Supervisor',    activo:false, ultimoAcceso:'10/05/2025 04:45 PM'),
  Usuario(id:'U009',nombre:'Laura Castro',   numero:'222 901 2345',correo:'laura.castro@tecnm.mx',   rol:'Operador',      activo:true,  ultimoAcceso:'20/05/2025 07:55 AM'),
  Usuario(id:'U010',nombre:'Diego Flores',   numero:'222 012 3456',correo:'diego.flores@tecnm.mx',   rol:'Administrador', activo:true,  ultimoAcceso:'20/05/2025 11:30 AM'),
  Usuario(id:'U011',nombre:'Carmen Vega',    numero:'222 111 2233',correo:'carmen.vega@tecnm.mx',    rol:'Supervisor',    activo:true,  ultimoAcceso:'19/05/2025 03:20 PM'),
  Usuario(id:'U012',nombre:'Roberto Mora',   numero:'222 222 3344',correo:'roberto.mora@tecnm.mx',   rol:'Operador',      activo:false, ultimoAcceso:'12/05/2025 09:00 AM'),
  Usuario(id:'U013',nombre:'Elena Ríos',     numero:'222 333 4455',correo:'elena.rios@tecnm.mx',     rol:'Invitado',      activo:true,  ultimoAcceso:'17/05/2025 04:40 PM'),
  Usuario(id:'U014',nombre:'Héctor Ponce',   numero:'222 444 5566',correo:'hector.ponce@tecnm.mx',   rol:'Mantenimiento', activo:true,  ultimoAcceso:'20/05/2025 08:00 AM'),
  Usuario(id:'U015',nombre:'Patricia Leal',  numero:'222 555 6677',correo:'patricia.leal@tecnm.mx',  rol:'Administrador', activo:true,  ultimoAcceso:'20/05/2025 10:55 AM'),
  Usuario(id:'U016',nombre:'Fernando Gil',   numero:'222 666 7788',correo:'fernando.gil@tecnm.mx',   rol:'Operador',      activo:true,  ultimoAcceso:'20/05/2025 07:30 AM'),
  Usuario(id:'U017',nombre:'Nora Salas',     numero:'222 777 8899',correo:'nora.salas@tecnm.mx',     rol:'Supervisor',    activo:false, ultimoAcceso:'08/05/2025 01:15 PM'),
  Usuario(id:'U018',nombre:'Andrés Meraz',   numero:'222 888 9900',correo:'andres.meraz@tecnm.mx',   rol:'Operador',      activo:true,  ultimoAcceso:'19/05/2025 06:10 PM'),
  Usuario(id:'U019',nombre:'Silvia Paredes', numero:'222 999 0011',correo:'silvia.paredes@tecnm.mx', rol:'Invitado',      activo:true,  ultimoAcceso:'16/05/2025 03:50 PM'),
  Usuario(id:'U020',nombre:'Tomás Ibarra',   numero:'222 101 1122',correo:'tomas.ibarra@tecnm.mx',   rol:'Mantenimiento', activo:true,  ultimoAcceso:'20/05/2025 09:45 AM'),
  Usuario(id:'U021',nombre:'Claudia Reyes',  numero:'222 202 2233',correo:'claudia.reyes@tecnm.mx',  rol:'Operador',      activo:true,  ultimoAcceso:'18/05/2025 11:20 AM'),
  Usuario(id:'U022',nombre:'Marcos Ávila',   numero:'222 303 3344',correo:'marcos.avila@tecnm.mx',   rol:'Supervisor',    activo:true,  ultimoAcceso:'20/05/2025 08:40 AM'),
  Usuario(id:'U023',nombre:'Isabel Quiroz',  numero:'222 404 4455',correo:'isabel.quiroz@tecnm.mx',  rol:'Administrador', activo:true,  ultimoAcceso:'20/05/2025 10:05 AM'),
  Usuario(id:'U024',nombre:'Samuel Garza',   numero:'222 505 5566',correo:'samuel.garza@tecnm.mx',   rol:'Operador',      activo:false, ultimoAcceso:'05/05/2025 02:30 PM'),
];

// ═════════════════════════════════════════════════════════════════════════════
class UsuariosApp extends StatelessWidget {
  const UsuariosApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Usuarios SCADA',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: kBg,
          fontFamily: 'Roboto',
        ),
        home: const UsuariosScreen(),
      );
}

// ═════════════════════════════════════════════════════════════════════════════
class UsuariosScreen extends StatefulWidget {
  const UsuariosScreen({super.key});
  @override
  State<UsuariosScreen> createState() => _UsuariosScreenState();
}

class _UsuariosScreenState extends State<UsuariosScreen> {
  // ── Lista mutable de usuarios (copiada desde _seedUsers) ──────────────────
  late List<Usuario> _users;

  final _searchCtrl = TextEditingController();
  String _query = '';
  int _page     = 1;
  static const _perPage = 8;

  @override
  void initState() {
    super.initState();
    _users = List<Usuario>.from(_seedUsers);
  }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  List<Usuario> get _filtered {
    if (_query.isEmpty) return _users;
    final q = _query.toLowerCase();
    return _users.where((u) =>
        u.nombre.toLowerCase().contains(q) ||
        u.correo.toLowerCase().contains(q) ||
        u.rol.toLowerCase().contains(q) ||
        u.id.toLowerCase().contains(q)).toList();
  }

  int get _totalPages => (_filtered.length / _perPage).ceil().clamp(1, 999);

  List<Usuario> get _pageUsers {
    final start = (_page - 1) * _perPage;
    final end   = (start + _perPage).clamp(0, _filtered.length);
    return _filtered.sublist(start, end);
  }

  // ── KPIs reactivos ─────────────────────────────────────────────────────────
  int get _totalU  => _users.length;
  int get _activeU => _users.where((u) => u.activo).length;
  int get _inactU  => _users.where((u) => !u.activo).length;
  int get _adminU  => _users.where((u) => u.rol == 'Administrador').length;

  // ── Eliminar usuario con diálogo de confirmación ──────────────────────────
  void _onDeleteTap(Usuario user) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.65),
      builder: (_) => _DeleteConfirmDialog(
        user: user,
        onConfirm: () {
          setState(() {
            _users.removeWhere((u) => u.id == user.id);
            // Ajusta la página si queda vacía tras eliminar
            final maxPage = (_filtered.length / _perPage).ceil().clamp(1, 999);
            if (_page > maxPage) _page = maxPage;
          });
        },
      ),
    );
  }

  // ── build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,





      body: SafeArea(
  child: SingleChildScrollView(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          //_buildHeader(),
          const SizedBox(height: 22),
          _buildKpiRow(),
          const SizedBox(height: 22),

         SizedBox(
  height: 520,
  child: _buildTable(),
),

          const SizedBox(height: 14),
          _buildPagination(),
            ],
          ),
        ),
      ),
      )
    );
  }













/*   // ── Header ─────────────────────────────────────────────────────────────────
  Widget _buildHeader() => Row(
    children: [
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
        Text('Usuarios',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: kText)),
        SizedBox(height: 3),
        Text('Gestión de usuarios del sistema SCADA',
            style: TextStyle(fontSize: 13, color: kMuted2)),
      ]),
      const Spacer(), */

/*       // Buscador
      SizedBox(
        width: 240, height: 40,
        child: TextField(
          controller: _searchCtrl,
          onChanged: (v) => setState(() { _query = v; _page = 1; }),
          style: const TextStyle(fontSize: 13, color: kText),
          decoration: InputDecoration(
            hintText: 'Buscar usuario...',
            hintStyle: const TextStyle(fontSize: 13, color: kMuted),
            prefixIcon: const Icon(Icons.search, color: kMuted, size: 18),
            filled: true,
            fillColor: kCard,
            contentPadding: EdgeInsets.zero,
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: kBorder)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: kBlue)),
          ),
        ),
      ),
      const SizedBox(width: 12),

      // Botón nuevo usuario
      ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: kBlue,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        icon: const Icon(Icons.add, size: 18),
        label: const Text('Nuevo usuario',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        onPressed: () {},
      ),
    ],
  );


 */









  // ── KPI cards ──────────────────────────────────────────────────────────────
  Widget _buildKpiRow() => Row(children: [
    Expanded(child: _KpiCard(label: 'Total usuarios',  value: '$_totalU', sub: 'usuarios registrados')),
    const SizedBox(width: 14),
    Expanded(child: _KpiCard(label: 'Activos',         value: '$_activeU', sub: 'usuarios activos')),
    const SizedBox(width: 14),
    Expanded(child: _KpiCard(label: 'Inactivos',       value: '$_inactU', sub: 'usuarios inactivos')),
    const SizedBox(width: 14),
    Expanded(child: _KpiCard(label: 'Administradores', value: '$_adminU', sub: 'con permisos de admin')),
  ]);




















  // ── Tabla ──────────────────────────────────────────────────────────────────
Widget _buildTable() => Container(
  decoration: BoxDecoration(
    color: kCard,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: kBorder),
  ),
  child: SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: SizedBox(
      width: 1250,
      child: Column(
        children: [
          const _TableHeader(),
          const Divider(height: 1, color: kBorder),

          Expanded(
            child: ListView.separated(
              itemCount: _pageUsers.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: kBorder),
              itemBuilder: (_, i) => _UserRow(
                user: _pageUsers[i],
                onDelete: () => _onDeleteTap(_pageUsers[i]),
              ),
            ),
          ),
        ],
      ),
    ),
  ),
);














  // ── Paginación ─────────────────────────────────────────────────────────────
  Widget _buildPagination() {
    final total = _filtered.length;
    final start = (_page - 1) * _perPage + 1;
    final end   = ((_page - 1) * _perPage + _perPage).clamp(0, total);

    List<Widget> pageButtons = [];
    const maxVisible = 3;
    for (int p = 1; p <= _totalPages && p <= maxVisible; p++) {
      pageButtons.add(Padding(
        padding: const EdgeInsets.only(right: 6),
        child: _PageNumBtn(
          number: p, selected: _page == p,
          onTap: () => setState(() => _page = p),
        ),
      ));
    }
    if (_totalPages > maxVisible) {
      pageButtons.add(const Padding(
        padding: EdgeInsets.only(right: 6),
        child: SizedBox(width: 24,
            child: Center(child: Text('...', style: TextStyle(color: kMuted2)))),
      ));
    }

    return Row(children: [
      Text('Mostrando $start a $end de $total usuarios',
          style: const TextStyle(fontSize: 13, color: kMuted2)),
      const Spacer(),
      _PageBtn(icon: Icons.chevron_left,
          onTap: _page > 1 ? () => setState(() => _page--) : null),
      const SizedBox(width: 6),
      ...pageButtons,
      _PageBtn(icon: Icons.chevron_right,
          onTap: _page < _totalPages ? () => setState(() => _page++) : null),
    ]);
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// DIÁLOGO DE CONFIRMACIÓN DE ELIMINACIÓN
// ═════════════════════════════════════════════════════════════════════════════
class _DeleteConfirmDialog extends StatelessWidget {
  final Usuario user;
  final VoidCallback onConfirm;

  const _DeleteConfirmDialog({
    required this.user,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      child: Container(
        width: 460,
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: kBorder, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 32,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Encabezado ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Row(
                children: [
                  Container(
                    width: 42, height: 42,
                    decoration: BoxDecoration(
                      color: kRed.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: kRed.withOpacity(0.35)),
                    ),
                    child: const Icon(Icons.delete_forever_rounded,
                        color: kRed, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          '¿Eliminar usuario?',
                          style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: kText),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Esta acción es permanente y no se puede deshacer.',
                          style: TextStyle(fontSize: 12, color: kMuted2),
                        ),
                      ],
                    ),
                  ),
                  // Botón cerrar
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 30, height: 30,
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.close, color: kMuted2, size: 18),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            const Divider(height: 1, color: kBorder),
            const SizedBox(height: 20),

            // ── Datos del usuario ───────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: kBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: kBorder),
                ),
                child: Column(
                  children: [
                    _InfoRow(icon: Icons.person_outline,     label: 'Nombre', value: user.nombre),
                    const SizedBox(height: 12),
                    _InfoRow(icon: Icons.tag,                label: 'ID',     value: user.id),
                    const SizedBox(height: 12),
                    _InfoRow(icon: Icons.email_outlined,     label: 'Correo', value: user.correo),
                    const SizedBox(height: 12),
                    _InfoRow(icon: Icons.shield_outlined,    label: 'Rol',    value: user.rol),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ── Botones ─────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Row(
                children: [
                  // Cancelar
                  Expanded(
                    child: SizedBox(
                      height: 42,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: kText,
                          side: const BorderSide(color: kBorder),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancelar',
                            style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Eliminar
                  Expanded(
                    child: SizedBox(
                      height: 42,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kRed,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.delete_outline, size: 18),
                        label: const Text('Eliminar',
                            style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w600)),
                        onPressed: () {
                          Navigator.of(context).pop();
                          onConfirm();
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Fila de información dentro del diálogo ────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: kMuted2),
        const SizedBox(width: 8),
        SizedBox(
          width: 54,
          child: Text(label,
              style: const TextStyle(fontSize: 12, color: kMuted2)),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: kText),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ─── KPI Card ─────────────────────────────────────────────────────────────────
class _KpiCard extends StatelessWidget {
  final String label, value, sub;
  const _KpiCard({required this.label, required this.value, required this.sub});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kBorder),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 13, color: kMuted2)),
          const SizedBox(height: 8),
          Text(value,
              style: const TextStyle(
                  fontSize: 36, fontWeight: FontWeight.bold, color: kText)),
          const SizedBox(height: 4),
          Text(sub, style: const TextStyle(fontSize: 12, color: kMuted)),
        ]),
      );
}













// ─── Encabezado tabla ─────────────────────────────────────────────────────────
class _TableHeader extends StatelessWidget {
  const _TableHeader();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 13,
        ),
        child: Row(
          children: const [
            _TH('ID', flex: 2),
            _TH('Nombre', flex: 4),
            _TH('Número', flex: 4),
            _TH('Correo', flex: 6),
            _TH('Rol', flex: 4),
            _TH('Estado', flex: 3),
            _TH('Último acceso', flex: 5),
            _TH('Acciones', flex: 4, align: TextAlign.center),
          ],
        ),
      );
}








class _TH extends StatelessWidget {
  final String text;
  final int flex;
  final TextAlign align;
  const _TH(this.text, {required this.flex, this.align = TextAlign.left});

  @override
  Widget build(BuildContext context) => Expanded(
        flex: flex,
        child: Text(text, textAlign: align,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600, color: kMuted2)),
      );
}







// ─── Fila usuario ─────────────────────────────────────────────────────────────
class _UserRow extends StatefulWidget {
  final Usuario user;
  final VoidCallback onDelete; // ← nuevo parámetro
  const _UserRow({required this.user, required this.onDelete});
  @override
  State<_UserRow> createState() => _UserRowState();
}

class _UserRowState extends State<_UserRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final u = widget.user;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit:  (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        color: _hover ? kRowHover : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          // ID
          Expanded(flex: 2,
              child: Text(u.id,
                  style: const TextStyle(fontSize: 13, color: kMuted2))),
          // Nombre
          Expanded(flex: 4,
              child: Text(u.nombre,
                  style: const TextStyle(
                      fontSize: 13, color: kText, fontWeight: FontWeight.w500))),
          // Número
          Expanded(flex: 4,
              child: Text(u.numero,
                  style: const TextStyle(fontSize: 13, color: kText))),
          // Correo
          Expanded(flex: 6,
              child: Text(u.correo,
                  style: const TextStyle(fontSize: 13, color: kText))),
          // Rol
          Expanded(flex: 4,
              child: Text(u.rol,
                  style: const TextStyle(fontSize: 13, color: kText))),
          // Estado
          Expanded(flex: 3, child: _StatusBadge(active: u.activo)),
          // Último acceso
          Expanded(flex: 5,
              child: Text(u.ultimoAcceso,
                  style: const TextStyle(fontSize: 12, color: kMuted2))),
         
         




         
         
         
          // Acciones
Expanded(
  flex: 4,
  child: Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      // Editar
      _ActionBtn(
        icon: Icons.edit_outlined,
        color: kBlue,
        onTap: () {},
      ),
      const SizedBox(width: 6),

      // Eliminar
      _ActionBtn(
        icon: Icons.delete_outline,
        color: kRed,
        onTap: widget.onDelete,
      ),
      const SizedBox(width: 6),

      // Actividades de usuario
 _ActionBtn(
  icon: Icons.event_note,
  color: Colors.orange,
  onTap: () {
    showDialog(
      context: context,
      barrierDismissible: true, // cerrar al tocar fuera
      barrierColor: Colors.black.withOpacity(0.65),
      builder: (_) => const ActividadesScreen(),
    );
  },
),

      const SizedBox(width: 6),





      // Permisos de usuario
      _ActionBtn(
  icon: Icons.manage_accounts,
  color: Colors.purple,
  onTap: () {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.65),
      builder: (_) => const PermisosScreen(),
    );
  },
),




    ],
  ),
),









        ]),
      ),
    );
  }
}

// ─── Badge estado ─────────────────────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final bool active;
  const _StatusBadge({required this.active});

  @override
  Widget build(BuildContext context) => FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: active
                ? kGreen.withOpacity(.2)
                : kRed.withOpacity(.2),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            active ? 'Activo' : 'Inactivo',
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600,
                color: active ? kGreen : kRed),
          ),
        ),
      );
}

// ─── Botón acción ─────────────────────────────────────────────────────────────
class _ActionBtn extends StatefulWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn({required this.icon, required this.color, required this.onTap});
  @override
  State<_ActionBtn> createState() => _ActionBtnState();
}

class _ActionBtnState extends State<_ActionBtn> {
  bool _hover = false;
  @override
  Widget build(BuildContext context) => MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit:  (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            width: 30, height: 30,
            decoration: BoxDecoration(
              color: _hover ? widget.color.withOpacity(.18) : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                  color: _hover ? widget.color.withOpacity(.4) : Colors.transparent),
            ),
            child: Icon(widget.icon, size: 16, color: widget.color),
          ),
        ),
      );
}

// ─── Botón paginación (flecha) ────────────────────────────────────────────────
class _PageBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _PageBtn({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 34, height: 34,
          decoration: BoxDecoration(
            color: kCard,
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: kBorder),
          ),
          child: Icon(icon, size: 18,
              color: onTap != null ? kText : kMuted),
        ),
      );
}

// ─── Botón paginación (número) ────────────────────────────────────────────────
class _PageNumBtn extends StatelessWidget {
  final int number;
  final bool selected;
  final VoidCallback onTap;
  const _PageNumBtn(
      {required this.number, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 34, height: 34,
          decoration: BoxDecoration(
            color: selected ? kBlue : kCard,
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: selected ? kBlue : kBorder),
          ),
          child: Center(
            child: Text('$number',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : kText)),
          ),
        ),
      );
}