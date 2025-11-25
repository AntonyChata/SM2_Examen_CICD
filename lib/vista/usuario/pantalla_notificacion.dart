import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../vistamodelo/notificacion/notificacion_vm.dart';
import '../../modelo/notificacion.dart';

class PantallaNotificaciones extends StatefulWidget {
  const PantallaNotificaciones({super.key});

  @override
  State<PantallaNotificaciones> createState() => _PantallaNotificacionesState();
}

class _PantallaNotificacionesState extends State<PantallaNotificaciones> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final vm = context.read<NotificacionVM>();
      vm.escucharNotificaciones();

      // ✅ Marca todas como leídas al abrir la pantalla
      await vm.marcarTodasComoLeidas();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<NotificacionVM>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Notificaciones"),
        backgroundColor: Colors.teal,
      ),
      body: SafeArea(
        child: vm.notificaciones.isEmpty
            ? const Center(
                child: Text(
                  "No tienes notificaciones aún 🐾",
                  style: TextStyle(fontSize: 16),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: vm.notificaciones.length,
                itemBuilder: (context, index) {
                  final Notificacion n = vm.notificaciones[index];

                  // 🔹 Manejo seguro de fecha (por si viene nula)
                  String hora = "--:--";
                  if (n.fecha != null) {
                    final f = n.fecha!;
                    hora =
                        "${f.hour.toString().padLeft(2, '0')}:${f.minute.toString().padLeft(2, '0')}";
                  }

                  return Card(
                    elevation: 3,
                    margin: const EdgeInsets.symmetric(
                      vertical: 6,
                      horizontal: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: const Icon(
                        Icons.notifications_active,
                        color: Colors.teal,
                      ),
                      title: Text(
                        n.titulo,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        n.mensaje,
                        style: const TextStyle(fontSize: 14),
                      ),
                      trailing: Text(
                        hora,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  NotificacionVM? _vm;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _vm ??= context.read<NotificacionVM>();
  }

  @override
  void dispose() {
    _vm?.detenerEscucha();
    super.dispose();
  }
}
