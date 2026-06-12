import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  String? _docId;
  Map<String, dynamic>? _originalData;
  
  // Controllers para edición
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Valores para Dropdowns
  String? _selectedSexo;
  String? _selectedGrupo;
  String? _selectedSemestre;

  // Foto de perfil local
  File? _imageFile;
  String? _localImagePath;

  // Estados de habilitación de edición
  bool _editNombre = false;
  bool _editSexo = false;
  bool _editGrupo = false;
  bool _editSemestre = false;
  bool _editPassword = false;

  // Visibilidad de contraseña
  bool _showPassword = false;

  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    
    // Listeners para detectar cambios
    _nombreController.addListener(_checkChanges);
    _passwordController.addListener(_checkChanges);
  }

  void _checkChanges() {
    if (_originalData == null) return;
    
    bool changed = _nombreController.text != (_originalData!['nombre'] ?? '') ||
                   _passwordController.text != (_originalData!['passwordHash'] ?? '') ||
                   _selectedSexo != (_originalData!['sexo'] ?? '') ||
                   _selectedGrupo != (_originalData!['grupo'] ?? '') ||
                   _selectedSemestre != (_originalData!['semestre']?.toString() ?? '') ||
                   _imageFile != null;
    
    if (changed != _hasChanges) {
      setState(() => _hasChanges = changed);
    }
  }

  Future<void> _loadUserProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? email = prefs.getString('userEmail');
      _localImagePath = prefs.getString('profileImagePath_\$email');
      
      if (_localImagePath != null) {
        _imageFile = File(_localImagePath!);
      }

      if (email != null) {
        final query = await FirebaseFirestore.instance
            .collection('usuarios')
            .where('correo', isEqualTo: email)
            .limit(1)
            .get();

        if (query.docs.isNotEmpty) {
          final doc = query.docs.first;
          _docId = doc.id;
          _originalData = doc.data();
          
          _nombreController.text = _originalData!['nombre'] ?? '';
          _passwordController.text = _originalData!['passwordHash'] ?? '';
          _selectedSexo = _originalData!['sexo'] ?? 'Masculino';
          _selectedGrupo = _originalData!['grupo'] ?? 'Grupo A';
          _selectedSemestre = _originalData!['semestre']?.toString() ?? '1';

          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      debugPrint("Error loading profile: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      setState(() {
        _imageFile = File(image.path);
        _localImagePath = image.path;
        _checkChanges();
      });
    }
  }

  Future<void> _confirmSave() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text("¿Estás seguro?", style: TextStyle(color: Colors.white)),
        content: const Text("Se guardarán los cambios en tu perfil y en la base de datos.", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCELAR", style: TextStyle(color: Colors.redAccent)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _saveChanges();
            },
            child: const Text("GUARDAR DATOS", style: TextStyle(color: Color(0xFF38BDF8))),
          ),
        ],
      ),
    );
  }

  Future<void> _saveChanges() async {
    if (_docId == null) return;
    
    setState(() => _isSaving = true);
    
    try {
      final Map<String, dynamic> updatedData = {
        'nombre': _nombreController.text,
        'passwordHash': _passwordController.text,
        'sexo': _selectedSexo,
        'grupo': _selectedGrupo,
        'semestre': _selectedSemestre,
      };

      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(_docId)
          .update(updatedData);

      // Guardar imagen localmente y datos de sesión
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userName', _nombreController.text);
      
      final String? email = prefs.getString('userEmail');
      if (_localImagePath != null && email != null) {
        await prefs.setString('profileImagePath_\$email', _localImagePath!);
      }

      // Actualizar estado local
      _originalData!.addAll(updatedData);
      setState(() {
        _isSaving = false;
        _hasChanges = false;
        _editNombre = _editSexo = _editGrupo = _editSemestre = _editPassword = false;
        _showPassword = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Perfil actualizado con éxito"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al guardar: $e"), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color kCyan = Color(0xFF38BDF8);
    const Color kTextMuted = Color(0xFF94A3B8);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: kCyan));
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MI PERFIL',
                      style: TextStyle(color: kCyan, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                    ),
                    Text(
                      'Información detallada de tu cuenta institucional',
                      style: TextStyle(color: kTextMuted, fontSize: 13),
                    ),
                  ],
                ),
                if (_isSaving)
                  const CircularProgressIndicator(color: kCyan, strokeWidth: 2)
              ],
            ),
            const SizedBox(height: 32),
            
            // Header con Foto y Nombre
            Center(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 55,
                          backgroundColor: kCyan.withValues(alpha: 0.1),
                          backgroundImage: _imageFile != null ? FileImage(_imageFile!) : null,
                          child: _imageFile == null 
                            ? const Icon(Icons.person, size: 55, color: kCyan)
                            : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(color: kCyan, shape: BoxShape.circle),
                            child: const Icon(Icons.camera_alt, size: 18, color: Colors.black),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _nombreController.text,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  Text(
                    _originalData!['rol'] ?? 'N/A',
                    style: const TextStyle(color: kCyan, fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Sección Datos Personales
            _buildInfoSection('DATOS PERSONALES', [
              _infoTile(Icons.email_outlined, 'Correo', _originalData!['correo'], editable: false),
              _editableTile(Icons.person_outline, 'Nombre completo', _nombreController, _editNombre, (v) => setState(() => _editNombre = v)),
              _passwordEditableTile(),
              _dropdownTile(Icons.wc_outlined, 'Sexo', _selectedSexo, ['Masculino', 'Femenino'], _editSexo, (v) {
                setState(() {
                  _selectedSexo = v;
                  _checkChanges();
                });
              }, (v) => setState(() => _editSexo = v)),
            ]),
            
            const SizedBox(height: 24),
            
            // Sección Información Académica
            _buildInfoSection('INFORMACIÓN ACADÉMICA', [
              _infoTile(Icons.numbers_outlined, 'Número de Control', _originalData!['numeroControl'], editable: false),
              _dropdownTile(Icons.layers_outlined, 'Semestre', _selectedSemestre, ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10'], _editSemestre, (v) {
                setState(() {
                  _selectedSemestre = v;
                  _checkChanges();
                });
              }, (v) => setState(() => _editSemestre = v)),
              _dropdownTile(Icons.group_outlined, 'Grupo', _selectedGrupo, ['Grupo A', 'Grupo B', 'Grupo C'], _editGrupo, (v) {
                setState(() {
                  _selectedGrupo = v;
                  _checkChanges();
                });
              }, (v) => setState(() => _editGrupo = v)),
            ]),
            
            const SizedBox(height: 40),
            
            // Botón de Guardar
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _hasChanges ? _confirmSave : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kCyan,
                  foregroundColor: Colors.black,
                  disabledBackgroundColor: Colors.white10,
                  disabledForegroundColor: Colors.white24,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('GUARDAR DATOS', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(title, style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
        ),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF334155)),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _infoTile(IconData icon, String label, String? value, {bool editable = true}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF94A3B8), size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10)),
                const SizedBox(height: 2),
                Text(value ?? 'N/A', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _editableTile(IconData icon, String label, TextEditingController controller, bool isEditing, Function(bool) toggle) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: isEditing ? const Color(0xFF38BDF8) : const Color(0xFF94A3B8), size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10)),
                isEditing 
                  ? TextField(
                      controller: controller,
                      autofocus: true,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 8),
                        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF38BDF8))),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(controller.text, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                    ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(isEditing ? Icons.check_circle_outline : Icons.edit_outlined, 
                 color: isEditing ? Colors.green : const Color(0xFF38BDF8), size: 20),
            onPressed: () => toggle(!isEditing),
          ),
        ],
      ),
    );
  }

  Widget _dropdownTile(IconData icon, String label, String? value, List<String> options, bool isEditing, Function(String?) onChanged, Function(bool) toggle) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: isEditing ? const Color(0xFF38BDF8) : const Color(0xFF94A3B8), size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10)),
                isEditing 
                  ? DropdownButton<String>(
                      value: options.contains(value) ? value : options.first,
                      dropdownColor: const Color(0xFF1E293B),
                      isExpanded: true,
                      underline: Container(height: 1, color: const Color(0xFF38BDF8)),
                      items: options.map((String opt) {
                        return DropdownMenuItem<String>(
                          value: opt,
                          child: Text(opt, style: const TextStyle(color: Colors.white, fontSize: 14)),
                        );
                      }).toList(),
                      onChanged: onChanged,
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(value ?? 'N/A', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                    ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(isEditing ? Icons.check_circle_outline : Icons.edit_outlined, 
                 color: isEditing ? Colors.green : const Color(0xFF38BDF8), size: 20),
            onPressed: () => toggle(!isEditing),
          ),
        ],
      ),
    );
  }

  Widget _passwordEditableTile() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.lock_outline, color: Color(0xFF94A3B8), size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Contraseña', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10)),
                _editPassword 
                  ? TextField(
                      controller: _passwordController,
                      autofocus: true,
                      obscureText: !_showPassword,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                        focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF38BDF8))),
                        enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                        suffixIcon: IconButton(
                          icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility, color: const Color(0xFF94A3B8), size: 18),
                          onPressed: () => setState(() => _showPassword = !_showPassword),
                        ),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        _passwordController.text.replaceAll(RegExp(r'.'), '•'), 
                        style: const TextStyle(color: Colors.white, fontSize: 14, letterSpacing: 2)
                      ),
                    ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(_editPassword ? Icons.check_circle_outline : Icons.edit_outlined, 
                 color: _editPassword ? Colors.green : const Color(0xFF38BDF8), size: 20),
            onPressed: () => setState(() {
              _editPassword = !_editPassword;
              if (!_editPassword) _showPassword = false;
            }),
          ),
        ],
      ),
    );
  }
}
