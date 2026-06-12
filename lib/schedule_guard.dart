import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class ScheduleGuard {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Verifica si el usuario actual tiene permiso de CONEXIÓN en este momento exacto.
  static Future<bool> canConnectToHardware() async {
    final prefs = await SharedPreferences.getInstance();
    final String? email = prefs.getString('userEmail');
    final String? rol = prefs.getString('userRole');

    if (email == null) return false;

    // 1. Los Administradores siempre tienen acceso total al hardware
    if (rol == 'Administrador') return true;

    try {
      // 2. Obtener el ID del usuario actual
      final userQuery = await _firestore
          .collection('usuarios')
          .where('correo', isEqualTo: email)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) return false;
      final String userId = userQuery.docs.first.id;

      // 3. Buscar horarios que incluyan a este usuario específico o a su grupo/semestre
      final now = DateTime.now();
      final String dayKey = _getDayKey(now.weekday); // lunes, martes...
      final int hourIndex = _getHourIndex(now.hour); // 0-7 para 7:00-15:00

      if (hourIndex == -1) return false; // Fuera del rango 7 AM - 3 PM

      final schedulesQuery = await _firestore
          .collection('horarios')
          .where('userIds', arrayContains: userId)
          .get();

      if (schedulesQuery.docs.isNotEmpty) {
        for (var doc in schedulesQuery.docs) {
          final data = doc.data();
          final Map<String, dynamic> matrix = data['matriz'] ?? {};
          // El formato en Firestore es "hourIndex-dayIndex" (ej: "0-0" para Lunes 7:00)
          final String cellKey = '$hourIndex-${now.weekday - 1}';
          if (matrix[cellKey] == true) return true;
        }
      }

      // 4. Si no hay horario específico, buscamos por Rol/Semestre/Grupo (para Alumnos)
      if (rol == 'Alumno') {
        final userData = userQuery.docs.first.data();
        final int semestre = userData['semestre'] ?? 0;
        final String grupo = userData['grupo'] ?? '';

        final genericSchedules = await _firestore
            .collection('horarios')
            .where('rol', isEqualTo: 'Alumno')
            .where('semestre', isEqualTo: semestre)
            .where('grupo', isEqualTo: grupo)
            .get();

        for (var doc in genericSchedules.docs) {
          final data = doc.data();
          final Map<String, dynamic> matrix = data['matriz'] ?? {};
          final String cellKey = '$hourIndex-${now.weekday - 1}';
          if (matrix[cellKey] == true) return true;
        }
      }

      return false; // No se encontró ningún bloque activo
    } catch (e) {
      print('Error in ScheduleGuard: $e');
      return false;
    }
  }

  static String _getDayKey(int weekday) {
    switch (weekday) {
      case 1: return 'lunes';
      case 2: return 'martes';
      case 3: return 'miercoles';
      case 4: return 'jueves';
      case 5: return 'viernes';
      default: return 'fuera';
    }
  }

  static int _getHourIndex(int hour) {
    if (hour < 7 || hour >= 15) return -1;
    return hour - 7; // 7 AM -> index 0, 14 PM -> index 7
  }
}
