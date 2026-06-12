import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'auth_service.dart';

// ================= ANIMATIONS =================
class FadeInSlide extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final double beginY;

  const FadeInSlide({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 500),
    this.delay = Duration.zero,
    this.beginY = 1.0,
  });

  @override
  State<FadeInSlide> createState() => _FadeInSlideState();
}

class _FadeInSlideState extends State<FadeInSlide>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: Offset(0, widget.beginY),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(position: _slideAnimation, child: widget.child),
    );
  }
}

// ================= LOGIN =================
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool rememberMe = false;
  bool obscure = true;
  bool _isLoading = false;

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  String? emailError;
  String? passwordError;

  /*
  Future<void> _handleGoogleSignIn() async {
    final authService = AuthService();
    final creds = await authService.iniciarSesionConGoogle();

    if (!mounted) return;

    if (creds != null) {
      if (rememberMe) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        if (creds.user?.email != null) {
          await prefs.setString('userEmail', creds.user!.email!);
        }
        if (creds.user?.displayName != null) {
          await prefs.setString('userName', creds.user!.displayName!);
        }
      }
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Inicio de sesión cancelado o fallido.'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
    }
  }
  */

  @override
  void initState() {
    super.initState();
    emailController.addListener(_validateEmail);
    passwordController.addListener(_validatePassword);
  }

  @override
  void dispose() {
    emailController.removeListener(_validateEmail);
    passwordController.removeListener(_validatePassword);
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void _validateEmail() {
    setState(() {
      emailError = (emailController.text.isEmpty ||
              emailController.text.contains('@'))
          ? null
          : 'Correo inválido';
    });
  }

  void _validatePassword() {
    setState(() {
      passwordError = null;
    });
  }

  void submitLogin() async {
    _validateEmail();
    _validatePassword();
    if (emailError != null || passwordError != null || emailController.text.isEmpty || passwordController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor, rellene todos los campos correctamente.'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Buscar el usuario en Firestore por correo
      final querySnapshot = await FirebaseFirestore.instance
          .collection('usuarios')
          .where('correo', isEqualTo: emailController.text)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('El usuario no existe en la base de datos.'),
            backgroundColor: Colors.orangeAccent,
          ),
        );
      } else {
        final userData = querySnapshot.docs.first.data();
        final storedPassword = userData['passwordHash'];

        // 2. Verificar la contraseña
        if (storedPassword == passwordController.text) {
          final String rol = userData['rol'] ?? 'Alumno';

          // 3. Manejo de sesión local
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('isLoggedIn', true);
          await prefs.setString('userEmail', emailController.text);
          await prefs.setString('userName', userData['nombre'] ?? '');
          await prefs.setString('userRole', rol);
          await prefs.setBool('showWelcome', rol != 'Pendiente'); 

          if (!mounted) return;

          // REDIRECCIÓN SEGÚN ROL Y PERFIL
          if (rol == 'Pendiente') {
            Navigator.pushReplacementNamed(context, '/espera');
          } else if (rol == 'Alumno' && !(userData['perfilCompleto'] ?? false)) {
            Navigator.pushReplacementNamed(context, '/formulario');
          } else if (!(userData['encuestaCompletada'] ?? false)) {
            Navigator.pushReplacementNamed(context, '/encuesta');
          } else {
            Navigator.pushReplacementNamed(context, '/home');
          }
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Contraseña incorrecta. Inténtelo de nuevo.'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error de conexión con la nube: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BackgroundWrapper(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(25),
            child: Container(
              width: 430,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.blueAccent.withValues(alpha: .3)),
              ),
              child: Column(
                children: [
                  const FadeInSlide(
                    child: Icon(Icons.precision_manufacturing,
                        size: 80, color: Colors.blueAccent),
                  ),
                  const SizedBox(height: 15),
                  const FadeInSlide(
                    delay: Duration(milliseconds: 100),
                    child: Text(
                      'INDUSTRIAL CONTROL',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  FadeInSlide(
                    delay: const Duration(milliseconds: 200),
                    child: TextField(
                      controller: emailController,
                      decoration: inputDecoration(
                              'Correo o usuario', Icons.person_outline)
                          .copyWith(
                        errorText: emailError,
                        errorStyle: const TextStyle(color: Colors.orangeAccent),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide:
                              const BorderSide(color: Colors.orangeAccent),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  FadeInSlide(
                    delay: const Duration(milliseconds: 300),
                    child: TextField(
                      controller: passwordController,
                      obscureText: obscure,
                      decoration:
                          inputDecoration('Contraseña', Icons.lock_outline)
                              .copyWith(
                        errorText: passwordError,
                        errorStyle:
                            const TextStyle(color: Colors.orangeAccent),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide:
                              const BorderSide(color: Colors.orangeAccent),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(obscure
                              ? Icons.visibility_off
                              : Icons.visibility),
                          onPressed: () => setState(() => obscure = !obscure),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  FadeInSlide(
                    delay: const Duration(milliseconds: 400),
                    child: Row(
                      children: [
                        Checkbox(
                          value: rememberMe,
                          onChanged: (v) => setState(() => rememberMe = v!),
                        ),
                        const Text('Recordar sesión'),
                        const Spacer(),
                        TextButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ForgotPasswordScreen(),
                            ),
                          ),
                          child: const Text('¿Olvidaste tu contraseña?'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  FadeInSlide(
                    delay: const Duration(milliseconds: 500),
                    child: ElevatedButton(
                      onPressed: submitLogin,
                      style: buttonStyle(),
                      child: const SizedBox(
                        width: double.infinity,
                        child: Center(child: Text('Entrar')),
                      ),
                    ),
                  ),
                  /*
                  const SizedBox(height: 20),
                  FadeInSlide(
                    delay: const Duration(milliseconds: 600),
                    child: Row(
                      children: const [
                        Expanded(child: Divider(color: Colors.white38)),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Text('O',
                              style: TextStyle(color: Colors.white38)),
                        ),
                        Expanded(child: Divider(color: Colors.white38)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  FadeInSlide(
                    delay: const Duration(milliseconds: 700),
                    child: ElevatedButton.icon(
                      onPressed: _handleGoogleSignIn,
                      icon: const Icon(Icons.g_mobiledata,
                          color: Colors.black87, size: 26),
                      label: const Text('Continuar con Google',
                          style: TextStyle(color: Colors.black87)),
                      style: socialButtonStyle(backgroundColor: Colors.white),
                    ),
                  ),
                  */
                  const SizedBox(height: 20),
                  FadeInSlide(
                    delay: const Duration(milliseconds: 800),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('¿No tienes cuenta? '),
                        TextButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const RegisterScreen(),
                            ),
                          ),
                          child: const Text('Crear cuenta'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Diálogo simulador de Google ───────────────────────────────
class _GoogleAccountPickerDialog extends StatelessWidget {
  const _GoogleAccountPickerDialog();

  static const _accounts = [
    {'name': 'Usuario Demo', 'email': 'demo@gmail.com'},
    {'name': 'Cuenta Trabajo', 'email': 'trabajo@gmail.com'},
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF101725),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: const [
          Icon(Icons.g_mobiledata, color: Colors.blueAccent, size: 28),
          SizedBox(width: 8),
          Text('Elegir cuenta', style: TextStyle(fontSize: 18)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: _accounts.map((acc) {
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blueAccent.withValues(alpha: .2),
              child: Text(acc['name']![0],
                  style: const TextStyle(color: Colors.blueAccent)),
            ),
            title: Text(acc['name']!),
            subtitle: Text(acc['email']!,
                style: const TextStyle(color: Colors.white54, fontSize: 12)),
            onTap: () => Navigator.of(context).pop(acc['name']),
          );
        }).toList(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Cancelar'),
        ),
      ],
    );
  }
}

// ================= REGISTER =================
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  bool acceptedTerms = false;
  bool rememberMe = false;
  String? _selectedSemestre;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  Uint8List? _profileImageBytes;
  bool _isLoading = false;

  final _nombreController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _controlNumberController = TextEditingController();
  final _telefonoController = TextEditingController();
  String? _confirmPasswordError;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_validatePassword);
    _confirmPasswordController.addListener(_validatePassword);
    _controlNumberController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _controlNumberController.dispose();
    _telefonoController.dispose();
    super.dispose();
  }

  void _validatePassword() {
    setState(() {
      _confirmPasswordError =
          (_confirmPasswordController.text.isNotEmpty &&
                  _passwordController.text != _confirmPasswordController.text)
              ? 'Las contraseñas no coinciden'
              : null;
    });
  }

  Future<void> _pickImage() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );

      if (result != null && result.files.first.bytes != null) {
        setState(() {
          _profileImageBytes = result.files.first.bytes;
        });
      }
    } catch (e) {
      if (kDebugMode) print("Error picking file: $e");
    }
  }

  void _registrarUsuario() async {
    if (_nombreController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _telefonoController.text.isEmpty ||
        _confirmPasswordError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, completa todos los campos correctamente.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // VALIDACIÓN DE DOMINIO INSTITUCIONAL (Ofuscada por seguridad)
    if (!_emailController.text.endsWith('@huetamo.tecnm.mx')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No está permitido el registro con el correo ingresado.'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? localPath;
      if (_profileImageBytes != null) {
        final directory = await getApplicationDocumentsDirectory();
        final String emailSanitized = _emailController.text.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
        final String fileName = 'profile_$emailSanitized.png';
        final File file = File(p.join(directory.path, fileName));
        await file.writeAsBytes(_profileImageBytes!);
        localPath = file.path;
      }

      // 1. Guardar en Firestore (Alineado a tu captura de pantalla)
      await FirebaseFirestore.instance.collection('usuarios').add({
        'activo': true,
        'correo': _emailController.text,
        'fechaRegistro': DateFormat('dd/MM/yyyy HH:mm:ss').format(DateTime.now()),
        'nombre': _nombreController.text,
        'numero': _telefonoController.text,
        'passwordHash': _passwordController.text, 
        'rol': 'Pendiente', 
        'perfilCompleto': false, // Nueva bandera
        'ultimoAcceso': DateFormat('dd/MM/yyyy HH:mm:ss').format(DateTime.now()),
      });

      if (localPath != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('profileImagePath_\${_emailController.text}', localPath);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cuenta creada. En espera de aprobación del administrador.'),
          backgroundColor: Colors.blueAccent,
        ),
      );
      
      // Redirigir a pantalla de espera
      Navigator.pushReplacementNamed(context, '/espera');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar en la nube: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showTermsDialog(BuildContext ctx) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF101725),
        title: const Text('Términos y Condiciones de Uso - SCADA MASTER',
            style: TextStyle(color: Colors.blueAccent, fontSize: 18, fontWeight: FontWeight.bold)),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '1. Aceptación de los Términos y Propósito del Sistema\n'
                'Al crear una cuenta y acceder a la aplicación SCADA MASTER, el usuario (ya sea estudiante, profesor o administrador) acepta de manera expresa los presentes términos y condiciones. Esta plataforma ha sido desarrollada con fines académicos, de investigación y de control industrial. Su propósito principal es permitir la supervisión, el monitoreo analítico y la manipulación remota de las maquetas físicas del laboratorio (Centro Neumático, Robot de 3 Ejes, Centro de Maquinados y Prensado) a través de una red local o conexión a la nube.',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              SizedBox(height: 12),
              Text(
                '2. Recopilación, Manejo y Privacidad de los Datos\n'
                'Para garantizar la trazabilidad y la seguridad en el laboratorio, el sistema recopila información personal básica del usuario (como nombre, correo electrónico, semestre, rol y número de control). Adicionalmente, la aplicación genera y almacena un registro continuo (logs) de todas las actividades operativas realizadas, incluyendo inicios de sesión, manipulación de actuadores, paros de emergencia y generación de reportes. Esta información se almacena de forma local y se sincroniza en la nube (mediante Firebase) exclusivamente para fines de evaluación académica, auditoría del sistema y control de acceso, comprometiéndonos a no compartir estos datos con terceros ajenos a la institución.',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              SizedBox(height: 12),
              Text(
                '3. Responsabilidad Operativa y Seguridad Física\n'
                'El usuario es directamente responsable de cualquier comando, movimiento o acción ejecutada a través de la aplicación sobre las maquetas físicas. Debido a que el sistema interactúa con hardware electromecánico y neumático en tiempo real, el usuario se compromete a operar la interfaz con precaución, respetando siempre los protocolos de seguridad del laboratorio. Queda estrictamente prohibido enviar comandos negligentes, alterar el código o intentar vulnerar el sistema híbrido de comunicación (HTTP/Wi-Fi local) de forma que ponga en riesgo la integridad de los equipos, los motores o la seguridad física de las personas presentes en el área de prácticas.',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              SizedBox(height: 12),
              Text(
                '4. Disponibilidad del Servicio y Conexión de Red\n'
                'SCADA MASTER opera bajo una arquitectura híbrida (Offline/Online). El usuario comprende que para el control directo de las maquetas es requisito indispensable estar conectado a la red Wi-Fi local generada por los controladores de hardware. La institución y los desarrolladores del software no se hacen responsables por daños a las piezas o interrupciones en las prácticas derivadas de latencias severas, pérdida de paquetes o desconexiones súbitas de la red durante el control manual o automático de los procesos industriales.',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              SizedBox(height: 12),
              Text(
                '5. Permisos, Credenciales y Suspensión de Cuentas\n'
                'Las credenciales de acceso (correo y contraseña) son de uso estrictamente personal e intransferible. El usuario acepta que su nivel de acceso (ver, editar, controlar o eliminar) será asignado y modificado por un administrador o profesor a cargo. El equipo administrativo se reserva el derecho de auditar el historial de eventos y suspender, revocar o eliminar de manera permanente la cuenta de cualquier usuario que comparta sus credenciales, realice actos de vandalismo digital o infrinja los reglamentos internos de la institución y del laboratorio de ingeniería.',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              SizedBox(height: 12),
              Text(
                '6. Propiedad Intelectual y Derechos de Autor\n'
                'Todo el código fuente, diseño de interfaz (UI/UX), logotipos, arquitectura de software y diagramas de red que conforman el sistema SCADA MASTER son propiedad intelectual exclusiva de sus desarrolladores y de la institución académica. Se prohíbe estrictamente a los usuarios (estudiantes o personal ajeno al equipo de desarrollo) realizar ingeniería inversa, descompilar el código, copiar fragmentos del software o distribuir la aplicación (archivos APK o credenciales) fuera del entorno del laboratorio sin autorización previa y por escrito.',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              SizedBox(height: 12),
              Text(
                '7. Código de Conducta y Usos Prohibidos\n'
                'El uso de esta aplicación está estrictamente limitado a los horarios de clase, prácticas autorizadas y proyectos de investigación. Queda terminantemente prohibido: a) Intentar vulnerar o interceptar los paquetes de datos (sniffing) de la red Wi-Fi local de las maquetas; b) Enviar comandos de saturación que provoquen el bloqueo de los microcontroladores (ataques de denegación de servicio a las placas); c) Interferir intencionalmente en las prácticas de otros compañeros controlando actuadores sin consentimiento; y d) Modificar los reportes analíticos generados por el sistema (archivos PDF) para alterar calificaciones o métricas.',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              SizedBox(height: 12),
              Text(
                '8. Límite de Responsabilidad (Cláusula "As Is")\n'
                'El sistema SCADA MASTER se proporciona "tal cual" (As Is) y "según disponibilidad". Aunque el software ha sido desarrollado con altos estándares de calidad, los desarrolladores y la institución no garantizan que la aplicación esté libre de errores (bugs), interrupciones o retrasos. Por lo tanto, no se asume responsabilidad alguna por pérdida de horas de práctica, impacto en calificaciones o daños a las maquetas derivados de fallos imprevistos en el código, en la base de datos de Firebase o en el hardware interno de los teléfonos de los usuarios.',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              SizedBox(height: 12),
              Text(
                '9. Manejo de Datos Offline y Sincronización a la Nube\n'
                'El usuario acepta que durante el "Modo Offline" (conexión a red local sin internet), la información de métricas y actividades se almacena en la memoria temporal del dispositivo móvil. El usuario tiene la responsabilidad de no forzar el cierre repentino de la aplicación ni borrar los datos caché antes de que el dispositivo recupere la conexión a internet y el sistema indique que la sincronización con la nube (Firebase) ha sido exitosa. La institución no se hace responsable por la pérdida de reportes o historiales si el usuario corrompe el almacenamiento local de su dispositivo.',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              SizedBox(height: 12),
              Text(
                '10. Modificaciones a los Términos y Condiciones\n'
                'Los administradores del sistema y la dirección del laboratorio se reservan el derecho de actualizar, modificar o reemplazar cualquier parte de estos Términos y Condiciones en cualquier momento, ya sea por actualizaciones del software, cambios en las reglas del laboratorio o nuevas integraciones de hardware. Las notificaciones sobre cambios importantes se reflejarán en el panel de avisos del sistema. El uso continuo de la aplicación tras la publicación de cualquier cambio constituye la aceptación íntegra de los nuevos términos.',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Entendido', style: TextStyle(color: Colors.blueAccent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Crear cuenta',
      profileImage: _profileImageBytes != null
          ? ClipOval(
              child: Image.memory(
                _profileImageBytes!,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
              ),
            )
          : null,
      onIconTap: _pickImage,
      child: Column(
        children: [
          const SizedBox(height: 20),
          FadeInSlide(
            delay: const Duration(milliseconds: 200),
            child: TextField(
              controller: _nombreController,
              decoration: inputDecoration('Nombre completo', Icons.person),
            ),
          ),
          const SizedBox(height: 15),
          FadeInSlide(
            delay: const Duration(milliseconds: 400),
            child: TextField(
              controller: _telefonoController, 
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              decoration: inputDecoration('Número de Teléfono', Icons.phone),
              keyboardType: TextInputType.number,
            ),
          ),
          const SizedBox(height: 15),
          FadeInSlide(
            delay: const Duration(milliseconds: 600),
            child: TextField(
              controller: _emailController,
              decoration: inputDecoration('Correo', Icons.email),
            ),
          ),
          const SizedBox(height: 15),
          FadeInSlide(
            delay: const Duration(milliseconds: 700),
            child: TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: inputDecoration('Contraseña', Icons.lock).copyWith(
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          FadeInSlide(
            delay: const Duration(milliseconds: 700),
            child: PasswordStrengthIndicator(password: _passwordController.text),
          ),
          const SizedBox(height: 15),
          FadeInSlide(
            delay: const Duration(milliseconds: 800),
            child: TextField(
              controller: _confirmPasswordController,
              obscureText: _obscureConfirmPassword,
              decoration: inputDecoration('Confirmar contraseña', Icons.lock)
                  .copyWith(
                errorText: _confirmPasswordError,
                errorStyle: const TextStyle(color: Colors.orangeAccent),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Colors.orangeAccent),
                ),
                suffixIcon: IconButton(
                  icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                ),
              ),
            ),
          ),
          const SizedBox(height: 15),
           FadeInSlide(
            delay: const Duration(milliseconds: 900),
            child: Row(
              children: [
                Checkbox(
                  value: rememberMe,
                  onChanged: (v) => setState(() => rememberMe = v!),
                ),
                const Text('Recordar sesión'),
              ],
            ),
          ),
          const SizedBox(height: 15),
          FadeInSlide(
            delay: const Duration(milliseconds: 1000),
            child: Row(
              children: [
                Checkbox(
                  value: acceptedTerms,
                  onChanged: (v) => setState(() => acceptedTerms = v!),
                ),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      text: 'Acepto los ',
                      children: [
                        TextSpan(
                          text: 'términos y condiciones',
                          style: const TextStyle(
                            color: Colors.blueAccent,
                            decoration: TextDecoration.underline,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () => _showTermsDialog(context),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          FadeInSlide(
            delay: const Duration(milliseconds: 1100),
            child: ElevatedButton(
              onPressed: (acceptedTerms && !_isLoading) ? _registrarUsuario : null,
              style: buttonStyle(),
              child: SizedBox(
                width: double.infinity,
                child: Center(
                  child: _isLoading 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Crear cuenta'),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          FadeInSlide(
            delay: const Duration(milliseconds: 1200),
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: buttonStyle().copyWith(
                backgroundColor: WidgetStateProperty.all(Colors.grey),
              ),
              child: const SizedBox(
                width: double.infinity,
                child: Center(child: Text('Cancelar')),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ================= PASSWORD STRENGTH =================
class PasswordStrengthIndicator extends StatelessWidget {
  final String password;
  const PasswordStrengthIndicator({super.key, required this.password});

  double _getStrength() {
    if (password.isEmpty) return 0;
    double s = 0;
    if (password.length >= 8) s += 0.25;
    if (RegExp(r'[A-Z]').hasMatch(password)) s += 0.25;
    if (RegExp(r'[a-z]').hasMatch(password)) s += 0.25;
    if (RegExp(r'[0-9]').hasMatch(password)) s += 0.25;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(password)) s += 0.25;
    return s.clamp(0, 1);
  }

  Color _getColor(double s) {
    if (s < 0.3) return Colors.red;
    if (s < 0.6) return Colors.orange;
    if (s < 0.8) return Colors.yellow;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    final s = _getStrength();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: 8,
          decoration: BoxDecoration(
            color: _getColor(s).withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            widthFactor: s,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              decoration: BoxDecoration(
                color: _getColor(s),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          s == 0
              ? ''
              : s < 0.3
                  ? 'Débil'
                  : s < 0.6
                      ? 'Aceptable'
                      : s < 0.8
                          ? 'Fuerte'
                          : 'Muy Fuerte',
          style: TextStyle(fontSize: 12, color: _getColor(s)),
        ),
      ],
    );
  }
}

// ================= RECOVERY =================
class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Recuperar contraseña',
      progress: 1,
      child: Column(
        children: [
          const FadeInSlide(
            child: TextField(
              decoration: InputDecoration(hintText: 'Correo o teléfono'),
            ),
          ),
          const SizedBox(height: 25),
          FadeInSlide(
            delay: const Duration(milliseconds: 100),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: buttonStyle().copyWith(
                    backgroundColor: WidgetStateProperty.all(Colors.grey),
                  ),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const VerificationScreen()),
                  ),
                  style: buttonStyle(),
                  child: const Text('Enviar código'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ================= VERIFICATION =================
class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  late Timer _timer;
  int _start = 30;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    setState(() {
      _canResend = false;
      _start = 30;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_start == 0) {
        setState(() => _canResend = true);
        t.cancel();
      } else {
        setState(() => _start--);
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Código de verificación',
      progress: 2,
      child: Column(
        children: [
          const FadeInSlide(
            child: Text(
              'Introduce el código de 6 dígitos enviado a tu correo.',
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 25),
          const FadeInSlide(
            delay: Duration(milliseconds: 100),
            child: PinputSimulation(),
          ),
          const SizedBox(height: 25),
          FadeInSlide(
            delay: const Duration(milliseconds: 200),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: _canResend ? _startTimer : null,
                  child: Text(
                    'Reenviar código',
                    style: TextStyle(
                        color: _canResend ? Colors.blueAccent : Colors.grey),
                  ),
                ),
                if (!_canResend)
                  Text(': $_start s', style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),
          const SizedBox(height: 15),
          FadeInSlide(
            delay: const Duration(milliseconds: 300),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: buttonStyle().copyWith(
                    backgroundColor: WidgetStateProperty.all(Colors.grey),
                  ),
                  child: const Text('Atrás'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ResetPasswordScreen()),
                  ),
                  style: buttonStyle(),
                  child: const Text('Verificar'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PinputSimulation extends StatefulWidget {
  const PinputSimulation({super.key});

  @override
  State<PinputSimulation> createState() => _PinputSimulationState();
}

class _PinputSimulationState extends State<PinputSimulation> {
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());

  @override
  void dispose() {
    for (final c in _controllers)
      c.dispose();
    for (final n in _focusNodes)
      n.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(6, (i) {
        return SizedBox(
          width: 45,
          height: 55,
          child: TextField(
            controller: _controllers[i],
            focusNode: _focusNodes[i],
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            maxLength: 1,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            decoration: const InputDecoration(
              counterText: '',
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12))),
              filled: true,
              fillColor: Colors.white10,
            ),
            onChanged: (v) {
              if (v.isNotEmpty && i < 5) {
                _focusNodes[i + 1].requestFocus();
              }
              if (v.isEmpty && i > 0) {
                _focusNodes[i - 1].requestFocus();
              }
            },
          ),
        );
      }),
    );
  }
}

// ================= RESET PASSWORD =================
class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String? _confirmPasswordError;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_validatePassword);
    _confirmPasswordController.addListener(_validatePassword);
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _validatePassword() {
    setState(() {
      _confirmPasswordError =
          (_confirmPasswordController.text.isNotEmpty &&
                  _passwordController.text != _confirmPasswordController.text)
              ? 'Las contraseñas no coinciden'
              : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Nueva contraseña',
      progress: 3,
      child: Column(
        children: [
          FadeInSlide(
            child: TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: inputDecoration('Nueva contraseña', Icons.lock),
            ),
          ),
          const SizedBox(height: 10),
          FadeInSlide(
            delay: const Duration(milliseconds: 100),
            child: PasswordStrengthIndicator(password: _passwordController.text),
          ),
          const SizedBox(height: 15),
          FadeInSlide(
            delay: const Duration(milliseconds: 200),
            child: TextField(
              controller: _confirmPasswordController,
              obscureText: true,
              decoration: inputDecoration('Confirmar contraseña', Icons.lock)
                  .copyWith(
                errorText: _confirmPasswordError,
                errorStyle: const TextStyle(color: Colors.orangeAccent),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Colors.orangeAccent),
                ),
              ),
            ),
          ),
          const SizedBox(height: 25),
          FadeInSlide(
            delay: const Duration(milliseconds: 300),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: buttonStyle().copyWith(
                    backgroundColor: WidgetStateProperty.all(Colors.grey),
                  ),
                  child: const Text('Atrás'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
                  style: buttonStyle(),
                  child: const Text('Restablecer'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ================= TEMPLATE =================
class AuthScaffold extends StatelessWidget {
  final String title;
  final Widget child;
  final int? progress;
  final IconData? icon;
  final Widget? profileImage;
  final VoidCallback? onIconTap;

  const AuthScaffold({
    super.key,
    required this.title,
    required this.child,
    this.progress,
    this.icon,
    this.profileImage,
    this.onIconTap,
  });

  @override
  Widget build(BuildContext context) {
    return BackgroundWrapper(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: Container(
              width: 420,
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  FadeInSlide(
                    beginY: -1,
                    child: GestureDetector(
                      onTap: onIconTap,
                      child: profileImage ??
                          Icon(icon ?? Icons.person,
                              size: 70, color: Colors.blueAccent),
                    ),
                  ),
                  const SizedBox(height: 20),
                  FadeInSlide(
                    beginY: -1,
                    delay: const Duration(milliseconds: 100),
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 26, fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (progress != null) ...[
                    const SizedBox(height: 15),
                    FadeInSlide(
                      delay: const Duration(milliseconds: 200),
                      child: Column(
                        children: [
                          LinearProgressIndicator(
                            value: progress! / 3,
                            minHeight: 8,
                            backgroundColor: Colors.white12,
                            valueColor: const AlwaysStoppedAnimation(
                                Colors.blueAccent),
                          ),
                          const SizedBox(height: 8),
                          Text('Paso $progress de 3'),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 25),
                  child,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ================= BACKGROUND =================
class BackgroundWrapper extends StatelessWidget {
  final Widget child;
  const BackgroundWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF0B1220),
                Color(0xFF101725),
                Color(0xFF0B1220),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        Opacity(
          opacity: 0.08,
          child: GridPaper(
            color: Colors.blueAccent,
            interval: 35,
            divisions: 1,
          ),
        ),
        child,
      ],
    );
  }
}

// ================= STYLES =================
InputDecoration inputDecoration(String hint, IconData icon) {
  return InputDecoration(
    hintText: hint,
    prefixIcon: Icon(icon),
    filled: true,
    fillColor: Colors.white12,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide.none,
    ),
  );
}

ButtonStyle buttonStyle() {
  return ElevatedButton.styleFrom(
    backgroundColor: Colors.blueAccent,
    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
    ),
  );
}

ButtonStyle socialButtonStyle({required Color backgroundColor}) {
  return ElevatedButton.styleFrom(
    backgroundColor: backgroundColor,
    minimumSize: const Size(double.infinity, 50),
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: backgroundColor == Colors.black
          ? const BorderSide(color: Colors.white38)
          : BorderSide.none,
    ),
  );
}
