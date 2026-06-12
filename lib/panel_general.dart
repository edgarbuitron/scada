import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'usage_monitor.dart';

// ── Paleta de Colores ──────────────────────────────────
const Color kBg = Color(0xFF081014);
const Color kPanel = Color(0xFF11222C);
const Color kCyanN = Color(0xFF00EAFF);
const Color kGreenN = Color(0xFF00FF88);
const Color kRedN = Color(0xFFFF3366);
const Color kBorderN = Color(0xFF1A3644);
const Color kText = Color(0xFFC5D1D8);
const Color kAudit = Color(0xFFFFAA00);

class PanelGeneralScreen extends StatefulWidget {
  const PanelGeneralScreen({super.key});

  @override
  State<PanelGeneralScreen> createState() => _PanelGeneralScreenState();
}

class _PanelGeneralScreenState extends State<PanelGeneralScreen> {
  String _mode = 'manual';
  final TextEditingController _piezasController = TextEditingController(text: '1');
  int _piezasTerminadas = 0;
  bool _isCycleRunning = false;
  
  final List<Map<String, dynamic>> _logs = [
    {
      "time": "17:56:53",
      "role": "Ingeniero",
      "message": "Configuración cambiada a Modo: manual",
      "color": kAudit
    }
  ];
  final ScrollController _logScroll = ScrollController();

  void _logAudit(String msg, Color color) {
    final now = DateTime.now();
    final time = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";
    setState(() {
      _logs.add({"time": time, "role": "Ingeniero", "message": msg, "color": color});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_logScroll.hasClients) {
        _logScroll.animateTo(_logScroll.position.maxScrollExtent, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
      }
    });
  }

  Future<void> _simularCicloGeneral() async {
    if (_isCycleRunning) return;
    final int target = int.tryParse(_piezasController.text) ?? 1;
    if (target <= 0) return;

    setState(() => _isCycleRunning = true);
    final monitor = Provider.of<UsageMonitor>(context, listen: false);
    monitor.setStationActive('general', true);

    _logAudit("Iniciando ciclo supervisor...", kCyanN);

    for (int i = 0; i < target; i++) {
      if (!_isCycleRunning) break;
      await Future.delayed(const Duration(seconds: 2));
      if (!_isCycleRunning) break;
      
      setState(() => _piezasTerminadas++);
      monitor.addProduction('general');
      _logAudit("Pieza supervisor ${i+1} completada", kGreenN);
    }

    setState(() => _isCycleRunning = false);
    monitor.setStationActive('general', false);
    _logAudit("Ciclo supervisor finalizado", kCyanN);
    monitor.syncStationAuditoria('general'); // Sincronizar
  }

  void _emergencyStop() {
    setState(() => _isCycleRunning = false);
    final monitor = Provider.of<UsageMonitor>(context, listen: false);
    monitor.setStationActive('general', false);
    monitor.addFailure('general');
    _logAudit("¡PARO DE EMERGENCIA ACTIVADO!", kRedN);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildControlPanel(),
            const SizedBox(height: 20),
            _buildAuditPanel(),
          ],
        ),
      ),
    );
  }

  Widget _buildControlPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kPanel,
        border: Border.all(color: kBorderN),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 16,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Selector de Modo
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Modo: ', style: TextStyle(color: kText)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: kCyanN),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _mode,
                        dropdownColor: kPanel,
                        style: const TextStyle(color: kCyanN, fontSize: 13),
                        items: const [
                          DropdownMenuItem(value: 'manual', child: Text('Manual (Simulación Física)')),
                          DropdownMenuItem(value: 'auto', child: Text('Automático')),
                        ],
                        onChanged: (v) {
                          setState(() => _mode = v!);
                          _logAudit("Modo cambiado a $v", kAudit);
                        },
                      ),
                    ),
                  ),
                ],
              ),
              // Input de Piezas
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Piezas: ', style: TextStyle(color: kText)),
                  SizedBox(
                    width: 50,
                    height: 35,
                    child: TextField(
                      controller: _piezasController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: kText),
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.zero,
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: kBorderN)),
                        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: kCyanN)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Botones de Acción
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _actionBtn(
                icon: _isCycleRunning ? Icons.stop : Icons.play_arrow,
                label: _isCycleRunning ? "EJECUTANDO..." : "INICIAR CICLO",
                color: _isCycleRunning ? kGreenN.withValues(alpha: 0.2) : kGreenN,
                textColor: _isCycleRunning ? kGreenN : Colors.black,
                onTap: _mode == 'auto' ? _simularCicloGeneral : null,
              ),
              _actionBtn(
                icon: Icons.warning_amber_rounded,
                label: "PARO EMERGENCIA",
                color: kRedN,
                textColor: Colors.white,
                onTap: _emergencyStop,
              ),
              _actionBtn(
                icon: Icons.refresh,
                label: "RESTABLECER",
                color: kCyanN,
                textColor: Colors.black,
                onTap: () {
                   final monitor = Provider.of<UsageMonitor>(context, listen: false);
                   setState(() => _piezasTerminadas = 0);
                   monitor.resetCyclePieces('general');
                   monitor.syncStationAuditoria('general'); // Sincronizar al reset
                   _logAudit("Sistema restablecido", kCyanN);
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          // KPI Piezas
          Container(
            width: 140,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: kGreenN.withValues(alpha: 0.5)),
              borderRadius: BorderRadius.circular(6),
              color: kGreenN.withValues(alpha: 0.05),
            ),
            child: Column(
              children: [
                const Text('Piezas Terminadas', style: TextStyle(color: kText, fontSize: 11)),
                Text('$_piezasTerminadas', style: const TextStyle(color: kGreenN, fontSize: 24, fontWeight: FontWeight.bold)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _actionBtn({required IconData icon, required String label, required Color color, required Color textColor, required VoidCallback? onTap}) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: textColor,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  Widget _buildAuditPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kPanel,
        border: Border.all(color: kBorderN),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Auditoría (Audit Trail) y Alertas', style: TextStyle(color: kCyanN, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Container(
            height: 250,
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: kBorderN),
            ),
            child: ListView.builder(
              controller: _logScroll,
              itemCount: _logs.length,
              itemBuilder: (context, i) {
                final log = _logs[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                      children: [
                        TextSpan(text: "[${log['time']}] ", style: const TextStyle(color: kText)),
                        TextSpan(text: "[${log['role']}] - ", style: const TextStyle(color: kCyanN)),
                        TextSpan(text: log['message'], style: TextStyle(color: log['color'])),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
