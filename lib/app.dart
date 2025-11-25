import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sos_mascotas/vista/mapa/pantalla_mapa_interactivo.dart';
import 'package:sos_mascotas/vista/usuario/pantalla_comentarios.dart';
import 'package:sos_mascotas/vista/usuario/pantalla_notificacion.dart';
import 'package:sos_mascotas/vistamodelo/notificacion/notificacion_vm.dart';

import 'vista/auth/pantalla_registro.dart';
import 'vista/auth/pantalla_login.dart';
import 'vista/auth/pantalla_recuperar.dart';
import 'vista/auth/pantalla_verifica_email.dart';

import 'vista/usuario/pantalla_inicio.dart';
import 'vista/usuario/pantalla_perfil.dart';

import 'vista/reportes/pantalla_reporte_mascota.dart';
import 'vista/reportes/pantalla_avistamiento.dart';
import 'vista/reportes/pantalla_ver_reportes.dart';
import 'vista/reportes/pantalla_mis_reportes.dart';

import 'vistamodelo/auth/recuperar_vm.dart';
import 'vistamodelo/auth/registro_vm.dart';
import 'vistamodelo/auth/login_vm.dart';
import 'servicios/api_dni_servicio.dart';
import 'vistamodelo/usuario/perfil_vm.dart';

final String bearer =
    "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoyOTUsImV4cCI6MTc1ODIzOTQxMX0.wX7JTrLUVGXvotDn376U462eIwzlA3PgzcM3sQ-mVX8";
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final api = ApiDniServicio(bearerToken: bearer);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SOS Mascota',
      navigatorKey: navigatorKey,
      theme: ThemeData(
        useMaterial3: true, // ✅ Activa Material 3
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4D9EF6), // 🎨 Color base azul moderno
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F6FA), // gris claro uniforme
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0.5,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
      initialRoute: "/login",
      routes: {
        "/login": (_) => ChangeNotifierProvider(
          create: (_) => LoginVM(),
          child: const PantallaLogin(),
        ),
        "/registro": (_) => ChangeNotifierProvider(
          create: (_) => RegistroVM(apiDni: api),
          child: const PantallaRegistro(),
        ),
        "/recuperar": (_) => ChangeNotifierProvider(
          create: (_) => RecuperarVM(),
          child: const PantallaRecuperar(),
        ),
        "/verificaEmail": (_) => const PantallaVerificaEmail(),
        "/perfil": (_) => ChangeNotifierProvider(
          create: (_) => PerfilVM(),
          child: const PantallaPerfil(),
        ),
        "/inicio": (_) => ChangeNotifierProvider(
          create: (_) => NotificacionVM()..escucharNotificaciones(),
          child: const PantallaInicio(),
        ),
        "/reportarMascota": (_) => const PantallaReporteMascota(),
        "/avistamiento": (_) => const PantallaAvistamiento(),
        "/verReportes": (_) => const PantallaVerReportes(),
        "/misReportes": (_) => const PantallaMisReportes(),
        "/notificaciones": (context) => ChangeNotifierProvider(
          create: (_) => NotificacionVM()..escucharNotificaciones(),
          child: const PantallaNotificaciones(),
        ),

        "/comentarios": (_) => const PantallaComentarios(),

        "/mapa": (context) => const PantallaMapaInteractivo(),
      },
    );
  }
}
