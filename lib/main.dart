import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'auth_guard.dart';
import 'login.dart';
import 'home.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // Habilitar persistencia offline para toda la app
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );
  runApp(const MyApp());
}

const Color kBgDark = Color(0xFF0F172A);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SCADA 4.0 · Hitech INGENIUM',
      theme: ThemeData.dark().copyWith(scaffoldBackgroundColor: kBgDark),
      // AuthGuard decide qué pantalla mostrar al inicio
      home: const AuthGuard(), 
      // Las rutas se mantienen para la navegación nombrada
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const ScadaMasterHome(),
      },
    );
  }
}
