import 'package:flutter/material.dart';

/* void main() {
  runApp(const ReporteApp());
} */

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

class ReporteApp extends StatelessWidget {
  const ReporteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: Center(
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: kBlue,
            padding: const EdgeInsets.symmetric(
              horizontal: 28,
              vertical: 18,
            ),
          ),
          onPressed: () {
            showDialog(
              context: context,
              barrierColor: Colors.black87,
              builder: (_) => const GenerarReporteDialog(),
            );
          },
          child: const Text("Generar Reporte"),
        ),
      ),
    );
  }
}

class ReporteItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  bool selected;
  DateTime? startDate;
  DateTime? endDate;

  ReporteItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.selected = false,
    this.startDate,
    this.endDate,
  });
}

class GenerarReporteDialog extends StatefulWidget {
  const GenerarReporteDialog({super.key});

  @override
  State<GenerarReporteDialog> createState() => _GenerarReporteDialogState();
}

class _GenerarReporteDialogState extends State<GenerarReporteDialog> {
  String selectedMaqueta = "Todas";

  final List<String> maquetas = [
    "Todas",
    "Neumático",
    "Prensado",
    "Maquinados",
    "Robot",
  ];

  final List<ReporteItem> reportes = [
    ReporteItem(
      title: "Producción",
      subtitle: "Reporte de producción",
      icon: Icons.bar_chart,
      color: kBlue,
    ),
    ReporteItem(
      title: "Tiempo Activo",
      subtitle: "Reporte disponibilidad",
      icon: Icons.timer,
      color: kGreen,
    ),
    ReporteItem(
      title: "Fallas",
      subtitle: "Reporte de fallos",
      icon: Icons.warning_amber,
      color: kOrange,
    ),
    ReporteItem(
      title: "Consumo",
      subtitle: "Reporte consumo",
      icon: Icons.bolt,
      color: kYellow,
    ),
  ];

  Future<void> pickDate(
    BuildContext context,
    ReporteItem item,
    bool isStart,
  ) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          item.startDate = picked;
        } else {
          item.endDate = picked;
        }
      });
    }
  }

  String formatDate(DateTime? date) {
    if (date == null) return "Seleccionar";
    return "${date.day}/${date.month}/${date.year}";
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
              const SizedBox(height: 20),
              const Text(
                "Tipos de reporte",
                style: TextStyle(
                  color: kText,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 14),
              ...reportes.map((item) => buildReporteCard(item)),
              const SizedBox(height: 20),
              const Text(
                "Maqueta",
                style: TextStyle(
                  color: kText,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: kCardDark,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: kBorder),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedMaqueta,
                    dropdownColor: kCardDark,
                    isExpanded: true,
                    style: const TextStyle(color: kText),
                    icon: const Icon(Icons.keyboard_arrow_down),
                    onChanged: (value) {
                      setState(() {
                        selectedMaqueta = value!;
                      });
                    },
                    items: maquetas.map((e) {
                      return DropdownMenuItem(
                        value: e,
                        child: Text(e),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 26),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kBlue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: showConfirmModal,
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text("Generar PDF"),
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kCardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: item.selected ? kBlue : kBorder,
          width: item.selected ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          InkWell(
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
          if (item.selected) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: dateButton(
                    "Fecha inicial",
                    formatDate(item.startDate),
                    () => pickDate(context, item, true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: dateButton(
                    "Fecha final",
                    formatDate(item.endDate),
                    () => pickDate(context, item, false),
                  ),
                ),
              ],
            ),
          ]
        ],
      ),
    );
  }

  Widget dateButton(
    String label,
    String value,
    VoidCallback onTap,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: kMuted)),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            decoration: BoxDecoration(
              color: kBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: kBorder),
            ),
            child: Row(
              children: [
                Text(value),
                const Spacer(),
                const Icon(Icons.calendar_month),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void showConfirmModal() {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (_) {
        Future.delayed(const Duration(seconds: 2), () {
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
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
                    "El PDF se generó correctamente",
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
