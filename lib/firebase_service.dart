import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class FirebaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> initializeMaqueta(String maquetaId) async {
    final docRef = _db.collection('maquetas').doc(maquetaId);
    final doc = await docRef.get();
    if (!doc.exists) {
      await docRef.set({
        'piezasProcesadas': 0,
        'parosEmergencia': 0,
        'ultimoReset': FieldValue.serverTimestamp(),
        'componentes': {},
      });
    }
  }

  Future<void> incrementarPiezas(String maquetaId) async {
    final docRef = _db.collection('maquetas').doc(maquetaId);
    await docRef.update({'piezasProcesadas': FieldValue.increment(1)});
  }

  Future<void> registrarAccionComponente(String maquetaId, String componenteId) async {
    final docRef = _db.collection('maquetas').doc(maquetaId);
    final field = 'componentes.$componenteId';
    await docRef.update({field: FieldValue.increment(1)});
  }

  Future<void> registrarParoEmergencia(String maquetaId) async {
    final docRef = _db.collection('maquetas').doc(maquetaId);
    await docRef.update({'parosEmergencia': FieldValue.increment(1)});
  }

  Future<void> guardarLog(String maquetaId, Map<String, dynamic> logData) async {
    final docRef = _db.collection('maquetas').doc(maquetaId).collection('auditoria');
    final now = DateTime.now().toUtc().toIso8601String();
    final randomSuffix = (Random().nextInt(900) + 100).toString();
    final docId = '$now-$randomSuffix';

    await docRef.doc(docId).set({
      'maqueta': maquetaId, // Añade el ID de la maqueta al log
      ...logData,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> registrarReset(String maquetaId) async {
    final docRef = _db.collection('maquetas').doc(maquetaId);
    await docRef.update({'ultimoReset': FieldValue.serverTimestamp()});
  }

  // Obtiene todos los logs de auditoría de todas las maquetas
  Future<List<Map<String, dynamic>>> getAuditLogs() async {
    // CORRECCIÓN: Se usa Source.cache en lugar de Source.cacheFirst
    final querySnapshot = await _db.collectionGroup('auditoria').orderBy('timestamp', descending: true).get(const GetOptions(source: Source.cache));

    return querySnapshot.docs.map((doc) => doc.data()).toList();
  }
}
