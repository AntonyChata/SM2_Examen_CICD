import 'package:flutter/material.dart';

class PantallaRegistroEspecial extends StatelessWidget {
  const PantallaRegistroEspecial({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Registro de Veterinarios / Albergues")),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.build_circle_outlined, size: 80, color: Colors.teal),
              SizedBox(height: 20),
              Text(
                "Esta opción está en desarrollo",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 10),
              Text(
                "Próximamente podrá registrar veterinarias y albergues de animales. "
                "Por el momento, esta función no está disponible.",
                style: TextStyle(fontSize: 16, color: Colors.black54),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
