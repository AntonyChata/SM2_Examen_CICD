import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../modelo/notificacion.dart';
import '../../servicios/notificacion_servicio.dart';

class NotificacionVM extends ChangeNotifier {
  final List<Notificacion> _notificaciones = [];
  List<Notificacion> get notificaciones => List.unmodifiable(_notificaciones);

  int _noLeidas = 0; // 🔹 contador de no leídas
  int get noLeidas => _noLeidas;

  StreamSubscription? _subs;

  /// 🔔 Escucha las notificaciones en tiempo real
  void escucharNotificaciones() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    _subs?.cancel(); // evita duplicar streams
    _subs = NotificacionServicio.obtenerNotificaciones(uid).listen((lista) {
      _notificaciones
        ..clear()
        ..addAll(lista);

      // 🔹 Calcula cuántas no están leídas
      _noLeidas = lista.where((n) => n.leido == false).length;
      notifyListeners();
    });
  }

  /// ✅ Marca todas las notificaciones como leídas
  Future<void> marcarTodasComoLeidas() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final batch = FirebaseFirestore.instance.batch();
    final query = await FirebaseFirestore.instance
        .collection('notificaciones')
        .where('usuarioId', isEqualTo: uid)
        .where('leido', isEqualTo: false)
        .get();

    for (var doc in query.docs) {
      batch.update(doc.reference, {'leido': true});
    }

    await batch.commit();

    _noLeidas = 0;
    notifyListeners();
  }

  /// 🚫 Detener la escucha
  void detenerEscucha() {
    _subs?.cancel();
    _subs = null;
  }
}
