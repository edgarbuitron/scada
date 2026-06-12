import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'llaves.dart';

// --- Paleta de Colores HITECH ---
const Color kBg = Color(0xFF0D1117);
const Color kPanel = Color(0xFF161B22);
const Color kCyan = Color(0xFF38BDF8);
const Color kText = Color(0xFFE6EDF3);
const Color kTextSec = Color(0xFF8B949E);
const Color kMessageUser = Color(0xFF1F6FEB);
const Color kMessageBot = Color(0xFF21262D);

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime time;

  ChatMessage({required this.text, required this.isUser, required this.time});
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<ChatMessage> _messages = [
    ChatMessage(
      text: "Hola, soy el asistente inteligente de HITECH INGENIUM. Estoy conectado al Pool de Inteligencia Artificial para el sistema SCADA. ¿En qué puedo ayudarte?",
      isUser: false,
      time: DateTime.now(),
    ),
  ];

  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;

  Future<void> _handleSend() async {
    if (_controller.text.trim().isEmpty || _isTyping) return;

    final userMsg = _controller.text;
    setState(() {
      _messages.add(ChatMessage(
        text: userMsg,
        isUser: true,
        time: DateTime.now(),
      ));
      _controller.clear();
      _isTyping = true;
    });

    _scrollToBottom();

    try {
      // 1. Obtener contexto real de Firestore
      String contextData = await _fetchRealTimeContext();

      // 2. Obtener Llave Rotada y Configuración desde Firestore
      final config = await LLavesService.getChatbotConfig();
      final String apiKey = config['key'];
      final String provider = config['provider'];
      final String model = config['model'];

      // 3. Preparar el Prompt del Sistema
      String systemPrompt = """
Actúa como un experto en sistemas SCADA e Industria 4.0 para el laboratorio HITECH INGENIUM.
CONTEXTO ACTUAL DEL LABORATORIO:
$contextData

Instrucciones:
- Responde de forma técnica y profesional.
- Usa los datos de Firestore proporcionados arriba.
- Si no hay datos, indícalo educadamente.
- Maquetas: Neumático, Maquinados, Prensado y Robot.
""";

      // 4. Llamada al API (Groq u OpenRouter)
      String botResponse = await _callAIProvider(
        provider: provider,
        apiKey: apiKey,
        model: model,
        systemPrompt: systemPrompt,
        userMsg: userMsg,
      );

      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(
            text: botResponse,
            isUser: false,
            time: DateTime.now(),
          ));
          _isTyping = false;
        });
      }
    } catch (e) {
      _handleChatError(e);
    }
    _scrollToBottom();
  }

  Future<String> _callAIProvider({
    required String provider,
    required String apiKey,
    required String model,
    required String systemPrompt,
    required String userMsg,
  }) async {
    String url = provider == 'groq' 
        ? "https://api.groq.com/openai/v1/chat/completions"
        : "https://openrouter.ai/api/v1/chat/completions";

    final response = await http.post(
      Uri.parse(url),
      headers: {
        "Authorization": "Bearer $apiKey",
        "Content-Type": "application/json",
        if (provider == 'openrouter') "HTTP-Referer": "https://hitech-ingenium.com", // Requerido por OpenRouter
      },
      body: jsonEncode({
        "model": model,
        "messages": [
          {"role": "system", "content": systemPrompt},
          {"role": "user", "content": userMsg}
        ],
        "temperature": 0.7,
        "max_tokens": 1024,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return data['choices'][0]['message']['content'];
    } else {
      throw "Error ${response.statusCode}: ${response.body}";
    }
  }

  void _handleChatError(dynamic e) {
    debugPrint("Chatbot Error: $e");
    String errorMsg = "Lo siento, el sistema está experimentando alta demanda. Reintentando con una nueva llave del pool...";
    
    if (e.toString().contains("401")) errorMsg = "Error de autorización en el pool de llaves.";
    if (e.toString().contains("429")) errorMsg = "Límite de tráfico alcanzado. Por favor, espera un momento.";

    if (mounted) {
      setState(() {
        _messages.add(ChatMessage(
          text: "Detección de Sistema: $errorMsg\n\n(Detalle técnico: $e)",
          isUser: false,
          time: DateTime.now(),
        ));
        _isTyping = false;
      });
    }
  }

  Future<String> _fetchRealTimeContext() async {
    try {
      // 1. Obtener Historial de Eventos
      final historialSnapshot = await FirebaseFirestore.instance
          .collection('historial')
          .orderBy('timestamp', descending: true)
          .limit(8)
          .get();

      String logs = "--- ÚLTIMOS EVENTOS ---\n";
      if (historialSnapshot.docs.isEmpty) {
        logs += "No hay procesos recientes registrados.\n";
      } else {
        for (var doc in historialSnapshot.docs) {
          final data = doc.data();
          final timestamp = data['timestamp'] as Timestamp?;
          final timeStr = timestamp != null ? timestamp.toDate().toString().split('.')[0] : 'N/A';
          logs += "- [$timeStr] Maqueta: ${data['maqueta']}, Evento: ${data['message']}, Tipo: ${data['type']}\n";
        }
      }

      // 2. Obtener Usuarios en Línea
      final usuariosSnapshot = await FirebaseFirestore.instance
          .collection('usuarios')
          .where('enLinea', isEqualTo: true)
          .get();

      logs += "\n--- ESTADO DE USUARIOS ---\n";
      logs += "Usuarios activos actualmente: ${usuariosSnapshot.docs.length}\n";
      if (usuariosSnapshot.docs.isNotEmpty) {
        logs += "Nombres: ${usuariosSnapshot.docs.map((d) => d.data()['nombre'] ?? 'N/A').join(', ')}\n";
      }

      // 3. Obtener Configuración General
      final configSnapshot = await FirebaseFirestore.instance
          .collection('configuracion')
          .get();

      logs += "\n--- CONFIGURACIÓN DEL SISTEMA ---\n";
      if (configSnapshot.docs.isEmpty) {
        logs += "Sin datos de configuración global.\n";
      } else {
        for (var doc in configSnapshot.docs) {
          logs += "- Documento ${doc.id}: ${doc.data()}\n";
        }
      }

      return logs;
    } catch (e) {
      debugPrint("Firestore Context Error: $e");
      return "Error al recuperar contexto extendido de Firebase.";
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) => _buildMessageBubble(_messages[index]),
            ),
          ),
          if (_isTyping)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: LinearProgressIndicator(color: kCyan, backgroundColor: kBg),
            ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: kPanel,
        border: Border(bottom: BorderSide(color: Color(0xFF30363D))),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: kMessageUser,
            child: Icon(Icons.hub_outlined, color: Colors.white),
          ),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "HITECH AI - Load Balancer",
                style: TextStyle(color: kText, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Row(
                children: const [
                  Icon(Icons.security, color: Colors.green, size: 12),
                  SizedBox(width: 5),
                  Text(
                    "Pool de Llaves Activo · Multi-Provider",
                    style: TextStyle(color: kCyan, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    return Align(
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
        decoration: BoxDecoration(
          color: msg.isUser ? kMessageUser : kMessageBot,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(msg.isUser ? 16 : 0),
            bottomRight: Radius.circular(msg.isUser ? 0 : 16),
          ),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              msg.text,
              style: const TextStyle(color: kText, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              "${msg.time.hour}:${msg.time.minute.toString().padLeft(2, '0')}",
              style: const TextStyle(color: Colors.white38, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: kPanel,
        border: Border(top: BorderSide(color: Color(0xFF30363D))),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              style: const TextStyle(color: kText),
              onSubmitted: (_) => _handleSend(),
              decoration: InputDecoration(
                hintText: "Pregunta al sistema industrial...",
                hintStyle: const TextStyle(color: kTextSec, fontSize: 14),
                filled: true,
                fillColor: kBg,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          CircleAvatar(
            backgroundColor: _isTyping ? kTextSec : kCyan,
            child: IconButton(
              icon: Icon(_isTyping ? Icons.hourglass_empty_rounded : Icons.send_rounded, color: Colors.black, size: 20),
              onPressed: _isTyping ? null : _handleSend,
            ),
          ),
        ],
      ),
    );
  }
}
