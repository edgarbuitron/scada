import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

import 'firebase_options.dart';
import 'auth_guard.dart';
import 'login.dart';
import 'home.dart';
import 'espera.dart';
import 'formulario.dart';
import 'usage_monitor.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configuración de ventana para Windows/Desktop
  if (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
    await windowManager.ensureInitialized();
    WindowOptions windowOptions = const WindowOptions(
      size: Size(1280, 800),
      minimumSize: Size(1100, 750), // Límite máximo de pequeñez para evitar rupturas
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
      title: 'SCADA 4.0 · HITECH INGENIUM',
    );
    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  try {
    // Inicializar Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Habilitar persistencia de datos local para modo offline
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );

    // RESTAURACIÓN DE ADMINISTRADOR (Script de emergencia)
    _createAdminIfNotExist();
  } catch (e) {
    debugPrint("Firebase init error: $e");
  }

  // Inicializar el monitor de uso global
  final usageMonitor = UsageMonitor();
  usageMonitor.startTracking();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: usageMonitor),
      ],
      child: const MyApp(),
    ),
  );
}

Future<void> _createAdminIfNotExist() async {
  try {
    const adminEmail = 'admin@huetamo.tecnm.mx';
    final query = await FirebaseFirestore.instance
        .collection('usuarios')
        .where('correo', isEqualTo: adminEmail)
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      await FirebaseFirestore.instance.collection('usuarios').add({
        'nombre': 'Administrador Master',
        'correo': adminEmail,
        'passwordHash': 'Admin2024*',
        'rol': 'Administrador',
        'matricula': 'ADM-001',
        'carrera': 'Sistemas Computacionales',
        'semestre': '9',
        'estado': 'Activo',
        'perfilCompleto': true,
        'encuestaCompletada': true,
        'enLinea': false,
        'fechaRegistro': DateTime.now().toIso8601String(),
        'ultimoAcceso': '',
      });
      debugPrint("✅ Usuario Administrador de emergencia creado con éxito.");
    }
  } catch (e) {
    debugPrint("❌ Error al crear administrador de emergencia: $e");
  }
}

const Color kBgDark = Color(0xFF0F172A);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SCADA 4.0 · Hitech INGENIUM',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: kBgDark,
      ),

      // Pantalla inicial
      home: const LoginScreen(),

      // Rutas
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const ScadaMasterHome(),
        '/espera': (context) => const EsperaScreen(),
        '/formulario': (context) => const FormularioAlumnoScreen(),
        '/encuesta': (context) => const EncuestaScadaScreen(),
      },
    );
  }
}
