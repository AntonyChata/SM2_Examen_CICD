import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../chat/pantalla_chat.dart';
import 'package:url_launcher/url_launcher.dart';

class PantallaDetalleCompleto extends StatefulWidget {
  final Map<String, dynamic> data;
  final String tipo;

  const PantallaDetalleCompleto({
    super.key,
    required this.data,
    required this.tipo,
  });

  @override
  State<PantallaDetalleCompleto> createState() =>
      _PantallaDetalleCompletoState();
}

class _PantallaDetalleCompletoState extends State<PantallaDetalleCompleto> {
  Map<String, dynamic>? usuarioData;
  bool cargandoUsuario = true;

  @override
  void initState() {
    super.initState();
    _cargarUsuario();
  }

  Future<void> _cargarUsuario() async {
    try {
      final usuarioId = widget.data["usuarioId"];
      if (usuarioId == null) return;
      final doc = await FirebaseFirestore.instance
          .collection("usuarios")
          .doc(usuarioId)
          .get();
      if (doc.exists) {
        setState(() {
          usuarioData = doc.data();
        });
      }
    } catch (e) {
      debugPrint("Error cargando usuario: $e");
    } finally {
      setState(() => cargandoUsuario = false);
    }
  }

  Future<void> _abrirEnMapa(double lat, double lng) async {
    final Uri uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw 'No se pudo abrir el mapa';
    }
  }

  Future<void> _abrirChat() async {
    final user = FirebaseAuth.instance.currentUser!;
    final publicadorId = widget.data["usuarioId"];
    final reporteId = widget.data["id"];
    final tipo = widget.tipo;

    if (publicadorId == user.uid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No puedes chatear contigo mismo.")),
      );
      return;
    }

    final chatExistente = await FirebaseFirestore.instance
        .collection("chats")
        .where("publicadorId", isEqualTo: publicadorId)
        .where("usuarioId", isEqualTo: user.uid)
        .where("reporteId", isEqualTo: reporteId)
        .limit(1)
        .get();

    String chatId;
    if (chatExistente.docs.isNotEmpty) {
      chatId = chatExistente.docs.first.id;
    } else {
      final nuevoChat = await FirebaseFirestore.instance
          .collection("chats")
          .add({
            "reporteId": reporteId,
            "tipo": tipo,
            "publicadorId": publicadorId,
            "usuarioId": user.uid,
            "usuarios": [publicadorId, user.uid],
            "fechaInicio": FieldValue.serverTimestamp(),
          });
      chatId = nuevoChat.id;
    }

    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PantallaChat(
            chatId: chatId,
            reporteId: reporteId,
            tipo: tipo,
            publicadorId: publicadorId,
            usuarioId: user.uid,
          ),
        ),
      );
    }
  }

  Color _colorPorEstado(String estado) {
    switch (estado.toUpperCase()) {
      case "PERDIDO":
        return Colors.red.shade600;
      case "AVISTADO":
        return Colors.green.shade600;
      case "ENCONTRADO":
        return Colors.teal.shade600;
      case "CONFIRMADO":
        return Colors.blue.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final esReporte = widget.tipo == "reporte";

    // 📅 Campos dinámicos según tipo
    final fecha = esReporte
        ? data["fechaPerdida"] ?? "-"
        : data["fechaAvistamiento"] ?? "-";

    final hora = esReporte
        ? data["horaPerdida"] ?? "-"
        : data["horaAvistamiento"] ?? "-";

    final descripcion = esReporte
        ? (data["detalles"]?.toString().isNotEmpty == true
              ? data["detalles"]
              : data["caracteristicas"] ?? "Sin detalles adicionales.")
        : (data["descripcion"]?.toString().isNotEmpty == true
              ? data["descripcion"]
              : "Sin detalles adicionales.");

    final fotos = (data["fotos"] ?? []) as List;
    final urlFoto = esReporte
        ? (fotos.isNotEmpty ? fotos.first : null)
        : (data["foto"] ?? "");
    final recompensa = data["recompensa"]?.toString().isNotEmpty == true
        ? "S/. ${data["recompensa"]}"
        : "Sin recompensa";

    // ✅ Estado dinámico
    final estado = (data["estado"] ?? (esReporte ? "PERDIDO" : "AVISTADO"))
        .toString()
        .toUpperCase();
    final colorEstado = _colorPorEstado(estado);

    final bool deshabilitarChat =
        estado == "ENCONTRADO" || estado == "CONFIRMADO";

    // 🏷️ Título dinámico
    final tituloAppBar = esReporte
        ? "Detalle del Reporte"
        : "Detalle del Avistamiento";

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          tituloAppBar,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 📸 Imagen principal
            Stack(
              alignment: Alignment.topRight,
              children: [
                urlFoto != null && urlFoto.isNotEmpty
                    ? Image.network(
                        urlFoto,
                        width: double.infinity,
                        height: 280,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        height: 280,
                        color: Colors.grey.shade300,
                        child: const Icon(
                          Icons.pets,
                          size: 100,
                          color: Colors.teal,
                        ),
                      ),
                Positioned(
                  top: 20,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: colorEstado,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      estado,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // 🐶 Detalle general
            Container(
              transform: Matrix4.translationValues(0, -20, 0),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data["nombre"] ?? "Mascota sin nombre",
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "${data["tipo"] ?? "Desconocido"} • ${data["raza"] ?? "Sin raza"}",
                    style: const TextStyle(color: Colors.grey, fontSize: 15),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _miniInfo("Fecha", fecha, Icons.event),
                      _miniInfo("Hora", hora, Icons.access_time),
                      _miniInfo(
                        "Distrito",
                        data["distrito"] ?? "-",
                        Icons.location_city,
                      ),
                    ],
                  ),

                  const SizedBox(height: 25),
                  const Text(
                    "Descripción",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    descripcion,
                    style: const TextStyle(color: Colors.black87, height: 1.5),
                  ),
                  const SizedBox(height: 25),

                  // 📍 Última ubicación
                  const Text(
                    "Última ubicación conocida",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.place, color: Colors.teal),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            data["direccion"] ?? "Ubicación no especificada",
                            style: const TextStyle(color: Colors.black87),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (data["latitud"] != null && data["longitud"] != null)
                    ElevatedButton.icon(
                      onPressed: () => _abrirEnMapa(
                        (data["latitud"] as num).toDouble(),
                        (data["longitud"] as num).toDouble(),
                      ),
                      icon: const Icon(Icons.map_outlined),
                      label: const Text("Ver en Google Maps"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                      ),
                    ),

                  const SizedBox(height: 25),

                  // 💰 Recompensa (solo si es reporte)
                  if (esReporte && recompensa != "Sin recompensa")
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFA726), Color(0xFFFF7043)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.card_giftcard,
                            color: Colors.white,
                            size: 28,
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            "Recompensa ofrecida",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            recompensa,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 30),

                  // 👤 Información de contacto
                  const Text(
                    "Información de contacto",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 10),
                  if (cargandoUsuario)
                    const Center(child: CircularProgressIndicator())
                  else if (usuarioData != null)
                    _buildContacto(usuarioData!, deshabilitarChat)
                  else
                    const Text(
                      "No se encontró la información del publicador.",
                      style: TextStyle(color: Colors.redAccent),
                    ),

                  // 🔎 Avistamientos relacionados
                  if (esReporte) ...[
                    const SizedBox(height: 40),
                    const Text(
                      "Avistamientos relacionados",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 10),

                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection("avistamientos")
                          .where("reporteId", isEqualTo: data["id"])
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        final docs = snapshot.data!.docs;
                        if (docs.isEmpty) {
                          return const Text(
                            "No hay avistamientos relacionados aún.",
                            style: TextStyle(color: Colors.grey),
                          );
                        }

                        return Column(
                          children: docs.map((doc) {
                            final a = doc.data() as Map<String, dynamic>;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => PantallaDetalleCompleto(
                                        data: a,
                                        tipo:
                                            "avistamiento", // 👈 Tipo para mostrar correctamente
                                      ),
                                    ),
                                  );
                                },
                                leading: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    a["foto"] ?? "",
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(
                                      Icons.pets,
                                      color: Colors.teal,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  a["descripcion"] ?? "Sin descripción",
                                ),
                                subtitle: Text(
                                  a["direccion"] ?? "Sin dirección",
                                ),
                                trailing: IconButton(
                                  icon: const Icon(
                                    Icons.map_outlined,
                                    color: Colors.teal,
                                  ),
                                  onPressed: () {
                                    final lat = (a["latitud"] as num?)
                                        ?.toDouble();
                                    final lng = (a["longitud"] as num?)
                                        ?.toDouble();
                                    if (lat != null && lng != null) {
                                      final Uri uri = Uri.parse(
                                        'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
                                      );
                                      launchUrl(
                                        uri,
                                        mode: LaunchMode.externalApplication,
                                      );
                                    }
                                  },
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniInfo(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.teal, size: 22),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(color: Colors.black54, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContacto(Map<String, dynamic> user, bool deshabilitarChat) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final nombre = user["nombre"] ?? "Usuario desconocido";
    final foto = user["fotoPerfil"];
    final correo = user["correo"] ?? "";
    final usuarioId = widget.data["usuarioId"];
    final esPropietario = usuarioId == currentUser?.uid;

    ImageProvider? imagen;
    if (foto != null && foto.isNotEmpty) {
      if (foto.startsWith("assets/")) {
        imagen = AssetImage(foto); // ✅ carga avatar local
      } else if (foto.startsWith("http")) {
        imagen = NetworkImage(foto); // ✅ carga desde Firebase
      }
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.teal.shade50,
            backgroundImage: imagen,
            child: imagen == null
                ? const Icon(Icons.person, color: Colors.teal, size: 30)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nombre,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(correo, style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),
          if (!esPropietario)
            ElevatedButton.icon(
              icon: const Icon(Icons.chat_bubble_outline),
              label: Text(deshabilitarChat ? "Reporte cerrado" : "Contactar"),
              style: ElevatedButton.styleFrom(
                backgroundColor: deshabilitarChat ? Colors.grey : Colors.teal,
                foregroundColor: Colors.white,
              ),
              onPressed: deshabilitarChat ? null : _abrirChat,
            ),
        ],
      ),
    );
  }
}
