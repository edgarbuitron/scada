import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Paleta de colores consistente con el proyecto
const Color kBgDark = Color(0xFF0F172A);
const Color kPanelBg = Color(0xFF1E293B);
const Color kCyan = Color(0xFF38BDF8);
const Color kGreen = Color(0xFF10B981);
const Color kRed = Color(0xFFF43F5E);
const Color kTextMain = Color(0xFFF8FAFC);
const Color kTextMuted = Color(0xFF94A3B8);
const Color kBorder = Color(0xFF334155);

class ScadaHitechDashboard extends StatefulWidget {
  const ScadaHitechDashboard({super.key});

  @override
  State<ScadaHitechDashboard> createState() => _ScadaHitechDashboardState();
}

class _ScadaHitechDashboardState extends State<ScadaHitechDashboard> {
  String _selectedMode = 'Manual (Simulación Física)';
  int _piecesToProcess = 1;
  int _finishedPieces = 0;
  bool _emergencyStop = false;
  bool _cycleStarted = false;
  
  final List<String> _auditLogs = [
    "[${DateFormat('HH:mm:ss').format(DateTime.now())}] [Ingeniero] - Sistema inicializado",
  ];

  void _addLog(String message) {
    setState(() {
      _auditLogs.insert(0, "[${DateFormat('HH:mm:ss').format(DateTime.now())}] [Operador] - $message");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgDark,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            _buildControlPanel(),
            const SizedBox(height: 24),
            _buildAuditTrail(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'HITECH INGENIUM SCADA',
          style: TextStyle(
            color: kCyan,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const Divider(color: kCyan, thickness: 1.5),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            DateFormat('HH:mm:ss').format(DateTime.now()),
            style: const TextStyle(color: kTextMuted, fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildControlPanel() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kPanelBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Modo: ', style: TextStyle(color: kTextMain)),
              const SizedBox(width: 8),
              _buildModeDropdown(),
              const Spacer(),
              const Text('Piezas: ', style: TextStyle(color: kTextMain)),
              const SizedBox(width: 8),
              _buildPiecesInput(),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildControlButton(
                label: 'INICIAR CICLO',
                icon: Icons.play_arrow,
                color: _cycleStarted || _emergencyStop ? Colors.grey : Colors.white24,
                textColor: _cycleStarted || _emergencyStop ? Colors.grey : kTextMain,
                onTap: _cycleStarted || _emergencyStop ? null : () {
                  setState(() => _cycleStarted = true);
                  _addLog('Ciclo iniciado - $_piecesToProcess piezas');
                },
              ),
              _buildControlButton(
                label: 'PARO EMERGENCIA',
                icon: Icons.warning_amber_rounded,
                color: kRed,
                textColor: kTextMain,
                onTap: () {
                  setState(() {
                    _emergencyStop = true;
                    _cycleStarted = false;
                  });
                  _addLog('¡PARO DE EMERGENCIA ACTIVADO!');
                },
              ),
              _buildControlButton(
                label: 'RESTABLECER',
                icon: Icons.refresh,
                color: kCyan,
                textColor: Colors.black,
                onTap: () {
                  setState(() {
                    _emergencyStop = false;
                    _cycleStarted = false;
                    _finishedPieces = 0;
                  });
                  _addLog('Sistema restablecido');
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildCounterCard(),
        ],
      ),
    );
  }

  Widget _buildModeDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: kCyan),
        borderRadius: BorderRadius.circular(4),
      ),
      child: DropdownButton<String>(
        value: _selectedMode,
        dropdownColor: kPanelBg,
        underline: const SizedBox(),
        style: const TextStyle(color: kCyan, fontSize: 13),
        items: ['Manual (Simulación Física)', 'Automático', 'Mantenimiento'].map((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
        onChanged: (val) {
          if (val != null) {
            setState(() => _selectedMode = val);
            _addLog('Configuración cambiada a Modo: ${val.toLowerCase()}');
          }
        },
      ),
    );
  }

  Widget _buildPiecesInput() {
    return Container(
      width: 60,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: kBorder),
      ),
      child: TextField(
        keyboardType: TextInputType.number,
        style: const TextStyle(color: kCyan),
        textAlign: TextAlign.center,
        decoration: const InputDecoration(border: InputBorder.none, isDense: true),
        onChanged: (val) {
          final n = int.tryParse(val);
          if (n != null) setState(() => _piecesToProcess = n);
        },
        controller: TextEditingController(text: _piecesToProcess.toString()),
      ),
    );
  }

  Widget _buildControlButton({
    required String label,
    required IconData icon,
    required Color color,
    required Color textColor,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          children: [
            Icon(icon, color: textColor, size: 18),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildCounterCard() {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: kGreen, width: 2),
      ),
      child: Column(
        children: [
          const Text('Piezas Terminadas', style: TextStyle(color: kGreen, fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            _finishedPieces.toString(),
            style: const TextStyle(color: kGreen, fontSize: 32, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildAuditTrail() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Auditoría (Audit Trail) y Alertas',
          style: TextStyle(color: kCyan, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Container(
          height: 120,
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: kBorder),
          ),
          child: ListView.builder(
            itemCount: _auditLogs.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Text(
                  _auditLogs[index],
                  style: const TextStyle(color: Colors.orange, fontFamily: 'monospace', fontSize: 12),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
