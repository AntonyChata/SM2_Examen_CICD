import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../modelo/usuario.dart';
import '../../servicios/api_dni_servicio.dart';

class RegistroVM extends ChangeNotifier {
  final formKey = GlobalKey<FormState>();

  final nombreCtrl = TextEditingController();
  final correoCtrl = TextEditingController();
  final telefonoCtrl = TextEditingController();
  final claveCtrl = TextEditingController();
  final dniCtrl = TextEditingController();

  bool cargando = false;
  bool buscandoDni = false;
  String? error;

  final ApiDniServicio apiDni;

  RegistroVM({required this.apiDni});

  /// 🔎 Buscar datos por DNI en la API
  Future<bool> buscarYAutocompletarNombre() async {
    final dni = dniCtrl.text.trim();
    if (dni.isEmpty) {
      error = "Ingrese DNI";
      notifyListeners();
      return false;
    }

    buscandoDni = true;
    notifyListeners();

    final datos = await apiDni.consultarDni(dni);

    buscandoDni = false;

    if (datos == null) {
      error = "DNI no encontrado o error en el servicio";
      notifyListeners();
      return false;
    }

    final nombreCompleto = [
      datos['nombres'] ?? '',
      datos['ape_paterno'] ?? '',
      datos['ape_materno'] ?? '',
    ].where((s) => s.toString().trim().isNotEmpty).join(' ');

    nombreCtrl.text = nombreCompleto;

    error = null;
    notifyListeners();
    return true;
  }

  /// 📝 Registrar usuario
  Future<bool> registrarUsuario() async {
    if (!formKey.currentState!.validate()) return false;

    cargando = true;
    error = null;
    notifyListeners();

    try {
      final dni = dniCtrl.text.trim();

      // 1) Verificar duplicado por DNI
      final query = await FirebaseFirestore.instance
          .collection("usuarios")
          .where("dni", isEqualTo: dni)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        cargando = false;
        error = "El DNI ya está registrado en otra cuenta.";
        notifyListeners();
        return false;
      }

      // 2) Crear cuenta en Firebase Auth
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: correoCtrl.text.trim(),
        password: claveCtrl.text.trim(),
      );

      final uid = cred.user!.uid;

      // 3) Crear objeto Usuario
      final usuario = Usuario(
        id: uid,
        dni: dni,
        nombre: nombreCtrl.text.trim(),
        correo: correoCtrl.text.trim(),
        telefono: telefonoCtrl.text.trim(),
        rol: "usuario",
        estadoVerificado: false,
        estadoRol: "activo",
        fechaRegistro: DateTime.now(),
        fotoPerfil: null,
      );

      // 4) Guardar en Firestore
      await FirebaseFirestore.instance
          .collection("usuarios")
          .doc(uid)
          .set(usuario.toMap());

      // 🔥 Guardar token FCM del nuevo usuario
      try {
        final token = await FirebaseMessaging.instance.getToken();
        if (token != null) {
          await FirebaseFirestore.instance
              .collection('usuarios')
              .doc(uid)
              .update({'token': token});
        }
      } catch (e) {
        print("Error guardando token FCM: $e");
      }
      // 5) Enviar verificación
      await cred.user?.sendEmailVerification();

      cargando = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      error = e.message;
    } catch (e) {
      error = e.toString();
    }

    cargando = false;
    notifyListeners();
    return false;
  }
}
