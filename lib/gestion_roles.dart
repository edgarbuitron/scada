import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'usuarios.dart' show Usuario;

// ─── Paleta ───
const kCard = Color(0xFF131D2E);
const kText = Color(0xFFE2E8F0);
const kBlue = Color(0xFF3B82F6);
const kMuted = Color(0xFF64748B);

class GestionRolesScreen extends StatefulWidget {
  final Usuario user;
  const GestionRolesScreen({super.key, required this.user});

  @override
  State<GestionRolesScreen> createState() => _GestionRolesScreenState();
}

class _GestionRolesScreenState extends State<GestionRolesScreen> {
  late String _currentRol;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Normalizamos el rol para que coincida con las opciones del sistema
    _currentRol = widget.user.rol;
    if (_currentRol == 'Operador') _currentRol = 'Alumno';
  }

  Future<void> _updateRol(String newRol) async {
    setState(() => _isSaving = true);
    try {
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(widget.user.id)
          .update({'rol': newRol});
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Rol de ${widget.user.nombre} actualizado a $newRol')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: kCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Row(
                children: [
                  Icon(Icons.supervised_user_circle, color: kBlue),
                  SizedBox(width: 10),
                  Text('Asignar Rol', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kText)),
                ],
              ),
              const SizedBox(height: 10),
              Text('Usuario: ${widget.user.nombre}', style: const TextStyle(color: kMuted, fontSize: 13)),
              const SizedBox(height: 20),
              
              _rolOption('Administrador', 'Control total del sistema', Icons.admin_panel_settings),
              _rolOption('Ingeniero', 'Docentes con acceso limitado', Icons.engineering),
              _rolOption('Alumno', 'Estudiantes con acceso restringido', Icons.school),
              _rolOption('Pendiente', 'Sin acceso (En espera de aprobación)', Icons.hourglass_empty_rounded),
              
              const SizedBox(height: 10),
              if (_isSaving) const LinearProgressIndicator(backgroundColor: Colors.transparent, color: kBlue),
            ],
          ),
        ),
      ),
    );
  }

  Widget _rolOption(String rol, String desc, IconData icon) {
    bool isSelected = _currentRol == rol;
    return InkWell(
      onTap: _isSaving ? null : () => _updateRol(rol),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? kBlue.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? kBlue : Colors.white10),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? kBlue : kMuted, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(rol, style: TextStyle(color: isSelected ? kBlue : kText, fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(desc, style: const TextStyle(color: kMuted, fontSize: 11)),
                ],
              ),
            ),
            if (isSelected) const Icon(Icons.check_circle, color: kBlue, size: 18),
          ],
        ),
      ),
    );
  }
}
