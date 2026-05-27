import 'package:flutter/material.dart';

void main() => runApp(const NuevoUsuarioApp());

// ─── Paleta ───────────────────────────────────────────────────────────────────
const kBg = Color(0xFF0D1321);
const kCard = Color(0xFF131D2E);
const kCardDark = Color(0xFF0F1825);
const kBorder = Color(0xFF1E2D45);
const kBlue = Color(0xFF3B82F6);
const kText = Color(0xFFE2E8F0);
const kMuted = Color(0xFF64748B);
const kMuted2 = Color(0xFF8B9CBD);

// ═════════════════════════════════════════════════════════════════════════════
class NuevoUsuarioApp extends StatelessWidget {
  const NuevoUsuarioApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Nuevo Usuario',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: kBg,
          fontFamily: 'Roboto',
          checkboxTheme: CheckboxThemeData(
            fillColor: WidgetStateProperty.resolveWith((s) =>
                s.contains(WidgetState.selected) ? kBlue : Colors.transparent),
            checkColor: WidgetStateProperty.all(Colors.white),
            side: const BorderSide(color: Color(0xFF2A3550), width: 1.5),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
        ),
        home: const _HomeScreen(),
      );
}

class _HomeScreen extends StatelessWidget {
  const _HomeScreen();

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: kBg,
        body: Center(
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: kBlue,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.person_add_outlined),
            label: const Text('+ Nuevo usuario',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            onPressed: () => showDialog(
              context: context,
              barrierColor: Colors.black.withOpacity(.75),
              builder: (_) => const NuevoUsuarioDialog(),
            ),
          ),
        ),
      );
}

// ═════════════════════════════════════════════════════════════════════════════
// DIALOG 1 – Nuevo usuario
// ═════════════════════════════════════════════════════════════════════════════
class NuevoUsuarioDialog extends StatefulWidget {
  const NuevoUsuarioDialog({super.key});

  @override
  State<NuevoUsuarioDialog> createState() => _NuevoUsuarioDialogState();
}

class _NuevoUsuarioDialogState extends State<NuevoUsuarioDialog> {
  final _nombreCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _correoCtrl = TextEditingController();
  String _rol = 'Operador';

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _telefonoCtrl.dispose();
    _correoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: kCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Encabezado ──
              Row(children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Nuevo usuario',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: kText)),
                      SizedBox(height: 3),
                      Text('Agregar un nuevo usuario al sistema',
                          style: TextStyle(fontSize: 12, color: kMuted2)),
                    ],
                  ),
                ),
                _closeBtn(context),
              ]),
              const SizedBox(height: 22),

              // ── Avatar ──
              Center(
                child: Stack(children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A2540),
                      shape: BoxShape.circle,
                      border: Border.all(color: kBorder, width: 2),
                    ),
                    child: const Icon(Icons.person_outline,
                        size: 40, color: kMuted2),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: const BoxDecoration(
                          color: kBlue, shape: BoxShape.circle),
                      child:
                          const Icon(Icons.add, size: 16, color: Colors.white),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 22),

              // ── Información personal ──
              _sectionLabel('Información personal'),
              const SizedBox(height: 14),
              _fieldLabel('Nombre completo'),
              const SizedBox(height: 6),
              _inputField(_nombreCtrl, 'Ej. Juan Pérez'),
              const SizedBox(height: 14),
              _fieldLabel('Número de teléfono'),
              const SizedBox(height: 6),
              _inputField(_telefonoCtrl, 'Ej. 222 123 4567',
                  keyboardType: TextInputType.phone),
              const SizedBox(height: 14),
              _fieldLabel('Correo electrónico'),
              const SizedBox(height: 6),
              _inputField(_correoCtrl, 'Ej. usuario@tecnm.mx',
                  keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 22),

              // ── Rol y permisos ──
              _sectionLabel('Rol y permisos'),
              const SizedBox(height: 14),
              Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _fieldLabel('Rol'),
                      const SizedBox(height: 6),
                      _dropdown(
                          _rol,
                          [
                            'Operador',
                            'Administrador',
                            'Supervisor',
                            'Mantenimiento',
                            'Invitado'
                          ],
                          (v) => setState(() => _rol = v!)),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: kText,
                    side: const BorderSide(color: kBorder),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    showDialog(
                      context: context,
                      barrierColor: Colors.black.withOpacity(.75),
                      builder: (_) => const PermisosDialog(),
                    );
                  },
                  child: const Text('Configurar permisos',
                      style: TextStyle(fontSize: 13)),
                ),
              ]),
              const SizedBox(height: 28),

              // ── Botones ──
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: kText,
                      side: const BorderSide(color: kBorder),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child:
                        const Text('Cancelar', style: TextStyle(fontSize: 14)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kBlue,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Guardar usuario',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dropdown(
          String value, List<String> items, void Function(String?) cb) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: kCardDark,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: kBorder),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            dropdownColor: kCardDark,
            style: const TextStyle(fontSize: 13, color: kText),
            icon:
                const Icon(Icons.keyboard_arrow_down, color: kMuted2, size: 20),
            onChanged: cb,
            items: items
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
          ),
        ),
      );
}

// ═════════════════════════════════════════════════════════════════════════════
// DIALOG 2 – Permisos del usuario  (con tabla scrollable)
// ═════════════════════════════════════════════════════════════════════════════
class _Modulo {
  final String nombre;
  final IconData icon;
  bool ver, editar, eliminar;

  _Modulo({
    required this.nombre,
    required this.icon,
    this.ver = false,
    this.editar = false,
    this.eliminar = false,
  });
}

class PermisosDialog extends StatefulWidget {
  final String nombreUsuario;
  const PermisosDialog({super.key, this.nombreUsuario = 'Carlos Ruiz'});

  @override
  State<PermisosDialog> createState() => _PermisosDialogState();
}

class _PermisosDialogState extends State<PermisosDialog> {
  late final List<_Modulo> _modulos;
  bool _selectAll = false;

  @override
  void initState() {
    super.initState();
    _modulos = [
      _Modulo(
          nombre: 'Dashboard',
          icon: Icons.dashboard_outlined,
          ver: true,
          editar: true,
          eliminar: false),
      _Modulo(
          nombre: 'Maquetas',
          icon: Icons.view_quilt_outlined,
          ver: true,
          editar: false,
          eliminar: true),
      _Modulo(
          nombre: 'Monitoreo',
          icon: Icons.monitor_heart_outlined,
          ver: true,
          editar: false,
          eliminar: false),
      _Modulo(
          nombre: 'Alarmas',
          icon: Icons.notifications_outlined,
          ver: true,
          editar: false,
          eliminar: false),
      _Modulo(
          nombre: 'Historial / Logs',
          icon: Icons.history_outlined,
          ver: true,
          editar: false,
          eliminar: false),
      _Modulo(
          nombre: 'Reportes',
          icon: Icons.description_outlined,
          ver: false,
          editar: false,
          eliminar: false),
      _Modulo(
          nombre: 'Cloud Sync',
          icon: Icons.cloud_outlined,
          ver: true,
          editar: true,
          eliminar: false),
      _Modulo(
          nombre: 'Configuración',
          icon: Icons.settings_outlined,
          ver: true,
          editar: false,
          eliminar: false),
    ];
    _refreshSelectAll();
  }

  void _refreshSelectAll() {
    _selectAll = _modulos.every((m) => m.ver && m.editar && m.eliminar);
  }

  void _toggleSelectAll(bool? v) {
    final val = v ?? false;
    setState(() {
      for (final m in _modulos) {
        m.ver = val;
        m.editar = val;
        m.eliminar = val;
      }
      _selectAll = val;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: kCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      // ── Se limita la altura máxima del diálogo ──────────────────────────
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440, maxHeight: 620),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ══════════════════════════════════════════════════════════════
            // ENCABEZADO – fijo, nunca se desplaza
            // ══════════════════════════════════════════════════════════════
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Row(children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Permisos del usuario',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: kText)),
                      const SizedBox(height: 3),
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(fontSize: 12, color: kMuted2),
                          children: [
                            const TextSpan(text: 'Configurar permisos para: '),
                            TextSpan(
                              text: widget.nombreUsuario,
                              style: const TextStyle(
                                  color: kText, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                _closeBtn(context),
              ]),
            ),

            const SizedBox(height: 20),

            // ══════════════════════════════════════════════════════════════
            // ÁREA SCROLLABLE – tabla + "seleccionar todo"
            // ══════════════════════════════════════════════════════════════
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Tabla de permisos ──
                    Container(
                      decoration: BoxDecoration(
                        color: kCardDark,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: kBorder),
                      ),
                      child: Column(children: [
                        _tableHeader(),
                        const Divider(height: 1, color: kBorder),
                        // ListView con shrinkWrap dentro de SingleChildScrollView
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _modulos.length,
                          separatorBuilder: (_, __) =>
                              const Divider(height: 1, color: kBorder),
                          itemBuilder: (_, i) => _moduloRow(_modulos[i]),
                        ),
                      ]),
                    ),

                    const SizedBox(height: 14),

                    // ── Seleccionar todo ──
                    Row(children: [
                      Checkbox(
                        value: _selectAll,
                        onChanged: _toggleSelectAll,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      const SizedBox(width: 6),
                      const Text('Seleccionar todo',
                          style: TextStyle(fontSize: 13, color: kText)),
                    ]),

                    // Espacio inferior para que el scroll no tape los botones
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),

            // ══════════════════════════════════════════════════════════════
            // BOTONES – fijos en la parte inferior, nunca se desplazan
            // ══════════════════════════════════════════════════════════════
            const Divider(height: 1, color: kBorder),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
              child: Row(children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: kText,
                      side: const BorderSide(color: kBorder),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child:
                        const Text('Cancelar', style: TextStyle(fontSize: 14)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kBlue,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Guardar permisos',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                  ),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tableHeader() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(children: const [
          Expanded(
            flex: 5,
            child: Text('Módulos del sistema',
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600, color: kMuted2)),
          ),
          Expanded(
            flex: 2,
            child: Center(
                child: Text('Ver',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: kMuted2))),
          ),
          Expanded(
            flex: 2,
            child: Center(
                child: Text('Editar',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: kMuted2))),
          ),
          Expanded(
            flex: 2,
            child: Center(
                child: Text('Eliminar',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: kMuted2))),
          ),
        ]),
      );

  Widget _moduloRow(_Modulo m) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(children: [
          // Nombre con ícono
          Expanded(
            flex: 5,
            child: Row(children: [
              Icon(m.icon, size: 18, color: kMuted2),
              const SizedBox(width: 10),
              Text(m.nombre,
                  style: const TextStyle(fontSize: 13, color: kText)),
            ]),
          ),
          // Ver
          Expanded(
            flex: 2,
            child: Center(
              child: Checkbox(
                value: m.ver,
                onChanged: (v) => setState(() {
                  m.ver = v ?? false;
                  _refreshSelectAll();
                }),
              ),
            ),
          ),
          // Editar
          Expanded(
            flex: 2,
            child: Center(
              child: Checkbox(
                value: m.editar,
                onChanged: (v) => setState(() {
                  m.editar = v ?? false;
                  _refreshSelectAll();
                }),
              ),
            ),
          ),
          // Eliminar
          Expanded(
            flex: 2,
            child: Center(
              child: Checkbox(
                value: m.eliminar,
                onChanged: (v) => setState(() {
                  m.eliminar = v ?? false;
                  _refreshSelectAll();
                }),
              ),
            ),
          ),
        ]),
      );
}

// ─── Helpers compartidos ──────────────────────────────────────────────────────
Widget _closeBtn(BuildContext context) => IconButton(
      onPressed: () => Navigator.pop(context),
      icon: const Icon(Icons.close, color: kMuted2, size: 20),
      splashRadius: 18,
    );

Widget _sectionLabel(String text) => Text(
      text,
      style: const TextStyle(
          fontSize: 14, fontWeight: FontWeight.w600, color: kText),
    );

Widget _fieldLabel(String text) => Text(
      text,
      style: const TextStyle(fontSize: 12, color: kMuted2),
    );

Widget _inputField(
  TextEditingController ctrl,
  String hint, {
  TextInputType keyboardType = TextInputType.text,
  bool obscure = false,
}) =>
    TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      obscureText: obscure,
      style: const TextStyle(fontSize: 13, color: kText),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 13, color: kMuted),
        filled: true,
        fillColor: kCardDark,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: kBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: kBlue),
        ),
      ),
    );