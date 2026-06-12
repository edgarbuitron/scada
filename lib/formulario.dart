import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

// =============================================================================
// FORMULARIO 1: DATOS ACADÉMICOS (SOLO PARA ALUMNOS)
// =============================================================================
class FormularioAlumnoScreen extends StatefulWidget {
  const FormularioAlumnoScreen({super.key});

  @override
  State<FormularioAlumnoScreen> createState() => _FormularioAlumnoScreenState();
}

class _FormularioAlumnoScreenState extends State<FormularioAlumnoScreen> {
  final _controlController = TextEditingController();
  String? _selectedSemestre;
  String? _selectedGrupo;
  bool _isSaving = false;

  final Color kBg = const Color(0xFF081014);
  final Color kPanel = const Color(0xFF11222C);
  final Color kCyan = const Color(0xFF00EAFF);
  final Color kText = const Color(0xFFC5D1D8);

  bool get _isFormValid =>
      _controlController.text.length == 8 &&
      _selectedSemestre != null &&
      _selectedGrupo != null;

  Future<void> _guardarDatos() async {
    if (!_isFormValid) return;

    setState(() => _isSaving = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? email = prefs.getString('userEmail');

      if (email != null) {
        final query = await FirebaseFirestore.instance
            .collection('usuarios')
            .where('correo', isEqualTo: email)
            .limit(1)
            .get();

        if (query.docs.isNotEmpty) {
          await query.docs.first.reference.update({
            'numeroControl': _controlController.text,
            'semestre': int.parse(_selectedSemestre!),
            'grupo': _selectedGrupo,
            'perfilCompleto': true,
          });

          if (mounted) {
            // Después de datos académicos, enviamos a la encuesta
            Navigator.pushReplacementNamed(context, '/encuesta');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar datos: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(25),
          child: Container(
            width: 420,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: kPanel,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: kCyan.withValues(alpha: .3)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.assignment_ind_rounded, size: 70, color: kCyan),
                const SizedBox(height: 20),
                const Text(
                  'DATOS ACADÉMICOS',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.2),
                ),
                const SizedBox(height: 10),
                Text(
                  'Paso 1 de 2: Completa tu perfil de alumno.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: kText, fontSize: 14),
                ),
                const SizedBox(height: 30),
                
                TextField(
                  controller: _controlController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(8),
                  ],
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('Número de Control (8 dígitos)', Icons.badge),
                ),
                const SizedBox(height: 15),

                DropdownButtonFormField<String>(
                  value: _selectedSemestre,
                  dropdownColor: kPanel,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('Seleccionar Semestre', Icons.school),
                  items: List.generate(12, (i) => (i + 1).toString())
                      .map((s) => DropdownMenuItem(value: s, child: Text('Semestre $s')))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedSemestre = v),
                ),
                const SizedBox(height: 15),

                DropdownButtonFormField<String>(
                  value: _selectedGrupo,
                  dropdownColor: kPanel,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('Seleccionar Grupo', Icons.group_work),
                  items: const [
                    DropdownMenuItem(value: 'Grupo A', child: Text('Grupo A')),
                    DropdownMenuItem(value: 'Grupo B', child: Text('Grupo B')),
                  ],
                  onChanged: (v) => setState(() => _selectedGrupo = v),
                ),
                const SizedBox(height: 35),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (_isFormValid && !_isSaving) ? _guardarDatos : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kCyan,
                      foregroundColor: Colors.black,
                      disabledBackgroundColor: Colors.white10,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _isSaving 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                      : const Text('CONTINUAR A LA ENCUESTA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
      prefixIcon: Icon(icon, color: kCyan, size: 20),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.05),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: kCyan, width: 1)),
    );
  }
}

// =============================================================================
// FORMULARIO 2: ENCUESTA DE DIAGNÓSTICO (PARA TODOS LOS ROLES)
// =============================================================================
class EncuestaScadaScreen extends StatefulWidget {
  const EncuestaScadaScreen({super.key});

  @override
  State<EncuestaScadaScreen> createState() => _EncuestaScadaScreenState();
}

class _EncuestaScadaScreenState extends State<EncuestaScadaScreen> {
  final Map<int, String?> _respuestas = {};
  bool _isSaving = false;

  final Color kBg = const Color(0xFF081014);
  final Color kPanel = const Color(0xFF11222C);
  final Color kCyan = const Color(0xFF00EAFF);
  final Color kText = const Color(0xFFC5D1D8);

  final List<Map<String, dynamic>> _preguntas = [
    {
      'id': 1,
      'pregunta': '¿Cuál es tu nivel de experiencia utilizando Sistemas SCADA en entornos industriales o académicos?',
      'opciones': [
        'Soy nuevo/a en esto (Primera vez).',
        'Conozco la teoría, pero nunca he operado uno.',
        'He utilizado sistemas básicos o académicos.',
        'Tengo experiencia avanzada / industrial.'
      ]
    },
    {
      'id': 2,
      'pregunta': '¿Qué plataformas comerciales o industriales de SCADA/PLC conoces o has utilizado?',
      'opciones': [
        'Siemens (TIA Portal, WinCC)',
        'Allen-Bradley / Rockwell (FactoryTalk)',
        'Ignition',
        'LabVIEW',
        'Ninguna de las anteriores / Otro'
      ]
    },
    {
      'id': 3,
      'pregunta': '¿Cuál crees que es el valor más importante de un sistema SCADA en la Industria 4.0?',
      'opciones': [
        'Monitorear datos en tiempo real.',
        'Controlar maquinaria a distancia.',
        'Generar un historial (logs) para mantenimiento preventivo.',
        'Todas las anteriores.'
      ]
    },
    {
      'id': 4,
      'pregunta': '¿Has operado previamente las maquetas físicas de este laboratorio?',
      'opciones': ['Sí', 'No']
    },
    {
      'id': 5,
      'pregunta': '¿Qué es lo que más te interesa aprender o utilizar en esta aplicación?',
      'opciones': [
        'Visualización de datos y Dashboards.',
        'Control manual de actuadores y relés.',
        'Análisis de reportes e Inteligencia Artificial.'
      ]
    },
    {
      'id': 6,
      'pregunta': '¿Con qué tipo de hardware o controladores estás más familiarizado?',
      'opciones': [
        'Microcontroladores (ESP32, Arduino)',
        'PLCs Industriales (Siemens, Allen-Bradley)',
        'Computadoras de placa reducida (Raspberry Pi)',
        'Ninguno, mi enfoque es solo en el software/monitoreo'
      ]
    },
    {
      'id': 7,
      'pregunta': '¿En qué área técnica te interesa enfocarte más al usar este laboratorio?',
      'opciones': [
        'Programación de software e interfaces (UI/UX)',
        'Electrónica y configuración de redes (IoT)',
        'Mecánica y neumática física',
        'Análisis de datos para mantenimiento preventivo'
      ]
    },
    {
      'id': 8,
      'pregunta': '¿Cuál será tu función principal al utilizar el sistema en el laboratorio?',
      'opciones': [
        'Solo observar métricas y descargar reportes (Modo lectura).',
        'Controlar los actuadores y operar las maquetas (Modo operador).',
        'Configurar la red, el ESP32 o evaluar el código (Modo admin).'
      ]
    },
    {
      'id': 9,
      'pregunta': '¿Qué tipo de predicción de la IA crees que sería más útil en estas maquetas?',
      'opciones': [
        'Predecir cuándo fallará un sensor por desgaste.',
        'Optimizar el tiempo que tarda la banda transportadora.',
        'Detectar anomalías en la conexión'
      ]
    },
    {
      'id': 10,
      'pregunta': '¿En qué entorno planearias utilizar más esta aplicación?',
      'opciones': [
        'Directamente frente a las maquetas.',
        'En un salón de clases o biblioteca.',
        'Desde mi computadora personal simulando la conexión.'
      ]
    },
  ];

  bool get _todasContestadas => _respuestas.length == _preguntas.length;

  Future<void> _finalizarEncuesta() async {
    if (!_todasContestadas) return;

    setState(() => _isSaving = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? email = prefs.getString('userEmail');

      if (email != null) {
        final query = await FirebaseFirestore.instance
            .collection('usuarios')
            .where('correo', isEqualTo: email)
            .limit(1)
            .get();

        if (query.docs.isNotEmpty) {
          await query.docs.first.reference.update({
            'encuestaCompletada': true,
            'respuestasEncuesta': _respuestas.map((k, v) => MapEntry(k.toString(), v)),
          });

          if (mounted) {
            Navigator.pushReplacementNamed(context, '/home');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar encuesta: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kPanel,
        title: const Text('ENCUESTA DE DIAGNÓSTICO', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              children: [
                const SizedBox(height: 10),
                const Text(
                  'Por favor, responde las siguientes preguntas para personalizar tu experiencia en SCADA MASTER.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 25),
                
                ..._preguntas.map((p) => _buildPreguntaCard(p)),

                const SizedBox(height: 30),
                
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: (_todasContestadas && !_isSaving) ? _finalizarEncuesta : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kCyan,
                      foregroundColor: Colors.black,
                      disabledBackgroundColor: Colors.white10,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    child: _isSaving 
                      ? const CircularProgressIndicator(color: Colors.black)
                      : const Text('FINALIZAR Y CONTINUAR', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPreguntaCard(Map<String, dynamic> p) {
    int id = p['id'];
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kPanel,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: _respuestas.containsKey(id) ? kCyan.withValues(alpha: 0.4) : Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$id. ', style: TextStyle(color: kCyan, fontWeight: FontWeight.bold, fontSize: 16)),
              Expanded(
                child: Text(
                  p['pregunta'],
                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          ... (p['opciones'] as List<String>).map((opt) => RadioListTile<String>(
            title: Text(opt, style: TextStyle(color: kText, fontSize: 13)),
            value: opt,
            groupValue: _respuestas[id],
            activeColor: kCyan,
            contentPadding: EdgeInsets.zero,
            onChanged: (val) {
              setState(() {
                _respuestas[id] = val;
              });
            },
          )),
        ],
      ),
    );
  }
}
