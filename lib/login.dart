import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:bcrypt/bcrypt.dart'; // Corregido: Usa el paquete bcrypt
import 'user_model.dart'; // Importa el modelo de usuario centralizado

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
    _controller =
        AnimationController(vsync: this, duration: widget.duration);
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

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  String? emailError;
  String? passwordError;

  Future<void> _handleGoogleSignIn() async {
    final picked = await showDialog<String>(
      context: context,
      builder: (_) => const _GoogleAccountPickerDialog(),
    );
    if (!mounted) return;
    if (picked != null) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Inicio de sesión cancelado.'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
    }
  }

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
      passwordError =
          (passwordController.text.isEmpty ||
                  passwordController.text.length >= 6)
              ? null
              : 'Mínimo 6 caracteres';
    });
  }

  void submitLogin() {
    _validateEmail();
    _validatePassword();
    if (emailError == null && passwordError == null) {
      if (emailController.text.isEmpty || passwordController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor, rellene todos los campos.'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      try {
        final user = usuariosNotifier.value.firstWhere(
          (u) => u.email == emailController.text,
          orElse: () => throw Exception(), // Evita error si no se encuentra
        );
        
        // Corregido: Usa BCrypt.checkpw (sincrónico)
        final isCorrect = BCrypt.checkpw(passwordController.text, user.passwordHash);

        if (isCorrect) {
          if (user.activo) {
            Navigator.pushReplacementNamed(context, '/home');
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Tu cuenta está inactiva. Contacta al administrador.'),
                backgroundColor: Colors.orangeAccent,
              ),
            );
          }
        } else {
          throw Exception();
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Credenciales incorrectas. Inténtalo de nuevo.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
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
                border: Border.all(color: Colors.blueAccent.withOpacity(.3)),
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
              backgroundColor: Colors.blueAccent.withOpacity(.2),
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
  String? _selectedSemestre;
  int? _avatarColorIndex;

  static const _avatarColors = [
    Colors.blueAccent,
    Colors.teal,
    Colors.deepPurpleAccent,
    Colors.pink,
    Colors.orange,
  ];

  final _nombreController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _controlNumberController = TextEditingController();
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
    super.dispose();
  }

  void _validatePassword() {
    setState(() {
      _confirmPasswordError =
          (_confirmPasswordController.text.isNotEmpty &&
                  _passwordController.text !=
                      _confirmPasswordController.text)
              ? 'Las contraseñas no coinciden'
              : null;
    });
  }

  void _registrarUsuario() {
    // Validar que los campos no estén vacíos
    if (_nombreController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, completa todos los campos correctamente.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final String password = _passwordController.text;
    // Corregido: Usa BCrypt.hashpw (sincrónico)
    final String hashedPassword = BCrypt.hashpw(password, BCrypt.gensalt());

    final nuevoUsuario = Usuario(
      id: (usuariosNotifier.value.length + 1).toString(),
      nombre: _nombreController.text,
      rol: 'Operador', // Rol por defecto
      email: _emailController.text,
      passwordHash: hashedPassword,
      activo: true,
      ultimoAcceso: DateTime.now(),
    );

    // Actualiza el ValueNotifier para notificar a los oyentes
    final currentUsers = List<Usuario>.from(usuariosNotifier.value);
    currentUsers.add(nuevoUsuario);
    usuariosNotifier.value = currentUsers;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('¡Cuenta creada exitosamente!'),
        backgroundColor: Colors.green,
      ),
    );

    Navigator.pop(context);
  }

  void _pickAvatar() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF101725),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Elige un color de avatar',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(_avatarColors.length, (i) {
                return GestureDetector(
                  onTap: () {
                    setState(() => _avatarColorIndex = i);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Avatar actualizado'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: _avatarColors[i],
                      shape: BoxShape.circle,
                      border: _avatarColorIndex == i
                          ? Border.all(color: Colors.white, width: 3)
                          : null,
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showTermsDialog(BuildContext ctx) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('Términos y Condiciones'),
        content: const SingleChildScrollView(
          child: Text(
            'Lorem ipsum dolor sit amet, consectetur adipiscing elit. '
            'Maecenas tempus, tellus eget condimentum rhoncus, sem quam '
            'semper libero, sit amet adipiscing sem neque sed ipsum.\n\n'
            '(Aquí iría el texto completo de tus términos y condiciones)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final avatarColor = _avatarColorIndex != null
        ? _avatarColors[_avatarColorIndex!]
        : Colors.white24;

    return AuthScaffold(
      title: 'Crear cuenta',
      icon: Icons.person,
      child: Column(
        children: [
          FadeInSlide(
            delay: const Duration(milliseconds: 100),
            child: GestureDetector(
              onTap: _pickAvatar,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: avatarColor,
                    child: _avatarColorIndex == null
                        ? const Icon(Icons.camera_alt,
                            size: 40, color: Colors.white70)
                        : const Text('TU',
                            style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: const BoxDecoration(
                        color: Colors.blueAccent,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.edit,
                          size: 14, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          const Text('Toca para elegir avatar',
              style: TextStyle(color: Colors.white54, fontSize: 12)),
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
            delay: const Duration(milliseconds: 300),
            child: TextField(
              controller: _controlNumberController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(12),
              ],
              decoration: inputDecoration('Número de Control', Icons.badge)
                  .copyWith(
                counterText: '${_controlNumberController.text.length} / 12',
              ),
            ),
          ),
          const SizedBox(height: 15),
          FadeInSlide(
            delay: const Duration(milliseconds: 400),
            child: TextField(
              decoration: inputDecoration('Número de Teléfono', Icons.phone),
              keyboardType: TextInputType.phone,
            ),
          ),
          const SizedBox(height: 15),
          FadeInSlide(
            delay: const Duration(milliseconds: 500),
            child: DropdownButtonFormField<String>(
              value: _selectedSemestre,
              decoration: inputDecoration('Semestre', Icons.school),
              hint: const Text('Seleccionar Semestre'),
              dropdownColor: const Color(0xFF101725),
              items: List.generate(12, (i) => (i + 1).toString())
                  .map((v) => DropdownMenuItem<String>(
                        value: v,
                        child: Text('Semestre $v'),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _selectedSemestre = v),
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
              obscureText: true,
              decoration: inputDecoration('Contraseña', Icons.lock),
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
          const SizedBox(height: 15),
          FadeInSlide(
            delay: const Duration(milliseconds: 900),
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
            delay: const Duration(milliseconds: 1000),
            child: ElevatedButton(
              onPressed: acceptedTerms ? _registrarUsuario : null,
              style: buttonStyle(),
              child: const SizedBox(
                width: double.infinity,
                child: Center(child: Text('Crear cuenta')),
              ),
            ),
          ),
          const SizedBox(height: 12),
          FadeInSlide(
            delay: const Duration(milliseconds: 1100),
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: buttonStyle().copyWith(
                backgroundColor: MaterialStateProperty.all(Colors.grey),
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
            color: _getColor(s).withOpacity(0.3),
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
                    backgroundColor: MaterialStateProperty.all(Colors.grey),
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
                    backgroundColor: MaterialStateProperty.all(Colors.grey),
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
                  _passwordController.text !=
                      _confirmPasswordController.text)
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
                    backgroundColor: MaterialStateProperty.all(Colors.grey),
                  ),
                  child: const Text('Atrás'),
                ),
                ElevatedButton(
                  onPressed: () =>
                      Navigator.popUntil(context, (r) => r.isFirst),
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

  const AuthScaffold({
    super.key,
    required this.title,
    required this.child,
    this.progress,
    this.icon,
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
                    child: Icon(icon ?? Icons.security,
                        size: 70, color: Colors.blueAccent),
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
