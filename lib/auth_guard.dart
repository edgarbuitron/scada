import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login.dart';
import 'home.dart'; // Asegúrate de que ScadaMasterHome está en home.dart

class AuthGuard extends StatefulWidget {
  const AuthGuard({super.key});

  @override
  State<AuthGuard> createState() => _AuthGuardState();
}

class _AuthGuardState extends State<AuthGuard> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    // Un pequeño delay para evitar saltos visuales bruscos
    await Future.delayed(const Duration(milliseconds: 200)); 

    final prefs = await SharedPreferences.getInstance();
    final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    if (mounted) {
      if (isLoggedIn) {
        // Si está logueado, reemplaza la pantalla actual con el Home
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        // Si no, reemplaza la pantalla actual con el Login
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Muestra un indicador de carga mientras se verifica el estado de la sesión
    return const Scaffold(
      backgroundColor: Color(0xFF0F172A),
      body: Center(
        child: CircularProgressIndicator(color: Color(0xFF38BDF8)),
      ),
    );
  }
}
