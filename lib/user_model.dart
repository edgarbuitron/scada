import 'package:flutter/foundation.dart';
import 'package:bcrypt/bcrypt.dart';

class Usuario {
  final String id;
  final String nombre;
  String rol;
  final String email;
  final String passwordHash;
  bool activo;
  DateTime ultimoAcceso;

  Usuario({
    required this.id,
    required this.nombre,
    required this.rol,
    required this.email,
    required this.passwordHash,
    this.activo = true,
    required this.ultimoAcceso,
  });
}

// Lista inicial de usuarios
final List<Usuario> _initialUsers = [
  Usuario(
    id: '1',
    nombre: 'Admin General',
    rol: 'Administrador',
    email: 'admin@hitech.com',
    passwordHash: BCrypt.hashpw('admin123', BCrypt.gensalt()), 
    activo: true,
    ultimoAcceso: DateTime.now(),
  ),
  Usuario(
    id: '2',
    nombre: 'Desarrollador Jefe',
    rol: 'Desarrollador',
    email: 'dev@hitech.com',
    passwordHash: BCrypt.hashpw('dev123', BCrypt.gensalt()),
    activo: true,
    ultimoAcceso: DateTime.now(),
  ),
  Usuario(
    id: '3',
    nombre: 'Operador de Planta',
    rol: 'Operador',
    email: 'operador@hitech.com',
    passwordHash: BCrypt.hashpw('op123', BCrypt.gensalt()),
    activo: false,
    ultimoAcceso: DateTime.now().subtract(const Duration(days: 2)),
  ),
];

// ValueNotifier global que notificará a los widgets cuando la lista de usuarios cambie.
final ValueNotifier<List<Usuario>> usuariosNotifier = ValueNotifier(_initialUsers);
