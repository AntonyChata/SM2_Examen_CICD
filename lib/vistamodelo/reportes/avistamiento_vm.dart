import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:sos_mascotas/app.dart';
import 'package:sos_mascotas/servicios/notificacion_servicio.dart';
import 'package:sos_mascotas/servicios/servicio_tflite.dart';
import '../../modelo/avistamiento.dart';

class AvistamientoVM extends ChangeNotifier {
  Avistamiento avistamiento = Avistamiento();
  bool _cargando = false;

  bool get cargando => _cargando;

  void setDireccion(String v) => avistamiento.direccion = v;
  void setDescripcion(String v) => avistamiento.descripcion = v;

  // 🔧 Comprimir imagen antes de subir
  Future<File> _comprimirImagen(File archivo) async {
    final dir = await getTemporaryDirectory();
    final targetPath =
        "${dir.absolute.path}/${DateTime.now().millisecondsSinceEpoch}.jpg";

    final result = await FlutterImageCompress.compressAndGetFile(
      archivo.absolute.path,
      targetPath,
      quality: 70,
    );

    return result != null ? File(result.path) : archivo;
  }

  // 📸 Subir foto con validación local (modelo TFLite)
  Future<String> subirFoto(File archivo) async {
    final comprimido = await _comprimirImagen(archivo);

    final resultado = await ServicioTFLite.detectarAnimal(comprimido);
    final tipo = resultado["etiqueta"];
    final confianza = (resultado["confianza"] * 100).toStringAsFixed(2);

    if (tipo == "otro" || resultado["confianza"] < 0.6) {
      throw Exception(
        "⚠️ No se detectó una mascota con claridad (confianza: $confianza%).",
      );
    }

    // 🔔 Mostrar mensaje informativo
    ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
      SnackBar(
        content: Text("🐾 Se detectó un $tipo ($confianza%)"),
        backgroundColor: Colors.green.shade700,
        duration: const Duration(seconds: 3),
      ),
    );

    final uid = FirebaseAuth.instance.currentUser!.uid;
    final ref = FirebaseStorage.instance
        .ref()
        .child("avistamientos")
        .child(uid)
        .child("${DateTime.now().millisecondsSinceEpoch}.jpg");

    await ref.putFile(comprimido);
    return await ref.getDownloadURL();
  }

  // 💾 Guardar el avistamiento en Firestore
  Future<bool> guardarAvistamiento() async {
    try {
      _cargando = true;
      notifyListeners();

      final uid = FirebaseAuth.instance.currentUser!.uid;
      final docRef = FirebaseFirestore.instance
          .collection("avistamientos")
          .doc();

      avistamiento.id = docRef.id;
      avistamiento.usuarioId = uid;

      avistamiento.direccion = avistamiento.direccion.trim();
      avistamiento.distrito = avistamiento.distrito.trim();

      await docRef.set(
        avistamiento.toMap()
          ..addAll({"fechaRegistro": FieldValue.serverTimestamp()}),
      );

      // 🔍 Intentar vincular con algún reporte de mascota perdida
      await _buscarCoincidenciaConReportes(avistamiento);

      // 🔔 Notificación push global
      await NotificacionServicio.enviarPush(
        titulo: "Nuevo avistamiento 👀",
        cuerpo: "Se ha registrado un nuevo avistamiento de mascota.",
      );

      _cargando = false;
      notifyListeners();
      return true;
    } catch (e) {
      _cargando = false;
      notifyListeners();
      debugPrint("❌ Error al guardar avistamiento: $e");
      return false;
    }
  }

  // 🔹 Calcular distancia entre coordenadas (Haversine)
  double _calcularDistancia(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const R = 6371; // Radio de la Tierra en km
    final dLat = _gradosARadianes(lat2 - lat1);
    final dLon = _gradosARadianes(lon2 - lon1);
    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_gradosARadianes(lat1)) *
            cos(_gradosARadianes(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double _gradosARadianes(double grados) => grados * pi / 180.0;

  // 🔍 Buscar coincidencia entre avistamiento y reportes cercanos
  Future<void> _buscarCoincidenciaConReportes(Avistamiento av) async {
    try {
      final reportes = await FirebaseFirestore.instance
          .collection("reportes_mascotas")
          .where("estado", isEqualTo: "perdido")
          .get();

      for (var doc in reportes.docs) {
        final data = doc.data();
        final fotos = List<String>.from(data["fotos"] ?? []);
        if (fotos.isEmpty) continue;

        final distancia = _calcularDistancia(
          av.latitud ?? 0,
          av.longitud ?? 0,
          (data["latitud"] ?? 0).toDouble(),
          (data["longitud"] ?? 0).toDouble(),
        );

        print("📍 Distancia con ${doc.id}: ${distancia.toStringAsFixed(2)} km");

        // Si está a más de 9 km, descartar
        if (distancia > 9.0) continue;

        // Descargar imágenes y comparar localmente
        final similitud = await _compararImagenes(av.foto, fotos.first);
        print("🤖 Similitud con ${doc.id}: $similitud");

        if (similitud >= 0.5) {
          await FirebaseFirestore.instance
              .collection("avistamientos")
              .doc(av.id)
              .update({"reporteId": doc.id});

          final usuarioId = data["usuarioId"];
          await _notificarCoincidencia(usuarioId, av.id);

          print("✅ Avistamiento vinculado con reporte ${doc.id}");
          break;
        }
      }
    } catch (e) {
      print("⚠️ Error al buscar coincidencias: $e");
    }
  }

  // 🧠 Comparar imágenes localmente usando embeddings TFLite
  Future<double> _compararImagenes(String url1, String url2) async {
    try {
      if (url1 == url2) return 1.0;
      final file1 = await _descargarImagen(url1);
      final file2 = await _descargarImagen(url2);
      return await ServicioTFLite.compararImagenes(file1, file2);
    } catch (e) {
      debugPrint("⚠️ Error comparando imágenes localmente: $e");
      return 0.0;
    }
  }

  // 📥 Descargar imagen desde URL temporalmente
  Future<File> _descargarImagen(String url) async {
    final response = await http.get(Uri.parse(url));
    final dir = await getTemporaryDirectory();
    final file = File(
      "${dir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg",
    );
    await file.writeAsBytes(response.bodyBytes);
    return file;
  }

  // 🔔 Notificar al dueño del reporte si hay coincidencia
  Future<void> _notificarCoincidencia(
    String usuarioId,
    String avistamientoId,
  ) async {
    try {
      await NotificacionServicio.enviarPush(
        titulo: "Posible coincidencia 🐾",
        cuerpo: "Tu mascota perdida podría haber sido vista recientemente.",
      );
    } catch (e) {
      debugPrint("Error enviando notificación de coincidencia: $e");
    }
  }

  // 🧩 Validar campos antes de guardar
  bool _esUbicacionValida(double? lat, double? lon) =>
      lat != null && lon != null && (lat != 0 || lon != 0);

  String? validarCampos() {
    final desc = avistamiento.descripcion.trim();
    final foto = avistamiento.foto.trim();

    if (desc.isEmpty) return 'La descripción no puede estar vacía';
    if (foto.isEmpty) return 'Debe adjuntar una foto del avistamiento';
    if (!_esUbicacionValida(avistamiento.latitud, avistamiento.longitud)) {
      return 'Debe seleccionar una ubicación válida';
    }
    return null;
  }

  // ✅ Actualizar ubicación
  void actualizarUbicacion({
    required String direccion,
    required String distrito,
    required double latitud,
    required double longitud,
  }) {
    avistamiento.direccion = direccion;
    avistamiento.distrito = distrito;
    avistamiento.latitud = latitud;
    avistamiento.longitud = longitud;
    notifyListeners();
  }
}
