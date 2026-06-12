import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class LLavesService {
  // Configuración por defecto (Backup en caso de que Firebase o el Internet fallen)
  static final List<String> _defaultGroqKeys = [
    "LLAVE_FALSA_1",
    "LLAVE_FALSA-1",
    "LLAVE_FALSA_1",
    "LLAVE_FALSA_1",
    "LLAVE_FALSA_1",
    "LLAVE_FALSA_1",
  ];

  /// Obtiene la configuración desde Firestore y retorna una llave aleatoria del pool.
  /// Colección: configuracion -> Documento: chatbot
  static Future<Map<String, dynamic>> getChatbotConfig() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('configuracion')
          .doc('chatbot')
          .get();

      if (doc.exists && doc.data() != null) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        List<dynamic> remoteKeys = data['api_keys'] ?? [];
        String provider = data['provider'] ?? 'groq';
        String model = data['model'] ?? 'llama-3.1-8b-instant'; // Excelente modelo por cierto

        if (remoteKeys.isNotEmpty) {
          // 🔥 MEJORA: Elegimos una llave al azar del pool de Firebase.
          // Así los 80 usuarios se distribuyen perfectamente y no saturan la misma llave.
          int randomIndex = Random().nextInt(remoteKeys.length);
          return {
            "key": remoteKeys[randomIndex],
            "provider": provider,
            "model": model,
          };
        }
      }
    } catch (e) {
      print("Error leyendo llaves desde Firestore: $e");
    }

    // 🛡️ MEJORA: Respaldo ultra seguro. Si la lista local está vacía, evita que la app truene.
    String backupKey = _defaultGroqKeys.isNotEmpty
        ? _defaultGroqKeys[Random().nextInt(_defaultGroqKeys.length)]
        : "SIN_LLAVE_LOCAL";

    return {
      "key": backupKey,
      "provider": "groq",
      "model": "llama-3.1-8b-instant",
    };
  }
}
