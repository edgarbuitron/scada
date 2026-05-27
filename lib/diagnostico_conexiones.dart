import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

// ─── Colores y Estilos (sin cambios) ───────────────────────────────────────
const kBg = Color(0xFF0D1321);
const kCard = Color(0xFF131D2E);
const kBorder = Color(0xFF1E2D45);
const kBlue = Color(0xFF3B82F6);
const kGreen = Color(0xFF22C55E);
const kRed = Color(0xFFEF4444);
const kText = Color(0xFFE2E8F0);
const kMuted = Color(0xFF64748B);
const kMuted2 = Color(0xFF8B9CBD);

// ─── Modelo de Datos Mejorado ───────────────────────────────────────────────
class Conexion {
  final String id;
  final String nombre;
  int paquetesEnviados;
  int paquetesRecibidos;
  int latencia;

  Conexion({
    required this.id,
    required this.nombre,
    this.paquetesEnviados = 0,
    this.paquetesRecibidos = 0,
    this.latencia = 0,
  });

  int get paquetesPerdidos => paquetesEnviados - paquetesRecibidos;
  double get porcentajePerdida => paquetesEnviados > 0 ? (paquetesPerdidos / paquetesEnviados) * 100 : 0;
  bool get isOffline => latencia < 0;

  // CORRECCIÓN: Se elimina el FieldValue para que sea compatible con jsonEncode
  Map<String, dynamic> toJson() => {
    'id': id,
    'nombre': nombre,
    'paquetesEnviados': paquetesEnviados,
    'paquetesRecibidos': paquetesRecibidos,
    'latencia': latencia,
  };

  static Conexion fromJson(Map<String, dynamic> json) => Conexion(
    id: json['id'],
    nombre: json['nombre'],
    paquetesEnviados: json['paquetesEnviados'] ?? 0,
    paquetesRecibidos: json['paquetesRecibidos'] ?? 0,
    latencia: json['latencia'] ?? 0,
  );
}

// ─── Pantalla de Diagnóstico (Stateful) ───────────────────────────────────
class DiagnosticoScreen extends StatefulWidget {
  const DiagnosticoScreen({super.key});

  @override
  State<DiagnosticoScreen> createState() => _DiagnosticoScreenState();
}

class _DiagnosticoScreenState extends State<DiagnosticoScreen> {
  Map<String, Conexion> _conexiones = {};
  bool _isLoading = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _initializeData();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _updateAndSyncData());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _initializeData() async {
    if (mounted) setState(() => _isLoading = true);
    final connectivityResult = await Connectivity().checkConnectivity();
    
    if (connectivityResult.contains(ConnectivityResult.none)) {
      await _loadFromLocal();
    } else {
      await _loadFromFirebase();
    }
    
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadFromFirebase() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance.collection('conexiones').get();
      if (querySnapshot.docs.isNotEmpty) {
        // CORRECCIÓN: Se especifica el tipo explícito para 'data' para evitar errores.
        final Map<String, Conexion> data = { 
          for (var doc in querySnapshot.docs) doc.id : Conexion.fromJson(doc.data())
        };
        if (mounted) {
          setState(() => _conexiones = data);
        }
        await _saveToLocal(data.values.toList());
      } else {
        _setupInitialData();
      }
    } catch (e) {
      await _loadFromLocal();
    }
  }

  Future<void> _loadFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final localDataString = prefs.getString('conexiones_data');
      if (localDataString != null) {
        final List<dynamic> localData = jsonDecode(localDataString);
        // CORRECCIÓN: Se especifica el tipo explícito y se hacen castings seguros.
        final Map<String, Conexion> data = { 
          for (var item in localData) 
            (item as Map<String, dynamic>)['id'] as String: 
            Conexion.fromJson(item as Map<String, dynamic>)
        };
        if (mounted) {
          setState(() => _conexiones = data);
        }
      } else {
        _setupInitialData();
      }
    } catch (e) {
      _setupInitialData(); // Si hay error al leer local, empezar de cero
    }
  }

  void _setupInitialData() {
    final initialData = {
      'neumatico': Conexion(id: 'neumatico', nombre: 'Centro Neumático'),
      'maquinados': Conexion(id: 'maquinados', nombre: 'Centro de Maquinados'),
      'robot': Conexion(id: 'robot', nombre: 'Robot 3 ejes'),
      'prensado': Conexion(id: 'prensado', nombre: 'Centro de Prensado'),
    };
    if (mounted) {
      setState(() => _conexiones = initialData);
    }
    _updateAndSyncData();
  }

  Future<void> _updateAndSyncData() async {
    final random = Random();
    if (mounted) {
      setState(() {
        _conexiones.forEach((key, con) {
          con.paquetesEnviados += random.nextInt(100) + 50;
          int paquetesPerdidos = (random.nextDouble() * 10).toInt();
          con.paquetesRecibidos = con.paquetesEnviados - paquetesPerdidos;
          con.latencia = (key == 'robot' || key == 'prensado') ? -1 : 10 + random.nextInt(15);
        });
      });
    }

    final connectionsList = _conexiones.values.toList();
    await _saveToLocal(connectionsList);

    final connectivityResult = await Connectivity().checkConnectivity();
    if (!connectivityResult.contains(ConnectivityResult.none)) {
      await _syncToFirebase(connectionsList);
    }
  }

  Future<void> _saveToLocal(List<Conexion> data) async {
    final prefs = await SharedPreferences.getInstance();
    final localData = data.map((c) => c.toJson()).toList();
    await prefs.setString('conexiones_data', jsonEncode(localData));
  }

  Future<void> _syncToFirebase(List<Conexion> data) async {
    final batch = FirebaseFirestore.instance.batch();
    for (var con in data) {
      final docRef = FirebaseFirestore.instance.collection('conexiones').doc(con.id);
      // CORRECCIÓN: Se añade el timestamp aquí, solo para Firebase.
      final firebaseData = con.toJson()..['timestamp'] = FieldValue.serverTimestamp();
      batch.set(docRef, firebaseData, SetOptions(merge: true));
    }
    try {
      await batch.commit();
    } catch (e) {
      // Manejar posible error al escribir en Firebase
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: kBg,
    body: SafeArea(
      child: _isLoading
          ? const Center(child: CircularProgressIndicator(color: kBlue))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _buildHeader(),
                  const SizedBox(height: 22),
                  _buildKpis(),
                  const SizedBox(height: 24),
                  _buildRendimiento(),
                ]),
            ),
    ),
  );

  Widget _buildHeader() => Row(children: const [ 
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [ 
          Text('Diagnóstico de conexiones', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: kText)),
          SizedBox(height: 3),
          Text('Monitorea el estado y rendimiento de todas las conexiones', style: TextStyle(fontSize: 13, color: kMuted2)),
        ]),
      ]);

  Widget _buildKpis() {
    int totalEnviados = _conexiones.values.fold(0, (sum, c) => sum + c.paquetesEnviados);
    int totalRecibidos = _conexiones.values.fold(0, (sum, c) => sum + c.paquetesRecibidos);
    int totalPerdidos = totalEnviados - totalRecibidos;
    double pctPerdida = totalEnviados > 0 ? (totalPerdidos / totalEnviados) * 100 : 0;

    return Row(children: [
      Expanded(child: _KpiCard(label: 'Paquetes enviados', value: totalEnviados.toString(), sub: 'total', valueColor: kText)),
      const SizedBox(width: 12),
      Expanded(child: _KpiCard(label: 'Paquetes recibidos', value: totalRecibidos.toString(), sub: 'total', valueColor: kText)),
      const SizedBox(width: 12),
      Expanded(child: _KpiCard(label: 'Paquetes perdidos', value: totalPerdidos.toString(), sub: '(${pctPerdida.toStringAsFixed(2)}%)', valueColor: kRed)),
      const SizedBox(width: 12),
      Expanded(child: _KpiCard(label: 'Dispositivos Offline', value: _conexiones.values.where((c) => c.isOffline).length.toString(), sub: 'actualmente', valueColor: kRed)),
    ]);
  }

  Widget _buildRendimiento() => Container(
    decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: kBorder)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Padding(
        padding: EdgeInsets.fromLTRB(18, 18, 18, 12),
        child: Text('Rendimiento de conexiones', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kText)),
      ),
      const Divider(height: 1, color: kBorder),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
        child: Row(children: const [
          Expanded(flex: 4, child: _TH('Maqueta')),
          Expanded(flex: 2, child: _TH('Enviados', right: true)),
          Expanded(flex: 2, child: _TH('Recibidos', right: true)),
          Expanded(flex: 2, child: _TH('Pérdida %', right: true)),
          Expanded(flex: 2, child: _TH('Latencia', right: true)),
        ]),
      ),
      const Divider(height: 1, color: kBorder),
      ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _conexiones.length,
        separatorBuilder: (_, __) => const Divider(height: 1, color: kBorder),
        itemBuilder: (_, i) {
          final con = _conexiones.values.toList()[i];
          final latColor = con.isOffline ? kMuted2 : kGreen;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: Row(children: [
              Expanded(flex: 4, child: Text(con.nombre, style: const TextStyle(fontSize: 13, color: kText))),
              Expanded(flex: 2, child: Text(con.paquetesEnviados.toString(), textAlign: TextAlign.right, style: const TextStyle(fontSize: 13, color: kMuted2))),
              Expanded(flex: 2, child: Text(con.paquetesRecibidos.toString(), textAlign: TextAlign.right, style: const TextStyle(fontSize: 13, color: kMuted2))),
              Expanded(flex: 2, child: Text('${con.porcentajePerdida.toStringAsFixed(2)}%', textAlign: TextAlign.right, style: const TextStyle(fontSize: 13, color: kMuted2))),
              Expanded(flex: 2, child: Text(con.isOffline ? '--' : '${con.latencia} ms', textAlign: TextAlign.right, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: latColor))),
            ]),
          );
        },
      ),
      const SizedBox(height: 6),
    ]),
  );
}

class _KpiCard extends StatelessWidget {
  final String label, value, sub;
  final Color valueColor;
  const _KpiCard({required this.label, required this.value, required this.sub, required this.valueColor});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: kBorder)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 12, color: kMuted2)),
      const SizedBox(height: 8),
      Text(value, style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: valueColor)),
      const SizedBox(height: 3),
      Text(sub, style: const TextStyle(fontSize: 12, color: kMuted)),
    ]),
  );
}

class _TH extends StatelessWidget {
  final String text;
  final bool right;
  const _TH(this.text, {this.right = false});
  @override
  Widget build(BuildContext context) => Text(text, textAlign: right ? TextAlign.right : TextAlign.left, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kMuted2));
}
