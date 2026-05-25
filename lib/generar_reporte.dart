import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

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

  const GenerarReporteDialog({
    super.key,
    required this.maqueta,
    required this.dateRange,
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
        barrierColor: kBg.withOpacity(0.7),
        pageBuilder: (context, _, __) => PreviewScreen(
          maqueta: widget.maqueta,
          dateRange: widget.dateRange,
          reportes: reportes.where((r) => r.selected).toList(),
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

  const PreviewScreen({
    super.key,
    required this.maqueta,
    required this.reportes,
    required this.dateRange,
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

    final formattedDateRange = "${DateFormat('dd/MM/yyyy').format(dateRange.start)} - ${DateFormat('dd/MM/yyyy').format(dateRange.end)}";

    pdf.addPage(
      pw.Page(
        theme: theme,
        pageFormat: format,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                     pw.Text(
                        'Reporte de Análisis - $maqueta',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 24),
                     ),
                     pw.SizedBox(height: 4),
                     pw.Text(
                        'Período: $formattedDateRange',
                        style: const pw.TextStyle(color: PdfColors.grey700, fontSize: 14),
                     ),
                  ]
                )
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'Secciones Incluidas:',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18),
              ),
              pw.SizedBox(height: 10),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: reportes.map((item) {
                    return pw.Container(
                      margin: const pw.EdgeInsets.only(bottom: 4),
                      child: pw.Text('• ${item.title} (${item.subtitle})'),
                    );
                }).toList(),
              ),
              pw.SizedBox(height: 30),
              pw.Center(
                child: pw.Text(
                  'Contenido detallado y gráficos irían aquí.',
                  style: pw.TextStyle(fontStyle: pw.FontStyle.italic, color: PdfColors.grey),
                ),
              ),
              pw.Spacer(),
              pw.Footer(
                title: pw.Text(
                  'Reporte generado el: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
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
              maxPageWidth: 400,
              pageFormats: const {'A4': PdfPageFormat.a4},
              canChangeOrientation: false,
              canChangePageFormat: false,
              pdfPreviewPageDecoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              build: (format) => _generatePdf(format),
              canDebug: false,
              allowPrinting: false,
              allowSharing: false,
              actions: [
                const Spacer(),
                PdfPreviewAction(
                  icon: const Tooltip(
                    message: 'Descargar PDF',
                    child: Icon(Icons.save_alt_outlined),
                  ),
                  onPressed: (context, fn, format) async {
                    final bytes = await _generatePdf(format);
                    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => bytes);
                    showConfirmModal(context);
                  },
                ),
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
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (_) {
        Future.delayed(const Duration(seconds: 2), () {
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
        });

        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Center(
            child: Container(
              width: 280,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 28,
              ),
              decoration: BoxDecoration(
                color: kCard,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.35),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: const BoxDecoration(
                      color: kGreen,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 42,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    "¡Reporte generado!",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: kText,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "El PDF se ha enviado a la cola de impresión/descarga.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: kMuted,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: kBlue,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
