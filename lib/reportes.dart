import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

void main() {
  runApp(const AnalyticsApp());
}

class C {
  static const bg = Color(0xFF0D1117);
  static const card = Color(0xFF161B27);
  static const border = Color(0xFF1F2937);
  static const white = Colors.white;
  static const muted = Color(0xFF6B7280);

  static const blue = Color(0xFF3B82F6);
  static const green = Color(0xFF10B981);
  static const red = Color(0xFFEF4444);
  static const yellow = Color(0xFFF59E0B);

  static Color blueA(double a) => blue.withValues(alpha: a);
  static Color greenA(double a) => green.withValues(alpha: a);
  static Color redA(double a) => red.withValues(alpha: a);
  static Color yellowA(double a) => yellow.withValues(alpha: a);

  static Color gridLine() => const Color(0xFF1F2937);
}

class Data {
  static const List<double> produccion = [
    1000.0,
    1200.0,
    1800.0,
    2200.0,
    2500.0,
    2300.0,
    3000.0,
  ];

  static const List<double> tiempoActivo = [
    65.0,
    55.0,
    75.0,
    50.0,
    70.0,
    65.0,
    70.0,
  ];

  static const List<double> fallas = [
    5.0,
    8.0,
    4.0,
    10.0,
    6.0,
    5.0,
    7.0,
  ];

  static const List<double> consumo = [
    500.0,
    480.0,
    550.0,
    520.0,
    540.0,
    460.0,
    580.0,
  ];

  static const List<String> fechas = [
    '14/05',
    '15/05',
    '16/05',
    '17/05',
    '18/05',
    '19/05',
    '20/05',
  ];
}

class AnalyticsApp extends StatelessWidget {
  const AnalyticsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Analytics Dashboard',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: C.bg,
        colorScheme: const ColorScheme.dark(),
      ),
      home: const DashboardPage(),
    );
  }
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            HeaderWidget(),
            SizedBox(height: 24),
            KpiRow(),
            SizedBox(height: 24),
            TopChartsRow(),
            SizedBox(height: 24),
            BottomChartsRow(),
          ],
        ),
      ),
    );
  }
}

class HeaderWidget extends StatelessWidget {
  const HeaderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Analytics / Reportes',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: C.white,
            ),
          ),
        ),
        const _DateBox(),
        const SizedBox(width: 12),
        //const GenerarReporteBtn(),
      ],
    );
  }
}

class _DateBox extends StatelessWidget {
  const _DateBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: C.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: C.border),
      ),
      child: const Text(
        '01/05/2025 - 20/05/2025',
        style: TextStyle(color: C.white),
      ),
    );
  }
}

/* class GenerarReporteBtn extends StatelessWidget {
  const GenerarReporteBtn({super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: C.card,
            title: const Text(
              'Reporte generado',
              style: TextStyle(color: C.white),
            ),
            content: const Text(
              'El reporte se generó correctamente.',
              style: TextStyle(color: C.white),
            ),
          ),
        );
      },
      icon: const Icon(Icons.download),
      label: const Text('Generar'),
    );
  }
}

 */





class KpiRow extends StatelessWidget {
  const KpiRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: const [
        SizedBox(width: 250, child: KpiCard('Producción', '12,540')),
        SizedBox(width: 250, child: KpiCard('Tiempo Activo', '87.6%')),
        SizedBox(width: 250, child: KpiCard('Fallas', '24')),
        SizedBox(width: 250, child: KpiCard('Consumo', '1,245')),
      ],
    );
  }
}

class KpiCard extends StatelessWidget {
  final String title;
  final String value;

  const KpiCard(this.title, this.value, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: C.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: C.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: C.muted)),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: C.white,
            ),
          ),
        ],
      ),
    );
  }
}

class TopChartsRow extends StatelessWidget {
  const TopChartsRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: const [
        SizedBox(width: 450, child: BarChartCard()),
        SizedBox(width: 450, child: PieChartCard()),
      ],
    );
  }
}

class BottomChartsRow extends StatelessWidget {
  const BottomChartsRow({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox();
  }
}

class BarChartCard extends StatelessWidget {
  const BarChartCard({super.key});

  @override
  Widget build(BuildContext context) {
    return ChartCard(
      title: 'Producción por día',
      child: SizedBox(
        height: 250,
        child: BarChart(
          BarChartData(
            borderData: FlBorderData(show: false),
            barGroups: List.generate(
              Data.produccion.length,
              (i) => BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: Data.produccion[i],
                    color: C.blue,
                    width: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PieChartCard extends StatelessWidget {
  const PieChartCard({super.key});

  @override
  Widget build(BuildContext context) {
    return ChartCard(
      title: 'Distribución de fallas',
      child: SizedBox(
        height: 250,
        child: PieChart(
          PieChartData(
            sections: [
              PieChartSectionData(value: 40.0, color: C.blue),
              PieChartSectionData(value: 30.0, color: C.green),
              PieChartSectionData(value: 20.0, color: C.red),
              PieChartSectionData(value: 10.0, color: C.yellow),
            ],
          ),
        ),
      ),
    );
  }
}

class ChartCard extends StatelessWidget {
  final String title;
  final Widget child;

  const ChartCard({
    super.key,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: C.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: C.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(color: C.white),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}