import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'app.dart';

// 🔹 Importa el servicio TFLite
import 'package:sos_mascotas/servicios/servicio_tflite.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

/// 📨 Handler cuando el mensaje llega en background (solo Android/iOS)
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint(
    "📩 Mensaje recibido en background: ${message.notification?.title}",
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Inicializa Firebase con soporte multiplataforma
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  print("🚫 Firebase App Check desactivado para entorno de desarrollo.");

  // 🔹 Inicializa modelos TFLite al arrancar la app
  try {
    await ServicioTFLite.inicializarModelos();
    debugPrint("✅ Modelos TFLite inicializados correctamente");
  } catch (e) {
    debugPrint("⚠️ Error al inicializar modelos TFLite: $e");
  }

  // 🔔 Configuración de notificaciones solo en móviles
  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    final messaging = FirebaseMessaging.instance;

    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    debugPrint(
      '🔐 Permisos de notificaciones: ${settings.authorizationStatus}',
    );
    await messaging.subscribeToTopic("mascotas");

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    // 🧠 Handler de mensajes en background
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 📩 Escuchar mensajes en primer plano
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('🔔 Mensaje recibido: ${message.notification?.title}');
      if (message.notification != null) {
        flutterLocalNotificationsPlugin.show(
          0,
          message.notification!.title,
          message.notification!.body,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'default_channel',
              'Notificaciones SOS Mascota',
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
        );
      }
    });
  } else {
    debugPrint("🌐 Modo Web: notificaciones locales deshabilitadas.");
  }

  // 🧩 Actualizar token FCM del usuario autenticado (solo si está logueado)
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .update({'token': token});
      debugPrint("✅ Token actualizado para ${user.email}");
    }
  }

  runApp(const MyApp());
}
