import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../vistamodelo/auth/recuperar_vm.dart';

class PantallaRecuperar extends StatelessWidget {
  const PantallaRecuperar({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RecuperarVM>();

    return Scaffold(
      backgroundColor: const Color(0xFFEAF0FB), // igual que login y registro
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 40),

              // 🔑 Ícono de recuperación
              const CircleAvatar(
                radius: 40,
                backgroundColor: Colors.white,
                child: Icon(Icons.key, size: 40, color: Colors.teal),
              ),
              const SizedBox(height: 12),
              const Text(
                "Recuperar contraseña",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              const Text(
                "Ingresa tu correo y te enviaremos un enlace",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),

              const SizedBox(height: 30),

              // 📩 Tarjeta blanca
              Container(
                width: 340,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Form(
                  key: vm.formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Campo de correo
                      TextFormField(
                        controller: vm.correoCtrl,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.email_outlined),
                          labelText: "Correo electrónico",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (v) => v != null && v.contains('@')
                            ? null
                            : "Correo inválido",
                      ),
                      const SizedBox(height: 20),

                      // Botón enviar
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: vm.enviando
                            ? null
                            : () => vm.enviarCorreo(context),
                        child: vm.enviando
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                "Enviar enlace de recuperación",
                                style: TextStyle(color: Colors.white),
                              ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // 🔗 Volver al login
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("¿Recordaste tu contraseña? "),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushReplacementNamed(
                        context,
                        "/login",
                      ); // 👈 cambio aquí
                    },
                    child: const Text(
                      "Iniciar sesión",
                      style: TextStyle(color: Colors.teal),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
