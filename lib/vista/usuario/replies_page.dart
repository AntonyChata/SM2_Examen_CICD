import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';

class RepliesPage extends StatefulWidget {
  final String parentCommentId;
  final String parentAuthor;
  const RepliesPage({
    super.key,
    required this.parentCommentId,
    required this.parentAuthor,
  });

  @override
  State<RepliesPage> createState() => _RepliesPageState();
}

class _RepliesPageState extends State<RepliesPage> {
  final TextEditingController _ctrl = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  bool _sending = false;
  XFile? _media;
  String? _mediaPreviewPath;

  CollectionReference get _repliesRef => FirebaseFirestore.instance
      .collection('comentarios')
      .doc(widget.parentCommentId)
      .collection('respuestas');

  Future<void> _pickImage() async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1400,
      );
      if (picked != null) {
        setState(() {
          _media = picked;
          _mediaPreviewPath = picked.path;
        });
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al seleccionar imagen: $e')),
        );
      }
    }
  }

  Future<Map<String, String>> _uploadMedia(XFile file) async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'anon';
    final ext = file.path.split('.').last;
    final ref = FirebaseStorage.instance
        .ref()
        .child('comentarios')
        .child(widget.parentCommentId)
        .child('respuestas')
        .child('$uid-${DateTime.now().millisecondsSinceEpoch}.$ext');
    await ref.putFile(File(file.path));
    final url = await ref.getDownloadURL();
    return {'url': url, 'type': 'image'};
  }

  Future<void> _sendReply() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty && _media == null) return;
    setState(() => _sending = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      String? mediaUrl;
      String? mediaType;

      if (_media != null) {
        final up = await _uploadMedia(_media!);
        mediaUrl = up['url'];
        mediaType = up['type'];
      }

      // 🔹 Intentamos obtener nombre y apellido desde la colección 'usuarios'
      final userDoc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user?.uid)
          .get();

      String autorNombre = 'Anónimo';
      if (userDoc.exists) {
        final data = userDoc.data()!;
        final nombre = data['nombre'] ?? '';
        final apellido = data['apellido'] ?? '';
        autorNombre = '$nombre $apellido'.trim();
      } else {
        autorNombre = user?.displayName ?? 'Usuario';
      }

      await _repliesRef.add({
        'texto': text,
        'autor': autorNombre,
        'uid': user?.uid,
        'fecha': FieldValue.serverTimestamp(),
        'mediaUrl': mediaUrl,
        'mediaType': mediaType,
        'likes': <String>[],
      });

      _ctrl.clear();
      setState(() {
        _media = null;
        _mediaPreviewPath = null;
      });
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al enviar respuesta: $e')),
        );
      }
    } finally {
      setState(() => _sending = false);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Respuestas a ${widget.parentAuthor}'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.teal,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _repliesRef
                  .orderBy('fecha', descending: false)
                  .snapshots(),
              builder: (context, snap) {
                if (snap.hasError) {
                  return Center(child: Text('Error: ${snap.error}'));
                }
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snap.data!.docs;
                if (docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'Aún no hay respuestas. Sé el primero en responder.',
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final d = docs[i];
                    final data = d.data() as Map<String, dynamic>;
                    final texto = data['texto'] ?? '';
                    final autor = data['autor'] ?? 'Anónimo';
                    final ts = data['fecha'] as Timestamp?;
                    final fecha = ts != null ? ts.toDate() : null;
                    final mediaUrl = data['mediaUrl'] as String?;
                    final likes = List<String>.from(data['likes'] ?? []);
                    final uid = FirebaseAuth.instance.currentUser?.uid;
                    final liked = uid != null && likes.contains(uid);

                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const CircleAvatar(
                                  radius: 16,
                                  backgroundColor: Colors.grey,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    autor,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                if (fecha != null)
                                  Text(
                                    '${fecha.toLocal()}'.split('.').first,
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(texto),
                            if (mediaUrl != null) ...[
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.network(
                                  mediaUrl,
                                  height: 140,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ],
                            Row(
                              children: [
                                IconButton(
                                  icon: Icon(
                                    Icons.favorite,
                                    color: liked ? Colors.red : Colors.grey,
                                  ),
                                  onPressed: () async {
                                    final user =
                                        FirebaseAuth.instance.currentUser;
                                    if (user == null) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Inicia sesión para reaccionar',
                                            ),
                                          ),
                                        );
                                      }
                                      return;
                                    }
                                    final uid = user.uid;
                                    final docRef = _repliesRef.doc(d.id);
                                    await FirebaseFirestore.instance
                                        .runTransaction((tx) async {
                                          final s = await tx.get(docRef);
                                          if (!s.exists) return;
                                          final map =
                                              s.data() as Map<String, dynamic>;
                                          final List ls = List.from(
                                            map['likes'] ?? [],
                                          );
                                          if (ls.contains(uid)) {
                                            tx.update(docRef, {
                                              'likes': FieldValue.arrayRemove([
                                                uid,
                                              ]),
                                            });
                                          } else {
                                            tx.update(docRef, {
                                              'likes': FieldValue.arrayUnion([
                                                uid,
                                              ]),
                                            });
                                          }
                                        });
                                  },
                                ),
                                Text('${likes.length}'),
                                const Spacer(),
                                IconButton(
                                  icon: const Icon(
                                    Icons.share,
                                    color: Colors.grey,
                                  ),
                                  onPressed: () {
                                    final sb = StringBuffer()..write(texto);
                                    if (mediaUrl != null) {
                                      sb.writeln('\n$mediaUrl');
                                    }
                                    Share.share(sb.toString());
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: _ctrl,
                          minLines: 1,
                          maxLines: 4,
                          decoration: InputDecoration(
                            hintText:
                                'Responder a ${widget.parentAuthor.split(' ').first}...',
                          ),
                        ),
                        if (_mediaPreviewPath != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Image.file(
                              File(_mediaPreviewPath!),
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.photo, color: Colors.teal),
                    onPressed: _pickImage,
                  ),
                  _sending
                      ? const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : IconButton(
                          icon: const Icon(Icons.send, color: Colors.teal),
                          onPressed: _sendReply,
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
