import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'analitycs.dart';

const kBg = Color(0xFF0F172A);
const kCard = Color(0xFF1E293B);
const kCardDark = Color(0xFF111827);
const kBorder = Color(0xFF334155);
const kBlue = Color(0xFF3B82F6);
const kGreen = Color(0xFF22C55E);
const kOrange = Color(0xFFF97316);
const kYellow = Color(0xFFEAB308);
const kText = Color(0xFFF8FAFC);
const kMuted = Color(0xFF94A3B8);

class ReporteItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  bool selected;

  ReporteItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.selected = false,
  });
}

class GenerarReporteDialog extends StatefulWidget {
  final String maqueta;
  final DateTimeRange dateRange;
  final StationAnalyticsData data;
  final List<String> dateLabels;

  const GenerarReporteDialog({
    super.key,
    required this.maqueta,
    required this.dateRange,
    required this.data,
    required this.dateLabels,
  });

  @override
  State<GenerarReporteDialog> createState() => _GenerarReporteDialogState();
}

class _GenerarReporteDialogState extends State<GenerarReporteDialog> {
  final List<ReporteItem> reportes = [
    ReporteItem(
      title: "Producción",
      subtitle: "Unidades producidas y eficiencia",
      icon: Icons.bar_chart,
      color: kBlue,
      selected: true,
    ),
    ReporteItem(
      title: "Tiempo Activo",
      subtitle: "Disponibilidad y OEE de la máquina",
      icon: Icons.timer,
      color: kGreen,
      selected: true,
    ),
    ReporteItem(
      title: "Fallas",
      subtitle: "Registro y tipos de fallos",
      icon: Icons.warning_amber,
      color: kOrange,
    ),
    ReporteItem(
      title: "Consumo Energético",
      subtitle: "Reporte de consumo en kWh",
      icon: Icons.bolt,
      color: kYellow,
    ),
  ];

  void _openPreview(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: kBg.withValues(alpha: 0.7),
        pageBuilder: (context, _, __) => PreviewScreen(
          maqueta: widget.maqueta,
          dateRange: widget.dateRange,
          reportes: reportes.where((r) => r.selected).toList(),
          data: widget.data,
          dateLabels: widget.dateLabels,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Dialog(
      backgroundColor: kCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 650,
          maxHeight: size.height * 0.9,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      "Generar Reporte",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: kText,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  )
                ],
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: kCardDark,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: kBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(color: kMuted, fontSize: 13),
                        children: [
                          const TextSpan(text: "Reporte para: "),
                          TextSpan(
                            text: widget.maqueta,
                            style: const TextStyle(color: kText, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(color: kMuted, fontSize: 13),
                        children: [
                          const TextSpan(text: "Período: "),
                          TextSpan(
                            text: "${DateFormat('dd/MM/yy').format(widget.dateRange.start)} - ${DateFormat('dd/MM/yy').format(widget.dateRange.end)}",
                            style: const TextStyle(color: kText, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Tipos de reporte a incluir",
                style: TextStyle(
                  color: kText,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 14),
              ...reportes.map((item) => buildReporteCard(item)),
              const SizedBox(height: 26),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kBlue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () => _openPreview(context),
                  icon: const Icon(Icons.preview_outlined),
                  label: const Text("Previsualizar PDF"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildReporteCard(ReporteItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
      decoration: BoxDecoration(
        color: kCardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: item.selected ? kBlue : kBorder,
          width: item.selected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            item.selected = !item.selected;
          });
        },
        child: Row(
          children: [
            Icon(item.icon, color: item.color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      color: kText,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    item.subtitle,
                    style: const TextStyle(
                      color: kMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Checkbox(
              value: item.selected,
              activeColor: kBlue,
              onChanged: (value) {
                setState(() {
                  item.selected = value!;
                });
              },
            )
          ],
        ),
      ),
    );
  }
}


class PreviewScreen extends StatelessWidget {
  final String maqueta;
  final List<ReporteItem> reportes;
  final DateTimeRange dateRange;
  final StationAnalyticsData data;
  final List<String> dateLabels;

  const PreviewScreen({
    super.key,
    required this.maqueta,
    required this.reportes,
    required this.dateRange,
    required this.data,
    required this.dateLabels,
  });

  Future<Uint8List> _generatePdf(PdfPageFormat format) async {
    final pdf = pw.Document(version: PdfVersion.pdf_1_5, compress: true);
    final font = await PdfGoogleFonts.robotoRegular();
    final boldFont = await PdfGoogleFonts.robotoBold();
    final italicFont = await PdfGoogleFonts.robotoItalic();

    final theme = pw.ThemeData.withFont(
      base: font,
      bold: boldFont,
      italic: italicFont,
    );

    final formattedDateRange =
        "${DateFormat('dd/MM/yyyy').format(dateRange.start)} - ${DateFormat('dd/MM/yyyy').format(dateRange.end)}";

    pdf.addPage(
      pw.MultiPage(
        theme: theme,
        pageFormat: format,
        build: (context) {
          return [
            pw.Header(
                level: 0,
                child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'Reporte de Análisis SCADA',
                              style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold, fontSize: 22, color: PdfColors.blue900),
                            ),
                            pw.SizedBox(height: 2),
                            pw.Text(
                              'Maqueta: $maqueta',
                              style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold, fontSize: 16),
                            ),
                            pw.SizedBox(height: 4),
                            pw.Text(
                              'Período: $formattedDateRange',
                              style: const pw.TextStyle(
                                  color: PdfColors.grey700, fontSize: 12),
                            ),
                          ]),
                      pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.end,
                          children: [
                            pw.Text('Planta Industrial 4.0',
                                style: pw.TextStyle(
                                    fontSize: 10, color: PdfColors.grey)),
                            pw.Text('Generado el: ${DateFormat('dd/MM/yyyy').format(DateTime.now())}',
                                style: pw.TextStyle(
                                    fontSize: 10, color: PdfColors.grey)),
                          ])
                    ])),
            pw.SizedBox(height: 20),
            
            // KPI Summary Row
            pw.Row(
              children: [
                _buildKpiBox('Producción', data.produccionTotal, 'unidades', PdfColors.blue),
                pw.SizedBox(width: 10),
                _buildKpiBox('Tiempo Activo', data.tiempoActivoPorcentaje, '', PdfColors.green),
                pw.SizedBox(width: 10),
                _buildKpiBox('Fallas', data.fallasTotales, 'eventos', PdfColors.red),
                pw.SizedBox(width: 10),
                _buildKpiBox('Consumo', data.consumoTotal, 'kWh', PdfColors.orange),
              ]
            ),
            pw.SizedBox(height: 25),

            // DYNAMIC SECTIONS
            ...reportes.expand((reporte) {
              if (reporte.title == "Producción") {
                return [_buildProductionSection(theme)];
              } else if (reporte.title == "Tiempo Activo") {
                return [_buildUptimeSection(theme)];
              } else if (reporte.title == "Fallas") {
                return [_buildFailsSection(theme)];
              } else if (reporte.title == "Consumo Energético") {
                return [_buildConsumptionSection(theme)];
              }
              return [];
            }),
            
            pw.SizedBox(height: 20),
            pw.Divider(color: PdfColors.grey300),
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 10),
              child: pw.Center(
                child: pw.Text(
                  'Fin del reporte - Información confidencial para uso interno.',
                  style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600, fontStyle: pw.FontStyle.italic),
                ),
              ),
            )
          ];
        },
        footer: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(top: 1.0 * PdfPageFormat.cm),
          child: pw.Text(
            'Página ${context.pageNumber} de ${context.pagesCount}',
            style: const pw.TextStyle(color: PdfColors.grey, fontSize: 9),
          ),
        ),
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildKpiBox(String label, String value, String unit, PdfColor color) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey300),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
          color: PdfColors.grey50,
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(label, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
            pw.SizedBox(height: 5),
            pw.Text(value, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: color)),
            if (unit.isNotEmpty) pw.Text(unit, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
          ],
        ),
      ),
    );
  }

  pw.Widget _buildProductionSection(pw.ThemeData theme) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionTitle('Análisis de Producción'),
        pw.SizedBox(height: 10),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              flex: 2,
              child: pw.Container(
                height: 180,
                child: pw.Chart(
                  grid: pw.CartesianGrid(
                    xAxis: pw.FixedAxis.fromStrings(dateLabels, textStyle: const pw.TextStyle(fontSize: 7)),
                    yAxis: pw.LinearAxis(
                      textStyle: const pw.TextStyle(fontSize: 7),
                    ),
                  ),
                  datasets: [
                    pw.BarDataSet(
                      color: PdfColors.blue,
                      data: List.generate(data.produccion.length, (i) => pw.PointChartValue(i.toDouble(), data.produccion[i])),
                      width: 10,
                    ),
                  ],
                ),
              ),
            ),
            pw.SizedBox(width: 20),
            pw.Expanded(
              flex: 1,
              child: _buildDataTable('Día', 'Unds', dateLabels, data.produccion),
            ),
          ],
        ),
        pw.SizedBox(height: 25),
      ],
    );
  }

  pw.Widget _buildUptimeSection(pw.ThemeData theme) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionTitle('Tiempo de Actividad y OEE'),
        pw.SizedBox(height: 10),
        pw.Container(
          height: 150,
          child: pw.Chart(
            grid: pw.CartesianGrid(
              xAxis: pw.FixedAxis.fromStrings(dateLabels, textStyle: const pw.TextStyle(fontSize: 7)),
              yAxis: pw.LinearAxis(
                textStyle: const pw.TextStyle(fontSize: 7),
                maximum: 100,
              ),
            ),
            datasets: [
              pw.LineDataSet(
                color: PdfColors.green,
                data: List.generate(data.tiempoActivo.length, (i) => pw.PointChartValue(i.toDouble(), data.tiempoActivo[i])),
                isCurved: true,
                drawPoints: true,
                pointSize: 3,
                drawSurface: true,
                surfaceColor: PdfColors.green100,
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Text('El gráfico anterior muestra el porcentaje de disponibilidad de la máquina por día. El promedio alcanzado fue de ${data.tiempoActivoPorcentaje}.',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey800)),
        pw.SizedBox(height: 25),
      ],
    );
  }

  pw.Widget _buildFailsSection(pw.ThemeData theme) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionTitle('Registro de Fallas y Alarmas'),
        pw.SizedBox(height: 10),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
             pw.Expanded(
               child: pw.Column(children: [
                  pw.Text('Fallas Diarias', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                  pw.SizedBox(height: 5),
                  pw.Container(
                    height: 120,
                    child: pw.Chart(
                      grid: pw.CartesianGrid(
                        xAxis: pw.FixedAxis.fromStrings(dateLabels, textStyle: const pw.TextStyle(fontSize: 7)),
                        yAxis: pw.LinearAxis(
                          textStyle: const pw.TextStyle(fontSize: 7),
                        ),
                      ),
                      datasets: [
                        pw.LineDataSet(
                          color: PdfColors.red,
                          data: List.generate(data.fallas.length, (i) => pw.PointChartValue(i.toDouble(), data.fallas[i])),
                          drawPoints: true,
                          pointSize: 2,
                        ),
                      ],
                    ),
                  ),
               ])
             ),
             pw.SizedBox(width: 20),
             pw.Expanded(
               child: pw.Column(children: [
                  pw.Text('Distribución de Tipos', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                  pw.SizedBox(height: 5),
                  pw.Table(
                    border: pw.TableBorder.all(color: PdfColors.grey200, width: 0.5),
                    children: [
                      pw.TableRow(
                        decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                        children: [
                           pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Categoría', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))),
                           pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Valor', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))),
                        ]
                      ),
                      ...data.pieData.map((p) => pw.TableRow(
                        children: [
                           pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(p.label, style: const pw.TextStyle(fontSize: 9))),
                           pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('${p.value.toStringAsFixed(1)}%', style: const pw.TextStyle(fontSize: 9))),
                        ]
                      ))
                    ]
                  )
               ])
             )
          ]
        ),
        pw.SizedBox(height: 25),
      ],
    );
  }

  pw.Widget _buildConsumptionSection(pw.ThemeData theme) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionTitle('Eficiencia Energética'),
        pw.SizedBox(height: 10),
        pw.Row(
           children: [
             pw.Expanded(
               flex: 2,
               child: pw.Container(
                  height: 140,
                  child: pw.Chart(
                    grid: pw.CartesianGrid(
                      xAxis: pw.FixedAxis.fromStrings(dateLabels, textStyle: const pw.TextStyle(fontSize: 7)),
                      yAxis: pw.LinearAxis(
                        textStyle: const pw.TextStyle(fontSize: 7),
                      ),
                    ),
                    datasets: [
                      pw.LineDataSet(
                        color: PdfColors.orange,
                        data: List.generate(data.consumo.length, (i) => pw.PointChartValue(i.toDouble(), data.consumo[i])),
                        drawPoints: true,
                        drawSurface: true,
                        surfaceColor: PdfColors.orange100,
                      ),
                    ],
                  ),
                ),
             ),
             pw.SizedBox(width: 15),
             pw.Expanded(
               flex: 1,
               child: _buildDataTable('Día', 'kWh', dateLabels, data.consumo),
             )
           ]
        ),
        pw.SizedBox(height: 25),
      ],
    );
  }

  pw.Widget _sectionTitle(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 4, left: 2),
      decoration: const pw.BoxDecoration(border: Border(bottom: BorderSide(color: PdfColors.grey300, width: 1.5))),
      child: pw.Text(text, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
    );
  }

  pw.Widget _buildDataTable(String h1, String h2, List<String> labels, List<double> values) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text(h1, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold))),
            pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text(h2, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold))),
          ]
        ),
        ...List.generate(labels.length, (i) => pw.TableRow(
          children: [
            pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text(labels[i], style: const pw.TextStyle(fontSize: 8))),
            pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text(values[i].toStringAsFixed(0), style: const pw.TextStyle(fontSize: 8))),
          ]
        ))
      ]
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 650,
          maxHeight: size.height * 0.85,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Scaffold(
            backgroundColor: kCardDark,
            body: PdfPreview(
              maxPageWidth: 500,
              pageFormats: const {'A4': PdfPageFormat.a4},
              canChangeOrientation: false,
              canChangePageFormat: false,
              pdfPreviewPageDecoration: const BoxDecoration(
                color: Colors.white,
              ),
              build: (format) => _generatePdf(format),
              canDebug: false,
              allowPrinting: true,
              allowSharing: true,
              actions: [
                const Spacer(),
                PdfPreviewAction(
                  icon: const Tooltip(
                    message: 'Volver y Editar',
                    child: Icon(Icons.edit_outlined),
                  ),
                  onPressed: (context, _, __) {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void showConfirmModal(BuildContext context) {
    // This is optional now as PdfPreview has its own flow
  }
}
