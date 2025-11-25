import 'package:cloud_firestore/cloud_firestore.dart';

class Notificacion {
  final String id;
  final String titulo;
  final String mensaje;
  final DateTime? fecha;
  final String usuarioId;
  final String tipo;
  final bool leido;

  Notificacion({
    required this.id,
    required this.titulo,
    required this.mensaje,
    required this.usuarioId,
    required this.tipo,
    this.fecha,
    this.leido = false,
  });

  factory Notificacion.fromMap(String id, Map<String, dynamic> data) {
    return Notificacion(
      id: id,
      titulo: data['titulo'] ?? '',
      mensaje: data['mensaje'] ?? '',
      usuarioId: data['usuarioId'] ?? '',
      tipo: data['tipo'] ?? '',
      leido: data['leido'] ?? false,
      fecha: (data['fecha'] is Timestamp)
          ? (data['fecha'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'titulo': titulo,
      'mensaje': mensaje,
      'usuarioId': usuarioId,
      'tipo': tipo,
      'leido': leido,
      'fecha': fecha ?? FieldValue.serverTimestamp(),
    };
  }
}
