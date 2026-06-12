import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class UsageMonitor with ChangeNotifier {
  static final UsageMonitor _instance = UsageMonitor._internal();
  factory UsageMonitor() => _instance;
  UsageMonitor._internal() {
    _initPendingUsersListener();
  }

  // Tiempos de operación
  final Map<String, Duration> _stationTimes = {
    'general': Duration.zero,
    'neumatico': Duration.zero,
    'maquinados': Duration.zero,
    'robot': Duration.zero,
    'prensado': Duration.zero,
  };

  // Producción (Piezas terminadas)
  final Map<String, int> _stationProduction = {
    'general': 0,
    'neumatico': 0,
    'maquinados': 0,
    'robot': 0,
    'prensado': 0,
  };

  // Fallas (Paros de emergencia)
  final Map<String, int> _stationFailures = {
    'general': 0,
    'neumatico': 0,
    'maquinados': 0,
    'robot': 0,
    'prensado': 0,
  };

  // Consumo Energético
  final Map<String, double> _stationConsumption = {
    'general': 0.0,
    'neumatico': 0.0,
    'maquinados': 0.0,
    'robot': 0.0,
    'prensado': 0.0,
  };

  // ESTADO DE PROCESAMIENTO (Persistente al navegar)
  final Map<String, bool> _isActive = {
    'general': false,
    'neumatico': false,
    'maquinados': false,
    'robot': false,
    'prensado': false,
  };

  // Almacenamiento de progreso de piezas por estación
  final Map<String, int> _cycleFinishedPieces = {
    'general': 0,
    'neumatico': 0,
    'maquinados': 0,
    'robot': 0,
    'prensado': 0,
  };

  // NUEVO: Conteo de interacciones por componente (Sensor/Actuador)
  final Map<String, Map<String, int>> _componentInteractions = {
    'general': {},
    'neumatico': {},
    'maquinados': {},
    'robot': {},
    'prensado': {},
  };

  // NUEVO: Conteo de usuarios pendientes
  int _pendingUsersCount = 0;
  int get pendingUsersCount => _pendingUsersCount;

  Timer? _ticker;
  Timer? _consumptionTimer;
  StreamSubscription? _pendingUsersSub;

  void _initPendingUsersListener() {
    _pendingUsersSub?.cancel();
    _pendingUsersSub = FirebaseFirestore.instance
        .collection('usuarios')
        .where('rol', isEqualTo: 'Pendiente')
        .snapshots()
        .listen((snapshot) {
      _pendingUsersCount = snapshot.docs.length;
      notifyListeners();
    });
  }

  // NUEVO: Registro de auditoría centralizado con Identidad de Usuario
  Future<void> logEvent({
    required String maqueta,
    required String message,
    required String role,
    required String type, // informatico, ejecucion, terminado, critico
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String userName = prefs.getString('userName') ?? 'Usuario Desconocido';
      
      await FirebaseFirestore.instance.collection('historial').add({
        'timestamp': FieldValue.serverTimestamp(),
        'maqueta': maqueta,
        'message': message,
        'role': role,
        'userName': userName, // Guardamos el nombre real
        'type': type,
      });
    } catch (e) {
      debugPrint("Error al guardar log: $e");
    }
  }

  void startTracking() {
    _ticker ??= Timer.periodic(const Duration(seconds: 1), (timer) {
      bool changed = false;
      _isActive.forEach((station, active) {
        if (active) {
          _stationTimes[station] = _stationTimes[station]! + const Duration(seconds: 1);
          changed = true;
        }
      });
      if (changed) notifyListeners();
    });

    _consumptionTimer ??= Timer.periodic(const Duration(seconds: 10), (timer) {
      bool changed = false;
      _isActive.forEach((station, active) {
        if (active) {
          _stationConsumption[station] = _stationConsumption[station]! + 0.05;
          changed = true;
        }
      });
      if (changed) notifyListeners();
    });
  }

  // Setters de estado global
  void setStationActive(String stationId, bool active) {
    if (_isActive.containsKey(stationId)) {
      _isActive[stationId] = active;
      notifyListeners();
    }
  }

  bool isStationActive(String stationId) => _isActive[stationId] ?? false;

  void addProduction(String stationId) {
    if (_stationProduction.containsKey(stationId)) {
      _stationProduction[stationId] = _stationProduction[stationId]! + 1;
      _cycleFinishedPieces[stationId] = _cycleFinishedPieces[stationId]! + 1;
      notifyListeners();
      syncStationAuditoria(stationId); // Sincronizar inmediatamente al producir
    }
  }

  void addFailure(String stationId) {
    if (_stationFailures.containsKey(stationId)) {
      _stationFailures[stationId] = _stationFailures[stationId]! + 1;
      notifyListeners();
      syncStationAuditoria(stationId); // Sincronizar inmediatamente al fallar
    }
  }

  // NUEVO: Incrementar interacción con componente específico
  void incrementComponentInteraction(String stationId, String type, String componentId) {
    if (_componentInteractions.containsKey(stationId)) {
      final key = "${type}_$componentId"; // Ej: sensor_P1 o actuador_M1
      _componentInteractions[stationId]![key] = (_componentInteractions[stationId]![key] ?? 0) + 1;
      notifyListeners();
      syncStationAuditoria(stationId); // Sincronizar al interactuar manualmente
    }
  }

  // NUEVO: Sincronizar datos agregados a Firestore (maquetas > station > auditoria > timestamp)
  Future<void> syncStationAuditoria(String stationId) async {
    if (!_componentInteractions.containsKey(stationId)) return;

    try {
      final String timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      
      await FirebaseFirestore.instance
          .collection('maquetas')
          .doc(stationId)
          .collection('auditoria')
          .doc(timestamp)
          .set({
        'componentes': _componentInteractions[stationId],
        'parosEmergencia': _stationFailures[stationId] ?? 0,
        'piezasProcesadas': _stationProduction[stationId] ?? 0,
        'ultimoReset': DateFormat('dd/MM/yyyy HH:mm:ss').format(DateTime.now()),
      });
    } catch (e) {
      debugPrint("Error al sincronizar auditoría de maqueta: $e");
    }
  }

  void resetCyclePieces(String stationId) {
    if (_cycleFinishedPieces.containsKey(stationId)) {
      _cycleFinishedPieces[stationId] = 0;
      notifyListeners();
    }
  }

  int getCycleFinishedPieces(String stationId) => _cycleFinishedPieces[stationId] ?? 0;

  // Getters para UI
  Duration getStationTime(String stationId) => _stationTimes[stationId] ?? Duration.zero;
  int getStationProduction(String stationId) => _stationProduction[stationId] ?? 0;
  int getStationFailures(String stationId) => _stationFailures[stationId] ?? 0;
  double getStationConsumption(String stationId) => _stationConsumption[stationId] ?? 0.0;

  // Totales
  Duration get totalTime => _stationTimes.values.reduce((a, b) => a + b);
  int get totalProduction => _stationProduction.values.reduce((a, b) => a + b);
  int get totalFailures => _stationFailures.values.reduce((a, b) => a + b);
  double get totalConsumption => _stationConsumption.values.reduce((a, b) => a + b);

  String formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(d.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(d.inSeconds.remainder(60));
    return "${twoDigits(d.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  void dispose() {
    _pendingUsersSub?.cancel();
    _ticker?.cancel();
    _consumptionTimer?.cancel();
    super.dispose();
  }
}
