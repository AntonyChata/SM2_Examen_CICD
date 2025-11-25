import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../modelo/usuario.dart';

class LoginVM extends ChangeNotifier {
  final formKey = GlobalKey<FormState>();
  final correoCtrl = TextEditingController();
  final claveCtrl = TextEditingController();

  bool cargando = false;
  String? error;
  Future<void> guardarTokenFCM(String uid) async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await FirebaseFirestore.instance.collection('usuarios').doc(uid).update(
          {'token': token},
        );
        print("✅ Token FCM guardado para usuario: $uid");
      }
    } catch (e) {
      print("❌ Error al guardar token FCM: $e");
    }
  }

  Future<bool> login() async {
    if (!formKey.currentState!.validate()) return false;
    cargando = true;
    error = null;
    notifyListeners();

    try {
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: correoCtrl.text.trim(),
        password: claveCtrl.text.trim(),
      );

      await cred.user?.reload();
      if (cred.user != null && !cred.user!.emailVerified) {
        error = "Debe verificar su correo antes de continuar.";
        cargando = false;
        notifyListeners();
        return false;
      }

      cargando = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      error = (e.code == 'user-not-found')
          ? 'Usuario no existe'
          : (e.code == 'wrong-password')
          ? 'Contraseña incorrecta'
          : (e.message ?? 'Error al iniciar sesión');
      cargando = false;
      notifyListeners();
      return false;
    }
  }

  Future<String?> loginYDeterminarRuta() async {
    if (!formKey.currentState!.validate()) return null;
    cargando = true;
    error = null;
    notifyListeners();

    try {
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: correoCtrl.text.trim(),
        password: claveCtrl.text.trim(),
      );

      await cred.user?.reload();
      if (cred.user != null && !cred.user!.emailVerified) {
        error = "Debe verificar su correo antes de continuar.";
        cargando = false;
        notifyListeners();
        return null;
      }

      final uid = cred.user!.uid;

      // ✅ Guardar el token FCM del usuario actual
      await guardarTokenFCM(uid);

      // Cargar los datos del usuario
      final doc = await FirebaseFirestore.instance
          .collection("usuarios")
          .doc(uid)
          .get();

      // ✅ Usamos el modelo Usuario
      final usuario = Usuario.fromMap(doc.data() ?? {}, doc.id);

      cargando = false;
      notifyListeners();

      // 👇 ahora decidimos la ruta según su perfil
      if (usuario.fotoPerfil == null || usuario.fotoPerfil!.isEmpty) {
        return "/perfil";
      } else {
        return "/inicio";
      }
    } on FirebaseAuthException catch (e) {
      error = e.message;
      cargando = false;
      notifyListeners();
      return null;
    }
  }
}
