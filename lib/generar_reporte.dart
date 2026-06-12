import 'package:flutter/material.dart' as material;
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'analytics.dart';

const material.Color kBg = material.Color(0xFF0F172A);
const material.Color kCard = material.Color(0xFF1E293B);
const material.Color kCardDark = material.Color(0xFF111827);
const material.Color kBorder = material.Color(0xFF334155);
const material.Color kBlue = material.Color(0xFF3B82F6);
const material.Color kGreen = material.Color(0xFF22C55E);
const material.Color kOrange = material.Color(0xFFF97316);
const material.Color kYellow = material.Color(0xFFEAB308);
const material.Color kText = material.Color(0xFFF8FAFC);
const material.Color kMuted = material.Color(0xFF94A3B8);

class ReporteItem {
  final String title;
  final String subtitle;
  final material.IconData icon;
  final material.Color color;
  bool selected;

  ReporteItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.selected = false,
  });
}

class GenerarReporteDialog extends material.StatefulWidget {
  final String maqueta;
  final material.DateTimeRange dateRange;
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
  material.State<GenerarReporteDialog> createState() => _GenerarReporteDialogState();
}

class _GenerarReporteDialogState extends material.State<GenerarReporteDialog> {
  final List<ReporteItem> reportes = [
    ReporteItem(
      title: "Producción",
      subtitle: "Unidades producidas y eficiencia",
      icon: material.Icons.bar_chart,
      color: kBlue,
      selected: true,
    ),
    ReporteItem(
      title: "Tiempo Activo",
      subtitle: "Disponibilidad y OEE de la máquina",
      icon: material.Icons.timer,
      color: kGreen,
      selected: true,
    ),
    ReporteItem(
      title: "Fallas",
      subtitle: "Registro y tipos de fallos",
      icon: material.Icons.warning_amber,
      color: kOrange,
    ),
    ReporteItem(
      title: "Consumo Energético",
      subtitle: "Reporte de consumo en kWh",
      icon: material.Icons.bolt,
      color: kYellow,
    ),
  ];

  void _openPreview(material.BuildContext context) {
    material.Navigator.of(context).push(
      material.PageRouteBuilder(
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
  material.Widget build(material.BuildContext context) {
    final size = material.MediaQuery.of(context).size;

    return material.Dialog(
      backgroundColor: kCard,
      shape: material.RoundedRectangleBorder(
        borderRadius: material.BorderRadius.circular(18),
      ),
      child: material.ConstrainedBox(
        constraints: material.BoxConstraints(
          maxWidth: 650,
          maxHeight: size.height * 0.9,
        ),
        child: material.SingleChildScrollView(
          padding: const material.EdgeInsets.all(24),
          child: material.Column(
            crossAxisAlignment: material.CrossAxisAlignment.start,
            children: [
              material.Row(
                children: [
                  const material.Expanded(
                    child: material.Text(
                      "Generar Reporte",
                      style: material.TextStyle(
                        fontSize: 24,
                        fontWeight: material.FontWeight.bold,
                        color: kText,
                      ),
                    ),
                  ),
                  material.IconButton(
                    onPressed: () => material.Navigator.pop(context),
                    icon: const material.Icon(material.Icons.close),
                  )
                ],
              ),
              const material.SizedBox(height: 8),
              material.Container(
                width: double.infinity,
                padding: const material.EdgeInsets.all(12),
                decoration: material.BoxDecoration(
                  color: kCardDark,
                  borderRadius: material.BorderRadius.circular(10),
                  border: material.Border.all(color: kBorder),
                ),
                child: material.Column(
                  crossAxisAlignment: material.CrossAxisAlignment.start,
                  children: [
                    material.RichText(
                      text: material.TextSpan(
                        style: const material.TextStyle(color: kMuted, fontSize: 13),
                        children: [
                          const material.TextSpan(text: "Reporte para: "),
                          material.TextSpan(
                            text: widget.maqueta,
                            style: const material.TextStyle(color: kText, fontWeight: material.FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    const material.SizedBox(height: 4),
                    material.RichText(
                      text: material.TextSpan(
                        style: const material.TextStyle(color: kMuted, fontSize: 13),
                        children: [
                          const material.TextSpan(text: "Período: "),
                          material.TextSpan(
                            text: "${DateFormat('dd/MM/yy').format(widget.dateRange.start)} - ${DateFormat('dd/MM/yy').format(widget.dateRange.end)}",
                            style: const material.TextStyle(color: kText, fontWeight: material.FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const material.SizedBox(height: 20),
              const material.Text(
                "Tipos de reporte a incluir",
                style: material.TextStyle(
                  color: kText,
                  fontSize: 16,
                  fontWeight: material.FontWeight.bold,
                ),
              ),
              const material.SizedBox(height: 14),
              ...reportes.map((item) => buildReporteCard(item)),
              const material.SizedBox(height: 26),
              material.SizedBox(
                width: double.infinity,
                child: material.ElevatedButton.icon(
                  style: material.ElevatedButton.styleFrom(
                    backgroundColor: kBlue,
                    padding: const material.EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () => _openPreview(context),
                  icon: const material.Icon(material.Icons.preview_outlined),
                  label: const material.Text("Previsualizar PDF"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  material.Widget buildReporteCard(ReporteItem item) {
    return material.Container(
      margin: const material.EdgeInsets.only(bottom: 14),
      padding: const material.EdgeInsets.fromLTRB(14, 10, 8, 10),
      decoration: material.BoxDecoration(
        color: kCardDark,
        borderRadius: material.BorderRadius.circular(14),
        border: material.Border.all(
          color: item.selected ? kBlue : kBorder,
          width: item.selected ? 2 : 1,
        ),
      ),
      child: material.InkWell(
        onTap: () {
          setState(() {
            item.selected = !item.selected;
          });
        },
        child: material.Row(
          children: [
            material.Icon(item.icon, color: item.color),
            const material.SizedBox(width: 12),
            material.Expanded(
              child: material.Column(
                crossAxisAlignment: material.CrossAxisAlignment.start,
                children: [
                  material.Text(
                    item.title,
                    style: const material.TextStyle(
                      color: kText,
                      fontWeight: material.FontWeight.bold,
                    ),
                  ),
                  material.Text(
                    item.subtitle,
                    style: const material.TextStyle(
                      color: kMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            material.Checkbox(
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


class PreviewScreen extends material.StatelessWidget {
  final String maqueta;
  final List<ReporteItem> reportes;
  final material.DateTimeRange dateRange;
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

    final theme = pw.ThemeData.withFont(
      base: font,
      bold: boldFont,
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
                                  fontWeight: pw.FontWeight.bold, fontSize: 16, color: PdfColors.black),
                            ),
                            pw.SizedBox(height: 4),
                            pw.Text(
                              'Período: $formattedDateRange',
                              style: const pw.TextStyle(
                                  color: PdfColors.black, fontSize: 12),
                            ),
                          ]),
                      pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.end,
                          children: [
                            pw.Text('Planta Industrial 4.0',
                                style: const pw.TextStyle(
                                    fontSize: 10, color: PdfColors.grey700)),
                            pw.Text('Generado el: ${DateFormat('dd/MM/yyyy').format(DateTime.now())}',
                                style: const pw.TextStyle(
                                    fontSize: 10, color: PdfColors.grey700)),
                          ])
                    ])),
            pw.SizedBox(height: 20),
            
            // DYNAMIC SECTIONS
            ...reportes.expand((reporte) {
              if (reporte.title == "Producción") {
                return [_buildProductionSection()];
              } else if (reporte.title == "Tiempo Activo") {
                return [_buildUptimeSection()];
              } else if (reporte.title == "Fallas") {
                return [_buildFailsSection()];
              } else if (reporte.title == "Consumo Energético") {
                return [_buildConsumptionSection()];
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
                  style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey900),
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

  pw.Widget _buildProductionSection() {
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
                    xAxis: pw.FixedAxis(
                      List.generate(dateLabels.length, (i) => i.toDouble()),
                      buildLabel: (v) => pw.Text(dateLabels[v.toInt()], style: const pw.TextStyle(fontSize: 7, color: PdfColors.black)),
                    ),
                    yAxis: pw.FixedAxis([0, 10, 20, 30, 40, 50], textStyle: const pw.TextStyle(fontSize: 7, color: PdfColors.black)),
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
        pw.SizedBox(height: 10),
        pw.Text('El gráfico muestra las unidades producidas diariamente. Se observa el rendimiento de producción total de ${data.produccionTotal} unidades en el periodo.',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.black)),
        pw.SizedBox(height: 25),
      ],
    );
  }

  pw.Widget _buildUptimeSection() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionTitle('Tiempo de Actividad y OEE'),
        pw.SizedBox(height: 10),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              flex: 2,
              child: pw.Container(
                height: 150,
                child: pw.Chart(
                  grid: pw.CartesianGrid(
                    xAxis: pw.FixedAxis(
                      List.generate(dateLabels.length, (i) => i.toDouble()),
                      buildLabel: (v) => pw.Text(dateLabels[v.toInt()], style: const pw.TextStyle(fontSize: 7, color: PdfColors.black)),
                    ),
                    yAxis: pw.FixedAxis([0, 25, 50, 75, 100], textStyle: const pw.TextStyle(fontSize: 7, color: PdfColors.black)),
                  ),
                  datasets: [
                    pw.LineDataSet(
                      color: PdfColors.green,
                      data: List.generate(data.tiempoActivo.length, (i) => pw.PointChartValue(i.toDouble(), data.tiempoActivo[i])),
                      drawPoints: true,
                      pointSize: 3,
                      drawSurface: true,
                      surfaceColor: PdfColors.green100,
                    ),
                  ],
                ),
              ),
            ),
            pw.SizedBox(width: 20),
            pw.Expanded(
              flex: 1,
              child: _buildDataTable('Día', '% OEE', dateLabels, data.tiempoActivo),
            ),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Text('El gráfico anterior muestra el porcentaje de disponibilidad de la máquina por día. El tiempo total de operación registrado fue de ${data.tiempoActivoRaw}.',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.black)),
        pw.SizedBox(height: 25),
      ],
    );
  }

  pw.Widget _buildFailsSection() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionTitle('Registro de Fallas y Alarmas'),
        pw.SizedBox(height: 10),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
             pw.Expanded(
               flex: 2,
               child: pw.Container(
                    height: 120,
                    child: pw.Chart(
                      grid: pw.CartesianGrid(
                        xAxis: pw.FixedAxis(
                          List.generate(dateLabels.length, (i) => i.toDouble()),
                          buildLabel: (v) => pw.Text(dateLabels[v.toInt()], style: const pw.TextStyle(fontSize: 7, color: PdfColors.black)),
                        ),
                        yAxis: pw.FixedAxis([0, 5, 10, 15], textStyle: const pw.TextStyle(fontSize: 7, color: PdfColors.black)),
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
             ),
             pw.SizedBox(width: 20),
             pw.Expanded(
               flex: 1,
               child: pw.Column(children: [
                  pw.Table(
                    border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
                    children: [
                      pw.TableRow(
                        decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                        children: [
                           pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Categoría', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.black))),
                           pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Valor', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.black))),
                        ]
                      ),
                      ...data.pieData.map((p) => pw.TableRow(
                        children: [
                           pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(p.label, style: const pw.TextStyle(fontSize: 8, color: PdfColors.black))),
                           pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('${p.value.toStringAsFixed(1)}%', style: const pw.TextStyle(fontSize: 8, color: PdfColors.black))),
                        ]
                      ))
                    ]
                  )
               ])
             )
          ]
        ),
        pw.SizedBox(height: 10),
        pw.Text('Registro detallado de incidencias y paros de emergencia. Se registraron un total de ${data.fallasTotales} fallas durante este período.',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.black)),
        pw.SizedBox(height: 25),
      ],
    );
  }

  pw.Widget _buildConsumptionSection() {
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
                      xAxis: pw.FixedAxis(
                        List.generate(dateLabels.length, (i) => i.toDouble()),
                        buildLabel: (v) => pw.Text(dateLabels[v.toInt()], style: const pw.TextStyle(fontSize: 7, color: PdfColors.black)),
                      ),
                      yAxis: pw.FixedAxis([0, 2, 4, 6, 8, 10], textStyle: const pw.TextStyle(fontSize: 7, color: PdfColors.black)),
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
        pw.SizedBox(height: 10),
        pw.Text('Historial de consumo eléctrico en kWh por día. El consumo total acumulado en el período fue de ${data.consumoTotal} kWh.',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.black)),
        pw.SizedBox(height: 25),
      ],
    );
  }

  pw.Widget _sectionTitle(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 4, left: 2),
      decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 1.5))),
      child: pw.Text(text, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
    );
  }

  pw.Widget _buildDataTable(String h1, String h2, List<String> labels, List<double> values) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey300),
          children: [
            pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text(h1, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.black))),
            pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text(h2, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.black))),
          ]
        ),
        ...List.generate(labels.length, (i) => pw.TableRow(
          children: [
            pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text(labels[i], style: const pw.TextStyle(fontSize: 8, color: PdfColors.black))),
            pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text(values[i].toStringAsFixed(1), style: const pw.TextStyle(fontSize: 8, color: PdfColors.black))),
          ]
        ))
      ]
    );
  }

  @override
  material.Widget build(material.BuildContext context) {
    final size = material.MediaQuery.of(context).size;
    return material.Center(
      child: material.ConstrainedBox(
        constraints: material.BoxConstraints(
          maxWidth: 650,
          maxHeight: size.height * 0.85,
        ),
        child: material.ClipRRect(
          borderRadius: material.BorderRadius.circular(12),
          child: material.Scaffold(
            backgroundColor: kCardDark,
            body: PdfPreview(
              maxPageWidth: 500,
              pageFormats: const {'A4': PdfPageFormat.a4},
              canChangeOrientation: false,
              canChangePageFormat: false,
              pdfPreviewPageDecoration: const material.BoxDecoration(
                color: material.Colors.white,
              ),
              build: (format) => _generatePdf(format),
              canDebug: false,
              allowPrinting: true,
              allowSharing: true,
              actions: [
                const material.Spacer(),
                PdfPreviewAction(
                  icon: const material.Tooltip(
                    message: 'Volver y Editar',
                    child: material.Icon(material.Icons.edit_outlined),
                  ),
                  onPressed: (context, _, __) {
                    material.Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
