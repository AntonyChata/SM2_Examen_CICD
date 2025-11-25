import 'package:cloud_firestore/cloud_firestore.dart';

class Comentario {
  final String id;
  final String texto;
  final String autor;
  final String uid;
  final DateTime fecha;
  final String? mediaUrl;
  final String? mediaType;
  final List<String> likes;
  final List<String> dislikes;
  final int shares;

  Comentario({
    required this.id,
    required this.texto,
    required this.autor,
    required this.uid,
    required this.fecha,
    this.mediaUrl,
    this.mediaType,
    required this.likes,
    required this.dislikes,
    required this.shares,
  });

  factory Comentario.fromMap(String id, Map<String, dynamic> data) {
    return Comentario(
      id: id,
      texto: data['texto'] ?? '',
      autor: data['autor'] ?? 'Anónimo',
      uid: data['uid'] ?? '',
      fecha: (data['fecha'] as Timestamp?)?.toDate() ?? DateTime.now(),
      mediaUrl: data['mediaUrl'],
      mediaType: data['mediaType'],
      likes: List<String>.from(data['likes'] ?? []),
      dislikes: List<String>.from(data['dislikes'] ?? []),
      shares: data['shares'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'texto': texto,
      'autor': autor,
      'uid': uid,
      'fecha': fecha,
      'mediaUrl': mediaUrl,
      'mediaType': mediaType,
      'likes': likes,
      'dislikes': dislikes,
      'shares': shares,
    };
  }
}
