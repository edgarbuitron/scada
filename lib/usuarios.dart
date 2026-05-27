import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'actividades_recientes.dart';
import 'permisos.dart';
import 'package:intl/intl.dart';

void main() => runApp(const UsuariosApp());

// ─── Paleta ───────────────────────────────────────────────────────────────────
const kBg = Color(0xFF0D1321);
const kCard = Color(0xFF131D2E);
const kBorder = Color(0xFF1E2D45);
const kBlue = Color(0xFF3B82F6);
const kGreen = Color(0xFF16A34A);
const kRed = Color(0xFFDC2626);
const kText = Color(0xFFE2E8F0);
const kMuted = Color(0xFF64748B);
const kMuted2 = Color(0xFF8B9CBD);
const kRowHover = Color(0xFF182336);

// ─── Modelo ───────────────────────────────────────────────────────────────────
class Usuario {
  final String id;
  final String nombre;
  final String passwordHash;
  final String numero;
  final String correo;
  final String rol;
  final String ultimoAcceso;
  final String fechaRegistro;
  final String numeroControl;
  final int semestre;
  final bool activo;

  Usuario({
    required this.id,
    required this.nombre,
    required this.passwordHash,
    required this.numero,
    required this.correo,
    required this.rol,
    required this.activo,
    required this.ultimoAcceso,
    required this.semestre,
    required this.fechaRegistro,
    required this.numeroControl,
  });

  factory Usuario.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Usuario(
      id: doc.id,
      nombre: data['nombre'] ?? '',
      passwordHash: data['passwordHash'] ?? '',
      numero: data['numero'] ?? '',
      correo: data['correo'] ?? '',
      rol: data['rol'] ?? '',
      activo: data['activo'] ?? false,
      ultimoAcceso: data['ultimoAcceso'] ?? '',
      semestre: data['semestre'] ?? 0,
      fechaRegistro: data['fechaRegistro'] ?? '',
      numeroControl: data['numeroControl'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'passwordHash': passwordHash,
      'numero': numero,
      'correo': correo,
      'rol': rol,
      'activo': activo,
      'ultimoAcceso': ultimoAcceso,
      'semestre': semestre,
      'fechaRegistro': fechaRegistro,
      'numeroControl': numeroControl,
    };
  }
}

// ─── App ───────────────────────────────────────────────────────────────────────
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
  // Filtros de texto
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _controlController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _semestreController = TextEditingController();

  // Filtros de fecha
  DateTime? _fechaRegistro;
  DateTime? _ultimoAcceso;

  // Filtro de Rol
  String _selectedRol = 'Todos';

  @override
  void initState() {
    super.initState();
    _nameController.addListener(() => setState(() {}));
    _controlController.addListener(() => setState(() {}));
    _phoneController.addListener(() => setState(() {}));
    _emailController.addListener(() => setState(() {}));
    _semestreController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _controlController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _semestreController.dispose();
    super.dispose();
  }

  void _onDeleteTap(String userId) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (_) => AlertDialog(
        backgroundColor: kCard,
        title: const Text('¿Eliminar usuario?', style: TextStyle(color: kText)),
        content: const Text('Esta acción es permanente y no se puede deshacer.',
            style: TextStyle(color: kMuted2)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar', style: TextStyle(color: kText)),
          ),
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('usuarios')
                  .doc(userId)
                  .delete();
              if (!mounted) return;
              Navigator.of(context).pop();
            },
            child: const Text('Eliminar', style: TextStyle(color: kRed)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('usuarios').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final allUsers = snapshot.hasData
                ? snapshot.data!.docs
                    .map((doc) => Usuario.fromFirestore(doc))
                    .toList()
                : <Usuario>[];

            final filteredUsers = allUsers.where((u) {
              final matchesName = u.nombre.toLowerCase().contains(_nameController.text.toLowerCase());
              final matchesControl = u.numeroControl.contains(_controlController.text);
              final matchesPhone = u.numero.contains(_phoneController.text);
              final matchesEmail = u.correo.toLowerCase().contains(_emailController.text.toLowerCase());
              final matchesSemestre = _semestreController.text.isEmpty || u.semestre.toString() == _semestreController.text;
              final matchesRol = _selectedRol == 'Todos' || u.rol == _selectedRol;

              bool matchesFechaReg = true;
              if (_fechaRegistro != null) {
                try {
                  final regDate = DateFormat('dd/MM/yyyy').parse(u.fechaRegistro.split(' ')[0]);
                  matchesFechaReg = regDate.year == _fechaRegistro!.year &&
                                   regDate.month == _fechaRegistro!.month &&
                                   regDate.day == _fechaRegistro!.day;
                } catch (_) {
                  matchesFechaReg = false;
                }
              }

              bool matchesUltimoAcc = true;
              if (_ultimoAcceso != null) {
                try {
                  final accDate = DateFormat('dd/MM/yyyy').parse(u.ultimoAcceso.split(' ')[0]);
                  matchesUltimoAcc = accDate.year == _ultimoAcceso!.year &&
                                    accDate.month == _ultimoAcceso!.month &&
                                    accDate.day == _ultimoAcceso!.day;
                } catch (_) {
                  matchesUltimoAcc = false;
                }
              }

              return matchesName && matchesControl && matchesPhone && 
                     matchesEmail && matchesSemestre && matchesRol && 
                     matchesFechaReg && matchesUltimoAcc;
            }).toList();

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(allUsers),
                  const SizedBox(height: 24),
                  _buildFilterSection(),
                  const SizedBox(height: 22),
                  _buildTable(filteredUsers),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(List<Usuario> users) {
    final total = users.length;
    final activos = users.where((u) => u.activo).length;
    final inactivos = total - activos;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Gestión de Usuarios',
          style: TextStyle(
              fontSize: 24, fontWeight: FontWeight.bold, color: kText),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            _buildStatCard('Total', total.toString(), kBlue),
            const SizedBox(width: 16),
            _buildStatCard('Activos', activos.toString(), kGreen),
            const SizedBox(width: 16),
            _buildStatCard('Inactivos', inactivos.toString(), kRed),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: kMuted2, fontSize: 13)),
            const SizedBox(height: 8),
            Text(value,
                style: TextStyle(
                    color: color, fontSize: 22, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Filtros Avanzados', 
            style: TextStyle(color: kMuted2, fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          // Primera fila: Nombre y Control
          Row(
            children: [
              Expanded(child: _buildTextField(_nameController, 'Nombre', Icons.person)),
              const SizedBox(width: 12),
              Expanded(child: _buildTextField(_controlController, 'N° Control', Icons.badge)),
            ],
          ),
          const SizedBox(height: 12),
          // Segunda fila: Teléfono y Correo
          Row(
            children: [
              Expanded(child: _buildTextField(_phoneController, 'Teléfono', Icons.phone)),
              const SizedBox(width: 12),
              Expanded(child: _buildTextField(_emailController, 'Correo', Icons.email)),
            ],
          ),
          const SizedBox(height: 12),
          // Tercera fila: Semestre y Rol
          Row(
            children: [
              Expanded(child: _buildTextField(_semestreController, 'Semestre', Icons.school, isNumber: true)),
              const SizedBox(width: 12),
              Expanded(child: _buildRoleDropdown()),
            ],
          ),
          const SizedBox(height: 12),
          // Cuarta fila: Fechas
          Row(
            children: [
              Expanded(child: _buildDatePicker('Fecha Registro', _fechaRegistro, (d) => setState(() => _fechaRegistro = d))),
              const SizedBox(width: 12),
              Expanded(child: _buildDatePicker('Último Acceso', _ultimoAcceso, (d) => setState(() => _ultimoAcceso = d))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon, {bool isNumber = false}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: const TextStyle(color: kText, fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: kMuted, fontSize: 12),
        prefixIcon: Icon(icon, color: kMuted, size: 18),
        suffixIcon: controller.text.isNotEmpty 
          ? IconButton(
              icon: const Icon(Icons.refresh, size: 16, color: kBlue),
              onPressed: () => controller.clear(),
            )
          : null,
        filled: true,
        fillColor: kBg,
        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: kBorder)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: kBorder)),
      ),
    );
  }

  Widget _buildRoleDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: kBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: kBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedRol,
          dropdownColor: kCard,
          style: const TextStyle(color: kText, fontSize: 13),
          icon: const Icon(Icons.filter_list, color: kMuted, size: 18),
          isExpanded: true,
          items: ['Todos', 'Administrador', 'Ingeniero', 'Operador']
              .map((rol) => DropdownMenuItem(value: rol, child: Text(rol)))
              .toList(),
          onChanged: (val) => setState(() => _selectedRol = val!),
        ),
      ),
    );
  }

  Widget _buildDatePicker(String label, DateTime? selected, Function(DateTime?) onSelect) {
    return GestureDetector(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: selected ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (date != null) onSelect(date);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: kBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: kBorder),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: kMuted, size: 16),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                selected == null ? label : DateFormat('dd/MM/yyyy').format(selected),
                style: TextStyle(color: selected == null ? kMuted : kText, fontSize: 12),
              ),
            ),
            if (selected != null)
              IconButton(
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.refresh, size: 16, color: kBlue),
                onPressed: () => onSelect(null),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTable(List<Usuario> users) => Container(
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kBorder),
        ),
        child: users.isEmpty
            ? const SizedBox(
                height: 200,
                child: Center(
                  child: Text(
                    'No se encontraron usuarios con los filtros aplicados.',
                    style: TextStyle(fontSize: 14, color: kMuted2),
                  ),
                ),
              )
            : SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: 1400,
                  height: 520,
                  child: Column(
                    children: [
                      const _TableHeader(),
                      const Divider(height: 1, color: kBorder),
                      Expanded(
                        child: ListView.separated(
                          itemCount: users.length,
                          separatorBuilder: (_, __) =>
                              const Divider(height: 1, color: kBorder),
                          itemBuilder: (_, i) => _UserRow(
                            user: users[i],
                            onDelete: () => _onDeleteTap(users[i].id),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      );
}

class _TableHeader extends StatelessWidget {
  const _TableHeader();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: const Row(
          children: [
            _TH('ID', flex: 2),
            _TH('Nombre', flex: 4),
            _TH('Contraseña', flex: 4),
            _TH('N° Control', flex: 4),
            _TH('Número', flex: 4),
            _TH('Correo', flex: 6),
            _TH('Semestre', flex: 3),
            _TH('Fecha Registro', flex: 4),
            _TH('Último acceso', flex: 5),
            _TH('Estado', flex: 3),
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
        child: Text(text,
            textAlign: align,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600, color: kMuted2)),
      );
}

class _UserRow extends StatefulWidget {
  final Usuario user;
  final VoidCallback onDelete;
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
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        color: _hover ? kRowHover : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          Expanded(
              flex: 2,
              child: Text(u.id,
                  style: const TextStyle(fontSize: 13, color: kMuted2))),
          Expanded(
              flex: 4,
              child: Text(u.nombre,
                  style: const TextStyle(
                      fontSize: 13, color: kText, fontWeight: FontWeight.w500))),
          const Expanded(
              flex: 4,
              child: Text('********',
                  style: TextStyle(fontSize: 13, color: kText))),
          Expanded(
              flex: 4,
              child: Text(u.numeroControl,
                  style: const TextStyle(fontSize: 13, color: kText))),
          Expanded(
              flex: 4,
              child: Text(u.numero,
                  style: const TextStyle(fontSize: 13, color: kText))),
          Expanded(
              flex: 6,
              child: Text(u.correo,
                  style: const TextStyle(fontSize: 13, color: kText))),
          Expanded(
              flex: 3,
              child: Text(u.semestre.toString(),
                  style: const TextStyle(fontSize: 13, color: kText))),
          Expanded(
              flex: 4,
              child: Text(u.fechaRegistro,
                  style: const TextStyle(fontSize: 13, color: kText))),
          Expanded(
              flex: 5,
              child: Text(u.ultimoAcceso,
                  style: const TextStyle(fontSize: 12, color: kMuted2))),
          Expanded(flex: 3, child: _StatusBadge(active: u.activo)),
          Expanded(
            flex: 4,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _ActionBtn(
                  icon: Icons.delete_outline,
                  color: kRed,
                  onTap: widget.onDelete,
                ),
                const SizedBox(width: 6),
                _ActionBtn(
                  icon: Icons.event_note,
                  color: Colors.orange,
                  onTap: () {
                    showDialog(
                      context: context,
                      barrierDismissible: true,
                      barrierColor: Colors.black.withValues(alpha: 0.65),
                      builder: (_) => const ActividadesScreen(),
                    );
                  },
                ),
                const SizedBox(width: 6),
                _ActionBtn(
                  icon: Icons.manage_accounts,
                  color: Colors.purple,
                  onTap: () {
                    showDialog(
                      context: context,
                      barrierDismissible: true,
                      barrierColor: Colors.black.withValues(alpha: 0.65),
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
                ? kGreen.withValues(alpha: 0.2)
                : kRed.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            active ? 'Activo' : 'Inactivo',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: active ? kGreen : kRed),
          ),
        ),
      );
}

class _ActionBtn extends StatefulWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn(
      {required this.icon, required this.color, required this.onTap});
  @override
  State<_ActionBtn> createState() => _ActionBtnState();
}

class _ActionBtnState extends State<_ActionBtn> {
  bool _hover = false;
  @override
  Widget build(BuildContext context) => MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: _hover
                  ? widget.color.withValues(alpha: 0.18)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                  color: _hover
                      ? widget.color.withValues(alpha: 0.4)
                      : Colors.transparent),
            ),
            child: Icon(widget.icon, size: 16, color: widget.color),
          ),
        ),
      );
}
