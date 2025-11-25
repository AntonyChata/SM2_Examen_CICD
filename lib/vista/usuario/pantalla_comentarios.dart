import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'replies_page.dart';

class PantallaComentarios extends StatefulWidget {
  const PantallaComentarios({super.key});

  @override
  State<PantallaComentarios> createState() => _PantallaComentariosState();
}

class _PantallaComentariosState extends State<PantallaComentarios> {
  final TextEditingController _ctrl = TextEditingController();
  final CollectionReference _comentariosRef = FirebaseFirestore.instance
      .collection('comentarios');
  final ImagePicker _picker = ImagePicker();
  final ScrollController _scrollController = ScrollController();

  XFile? _media;
  String? _mediaPreviewPath;
  bool _enviando = false;

  String _filtro = 'todos';
  String _filtroTiempo = 'todos';
  DateTime? _fechaSeleccionada;
  Set<String> _guardados = {};

  @override
  void initState() {
    super.initState();
    _cargarGuardados();
  }

  Future<void> _cargarGuardados() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(user.uid)
        .get();
    if (doc.exists && doc.data()!['guardados'] != null) {
      setState(() {
        _guardados = Set<String>.from(doc.data()!['guardados']);
      });
    }
  }

  Future<void> _guardarPersistente() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await FirebaseFirestore.instance.collection('usuarios').doc(user.uid).set({
      'guardados': _guardados.toList(),
    }, SetOptions(merge: true));
  }

  Future<void> _pickImage() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
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
        .child('$uid-${DateTime.now().millisecondsSinceEpoch}.$ext');
    await ref.putFile(File(file.path));
    final url = await ref.getDownloadURL();
    return {'url': url, 'type': 'image'};
  }

  Future<void> _eliminarComentario(String docId, String? mediaUrl) async {
    try {
      // eliminar subcolección de respuestas
      final replies = await _comentariosRef
          .doc(docId)
          .collection('respuestas')
          .get();
      for (var doc in replies.docs) {
        await doc.reference.delete();
      }

      // eliminar imagen asociada si hay
      if (mediaUrl != null && mediaUrl.isNotEmpty) {
        try {
          final ref = await FirebaseStorage.instance.refFromURL(mediaUrl);
          await ref.delete();
        } catch (_) {}
      }

      await _comentariosRef.doc(docId).delete();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Comentario eliminado')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al eliminar: $e')));
    }
  }

  Future<void> _enviarComentario() async {
    final texto = _ctrl.text.trim();
    if (texto.isEmpty && _media == null) return;
    setState(() => _enviando = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final docUsuario = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .get();
      String autor = 'Anónimo';
      if (docUsuario.exists) {
        final data = docUsuario.data()!;
        autor = "${data['nombre'] ?? ''} ${data['apellido'] ?? ''}".trim();
      }

      String? mediaUrl;
      String? mediaType;
      if (_media != null) {
        final upload = await _uploadMedia(_media!);
        mediaUrl = upload['url'];
        mediaType = upload['type'];
      }

      await _comentariosRef.add({
        'texto': texto,
        'autor': autor,
        'uid': user.uid,
        'fecha': FieldValue.serverTimestamp(),
        'mediaUrl': mediaUrl,
        'mediaType': mediaType,
        'likes': <String>[],
        'dislikes': <String>[],
        'shares': 0,
      });

      _ctrl.clear();
      setState(() {
        _media = null;
        _mediaPreviewPath = null;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Comentario enviado')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _enviando = false);
    }
  }

  Future<void> _toggleReaction(String docId, bool isLike) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final uid = user.uid;
    final docRef = _comentariosRef.doc(docId);
    await FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(docRef);
      if (!snap.exists) return;
      final data = snap.data() as Map<String, dynamic>;
      final List likes = List.from(data['likes'] ?? []);
      if (isLike) {
        if (likes.contains(uid)) {
          tx.update(docRef, {
            'likes': FieldValue.arrayRemove([uid]),
          });
        } else {
          tx.update(docRef, {
            'likes': FieldValue.arrayUnion([uid]),
          });
        }
      }
    });
  }

  bool _filtrarPorFecha(DateTime? fecha) {
    if (fecha == null) return true;
    final ahora = DateTime.now();
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);
    final dia = DateTime(fecha.year, fecha.month, fecha.day);
    final diff = hoy.difference(dia).inDays;
    switch (_filtroTiempo) {
      case 'hoy':
        return diff == 0;
      case 'ayer':
        return diff == 1;
      case 'anteayer':
        return diff == 2;
      case 'fecha':
        if (_fechaSeleccionada == null) return true;
        final sel = DateTime(
          _fechaSeleccionada!.year,
          _fechaSeleccionada!.month,
          _fechaSeleccionada!.day,
        );
        return sel == dia;
      default:
        return true;
    }
  }

  List<QueryDocumentSnapshot> _aplicarFiltro(List<QueryDocumentSnapshot> docs) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return docs;
    return docs.where((d) {
      final data = d.data() as Map<String, dynamic>;
      final fecha = (data['fecha'] as Timestamp?)?.toDate();
      if (!_filtrarPorFecha(fecha)) return false;
      switch (_filtro) {
        case 'likes':
          return List.from(data['likes'] ?? []).contains(user.uid);
        case 'comentados':
          return data['uid'] == user.uid;
        case 'compartidos':
          return (data['shares'] ?? 0) > 0;
        case 'guardados':
          return _guardados.contains(d.id);
        default:
          return true;
      }
    }).toList();
  }

  Widget _chip(String valor, IconData icon, String texto) {
    final activo = _filtro == valor;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        selectedColor: Colors.teal.shade100,
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 4),
            Text(texto),
          ],
        ),
        selected: activo,
        onSelected: (_) => setState(() => _filtro = valor),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Comentarios'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.teal,
        elevation: 1,
      ),
      body: Column(
        children: [
          // 🔹 Filtros
          Container(
            color: Colors.teal.shade50,
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                DropdownButton<String>(
                  value: _filtroTiempo,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(value: 'todos', child: Text('Todos')),
                    DropdownMenuItem(value: 'hoy', child: Text('Hoy')),
                    DropdownMenuItem(value: 'ayer', child: Text('Ayer')),
                    DropdownMenuItem(
                      value: 'anteayer',
                      child: Text('Anteayer'),
                    ),
                    DropdownMenuItem(
                      value: 'fecha',
                      child: Text('Elegir otra fecha'),
                    ),
                  ],
                  onChanged: (v) async {
                    if (v == 'fecha') {
                      final f = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (f != null) {
                        setState(() {
                          _filtroTiempo = 'fecha';
                          _fechaSeleccionada = f;
                        });
                      }
                    } else if (v != null) {
                      setState(() => _filtroTiempo = v);
                    }
                  },
                ),
                const SizedBox(height: 5),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _chip('todos', Icons.all_inclusive, 'Todos'),
                      _chip('likes', Icons.favorite, 'Likes'),
                      _chip('comentados', Icons.comment, 'Mis comentarios'),
                      _chip('compartidos', Icons.share, 'Compartidos'),
                      _chip('guardados', Icons.bookmark, 'Guardados'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 🔹 Lista de comentarios
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _comentariosRef
                  .orderBy('fecha', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = _aplicarFiltro(snapshot.data!.docs);
                if (docs.isEmpty) {
                  return const Center(child: Text('Sin resultados.'));
                }
                return ListView.builder(
                  controller: _scrollController,
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final d = docs[i];
                    final data = d.data() as Map<String, dynamic>;
                    final esMio = data['uid'] == user?.uid;
                    return CommentTile(
                      docId: d.id,
                      texto: data['texto'] ?? '',
                      autor: data['autor'] ?? 'Anónimo',
                      fecha: (data['fecha'] as Timestamp?)?.toDate(),
                      mediaUrl: data['mediaUrl'],
                      mediaType: data['mediaType'],
                      likes: List<String>.from(data['likes'] ?? []),
                      dislikes: List<String>.from(data['dislikes'] ?? []),
                      shares: data['shares'] ?? 0,
                      onLike: () => _toggleReaction(d.id, true),
                      onComment: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RepliesPage(
                            parentCommentId: d.id,
                            parentAuthor: data['autor'],
                          ),
                        ),
                      ),
                      onShare: () async {
                        await Share.share(data['texto'] ?? '');
                        _comentariosRef.doc(d.id).update({
                          'shares': FieldValue.increment(1),
                        });
                      },
                      onGuardar: () {
                        setState(() {
                          if (_guardados.contains(d.id)) {
                            _guardados.remove(d.id);
                          } else {
                            _guardados.add(d.id);
                          }
                          _guardarPersistente();
                        });
                      },
                      guardado: _guardados.contains(d.id),
                      esMio: esMio,
                      onEliminar: () =>
                          _eliminarComentario(d.id, data['mediaUrl']),
                    );
                  },
                );
              },
            ),
          ),

          // 🔹 Barra inferior (comentar)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.photo, color: Colors.teal),
                    onPressed: _pickImage,
                  ),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: _ctrl,
                          minLines: 1,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            hintText: 'Escribe un comentario...',
                            border: InputBorder.none,
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
                  _enviando
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
                          onPressed: _enviarComentario,
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

/* -------------------- CommentTile -------------------- */
class CommentTile extends StatelessWidget {
  final String docId;
  final String texto;
  final String autor;
  final DateTime? fecha;
  final String? mediaUrl;
  final String? mediaType;
  final List<String> likes;
  final List<String> dislikes;
  final int shares;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final Future<void> Function()? onShare;
  final VoidCallback onGuardar;
  final bool guardado;
  final bool esMio;
  final VoidCallback onEliminar;

  const CommentTile({
    super.key,
    required this.docId,
    required this.texto,
    required this.autor,
    required this.fecha,
    this.mediaUrl,
    this.mediaType,
    required this.likes,
    required this.dislikes,
    required this.shares,
    required this.onLike,
    required this.onComment,
    required this.onShare,
    required this.onGuardar,
    required this.guardado,
    required this.esMio,
    required this.onEliminar,
  });

  String _fechaBonita(DateTime? fecha) {
    if (fecha == null) return '';
    final hoy = DateTime.now();
    final diff = hoy
        .difference(DateTime(fecha.year, fecha.month, fecha.day))
        .inDays;
    final hora =
        '${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}';
    if (diff == 0) return 'Hoy $hora';
    if (diff == 1) return 'Ayer $hora';
    if (diff == 2) return 'Anteayer $hora';
    return '${fecha.day}/${fecha.month}/${fecha.year}';
  }

  @override
  Widget build(BuildContext context) {
    final hasLiked =
        FirebaseAuth.instance.currentUser != null &&
        likes.contains(FirebaseAuth.instance.currentUser!.uid);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.teal,
                  child: Icon(Icons.person, color: Colors.white),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    autor,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                if (fecha != null)
                  Text(
                    _fechaBonita(fecha),
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                if (esMio)
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (v) {
                      if (v == 'eliminar') onEliminar();
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'eliminar',
                        child: Text('Eliminar'),
                      ),
                    ],
                  ),
              ],
            ),
            if (texto.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(texto, style: const TextStyle(fontSize: 14)),
            ],
            if (mediaUrl != null && mediaType == 'image') ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(mediaUrl!, height: 180, fit: BoxFit.cover),
              ),
            ],
            const SizedBox(height: 6),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('comentarios')
                  .doc(docId)
                  .collection('respuestas')
                  .snapshots(),
              builder: (context, snap) {
                final repliesCount = snap.data?.docs.length ?? 0;
                return Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        hasLiked ? Icons.favorite : Icons.favorite_border,
                        color: hasLiked ? Colors.red : Colors.grey,
                      ),
                      onPressed: onLike,
                    ),
                    Text('${likes.length}'),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(
                        Icons.comment,
                        color: Colors.lightBlueAccent,
                      ),
                      onPressed: onComment,
                    ),
                    Text('$repliesCount'),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.share, color: Colors.green),
                      onPressed: onShare,
                    ),
                    Text('$shares'),
                    const Spacer(),
                    IconButton(
                      icon: Icon(
                        guardado ? Icons.bookmark : Icons.bookmark_border,
                        color: guardado ? Colors.amber : Colors.grey,
                      ),
                      onPressed: onGuardar,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
