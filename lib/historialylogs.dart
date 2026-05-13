// ============================================================
// Historial / Logs  –  Flutter/Dart  (RESPONSIVE + DATE PICKER)
// ============================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // agrega intl: ^0.19.0 en pubspec.yaml

void main() {
  runApp(const IndustrialLogsApp());
}

// ─── App root ─────────────────────────────────────────────────
class IndustrialLogsApp extends StatelessWidget {
  const IndustrialLogsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF07111E),
        colorScheme: ColorScheme.dark(
          primary: Colors.blueAccent,
          surface: const Color(0xFF0E1828),
        ),
      ),
      home: const LogsScreen(),
    );
  }
}

// ─── Utilidades responsivas ───────────────────────────────────
class R {
  final double _w;
  const R(this._w);

  bool get isSmall  => _w < 600;
  bool get isMedium => _w >= 600 && _w < 1024;
  bool get isLarge  => _w >= 1024;

  double scale(double base) {
    if (_w < 400)  return base * 0.78;
    if (_w < 600)  return base * 0.88;
    if (_w < 900)  return base * 0.94;
    return base;
  }

  double get hPad {
    if (_w < 400) return 12;
    if (_w < 600) return 16;
    if (_w < 900) return 20;
    return 24;
  }

  // Ancho de cada control de filtro
  double get filterWidth {
    if (_w < 400) return (_w - hPad * 2 - 10) / 2;  // 2 por fila
    if (_w < 600) return (_w - hPad * 2 - 10) / 2;  // 2 por fila
    if (_w < 900) return 160;
    return 170;
  }

  // Altura fija de la tabla (se escala)
  double get tableHeight {
    if (_w < 400) return 340;
    if (_w < 600) return 420;
    if (_w < 900) return 480;
    return 520;
  }

  // Mínimo de columnas de la tabla interna
  double get tableMinWidth {
    if (_w < 600) return 620;
    return 0; // sin mínimo en tablet/desktop
  }
}

// ─── Colores ──────────────────────────────────────────────────
class AC {
  static const bg      = Color(0xFF07111E);
  static const card    = Color(0xFF0E1828);
  static const border  = Colors.blueAccent;
  static const muted   = Colors.white54;
  static const white   = Colors.white;
}

// ─── Formateo de fecha ────────────────────────────────────────
final _fmt = DateFormat('dd/MM/yyyy');
final _fmtFull = DateFormat('dd/MM/yyyy HH:mm:ss');

String _fmtDate(DateTime? d) =>
    d == null ? 'Seleccionar' : _fmt.format(d);

/// Parsea "dd/MM/yyyy HH:mm:ss" → DateTime (solo la fecha)
DateTime? _parseRowDate(String raw) {
  try {
    return _fmtFull.parse(raw);
  } catch (_) {
    return null;
  }
}

// ─── Pantalla principal ───────────────────────────────────────
class LogsScreen extends StatefulWidget {
  const LogsScreen({super.key});

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  // ── Filtros ──
  DateTime? startDate;
  DateTime? endDate;
  String maqueta   = "Todas";
  String evento    = "Todos";
  String severidad = "Todas";

  // ── Paginación ──
  int currentPage    = 1;
  final int rowsPerPage = 8;

  // ── Datos ──
  late List<Map<String, String>> registros;

  @override
  void initState() {
    super.initState();
    _generarRegistros();
  }

  void _generarRegistros() {
    final eventos = [
      "Motor iniciado",    "Paro emergencia",
      "Presión alta",      "Sensor desconectado",
      "Motor detenido",    "Error PLC",
      "Temperatura alta",  "Ciclo completado",
    ];
    final maquetas = [
      "Prensa Hidráulica", "Brazo Robótico",
      "Sistema Neumático", "Pick & Place",
    ];
    final usuarios = [
      "Juan Pérez", "María López", "Carlos Ruiz", "Ana López",
    ];
    final severidades = ["Info", "Advertencia", "Crítico"];

    // Repartimos 40 registros entre el 10/05 y el 20/05
    registros = List.generate(40, (i) {
      final day  = 10 + (i ~/ 4);           // días 10 → 19
      final hour = 8  + (i % 4) * 2;        // horas 8, 10, 12, 14
      final min  = (i * 7) % 60;
      final dateStr =
          '${day.toString().padLeft(2, '0')}/05/2025 '
          '${hour.toString().padLeft(2, '0')}:${min.toString().padLeft(2, '0')}:00';
      return {
        "fecha"    : dateStr,
        "maqueta"  : maquetas[i % maquetas.length],
        "evento"   : eventos[i % eventos.length],
        "usuario"  : usuarios[i % usuarios.length],
        "severidad": severidades[i % severidades.length],
      };
    });
  }

  // ── Filtrado ──────────────────────────────────────────────
  List<Map<String, String>> get filteredRegistros {
    return registros.where((row) {
      // Filtro de maqueta
      if (maqueta != "Todas" && row["maqueta"] != maqueta) return false;
      // Filtro de evento
      if (evento != "Todos" && row["evento"] != evento) return false;
      // Filtro de severidad
      if (severidad != "Todas" && row["severidad"] != severidad) return false;

      // Filtro de fecha
      final rowDate = _parseRowDate(row["fecha"]!);
      if (rowDate != null) {
        if (startDate != null) {
          final start = DateTime(startDate!.year, startDate!.month, startDate!.day);
          if (rowDate.isBefore(start)) return false;
        }
        if (endDate != null) {
          // incluimos todo el día final
          final end = DateTime(endDate!.year, endDate!.month, endDate!.day, 23, 59, 59);
          if (rowDate.isAfter(end)) return false;
        }
      }
      return true;
    }).toList();
  }

  List<Map<String, String>> get currentRows {
    final filtered = filteredRegistros;
    final start = (currentPage - 1) * rowsPerPage;
    final end = (start + rowsPerPage).clamp(0, filtered.length);
    if (start >= filtered.length) return [];
    return filtered.sublist(start, end);
  }

  // ── totalPages dinámico ──
  int get totalPages =>
      (filteredRegistros.length / rowsPerPage).ceil().clamp(1, 9999);

  void _resetFilters() {
    setState(() {
      maqueta   = "Todas";
      evento    = "Todos";
      severidad = "Todas";
      startDate = null;
      endDate   = null;
      currentPage = 1;
    });
  }

  // ── DatePicker ──
  Future<void> _pickDate(BuildContext ctx, bool isStart) async {
    final initial = isStart
        ? (startDate ?? DateTime(2025, 5, 10))
        : (endDate   ?? DateTime(2025, 5, 20));

    final picked = await showDatePicker(
      context: ctx,
      initialDate: initial,
      firstDate: DateTime(2025, 1, 1),
      lastDate: DateTime(2025, 12, 31),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Colors.blueAccent,
            onPrimary: Colors.white,
            surface: Color(0xFF0E1828),
            onSurface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          startDate = picked;
          // si la fecha inicial es mayor que la final, limpiamos la final
          if (endDate != null && picked.isAfter(endDate!)) endDate = null;
        } else {
          endDate = picked;
          // si la fecha final es menor que la inicial, limpiamos la inicial
          if (startDate != null && picked.isBefore(startDate!)) startDate = null;
        }
        currentPage = 1;
      });
    }
  }

  // ── Color de severidad ──
  Color _severityColor(String v) {
    switch (v) {
      case "Crítico":     return Colors.redAccent;
      case "Advertencia": return Colors.orangeAccent;
      default:            return Colors.greenAccent;
    }
  }

  Color _severityBg(String v) {
    switch (v) {
      case "Crítico":     return Colors.redAccent.withOpacity(0.12);
      case "Advertencia": return Colors.orangeAccent.withOpacity(0.12);
      default:            return Colors.greenAccent.withOpacity(0.10);
    }
  }

  // ══════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AC.bg,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final r = R(constraints.maxWidth);
            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: r.hPad,
                vertical: r.scale(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(r),
                  SizedBox(height: r.scale(20)),
                  _buildFilters(context, r),
                  SizedBox(height: r.scale(20)),
                  _buildTable(r),
                  SizedBox(height: r.scale(20)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ─── Header ──────────────────────────────────────────────
  Widget _buildHeader(R r) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Historial de Eventos",
          style: TextStyle(
            fontSize: r.scale(28),
            fontWeight: FontWeight.bold,
            color: AC.white,
          ),
        ),
        SizedBox(height: r.scale(4)),
        Text(
          "Consulta y analiza todos los eventos del sistema",
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: r.scale(13),
          ),
        ),
      ],
    );
  }

  // ─── Panel de filtros ─────────────────────────────────────
  Widget _buildFilters(BuildContext ctx, R r) {
    return Wrap(
      spacing: r.scale(12),
      runSpacing: r.scale(12),
      children: [
        // Fecha inicial
        _buildDateField(ctx, r, "Fecha inicial", startDate, true),
        // Fecha final
        _buildDateField(ctx, r, "Fecha final",   endDate,   false),
        // Maqueta
        _buildDropdown(r, "Maqueta", maqueta,
          ["Todas","Prensa Hidráulica","Brazo Robótico","Sistema Neumático","Pick & Place"],
          (v) => setState(() { maqueta = v!; currentPage = 1; }),
        ),
        // Tipo evento
        _buildDropdown(r, "Tipo evento", evento,
          ["Todos","Motor iniciado","Paro emergencia","Presión alta",
           "Sensor desconectado","Motor detenido","Error PLC","Temperatura alta","Ciclo completado"],
          (v) => setState(() { evento = v!; currentPage = 1; }),
        ),
        // Severidad
        _buildDropdown(r, "Severidad", severidad,
          ["Todas","Info","Advertencia","Crítico"],
          (v) => setState(() { severidad = v!; currentPage = 1; }),
        ),
        // Botón restablecer
        _buildResetButton(r),
      ],
    );
  }

  Widget _buildDateField(BuildContext ctx, R r, String label,
      DateTime? date, bool isStart) {
    final hasDate = date != null;
    return SizedBox(
      width: r.filterWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  color: AC.muted, fontSize: r.scale(12))),
          SizedBox(height: r.scale(6)),
          GestureDetector(
            onTap: () => _pickDate(ctx, isStart),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: r.scale(12),
                vertical: r.scale(13),
              ),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(12),
                border: hasDate
                    ? Border.all(color: Colors.blueAccent.withOpacity(0.6))
                    : null,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    size: r.scale(14),
                    color: hasDate ? Colors.blueAccent : Colors.white54,
                  ),
                  SizedBox(width: r.scale(8)),
                  Expanded(
                    child: Text(
                      _fmtDate(date),
                      style: TextStyle(
                        fontSize: r.scale(12),
                        color: hasDate ? AC.white : Colors.white54,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  if (hasDate)
                    GestureDetector(
                      onTap: () => setState(() {
                        if (isStart) startDate = null;
                        else         endDate   = null;
                        currentPage = 1;
                      }),
                      child: Icon(Icons.close,
                          size: r.scale(14), color: Colors.white54),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(R r, String label, String value,
      List<String> items, Function(String?) onChanged) {
    return SizedBox(
      width: r.filterWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  color: AC.muted, fontSize: r.scale(12))),
          SizedBox(height: r.scale(6)),
          Container(
            padding: EdgeInsets.symmetric(horizontal: r.scale(10)),
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              underline: const SizedBox(),
              dropdownColor: const Color(0xFF0E1828),
              style: TextStyle(
                  color: AC.white, fontSize: r.scale(13)),
              items: items
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResetButton(R r) {
    return Padding(
      // alinea verticalmente con los campos (label + campo)
      padding: EdgeInsets.only(top: r.scale(18)),
      child: ElevatedButton.icon(
        onPressed: _resetFilters,
        icon: Icon(Icons.restart_alt, size: r.scale(16)),
        label: Text(
          "Restablecer",
          style: TextStyle(fontSize: r.scale(13)),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white10,
          foregroundColor: AC.white,
          padding: EdgeInsets.symmetric(
            horizontal: r.scale(14),
            vertical: r.scale(13),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  // ─── Tabla ────────────────────────────────────────────────
  Widget _buildTable(R r) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(r.scale(14)),
      decoration: BoxDecoration(
        color: AC.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AC.border.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En pantallas pequeñas la tabla hace scroll horizontal
          r.isSmall
              ? SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: r.tableMinWidth,
                    child: _buildTableContent(r),
                  ),
                )
              : _buildTableContent(r),
          SizedBox(height: r.scale(12)),
          _buildPagination(r),
        ],
      ),
    );
  }

  Widget _buildTableContent(R r) {
    return Column(
      children: [
        _buildTableHeader(r),
        SizedBox(
          height: r.tableHeight,
          child: currentRows.isEmpty
              ? _buildEmptyState(r)
              : ListView.builder(
                  physics: const ClampingScrollPhysics(),
                  itemCount: currentRows.length,
                  itemBuilder: (_, i) => _buildTableRow(r, currentRows[i], i),
                ),
        ),
      ],
    );
  }

  Widget _buildTableHeader(R r) {
    final style = TextStyle(
      color: Colors.white60,
      fontSize: r.scale(11),
      fontWeight: FontWeight.w700,
      letterSpacing: 0.8,
    );
    return Container(
      padding: EdgeInsets.symmetric(
          vertical: r.scale(12), horizontal: r.scale(8)),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white24)),
      ),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text("FECHA",     style: style)),
          Expanded(flex: 2, child: Text("MAQUETA",   style: style)),
          Expanded(flex: 2, child: Text("EVENTO",    style: style)),
          Expanded(flex: 2, child: Text("USUARIO",   style: style)),
          Expanded(flex: 1, child: Text("SEVERIDAD", style: style)),
        ],
      ),
    );
  }

  Widget _buildTableRow(R r, Map<String, String> row, int index) {
    final sev = row["severidad"]!;
    return Container(
      padding: EdgeInsets.symmetric(
          vertical: r.scale(13), horizontal: r.scale(8)),
      decoration: BoxDecoration(
        color: index.isEven ? Colors.white.withOpacity(0.02) : Colors.transparent,
        border: const Border(
          bottom: BorderSide(color: Colors.white12),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              row["fecha"]!,
              style: TextStyle(
                  color: AC.white, fontSize: r.scale(12)),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              row["maqueta"]!,
              style: TextStyle(
                  color: AC.white, fontSize: r.scale(12)),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              row["evento"]!,
              style: TextStyle(
                  color: AC.white, fontSize: r.scale(12)),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              row["usuario"]!,
              style: TextStyle(
                  color: Colors.white70, fontSize: r.scale(12)),
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: r.scale(8),
                vertical: r.scale(4),
              ),
              decoration: BoxDecoration(
                color: _severityBg(sev),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                sev,
                style: TextStyle(
                  color: _severityColor(sev),
                  fontSize: r.scale(11),
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(R r) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded,
              color: Colors.white24, size: r.scale(48)),
          SizedBox(height: r.scale(12)),
          Text(
            "Sin registros con los filtros aplicados",
            style: TextStyle(
                color: Colors.white38, fontSize: r.scale(13)),
          ),
        ],
      ),
    );
  }

  // ─── Paginación ───────────────────────────────────────────
  Widget _buildPagination(R r) {
    final filtered = filteredRegistros;
    final start    = (currentPage - 1) * rowsPerPage + 1;
    final end      = ((currentPage - 1) * rowsPerPage + currentRows.length)
        .clamp(0, filtered.length);
    final total    = filtered.length;

    // En móvil: diseño compacto con flechas prev/next
    if (r.isSmall) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            "Mostrando $start–$end de $total registros",
            style: TextStyle(
                color: Colors.grey[400], fontSize: r.scale(11)),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: r.scale(10)),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _pageBtn(r, Icons.chevron_left, currentPage > 1,
                  () => setState(() => currentPage--)),
              SizedBox(width: r.scale(12)),
              Text(
                "Página $currentPage de $totalPages",
                style: TextStyle(
                    color: AC.white, fontSize: r.scale(12)),
              ),
              SizedBox(width: r.scale(12)),
              _pageBtn(r, Icons.chevron_right, currentPage < totalPages,
                  () => setState(() => currentPage++)),
            ],
          ),
        ],
      );
    }

    // Tablet / desktop: texto + botones numerados
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "Mostrando $start a $end de $total registros",
          style: TextStyle(
              color: Colors.grey[400], fontSize: r.scale(12)),
        ),
        _buildPageButtons(r),
      ],
    );
  }

  Widget _pageBtn(R r, IconData icon, bool enabled, VoidCallback onTap) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.all(r.scale(8)),
        decoration: BoxDecoration(
          color: enabled ? Colors.white10 : Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon,
            color: enabled ? AC.white : Colors.white24,
            size: r.scale(18)),
      ),
    );
  }

  Widget _buildPageButtons(R r) {
    // Mostramos máximo 5 páginas centradas alrededor de la actual
    const maxVisible = 5;
    int startP = (currentPage - maxVisible ~/ 2).clamp(1, totalPages);
    int endP   = (startP + maxVisible - 1).clamp(1, totalPages);
    if (endP - startP < maxVisible - 1) {
      startP = (endP - maxVisible + 1).clamp(1, totalPages);
    }

    return Row(
      children: [
        // Botón anterior
        if (currentPage > 1)
          _numBtn(r, '‹', () => setState(() => currentPage--), false),
        ...List.generate(endP - startP + 1, (i) {
          final p = startP + i;
          return _numBtn(r, '$p', () => setState(() => currentPage = p),
              p == currentPage);
        }),
        // Botón siguiente
        if (currentPage < totalPages)
          _numBtn(r, '›', () => setState(() => currentPage++), false),
      ],
    );
  }

  Widget _numBtn(R r, String label, VoidCallback onTap, bool active) {
    return Padding(
      padding: EdgeInsets.only(left: r.scale(5)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          constraints: BoxConstraints(
              minWidth: r.scale(36), minHeight: r.scale(34)),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? Colors.blueAccent : Colors.white10,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: AC.white,
              fontSize: r.scale(13),
              fontWeight:
                  active ? FontWeight.w700 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}