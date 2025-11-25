import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../vistamodelo/auth/login_vm.dart';

class PantallaLogin extends StatelessWidget {
  const PantallaLogin({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<LoginVM>();

    return Scaffold(
      backgroundColor: const Color(0xFFEAF0FB), // fondo azul muy suave
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 40),
              // Logo
              Column(
                children: const [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.pets, size: 40, color: Colors.teal),
                  ),
                  SizedBox(height: 12),
                  Text(
                    "SOS Mascota",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "Encuentra a tu mascota perdida",
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // Tarjeta de Login
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
                      const Text(
                        "Iniciar Sesión",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Campo Correo
                      TextFormField(
                        controller: vm.correoCtrl,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.email_outlined),
                          hintText: "tu@email.com",
                          labelText: "Correo electrónico",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (v) => v != null && v.contains('@')
                            ? null
                            : "Correo inválido",
                      ),
                      const SizedBox(height: 15),

                      // Campo Contraseña
                      TextFormField(
                        controller: vm.claveCtrl,
                        obscureText: true,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.lock_outline),
                          hintText: "********",
                          labelText: "Contraseña",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (v) => v != null && v.length >= 6
                            ? null
                            : "Mínimo 6 caracteres",
                      ),

                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(context, "/recuperar");
                          },
                          child: const Text(
                            "¿Olvidaste tu contraseña?",
                            style: TextStyle(color: Colors.teal),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Botón Entrar
                      ElevatedButton.icon(
                        icon: const Icon(Icons.login),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: vm.cargando
                            ? null
                            : () async {
                                final ruta = await vm.loginYDeterminarRuta();
                                if (!context.mounted) return;

                                if (ruta != null) {
                                  Navigator.pushReplacementNamed(context, ruta);
                                } else if (vm.error != null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(vm.error!)),
                                  );
                                }
                              },
                        label: vm.cargando
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text("Entrar"),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Registro
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("¿No tienes una cuenta? "),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, "/registro");
                    },
                    child: const Text("Registrarse"),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
