import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// --- Colores y Utilidades ---
class AC {
  static Color get primary => const Color(0xFF00BFFF);
  static Color get panel => const Color(0xFF1E2A3A);
  static Color get bg => const Color(0xFF121822);
  static Color get white => Colors.white;
  static Color get critico => const Color(0xFFE53935);
  static Color get terminado => const Color(0xFFFF7043); // Naranja
  static Color get ejecucion => const Color(0xFFFFD54F); // Amarillo
  static Color get informatico => Colors.white; // Blanco
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
  if (timestamp is DateTime) return timestamp;
  return null;
}

class LogsScreen extends StatefulWidget {
  const LogsScreen({super.key});
  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  // Filtros
  DateTime? startDate;
  DateTime? endDate;
  String maqueta = "Todas";
  String evento = "Todos";
  String severidad = "Todas";
  String filtroRol = "Todos"; // Nuevo filtro solicitado

  // Paginación
  int currentPage = 1;
  final int rowsPerPage = 10;

  List<String> _tiposDeEventoUnicos = ["Todos"];

  @override
  Widget build(BuildContext context) {
    final r = R(context);
    return Scaffold(
      backgroundColor: AC.bg,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('historial')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          List<Map<String, dynamic>> registros = [];
          if (snapshot.hasData) {
            registros = snapshot.data!.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return data;
            }).toList();

            // Actualizar tipos de evento únicos
            final eventosSet = registros.map((log) => log['message'] as String? ?? '').toSet();
            _tiposDeEventoUnicos = ["Todos", ...eventosSet.where((e) => e.isNotEmpty)];
          }

          // Filtrado en memoria
          final filtered = registros.where((row) {
            if (maqueta != "Todas" && row["maqueta"] != maqueta) return false;
            if (evento != "Todos" && row["message"] != evento) return false;
            if (severidad != "Todas" && (row["type"] as String? ?? '').toLowerCase() != severidad.toLowerCase()) return false;
            if (filtroRol != "Todos" && (row["role"] as String? ?? '') != filtroRol) return false;

            final rowDate = _tryParseFirebaseTimestamp(row["timestamp"]);
            if (rowDate != null) {
              if (startDate != null && rowDate.isBefore(DateTime(startDate!.year, startDate!.month, startDate!.day))) return false;
              if (endDate != null && rowDate.isAfter(DateTime(endDate!.year, endDate!.month, endDate!.day, 23, 59, 59))) return false;
            }
            return true;
          }).toList();

          final int totalPages = (filtered.isEmpty) ? 1 : (filtered.length / rowsPerPage).ceil();
          if (currentPage > totalPages) currentPage = totalPages;

          final start = (currentPage - 1) * rowsPerPage;
          final currentRows = filtered.skip(start).take(rowsPerPage).toList();

          return SingleChildScrollView(
            padding: EdgeInsets.all(r.scale(20)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Historial de Eventos', style: TextStyle(color: AC.white, fontSize: r.scale(24), fontWeight: FontWeight.bold)),
              SizedBox(height: r.scale(8)),
              Text('Consulta y analiza todos los eventos del sistema', style: TextStyle(color: Colors.white70, fontSize: r.scale(14))),
              SizedBox(height: r.scale(24)),
              _buildFilterBar(r),
              SizedBox(height: r.scale(20)),
              _buildTableContent(r, currentRows, snapshot.connectionState == ConnectionState.waiting),
              SizedBox(height: r.scale(20)),
              _buildPaginationControls(r, currentPage, totalPages),
            ]),
          );
        },
      ),
    );
  }

  Widget _buildFilterBar(R r) {
    return Container(
      padding: EdgeInsets.all(r.scale(16)),
      decoration: BoxDecoration(color: AC.panel, borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ElevatedButton.icon(
            onPressed: () => setState(() {
              maqueta = "Todas"; evento = "Todos"; severidad = "Todas";
              filtroRol = "Todos";
              startDate = null; endDate = null; currentPage = 1;
            }), 
            icon: const Icon(Icons.refresh), 
            label: const Text('Restablecer'),
            style: ElevatedButton.styleFrom(backgroundColor: AC.primary, foregroundColor: Colors.black),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _datePickerField(r, 'Fecha Inicial', startDate, () => _pickDate(context, true))),
              SizedBox(width: r.scale(16)),
              Expanded(child: _datePickerField(r, 'Fecha Final', endDate, () => _pickDate(context, false))),
            ],
          ),
          SizedBox(height: r.scale(16)),
          Row(
            children: [
              Expanded(child: _filterDropdown(r, 'Maqueta', maqueta, const ["Todas", "neumatico", "prensado", "maquinados", "robot"], (v) => setState(() => maqueta = v!))),
              SizedBox(width: r.scale(16)),
              Expanded(child: _filterDropdown(r, 'Tipo evento', evento, _tiposDeEventoUnicos, (v) => setState(() => evento = v!))),
            ],
          ),
          SizedBox(height: r.scale(16)),
          Row(
            children: [
              Expanded(child: _filterDropdown(r, 'Severidad', severidad, const ["Todas", "Critico", "Terminado", "Ejecucion", "Informatico"], (v) => setState(() => severidad = v!))),
              SizedBox(width: r.scale(16)),
              // NUEVO FILTRO DE ROL
              Expanded(child: _filterDropdown(r, 'Filtrar por Rol', filtroRol, const ["Todos", "Administrador", "Ingeniero", "Alumno"], (v) => setState(() => filtroRol = v!))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _datePickerField(R r, String label, DateTime? date, VoidCallback onTap) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(color: Colors.white70, fontSize: r.scale(12))),
      SizedBox(height: r.scale(8)),
      InkWell(
        onTap: onTap,
        child: Container(
          width: double.infinity,
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
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: r.scale(12)),
        decoration: BoxDecoration(border: Border.all(color: Colors.grey[700]!), borderRadius: BorderRadius.circular(4)),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(isExpanded: true, value: value, items: items.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(), onChanged: onChanged, dropdownColor: AC.panel, style: TextStyle(color: AC.white, fontSize: r.scale(14))),
        ),
      ),
    ]);
  }

  Widget _buildTableContent(R r, List<Map<String, dynamic>> rows, bool loading) {
    return Column(
      children: [
        _buildTableHeader(r),
        SizedBox(
          height: r.tableHeight,
          child: loading
              ? Center(child: CircularProgressIndicator(color: AC.primary))
              : rows.isEmpty
              ? Center(child: Text('No se encontraron registros.', style: TextStyle(color: Colors.white70, fontSize: r.scale(14))))
              : ListView.builder(itemCount: rows.length, itemBuilder: (_, i) => _buildTableRow(r, rows[i])),
        ),
      ],
    );
  }

  Widget _buildTableHeader(R r) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: r.scale(12), horizontal: r.scale(16)),
      decoration: BoxDecoration(color: AC.panel.withValues(alpha: 0.5), borderRadius: const BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8))),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text('FECHA', style: TextStyle(color: Colors.white70, fontSize: r.scale(12), fontWeight: FontWeight.bold))),
          Expanded(flex: 2, child: Text('MAQUETA', style: TextStyle(color: Colors.white70, fontSize: r.scale(12), fontWeight: FontWeight.bold))),
          Expanded(flex: 3, child: Text('EVENTO', style: TextStyle(color: Colors.white70, fontSize: r.scale(12), fontWeight: FontWeight.bold))),
          Expanded(flex: 2, child: Text('IDENTIDAD', style: TextStyle(color: Colors.white70, fontSize: r.scale(12), fontWeight: FontWeight.bold))),
          Expanded(flex: 2, child: Text('SEVERIDAD', style: TextStyle(color: Colors.white70, fontSize: r.scale(12), fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _buildTableRow(R r, Map<String, dynamic> row) {
    final type = (row["type"] as String? ?? 'informatico').toLowerCase();
    final fecha = _tryParseFirebaseTimestamp(row["timestamp"]);
    final String ident = row["userName"] ?? row["role"] ?? 'N/A'; // Priorizamos el Nombre real

    return Container(
      padding: EdgeInsets.symmetric(vertical: r.scale(12), horizontal: r.scale(16)),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey[800]!))),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(fecha != null ? _fmtFull.format(fecha) : '--', style: TextStyle(color: AC.white, fontSize: r.scale(11)))),
          Expanded(flex: 2, child: Text(row["maqueta"] ?? '--', style: TextStyle(color: AC.white, fontSize: r.scale(11)))),
          Expanded(flex: 3, child: Text(row["message"] ?? '--', style: TextStyle(color: AC.white, fontSize: r.scale(11)))),
          Expanded(flex: 2, child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(ident, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
              Text(row["role"] ?? '--', style: const TextStyle(color: Colors.white38, fontSize: 9)),
            ],
          )),
          Expanded(flex: 2, child: _severityBadge(r, type)),
        ],
      ),
    );
  }

  Widget _severityBadge(R r, String v) {
    String label = v.capitalize();
    if (v == 'ejecucion') label = 'En Ejecución';
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: r.scale(8), vertical: r.scale(4)),
      decoration: BoxDecoration(color: _severityBg(v), borderRadius: BorderRadius.circular(12)),
      child: Text(label, textAlign: TextAlign.center, style: TextStyle(color: _severityColor(v), fontSize: r.scale(9), fontWeight: FontWeight.bold)),
    );
  }

  Color _severityColor(String v) {
    if (v == 'informatico') return Colors.black;
    if (v == 'ejecucion') return Colors.black;
    return Colors.white;
  }
  
  Color _severityBg(String v) {
    switch (v) {
      case 'critico': return AC.critico;
      case 'terminado': return AC.terminado;
      case 'ejecucion': return AC.ejecucion;
      case 'informatico': return AC.informatico;
      default: return AC.info.withValues(alpha: 0.7);
    }
  }

  Widget _buildPaginationControls(R r, int current, int total) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text('Página $current de $total', style: TextStyle(color: Colors.white70, fontSize: r.scale(12))),
        SizedBox(width: r.scale(16)),
        IconButton(onPressed: current > 1 ? () => setState(() => currentPage--) : null, icon: const Icon(Icons.chevron_left, color: Colors.white)),
        IconButton(onPressed: current < total ? () => setState(() => currentPage++) : null, icon: const Icon(Icons.chevron_right, color: Colors.white)),
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
