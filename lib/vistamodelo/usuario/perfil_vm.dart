import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class PerfilVM extends ChangeNotifier {
  final nombreCtrl = TextEditingController();
  final correoCtrl = TextEditingController();
  final telefonoCtrl = TextEditingController();
  final ubicacionCtrl = TextEditingController();

  String? fotoUrl;
  bool cargando = true;

  bool notificacionesPush = true;
  bool alertasEmail = false;

  PerfilVM() {
    cargarPerfil();
  }

  Future<void> cargarPerfil() async {
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final doc = await FirebaseFirestore.instance
          .collection("usuarios")
          .doc(uid)
          .get();

      if (doc.exists) {
        final d = doc.data()!;
        nombreCtrl.text = d["nombre"] ?? "";
        correoCtrl.text = d["correo"] ?? "";
        telefonoCtrl.text = d["telefono"] ?? "";
        ubicacionCtrl.text = d["ubicacion"] ?? "";
        fotoUrl = d["fotoPerfil"];
      }
    } finally {
      cargando = false;
      notifyListeners();
    }
  }

  Future<void> guardar() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance.collection("usuarios").doc(uid).update({
      "telefono": telefonoCtrl.text.trim(),
      "ubicacion": ubicacionCtrl.text.trim(),
      "fotoPerfil": fotoUrl ?? "",
    });

    notifyListeners();
  }

  Future<void> cambiarFoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final uid = FirebaseAuth.instance.currentUser!.uid;
    final ref = FirebaseStorage.instance.ref().child(
      "usuarios/$uid/perfil.jpg",
    );

    await ref.putFile(File(picked.path));
    final url = await ref.getDownloadURL();

    fotoUrl = url;
    await FirebaseFirestore.instance.collection("usuarios").doc(uid).update({
      "fotoPerfil": url,
    });

    notifyListeners();
  }

  Future<void> enviarResetPassword() async {
    final correo = correoCtrl.text.trim();
    if (correo.isNotEmpty) {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: correo);
    }
  }

  Future<void> eliminarCuenta() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance.collection("usuarios").doc(uid).delete();
    await FirebaseAuth.instance.currentUser!.delete();
  }

  @override
  void dispose() {
    nombreCtrl.dispose();
    correoCtrl.dispose();
    telefonoCtrl.dispose();
    ubicacionCtrl.dispose();
    super.dispose();
  }
}
