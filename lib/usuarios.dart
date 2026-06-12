import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'actividades_recientes.dart';
import 'permisos.dart';
import 'gestion_roles.dart';
import 'usage_monitor.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  final int? semestre; // Ahora opcional
  final bool activo;
  final String sexo;
  final String grupo;
  final bool enLinea;
  final bool perfilCompleto; // Nueva propiedad

  Usuario({
    required this.id,
    required this.nombre,
    required this.passwordHash,
    required this.numero,
    required this.correo,
    required this.rol,
    required this.activo,
    required this.ultimoAcceso,
    this.semestre,
    required this.fechaRegistro,
    required this.numeroControl,
    required this.sexo,
    required this.grupo,
    required this.enLinea,
    required this.perfilCompleto,
  });

  factory Usuario.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    bool completo = data['perfilCompleto'] ?? false;

    // Conversión segura de semestre (puede venir como String o int de Firestore)
    int? parsedSemestre;
    var rawSemestre = data['semestre'];
    if (rawSemestre is int) {
      parsedSemestre = rawSemestre;
    } else if (rawSemestre is String) {
      parsedSemestre = int.tryParse(rawSemestre);
    }

    return Usuario(
      id: doc.id,
      nombre: data['nombre'] ?? '',
      passwordHash: data['passwordHash'] ?? '',
      numero: data['numero'] ?? '',
      correo: data['correo'] ?? '',
      rol: data['rol'] ?? 'Operador',
      activo: data['activo'] ?? true,
      ultimoAcceso: data['ultimoAcceso'] ?? '',
      semestre: completo ? (parsedSemestre ?? 1) : null,
      fechaRegistro: data['fechaRegistro'] ?? '',
      numeroControl: completo ? (data['numeroControl'] ?? '') : '',
      sexo: completo ? (data['sexo'] ?? 'Masculino') : '',
      grupo: completo ? (data['grupo'] ?? 'Grupo A') : '',
      enLinea: data['enLinea'] ?? false,
      perfilCompleto: completo,
    );
  }
}

// ─── App ───────────────────────────────────────────────────────────────────────
class UsuariosApp extends StatelessWidget {
  const UsuariosApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Usuarios SCADA Cloud',
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
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Filtros de texto
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _controlController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _semestreController = TextEditingController();

  // Filtros de fecha
  DateTime? _fechaRegistro;
  DateTime? _ultimoAcceso;

  // Filtros de Selección
  String _selectedRol = 'Todos';
  String _selectedSexo = 'Todos';
  String _selectedGrupo = 'Todos';
  String _selectedEstado = 'Todos';
  bool _filterOnlyPending = false;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(() => setState(() {}));
    _controlController.addListener(() => setState(() {}));
    _phoneController.addListener(() => setState(() {}));
    _emailController.addListener(() => setState(() {}));
    _semestreController.addListener(() => setState(() {}));
    
    // EJECUTAR POBLAMIENTO DE DATOS DE PRUEBA (SOLO UNA VEZ)
    _poblarDatosDePrueba();
  }

  Future<void> _poblarDatosDePrueba() async {
    try {
      final query = await _firestore.collection('usuarios').get();
      final random = Random();
      
      for (var doc in query.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        // Solo rellenamos si perfilCompleto es falso o los campos están vacíos
        if (data['perfilCompleto'] != true || data['numeroControl'] == null || data['numeroControl'] == '') {
          String sex = random.nextBool() ? 'Masculino' : 'Femenino';
          String grp = random.nextBool() ? 'Grupo A' : 'Grupo B';
          int sem = random.nextInt(8) + 1;
          String ctrl = (random.nextInt(90000000) + 10000000).toString(); 

          await doc.reference.update({
            'sexo': data['sexo'] ?? sex,
            'grupo': data['grupo'] ?? grp,
            'semestre': data['semestre'] ?? sem,
            'numeroControl': data['numeroControl'] ?? ctrl,
            'perfilCompleto': true, 
          });
        }
      }
      debugPrint("Poblamiento de datos de prueba completado.");
    } catch (e) {
      debugPrint("Error en poblamiento: $e");
    }
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

  void _onDeleteTap(String docId) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (_) => AlertDialog(
        backgroundColor: kCard,
        title: const Text('¿Eliminar usuario?', style: TextStyle(color: kText)),
        content: const Text('Esta acción se eliminará permanentemente de Firestore.',
            style: TextStyle(color: kMuted2)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar', style: TextStyle(color: kText)),
          ),
          TextButton(
            onPressed: () async {
              try {
                await _firestore.collection('usuarios').doc(docId).delete();
                if (mounted) Navigator.of(context).pop();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Usuario eliminado de la nube')),
                  );
                }
              } catch (e) {
                if (mounted) Navigator.of(context).pop();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error al eliminar: $e'), backgroundColor: kRed),
                  );
                }
              }
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
          stream: _firestore.collection('usuarios').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: kRed)));
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: kBlue));
            }

            final List<Usuario> allUsersFromCloud = snapshot.data!.docs.map((doc) => Usuario.fromFirestore(doc)).toList();

            final filteredUsers = allUsersFromCloud.where((u) {
              // Si el botón de "Usuarios nuevos" está activo, ignoramos el resto de filtros y mostramos solo los Pendientes
              if (_filterOnlyPending) return u.rol == 'Pendiente';

              final matchesName = u.nombre.toLowerCase().contains(_nameController.text.toLowerCase());
              final matchesControl = u.numeroControl.contains(_controlController.text);
              final matchesPhone = u.numero.contains(_phoneController.text);
              final matchesEmail = u.correo.toLowerCase().contains(_emailController.text.toLowerCase());
              final matchesSemestre = _semestreController.text.isEmpty || u.semestre.toString() == _semestreController.text;
              final matchesRol = _selectedRol == 'Todos' || u.rol == _selectedRol;
              final matchesSexo = _selectedSexo == 'Todos' || u.sexo == _selectedSexo;
              final matchesGrupo = _selectedGrupo == 'Todos' || u.grupo == _selectedGrupo;
              
              bool matchesEstado = true;
              if (_selectedEstado == 'Activo') matchesEstado = u.enLinea;
              if (_selectedEstado == 'Inactivo') matchesEstado = !u.enLinea;

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
                     matchesSexo && matchesGrupo && matchesEstado &&
                     matchesFechaReg && matchesUltimoAcc;
            }).toList();

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(allUsersFromCloud),
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
    final activos = users.where((u) => u.enLinea).length;
    final inactivos = total - activos;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Gestión de Usuarios (Firestore Cloud)',
          style: TextStyle(
              fontSize: 24, fontWeight: FontWeight.bold, color: kText),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            _buildStatCard('Total Cloud', total.toString(), kBlue),
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
          // Fila 1: Nombre y N° Control
          Row(
            children: [
              Expanded(child: _buildTextField(_nameController, 'Nombre', Icons.person)),
              const SizedBox(width: 12),
              Expanded(child: _buildTextField(_controlController, 'N° Control', Icons.badge)),
            ],
          ),
          const SizedBox(height: 12),
          // Fila 2: Sexo y Grupo
          Row(
            children: [
              Expanded(child: _buildDropdownFilter('Sexo', _selectedSexo, ['Todos', 'Masculino', 'Femenino'], Icons.wc, (v) => setState(() => _selectedSexo = v!))),
              const SizedBox(width: 12),
              Expanded(child: _buildDropdownFilter('Grupo', _selectedGrupo, ['Todos', 'Grupo A', 'Grupo B'], Icons.group_work, (v) => setState(() => _selectedGrupo = v!))),
            ],
          ),
          const SizedBox(height: 12),
          // Fila 3: Teléfono y Correo
          Row(
            children: [
              Expanded(child: _buildTextField(_phoneController, 'Teléfono', Icons.phone)),
              const SizedBox(width: 12),
              Expanded(child: _buildTextField(_emailController, 'Correo', Icons.email)),
            ],
          ),
          const SizedBox(height: 12),
          // Fila 4: Semestre y Rol
          Row(
            children: [
              Expanded(child: _buildTextField(_semestreController, 'Semestre', Icons.school, isNumber: true)),
              const SizedBox(width: 12),
              Expanded(child: _buildRoleDropdown()),
            ],
          ),
          const SizedBox(height: 12),
          // Fila 5: Fecha Registro y Último Acceso
          Row(
            children: [
              Expanded(child: _buildDatePicker('Fecha Registro', _fechaRegistro, (d) => setState(() => _fechaRegistro = d))),
              const SizedBox(width: 12),
              Expanded(child: _buildDatePicker('Último Acceso', _ultimoAcceso, (d) => setState(() => _ultimoAcceso = d))),
            ],
          ),
          const SizedBox(height: 12),
          // Fila 6: Estado (Activo/Inactivo) y Usuarios Nuevos
          Row(
            children: [
              Expanded(child: _buildDropdownFilter('Estado', _selectedEstado, ['Todos', 'Activo', 'Inactivo'], Icons.toggle_on_outlined, (v) => setState(() => _selectedEstado = v!))),
              const SizedBox(width: 12),
              Expanded(child: _buildPendingFilterButton()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPendingFilterButton() {
    final monitor = Provider.of<UsageMonitor>(context);
    final int count = monitor.pendingUsersCount;
    final bool hasPending = count > 0;
    
    // Si el filtro está activo, mostramos un resaltado especial
    final Color bgColor = _filterOnlyPending ? Colors.yellow.withValues(alpha: 0.2) : (hasPending ? Colors.yellow.withValues(alpha: 0.1) : kBg);
    final Color borderColor = _filterOnlyPending ? Colors.yellow : (hasPending ? Colors.yellow.withValues(alpha: 0.5) : kBorder);
    final Color textColor = (hasPending || _filterOnlyPending) ? Colors.yellowAccent : kMuted;

    return InkWell(
      onTap: () => setState(() => _filterOnlyPending = !_filterOnlyPending),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Icon(Icons.person_add_alt_1, color: textColor, size: 18),
            const SizedBox(width: 10),
            Text(
              'Usuarios nuevos ${hasPending ? '($count)' : ''}', 
              style: TextStyle(color: textColor, fontSize: 13, fontWeight: hasPending ? FontWeight.bold : FontWeight.normal)
            ),
            const Spacer(),
            if (hasPending) const Icon(Icons.priority_high_rounded, color: Colors.yellowAccent, size: 16),
            if (!hasPending) Icon(Icons.filter_list, color: kMuted.withValues(alpha: 0.5), size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownFilter(String label, String value, List<String> itemStrings, IconData icon, ValueChanged<String?>? onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: kBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: kBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          dropdownColor: kCard,
          style: const TextStyle(color: kText, fontSize: 13),
          icon: const Icon(Icons.arrow_drop_down, color: kMuted, size: 18),
          isExpanded: true,
          items: itemStrings.map((item) => DropdownMenuItem(value: item, child: Row(
            children: [
              Icon(icon, color: kMuted, size: 18),
              const SizedBox(width: 10),
              Text(item == 'Todos' ? label : item),
            ],
          ))).toList(),
          onChanged: onChanged,
        ),
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
          items: ['Todos', 'Administrador', 'Ingeniero', 'Alumno', 'Pendiente']
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
                    'No se encontraron usuarios en la nube Firestore.',
                    style: TextStyle(fontSize: 14, color: kMuted2),
                  ),
                ),
              )
            : SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: 1600,
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
            _TH('ID Cloud', flex: 2),
            _TH('Nombre', flex: 4),
            _TH('Contraseña', flex: 4),
            _TH('Sexo', flex: 3),
            _TH('Grupo', flex: 3),
            _TH('N° Control', flex: 4),
            _TH('Número', flex: 4),
            _TH('Correo', flex: 6),
            _TH('Semestre', flex: 3),
            _TH('Fecha Registro', flex: 4),
            _TH('Último acceso', flex: 5),
            _TH('Estado', flex: 3),
            _TH('Acciones', flex: 5, align: TextAlign.center),
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
              child: Text('${u.id.substring(0, min(u.id.length, 5))}...',
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
              flex: 3,
              child: Text(u.sexo.isEmpty ? 'Sin datos' : u.sexo,
                  style: TextStyle(fontSize: 13, color: u.sexo.isEmpty ? kMuted : kText))),
          Expanded(
              flex: 3,
              child: Text(u.grupo.isEmpty ? 'Sin datos' : u.grupo,
                  style: TextStyle(fontSize: 13, color: u.grupo.isEmpty ? kMuted : kText))),
          Expanded(
              flex: 4,
              child: Text(u.numeroControl.isEmpty ? 'Sin datos' : u.numeroControl,
                  style: TextStyle(fontSize: 13, color: u.numeroControl.isEmpty ? kMuted : kText))),
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
              child: Text(u.semestre == null ? 'N/A' : u.semestre.toString(),
                  style: TextStyle(fontSize: 13, color: u.semestre == null ? kMuted : kText))),
          Expanded(
              flex: 4,
              child: Text(u.fechaRegistro,
                  style: const TextStyle(fontSize: 13, color: kText))),
          Expanded(
              flex: 5,
              child: Text(u.ultimoAcceso,
                  style: const TextStyle(fontSize: 12, color: kMuted2))),
          Expanded(flex: 3, child: _StatusBadge(active: u.enLinea)),
          Expanded(
            flex: 5,
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
                      builder: (_) => ActividadesScreen(user: u),
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
                const SizedBox(width: 6),
                _ActionBtn(
                  icon: Icons.supervised_user_circle,
                  color: kBlue,
                  onTap: () {
                    showDialog(
                      context: context,
                      barrierDismissible: true,
                      barrierColor: Colors.black.withValues(alpha: 0.65),
                      builder: (_) => GestionRolesScreen(user: u),
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
            border: Border.all(color: active ? kGreen.withValues(alpha: 0.5) : kRed.withValues(alpha: 0.5)),
          ),
          child: Row(
            children: [
              Container(
                width: 6, height: 6,
                decoration: BoxDecoration(shape: BoxShape.circle, color: active ? kGreen : kRed),
              ),
              const SizedBox(width: 6),
              Text(
                active ? 'En línea' : 'Inactivo',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: active ? kGreen : kRed),
              ),
            ],
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
