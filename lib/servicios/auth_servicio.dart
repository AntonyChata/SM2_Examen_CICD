import 'package:firebase_auth/firebase_auth.dart';

class AuthServicio {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String> registrar(String correo, String clave) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: correo,
      password: clave,
    );
    return cred.user!.uid;
  }

  // Enviar correo de verificación al usuario actual
  Future<void> enviarVerificacionCorreo() async {
    final user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  // Volver a cargar datos del usuario desde Firebase
  Future<void> recargarUsuario() async {
    final user = _auth.currentUser;
    if (user != null) await user.reload();
  }

  // ¿El correo ya fue verificado?
  bool get correoVerificado {
    final user = _auth.currentUser;
    return (user != null && user.emailVerified);
  }

  // Reenviar correo (igual a enviarVerificacionCorreo, separado por claridad)
  Future<void> reenviarVerificacion() => enviarVerificacionCorreo();

  // (Opcional) login que bloquea si no está verificado
  Future<User?> loginBloqueandoSiNoVerificado(
    String correo,
    String clave,
  ) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: correo,
      password: clave,
    );
    await cred.user?.reload();
    if (cred.user != null && !cred.user!.emailVerified) {
      throw FirebaseAuthException(
        code: 'email-not-verified',
        message: 'Debe verificar su correo antes de continuar.',
      );
    }

    return cred.user;
  }
}
