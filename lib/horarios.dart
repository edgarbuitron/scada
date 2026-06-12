import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'usuarios.dart' show Usuario;

// ─── Paleta Unificada ───
const Color kBg = Color(0xFF081014);
const Color kPanel = Color(0xFF11222C);
const Color kCyan = Color(0xFF00EAFF);
const Color kBlue = Color(0xFF3B82F6);
const Color kText = Color(0xFFC5D1D8);
const Color kBorder = Color(0xFF1A3644);
const Color kMuted = Color(0xFF64748B);
const Color kRed = Color(0xFFF43F5E);
const Color kWarning = Color(0xFFF59E0B);

class HorariosScreen extends StatefulWidget {
  const HorariosScreen({super.key});

  @override
  State<HorariosScreen> createState() => _HorariosScreenState();
}

class _HorariosScreenState extends State<HorariosScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  String _filterRol = 'Todos';
  String _filterSemestre = 'Todos';
  String _filterGrupo = 'Todos';
  String _filterAsignacion = 'Todos los horarios'; 
  
  Set<String> _selectedUserIds = {};

  Map<String, List<String>> _userSchedulesMap = {};

  @override
  void initState() {
    super.initState();
    _fetchUserSchedules();
  }

  Future<void> _fetchUserSchedules() async {
    final query = await _firestore.collection('horarios').get();
    final Map<String, List<String>> newMap = {};
    
    for (var doc in query.docs) {
      final data = doc.data();
      final List<dynamic> userIds = data['userIds'] ?? [];
      final String scheduleName = data['nombre'] ?? 'Sin nombre';
      
      for (var uid in userIds) {
        if (newMap.containsKey(uid)) {
          newMap[uid]!.add(scheduleName);
        } else {
          newMap[uid] = [scheduleName];
        }
      }
    }
    
    if (mounted) {
      setState(() {
        _userSchedulesMap = newMap;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Horarios de uso',
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showEditor(),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('crear horario +'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // FILTROS REORGANIZADOS
            Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _buildRoleButton('Alumnos', 'Alumno'),
                _buildRoleButton('Ingenieros', 'Ingeniero'),
                _buildRoleButton('Administradores', 'Administrador'),
                _buildAsignacionFilter(), // Filtro de Horarios a un lado de Administradores
                // _buildRoleButton('Todos', 'Todos'), // Filtro "Todos" desactivado temporalmente
              ],
            ),
            
            if (_filterRol == 'Alumno') ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _buildFilterDropdown('SEMESTRE', _filterSemestre, ['Todos', ...List.generate(12, (i) => (i+1).toString())], 
                    (v) => setState(() { _filterSemestre = v!; _selectedUserIds.clear(); }))
                  ,
                  _buildFilterDropdown('GRUPO', _filterGrupo, ['Todos', 'Grupo A', 'Grupo B'], 
                    (v) => setState(() { _filterGrupo = v!; _selectedUserIds.clear(); }))
                  ,
                ],
              ),
            ],
            
            const SizedBox(height: 20),

            Container(
              decoration: BoxDecoration(
                color: kPanel,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kBorder),
              ),
              child: ExpansionTile(
                initiallyExpanded: false,
                backgroundColor: Colors.transparent,
                collapsedBackgroundColor: Colors.transparent,
                tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                title: Row(
                  children: [
                    const Icon(Icons.people_outline, color: kCyan, size: 20),
                    const SizedBox(width: 12),
                    const Text('Seleccionar Usuarios para Horario', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    if (_selectedUserIds.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: kCyan, borderRadius: BorderRadius.circular(10)),
                        child: Text('${_selectedUserIds.length}', style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
                children: [
                  _CommonUsersTable(
                    selectedIds: _selectedUserIds,
                    filterRol: _filterRol,
                    filterSemestre: _filterSemestre,
                    filterGrupo: _filterGrupo,
                    filterAsignacion: _filterAsignacion,
                    userSchedulesMap: _userSchedulesMap,
                    onSelectionChanged: (newIds) {
                      final addedIds = newIds.difference(_selectedUserIds);
                      if (addedIds.isNotEmpty) {
                        for (var id in addedIds) {
                          if (_userSchedulesMap.containsKey(id)) {
                            _showScheduleWarning(id, _userSchedulesMap[id]!);
                          }
                        }
                      }
                      setState(() => _selectedUserIds = newIds);
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),
            
            StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('horarios').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: kCyan));
                
                final docs = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  bool matchesRol = _filterRol == 'Todos' || data['rol'] == _filterRol;
                  bool matchesSem = _filterSemestre == 'Todos' || (data['semestre']?.toString() ?? 'Todos') == _filterSemestre;
                  bool matchesGrp = _filterGrupo == 'Todos' || data['grupo'] == _filterGrupo;
                  return matchesRol && matchesSem && matchesGrp;
                }).toList();

                if (docs.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Text('No hay horarios creados para estos filtros.', style: TextStyle(color: kText)),
                    ),
                  );
                }

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.4,
                  ),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    return _buildHorarioCard(doc.id, data);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAsignacionFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: kPanel,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: kCyan.withValues(alpha: 0.5)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _filterAsignacion,
          dropdownColor: kPanel,
          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
          items: ['Todos los horarios', 'En horario', 'Sin horario'].map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: (v) => setState(() { 
            _filterAsignacion = v!; 
            _selectedUserIds.clear(); 
          }),
        ),
      ),
    );
  }

  void _showScheduleWarning(String userId, List<String> existingSchedules) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: kWarning,
        duration: const Duration(seconds: 4),
        content: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.black),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Aviso: Este usuario ya está asignado a: ${existingSchedules.join(", ")}',
                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleButton(String label, String roleValue) {
    bool isSelected = _filterRol == roleValue;
    return InkWell(
      onTap: () {
        setState(() {
          _filterRol = roleValue;
          if (_filterRol != 'Alumno') {
            _filterSemestre = 'Todos';
            _filterGrupo = 'Todos';
          }
          _selectedUserIds.clear();
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? kBlue.withValues(alpha: 0.2) : kPanel,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? kBlue : kBorder),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : kText,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterDropdown(String label, String value, List<String> items, ValueChanged<String?>? onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: kPanel,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: kCyan.withValues(alpha: 0.5)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          disabledHint: Text(label, style: const TextStyle(color: Colors.white24, fontSize: 12)),
          dropdownColor: kPanel,
          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e == 'Todos' ? label : e))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildHorarioCard(String id, Map<String, dynamic> data) {
    final List<dynamic> users = data['userIds'] ?? [];
    return InkWell(
      onTap: () => _showEditor(id: id, existingData: data),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kPanel,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kCyan.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    data['nombre'] ?? 'HORARIO',
                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.1),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: kRed, size: 20),
                      onPressed: () => _confirmDelete(id),
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.edit_note_rounded, color: kCyan, size: 22),
                  ],
                ),
              ],
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: kCyan.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${data['rol']} ${data['rol'] == 'Alumno' ? '- ${data['grupo']}' : ''}',
                style: const TextStyle(color: kCyan, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.people, color: kMuted, size: 12),
                const SizedBox(width: 6),
                Text(
                  '${users.length} Usuarios vinculados',
                  style: const TextStyle(color: kText, fontSize: 10),
                ),
              ],
            ),
            if (data['rol'] == 'Alumno')
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Semestre: ${data['semestre']}',
                  style: const TextStyle(color: kMuted, fontSize: 10),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kPanel,
        title: const Text('¿Borrar horario?', style: TextStyle(color: Colors.white)),
        content: const Text('¿Estás seguro de borrar este horario? Esta acción no se puede deshacer.', style: TextStyle(color: kText)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCELAR', style: TextStyle(color: kText)),
          ),
          ElevatedButton(
            onPressed: () async {
              await _firestore.collection('horarios').doc(id).delete();
              _fetchUserSchedules(); // Refrescar mapa
              if (mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: kRed),
            child: const Text('BORRAR', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showEditor({String? id, Map<String, dynamic>? existingData}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => HorarioEditorDialog(
        docId: id,
        existingData: existingData,
        initialUserIds: id == null ? _selectedUserIds.toList() : (existingData!['userIds'] as List<dynamic>).map((e) => e.toString()).toList(),
        initialRol: id == null ? (_filterRol == 'Todos' ? 'Alumno' : _filterRol) : existingData!['rol'],
        initialSemestre: id == null ? (_filterSemestre == 'Todos' ? 1 : int.parse(_filterSemestre)) : existingData!['semestre'],
        initialGrupo: id == null ? (_filterGrupo == 'Todos' ? 'Grupo A' : _filterGrupo) : existingData!['grupo'],
        userSchedulesMap: _userSchedulesMap,
        onSaveSuccess: () => _fetchUserSchedules(),
      ),
    );
  }
}

// =============================================================================
// WIDGET REUTILIZABLE: TABLA DE USUARIOS
// =============================================================================
class _CommonUsersTable extends StatefulWidget {
  final Set<String> selectedIds;
  final String filterRol;
  final String filterSemestre;
  final String filterGrupo;
  final String filterAsignacion; 
  final Map<String, List<String>> userSchedulesMap;
  final Function(Set<String>) onSelectionChanged;

  const _CommonUsersTable({
    required this.selectedIds,
    required this.filterRol,
    required this.filterSemestre,
    required this.filterGrupo,
    required this.filterAsignacion,
    required this.userSchedulesMap,
    required this.onSelectionChanged,
  });

  @override
  State<_CommonUsersTable> createState() => _CommonUsersTableState();
}

class _CommonUsersTableState extends State<_CommonUsersTable> {
  int _currentPage = 0;
  final int _pageSize = 10;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('usuarios').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const LinearProgressIndicator(color: kCyan);

        final List<Usuario> allFiltered = snapshot.data!.docs.map((doc) => Usuario.fromFirestore(doc)).where((u) {
          bool matchesRol = widget.filterRol == 'Todos' || u.rol == widget.filterRol;
          bool matchesSem = widget.filterSemestre == 'Todos' || u.semestre.toString() == widget.filterSemestre;
          bool matchesGrp = widget.filterGrupo == 'Todos' || u.grupo == widget.filterGrupo;
          
          bool matchesAsig = true;
          if (widget.filterAsignacion == 'En horario') {
            matchesAsig = widget.userSchedulesMap.containsKey(u.id);
          } else if (widget.filterAsignacion == 'Sin horario') {
            matchesAsig = !widget.userSchedulesMap.containsKey(u.id);
          }
          
          return matchesRol && matchesSem && matchesGrp && matchesAsig;
        }).toList();

        final int totalItems = allFiltered.length;
        final int totalPages = (totalItems / _pageSize).ceil();
        if (_currentPage >= totalPages && totalPages > 0) _currentPage = totalPages - 1;

        final List<Usuario> paged = allFiltered.skip(_currentPage * _pageSize).take(_pageSize).toList();

        return Column(
          children: [
            const Divider(color: kBorder, height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Checkbox(
                    value: allFiltered.isNotEmpty && widget.selectedIds.length == allFiltered.length,
                    activeColor: kCyan,
                    onChanged: (val) {
                      if (val!) {
                        widget.onSelectionChanged(allFiltered.map((u) => u.id).toSet());
                      } else {
                        widget.onSelectionChanged({});
                      }
                    },
                  ),
                  const Text('Seleccionar todos', style: TextStyle(color: kText, fontSize: 12)),
                  const Spacer(),
                  Text('Página ${_currentPage + 1} de ${totalPages > 0 ? totalPages : 1}', style: const TextStyle(color: kMuted, fontSize: 11)),
                ],
              ),
            ),
            
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 800),
                child: DataTable(
                  showCheckboxColumn: false,
                  headingRowHeight: 40,
                  dataRowMinHeight: 45,
                  dataRowMaxHeight: 45,
                  horizontalMargin: 12,
                  columnSpacing: 20,
                  headingRowColor: WidgetStateProperty.all(kBg),
                  columns: const [
                    DataColumn(label: SizedBox(width: 30)),
                    DataColumn(label: Text('Asignado', style: TextStyle(color: kCyan, fontSize: 10))),
                    DataColumn(label: Text('ID Cloud', style: TextStyle(color: kCyan, fontSize: 12))),
                    DataColumn(label: Text('Nombre', style: TextStyle(color: kCyan, fontSize: 12))),
                    DataColumn(label: Text('Rol', style: TextStyle(color: kCyan, fontSize: 12))),
                    DataColumn(label: Text('Grupo', style: TextStyle(color: kCyan, fontSize: 12))),
                    DataColumn(label: Text('Semestre', style: TextStyle(color: kCyan, fontSize: 12))),
                  ],
                  rows: paged.map((u) {
                    final bool isSelected = widget.selectedIds.contains(u.id);
                    final bool hasSchedule = widget.userSchedulesMap.containsKey(u.id);
                    return DataRow(
                      color: WidgetStateProperty.resolveWith<Color?>((states) => isSelected ? kBlue.withValues(alpha: 0.15) : null),
                      cells: [
                        DataCell(
                          Checkbox(
                            value: isSelected,
                            activeColor: kCyan,
                            onChanged: (val) {
                              final newSet = Set<String>.from(widget.selectedIds);
                              if (val!) newSet.add(u.id); else newSet.remove(u.id);
                              widget.onSelectionChanged(newSet);
                            },
                          ),
                        ),
                        DataCell(
                          hasSchedule 
                            ? const Icon(Icons.event_available_rounded, color: kWarning, size: 18)
                            : Icon(Icons.event_busy_outlined, color: kMuted.withValues(alpha: 0.3), size: 18)
                        ),
                        DataCell(Text(u.id.length > 5 ? '${u.id.substring(0, 5)}...' : u.id, style: const TextStyle(color: kMuted, fontSize: 11))),
                        DataCell(
                          Text(u.nombre, 
                            style: TextStyle(
                              color: hasSchedule ? kWarning : Colors.white, 
                              fontSize: 11, 
                              fontWeight: FontWeight.bold
                            )
                          )
                        ),
                        DataCell(Text(u.rol, style: const TextStyle(color: kText, fontSize: 11))),
                        DataCell(Text(u.grupo, style: const TextStyle(color: kText, fontSize: 11))),
                        DataCell(Text(u.semestre?.toString() ?? 'N/A', style: const TextStyle(color: kText, fontSize: 11))),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: _currentPage > 0 ? () => setState(() => _currentPage--) : null,
                    color: kCyan,
                  ),
                  const SizedBox(width: 20),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: (_currentPage + 1) * _pageSize < totalItems ? () => setState(() => _currentPage++) : null,
                    color: kCyan,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

// =============================================================================
// DIÁLOGO: EDITOR DE HORARIO
// =============================================================================
class HorarioEditorDialog extends StatefulWidget {
  final String? docId;
  final Map<String, dynamic>? existingData;
  final List<String> initialUserIds;
  final String initialRol;
  final int initialSemestre;
  final String initialGrupo;
  final Map<String, List<String>> userSchedulesMap;
  final VoidCallback onSaveSuccess;

  const HorarioEditorDialog({
    super.key, 
    this.docId, 
    this.existingData, 
    required this.initialUserIds,
    required this.initialRol,
    required this.initialSemestre,
    required this.initialGrupo,
    required this.userSchedulesMap,
    required this.onSaveSuccess,
  });

  @override
  State<HorarioEditorDialog> createState() => _HorarioEditorDialogState();
}

class _HorarioEditorDialogState extends State<HorarioEditorDialog> {
  late TextEditingController _nameController;
  late Set<String> _editingUserIds;
  bool _isSaving = false;
  
  final List<List<bool>> _selection = List.generate(8, (_) => List.generate(5, (_) => false));
  final List<String> _days = ['LUNES', 'MARTES', 'MIÉRC.', 'JUEVES', 'VIERNES'];
  final List<String> _hours = ['07:00', '08:00', '09:00', '10:00', '11:00', '12:00', '13:00', '14:00'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existingData?['nombre'] ?? 'NOMBRE DEL HORARIO');
    _editingUserIds = Set<String>.from(widget.initialUserIds);

    if (widget.existingData != null) {
      final Map<String, dynamic>? savedMatrix = widget.existingData!['matriz'];
      if (savedMatrix != null) {
        for (int h = 0; h < 8; h++) {
          for (int d = 0; d < 5; d++) {
            _selection[h][d] = savedMatrix['$h-$d'] ?? false;
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(12),
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 900),
        decoration: BoxDecoration(
          color: kPanel,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: kBorder),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 40, spreadRadius: 10)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 300,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: kBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: kCyan.withValues(alpha: 0.5)),
                    ),
                    child: TextField(
                      controller: _nameController,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      decoration: const InputDecoration(border: InputBorder.none, isDense: true, hintText: 'Nombre del horario'),
                    ),
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(widget.initialRol, style: TextStyle(color: kCyan, fontWeight: FontWeight.bold, fontSize: 12)),
                      if (widget.initialRol == 'Alumno')
                        Text('${widget.initialGrupo} - Semestre ${widget.initialSemestre}', style: const TextStyle(color: kMuted, fontSize: 10)),
                    ],
                  ),
                ],
              ),
            ),

            const Divider(color: kBorder, height: 1),

            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Theme(
                      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        initiallyExpanded: false,
                        title: const Text('Gestionar Usuarios del Horario', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                        subtitle: Text('Usuarios seleccionados: ${_editingUserIds.length}', style: TextStyle(color: kCyan.withValues(alpha: 0.7), fontSize: 11)),
                        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                          _CommonUsersTable(
                            selectedIds: _editingUserIds,
                            filterRol: widget.initialRol,
                            filterSemestre: widget.initialSemestre.toString(),
                            filterGrupo: widget.initialGrupo,
                            filterAsignacion: 'Todos los horarios', 
                            userSchedulesMap: widget.userSchedulesMap,
                            onSelectionChanged: (newIds) => setState(() => _editingUserIds = newIds),
                          ),
                        ],
                      ),
                    ),
                    const Divider(color: kBorder, height: 1),
                    
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Container(
                          width: 700,
                          decoration: BoxDecoration(border: Border.all(color: kBorder), borderRadius: BorderRadius.circular(4)),
                          child: Table(
                            border: TableBorder.all(color: kBorder, width: 1),
                            columnWidths: const { 0: FixedColumnWidth(80) },
                            children: [
                              TableRow(
                                decoration: const BoxDecoration(color: kBg),
                                children: [
                                  const SizedBox(height: 40),
                                  ..._days.map((d) => Center(child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    child: Text(d, style: const TextStyle(color: kCyan, fontWeight: FontWeight.bold, fontSize: 10)),
                                  ))),
                                ],
                              ),
                              ...List.generate(8, (h) => TableRow(
                                children: [
                                  Container(
                                    height: 55, alignment: Alignment.center, color: kBg,
                                    child: Text(_hours[h], style: const TextStyle(color: kText, fontSize: 11, fontWeight: FontWeight.bold)),
                                  ),
                                  ...List.generate(5, (d) => GestureDetector(
                                    onTap: () => setState(() => _selection[h][d] = !_selection[h][d]),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 150),
                                      height: 55,
                                      color: _selection[h][d] ? kCyan.withValues(alpha: 0.3) : Colors.transparent,
                                      child: _selection[h][d] ? const Center(child: Icon(Icons.check_circle_rounded, color: kCyan, size: 16)) : null,
                                    ),
                                  )),
                                ],
                              )),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCELAR', style: TextStyle(color: kText, fontWeight: FontWeight.bold))),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _isSaving ? null : () => _save(),
                    style: ElevatedButton.styleFrom(backgroundColor: kCyan, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: _isSaving 
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                      : Text(widget.docId == null ? 'CREAR HORARIO' : 'GUARDAR CAMBIOS', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final Map<String, bool> matrizMap = {};
      for (int h = 0; h < 8; h++) {
        for (int d = 0; d < 5; d++) {
          matrizMap['$h-$d'] = _selection[h][d];
        }
      }

      final data = {
        'nombre': _nameController.text,
        'rol': widget.initialRol,
        'semestre': widget.initialSemestre,
        'grupo': widget.initialGrupo,
        'matriz': matrizMap,
        'userIds': _editingUserIds.toList(),
        'ultimaModificacion': FieldValue.serverTimestamp(),
      };

      if (widget.docId == null) {
        await FirebaseFirestore.instance.collection('horarios').add(data);
      } else {
        await FirebaseFirestore.instance.collection('horarios').doc(widget.docId).update(data);
      }

      widget.onSaveSuccess();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() => _isSaving = false);
      }
    }
  }
}
