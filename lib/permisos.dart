import 'package:flutter/material.dart';

//void main() => runApp(const PermisosApp());

// ─── Paleta ────────────────────────────────────────────────────────────────
const kBg = Color(0xFF0D1321);
const kCard = Color(0xFF131D2E);
const kCardDark = Color(0xFF0F1825);
const kBorder = Color(0xFF1E2D45);
const kBlue = Color(0xFF3B82F6);
const kText = Color(0xFFE2E8F0);
const kMuted = Color(0xFF64748B);
const kMuted2 = Color(0xFF8B9CBD);

// ═══════════════════════════════════════════════════════════════════════════
class PermisosApp extends StatelessWidget {
  const PermisosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Permisos',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: kBg,
        fontFamily: 'Roboto',
        checkboxTheme: CheckboxThemeData(
          fillColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? kBlue
                : Colors.transparent,
          ),
          checkColor: WidgetStateProperty.all(Colors.white),
          side: const BorderSide(color: Color(0xFF2A3550), width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
      home: const PermisosScreen(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
class _Modulo {
  final String nombre;
  final IconData icon;
  bool ver;
  bool editar;
  bool eliminar;

  _Modulo({
    required this.nombre,
    required this.icon,
    this.ver = false,
    this.editar = false,
    this.eliminar = false,
  });
}

// ═══════════════════════════════════════════════════════════════════════════
class PermisosScreen extends StatefulWidget {
  const PermisosScreen({super.key});

  @override
  State<PermisosScreen> createState() => _PermisosScreenState();
}

class _PermisosScreenState extends State<PermisosScreen> {
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
      ),
      _Modulo(
        nombre: 'Maquetas',
        icon: Icons.view_quilt_outlined,
        ver: true,
        eliminar: true,
      ),
      _Modulo(
        nombre: 'Monitoreo',
        icon: Icons.monitor_heart_outlined,
        ver: true,
      ),
      _Modulo(
        nombre: 'Alarmas',
        icon: Icons.notifications_outlined,
        ver: true,
      ),
      _Modulo(
        nombre: 'Historial / Logs',
        icon: Icons.history_outlined,
        ver: true,
      ),
      _Modulo(
        nombre: 'Reportes',
        icon: Icons.description_outlined,
      ),
      _Modulo(
        nombre: 'Cloud Sync',
        icon: Icons.cloud_outlined,
        ver: true,
        editar: true,
      ),
      _Modulo(
        nombre: 'Configuración',
        icon: Icons.settings_outlined,
        ver: true,
      ),
    ];

    _refreshSelectAll();
  }

  void _refreshSelectAll() {
    _selectAll = _modulos.every(
      (m) => m.ver && m.editar && m.eliminar,
    );
  }

  void _toggleSelectAll(bool? value) {
    final val = value ?? false;

    setState(() {
      for (final modulo in _modulos) {
        modulo.ver = val;
        modulo.editar = val;
        modulo.eliminar = val;
      }
      _selectAll = val;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pop(context), // cerrar tocando afuera
      child: Material(
        color: Colors.transparent,
        child: Center(
          child: GestureDetector(
            onTap: () {},
            child: Container(
              width: 440,
              constraints: const BoxConstraints(maxHeight: 620),
              decoration: BoxDecoration(
                color: kCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: kBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Permisos del usuario',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: kText,
                                ),
                              ),
                              SizedBox(height: 3),
                              Text(
                                'Configurar permisos para: Carlos Ruiz',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: kMuted2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Tabla
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: kCardDark,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: kBorder),
                            ),
                            child: Column(
                              children: [
                                _tableHeader(),
                                const Divider(height: 1, color: kBorder),
                                ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _modulos.length,
                                  separatorBuilder: (_, __) =>
                                      const Divider(height: 1, color: kBorder),
                                  itemBuilder: (_, index) =>
                                      _moduloRow(_modulos[index]),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Checkbox(
                                value: _selectAll,
                                onChanged: _toggleSelectAll,
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'Seleccionar todo',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: kText,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Divider(height: 1, color: kBorder),

                  // Botones
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: kText,
                              side: const BorderSide(color: kBorder),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: () {},
                            child: const Text('Cancelar'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kBlue,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: () {},
                            child: const Text('Guardar permisos'),
                          ),
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

  Widget _tableHeader() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Text(
              'Módulos del sistema',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: kMuted2,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Center(child: Text('Ver')),
          ),
          Expanded(
            flex: 2,
            child: Center(child: Text('Editar')),
          ),
          Expanded(
            flex: 2,
            child: Center(child: Text('Eliminar')),
          ),
        ],
      ),
    );
  }

  Widget _moduloRow(_Modulo modulo) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Row(
              children: [
                Icon(modulo.icon, size: 18, color: kMuted2),
                const SizedBox(width: 10),
                Text(
                  modulo.nombre,
                  style: const TextStyle(
                    fontSize: 13,
                    color: kText,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: Checkbox(
                value: modulo.ver,
                onChanged: (v) {
                  setState(() {
                    modulo.ver = v ?? false;
                    _refreshSelectAll();
                  });
                },
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: Checkbox(
                value: modulo.editar,
                onChanged: (v) {
                  setState(() {
                    modulo.editar = v ?? false;
                    _refreshSelectAll();
                  });
                },
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: Checkbox(
                value: modulo.eliminar,
                onChanged: (v) {
                  setState(() {
                    modulo.eliminar = v ?? false;
                    _refreshSelectAll();
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
