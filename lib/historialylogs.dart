import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_service.dart'; // Importar el servicio de Firebase

// --- Colores y Utilitidades se mantienen igual ---
class AC {
  static Color get primary => const Color(0xFF00BFFF);
  static Color get panel => const Color(0xFF1E2A3A);
  static Color get bg => const Color(0xFF121822);
  static Color get white => Colors.white;
  static Color get critico => const Color(0xFFE53935);
  static Color get advertencia => const Color(0xFFFFB300);
  static Color get info => const Color(0xFF80DEEA);
}

class R {
  final BuildContext context;
  R(this.context);
  double get width => MediaQuery.of(context).size.width;
  bool get isMobile => width < 600;
  double get tableHeight => isMobile ? 400 : 500;
  double scale(double f) => isMobile ? f * 0.8 : f;
}

final _fmtFull = DateFormat('dd/MM/yyyy HH:mm:ss');
String _fmtDate(DateTime? d) => d == null ? 'Seleccionar' : DateFormat('dd/MM/yyyy').format(d);

DateTime? _tryParseFirebaseTimestamp(dynamic timestamp) {
  if (timestamp is Timestamp) return timestamp.toDate();
  return null;
}

// --- Pantalla Principal ---
class LogsScreen extends StatefulWidget {
  const LogsScreen({super.key});
  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  // --- CONEXIÓN A FIREBASE ---
  final FirebaseService _firebaseService = FirebaseService();
  bool _isLoading = true;

  // --- Filtros ---
  DateTime? startDate;
  DateTime? endDate;
  String maqueta = "Todas";
  String evento = "Todos";
  String severidad = "Todas";

  // --- Paginación ---
  int currentPage = 1;
  final int rowsPerPage = 10;

  // --- Datos de Firebase ---
  List<Map<String, dynamic>> registros = []; // <-- AHORA ES dinámico
  List<String> _tiposDeEventoUnicos = ["Todos"];

  @override
  void initState() {
    super.initState();
    // Se reemplaza _generarRegistros por _fetchLogs
    _fetchLogs();
  }

  // --- NUEVA FUNCIÓN PARA CARGAR DATOS DE FIREBASE ---
  Future<void> _fetchLogs() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final logs = await _firebaseService.getAuditLogs();
      if (mounted) {
        setState(() {
          registros = logs;
          // Extraer tipos de evento únicos para el dropdown de filtros
          final eventosSet = logs.map((log) => log['message'] as String? ?? '').toSet();
          _tiposDeEventoUnicos = ["Todos", ...eventosSet.where((e) => e.isNotEmpty)];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar logs: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // --- Lógica de filtrado adaptada para datos dinámicos ---
  List<Map<String, dynamic>> get filteredRegistros {
    return registros.where((row) {
      if (maqueta != "Todas" && row["maqueta"] != maqueta) return false;
      if (evento != "Todos" && row["message"] != evento) return false;
      if (severidad != "Todas" && (row["type"] as String? ?? '').toLowerCase() != severidad.toLowerCase()) return false;

      // Filtro de fecha adaptado para Timestamp
      final rowDate = _tryParseFirebaseTimestamp(row["timestamp"]);
      if (rowDate != null) {
        if (startDate != null && rowDate.isBefore(DateTime(startDate!.year, startDate!.month, startDate!.day))) return false;
        if (endDate != null && rowDate.isAfter(DateTime(endDate!.year, endDate!.month, endDate!.day, 23, 59, 59))) return false;
      }
      return true;
    }).toList();
  }

  List<Map<String, dynamic>> get currentRows {
    final filtered = filteredRegistros;
    final start = (currentPage - 1) * rowsPerPage;
    if (start >= filtered.length) return [];
    final end = (start + rowsPerPage).clamp(0, filtered.length);
    return filtered.sublist(start, end);
  }

  int get totalPages => (filteredRegistros.isEmpty) ? 1 : (filteredRegistros.length / rowsPerPage).ceil();

  void _resetFilters() {
    setState(() {
      maqueta = "Todas";
      evento = "Todos";
      severidad = "Todas";
      startDate = null;
      endDate = null;
      currentPage = 1;
    });
  }

  // --- El resto de la UI se adapta para manejar los nuevos datos ---
  @override
  Widget build(BuildContext context) {
    final r = R(context);
    return Scaffold(
      backgroundColor: AC.bg,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(r.scale(20)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Historial de Eventos', style: TextStyle(color: AC.white, fontSize: r.scale(24), fontWeight: FontWeight.bold)),
          SizedBox(height: r.scale(8)),
          Text('Consulta y analiza todos los eventos del sistema', style: TextStyle(color: Colors.white70, fontSize: r.scale(14))),
          SizedBox(height: r.scale(24)),
          _buildFilterBar(r),
          SizedBox(height: r.scale(20)),
          _buildTableContent(r),
          SizedBox(height: r.scale(20)),
          _buildPaginationControls(r),
        ]),
      ),
    );
  }

  Widget _buildFilterBar(R r) {
    return Container(
      padding: EdgeInsets.all(r.scale(16)),
      decoration: BoxDecoration(color: AC.panel, borderRadius: BorderRadius.circular(8)),
      child: Wrap(spacing: r.scale(16), runSpacing: r.scale(16), children: [
        _datePickerField(r, 'Fecha Inicial', startDate, () => _pickDate(context, true)),
        _datePickerField(r, 'Fecha Final', endDate, () => _pickDate(context, false)),
        _filterDropdown(r, 'Maqueta', maqueta, ["Todas", "neumatico", "prensado", "maquinados", "robot_3_ejes"], (v) => setState(() => maqueta = v!)),
        _filterDropdown(r, 'Tipo evento', evento, _tiposDeEventoUnicos, (v) => setState(() => evento = v!)),
        _filterDropdown(r, 'Severidad', severidad, ["Todas", "Critico", "Advertencia", "Info"], (v) => setState(() => severidad = v!)),
        ElevatedButton.icon(onPressed: _resetFilters, icon: const Icon(Icons.refresh), label: const Text('Restablecer')),
      ]),
    );
  }
  
  Widget _datePickerField(R r, String label, DateTime? date, VoidCallback onTap) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(color: Colors.white70, fontSize: r.scale(12))),
      SizedBox(height: r.scale(8)),
      InkWell(
        onTap: onTap,
        child: Container(
          width: r.isMobile ? double.infinity : 180,
          padding: EdgeInsets.symmetric(horizontal: r.scale(12), vertical: r.scale(14)),
          decoration: BoxDecoration(border: Border.all(color: Colors.grey[700]!), borderRadius: BorderRadius.circular(4)),
          child: Row(children: [ const Icon(Icons.calendar_today, color: Colors.white70, size: 16), SizedBox(width: r.scale(10)), Text(_fmtDate(date), style: TextStyle(color: AC.white, fontSize: r.scale(14))) ]),
        ),
      ),
    ]);
  }

  Widget _filterDropdown(R r, String label, String value, List<String> items, ValueChanged<String?> onChanged) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(color: Colors.white70, fontSize: r.scale(12))),
      SizedBox(height: r.scale(8)),
      Container(
        width: r.isMobile ? double.infinity : 180,
        padding: EdgeInsets.symmetric(horizontal: r.scale(12)),
        decoration: BoxDecoration(border: Border.all(color: Colors.grey[700]!), borderRadius: BorderRadius.circular(4)),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(isExpanded: true, value: value, items: items.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(), onChanged: onChanged, dropdownColor: AC.panel, style: TextStyle(color: AC.white, fontSize: r.scale(14))),
        ),
      ),
    ]);
  }

  Widget _buildTableContent(R r) {
    return Column(
      children: [
        _buildTableHeader(r),
        SizedBox(
          height: r.tableHeight,
          // Se muestra un loader mientras se cargan los datos
          child: _isLoading
              ? Center(child: CircularProgressIndicator(color: AC.primary))
              : currentRows.isEmpty
                  ? _buildEmptyState(r)
                  : ListView.builder(itemCount: currentRows.length, itemBuilder: (_, i) => _buildTableRow(r, currentRows[i], i)),
        ),
      ],
    );
  }

  Widget _buildTableHeader(R r) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: r.scale(12), horizontal: r.scale(16)),
      decoration: BoxDecoration(color: AC.panel.withOpacity(0.5), borderRadius: const BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8))),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text('FECHA', style: TextStyle(color: Colors.white70, fontSize: r.scale(12), fontWeight: FontWeight.bold))),
          Expanded(flex: 2, child: Text('MAQUETA', style: TextStyle(color: Colors.white70, fontSize: r.scale(12), fontWeight: FontWeight.bold))),
          Expanded(flex: 2, child: Text('EVENTO', style: TextStyle(color: Colors.white70, fontSize: r.scale(12), fontWeight: FontWeight.bold))),
          Expanded(flex: 2, child: Text('USUARIO', style: TextStyle(color: Colors.white70, fontSize: r.scale(12), fontWeight: FontWeight.bold))),
          Expanded(flex: 1, child: Text('SEVERIDAD', style: TextStyle(color: Colors.white70, fontSize: r.scale(12), fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _buildTableRow(R r, Map<String, dynamic> row, int index) {
    final sev = (row["type"] as String? ?? 'info').capitalize();
    final fecha = _tryParseFirebaseTimestamp(row["timestamp"]);

    return Container(
      padding: EdgeInsets.symmetric(vertical: r.scale(12), horizontal: r.scale(16)),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey[800]!))),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(fecha != null ? _fmtFull.format(fecha) : '--', style: TextStyle(color: AC.white, fontSize: r.scale(12)))),
          Expanded(flex: 2, child: Text(row["maqueta"] ?? '--', style: TextStyle(color: AC.white, fontSize: r.scale(12)))),
          Expanded(flex: 2, child: Text(row["message"] ?? '--', style: TextStyle(color: AC.white, fontSize: r.scale(12)))),
          Expanded(flex: 2, child: Text(row["role"] ?? '--', style: TextStyle(color: Colors.white70, fontSize: r.scale(12)))),
          Expanded(flex: 1, child: _severityBadge(r, sev)),
        ],
      ),
    );
  }
  
  Widget _severityBadge(R r, String v) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: r.scale(10), vertical: r.scale(4)),
      decoration: BoxDecoration(color: _severityBg(v), borderRadius: BorderRadius.circular(12)),
      child: Text(v, textAlign: TextAlign.center, style: TextStyle(color: _severityColor(v), fontSize: r.scale(10), fontWeight: FontWeight.bold)),
    );
  }

  Color _severityColor(String v) => v == 'Critico' ? Colors.white : v == 'Advertencia' ? Colors.black : AC.bg;
  Color _severityBg(String v) => v == 'Critico' ? AC.critico : v == 'Advertencia' ? AC.advertencia : AC.info.withOpacity(0.7);

  Widget _buildEmptyState(R r) {
    return Center(child: Text('No se encontraron registros.', style: TextStyle(color: Colors.white70, fontSize: r.scale(14))));
  }

  Widget _buildPaginationControls(R r) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text('Página $currentPage de $totalPages', style: TextStyle(color: Colors.white70, fontSize: r.scale(12))),
        SizedBox(width: r.scale(16)),
        IconButton(onPressed: currentPage > 1 ? () => setState(() => currentPage--) : null, icon: const Icon(Icons.chevron_left, color: Colors.white)),
        IconButton(onPressed: currentPage < totalPages ? () => setState(() => currentPage++) : null, icon: const Icon(Icons.chevron_right, color: Colors.white)),
      ],
    );
  }

  Future<void> _pickDate(BuildContext ctx, bool isStart) async {
    final picked = await showDatePicker(context: ctx, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2100));
    if (picked != null) {
      setState(() => isStart ? startDate = picked : endDate = picked);
    }
  }
}


extension StringExtension on String {
    String capitalize() {
      if (this.isEmpty) return "";
      return "${this[0].toUpperCase()}${this.substring(1).toLowerCase()}";
    }
}
