import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'actividades_recientes.dart';
import 'permisos.dart';
import 'package:bcrypt/bcrypt.dart';

void main() => runApp(const UsuariosApp());

// ─── Paleta ───────────────────────────────────────────────────────────────────
const kBg = Color(0xFF0D1321);
const kCard = Color(0xFF131D2E);
const kBorder = Color(0xFF1E2D45);
const kBlue = Color(0xFF3B82F6);
const kGreen = Color(0xFF16A34A);
const kRed = Color(0xFFDC2626);
const kText = Color(0xFFE2E8F0);
const kMuted = Color(0xFF64748B);
const kMuted2 = Color(0xFF8B9CBD);
const kRowHover = Color(0xFF182336);

// ─── Modelo ───────────────────────────────────────────────────────────────────
class Usuario {
  final String id;
  final String nombre;
  final String passwordHash;
  final String numero;
  final String correo;
  final String rol;
  final String ultimoAcceso;
  final String fechaRegistro;
  final String numeroControl;
  final int semestre;
  final bool activo;

  Usuario({
    required this.id,
    required this.nombre,
    required this.passwordHash,
    required this.numero,
    required this.correo,
    required this.rol,
    required this.activo,
    required this.ultimoAcceso,
    required this.semestre,
    required this.fechaRegistro,
    required this.numeroControl,
  });

  // Factory para crear un Usuario desde un DocumentSnapshot de Firestore
  factory Usuario.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Usuario(
      id: doc.id, // Usar el ID del documento de Firestore
      nombre: data['nombre'] ?? '',
      passwordHash: data['passwordHash'] ?? '',
      numero: data['numero'] ?? '',
      correo: data['correo'] ?? '',
      rol: data['rol'] ?? '',
      activo: data['activo'] ?? false,
      ultimoAcceso: data['ultimoAcceso'] ?? '',
      semestre: data['semestre'] ?? 0,
      fechaRegistro: data['fechaRegistro'] ?? '',
      numeroControl: data['numeroControl'] ?? '',
    );
  }

  // Método para convertir un Usuario a un Map para Firestore
  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'passwordHash': passwordHash,
      'numero': numero,
      'correo': correo,
      'rol': rol,
      'activo': activo,
      'ultimoAcceso': ultimoAcceso,
      'semestre': semestre,
      'fechaRegistro': fechaRegistro,
      'numeroControl': numeroControl,
    };
  }
}

// ─── App ───────────────────────────────────────────────────────────────────────
class UsuariosApp extends StatelessWidget {
  const UsuariosApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Usuarios SCADA',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: kBg,
          fontFamily: 'Roboto',
        ),
        home: const UsuariosScreen(),
      );
}

// ═════════════════════════════════════════════════════════════════════════════
class UsuariosScreen extends StatefulWidget {
  const UsuariosScreen({super.key});
  @override
  State<UsuariosScreen> createState() => _UsuariosScreenState();
}

class _UsuariosScreenState extends State<UsuariosScreen> {

  // --- Función para sembrar la base de datos ---
  Future<void> _seedDatabase() async {
    final firestore = FirebaseFirestore.instance;
    final collection = firestore.collection('usuarios');
    final snapshot = await collection.get();

    if (snapshot.docs.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La base de datos ya contiene datos. No se requiere acción.')),
      );
      return;
    }

    final seedUsers = <Usuario>[
       Usuario(
      id: 'U001',
      nombre: 'Juan Pérez',
      passwordHash: BCrypt.hashpw('pass123', BCrypt.gensalt()),
      numero: '222 123 4567',
      correo: 'juan.perez@tecnm.mx',
      rol: 'Administrador',
      activo: true,
      ultimoAcceso: '20/05/2025 10:42 AM',
      semestre: 8,
      fechaRegistro: '15/01/2024',
      numeroControl: '12345678'),
    ];

    for (var user in seedUsers) {
      await collection.doc(user.id).set(user.toMap());
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Datos de ejemplo subidos a Firestore!')),
    );
  }


  // ── Eliminar usuario con diálogo de confirmación ──────────────────────────
  void _onDeleteTap(String userId) {
     showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.65),
      builder: (_) => AlertDialog(
        backgroundColor: kCard,
        title: const Text('¿Eliminar usuario?', style: TextStyle(color: kText)),
        content: const Text('Esta acción es permanente y no se puede deshacer.', style: TextStyle(color: kMuted2)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar', style: TextStyle(color: kText)),
          ),
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('usuarios').doc(userId).delete();
              Navigator.of(context).pop();
            },
            child: const Text('Eliminar', style: TextStyle(color: kRed)),
          ),
        ],
      ),
    );
  }

  // ── build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: kBg,
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ElevatedButton(
                    onPressed: _seedDatabase,
                    child: const Text('Subir Datos a Firebase (Solo usar 1 vez)'),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    height: 520,
                    child: _buildTable(),
                  ),
                ],
              ),
            ),
          ),
        ));
  }

  
  // ── Tabla ──────────────────────────────────────────────────────────────────
  Widget _buildTable() => Container(
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kBorder),
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('usuarios').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(
                child: Text(
                  'No se encontraron usuarios.',
                  style: TextStyle(fontSize: 16, color: kMuted2),
                ),
              );
            }

            final users = snapshot.data!.docs.map((doc) => Usuario.fromFirestore(doc)).toList();

            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: 1400,
                child: Column(
                  children: [
                    const _TableHeader(),
                    const Divider(height: 1, color: kBorder),
                    Expanded(
                      child: ListView.separated(
                        itemCount: users.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1, color: kBorder),
                        itemBuilder: (_, i) => _UserRow(
                          user: users[i],
                          onDelete: () => _onDeleteTap(users[i].id),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
}


// ─── Encabezado tabla ─────────────────────────────────────────────────────────
class _TableHeader extends StatelessWidget {
  const _TableHeader();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 13,
        ),
        child: Row(
          children: const [
            _TH('ID', flex: 2),
            _TH('Nombre', flex: 4),
            _TH('Contraseña', flex: 4),
            _TH('N° Control', flex: 4),
            _TH('Número', flex: 4),
            _TH('Correo', flex: 6),
            _TH('Semestre', flex: 3),
            _TH('Fecha Registro', flex: 4),
            _TH('Último acceso', flex: 5),
            _TH('Estado', flex: 3),
            _TH('Acciones', flex: 4, align: TextAlign.center),
          ],
        ),
      );
}

class _TH extends StatelessWidget {
  final String text;
  final int flex;
  final TextAlign align;
  const _TH(this.text, {required this.flex, this.align = TextAlign.left});

  @override
  Widget build(BuildContext context) => Expanded(
        flex: flex,
        child: Text(text,
            textAlign: align,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600, color: kMuted2)),
      );
}

// ─── Fila usuario ─────────────────────────────────────────────────────────────
class _UserRow extends StatefulWidget {
  final Usuario user;
  final VoidCallback onDelete; // ← nuevo parámetro
  const _UserRow({required this.user, required this.onDelete});
  @override
  State<_UserRow> createState() => _UserRowState();
}

class _UserRowState extends State<_UserRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final u = widget.user;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        color: _hover ? kRowHover : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          // ID
          Expanded(
              flex: 2,
              child: Text(u.id,
                  style: const TextStyle(fontSize: 13, color: kMuted2))),
          // Nombre
          Expanded(
              flex: 4,
              child: Text(u.nombre,
                  style: const TextStyle(
                      fontSize: 13,
                      color: kText,
                      fontWeight: FontWeight.w500))),
          // Contraseña
          const Expanded(
              flex: 4,
              child: Text('********',
                  style: TextStyle(fontSize: 13, color: kText))),
          // N° Control
          Expanded(
              flex: 4,
              child: Text(u.numeroControl,
                  style: const TextStyle(fontSize: 13, color: kText))),
          // Número
          Expanded(
              flex: 4,
              child: Text(u.numero,
                  style: const TextStyle(fontSize: 13, color: kText))),
          // Correo
          Expanded(
              flex: 6,
              child: Text(u.correo,
                  style: const TextStyle(fontSize: 13, color: kText))),
          // Semestre
          Expanded(
              flex: 3,
              child: Text(u.semestre.toString(),
                  style: const TextStyle(fontSize: 13, color: kText))),
          // Fecha de registro
          Expanded(
              flex: 4,
              child: Text(u.fechaRegistro,
                  style: const TextStyle(fontSize: 13, color: kText))),

          // Último acceso
          Expanded(
              flex: 5,
              child: Text(u.ultimoAcceso,
                  style: const TextStyle(fontSize: 12, color: kMuted2))),
          // Estado
          Expanded(flex: 3, child: _StatusBadge(active: u.activo)),
          // Acciones
          Expanded(
            flex: 4,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Eliminar
                _ActionBtn(
                  icon: Icons.delete_outline,
                  color: kRed,
                  onTap: widget.onDelete,
                ),
                const SizedBox(width: 6),

                // Actividades de usuario
                _ActionBtn(
                  icon: Icons.event_note,
                  color: Colors.orange,
                  onTap: () {
                    showDialog(
                      context: context,
                      barrierDismissible: true, // cerrar al tocar fuera
                      barrierColor: Colors.black.withOpacity(0.65),
                      builder: (_) => const ActividadesScreen(),
                    );
                  },
                ),

                const SizedBox(width: 6),

                // Permisos de usuario
                _ActionBtn(
                  icon: Icons.manage_accounts,
                  color: Colors.purple,
                  onTap: () {
                    showDialog(
                      context: context,
                      barrierDismissible: true,
                      barrierColor: Colors.black.withOpacity(0.65),
                      builder: (_) => const PermisosScreen(),
                    );
                  },
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

// ─── Badge estado ─────────────────────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final bool active;
  const _StatusBadge({required this.active});

  @override
  Widget build(BuildContext context) => FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: active ? kGreen.withOpacity(.2) : kRed.withOpacity(.2),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            active ? 'Activo' : 'Inactivo',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: active ? kGreen : kRed),
          ),
        ),
      );
}

// ─── Botón acción ─────────────────────────────────────────────────────────────
class _ActionBtn extends StatefulWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn(
      {required this.icon, required this.color, required this.onTap});
  @override
  State<_ActionBtn> createState() => _ActionBtnState();
}

class _ActionBtnState extends State<_ActionBtn> {
  bool _hover = false;
  @override
  Widget build(BuildContext context) => MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color:
                  _hover ? widget.color.withOpacity(.18) : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                  color: _hover
                      ? widget.color.withOpacity(.4)
                      : Colors.transparent),
            ),
            child: Icon(widget.icon, size: 16, color: widget.color),
          ),
        ),
      );
}
