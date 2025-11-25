import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sos_mascotas/vista/reportes/pantalla_detalle_completo.dart';

class PantallaMisReportes extends StatelessWidget {
  const PantallaMisReportes({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text("Inicia sesión para ver tus reportes.")),
      );
    }

    final reportesRef = FirebaseFirestore.instance
        .collection("reportes_mascotas")
        .where("usuarioId", isEqualTo: uid)
        .orderBy("fechaRegistro", descending: true);

    final avistamientosRef = FirebaseFirestore.instance
        .collection("avistamientos")
        .where("usuarioId", isEqualTo: uid)
        .orderBy("fechaRegistro", descending: true);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F8FA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 1,
          title: const Text(
            "Mis Reportes",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          centerTitle: true,
          bottom: const TabBar(
            labelColor: Colors.teal,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.teal,
            tabs: [
              Tab(icon: Icon(Icons.pets), text: "Reportes"),
              Tab(icon: Icon(Icons.visibility), text: "Avistamientos"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _ListaReportes(stream: reportesRef.snapshots(), tipo: "reporte"),
            _ListaReportes(
              stream: avistamientosRef.snapshots(),
              tipo: "avistamiento",
            ),
          ],
        ),
      ),
    );
  }
}

class _ListaReportes extends StatelessWidget {
  final Stream<QuerySnapshot> stream;
  final String tipo;

  const _ListaReportes({required this.stream, required this.tipo});

  // 🟢 Cambiar estado de reporte
  Future<void> _cambiarEstado(
    BuildContext context,
    String docId,
    String estadoActual,
  ) async {
    final nuevoEstado = (estadoActual == "PERDIDO")
        ? "ENCONTRADO"
        : "CONFIRMADO";

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Cambiar estado"),
        content: Text("¿Deseas marcar este reporte como '$nuevoEstado'?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Confirmar"),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      try {
        final collection = tipo == "reporte"
            ? "reportes_mascotas"
            : "avistamientos";
        await FirebaseFirestore.instance
            .collection(collection)
            .doc(docId)
            .update({"estado": nuevoEstado});

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Estado cambiado a '$nuevoEstado'."),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error al cambiar estado: $e"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  // ✏️ Editar campos completos del reporte
  void _editar(BuildContext context, Map<String, dynamic> data, String docId) {
    final nombreCtrl = TextEditingController(text: data["nombre"] ?? "");
    final tipoCtrl = TextEditingController(text: data["tipo"] ?? "");
    final razaCtrl = TextEditingController(text: data["raza"] ?? "");
    final direccionCtrl = TextEditingController(text: data["direccion"] ?? "");
    final descripcionCtrl = TextEditingController(
      text:
          data["descripcion"] ??
          data["detalles"] ??
          data["caracteristicas"] ??
          "",
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Editar reporte"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nombreCtrl,
                decoration: const InputDecoration(
                  labelText: "Nombre de la mascota",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: tipoCtrl,
                decoration: const InputDecoration(
                  labelText: "Tipo (Perro, Gato, etc.)",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: razaCtrl,
                decoration: const InputDecoration(
                  labelText: "Raza",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: direccionCtrl,
                decoration: const InputDecoration(
                  labelText: "Dirección o zona",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: descripcionCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: "Descripción o detalles",
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final collection = tipo == "reporte"
                    ? "reportes_mascotas"
                    : "avistamientos";

                await FirebaseFirestore.instance
                    .collection(collection)
                    .doc(docId)
                    .update({
                      "nombre": nombreCtrl.text,
                      "tipo": tipoCtrl.text,
                      "raza": razaCtrl.text,
                      "direccion": direccionCtrl.text,
                      "descripcion": descripcionCtrl.text,
                    });

                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Cambios guardados correctamente."),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Error al guardar: $e"),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            },
            child: const Text("Guardar"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return Center(
            child: Text(
              tipo == "reporte"
                  ? "No has registrado ningún reporte 🐾"
                  : "No has registrado ningún avistamiento 👀",
              style: const TextStyle(color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            final id = docs[i].id;
            final fotos = (data["fotos"] ?? []) as List;
            final urlFoto = tipo == "reporte"
                ? (fotos.isNotEmpty ? fotos.first : null)
                : (data["foto"] ?? "");

            final nombre = data["nombre"] ?? "Mascota sin nombre";
            final raza = data["raza"] ?? "Sin raza";
            final direccion = data["direccion"] ?? "Zona no especificada";
            final descripcion =
                data["descripcion"] ??
                data["caracteristicas"] ??
                data["detalles"] ??
                "Sin descripción.";
            final fecha = tipo == "reporte"
                ? data["fechaPerdida"] ?? "-"
                : data["fechaAvistamiento"] ?? "-";
            final hora = tipo == "reporte"
                ? data["horaPerdida"] ?? "-"
                : data["horaAvistamiento"] ?? "-";
            final estado = (data["estado"] ?? "PERDIDO").toUpperCase();
            final colorEstado = estado == "ENCONTRADO"
                ? Colors.green
                : Colors.red;

            return GestureDetector(
              onTap: () {
                // ⚠️ Agregar el ID al mapa antes de enviarlo (necesario para las relaciones)
                final dataConId = {...data, "id": id};
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PantallaDetalleCompleto(
                      data: dataConId,
                      tipo: tipo, // "reporte" o "avistamiento"
                    ),
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 📸 Imagen
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: (urlFoto != null && urlFoto.isNotEmpty)
                            ? Image.network(
                                urlFoto,
                                width: 90,
                                height: 90,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                width: 90,
                                height: 90,
                                color: Colors.teal.shade50,
                                child: const Icon(
                                  Icons.pets,
                                  color: Colors.teal,
                                  size: 40,
                                ),
                              ),
                      ),
                      const SizedBox(width: 12),

                      // 🐶 Información
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    nombre,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colorEstado.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: colorEstado),
                                  ),
                                  child: Text(
                                    estado,
                                    style: TextStyle(
                                      color: colorEstado,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "${data["tipo"] ?? "Mascota"} • ${raza}",
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.place,
                                  color: Colors.teal,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    "$direccion • $fecha $hora",
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              descripcion.length > 70
                                  ? "${descripcion.substring(0, 70)}..."
                                  : descripcion,
                              style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 14,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 10),

                            // 🧩 Botones acción
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                TextButton.icon(
                                  onPressed: () => _editar(context, data, id),
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Colors.blueAccent,
                                  ),
                                  label: const Text(
                                    "Editar",
                                    style: TextStyle(color: Colors.blueAccent),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                TextButton.icon(
                                  onPressed: () =>
                                      _cambiarEstado(context, id, estado),
                                  icon: const Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                  ),
                                  label: const Text(
                                    "Cambiar estado",
                                    style: TextStyle(color: Colors.green),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
