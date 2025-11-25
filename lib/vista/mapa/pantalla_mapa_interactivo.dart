import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../chat/pantalla_chat.dart';
import '../reportes/pantalla_detalle_completo.dart';

class PantallaMapaInteractivo extends StatefulWidget {
  const PantallaMapaInteractivo({super.key});

  @override
  State<PantallaMapaInteractivo> createState() =>
      _PantallaMapaInteractivoState();
}

class _PantallaMapaInteractivoState extends State<PantallaMapaInteractivo> {
  final MapController _mapController = MapController();
  bool _cargando = true;
  List<Map<String, dynamic>> _puntos = [];
  Map<String, dynamic>? _seleccionado;
  String _tipoSeleccionado = "";

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _cargando = true);
    final List<Map<String, dynamic>> puntos = [];

    final reportes = await FirebaseFirestore.instance
        .collection("reportes_mascotas")
        .get();
    for (var doc in reportes.docs) {
      final data = doc.data();
      if (data["latitud"] != null && data["longitud"] != null) {
        puntos.add({...data, "tipo": "reporte"});
      }
    }

    final avistamientos = await FirebaseFirestore.instance
        .collection("avistamientos")
        .get();
    for (var doc in avistamientos.docs) {
      final data = doc.data();
      if (data["latitud"] != null && data["longitud"] != null) {
        puntos.add({...data, "tipo": "avistamiento"});
      }
    }

    setState(() {
      _puntos = puntos;
      _cargando = false;
    });
  }

  Future<void> _abrirChat() async {
    if (_seleccionado == null) return;
    final user = FirebaseAuth.instance.currentUser!;
    final publicadorId = _seleccionado!["usuarioId"];
    final reporteId = _seleccionado!["id"];

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
            "tipo": _tipoSeleccionado,
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
            tipo: _tipoSeleccionado,
            publicadorId: publicadorId,
            usuarioId: user.uid,
          ),
        ),
      );
    }
  }

  void _mostrarInfo(Map<String, dynamic> punto) {
    setState(() {
      _seleccionado = punto;
      _tipoSeleccionado = punto["tipo"];
    });
  }

  @override
  Widget build(BuildContext context) {
    final paddingInferior = MediaQuery.of(context).viewPadding.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.teal,
        title: const Text("Mapa Interactivo"),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _cargarDatos),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            _cargando
                ? const Center(child: CircularProgressIndicator())
                : FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: LatLng(-18.0066, -70.2463),
                      initialZoom: 13,
                      onTap: (tapPosition, point) {
                        setState(() => _seleccionado = null);
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.sosmascota.app',
                      ),
                      MarkerLayer(
                        markers: _puntos.map((punto) {
                          final lat = punto["latitud"];
                          final lng = punto["longitud"];
                          if (lat == null || lng == null)
                            return const Marker(
                              point: LatLng(0, 0),
                              child: SizedBox(),
                            );

                          final esReporte = punto["tipo"] == "reporte";
                          final color = esReporte
                              ? const Color(0xFF4D9EF6)
                              : const Color(0xFFF59E0B);

                          return Marker(
                            width: 50,
                            height: 50,
                            point: LatLng(lat, lng),
                            child: GestureDetector(
                              onTap: () => _mostrarInfo(punto),
                              child: Icon(
                                Icons.location_on,
                                color: color,
                                size: 40,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
            if (_seleccionado != null) _buildInfoCard(context, paddingInferior),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, double paddingInferior) {
    final data = _seleccionado!;
    final esReporte = _tipoSeleccionado == "reporte";
    final fotos = (data["fotos"] ?? []) as List;
    final urlFoto = esReporte
        ? (fotos.isNotEmpty ? fotos.first : null)
        : (data["foto"] ?? "");

    // Datos base
    final nombre = esReporte
        ? (data["nombre"] ?? "Mascota sin nombre")
        : (data["direccion"] ?? "Avistamiento");
    final descripcion = esReporte
        ? (data["caracteristicas"] ?? "Sin descripción")
        : (data["descripcion"] ?? "Sin descripción");
    final direccion = data["direccion"] ?? "Zona no especificada";
    final fecha = esReporte
        ? (data["fechaPerdida"] ?? "")
        : (data["fechaAvistamiento"] ?? "");

    final color = esReporte ? Colors.blueAccent : Colors.orangeAccent;

    return Positioned(
      bottom: 20 + paddingInferior,
      left: 16,
      right: 16,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.grey.shade100],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabecera con imagen y nombre
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: urlFoto != null && urlFoto.isNotEmpty
                      ? Image.network(
                          urlFoto,
                          width: 75,
                          height: 75,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          width: 75,
                          height: 75,
                          color: Colors.grey.shade200,
                          child: Icon(
                            esReporte ? Icons.pets : Icons.visibility,
                            size: 40,
                            color: color,
                          ),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nombre,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.grey.shade900,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        direccion,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.calendar_today, color: color, size: 15),
                          const SizedBox(width: 4),
                          Text(
                            fecha,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),
            const Divider(thickness: 1),

            // Descripción y tipo/raza si aplica
            Text(
              esReporte
                  ? "Tipo: ${data["tipo"] ?? "-"}  •  Raza: ${data["raza"] ?? "-"}"
                  : "Avistamiento registrado",
              style: TextStyle(
                fontSize: 13.5,
                color: Colors.teal.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              descripcion,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                height: 1.3,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 12),

            // Botones de acción
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.info_outline),
                  label: const Text("Ver detalle"),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.teal.shade700,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PantallaDetalleCompleto(
                          data: data,
                          tipo: _tipoSeleccionado,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 6),
                ElevatedButton.icon(
                  icon: const Icon(Icons.chat_bubble_outline, size: 18),
                  label: const Text("Contactar"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: _abrirChat,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
