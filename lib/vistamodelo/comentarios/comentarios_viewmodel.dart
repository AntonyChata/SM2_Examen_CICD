import 'package:cloud_firestore/cloud_firestore.dart';
import '../../modelo/comentario_model.dart';

class ComentariosViewModel {
  final CollectionReference _ref =
      FirebaseFirestore.instance.collection('comentarios');

  Stream<List<Comentario>> obtenerComentarios() {
    return _ref.orderBy('fecha', descending: true).snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) =>
              Comentario.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .toList();
    });
  }
}
