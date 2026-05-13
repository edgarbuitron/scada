//import 'dart:math';
import 'package:flutter/material.dart';

void main() => runApp(const DiagnosticoApp());

const kBg = Color(0xFF0D1321);
const kCard = Color(0xFF131D2E);
const kBorder = Color(0xFF1E2D45);
const kBlue = Color(0xFF3B82F6);
const kGreen = Color(0xFF22C55E);
const kRed = Color(0xFFEF4444);
const kText = Color(0xFFE2E8F0);
const kMuted = Color(0xFF64748B);
const kMuted2 = Color(0xFF8B9CBD);

// ─── Datos de la tabla ────────────────────────────────────────────────────────
const _rendimiento = [
  {
    'nombre': 'Neumática',
    'env': 2540,
    'rec': 2480,
    'per': 60,
    'pct': '2.36%',
    'lat': '12 ms'
  },
  {
    'nombre': 'Banda Transportadora',
    'env': 2320,
    'rec': 2270,
    'per': 50,
    'pct': '2.16%',
    'lat': '18 ms'
  },
  {
    'nombre': 'Robot Cartesiano',
    'env': 2120,
    'rec': 1980,
    'per': 140,
    'pct': '6.60%',
    'lat': '--'
  },
  {
    'nombre': 'Prensa Hidráulica',
    'env': 1980,
    'rec': 1890,
    'per': 90,
    'pct': '4.55%',
    'lat': '--'
  },
  {
    'nombre': 'Horno Industrial',
    'env': 1580,
    'rec': 1528,
    'per': 52,
    'pct': '3.29%',
    'lat': '--'
  },
];

// ─── Series del gráfico (simuladas similares a la imagen) ─────────────────────
// Eje X: 09:55 … 10:30 (8 puntos)
const _xLabels = [
  '09:55',
  '10:00',
  '10:05',
  '10:10',
  '10:15',
  '10:20',
  '10:25',
  '10:30'
];

final _series = <String, List<double>>{
  'Neumática': [72, 78, 68, 75, 80, 70, 75, 82],
  'Banda': [45, 50, 48, 52, 55, 47, 50, 53],
  'Robot': [30, 35, 38, 32, 28, 34, 36, 30],
  'Prensa': [20, 22, 25, 18, 24, 20, 22, 24],
  'Horno': [55, 60, 58, 62, 65, 58, 60, 63],
};

const _seriesColors = [
  kBlue,
  kGreen,
  Color(0xFFF59E0B),
  kRed,
  Color(0xFFA855F7)
];

// ═════════════════════════════════════════════════════════════════════════════
class DiagnosticoApp extends StatelessWidget {
  const DiagnosticoApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Diagnóstico de Conexiones',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: kBg,
            fontFamily: 'Roboto'),
        home: const DiagnosticoScreen(),
      );
}

class DiagnosticoScreen extends StatelessWidget {
  const DiagnosticoScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: kBg,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _buildHeader(),
              const SizedBox(height: 22),
              _buildKpis(),
              const SizedBox(height: 24),
              _buildRendimiento(),
              const SizedBox(height: 24),
              _buildChart(),
            ]),
          ),
        ),
      );

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _buildHeader() => Row(children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
          Text('Diagnóstico de conexiones',
              style: TextStyle(
                  fontSize: 24, fontWeight: FontWeight.bold, color: kText)),
          SizedBox(height: 3),
          Text('Monitorea el estado y rendimiento de todas las conexiones',
              style: TextStyle(fontSize: 13, color: kMuted2)),
        ]),
        const Spacer(),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
              backgroundColor: kBlue,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8))),
          icon: const Icon(Icons.file_download_outlined, size: 16),
          label: const Text('Exportar reporte',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          onPressed: () {},
        ),
      ]);

  // ── KPI cards ──────────────────────────────────────────────────────────────
  Widget _buildKpis() => Row(children: [
        Expanded(
            child: _KpiCard(
                label: 'Paquetes enviados',
                value: '12,540',
                sub: 'total',
                valueColor: kText)),
        const SizedBox(width: 12),
        Expanded(
            child: _KpiCard(
                label: 'Paquetes recibidos',
                value: '12,148',
                sub: 'total',
                valueColor: kText)),
        const SizedBox(width: 12),
        Expanded(
            child: _KpiCard(
                label: 'Paquetes perdidos',
                value: '392',
                sub: '(3.12%)',
                valueColor: kRed)),
        const SizedBox(width: 12),
        Expanded(
            child: _KpiCard(
                label: 'Reconexiones',
                value: '8',
                sub: 'hoy',
                valueColor: kGreen)),
      ]);

  // ── Tabla rendimiento ──────────────────────────────────────────────────────
  Widget _buildRendimiento() => Container(
        decoration: BoxDecoration(
            color: kCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kBorder)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(18, 18, 18, 12),
            child: Text('Rendimiento de conexiones',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold, color: kText)),
          ),
          const Divider(height: 1, color: kBorder),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
            child: Row(children: const [
              Expanded(flex: 4, child: _TH('Maqueta')),
              Expanded(flex: 2, child: _TH('Enviados', right: true)),
              Expanded(flex: 2, child: _TH('Recibidos', right: true)),
              Expanded(flex: 2, child: _TH('Pérdidos', right: true)),
              Expanded(flex: 2, child: _TH('Pérdida %', right: true)),
              Expanded(flex: 2, child: _TH('Latencia prom.', right: true)),
            ]),
          ),
          const Divider(height: 1, color: kBorder),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _rendimiento.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, color: kBorder),
            itemBuilder: (_, i) {
              final r = _rendimiento[i];
              final latColor = r['lat'] == '--' ? kMuted2 : kGreen;
              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                child: Row(children: [
                  Expanded(
                      flex: 4,
                      child: Text(r['nombre'] as String,
                          style: const TextStyle(fontSize: 13, color: kText))),
                  Expanded(
                      flex: 2,
                      child: Text('${r['env']}',
                          textAlign: TextAlign.right,
                          style:
                              const TextStyle(fontSize: 13, color: kMuted2))),
                  Expanded(
                      flex: 2,
                      child: Text('${r['rec']}',
                          textAlign: TextAlign.right,
                          style:
                              const TextStyle(fontSize: 13, color: kMuted2))),
                  Expanded(
                      flex: 2,
                      child: Text('${r['per']}',
                          textAlign: TextAlign.right,
                          style:
                              const TextStyle(fontSize: 13, color: kMuted2))),
                  Expanded(
                      flex: 2,
                      child: Text(r['pct'] as String,
                          textAlign: TextAlign.right,
                          style:
                              const TextStyle(fontSize: 13, color: kMuted2))),
                  Expanded(
                      flex: 2,
                      child: Text(r['lat'] as String,
                          textAlign: TextAlign.right,
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: latColor))),
                ]),
              );
            },
          ),
          const SizedBox(height: 6),
        ]),
      );

  // ── Gráfico de latencia ────────────────────────────────────────────────────
  Widget _buildChart() => Container(
        decoration: BoxDecoration(
            color: kCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kBorder)),
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Gráfico de latencia (ms)',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold, color: kText)),
          const SizedBox(height: 18),
          SizedBox(height: 220, child: _LatencyChart()),
          const SizedBox(height: 14),
          // Leyenda
          Wrap(
            spacing: 20,
            runSpacing: 8,
            children: _series.keys
                .toList()
                .asMap()
                .entries
                .map((e) => Row(mainAxisSize: MainAxisSize.min, children: [
                      Container(
                          width: 24, height: 3, color: _seriesColors[e.key]),
                      const SizedBox(width: 6),
                      Text(e.value,
                          style: const TextStyle(fontSize: 12, color: kMuted2)),
                    ]))
                .toList(),
          ),
        ]),
      );
}

// ─── Gráfico de líneas ────────────────────────────────────────────────────────
class _LatencyChart extends StatelessWidget {
  const _LatencyChart();
  @override
  Widget build(BuildContext context) => CustomPaint(
        painter: _ChartPainter(),
        size: Size.infinite,
      );
}

class _ChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const maxY = 100.0;
    const minY = 0.0;
    final range = maxY - minY;
    final cols = _xLabels.length;
    final gridLinesY = [0, 25, 50, 75, 100];

    // ── Grid ──
    final gridPaint = Paint()
      ..color = kBorder
      ..strokeWidth = .8;
    final textStyle = const TextStyle(fontSize: 9, color: kMuted2);

    for (final y in gridLinesY) {
      final dy = size.height * (1 - (y - minY) / range);
      canvas.drawLine(Offset(36, dy), Offset(size.width, dy), gridPaint);
      // Etiqueta Y
      _drawText(canvas, '$y', Offset(0, dy - 6), textStyle, 34);
    }

    // Etiquetas X
    for (int i = 0; i < cols; i++) {
      final dx = 36 + (size.width - 36) * i / (cols - 1);
      _drawText(canvas, _xLabels[i], Offset(dx - 16, size.height - 12),
          textStyle, 40);
    }

    // ── Líneas de series ──
    final seriesList = _series.entries.toList();
    for (int si = 0; si < seriesList.length; si++) {
      final values = seriesList[si].value;
      final paint = Paint()
        ..color = _seriesColors[si]
        ..strokeWidth = 2.2
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round;

      final path = Path();
      for (int i = 0; i < values.length; i++) {
        final dx = 36 + (size.width - 36) * i / (values.length - 1);
        final dy = (size.height - 20) * (1 - (values[i] - minY) / range);
        if (i == 0)
          path.moveTo(dx, dy);
        else
          path.lineTo(dx, dy);
      }
      canvas.drawPath(path, paint);

      // Punto final
      final lastDx = size.width;
      final lastDy = (size.height - 20) * (1 - (values.last - minY) / range);
      canvas.drawCircle(
          Offset(lastDx, lastDy), 4, Paint()..color = _seriesColors[si]);
    }
  }

  void _drawText(Canvas canvas, String text, Offset offset, TextStyle style,
      double maxWidth) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: maxWidth);
    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(_ChartPainter _) => false;
}

// ─── Helpers ─────────────────────────────────────────────────────────────────
class _KpiCard extends StatelessWidget {
  final String label, value, sub;
  final Color valueColor;
  const _KpiCard(
      {required this.label,
      required this.value,
      required this.sub,
      required this.valueColor});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
            color: kCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kBorder)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 12, color: kMuted2)),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: valueColor)),
          const SizedBox(height: 3),
          Text(sub, style: const TextStyle(fontSize: 12, color: kMuted)),
        ]),
      );
}

class _TH extends StatelessWidget {
  final String text;
  final bool right;
  const _TH(this.text, {this.right = false});
  @override
  Widget build(BuildContext context) => Text(text,
      textAlign: right ? TextAlign.right : TextAlign.left,
      style: const TextStyle(
          fontSize: 12, fontWeight: FontWeight.w600, color: kMuted2));
}
