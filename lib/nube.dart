import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

// ─── Colores y Estilos ────────────────────────────────────────────────────────
const Color kBg = Color(0xFF0A192F);
const Color kPanel = Color(0xFF172A46);
const Color kAccent = Color(0xFF64FFDA);
const Color kGreen = Color(0xFF10B981);
const Color kRed = Color(0xFFF43F5E);
const Color kBorder = Color(0xFF233554);
const Color kText = Color(0xFFD3E0F2);
const Color kMuted = Color(0xFF8892B0);

// ─── Pantalla Principal ─────────────────────────────────────────────────────
class NubeScreen extends StatelessWidget {
  const NubeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Dashboard de Producción en la Nube', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: kText)),
            const SizedBox(height: 8),
            const Text('Datos en tiempo real de todas las maquetas', style: TextStyle(fontSize: 16, color: kMuted)),
            const SizedBox(height: 24),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('maquetas').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: kAccent));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No hay datos de maquetas disponibles.', style: TextStyle(color: kMuted)));
                }

                final maquetas = snapshot.data!.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
                return Column(
                  children: [
                    _buildKPIGrid(maquetas),
                    const SizedBox(height: 24),
                    _buildCharts(maquetas),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKPIGrid(List<Map<String, dynamic>> maquetas) {
    final totalPiezas = maquetas.fold<int>(0, (sum, item) => sum + (item['piezasProcesadas'] ?? 0) as int);
    final totalEmergencias = maquetas.fold<int>(0, (sum, item) => sum + (item['parosEmergencia'] ?? 0) as int);
    final totalResets = maquetas.fold<int>(0, (sum, item) => sum + (item['resetsSistema'] ?? 0) as int);

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      children: [
        _kpiCard('Piezas Totales', totalPiezas.toString(), Icons.precision_manufacturing, kGreen),
        _kpiCard('Paros de Emergencia', totalEmergencias.toString(), Icons.error_outline, kRed),
        _kpiCard('Resets del Sistema', totalResets.toString(), Icons.replay, kAccent),
      ],
    );
  }

  Widget _kpiCard(String title, String value, IconData icon, Color color) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: kPanel,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: kBorder),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 40, color: color),
        const SizedBox(height: 12),
        Text(value, style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text(title, style: const TextStyle(fontSize: 14, color: kMuted), textAlign: TextAlign.center),
      ],
    ),
  );

  Widget _buildCharts(List<Map<String, dynamic>> maquetas) {
    return Column(
      children: [
        _chartContainer(
          title: 'Producción por Maqueta',
          child: BarChart(_buildBarChartData(maquetas)),
        ),
        const SizedBox(height: 24),
        _chartContainer(
          title: 'Distribución de Eventos de Alerta',
          child: PieChart(_buildPieChartData(maquetas)),
        ),
      ],
    );
  }

  Widget _chartContainer({required String title, required Widget child}) => Container(
    height: 350,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: kPanel, borderRadius: BorderRadius.circular(12), border: Border.all(color: kBorder)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kText)),
        const SizedBox(height: 24),
        Expanded(child: child),
      ],
    ),
  );

  BarChartData _buildBarChartData(List<Map<String, dynamic>> maquetas) {
    return BarChartData(
      alignment: BarChartAlignment.spaceAround,
      barTouchData: BarTouchData(enabled: false),
      titlesData: FlTitlesData(
        show: true,
        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (value, meta) => SideTitleWidget(axisSide: meta.axisSide, child: Text(maquetas[value.toInt()]['id'], style: const TextStyle(color: kMuted, fontSize: 10))))),
        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40, getTitlesWidget: (value, meta) => Text(value.toInt().toString(), style: const TextStyle(color: kMuted, fontSize: 10)))),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      gridData: FlGridData(show: true, getDrawingHorizontalLine: (value) => const FlLine(color: kBorder, strokeWidth: 0.5)),
      borderData: FlBorderData(show: false),
      barGroups: maquetas.asMap().entries.map((entry) {
        final index = entry.key;
        final maqueta = entry.value;
        return BarChartGroupData(
          x: index,
          barRods: [BarChartRodData(toY: (maqueta['piezasProcesadas'] ?? 0).toDouble(), color: kGreen, width: 20)],
        );
      }).toList(),
    );
  }

  PieChartData _buildPieChartData(List<Map<String, dynamic>> maquetas) {
    final emergencias = maquetas.fold<int>(0, (sum, item) => sum + (item['parosEmergencia'] ?? 0) as int);
    final resets = maquetas.fold<int>(0, (sum, item) => sum + (item['resetsSistema'] ?? 0) as int);
    final total = emergencias + resets;

    if (total == 0) {
      return PieChartData(sections: [PieChartSectionData(value: 1, title: 'Sin Datos', color: kMuted, radius: 80)]);
    }

    return PieChartData(
      sectionsSpace: 4,
      centerSpaceRadius: 50,
      sections: [
        PieChartSectionData(value: emergencias.toDouble(), title: '${(emergencias / total * 100).toStringAsFixed(0)}%', color: kRed, radius: 80, titleStyle: const TextStyle(fontWeight: FontWeight.bold)),
        PieChartSectionData(value: resets.toDouble(), title: '${(resets / total * 100).toStringAsFixed(0)}%', color: kAccent, radius: 80, titleStyle: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}
