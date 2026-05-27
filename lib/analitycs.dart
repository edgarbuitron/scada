import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'generar_reporte.dart';

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
  static const List<String> fechasOriginales = [
    '14/05',
    '15/05',
    '16/05',
    '17/05',
    '18/05',
    '19/05',
    '20/05'
  ];

  static final List<StationAnalyticsData> stations = [
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
  ];
}

class AnalyticsDashboard extends StatefulWidget {
  const AnalyticsDashboard({super.key});

  @override
  State<AnalyticsDashboard> createState() => _AnalyticsDashboardState();
}

class _AnalyticsDashboardState extends State<AnalyticsDashboard> {
  int _selectedSectionIndex = 0;
  late StationAnalyticsData _currentDisplayData;
  late DateTimeRange _selectedDateRange;
  List<String> _dateLabels = [];

  final List<String> _sections = [
    'General',
    'Neumático',
    'Maquinados',
    'Robot 3 Ejes',
    'Prensado'
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDateRange = DateTimeRange(start: now.subtract(const Duration(days: 6)), end: now);
    _updateDashboardData();
  }

  void _onSectionSelected(int index) {
    setState(() {
      _selectedSectionIndex = index;
      _updateDashboardData();
    });
  }

  Future<void> _pickDateRange() async {
    final newDateRange = await showDialog<DateTimeRange>(
      context: context,
      builder: (context) => _CustomDateRangeDialog(initialDateRange: _selectedDateRange),
    );

    if (newDateRange != null) {
      setState(() {
        _selectedDateRange = newDateRange;
        _updateDashboardData();
      });
    }
  }

  void _updateDashboardData() {
    final random = Random();
    final originalData = DashboardData.stations[0]; // Simplified for this example
    final days = _selectedDateRange.duration.inDays + 1;
    if (days <= 0) return;

    setState(() {
      _currentDisplayData = StationAnalyticsData(
        name: originalData.name,
        produccionTotal: NumberFormat('#,###').format(random.nextInt(5000) + (days * 500)),
        tiempoActivoPorcentaje: '${(random.nextDouble() * 15 + 80).toStringAsFixed(1)}%',
        fallasTotales: (random.nextInt(5) + (days / 2).floor()).toString(),
        consumoTotal: NumberFormat('#,###').format(random.nextInt(800) + (days * 100)),
        produccion: List.generate(days, (_) => random.nextDouble() * 3000 + 500),
        tiempoActivo: List.generate(days, (_) => random.nextDouble() * 20 + 78),
        fallas: List.generate(days, (_) => random.nextDouble() * 3),
        consumo: List.generate(days, (_) => random.nextDouble() * 500 + 100),
        pieData: originalData.pieData.map((e) => _PieSection(e.label, random.nextDouble() * 100, e.color)).toList(),
      );

      _dateLabels = List.generate(days, (i) {
        final date = _selectedDateRange.start.add(Duration(days: i));
        return DateFormat('dd/MM').format(date);
      });
    });
  }


  @override
  Widget build(BuildContext context) {
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
                _DashboardHeader(
                  r: r,
                  onDateTap: _pickDateRange,
                  selectedDateRange: _selectedDateRange,
                  maqueta: _sections[_selectedSectionIndex], 
                  data: _currentDisplayData,
                  dateLabels: _dateLabels,
                ),
                SizedBox(height: r.scale(24)),
                _SectionTabs(
                  r: r,
                  sections: _sections,
                  selectedIndex: _selectedSectionIndex,
                  onSelected: _onSectionSelected,
                ),
                SizedBox(height: r.scale(24)),
                _KPIRow(r: r, data: _currentDisplayData),
                SizedBox(height: r.scale(28)),
                _SectionLabel(
                    label: 'Resumen de ${_sections[_selectedSectionIndex]} en el período seleccionado',
                    r: r),
                SizedBox(height: r.scale(16)),
                _TopChartsRow(r: r, data: _currentDisplayData, dateLabels: _dateLabels),
                SizedBox(height: r.scale(20)),
                _BottomChartsRow(r: r, data: _currentDisplayData, dateLabels: _dateLabels),
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
  final VoidCallback onDateTap;
  final DateTimeRange selectedDateRange;
  final String maqueta;
  final StationAnalyticsData data;
  final List<String> dateLabels;

  const _DashboardHeader({
    required this.r,
    required this.onDateTap,
    required this.selectedDateRange,
    required this.maqueta,
    required this.data,
    required this.dateLabels,
  });

  @override
  Widget build(BuildContext context) {
    final generateReportButton = _GenerateReportButton(
      r: r,
      maqueta: maqueta,
      dateRange: selectedDateRange,
      data: data,
      dateLabels: dateLabels,
    );

    if (r.isSmall) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TitleBlock(r: r),
          SizedBox(height: r.scale(12)),
          Row(
            children: [
              Flexible(child: _DateRangePicker(r: r, onTap: onDateTap, dateRange: selectedDateRange)),
              SizedBox(width: r.scale(10)),
              generateReportButton,
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
            _DateRangePicker(r: r, onTap: onDateTap, dateRange: selectedDateRange),
            SizedBox(width: r.scale(12)),
            generateReportButton,
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
          'Análisis de Planta',
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
  final VoidCallback onTap;
  final DateTimeRange dateRange;

  const _DateRangePicker({required this.r, required this.onTap, required this.dateRange});

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('dd/MM/yyyy');
    final dateString = '${formatter.format(dateRange.start)} - ${formatter.format(dateRange.end)}';

    return GestureDetector(
      onTap: onTap,
      child: Container(
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
              dateString,
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
      ),
    );
  }
}

class _CustomDateRangeDialog extends StatefulWidget {
  final DateTimeRange initialDateRange;
  const _CustomDateRangeDialog({required this.initialDateRange});

  @override
  State<_CustomDateRangeDialog> createState() => _CustomDateRangeDialogState();
}

class _CustomDateRangeDialogState extends State<_CustomDateRangeDialog> {
  late DateTime _startDate;
  late DateTime _endDate;

  @override
  void initState() {
    super.initState();
    _startDate = widget.initialDateRange.start;
    _endDate = widget.initialDateRange.end;
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.blue,
              onPrimary: Colors.white,
              surface: AppColors.card,
              onSurface: AppColors.textPrimary,
            ),
            dialogBackgroundColor: AppColors.bg,
             buttonTheme: const ButtonThemeData(textTheme: ButtonTextTheme.primary),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      setState(() {
        if (isStart) {
          _startDate = pickedDate;
          if (_startDate.isAfter(_endDate)) {
            _endDate = _startDate;
          }
        } else {
          _endDate = pickedDate;
          if (_endDate.isBefore(_startDate)) {
            _startDate = _endDate;
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('dd/MM/yyyy');
    final r = R(MediaQuery.of(context).size.width);

    return Dialog(
      backgroundColor: AppColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Select range', style: TextStyle(fontSize: r.scale(16), fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildDateField('Start Date', formatter.format(_startDate), () => _selectDate(context, true), r)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildDateField('End Date', formatter.format(_endDate), () => _selectDate(context, false), r)),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(DateTimeRange(start: _startDate, end: _endDate));
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.blue, foregroundColor: Colors.white),
                    child: const Text('OK'),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateField(String label, String date, VoidCallback onTap, R r) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: AppColors.textMuted, fontSize: r.scale(11))),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: r.scale(12), vertical: r.scale(10)),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(date, style: TextStyle(color: AppColors.textPrimary, fontSize: r.scale(13))),
                Icon(Icons.calendar_month_outlined, color: AppColors.textMuted, size: r.scale(16)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _GenerateReportButton extends StatelessWidget {
  final R r;
  final String maqueta;
  final DateTimeRange dateRange;
  final StationAnalyticsData data;
  final List<String> dateLabels;

  const _GenerateReportButton({
    required this.r,
    required this.maqueta,
    required this.dateRange,
    required this.data,
    required this.dateLabels,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () {
        showDialog(
          context: context,
          barrierDismissible: true,
          barrierColor: Colors.black.withValues(alpha: 0.7),
          builder: (_) => GenerarReporteDialog(
            maqueta: maqueta,
            dateRange: dateRange,
            data: data,
            dateLabels: dateLabels,
          ),
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
          '%',
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
  final List<String> dateLabels;
  const _TopChartsRow({required this.r, required this.data, required this.dateLabels});

  static List<FlSpot> _spotsFrom(List<double> values) =>
      List.generate(values.length, (i) => FlSpot(i.toDouble(), values[i]));

  @override
  Widget build(BuildContext context) {
    final charts = [
      _BarChartCard(r: r, data: data.produccion, dateLabels: dateLabels),
      _LineChartCard(
        r: r,
        title: 'Tiempo activo (%)',
        color: AppColors.green,
        spots: _spotsFrom(data.tiempoActivo),
        maxY: 100,
        interval: 25,
        dateLabels: dateLabels,
      ),
      _LineChartCard(
        r: r,
        title: 'Fallas por día',
        color: AppColors.red,
        spots: _spotsFrom(data.fallas),
        maxY: 15,
        interval: 5,
        dateLabels: dateLabels,
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
  final List<String> dateLabels;
  const _BarChartCard({required this.r, required this.data, required this.dateLabels});

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
            maxY: data.isEmpty ? 1000 : (data.reduce(max) * 1.2),
            barGroups: List.generate(
              data.length,
              (i) => BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: data[i],
                    color: AppColors.blue,
                    width: barWidth,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                  ),
                ],
              ),
            ),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: data.isEmpty ? 250 : (data.reduce(max) * 1.2) / 4,
              getDrawingHorizontalLine: (_) =>
                  const FlLine(color: Color(0xFF1F2937), strokeWidth: 1),
            ),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: r.scale(38),
                  getTitlesWidget: (v, _) => Text(
                    v.toInt() == 0
                        ? '0'
                        : '${(v / 1000).toStringAsFixed(0)}k',
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
                    if (idx < 0 || idx >= dateLabels.length) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        dateLabels[idx],
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
  final List<String> dateLabels;

  const _LineChartCard({
    required this.r,
    required this.title,
    required this.color,
    required this.spots,
    required this.maxY,
    required this.interval,
    required this.dateLabels,
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
              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
                    if (idx < 0 || idx >= dateLabels.length) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        dateLabels[idx],
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
  final List<String> dateLabels;
  const _BottomChartsRow({required this.r, required this.data, required this.dateLabels});

  @override
  Widget build(BuildContext context) {
    final pie = _PieChartCard(r: r, sections: data.pieData);
    final consumoCard = _LineChartCard(
      r: r,
      title: 'Consumo de energía (kWh)',
      color: AppColors.yellow,
      spots: List.generate(
          data.consumo.length, (i) => FlSpot(i.toDouble(), data.consumo[i])),
      maxY: data.consumo.isEmpty ? 500 : data.consumo.reduce(max) * 1.2,
      interval: data.consumo.isEmpty ? 100 : (data.consumo.reduce(max) * 1.2) / 4,
      dateLabels: dateLabels,
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
    double totalValue = sections.fold(0, (sum, item) => sum + item.value);
    return PieChart(
      PieChartData(
        sections: totalValue == 0
            ? [
                PieChartSectionData(
                  value: 1,
                  color: AppColors.textMuted,
                  title: '',
                  radius: radius,
                )
              ]
            : sections
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
    double totalValue = sections.fold(0, (sum, item) => sum + item.value);
    if (totalValue == 0) return const Center(child: Text('No hay datos de fallas', style: TextStyle(color: AppColors.textMuted)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: sections
          .map((s) => Padding(
                padding: EdgeInsets.only(bottom: r.scale(12)),
                child: _LegendItem(section: s, total: totalValue, r: r),
              ))
          .toList(),
    );
  }

  Widget _buildLegendRow() {
     double totalValue = sections.fold(0, (sum, item) => sum + item.value);
    if (totalValue == 0) return const Center(child: Text('No hay datos de fallas', style: TextStyle(color: AppColors.textMuted)));

    return Wrap(
      spacing: r.scale(12),
      runSpacing: r.scale(8),
      children: sections.map((s) => _LegendItem(section: s, total: totalValue, r: r)).toList(),
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
  final double total;
  final R r;
  const _LegendItem({required this.section, required this.total, required this.r});

  @override
  Widget build(BuildContext context) {
    final percentage = (section.value / total) * 100;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: r.scale(11),
          height: r.scale(11),
          decoration: BoxDecoration(color: section.color, shape: BoxShape.circle),
        ),
        SizedBox(width: r.scale(6)),
        Text(
          section.label,
          style: TextStyle(color: AppColors.textPrimary, fontSize: r.scale(12)),
        ),
        SizedBox(width: r.scale(8)),
        Text(
          '${percentage.toStringAsFixed(1)}%',
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