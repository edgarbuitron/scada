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
    "[${DateFormat('HH:mm:ss').format(DateTime.now())}] [Ingeniero] - Sistema iniciado - Centro Neumático SCADA",
    "[${DateFormat('HH:mm:ss').format(DateTime.now())}] [Ingeniero] - Modo: manual - Rol: Ingeniero",
  ];

  void _addLog(String message) {
    setState(() {
      _auditLogs.insert(0, "[${DateFormat('HH:mm:ss').format(DateTime.now())}] [Ingeniero] - $message");
    });
  }

  @override
  Widget build(BuildContext context) {
    const Color kBg = Color(0xFF081014);
    const Color kPanel = Color(0xFF11222C);
    const Color kCyan = Color(0xFF00EAFF);
    const Color kRed = Color(0xFFFF3366);
    const Color kGreen = Color(0xFF00FF88);
    const Color kBorder = Color(0xFF1A3644);
    const Color kText = Color(0xFFC5D1D8);

    return Scaffold(
      backgroundColor: kBg,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título Principal del Panel
            const Text(
              'PANEL GENERAL',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 16),

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
                  // Primera Fila: Modo y Piezas
                  Row(
                    children: [
                      const Text('Modo:', style: TextStyle(color: kText, fontSize: 13)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildModeDropdown(kCyan, kPanel)),
                      const SizedBox(width: 20),
                      const Text('Piezas:', style: TextStyle(color: kText, fontSize: 13)),
                      const SizedBox(width: 8),
                      _buildPiecesInput(kCyan, kBorder, kBg),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Segunda Fila: Botones de Acción
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.start,
                    children: [
                      _buildControlButton(
                        label: 'INICIAR CICLO',
                        icon: Icons.play_arrow_rounded,
                        color: kGreen.withOpacity(0.15),
                        textColor: kGreen,
                        onTap: () {
                          _addLog('Iniciando secuencia automática...');
                        },
                      ),
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
                      _buildControlButton(
                        label: 'RESTABLECER',
                        icon: Icons.refresh_rounded,
                        color: kCyan,
                        textColor: Colors.black,
                        onTap: () {
                          setState(() {
                            _emergencyStop = false;
                            _finishedPieces = 0;
                          });
                          _addLog('Sistema restablecido correctamente.');
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Tercera Fila: Contador de Piezas
                  _buildCounter(kGreen, kPanel),
                ],
              ),
            ),
            
            const SizedBox(height: 250), // Espacio para el gemelo digital

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
        color: const Color(0xFF081014),
        border: Border.all(color: color.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedMode,
          dropdownColor: bg,
          isExpanded: true,
          style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold),
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
      ),
    );
  }

  Widget _buildPiecesInput(Color color, Color border, Color bg) {
    return Container(
      width: 60,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: border),
      ),
      child: TextField(
        keyboardType: TextInputType.number,
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
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
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: textColor.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: textColor, size: 20),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildCounter(Color color, Color bg) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        children: [
          const Text('PIEZAS PROCESADAS', style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(_finishedPieces.toString(), style: TextStyle(color: color, fontSize: 32, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildAuditTrail(Color titleColor, Color border) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.history_edu_rounded, color: titleColor, size: 18),
            const SizedBox(width: 8),
            Text('AUDITORÍA (AUDIT TRAIL)', style: TextStyle(color: titleColor, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          height: 180,
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.4),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: border),
          ),
          child: ListView.builder(
            itemCount: _auditLogs.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  _auditLogs[index],
                  style: const TextStyle(color: Color(0xFFFFAA00), fontFamily: 'monospace', fontSize: 11),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
