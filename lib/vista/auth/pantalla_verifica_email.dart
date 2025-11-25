import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../servicios/auth_servicio.dart';
import '../../servicios/firestore_servicio.dart';

class PantallaVerificaEmail extends StatefulWidget {
  const PantallaVerificaEmail({super.key});

  @override
  State<PantallaVerificaEmail> createState() => _PantallaVerificaEmailState();
}

class _PantallaVerificaEmailState extends State<PantallaVerificaEmail> {
  bool reenviando = false;
  bool comprobando = false;
  int cooldown = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    cooldown = 30;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (mounted) {
        setState(() {
          cooldown--;
          if (cooldown <= 0) {
            t.cancel();
          }
        });
      }
    });
  }

  Future<void> _reenviar() async {
    if (cooldown > 0) return;
    setState(() => reenviando = true);
    try {
      await AuthServicio().reenviarVerificacion();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Correo de verificación reenviado.')),
      );
      _startCooldown();
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo reenviar. Intente luego.')),
      );
    }
    setState(() => reenviando = false);
  }

  Future<void> _yaVerifique() async {
    setState(() => comprobando = true);
    try {
      final auth = AuthServicio();
      final fs = FirestoreServicio();
      await auth.recargarUsuario();

      if (auth.correoVerificado) {
        final uid = FirebaseAuth.instance.currentUser!.uid;
        await fs.actualizarEstadoVerificado(uid, true);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Correo verificado. ¡Bienvenido!')),
        );
        Navigator.pushReplacementNamed(context, "/login");
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Aún no está verificado. Revise su correo.'),
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error verificando estado.')),
      );
    }
    setState(() => comprobando = false);
  }

  @override
  Widget build(BuildContext context) {
    final email = FirebaseAuth.instance.currentUser?.email ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Verifique su correo')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.mark_email_unread_outlined, size: 72),
                const SizedBox(height: 16),
                Text(
                  'Hemos enviado un enlace de verificación a:',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  email,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Text(
                  'Abra su correo y haga clic en el enlace para activar su cuenta.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: comprobando ? null : _yaVerifique,
                  icon: comprobando
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.verified),
                  label: const Text('Ya verifiqué'),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: (reenviando || cooldown > 0) ? null : _reenviar,
                  child: reenviando
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          cooldown > 0
                              ? 'Reenviar en $cooldown s'
                              : 'Reenviar correo',
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
