import 'package:flutter/material.dart';

class PantallaDetalleReporte extends StatelessWidget {
  final String imagenUrl;
  final String titulo;

  const PantallaDetalleReporte({
    super.key,
    required this.imagenUrl,
    required this.titulo,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(titulo, style: const TextStyle(color: Colors.white)),
      ),
      body: Center(
        child: Hero(
          tag: imagenUrl,
          child: InteractiveViewer(
            child: Image.network(
              imagenUrl,
              fit: BoxFit.contain,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
