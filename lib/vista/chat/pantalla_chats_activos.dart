import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'pantalla_chat.dart';

class PantallaChatsActivos extends StatelessWidget {
  const PantallaChatsActivos({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser!;
    final chatsRef = FirebaseFirestore.instance
        .collection("chats")
        .where("usuarios", arrayContains: currentUser.uid);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Mis Chats"),
        backgroundColor: Colors.teal,
      ),
      backgroundColor: const Color(0xFFF5F6FA),
      body: StreamBuilder<QuerySnapshot>(
        stream: chatsRef.orderBy("fechaInicio", descending: true).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final chats = snapshot.data!.docs;

          if (chats.isEmpty) {
            return const Center(child: Text("Aún no tienes chats activos 💬"));
          }

          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, i) {
              final chat = chats[i];
              final data = chat.data() as Map<String, dynamic>;

              final isPublicador = data["publicadorId"] == currentUser.uid;
              final otherUserId = isPublicador
                  ? data["usuarioId"]
                  : data["publicadorId"];

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection("usuarios")
                    .doc(otherUserId)
                    .get(),
                builder: (context, userSnap) {
                  if (!userSnap.hasData) {
                    return const SizedBox();
                  }

                  final userData =
                      userSnap.data!.data() as Map<String, dynamic>? ?? {};
                  final nombre = userData["nombre"] ?? "Usuario";
                  final fotoPerfil = userData["fotoPerfil"];
                  final tipo = data["tipo"] ?? "reporte";

                  return StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection("chats")
                        .doc(chat.id)
                        .collection("mensajes")
                        .orderBy("fechaEnvio", descending: true)
                        .limit(1)
                        .snapshots(),
                    builder: (context, msgSnap) {
                      String ultimoMensaje = "";
                      String fechaUltimo = "";

                      if (msgSnap.hasData && msgSnap.data!.docs.isNotEmpty) {
                        final msg =
                            msgSnap.data!.docs.first.data()
                                as Map<String, dynamic>;
                        ultimoMensaje = msg["texto"] ?? "";
                        final fecha = msg["fechaEnvio"] as Timestamp?;
                        if (fecha != null) {
                          final date = fecha.toDate();
                          fechaUltimo =
                              "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
                        }
                      }

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            radius: 25,
                            backgroundColor: Colors.grey.shade300,
                            backgroundImage:
                                (fotoPerfil != null &&
                                    fotoPerfil.toString().isNotEmpty)
                                ? NetworkImage(fotoPerfil)
                                : null,
                            child:
                                (fotoPerfil == null ||
                                    fotoPerfil.toString().isEmpty)
                                ? const Icon(Icons.person, color: Colors.teal)
                                : null,
                          ),
                          title: Text(
                            nombre,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            ultimoMensaje.isNotEmpty
                                ? ultimoMensaje
                                : "Nuevo chat (${tipo.toUpperCase()})",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Text(
                            fechaUltimo,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PantallaChat(
                                  chatId: chat.id,
                                  reporteId: data["reporteId"],
                                  tipo: tipo,
                                  publicadorId: data["publicadorId"],
                                  usuarioId: data["usuarioId"],
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
