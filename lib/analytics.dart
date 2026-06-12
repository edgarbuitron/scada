import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'generar_reporte.dart';
import 'generar_excel.dart';
import 'usage_monitor.dart';

class AppColors {
  static const bg = Color(0xFF0D1117);
  static const card = Color(0xFF161B27);
  static const border = Color(0xFF1F2937);
  static const textPrimary = Colors.white;
  static const textMuted = Color(0xFF6B7280);
  static const blue = Color(0xFF3B82F6);
  static const green = Color(0xFF10B981);
  static const red = Color(0xFFEF4444);
  static const yellow = Color(0xFFF59E0B);
}

class R {
  final double _w;
  const R(this._w);
  bool get isSmall => _w < 600;
  double scale(double base) => _w < 600 ? base * 0.88 : base;
  double get hPad => _w < 600 ? 16 : 28;
}

class StationAnalyticsData {
  final String name;
  final String produccionTotal;
  final String tiempoActivoRaw;
  final String fallasTotales;
  final String consumoTotal;
  final List<double> produccion;
  final List<double> tiempoActivo;
  final List<double> fallas;
  final List<double> consumo;
  final List<PieSection> pieData;

  const StationAnalyticsData({
    required this.name,
    required this.produccionTotal,
    required this.tiempoActivoRaw,
    required this.fallasTotales,
    required this.consumoTotal,
    required this.produccion,
    required this.tiempoActivo,
    required this.fallas,
    required this.consumo,
    required this.pieData,
  });
}

class AnalyticsDashboard extends StatefulWidget {
  const AnalyticsDashboard({super.key});
  @override
  State<AnalyticsDashboard> createState() => _AnalyticsDashboardState();
}

class _AnalyticsDashboardState extends State<AnalyticsDashboard> {
  int _selectedSectionIndex = 0;
  late DateTimeRange _selectedDateRange;
  final List<String> _sections = ['General', 'Neumático', 'Maquinados', 'Robot 3 Ejes', 'Prensado'];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDateRange = DateTimeRange(start: now.subtract(const Duration(days: 6)), end: now);
  }

  StationAnalyticsData _buildDisplayData(UsageMonitor monitor) {
    String prod, time, fail, cons;
    List<double> listProd, listFail, listCons;

    if (_selectedSectionIndex == 0) {
      prod = monitor.totalProduction.toString();
      time = monitor.formatDuration(monitor.totalTime);
      fail = monitor.totalFailures.toString();
      cons = monitor.totalConsumption.toStringAsFixed(2);
      listProd = [10, 15, 8, 22, 12, 18, monitor.totalProduction.toDouble()];
      listFail = [1, 0, 2, 1, 0, 1, monitor.totalFailures.toDouble()];
      listCons = [1.2, 1.4, 0.9, 2.1, 1.3, 1.7, monitor.totalConsumption];
    } else {
      String stationId = '';
      switch(_selectedSectionIndex) {
        case 1: stationId = 'neumatico'; break;
        case 2: stationId = 'maquinados'; break;
        case 3: stationId = 'robot'; break;
        case 4: stationId = 'prensado'; break;
      }
      prod = monitor.getStationProduction(stationId).toString();
      time = monitor.formatDuration(monitor.getStationTime(stationId));
      fail = monitor.getStationFailures(stationId).toString();
      cons = monitor.getStationConsumption(stationId).toStringAsFixed(2);
      listProd = [2, 4, 3, 5, 2, 4, monitor.getStationProduction(stationId).toDouble()];
      listFail = [0, 0, 1, 0, 0, 0, monitor.getStationFailures(stationId).toDouble()];
      listCons = [0.3, 0.4, 0.2, 0.5, 0.3, 0.4, monitor.getStationConsumption(stationId)];
    }

    return StationAnalyticsData(
      name: _sections[_selectedSectionIndex],
      produccionTotal: prod,
      tiempoActivoRaw: time,
      fallasTotales: fail,
      consumoTotal: cons,
      produccion: listProd,
      tiempoActivo: [85, 82, 88, 80, 84, 86, 90],
      fallas: listFail,
      consumo: listCons,
      pieData: [
        const PieSection('Eléctrico', 40, AppColors.blue),
        const PieSection('Neumático', 25, AppColors.yellow),
        const PieSection('Mecánico', 20, AppColors.green),
        const PieSection('Sensor', 15, AppColors.red),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final usageMonitor = Provider.of<UsageMonitor>(context);
    final displayData = _buildDisplayData(usageMonitor);
    final days = _selectedDateRange.duration.inDays + 1;
    final dateLabels = List.generate(days, (i) => DateFormat('dd/MM').format(_selectedDateRange.start.add(Duration(days: i))));

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final r = R(constraints.maxWidth);
          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: r.hPad, vertical: r.scale(24)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Análisis de Planta', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => showDialog(
                            context: context,
                            builder: (_) => GenerarExcelDialog(
                              maqueta: displayData.name,
                              dateRange: _selectedDateRange,
                              data: displayData,
                              dateLabels: dateLabels,
                            ),
                          ),
                          icon: const Icon(Icons.table_chart_rounded, size: 16),
                          label: const Text('Excel'),
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.green, foregroundColor: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: () => showDialog(context: context, builder: (_) => GenerarReporteDialog(maqueta: displayData.name, dateRange: _selectedDateRange, data: displayData, dateLabels: dateLabels)),
                          icon: const Icon(Icons.download_rounded, size: 16),
                          label: const Text('Reporte'),
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.blue, foregroundColor: Colors.white),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _SectionTabs(r: r, sections: _sections, selectedIndex: _selectedSectionIndex, onSelected: (i) => setState(() => _selectedSectionIndex = i)),
                const SizedBox(height: 24),
                _KPIRow(r: r, data: displayData, selectedSectionIndex: _selectedSectionIndex),
                const SizedBox(height: 28),
                Text('Resumen de ${displayData.name} (Datos Estables)', style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _TopChartsRow(r: r, data: displayData, dateLabels: dateLabels, selectedSectionIndex: _selectedSectionIndex),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SectionTabs extends StatelessWidget {
  final R r; final List<String> sections; final int selectedIndex; final Function(int) onSelected;
  const _SectionTabs({required this.r, required this.sections, required this.selectedIndex, required this.onSelected});
  @override
  Widget build(BuildContext context) => SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: List.generate(sections.length, (i) => GestureDetector(onTap: () => onSelected(i), child: Container(margin: const EdgeInsets.only(right: 10), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(color: i == selectedIndex ? AppColors.blue : AppColors.card, borderRadius: BorderRadius.circular(8)), child: Text(sections[i], style: const TextStyle(color: Colors.white, fontSize: 13)))))));
}

class _KPIRow extends StatelessWidget {
  final R r; final StationAnalyticsData data; final int selectedSectionIndex;
  const _KPIRow({required this.r, required this.data, required this.selectedSectionIndex});
  @override
  Widget build(BuildContext context) {
    final cards = [
      _KPICard(r: r, title: 'Producción', subtitle: 'Total piezas', value: data.produccionTotal, unit: 'unid.', icon: Icons.bar_chart, color: AppColors.blue),
      _KPICard(r: r, title: 'Tiempo Activo', subtitle: selectedSectionIndex == 0 ? 'Total planta' : 'Uso real', value: data.tiempoActivoRaw, unit: '', icon: Icons.timer, color: AppColors.green),
      _KPICard(r: r, title: 'Fallas', subtitle: 'Paros Emerg.', value: data.fallasTotales, unit: 'alertas', icon: Icons.warning, color: AppColors.red),
      _KPICard(r: r, title: 'Consumo', subtitle: 'Lectura real', value: data.consumoTotal, unit: 'kWh', icon: Icons.bolt, color: AppColors.yellow),
    ];
    return r.isSmall ? Column(children: [Row(children: [Expanded(child: cards[0]), const SizedBox(width: 12), Expanded(child: cards[1])]), const SizedBox(height: 12), Row(children: [Expanded(child: cards[2]), const SizedBox(width: 12), Expanded(child: cards[3])])]) : Row(children: cards.map((c) => Expanded(child: Padding(padding: const EdgeInsets.only(right: 16), child: c))).toList());
  }
}

class _KPICard extends StatelessWidget {
  final R r; final String title, subtitle, value, unit; final IconData icon; final Color color;
  const _KPICard({required this.r, required this.title, required this.subtitle, required this.value, required this.unit, required this.icon, required this.color});
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)), child: Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)), Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)), Text(unit, style: const TextStyle(fontSize: 10, color: AppColors.textMuted))])), Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: color, size: 20))]));
}

class _TopChartsRow extends StatelessWidget {
  final R r; final StationAnalyticsData data; final List<String> dateLabels; final int selectedSectionIndex;
  const _TopChartsRow({required this.r, required this.data, required this.dateLabels, required this.selectedSectionIndex});
  @override
  Widget build(BuildContext context) => Column(children: [
    _ChartCard(
      r: r,
      title: 'Producción Acumulada',
      child: SizedBox(
        height: 150,
        child: BarChart(
          BarChartData(
            maxY: 50,
            barGroups: List.generate(data.produccion.length, (i) => BarChartGroupData(x: i, barRods: [BarChartRodData(toY: data.produccion[i], color: AppColors.blue, width: 12)])),
            borderData: FlBorderData(show: false),
            gridData: const FlGridData(show: false),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30, getTitlesWidget: (v, _) => Text(v.toInt().toString(), style: const TextStyle(color: AppColors.textMuted, fontSize: 8)))),
              bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false))
            )
          )
        )
      )
    ),
    const SizedBox(height: 16),
    _ChartCard(
      r: r,
      title: 'Tiempo activo (%)',
      child: SizedBox(
        height: 150,
        child: LineChart(
          LineChartData(
            maxY: 100,
            lineBarsData: [LineChartBarData(spots: List.generate(data.tiempoActivo.length, (i) => FlSpot(i.toDouble(), data.tiempoActivo[i])), color: AppColors.green, isCurved: true, belowBarData: BarAreaData(show: true, color: AppColors.green.withValues(alpha: 0.1)))],
            borderData: FlBorderData(show: false),
            gridData: const FlGridData(show: false),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30, getTitlesWidget: (v, _) => Text(v.toInt().toString(), style: const TextStyle(color: AppColors.textMuted, fontSize: 8)))),
              bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false))
            )
          )
        )
      )
    ),
    const SizedBox(height: 16),
    _ChartCard(
      r: r,
      title: 'Fallas por día',
      child: SizedBox(
        height: 150,
        child: LineChart(
          LineChartData(
            maxY: 15,
            lineBarsData: [LineChartBarData(spots: List.generate(data.fallas.length, (i) => FlSpot(i.toDouble(), data.fallas[i])), color: AppColors.red, isCurved: true, belowBarData: BarAreaData(show: true, color: AppColors.red.withValues(alpha: 0.1)))],
            borderData: FlBorderData(show: false),
            gridData: const FlGridData(show: false),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30, getTitlesWidget: (v, _) => Text(v.toInt().toString(), style: const TextStyle(color: AppColors.textMuted, fontSize: 8)))),
              bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false))
            )
          )
        )
      )
    ),
    const SizedBox(height: 16),
    _ChartCard(
      r: r,
      title: 'Histórico de Consumo (kWh)',
      child: SizedBox(
        height: 150,
        child: LineChart(
          LineChartData(
            maxY: 10,
            lineBarsData: [LineChartBarData(spots: List.generate(data.consumo.length, (i) => FlSpot(i.toDouble(), data.consumo[i])), color: AppColors.yellow, isCurved: true, belowBarData: BarAreaData(show: true, color: AppColors.yellow.withValues(alpha: 0.1)))],
            borderData: FlBorderData(show: false),
            gridData: const FlGridData(show: false),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30, getTitlesWidget: (v, _) => Text(v.toInt().toString(), style: const TextStyle(color: AppColors.textMuted, fontSize: 8)))),
              bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false))
            )
          )
        )
      )
    ),
    if (selectedSectionIndex == 0) ...[
      const SizedBox(height: 16),
      _PieChartCard(r: r, sections: data.pieData),
    ],
  ]);
}

class _ChartCard extends StatelessWidget {
  final R r; final String title; final Widget child;
  const _ChartCard({required this.r, required this.title, required this.child});
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)), const SizedBox(height: 12), child]));
}

class _PieChartCard extends StatelessWidget {
  final R r; final List<PieSection> sections;
  const _PieChartCard({required this.r, required this.sections});
  @override
  Widget build(BuildContext context) {
    return _ChartCard(r: r, title: 'Distribución de Fallas', child: SizedBox(height: 130, child: PieChart(PieChartData(sections: sections.map((s) => PieChartSectionData(value: s.value, color: s.color, title: '', radius: 40)).toList(), centerSpaceRadius: 30))));
  }
}

class PieSection { final String label; final double value; final Color color; const PieSection(this.label, this.value, this.color); }
