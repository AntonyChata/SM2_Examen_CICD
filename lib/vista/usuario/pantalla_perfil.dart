import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class PantallaPerfil extends StatefulWidget {
  const PantallaPerfil({super.key});

  @override
  State<PantallaPerfil> createState() => _PantallaPerfilState();
}

class _PantallaPerfilState extends State<PantallaPerfil> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _correoCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();

  String? _fotoUrl;
  bool cargando = true;
  int _currentIndex = 4;

  // 🐾 Lista de avatares locales
  final List<String> _avataresLocales = [
    "assets/avatars/man.png",
    "assets/avatars/woman.png",
    "assets/avatars/girl.png",
    "assets/avatars/gamer.png",
    "assets/avatars/panda.png",
    "assets/avatars/cat.png",
  ];

  @override
  void initState() {
    super.initState();
    _cargarPerfil();
  }

  Future<void> _cargarPerfil() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final doc = await FirebaseFirestore.instance
        .collection("usuarios")
        .doc(uid)
        .get();

    if (doc.exists) {
      final d = doc.data()!;
      _nombreCtrl.text = d["nombre"] ?? "";
      _correoCtrl.text = d["correo"] ?? "";
      _telefonoCtrl.text = d["telefono"] ?? "";
      _fotoUrl = d["fotoPerfil"];
    }

    setState(() => cargando = false);
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    final uid = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance.collection("usuarios").doc(uid).update({
      "telefono": _telefonoCtrl.text.trim(),
      "fotoPerfil": _fotoUrl ?? "",
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("✅ Perfil actualizado correctamente")),
    );
  }

  // 📸 Subir o tomar foto
  Future<void> _cambiarFoto(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source);
    if (picked == null) return;

    final uid = FirebaseAuth.instance.currentUser!.uid;
    final ref = FirebaseStorage.instance.ref().child(
      "usuarios/$uid/perfil.jpg",
    );

    await ref.putFile(File(picked.path));
    final url = await ref.getDownloadURL();

    setState(() => _fotoUrl = url);
    await FirebaseFirestore.instance.collection("usuarios").doc(uid).update({
      "fotoPerfil": url,
    });
  }

  // 🧩 Seleccionar avatar local
  Future<void> _seleccionarAvatarLocal() async {
    final seleccionado = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Selecciona tu avatar"),
          content: SizedBox(
            width: double.maxFinite,
            child: GridView.builder(
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
              ),
              itemCount: _avataresLocales.length,
              itemBuilder: (context, index) {
                final avatar = _avataresLocales[index];
                return GestureDetector(
                  onTap: () => Navigator.pop(context, avatar),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.teal, width: 2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(avatar, fit: BoxFit.cover),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );

    if (seleccionado != null) {
      setState(() => _fotoUrl = seleccionado);
      final uid = FirebaseAuth.instance.currentUser!.uid;
      await FirebaseFirestore.instance.collection("usuarios").doc(uid).update({
        "fotoPerfil": seleccionado,
      });
    }
  }

  // 🧭 Menú inferior de selección
  Widget _menuSeleccionAvatar() {
    return SafeArea(
      child: Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.photo_camera, color: Colors.teal),
            title: const Text("Tomar foto con cámara"),
            onTap: () => Navigator.pop(context, "camara"),
          ),
          ListTile(
            leading: const Icon(Icons.photo, color: Colors.teal),
            title: const Text("Subir foto desde galería"),
            onTap: () => Navigator.pop(context, "galeria"),
          ),
          ListTile(
            leading: const Icon(Icons.emoji_emotions, color: Colors.orange),
            title: const Text("Elegir avatar del sistema"),
            onTap: () => Navigator.pop(context, "avatar"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (cargando) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFEAF0FB),
      appBar: AppBar(
        backgroundColor: Colors.teal,
        elevation: 0,
        title: const Text(
          "Mi perfil",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: _guardar,
            child: const Text(
              "Guardar",
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // 📸 Foto o avatar
                Center(
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: () async {
                          final opcion = await showModalBottomSheet<String>(
                            context: context,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(20),
                              ),
                            ),
                            builder: (context) => _menuSeleccionAvatar(),
                          );

                          if (opcion == "galeria") {
                            _cambiarFoto(ImageSource.gallery);
                          } else if (opcion == "camara") {
                            _cambiarFoto(ImageSource.camera);
                          } else if (opcion == "avatar") {
                            _seleccionarAvatarLocal();
                          }
                        },
                        child: CircleAvatar(
                          radius: 55,
                          backgroundColor: Colors.white,
                          backgroundImage: _fotoUrl != null
                              ? (_fotoUrl!.startsWith("assets/")
                                    ? AssetImage(_fotoUrl!) as ImageProvider
                                    : NetworkImage(_fotoUrl!))
                              : null,
                          child: _fotoUrl == null
                              ? const Icon(
                                  Icons.pets,
                                  color: Colors.teal,
                                  size: 40,
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "Cambiar foto o avatar",
                        style: TextStyle(color: Colors.teal),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 🧾 Información Personal
                _buildSection(
                  "Información Personal",
                  Column(
                    children: [
                      _buildReadOnlyField("Nombre completo", _nombreCtrl),
                      const SizedBox(height: 12),
                      _buildReadOnlyField("Correo electrónico", _correoCtrl),
                      const SizedBox(height: 12),
                      _buildEditableField("Teléfono", _telefonoCtrl),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 🔒 Seguridad
                _buildSection(
                  "Seguridad",
                  Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.lock, color: Colors.teal),
                        title: const Text("Cambiar contraseña"),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          FirebaseAuth.instance.sendPasswordResetEmail(
                            email: _correoCtrl.text.trim(),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "📧 Enlace para restablecer enviado a tu correo.",
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),

      // 📌 Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.teal,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() => _currentIndex = index);
          if (index == 0) Navigator.pushReplacementNamed(context, "/inicio");
          if (index == 1) Navigator.pushNamed(context, "/buscar");
          if (index == 2) Navigator.pushNamed(context, "/reportar");
          if (index == 3) Navigator.pushNamed(context, "/mapa");
          if (index == 4) Navigator.pushReplacementNamed(context, "/perfil");
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Inicio"),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: "Buscar"),
          BottomNavigationBarItem(icon: Icon(Icons.add), label: "Reportar"),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: "Mapa"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Perfil"),
        ],
      ),
    );
  }

  // 📦 Widgets reutilizables
  Widget _buildSection(String title, Widget content) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.black,
            ),
          ),
          const Divider(),
          content,
        ],
      ),
    );
  }

  Widget _buildReadOnlyField(String label, TextEditingController ctrl) {
    return TextFormField(
      controller: ctrl,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildEditableField(
    String label,
    TextEditingController ctrl, {
    IconData? icon,
  }) {
    return TextFormField(
      controller: ctrl,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon, color: Colors.teal) : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
