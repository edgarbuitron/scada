import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'genrarPDF.dart';

void main() {
  runApp(const AnalyticsApp());
}

class AnalyticsApp extends StatelessWidget {
  const AnalyticsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Analytics / Reportes',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0D1117),
      ),
      home: const AnalyticsDashboard(),
    );
  }
}

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
  bool get isMedium => _w >= 600 && _w < 1024;
  bool get isLarge => _w >= 1024;

  double scale(double base) {
    if (_w < 400) return base * 0.78;
    if (_w < 600) return base * 0.88;
    if (_w < 900) return base * 0.94;
    return base;
  }

  double get hPad {
    if (_w < 400) return 12;
    if (_w < 600) return 16;
    if (_w < 900) return 20;
    return 28;
  }

  double get chartHeight {
    if (_w < 400) return 140;
    if (_w < 600) return 160;
    if (_w < 900) return 175;
    return 190;
  }

  double get pieSize {
    if (_w < 600) return 130;
    if (_w < 900) return 150;
    return 180;
  }
}

class StationAnalyticsData {
  final String name;
  final String produccionTotal;
  final String tiempoActivoPorcentaje;
  final String fallasTotales;
  final String consumoTotal;
  final List<double> produccion;
  final List<double> tiempoActivo;
  final List<double> fallas;
  final List<double> consumo;
  final List<_PieSection> pieData;

  const StationAnalyticsData({
    required this.name,
    required this.produccionTotal,
    required this.tiempoActivoPorcentaje,
    required this.fallasTotales,
    required this.consumoTotal,
    required this.produccion,
    required this.tiempoActivo,
    required this.fallas,
    required this.consumo,
    required this.pieData,
  });
}

class DashboardData {
  static const List<String> fechas = [
    '14/05',
    '15/05',
    '16/05',
    '17/05',
    '18/05',
    '19/05',
    '20/05'
  ];

  static final List<StationAnalyticsData> stations = [
    // 0: General
    const StationAnalyticsData(
      name: 'General',
      produccionTotal: '12,540',
      tiempoActivoPorcentaje: '87.6%',
      fallasTotales: '24',
      consumoTotal: '1,245',
      produccion: [1000, 1200, 1800, 2200, 2500, 2300, 3000],
      tiempoActivo: [65, 55, 75, 50, 70, 65, 70],
      fallas: [5, 8, 4, 10, 6, 5, 7],
      consumo: [500, 480, 550, 520, 540, 460, 580],
      pieData: [
        _PieSection('Eléctrico', 40, AppColors.blue),
        _PieSection('Neumático', 25, AppColors.yellow),
        _PieSection('Mecánico', 20, AppColors.green),
        _PieSection('Sensor', 15, AppColors.red),
      ],
    ),
    // 1: Neumático
    const StationAnalyticsData(
      name: 'Neumático',
      produccionTotal: '3,120',
      tiempoActivoPorcentaje: '92.1%',
      fallasTotales: '5',
      consumoTotal: '310',
      produccion: [250, 300, 450, 550, 600, 580, 720],
      tiempoActivo: [90, 88, 95, 91, 93, 89, 94],
      fallas: [1, 2, 0, 1, 0, 1, 0],
      consumo: [120, 110, 130, 125, 135, 115, 140],
      pieData: [
        _PieSection('Válvula', 50, AppColors.blue),
        _PieSection('Cilindro', 30, AppColors.yellow),
        _PieSection('Manguera', 15, AppColors.green),
        _PieSection('Sensor', 5, AppColors.red),
      ],
    ),
    // 2: Maquinados
    const StationAnalyticsData(
      name: 'Maquinados',
      produccionTotal: '2,890',
      tiempoActivoPorcentaje: '85.3%',
      fallasTotales: '8',
      consumoTotal: '450',
      produccion: [200, 280, 400, 500, 650, 550, 680],
      tiempoActivo: [80, 82, 88, 79, 85, 81, 87],
      fallas: [2, 1, 3, 0, 1, 1, 0],
      consumo: [180, 170, 200, 190, 210, 180, 220],
      pieData: [
        _PieSection('Motor', 60, AppColors.blue),
        _PieSection('Banda', 20, AppColors.yellow),
        _PieSection('CNC', 15, AppColors.green),
        _PieSection('Eléctrico', 5, AppColors.red),
      ],
    ),
    // 3: Robot
    const StationAnalyticsData(
      name: 'Robot 3 Ejes',
      produccionTotal: '3,510',
      tiempoActivoPorcentaje: '95.8%',
      fallasTotales: '3',
      consumoTotal: '280',
      produccion: [300, 350, 500, 600, 700, 650, 810],
      tiempoActivo: [95, 96, 94, 97, 98, 93, 99],
      fallas: [0, 0, 1, 0, 1, 0, 1],
      consumo: [100, 105, 110, 115, 120, 100, 125],
      pieData: [
        _PieSection('Gripper', 40, AppColors.blue),
        _PieSection('Eje Z', 30, AppColors.yellow),
        _PieSection('Eje X/Y', 20, AppColors.green),
        _PieSection('Firmware', 10, AppColors.red),
      ],
    ),
    // 4: Prensado
    const StationAnalyticsData(
      name: 'Prensado',
      produccionTotal: '3,020',
      tiempoActivoPorcentaje: '82.0%',
      fallasTotales: '8',
      consumoTotal: '205',
      produccion: [250, 270, 450, 550, 650, 600, 700],
      tiempoActivo: [78, 80, 85, 75, 88, 79, 83],
      fallas: [2, 3, 0, 1, 1, 1, 0],
      consumo: [80, 75, 90, 85, 95, 80, 100],
      pieData: [
        _PieSection('Hidráulico', 55, AppColors.blue),
        _PieSection('Molde', 25, AppColors.yellow),
        _PieSection('Eléctrico', 15, AppColors.green),
        _PieSection('Otros', 5, AppColors.red),
      ],
    ),
  ];
}

class AnalyticsDashboard extends StatefulWidget {
  const AnalyticsDashboard({super.key});

  @override
  State<AnalyticsDashboard> createState() => _AnalyticsDashboardState();
}

class _AnalyticsDashboardState extends State<AnalyticsDashboard> {
  int _selectedSectionIndex = 0;
  final List<String> _sections = [
    'General',
    'Neumático',
    'Maquinados',
    'Robot 3 Ejes',
    'Prensado'
  ];

  void _onSectionSelected(int index) {
    setState(() {
      _selectedSectionIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final StationAnalyticsData currentData =
        DashboardData.stations[_selectedSectionIndex];

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final r = R(constraints.maxWidth);
          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: r.hPad,
              vertical: r.scale(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DashboardHeader(r: r),
                SizedBox(height: r.scale(24)),
                _SectionTabs(
                  r: r,
                  sections: _sections,
                  selectedIndex: _selectedSectionIndex,
                  onSelected: _onSectionSelected,
                ),
                SizedBox(height: r.scale(24)),
                _KPIRow(r: r, data: currentData),
                SizedBox(height: r.scale(28)),
                _SectionLabel(
                    label: 'Resumen de ${_sections[_selectedSectionIndex]}',
                    r: r),
                SizedBox(height: r.scale(16)),
                _TopChartsRow(r: r, data: currentData),
                SizedBox(height: r.scale(20)),
                _BottomChartsRow(r: r, data: currentData),
                SizedBox(height: r.scale(24)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  final R r;
  const _DashboardHeader({required this.r});

  @override
  Widget build(BuildContext context) {
    if (r.isSmall) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TitleBlock(r: r),
          SizedBox(height: r.scale(12)),
          Row(
            children: [
              Flexible(child: _DateRangePicker(r: r)),
              SizedBox(width: r.scale(10)),
              _GenerateReportButton(r: r),
            ],
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(child: _TitleBlock(r: r)),
        SizedBox(width: r.scale(12)),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DateRangePicker(r: r),
            SizedBox(width: r.scale(12)),
            _GenerateReportButton(r: r),
          ],
        ),
      ],
    );
  }
}

class _TitleBlock extends StatelessWidget {
  final R r;
  const _TitleBlock({required this.r});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Análisis',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: r.scale(22),
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        SizedBox(height: r.scale(4)),
        Text(
          'Análisis y generación de reportes del sistema',
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: r.scale(13),
          ),
        ),
      ],
    );
  }
}

class _DateRangePicker extends StatelessWidget {
  final R r;
  const _DateRangePicker({required this.r});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: r.scale(14),
        vertical: r.scale(10),
      ),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '01/05/2025 - 20/05/2025',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: r.scale(12),
            ),
          ),
          SizedBox(width: r.scale(8)),
          Icon(Icons.calendar_today_outlined,
              color: AppColors.textMuted, size: r.scale(14)),
        ],
      ),
    );
  }
}

class _GenerateReportButton extends StatelessWidget {
  final R r;
  const _GenerateReportButton({required this.r});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () {
        showDialog(
          context: context,
          barrierDismissible: true,
          barrierColor: Colors.black.withOpacity(0.7),
          builder: (_) => const GenerarReporteDialog(),
        );
      },
      icon: Icon(Icons.download_rounded, size: r.scale(15)),
      label: Text(
        r.isSmall ? 'Reporte' : 'Generar Reporte',
        style: TextStyle(
          fontSize: r.scale(13),
          fontWeight: FontWeight.w600,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.blue,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(
          horizontal: r.scale(14),
          vertical: r.scale(11),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        elevation: 0,
      ),
    );
  }
}

class _SectionTabs extends StatelessWidget {
  final R r;
  final List<String> sections;
  final int selectedIndex;
  final Function(int) onSelected;

  const _SectionTabs({
    required this.r,
    required this.sections,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(sections.length, (index) {
          final isSelected = index == selectedIndex;
          return GestureDetector(
            onTap: () => onSelected(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: EdgeInsets.only(right: r.scale(10)),
              padding: EdgeInsets.symmetric(
                horizontal: r.scale(16),
                vertical: r.scale(8),
              ),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.blue : AppColors.card,
                borderRadius: BorderRadius.circular(8),
                border: isSelected ? null : Border.all(color: AppColors.border),
              ),
              child: Text(
                sections[index],
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: r.scale(13),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final R r;
  const _SectionLabel({required this.label, required this.r});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        color: AppColors.textPrimary,
        fontSize: r.scale(17),
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _KPIRow extends StatelessWidget {
  final R r;
  final StationAnalyticsData data;
  const _KPIRow({required this.r, required this.data});

  Widget _buildCard(String title, String subtitle, String value, String unit,
      IconData icon, Color iconColor, Color iconBg) {
    return _KPICard(
      r: r,
      title: title,
      subtitle: subtitle,
      value: value,
      unit: unit,
      icon: icon,
      iconColor: iconColor,
      iconBgColor: iconBg,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cards = [
      _buildCard(
          'Producción',
          'Total producido',
          data.produccionTotal,
          'unidades',
          Icons.bar_chart_rounded,
          AppColors.blue,
          AppColors.blue.withOpacity(0.15)),
      _buildCard(
          'Tiempo Activo',
          'Disponibilidad',
          data.tiempoActivoPorcentaje,
          '',
          Icons.access_time_rounded,
          AppColors.green,
          AppColors.green.withOpacity(0.15)),
      _buildCard(
          'Fallas',
          'Total fallos',
          data.fallasTotales,
          '',
          Icons.warning_amber_rounded,
          AppColors.red,
          AppColors.red.withOpacity(0.15)),
      _buildCard(
          'Consumo',
          'Energía utilizada',
          data.consumoTotal,
          'kWh',
          Icons.bolt_rounded,
          AppColors.yellow,
          AppColors.yellow.withOpacity(0.15)),
    ];

    if (r.isSmall) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: cards[0]),
              SizedBox(width: r.scale(12)),
              Expanded(child: cards[1]),
            ],
          ),
          SizedBox(height: r.scale(12)),
          Row(
            children: [
              Expanded(child: cards[2]),
              SizedBox(width: r.scale(12)),
              Expanded(child: cards[3]),
            ],
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: cards[0]),
        SizedBox(width: r.scale(16)),
        Expanded(child: cards[1]),
        SizedBox(width: r.scale(16)),
        Expanded(child: cards[2]),
        SizedBox(width: r.scale(16)),
        Expanded(child: cards[3]),
      ],
    );
  }
}

class _KPICard extends StatelessWidget {
  final R r;
  final String title;
  final String subtitle;
  final String value;
  final String unit;
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;

  const _KPICard({
    required this.r,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.unit,
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
  });

  @override
  Widget build(BuildContext context) {
    final iconSize = r.scale(48);
    final iconInner = r.scale(26);
    final valueFz = r.scale(r.isSmall ? 24 : 30);

    return Container(
      padding: EdgeInsets.all(r.scale(16)),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: r.scale(13),
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: r.scale(2)),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: r.scale(10),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: r.scale(10)),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: valueFz,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                if (unit.isNotEmpty)
                  Text(
                    unit,
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: r.scale(10),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(width: r.scale(8)),
          Container(
            width: iconSize,
            height: iconSize,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: iconInner),
          ),
        ],
      ),
    );
  }
}

class _TopChartsRow extends StatelessWidget {
  final R r;
  final StationAnalyticsData data;
  const _TopChartsRow({required this.r, required this.data});

  static List<FlSpot> _spotsFrom(List<double> values) =>
      List.generate(values.length, (i) => FlSpot(i.toDouble(), values[i]));

  @override
  Widget build(BuildContext context) {
    final charts = [
      _BarChartCard(r: r, data: data.produccion),
      _LineChartCard(
        r: r,
        title: 'Tiempo activo (%)',
        color: AppColors.green,
        spots: _spotsFrom(data.tiempoActivo),
        maxY: 100,
        interval: 25,
      ),
      _LineChartCard(
        r: r,
        title: 'Fallas por día',
        color: AppColors.red,
        spots: _spotsFrom(data.fallas),
        maxY: 15,
        interval: 5,
      ),
    ];

    if (r.isSmall) {
      return Column(
        children: [
          charts[0],
          SizedBox(height: r.scale(16)),
          charts[1],
          SizedBox(height: r.scale(16)),
          charts[2],
        ],
      );
    }

    if (r.isMedium) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: charts[0]),
              SizedBox(width: r.scale(14)),
              Expanded(child: charts[1]),
            ],
          ),
          SizedBox(height: r.scale(14)),
          SizedBox(
            width: double.infinity,
            child: charts[2],
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: charts[0]),
        SizedBox(width: r.scale(16)),
        Expanded(child: charts[1]),
        SizedBox(width: r.scale(16)),
        Expanded(child: charts[2]),
      ],
    );
  }
}

class _BarChartCard extends StatelessWidget {
  final R r;
  final List<double> data;
  const _BarChartCard({required this.r, required this.data});

  @override
  Widget build(BuildContext context) {
    final barWidth = r.scale(18);

    return _ChartCard(
      r: r,
      title: 'Producción por día (unidades)',
      child: SizedBox(
        height: r.chartHeight,
        child: BarChart(
          BarChartData(
            backgroundColor: Colors.transparent,
            maxY: 3500,
            barGroups: List.generate(
              data.length,
              (i) => BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: data[i],
                    color: AppColors.blue,
                    width: barWidth,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(4)),
                  ),
                ],
              ),
            ),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: 1000,
              getDrawingHorizontalLine: (_) =>
                  const FlLine(color: Color(0xFF1F2937), strokeWidth: 1),
            ),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles:
                  AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: r.scale(38),
                  interval: 1000,
                  getTitlesWidget: (v, _) => Text(
                    v.toInt() == 0
                        ? '0'
                        : '${(v / 1000).toStringAsFixed(0)},000',
                    style: TextStyle(
                        color: AppColors.textMuted, fontSize: r.scale(8)),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: r.scale(22),
                  getTitlesWidget: (v, _) {
                    final idx = v.toInt();
                    if (idx < 0 || idx >= DashboardData.fechas.length) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        DashboardData.fechas[idx],
                        style: TextStyle(
                            color: AppColors.textMuted, fontSize: r.scale(8)),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LineChartCard extends StatelessWidget {
  final R r;
  final String title;
  final Color color;
  final List<FlSpot> spots;
  final double maxY;
  final double interval;

  const _LineChartCard({
    required this.r,
    required this.title,
    required this.color,
    required this.spots,
    required this.maxY,
    required this.interval,
  });

  @override
  Widget build(BuildContext context) {
    return _ChartCard(
      r: r,
      title: title,
      child: SizedBox(
        height: r.chartHeight,
        child: LineChart(
          LineChartData(
            minY: 0,
            maxY: maxY,
            clipData: FlClipData.all(),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: interval,
              getDrawingHorizontalLine: (_) =>
                  const FlLine(color: Color(0xFF1F2937), strokeWidth: 1),
            ),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles:
                  AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: r.scale(32),
                  interval: interval,
                  getTitlesWidget: (v, _) => Text(
                    v.toInt().toString(),
                    style: TextStyle(
                        color: AppColors.textMuted, fontSize: r.scale(8)),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: r.scale(22),
                  getTitlesWidget: (v, _) {
                    final idx = v.toInt();
                    if (idx < 0 || idx >= DashboardData.fechas.length) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        DashboardData.fechas[idx],
                        style: TextStyle(
                            color: AppColors.textMuted, fontSize: r.scale(8)),
                      ),
                    );
                  },
                ),
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                curveSmoothness: 0.35,
                color: color,
                barWidth: r.scale(2.2),
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, pct, bar, idx) => FlDotCirclePainter(
                    radius: r.scale(3.5),
                    color: color,
                    strokeWidth: r.scale(2),
                    strokeColor: AppColors.card,
                  ),
                ),
                belowBarData: BarAreaData(
                  show: true,
                  color: color.withOpacity(0.08),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomChartsRow extends StatelessWidget {
  final R r;
  final StationAnalyticsData data;
  const _BottomChartsRow({required this.r, required this.data});

  @override
  Widget build(BuildContext context) {
    final pie = _PieChartCard(r: r, sections: data.pieData);
    final consumoCard = _LineChartCard(
      r: r,
      title: 'Consumo de energía (kWh)',
      color: AppColors.yellow,
      spots: List.generate(
          data.consumo.length, (i) => FlSpot(i.toDouble(), data.consumo[i])),
      maxY: 750,
      interval: 250,
    );

    if (r.isSmall) {
      return Column(
        children: [
          pie,
          SizedBox(height: r.scale(16)),
          consumoCard,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 2, child: pie),
        SizedBox(width: r.scale(16)),
        Expanded(flex: 3, child: consumoCard),
      ],
    );
  }
}

class _PieChartCard extends StatelessWidget {
  final R r;
  final List<_PieSection> sections;
  const _PieChartCard({required this.r, required this.sections});

  @override
  Widget build(BuildContext context) {
    final pieSize = r.pieSize;
    final radius = pieSize * 0.4;

    return _ChartCard(
      r: r,
      title: 'Distribución de fallas por tipo',
      child: Padding(
        padding: EdgeInsets.only(top: r.scale(8)),
        child: r.isSmall
            ? Column(
                children: [
                  SizedBox(
                    width: pieSize,
                    height: pieSize,
                    child: _buildPie(radius),
                  ),
                  SizedBox(height: r.scale(14)),
                  _buildLegendRow(),
                ],
              )
            : Row(
                children: [
                  SizedBox(
                    width: pieSize,
                    height: pieSize,
                    child: _buildPie(radius),
                  ),
                  SizedBox(width: r.scale(20)),
                  Flexible(child: _buildLegendColumn()),
                ],
              ),
      ),
    );
  }

  PieChart _buildPie(double radius) {
    return PieChart(
      PieChartData(
        sections: sections
            .map((s) => PieChartSectionData(
                  value: s.value,
                  color: s.color,
                  title: '',
                  radius: radius,
                ))
            .toList(),
        sectionsSpace: 2,
        centerSpaceRadius: 0,
      ),
    );
  }

  Widget _buildLegendColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: sections
          .map((s) => Padding(
                padding: EdgeInsets.only(bottom: r.scale(12)),
                child: _LegendItem(section: s, r: r),
              ))
          .toList(),
    );
  }

  Widget _buildLegendRow() {
    return Wrap(
      spacing: r.scale(12),
      runSpacing: r.scale(8),
      children: sections.map((s) => _LegendItem(section: s, r: r)).toList(),
    );
  }
}

class _PieSection {
  final String label;
  final double value;
  final Color color;
  const _PieSection(this.label, this.value, this.color);
}

class _LegendItem extends StatelessWidget {
  final _PieSection section;
  final R r;
  const _LegendItem({required this.section, required this.r});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: r.scale(11),
          height: r.scale(11),
          decoration:
              BoxDecoration(color: section.color, shape: BoxShape.circle),
        ),
        SizedBox(width: r.scale(6)),
        Text(
          section.label,
          style: TextStyle(color: AppColors.textPrimary, fontSize: r.scale(12)),
        ),
        SizedBox(width: r.scale(8)),
        Text(
          '${section.value.toInt()}%',
          style: TextStyle(color: AppColors.textMuted, fontSize: r.scale(12)),
        ),
      ],
    );
  }
}

class _ChartCard extends StatelessWidget {
  final R r;
  final String title;
  final Widget child;

  const _ChartCard({required this.r, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          r.scale(16), r.scale(14), r.scale(16), r.scale(10)),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: r.scale(13),
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: r.scale(12)),
          child,
        ],
      ),
    );
  }
}
