import 'package:flutter/material.dart';

void main() {
  runApp(const LoginApp());
}

class LoginApp extends StatelessWidget {
  const LoginApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Industrial Login',
      theme: ThemeData.dark(),
      home: const LoginScreen(),
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

  void validateLogin() {
    setState(() {
      emailError = null;
      passwordError = null;

      if (!emailController.text.contains('@')) {
        emailError = "Correo inválido";
      }

      if (passwordController.text.length < 6) {
        passwordError = "Mínimo 6 caracteres";
      }

      if (emailError == null && passwordError == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Inicio de sesión exitoso"),
          ),
        );
      }
    });
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
                  const Icon(
                    Icons.precision_manufacturing,
                    size: 80,
                    color: Colors.blueAccent,
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    "INDUSTRIAL CONTROL",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  Text(
                    "SCADA Academic Platform",
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                  const SizedBox(height: 30),
                  TextField(
                    controller: emailController,
                    decoration: inputDecoration(
                      "Correo o usuario",
                      Icons.person_outline,
                    ).copyWith(errorText: emailError),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: passwordController,
                    obscureText: obscure,
                    decoration: inputDecoration(
                      "Contraseña",
                      Icons.lock_outline,
                    ).copyWith(
                      errorText: passwordError,
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscure ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            obscure = !obscure;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Checkbox(
                        value: rememberMe,
                        onChanged: (v) {
                          setState(() {
                            rememberMe = v!;
                          });
                        },
                      ),
                      const Text("Recordar sesión"),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ForgotPasswordScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          "¿Olvidaste tu contraseña?",
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: validateLogin,
                    style: buttonStyle(),
                    child: const SizedBox(
                      width: double.infinity,
                      child: Center(
                        child: Text("Entrar"),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("¿No tienes cuenta? "),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const RegisterScreen(),
                            ),
                          );
                        },
                        child: const Text("Crear cuenta"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Versión 1.0.0",
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    "Instituto Tecnológico",
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 11,
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

// ================= REGISTER =================
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  bool acceptedTerms = false;

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: "Crear cuenta",
      child: Column(
        children: [
          TextField(
            decoration: inputDecoration(
              "Nombre completo",
              Icons.person,
            ),
          ),
          const SizedBox(height: 15),
          TextField(
            decoration: inputDecoration(
              "Semestre",
              Icons.school,
            ),
          ),
          const SizedBox(height: 15),
          TextField(
            decoration: inputDecoration(
              "Correo",
              Icons.email,
            ),
          ),
          const SizedBox(height: 15),
          TextField(
            decoration: inputDecoration(
              "Teléfono",
              Icons.phone,
            ),
          ),
          const SizedBox(height: 15),
          TextField(
            obscureText: true,
            decoration: inputDecoration(
              "Contraseña",
              Icons.lock,
            ),
          ),
          const SizedBox(height: 15),
          TextField(
            obscureText: true,
            decoration: inputDecoration(
              "Confirmar contraseña",
              Icons.lock,
            ),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Checkbox(
                value: acceptedTerms,
                onChanged: (v) {
                  setState(() {
                    acceptedTerms = v!;
                  });
                },
              ),
              const Expanded(
                child: Text(
                  "Acepto términos y condiciones",
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: acceptedTerms ? () => Navigator.pop(context) : null,
            style: buttonStyle(),
            child: const SizedBox(
              width: double.infinity,
              child: Center(
                child: Text("Crear cuenta"),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ================= RECOVERY =================
class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: "Recuperar contraseña",
      progress: 1,
      child: Column(
        children: [
          TextField(
            decoration: inputDecoration(
              "Correo o teléfono",
              Icons.email,
            ),
          ),
          const SizedBox(height: 25),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const VerificationScreen(),
                ),
              );
            },
            style: buttonStyle(),
            child: const Text("Enviar código"),
          ),
        ],
      ),
    );
  }
}

class VerificationScreen extends StatelessWidget {
  const VerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: "Código de verificación",
      progress: 2,
      child: Column(
        children: [
          TextField(
            decoration: inputDecoration(
              "Código",
              Icons.verified,
            ),
          ),
          const SizedBox(height: 25),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ResetPasswordScreen(),
                ),
              );
            },
            style: buttonStyle(),
            child: const Text("Verificar"),
          ),
        ],
      ),
    );
  }
}

class ResetPasswordScreen extends StatelessWidget {
  const ResetPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: "Nueva contraseña",
      progress: 3,
      child: Column(
        children: [
          TextField(
            obscureText: true,
            decoration: inputDecoration(
              "Nueva contraseña",
              Icons.lock,
            ),
          ),
          const SizedBox(height: 15),
          TextField(
            obscureText: true,
            decoration: inputDecoration(
              "Confirmar contraseña",
              Icons.lock,
            ),
          ),
          const SizedBox(height: 25),
          ElevatedButton(
            onPressed: () {
              Navigator.popUntil(
                context,
                (route) => route.isFirst,
              );
            },
            style: buttonStyle(),
            child: const Text(
              "Restablecer contraseña",
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

  const AuthScaffold({
    super.key,
    required this.title,
    required this.child,
    this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return BackgroundWrapper(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(25),
            child: Container(
              width: 420,
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.security,
                    size: 70,
                    color: Colors.blueAccent,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (progress != null) ...[
                    const SizedBox(height: 15),
                    LinearProgressIndicator(
                      value: progress! / 3,
                      minHeight: 8,
                    ),
                    const SizedBox(height: 8),
                    Text("Paso $progress de 3"),
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

  const BackgroundWrapper({
    super.key,
    required this.child,
  });

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
InputDecoration inputDecoration(
  String hint,
  IconData icon,
) {
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
    padding: const EdgeInsets.symmetric(
      vertical: 16,
      horizontal: 20,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
    ),
  );
}
