import 'package:flutter/material.dart';

void main() {
  runApp(const IndustrialLogsApp());
}

class IndustrialLogsApp extends StatelessWidget {
  const IndustrialLogsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Industrial Logs',
      theme: ThemeData.dark(),
      home: const LogsDashboard(),
    );
  }
}

class LogsDashboard extends StatelessWidget {
  const LogsDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1220),
      body: Row(
        children: [
          const Sidebar(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Historial de Eventos",
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Consulta y analiza eventos del sistema",
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                    const SizedBox(height: 25),

                    const FiltersSection(),

                    const SizedBox(height: 25),

                    Row(
                      children: const [
                        Expanded(
                          child: StatCard(
                            title: "Total eventos",
                            value: "245",
                            color: Colors.blueAccent,
                          ),
                        ),
                        SizedBox(width: 15),
                        Expanded(
                          child: StatCard(
                            title: "Críticos",
                            value: "18",
                            color: Colors.red,
                          ),
                        ),
                        SizedBox(width: 15),
                        Expanded(
                          child: StatCard(
                            title: "Advertencias",
                            value: "47",
                            color: Colors.orange,
                          ),
                        ),
                        SizedBox(width: 15),
                        Expanded(
                          child: StatCard(
                            title: "Informativos",
                            value: "180",
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 25),

                    const LogsTable(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// SIDEBAR
class Sidebar extends StatelessWidget {
  const Sidebar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      color: const Color(0xFF09111C),
      child: Column(
        children: [
          const SizedBox(height: 40),
          const Icon(
            Icons.precision_manufacturing,
            size: 60,
            color: Colors.blueAccent,
          ),
          const SizedBox(height: 15),
          const Text(
            "INDUSTRIAL\nCONTROL",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 40),

          menuItem(Icons.dashboard, "Dashboard"),
          menuItem(Icons.memory, "Maquetas"),
          menuItem(Icons.analytics, "Monitoreo"),
          menuItem(Icons.history, "Historial / Logs", true),
          menuItem(Icons.warning_amber, "Alertas"),
          menuItem(Icons.settings, "Configuración"),
          menuItem(Icons.cloud, "Cloud"),

          const Spacer(),

          const Padding(
            padding: EdgeInsets.all(20),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blueAccent,
                  child: Icon(Icons.person),
                ),
                SizedBox(width: 10),
                Text("Juan Pérez"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget menuItem(IconData icon, String title, [bool selected = false]) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 5,
      ),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: selected ? Colors.blueAccent : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon),
          const SizedBox(width: 12),
          Text(title),
        ],
      ),
    );
  }
}

// FILTERS
class FiltersSection extends StatelessWidget {
  const FiltersSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Row(
            children: [
              filterBox("Fecha inicio"),
              const SizedBox(width: 12),
              filterBox("Fecha final"),
              const SizedBox(width: 12),
              filterBox("Maqueta"),
              const SizedBox(width: 12),
              filterBox("Tipo"),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.filter_alt),
                label: const Text("Filtrar"),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.download),
                label: const Text("Exportar"),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget filterBox(String text) {
    return Expanded(
      child: TextField(
        decoration: InputDecoration(
          hintText: text,
          filled: true,
          fillColor: Colors.black26,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}

// STAT CARD
class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(title),
        ],
      ),
    );
  }
}

// LOGS TABLE
class LogsTable extends StatelessWidget {
  const LogsTable({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(18),
      ),
      child: DataTable(
        columns: const [
          DataColumn(label: Text("Fecha")),
          DataColumn(label: Text("Maqueta")),
          DataColumn(label: Text("Evento")),
          DataColumn(label: Text("Usuario")),
          DataColumn(label: Text("Severidad")),
        ],
        rows: [
          buildRow(
            "20/05/25",
            "Prensa",
            "Motor iniciado",
            "Juan",
            "Info",
            Colors.green,
          ),
          buildRow(
            "20/05/25",
            "Brazo",
            "Paro emergencia",
            "Carlos",
            "Crítico",
            Colors.red,
          ),
          buildRow(
            "20/05/25",
            "Sistema neumático",
            "Presión alta",
            "Ana",
            "Advertencia",
            Colors.orange,
          ),
          buildRow(
            "20/05/25",
            "Manipulador",
            "Sensor desconectado",
            "Luis",
            "Crítico",
            Colors.red,
          ),
        ],
      ),
    );
  }

  DataRow buildRow(
    String fecha,
    String maqueta,
    String evento,
    String usuario,
    String severidad,
    Color color,
  ) {
    return DataRow(
      cells: [
        DataCell(Text(fecha)),
        DataCell(Text(maqueta)),
        DataCell(Text(evento)),
        DataCell(Text(usuario)),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              severidad,
              style: TextStyle(color: color),
            ),
          ),
        ),
      ],
    );
  }
}