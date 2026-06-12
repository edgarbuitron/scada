import 'package:flutter/material.dart' as material;
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_filex/open_filex.dart';
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

class ExcelItem {
  final String title;
  final String subtitle;
  final material.IconData icon;
  final material.Color color;
  bool selected;

  ExcelItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.selected = false,
  });
}

class GenerarExcelDialog extends material.StatefulWidget {
  final String maqueta;
  final material.DateTimeRange dateRange;
  final StationAnalyticsData data;
  final List<String> dateLabels;

  const GenerarExcelDialog({
    super.key,
    required this.maqueta,
    required this.dateRange,
    required this.data,
    required this.dateLabels,
  });

  @override
  material.State<GenerarExcelDialog> createState() => _GenerarExcelDialogState();
}

class _GenerarExcelDialogState extends material.State<GenerarExcelDialog> {
  final List<ExcelItem> items = [
    ExcelItem(
      title: "Producción",
      subtitle: "Datos detallados de piezas producidas",
      icon: material.Icons.bar_chart,
      color: kBlue,
      selected: true,
    ),
    ExcelItem(
      title: "Tiempo Activo",
      subtitle: "Disponibilidad diaria y OEE",
      icon: material.Icons.timer,
      color: kGreen,
      selected: true,
    ),
    ExcelItem(
      title: "Fallas",
      subtitle: "Registro histórico de alarmas",
      icon: material.Icons.warning_amber,
      color: kOrange,
      selected: true,
    ),
    ExcelItem(
      title: "Consumo Energético",
      subtitle: "Lecturas de energía en kWh",
      icon: material.Icons.bolt,
      color: kYellow,
      selected: true,
    ),
  ];

  void _openPreview(material.BuildContext context) {
    material.Navigator.of(context).push(
      material.PageRouteBuilder(
        opaque: false,
        barrierColor: kBg.withValues(alpha: 0.7),
        pageBuilder: (context, _, __) => PreviewExcelScreen(
          maqueta: widget.maqueta,
          dateRange: widget.dateRange,
          items: items.where((i) => i.selected).toList(),
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
                      "Generar Excel",
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
                "Hojas a incluir en el Excel",
                style: material.TextStyle(
                  color: kText,
                  fontSize: 16,
                  fontWeight: material.FontWeight.bold,
                ),
              ),
              const material.SizedBox(height: 14),
              ...items.map((item) => buildExcelItemCard(item)),
              const material.SizedBox(height: 26),
              material.SizedBox(
                width: double.infinity,
                child: material.ElevatedButton.icon(
                  style: material.ElevatedButton.styleFrom(
                    backgroundColor: kGreen,
                    padding: const material.EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () => _openPreview(context),
                  icon: const material.Icon(material.Icons.preview_outlined),
                  label: const material.Text("Previsualizar Excel"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  material.Widget buildExcelItemCard(ExcelItem item) {
    return material.Container(
      margin: const material.EdgeInsets.only(bottom: 14),
      padding: const material.EdgeInsets.fromLTRB(14, 10, 8, 10),
      decoration: material.BoxDecoration(
        color: kCardDark,
        borderRadius: material.BorderRadius.circular(14),
        border: material.Border.all(
          color: item.selected ? kGreen : kBorder,
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
              activeColor: kGreen,
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

class PreviewExcelScreen extends material.StatefulWidget {
  final String maqueta;
  final material.DateTimeRange dateRange;
  final List<ExcelItem> items;
  final StationAnalyticsData data;
  final List<String> dateLabels;

  const PreviewExcelScreen({
    super.key,
    required this.maqueta,
    required this.dateRange,
    required this.items,
    required this.data,
    required this.dateLabels,
  });

  @override
  material.State<PreviewExcelScreen> createState() => _PreviewExcelScreenState();
}

class _PreviewExcelScreenState extends material.State<PreviewExcelScreen> {
  String? _generatedFilePath;

  Future<String> _generateExcelFile() async {
    try {
      final xlsio.Workbook workbook = xlsio.Workbook();
      final xlsio.Worksheet sheet = workbook.worksheets[0];
      sheet.name = "Reporte SCADA";
      
      // Header
      sheet.getRangeByName('A1:E1').merge();
      sheet.getRangeByName('A1').setText('REPORTE INDUSTRIAL - SCADA MASTER');
      sheet.getRangeByName('A1').cellStyle.bold = true;
      sheet.getRangeByName('A1').cellStyle.fontSize = 14;
      sheet.getRangeByName('A1').cellStyle.hAlign = xlsio.HAlignType.center;

      sheet.getRangeByIndex(3, 1).setText('Maqueta:');
      sheet.getRangeByIndex(3, 2).setText(widget.maqueta);
      sheet.getRangeByIndex(4, 1).setText('Período:');
      sheet.getRangeByIndex(4, 2).setText("${DateFormat('dd/MM/yy').format(widget.dateRange.start)} - ${DateFormat('dd/MM/yy').format(widget.dateRange.end)}");
      sheet.getRangeByIndex(5, 1).setText('Fecha Generación:');
      sheet.getRangeByIndex(5, 2).setText(DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now()));

      int currentRow = 7;

      // Detailed Sections
      for (var item in widget.items) {
        sheet.getRangeByIndex(currentRow, 1).setText('DETALLE: ${item.title.toUpperCase()}');
        sheet.getRangeByIndex(currentRow, 1).cellStyle.bold = true;
        sheet.getRangeByIndex(currentRow, 1).cellStyle.fontSize = 12;
        currentRow++;

        sheet.getRangeByIndex(currentRow, 1).setText('Fecha');
        sheet.getRangeByIndex(currentRow, 2).setText('Valor');
        sheet.getRangeByIndex(currentRow, 1, currentRow, 2).cellStyle.bold = true;
        sheet.getRangeByIndex(currentRow, 1, currentRow, 2).cellStyle.backColor = '#D1D5DB';
        sheet.getRangeByIndex(currentRow, 1, currentRow, 2).cellStyle.fontColor = '#000000';
        currentRow++;

        List<double> dataList = [];
        if (item.title == "Producción") dataList = widget.data.produccion;
        else if (item.title == "Tiempo Activo") dataList = widget.data.tiempoActivo;
        else if (item.title == "Fallas") dataList = widget.data.fallas;
        else if (item.title == "Consumo Energético") dataList = widget.data.consumo;

        for (int i = 0; i < widget.dateLabels.length; i++) {
          sheet.getRangeByIndex(currentRow, 1).setText(widget.dateLabels[i]);
          sheet.getRangeByIndex(currentRow, 2).setNumber(dataList[i]);
          currentRow++;
        }
        currentRow += 2;
      }

      final List<int> bytes = workbook.saveAsStream();
      workbook.dispose();

      Directory? directory;
      if (Platform.isAndroid) {
        directory = await getExternalStorageDirectory();
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      final String path = directory!.path;
      final String fileName = '$path/Reporte_Excel_${widget.maqueta}_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      final File file = File(fileName);
      await file.writeAsBytes(bytes, flush: true);
      
      _generatedFilePath = fileName;
      return fileName;
    } catch (e) {
      rethrow;
    }
  }

  void _shareFile() async {
    if (_generatedFilePath != null) {
      await Share.shareXFiles([XFile(_generatedFilePath!)], text: 'Reporte Excel SCADA - ${widget.maqueta}');
    }
  }

  @override
  material.Widget build(material.BuildContext context) {
    final size = material.MediaQuery.of(context).size;
    
    return material.Scaffold(
      backgroundColor: material.Colors.transparent,
      body: material.Center(
        child: material.ConstrainedBox(
          constraints: material.BoxConstraints(
            maxWidth: 650,
            maxHeight: size.height * 0.85,
          ),
          child: material.ClipRRect(
            borderRadius: material.BorderRadius.circular(12),
            child: material.Scaffold(
              backgroundColor: material.Colors.white,
              appBar: material.AppBar(
                backgroundColor: kCard,
                elevation: 0,
                title: const material.Text('Vista Previa Excel', style: material.TextStyle(color: material.Colors.white, fontSize: 18)),
                leading: material.IconButton(
                  icon: const material.Icon(material.Icons.arrow_back, color: material.Colors.white),
                  onPressed: () => material.Navigator.pop(context),
                ),
              ),
              body: material.Column(
                children: [
                  material.Expanded(
                    child: material.SingleChildScrollView(
                      padding: const material.EdgeInsets.all(32),
                      child: material.Column(
                        crossAxisAlignment: material.CrossAxisAlignment.start,
                        children: [
                          material.Row(
                            mainAxisAlignment: material.MainAxisAlignment.spaceBetween,
                            children: [
                              material.Column(
                                crossAxisAlignment: material.CrossAxisAlignment.start,
                                children: [
                                  material.Text(
                                    'Reporte de Análisis SCADA',
                                    style: material.TextStyle(fontWeight: material.FontWeight.bold, fontSize: 24, color: material.Colors.blue[900]),
                                  ),
                                  const material.SizedBox(height: 4),
                                  material.Text(
                                    'Maqueta: ${widget.maqueta}',
                                    style: const material.TextStyle(fontWeight: material.FontWeight.bold, fontSize: 18, color: material.Colors.black),
                                  ),
                                  const material.SizedBox(height: 4),
                                  material.Text(
                                    'Período: ${DateFormat('dd/MM/yyyy').format(widget.dateRange.start)} - ${DateFormat('dd/MM/yyyy').format(widget.dateRange.end)}',
                                    style: const material.TextStyle(color: material.Colors.black, fontSize: 13),
                                  ),
                                ],
                              ),
                              material.Column(
                                crossAxisAlignment: material.CrossAxisAlignment.end,
                                children: [
                                  const material.Text('Planta Industrial 4.0', style: material.TextStyle(fontSize: 11, color: material.Colors.grey)),
                                  material.Text('Generado el: ${DateFormat('dd/MM/yyyy').format(DateTime.now())}', style: const material.TextStyle(fontSize: 11, color: material.Colors.grey)),
                                ],
                              ),
                            ],
                          ),
                          const material.SizedBox(height: 32),

                          // Sections Preview
                          ...widget.items.map((item) => _buildSectionPreview(item)),
                        ],
                      ),
                    ),
                  ),
                  
                  // Bottom Actions Bar
                  material.Container(
                    padding: const material.EdgeInsets.symmetric(vertical: 20, horizontal: 40),
                    decoration: material.BoxDecoration(
                      color: kCardDark,
                      border: material.Border(top: material.BorderSide(color: material.Colors.grey[300]!, width: 0.5)),
                    ),
                    child: material.Row(
                      mainAxisAlignment: material.MainAxisAlignment.spaceAround,
                      children: [
                        _actionButton(material.Icons.print, 'Imprimir', () async {
                           final path = await _generateExcelFile();
                           await OpenFilex.open(path);
                        }),
                        _actionButton(material.Icons.share, 'Compartir', () async {
                           await _generateExcelFile();
                           _shareFile();
                        }),
                        _actionButton(material.Icons.edit, 'Editar', () {
                           material.Navigator.pop(context);
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  material.Widget _buildSectionPreview(ExcelItem item) {
    List<double> dataList = [];
    if (item.title == "Producción") dataList = widget.data.produccion;
    else if (item.title == "Tiempo Activo") dataList = widget.data.tiempoActivo;
    else if (item.title == "Fallas") dataList = widget.data.fallas;
    else if (item.title == "Consumo Energético") dataList = widget.data.consumo;

    return material.Column(
      crossAxisAlignment: material.CrossAxisAlignment.start,
      children: [
        material.Padding(
          padding: const material.EdgeInsets.symmetric(vertical: 12),
          child: material.Text(
            'Análisis de ${item.title}',
            style: material.TextStyle(fontSize: 16, fontWeight: material.FontWeight.bold, color: material.Colors.black),
          ),
        ),
        material.Table(
          border: material.TableBorder.all(color: material.Colors.black, width: 1.0),
          children: [
            material.TableRow(
              decoration: material.BoxDecoration(color: material.Colors.grey[300]),
              children: [
                const material.Padding(padding: material.EdgeInsets.all(8), child: material.Text('Día', style: material.TextStyle(fontWeight: material.FontWeight.bold, fontSize: 12, color: material.Colors.black))),
                material.Padding(padding: const material.EdgeInsets.all(8), child: material.Text(item.title, style: const material.TextStyle(fontWeight: material.FontWeight.bold, fontSize: 12, color: material.Colors.black))),
              ],
            ),
            ...List.generate(widget.dateLabels.length, (i) => material.TableRow(
              children: [
                material.Padding(padding: const material.EdgeInsets.all(8), child: material.Text(widget.dateLabels[i], style: const material.TextStyle(fontSize: 12, color: material.Colors.black))),
                material.Padding(padding: const material.EdgeInsets.all(8), child: material.Text(dataList[i].toStringAsFixed(1), style: const material.TextStyle(fontSize: 12, color: material.Colors.black))),
              ],
            )),
          ],
        ),
        const material.SizedBox(height: 24),
      ],
    );
  }

  material.Widget _actionButton(material.IconData icon, String label, material.VoidCallback onTap) {
    return material.Column(
      mainAxisSize: material.MainAxisSize.min,
      children: [
        material.IconButton(
          icon: material.Icon(icon, color: kBlue, size: 28),
          onPressed: onTap,
        ),
        material.Text(label, style: const material.TextStyle(color: kText, fontSize: 12)),
        const material.SizedBox(height: 4),
        material.Container(height: 2, width: 30, color: kBlue),
      ],
    );
  }
}
