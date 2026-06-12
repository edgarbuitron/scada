import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
    ],
  );
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Función principal para llamar a Google
  Future<UserCredential?> iniciarSesionConGoogle() async {
    try {
      // 1. Abre el panel nativo de selección de cuentas de Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      // PROTECCIÓN: Si el usuario presiona "Cancelar" o toca fuera del panel, detenemos el proceso
      if (googleUser == null) {
        print("El usuario canceló el inicio de sesión.");
        return null; 
      }

      // 2. Obtiene los detalles y llaves de seguridad de esa cuenta
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // 3. Empaqueta las credenciales para que Firebase las pueda leer
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 4. Inicia sesión oficialmente en tu base de datos y devuelve los datos del usuario
      return await _auth.signInWithCredential(credential);
      
    } catch (e) {
      print("Ocurrió un error al abrir Google: $e");
      return null;
    }
  }

  // Cerrar sesión
  Future<void> cerrarSesion() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
