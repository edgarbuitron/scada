import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class InicialStationScreen extends StatefulWidget {
  const InicialStationScreen({super.key});

  @override
  State<InicialStationScreen> createState() => _InicialStationScreenState();
}

class _InicialStationScreenState extends State<InicialStationScreen> {
  String _selectedMode = 'Manual (Simulación Física)';
  int _piecesToProcess = 1;
  int _finishedPieces = 0;
  bool _emergencyStop = false;
  bool _cycleStarted = false;
  
  final List<String> _auditLogs = [
    "[${DateFormat('HH:mm:ss').format(DateTime.now())}] [Ingeniero] - Sistema iniciado - Centro de Prensado TMPUM24-A",
    "[${DateFormat('HH:mm:ss').format(DateTime.now())}] [Ingeniero] - Modo: manual - Rol: Ingeniero",
  ];

  void _addLog(String message) {
    setState(() {
      _auditLogs.insert(0, "[${DateFormat('HH:mm:ss').format(DateTime.now())}] [Ingeniero] - $message");
    });
  }

  @override
  Widget build(BuildContext context) {
    const Color kBg = Color(0xFF0F172A);
    const Color kPanel = Color(0xFF1E293B);
    const Color kCyan = Color(0xFF38BDF8);
    const Color kRed = Color(0xFFF43F5E);
    const Color kGreen = Color(0xFF10B981);
    const Color kBorder = Color(0xFF334155);

    return Scaffold(
      backgroundColor: kBg,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Panel de Control Superior
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: kPanel,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kBorder),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Text('Modo: ', style: TextStyle(color: Colors.white)),
                      const SizedBox(width: 8),
                      _buildModeDropdown(kCyan, kPanel),
                      const SizedBox(width: 20),
                      const Text('Piezas: ', style: TextStyle(color: Colors.white)),
                      const SizedBox(width: 8),
                      _buildPiecesInput(kCyan, kBorder),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      _buildControlButton(
                        label: 'INICIAR CICLO AUTO',
                        icon: Icons.play_circle_fill,
                        color: Colors.white10,
                        textColor: Colors.white38,
                        onTap: null, // Desactivado por ahora
                      ),
                      const SizedBox(width: 15),
                      _buildControlButton(
                        label: 'PARO EMERGENCIA',
                        icon: Icons.warning_amber_rounded,
                        color: kRed,
                        textColor: Colors.white,
                        onTap: () {
                          setState(() => _emergencyStop = true);
                          _addLog('¡PARO DE EMERGENCIA ACTIVADO!');
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      _buildControlButton(
                        label: 'RESTABLECER',
                        icon: Icons.refresh,
                        color: kCyan,
                        textColor: Colors.black,
                        onTap: () {
                          setState(() {
                            _emergencyStop = false;
                            _finishedPieces = 0;
                          });
                          _addLog('Sistema restablecido.');
                        },
                      ),
                      const SizedBox(width: 20),
                      _buildCounter(kGreen),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 400), // Espacio para el gemelo digital (futuro)

            // Panel de Auditoría Inferior
            _buildAuditTrail(kCyan, kBorder),
          ],
        ),
      ),
    );
  }

  Widget _buildModeDropdown(Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: color.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: DropdownButton<String>(
        value: _selectedMode,
        dropdownColor: bg,
        underline: const SizedBox(),
        style: TextStyle(color: color, fontSize: 13),
        items: ['Manual (Simulación Física)', 'Automático'].map((String value) {
          return DropdownMenuItem<String>(value: value, child: Text(value));
        }).toList(),
        onChanged: (val) {
          if (val != null) {
            setState(() => _selectedMode = val);
            _addLog('Modo cambiado a: $val');
          }
        },
      ),
    );
  }

  Widget _buildPiecesInput(Color color, Color border) {
    return Container(
      width: 50,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: border),
      ),
      child: TextField(
        keyboardType: TextInputType.number,
        style: TextStyle(color: color),
        textAlign: TextAlign.center,
        decoration: const InputDecoration(border: InputBorder.none, isDense: true),
        onChanged: (v) => _piecesToProcess = int.tryParse(v) ?? 1,
        controller: TextEditingController(text: _piecesToProcess.toString()),
      ),
    );
  }

  Widget _buildControlButton({required String label, required IconData icon, required Color color, required Color textColor, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(25)),
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

  Widget _buildCounter(Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 2),
      ),
      child: Column(
        children: [
          const Text('Piezas Prensadas', style: TextStyle(color: Colors.white70, fontSize: 10)),
          Text(_finishedPieces.toString(), style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildAuditTrail(Color titleColor, Color border) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Auditoría (Audit Trail) y Alertas', style: TextStyle(color: titleColor, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Container(
          height: 150,
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: border),
          ),
          child: ListView.builder(
            itemCount: _auditLogs.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
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
