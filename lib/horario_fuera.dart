import 'package:flutter/material.dart';

class HorarioFueraDialog extends StatelessWidget {
  const HorarioFueraDialog({super.key});

  @override
  Widget build(BuildContext context) {
    const Color kBg = Color(0xFF081014);
    const Color kPanel = Color(0xFF11222C);
    const Color kCyan = Color(0xFF00EAFF);
    const Color kText = Color(0xFFC5D1D8);
    const Color kRed = Color(0xFFF43F5E);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        width: 450,
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: kPanel,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: kRed.withOpacity(0.5), width: 2),
          boxShadow: [
            BoxShadow(color: kRed.withOpacity(0.15), blurRadius: 30, spreadRadius: 5)
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: kRed.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.timer_off_rounded, size: 60, color: kRed),
            ),
            const SizedBox(height: 25),
            const Text(
              'CONEXIÓN RESTRINGIDA',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 15),
            const Text(
              'Actualmente te encuentras fuera del horario asignado para operar las maquetas físicas.',
              textAlign: TextAlign.center,
              style: TextStyle(color: kText, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: kBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: kCyan, size: 18),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Puedes seguir usando la App para consultar analíticas y reportes, pero no podrás enviar comandos al hardware.',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 35),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kRed,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 5,
                ),
                child: const Text(
                  'ENTENDIDO',
                  style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Función de utilidad para mostrar el bloqueo
void mostrarBloqueoHorario(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => const HorarioFueraDialog(),
  );
}
