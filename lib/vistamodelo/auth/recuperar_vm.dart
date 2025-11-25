import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RecuperarVM extends ChangeNotifier {
  final correoCtrl = TextEditingController();
  final formKey = GlobalKey<FormState>();

  bool enviando = false;
  String? error;

  Future<void> enviarCorreo(BuildContext context) async {
    if (!formKey.currentState!.validate()) return;

    enviando = true;
    notifyListeners();

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: correoCtrl.text.trim(),
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Correo enviado. Revise su bandeja.')),
        );
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      error = e.message ?? 'Error enviando correo';
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error!)));
      }
    }

    enviando = false;
    notifyListeners();
  }

  @override
  void dispose() {
    correoCtrl.dispose();
    super.dispose();
  }
}
