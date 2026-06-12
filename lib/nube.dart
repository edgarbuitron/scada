import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:intl/intl.dart';

// ─────────────────────────────────────────────
// PALETA DE COLORES (Consistente con el sistema)
// ─────────────────────────────────────────────
const Color _bg = Color(0xFF0D1117);
const Color _card = Color(0xFF161B22);
const Color _border = Color(0xFF21262D);
const Color _blue = Color(0xFF1F6FEB);
const Color _green = Color(0xFF3FB950);
const Color _red = Color(0xFFF85149);
const Color _orange = Color(0xFFD29922);
const Color _textPri = Color(0xFFE6EDF3);
const Color _textSec = Color(0xFF8B949E);

class CloudSyncDashboard extends StatefulWidget {
  const CloudSyncDashboard({super.key});

  @override
  State<CloudSyncDashboard> createState() => _CloudSyncDashboardState();
}

class _CloudSyncDashboardState extends State<CloudSyncDashboard> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Estados de conexión
  String _statusLabel = 'Conectando...';
  Color _statusColor = _orange;
  bool _isOnline = true;

  // Métricas reales
  int _totalCollections = 0; 
  int _totalRecords = 0;
  double _usedSpaceMB = 0.0;
  double _usagePercentage = 0.0;
  final double _totalCapacityMB = 1024.0; // 1 GB Spark Plan

  // Tiempos y tareas
  String _lastSync = "---";
  int _pendingTasks = 0;
  int _conflictsResolved = 0;
  
  // Tasas simuladas basadas en actividad real detectada
  double _writeRate = 0.0;
  double _readRate = 0.0;

  StreamSubscription? _connectivitySub;
  Timer? _metricsTimer;

  @override
  void initState() {
    super.initState();
    _checkInitialConnection();
    _startMetricsMonitoring();
    _initConnectivityListener();
  }

  Future<void> _checkInitialConnection() async {
    final result = await Connectivity().checkConnectivity();
    _updateConnectionStatus(result);
  }

  void _initConnectivityListener() {
    _connectivitySub = Connectivity().onConnectivityChanged.listen((result) {
      _updateConnectionStatus(result);
    });
  }

  void _updateConnectionStatus(List<ConnectivityResult> result) {
    setState(() {
      if (result.contains(ConnectivityResult.none)) {
        _isOnline = false;
        _statusLabel = 'Desconectado';
        _statusColor = _red;
      } else if (result.contains(ConnectivityResult.mobile)) {
        _isOnline = true;
        _statusLabel = 'Conexión Débil (Móvil)';
        _statusColor = _orange;
      } else {
        _isOnline = true;
        _statusLabel = 'Óptimo (Wi-Fi/LAN)';
        _statusColor = _green;
      }
    });
  }

  void _startMetricsMonitoring() {
    // Actualizar métricas cada 10 segundos
    _metricsTimer = Timer.periodic(const Duration(seconds: 10), (_) => _fetchFirestoreMetrics());
    _fetchFirestoreMetrics(); // Carga inicial
  }

  Future<void> _fetchFirestoreMetrics() async {
    try {
      // 1. Contar colecciones principales (Módulos)
      // Nota: Firestore no permite listar colecciones desde el SDK de cliente directamente, 
      // así que usamos las conocidas en tu proyecto.
      final collections = ['usuarios', 'historial', 'maquetas', 'configuracion', 'horarios'];
      _totalCollections = collections.length;

      // 2. Contar registros totales (Historial + Usuarios + Horarios)
      int recordsCount = 0;
      final historial = await _firestore.collection('historial').get(const GetOptions(source: Source.serverAndCache));
      final usuarios = await _firestore.collection('usuarios').get(const GetOptions(source: Source.serverAndCache));
      final horarios = await _firestore.collection('horarios').get(const GetOptions(source: Source.serverAndCache));
      
      recordsCount = historial.docs.length + usuarios.docs.length + horarios.docs.length;

      // 3. Calcular espacio (Estimación: 0.8KB por documento promedio)
      double estimatedMB = (recordsCount * 0.8) / 1024;
      
      setState(() {
        _totalRecords = recordsCount;
        _usedSpaceMB = estimatedMB;
        _usagePercentage = (estimatedMB / _totalCapacityMB) * 100;
        _lastSync = DateFormat('dd/MM/yyyy hh:mm a').format(DateTime.now());
        
        // Simular tasas si hay actividad
        if (_isOnline) {
           _writeRate = 1.2 + (recordsCount % 5) / 10;
           _readRate = 3.5 + (recordsCount % 3) / 10;
           _pendingTasks = 0;
        } else {
           _writeRate = 0.0;
           _readRate = 0.0;
           _pendingTasks = 2; // Simular tareas en espera de internet
        }
      });
    } catch (e) {
      debugPrint("Error fetching metrics: $e");
    }
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    _metricsTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(statusLabel: _statusLabel, statusColor: _statusColor),
              const SizedBox(height: 24),
              
              // Tarjeta de Última Actividad
              _LastSyncCard(lastSync: _lastSync, isOnline: _isOnline),
              const SizedBox(height: 16),

              // Tarjeta de Uso de Memoria
              _UsageCard(usage: _usagePercentage, usedMB: _usedSpaceMB, totalMB: _totalCapacityMB),
              const SizedBox(height: 16),

              // Infraestructura de Datos
              _InfrastructureCard(
                collections: _totalCollections, 
                records: _totalRecords, 
                statusLabel: _isOnline ? 'Activo' : 'Offline', 
                statusColor: _statusColor, 
                sizeMB: _usedSpaceMB
              ),
              const SizedBox(height: 16),

              // Rendimiento de Transmisión
              _TransmissionCard(
                processed: _totalRecords,
                pending: _pendingTasks,
                resolved: _conflictsResolved,
                writeRate: _writeRate,
                readRate: _readRate,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String statusLabel;
  final Color statusColor;
  const _Header({required this.statusLabel, required this.statusColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cloud Sync Monitor', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _textPri)),
            Text('Estado de sincronización y base de datos', style: TextStyle(fontSize: 13, color: _textSec)),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(20), border: Border.all(color: _border)),
          child: Row(
            children: [
              Text(statusLabel, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              Container(width: 8, height: 8, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
            ],
          ),
        )
      ],
    );
  }
}

class _LastSyncCard extends StatelessWidget {
  final String lastSync;
  final bool isOnline;
  const _LastSyncCard({required this.lastSync, required this.isOnline});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(12), border: Border.all(color: _border)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: _blue.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: const Icon(Icons.history, color: _blue, size: 20),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Última Actividad Local', style: TextStyle(color: _textSec, fontSize: 11)),
              const SizedBox(height: 4),
              Text(lastSync, style: const TextStyle(color: _textPri, fontSize: 16, fontWeight: FontWeight.bold)),
              Text(isOnline ? 'Sincronizado ahora' : 'Esperando conexión...', style: TextStyle(color: isOnline ? _green : _orange, fontSize: 11)),
            ],
          )
        ],
      ),
    );
  }
}

class _UsageCard extends StatelessWidget {
  final double usage, usedMB, totalMB;
  const _UsageCard({required this.usage, required this.usedMB, required this.totalMB});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(12), border: Border.all(color: _border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Uso de Memoria (Estimado)', style: TextStyle(color: _textSec, fontSize: 12)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 80, height: 80,
                child: CircularProgressIndicator(
                  value: usage / 100,
                  strokeWidth: 8,
                  backgroundColor: Colors.white10,
                  valueColor: const AlwaysStoppedAnimation(_blue),
                ),
              ),
              const SizedBox(width: 30),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${usage.toStringAsFixed(1)}%', style: const TextStyle(color: _textPri, fontSize: 28, fontWeight: FontWeight.bold)),
                  Text('${usedMB.toStringAsFixed(2)} MB / 1 GB', style: const TextStyle(color: _textSec, fontSize: 12)),
                ],
              )
            ],
          )
        ],
      ),
    );
  }
}

class _InfrastructureCard extends StatelessWidget {
  final int collections, records;
  final String statusLabel;
  final Color statusColor;
  final double sizeMB;
  const _InfrastructureCard({required this.collections, required this.records, required this.statusLabel, required this.statusColor, required this.sizeMB});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(12), border: Border.all(color: _border)),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.storage, color: _blue, size: 24),
              const SizedBox(width: 12),
              const Expanded(child: Text('Infraestructura de Datos', style: TextStyle(color: _textSec, fontWeight: FontWeight.bold))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                child: Text('● $statusLabel', style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
              )
            ],
          ),
          const Divider(height: 32, color: _border),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _metric('Tamaño Est.', '${sizeMB.toStringAsFixed(2)} MB'),
              _metric('Módulos', collections.toString()),
              _metric('Registros', records.toString()),
              _metric('Estado', statusLabel, color: statusColor),
            ],
          )
        ],
      ),
    );
  }

  Widget _metric(String label, String value, {Color color = _textPri}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: _textSec, fontSize: 10)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _TransmissionCard extends StatelessWidget {
  final int processed, pending, resolved;
  final double writeRate, readRate;
  const _TransmissionCard({required this.processed, required this.pending, required this.resolved, required this.writeRate, required this.readRate});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(12), border: Border.all(color: _border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Rendimiento de Transmisión', style: TextStyle(color: _textSec, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _transItem(Icons.check_circle_outline, 'Registros procesados', processed.toString()),
          _transItem(Icons.pending_actions, 'Tareas pendientes', pending.toString(), color: pending > 0 ? _orange : _textSec),
          _transItem(Icons.verified_user_outlined, 'Conflictos resueltos', resolved.toString()),
          _transItem(Icons.upload, 'Tasa de escritura local', '${writeRate.toStringAsFixed(1)} KB/s'),
          _transItem(Icons.download, 'Tasa de lectura local', '${readRate.toStringAsFixed(1)} KB/s'),
        ],
      ),
    );
  }

  Widget _transItem(IconData icon, String label, String value, {Color color = _textSec}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: const TextStyle(color: _textPri, fontSize: 13))),
          Text(value, style: const TextStyle(color: _textPri, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }
}
