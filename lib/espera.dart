import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EsperaScreen extends StatelessWidget {
  const EsperaScreen({super.key});

  Future<void> _cerrarSesion(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (context.mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color kBg = Color(0xFF081014);
    const Color kPanel = Color(0xFF11222C);
    const Color kCyan = Color(0xFF00EAFF);
    const Color kText = Color(0xFFC5D1D8);

    return Scaffold(
      backgroundColor: kBg,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 450),
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: kPanel,
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: kCyan.withValues(alpha: 0.3)),
              boxShadow: [
                BoxShadow(
                  color: kCyan.withValues(alpha: 0.1),
                  blurRadius: 30,
                  spreadRadius: 5,
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.pending_actions_rounded,
                  size: 80,
                  color: kCyan,
                ),
                const SizedBox(height: 25),
                const Text(
                  'CUENTA EN REVISIÓN',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Espera, se está creando tu cuenta. Comunícate con el administrador para tener acceso al sistema SCADA MASTER.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: kText,
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 35),
                const CircularProgressIndicator(
                  color: kCyan,
                  strokeWidth: 3,
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _cerrarSesion(context),
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('VOLVER AL LOGIN'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white10,
                      foregroundColor: Colors.white70,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Colors.white12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
