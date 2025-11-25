import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:sos_mascotas/vistamodelo/notificacion/notificacion_vm.dart';
import 'package:sos_mascotas/vista/chat/pantalla_chats_activos.dart';

class PantallaInicio extends StatefulWidget {
  const PantallaInicio({super.key});

  @override
  State<PantallaInicio> createState() => _PantallaInicioState();
}

class _PantallaInicioState extends State<PantallaInicio> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final ancho = MediaQuery.of(context).size.width;
    final bool esWeb = kIsWeb && ancho > 900;

    // 👇 Si es Web, mostramos diseño adaptado tipo dashboard
    if (esWeb) {
      return _buildWebLayout(context);
    }

    // 👇 Si no, se mantiene tu diseño móvil original
    return _buildMobileLayout(context);
  }

  // ---------------------- 💻 NUEVO DISEÑO WEB MODERNO ----------------------
  Widget _buildWebLayout(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      body: Row(
        children: [
          // 🌈 Menú lateral con efecto moderno
          Container(
            width: 260,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF009688), Color(0xFF00695C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 12,
                  offset: const Offset(3, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 50),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Icon(Icons.pets, color: Colors.white, size: 28),
                      SizedBox(width: 8),
                      Text(
                        "SOS Mascota",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                _menuItem(Icons.home, "Inicio", () {}),
                _menuItem(
                  Icons.add_circle,
                  "Reportar Mascota",
                  () => Navigator.pushNamed(context, "/reportarMascota"),
                ),
                _menuItem(
                  Icons.visibility,
                  "Registrar Avistamiento",
                  () => Navigator.pushNamed(context, "/avistamiento"),
                ),
                _menuItem(
                  Icons.map,
                  "Mapa Interactivo",
                  () => Navigator.pushNamed(context, "/mapa"),
                ),
                _menuItem(Icons.chat, "Chats", () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PantallaChatsActivos(),
                    ),
                  );
                }),
                const Spacer(),
                const Divider(color: Colors.white38),
                // 👇 Nuevo orden del final
                _menuItem(
                  Icons.person,
                  "Perfil",
                  () => Navigator.pushNamed(context, "/perfil"),
                ),
                _menuItem(
                  Icons.comment,
                  "Comentarios",
                  () => Navigator.pushNamed(context, "/comentarios"),
                ),
                _menuItem(Icons.exit_to_app, "Cerrar sesión", () async {
                  await FirebaseAuth.instance.signOut();
                  if (context.mounted) {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      "/login",
                      (_) => false,
                    );
                  }
                }),
                const SizedBox(height: 20),
              ],
            ),
          ),

          // 🌤 Contenido principal con encabezado superior
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFF5F7FA), Color(0xFFEFF1F5)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                children: [
                  // 🔹 Encabezado superior con nombre y foto
                  Container(
                    height: 80,
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        StreamBuilder<DocumentSnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection("usuarios")
                              .doc(uid)
                              .snapshots(),
                          builder: (context, snapshot) {
                            final data =
                                snapshot.data?.data()
                                    as Map<String, dynamic>? ??
                                {};
                            final nombre = data["nombre"] ?? "Usuario";
                            return Text(
                              "¡Hola, ${nombre.toString().toUpperCase()}!",
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF333333),
                              ),
                            );
                          },
                        ),
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.teal.shade100,
                          child: const Icon(Icons.person, color: Colors.teal),
                        ),
                      ],
                    ),
                  ),

                  // 🌟 Contenido principal
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Acciones rápidas",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF333333),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Wrap(
                            spacing: 20,
                            runSpacing: 20,
                            children: [
                              _modernActionCard(
                                Icons.add_circle,
                                "Reportar Mascota",
                                Colors.purple,
                                onTap: () => Navigator.pushNamed(
                                  context,
                                  "/reportarMascota",
                                ),
                              ),
                              _modernActionCard(
                                Icons.visibility,
                                "Registrar Avistamiento",
                                Colors.orange,
                                onTap: () => Navigator.pushNamed(
                                  context,
                                  "/avistamiento",
                                ),
                              ),
                              _modernActionCard(
                                Icons.map,
                                "Mapa Interactivo",
                                Colors.teal,
                                onTap: () =>
                                    Navigator.pushNamed(context, "/mapa"),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🔹 Tarjeta moderna con sombra y efecto hover
  Widget _modernActionCard(
    IconData icon,
    String title,
    Color color, {
    VoidCallback? onTap,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 350,
          height: 120,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 36),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _menuItem(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: Colors.white70),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------- 📱 DISEÑO MÓVIL ----------------------
  Widget _buildMobileLayout(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection("usuarios")
              .doc(uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Text("Cargando...");
            }
            final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
            final nombre = data["nombre"] ?? "Usuario";
            final fotoPerfil = data["fotoPerfil"];
            return Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pushNamed(context, "/perfil"),
                  child: CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage:
                        (fotoPerfil != null && fotoPerfil.toString().isNotEmpty)
                        ? (fotoPerfil.toString().startsWith("assets/")
                              ? AssetImage(fotoPerfil) as ImageProvider
                              : NetworkImage(fotoPerfil))
                        : null,
                    child: (fotoPerfil == null || fotoPerfil.toString().isEmpty)
                        ? const Icon(Icons.person, color: Colors.teal)
                        : null,
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "¡Hola, $nombre!",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black,
                      ),
                    ),
                    const Text(
                      "Ayudemos a encontrar mascotas",
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
        actions: [
          Consumer<NotificacionVM>(
            builder: (context, vm, _) {
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications, color: Colors.teal),
                    onPressed: () async {
                      Navigator.pushNamed(context, "/notificaciones");
                      await vm.marcarTodasComoLeidas();
                    },
                  ),
                  if (vm.noLeidas > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${vm.noLeidas}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: "Buscar mascotas perdidas...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.all(12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Acciones Rápidas",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildActionCard(
                    Icons.add_circle,
                    "Reportar Mascota",
                    Colors.purple,
                    onTap: () =>
                        Navigator.pushNamed(context, "/reportarMascota"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionCard(
                    Icons.visibility,
                    "Registrar Avistamiento",
                    Colors.orange,
                    onTap: () => Navigator.pushNamed(context, "/avistamiento"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionCard(
                    Icons.map,
                    "Mapa Interactivo",
                    Colors.teal,
                    onTap: () => Navigator.pushNamed(context, "/mapa"),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              "Menú Principal",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _buildMenuItem(
              Icons.pets,
              "Ver Mascotas Reportadas",
              "Explora todos los reportes",
              onTap: () => Navigator.pushNamed(context, "/verReportes"),
            ),
            _buildMenuItem(
              Icons.assignment,
              "Mis Reportes",
              "Gestiona tus publicaciones",
              onTap: () => Navigator.pushNamed(context, "/misReportes"),
            ),
            _buildMenuItem(
              Icons.chat,
              "Chats",
              "Conversaciones activas",
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PantallaChatsActivos()),
              ),
            ),
            _buildMenuItem(
              Icons.person,
              "Mi Perfil",
              "Configuración de cuenta",
              onTap: () => Navigator.pushNamed(context, "/perfil"),
            ),
            _buildMenuItem(
              Icons.comment,
              "Comentarios",
              "Lee y comparte experiencias",
              onTap: () => Navigator.pushNamed(context, "/comentarios"),
            ),
            _buildMenuItem(
              Icons.exit_to_app,
              "Cerrar Sesión",
              "Salir de tu cuenta actual",
              onTap: () async {
                final confirmar = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text("Cerrar Sesión"),
                    content: const Text("¿Deseas cerrar sesión?"),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text("Cancelar"),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        child: const Text("Cerrar Sesión"),
                      ),
                    ],
                  ),
                );

                if (confirmar == true) {
                  await FirebaseAuth.instance.signOut();
                  if (context.mounted) {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      "/login",
                      (_) => false,
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.teal,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() => _currentIndex = index);
          if (index == 4) {
            Navigator.pushNamed(context, "/perfil");
          }
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

  Widget _buildActionCard(
    IconData icon,
    String title,
    Color color, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 32, color: Colors.white),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    IconData icon,
    String title,
    String subtitle, {
    VoidCallback? onTap,
  }) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: Colors.teal),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
