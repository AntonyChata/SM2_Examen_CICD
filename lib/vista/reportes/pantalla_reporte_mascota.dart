import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:sos_mascotas/vista/reportes/pantalla_mapa_osm.dart';
import 'package:video_player/video_player.dart';
import '../../vistamodelo/reportes/reporte_vm.dart';
import 'video_recorte_page.dart';

class PantallaReporteMascota extends StatelessWidget {
  const PantallaReporteMascota({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ReporteMascotaVM(),
      child: const _WizardReporte(),
    );
  }
}

class _WizardReporte extends StatelessWidget {
  const _WizardReporte();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ReporteMascotaVM>();

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB), // Fondo gris moderno
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: AppBar(
          backgroundColor: Colors.white,
          elevation: 1,
          centerTitle: true,
          title: Column(
            children: [
              Text(
                "Reportar Mascota Perdida",
                style: Theme.of(context).textTheme.titleMedium!.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Paso ${vm.paso + 1} de 3",
                style: const TextStyle(color: Color(0xFF6366F1), fontSize: 14),
              ),
              const SizedBox(height: 8),
              // Barra de progreso con degradado
              Container(
                height: 6,
                width: MediaQuery.of(context).size.width * 0.6,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.grey[200],
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final width = (vm.paso + 1) / 3 * constraints.maxWidth;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      width: width,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFF2563EB)],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      body: IndexedStack(
        index: vm.paso,
        children: const [Paso1Mascota(), Paso2Ubicacion(), Paso3Resumen()],
      ),
    );
  }
}

/// 🔹 Paso 1: Fotos/Videos + datos básicos
class Paso1Mascota extends StatelessWidget {
  const Paso1Mascota({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ReporteMascotaVM>();
    //final picker = ImagePicker();

    return Form(
      key: vm.formKeyPaso1,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 📸 Foto de tu mascota
            // 📸 Foto y video de tu mascota
            _sectionTitle("Foto de tu mascota"),
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 🖼️ Previsualización (si hay fotos o videos)
                  if (vm.fotos.isNotEmpty || vm.videos.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ...vm.fotos.map(
                            (f) => ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: f.startsWith('http')
                                  ? Image.network(
                                      f,
                                      height: 80,
                                      width: 80,
                                      fit: BoxFit.cover,
                                    )
                                  : Image.file(
                                      File(f),
                                      height: 80,
                                      width: 80,
                                      fit: BoxFit.cover,
                                    ),
                            ),
                          ),
                          ...vm.videos.map(
                            (v) => Container(
                              height: 80,
                              width: 80,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.videocam_rounded,
                                size: 40,
                                color: Colors.orange,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // 🩶 Card principal estilo UI
                  GestureDetector(
                    onTap: () async {
                      final picker = ImagePicker();
                      final picked = await picker.pickImage(
                        source: ImageSource.gallery,
                      );

                      if (picked != null) {
                        try {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Analizando imagen... 🧠"),
                              backgroundColor: Colors.blueAccent,
                              duration: Duration(seconds: 2),
                            ),
                          );

                          final url = await vm.subirFoto(File(picked.path));
                          vm.agregarFoto(url);

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "✅ Imagen válida detectada y subida correctamente.",
                              ),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                e.toString().replaceAll("Exception: ", ""),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                        }
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 30),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.grey[300]!,
                          width: 1.2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt_rounded,
                              size: 28,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            "Agregar foto o video de tu mascota",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            "Toca para seleccionar desde galería o cámara",
                            style: TextStyle(fontSize: 13, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 🎛️ Botones cámara, galería y video
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Cámara (foto)
                      ElevatedButton.icon(
                        onPressed: () async {
                          final picker = ImagePicker();
                          final picked = await picker.pickImage(
                            source: ImageSource.camera,
                          );
                          if (picked == null) return;

                          try {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Analizando imagen... 🧠"),
                                backgroundColor: Colors.blueAccent,
                                duration: Duration(seconds: 2),
                              ),
                            );

                            final url = await vm.subirFoto(File(picked.path));
                            vm.agregarFoto(url);

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "✅ Imagen válida detectada y subida correctamente.",
                                ),
                                backgroundColor: Colors.green,
                              ),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  e.toString().replaceAll("Exception: ", ""),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.camera_alt_outlined, size: 18),
                        label: const Text("Cámara"),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: const Color(0xFF2563EB),
                          backgroundColor: const Color(0xFFEFF6FF),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Galería (foto)
                      ElevatedButton.icon(
                        onPressed: () async {
                          final picker = ImagePicker();
                          final picked = await picker.pickImage(
                            source: ImageSource.gallery,
                          );
                          if (picked == null) return;

                          try {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Analizando imagen... 🧠"),
                                backgroundColor: Colors.blueAccent,
                                duration: Duration(seconds: 2),
                              ),
                            );

                            final url = await vm.subirFoto(File(picked.path));
                            vm.agregarFoto(url);

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "✅ Imagen válida detectada y subida correctamente.",
                                ),
                                backgroundColor: Colors.green,
                              ),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  e.toString().replaceAll("Exception: ", ""),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                          }
                        },
                        icon: const Icon(
                          Icons.photo_library_outlined,
                          size: 18,
                        ),
                        label: const Text("Galería"),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: const Color(0xFF7C3AED),
                          backgroundColor: const Color(0xFFF5F3FF),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Video
                      ElevatedButton.icon(
                        onPressed: () async {
                          final picker = ImagePicker();
                          final pickedVideo = await picker.pickVideo(
                            source: ImageSource.gallery,
                          );
                          if (pickedVideo != null) {
                            final file = File(pickedVideo.path);
                            final controller = VideoPlayerController.file(file);
                            await controller.initialize();
                            final duracion = controller.value.duration;
                            await controller.dispose();

                            if (duracion.inSeconds <= 10) {
                              final url = await vm.subirVideo(file);
                              vm.agregarVideo(url);
                            } else {
                              if (context.mounted) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        ChangeNotifierProvider.value(
                                          value: vm,
                                          child: VideoRecortePage(
                                            videoFile: file,
                                          ),
                                        ),
                                  ),
                                );
                              }
                            }
                          }
                        },
                        icon: const Icon(Icons.videocam_outlined, size: 18),
                        label: const Text("Video"),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: const Color(0xFFEA580C),
                          backgroundColor: const Color(0xFFFFF7ED),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _sectionTitle("Información de la mascota"),
            _input(
              "Nombre de la mascota",
              onChanged: (v) => vm.reporte.nombre = v,
              validator: (v) =>
                  (v == null || v.isEmpty) ? "Ingrese el nombre" : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField(
              decoration: _inputDecoration("Tipo de mascota"),
              items: const [
                DropdownMenuItem(value: "Perro", child: Text("🐶 Perro")),
                DropdownMenuItem(value: "Gato", child: Text("🐱 Gato")),
                DropdownMenuItem(value: "Otro", child: Text("🐾 Otro")),
              ],
              onChanged: (v) => vm.reporte.tipo = v!,
              validator: (v) =>
                  v == null || v.isEmpty ? "Seleccione un tipo" : null,
            ),
            const SizedBox(height: 12),
            _input(
              "Raza",
              onChanged: (v) => vm.reporte.raza = v,
              validator: (v) =>
                  (v == null || v.isEmpty) ? "Ingrese la raza" : null,
            ),
            const SizedBox(height: 12),
            _input(
              "Características especiales",
              maxLines: 3,
              onChanged: (v) => vm.reporte.caracteristicas = v,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _outlinedNavButton("Atrás", onTap: vm.pasoAnterior),
                _gradientNavButton(
                  "Continuar",
                  onTap: () {
                    if (vm.fotos.isEmpty && vm.videos.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Debes agregar al menos una foto o video",
                          ),
                        ),
                      );
                      return;
                    }
                    if (vm.formKeyPaso1.currentState!.validate()) {
                      vm.siguientePaso();
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 🔹 Paso 2: Ubicación
class Paso2Ubicacion extends StatelessWidget {
  const Paso2Ubicacion({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ReporteMascotaVM>();
    final fechaCtrl = TextEditingController(text: vm.reporte.fechaPerdida);
    final horaCtrl = TextEditingController(text: vm.reporte.horaPerdida);
    final direccionCtrl = TextEditingController(text: vm.reporte.direccion);
    return Form(
      key: vm.formKeyPaso2,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _sectionTitle("📍 Lugar y momento de pérdida"),

            // 🗓️ Fecha y hora
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: fechaCtrl,
                    readOnly: true,
                    decoration: _inputDecoration(
                      "Fecha de pérdida",
                    ).copyWith(suffixIcon: const Icon(Icons.calendar_today)),
                    onTap: () async {
                      final fecha = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );

                      if (fecha != null) {
                        // Guardar en el modelo y mostrar en el campo
                        vm.reporte.fechaPerdida =
                            "${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}";
                        fechaCtrl.text = vm.reporte.fechaPerdida;
                      }
                    },
                    validator: (v) =>
                        (v == null || v.isEmpty) ? "Seleccione la fecha" : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: horaCtrl,
                    readOnly: true,
                    decoration: _inputDecoration(
                      "Hora aproximada",
                    ).copyWith(suffixIcon: const Icon(Icons.access_time)),
                    onTap: () async {
                      final hora = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (hora != null) {
                        vm.reporte.horaPerdida =
                            "${hora.hour.toString().padLeft(2, '0')}:${hora.minute.toString().padLeft(2, '0')}";
                        horaCtrl.text = vm.reporte.horaPerdida;
                      }
                    },
                    validator: (v) =>
                        (v == null || v.isEmpty) ? "Seleccione la hora" : null,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 🌍 Seleccionar ubicación en mapa
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "🌍 Seleccionar ubicación en el mapa",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4D9EF6),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.map_outlined),
                    label: const Text("Abrir mapa interactivo"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4D9EF6),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      elevation: 2,
                    ),
                    onPressed: () async {
                      final resultado = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PantallaMapaOSM(),
                        ),
                      );

                      if (resultado != null) {
                        vm.reporte.direccion =
                            (resultado['direccion'] ?? '') as String;
                        vm.reporte.distrito =
                            (resultado['distrito'] ?? '') as String;

                        // Si lat/lng vienen como double, los asignamos directamente
                        vm.reporte.latitud = resultado['lat'] is num
                            ? (resultado['lat'] as num).toDouble()
                            : null;
                        vm.reporte.longitud = resultado['lng'] is num
                            ? (resultado['lng'] as num).toDouble()
                            : null;

                        direccionCtrl.text = vm.reporte.direccion;
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  if (vm.reporte.direccion.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "📍 Dirección seleccionada:",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          vm.reporte.direccion,
                          style: const TextStyle(color: Colors.black87),
                        ),
                        const SizedBox(height: 8),

                        if (vm.reporte.distrito.isNotEmpty)
                          Text(
                            "🏘️ Distrito: ${vm.reporte.distrito}",
                            style: const TextStyle(
                              color: Colors.blueAccent,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 🏠 Dirección y referencias adicionales
            TextFormField(
              controller: direccionCtrl,
              decoration:
                  _inputDecoration(
                    "Dirección (puedes editar si lo deseas)",
                  ).copyWith(
                    suffixIcon: IconButton(
                      icon: const Icon(
                        Icons.map_outlined,
                        color: Color(0xFF4D9EF6),
                      ),
                      onPressed: () async {
                        final resultado = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PantallaMapaOSM(),
                          ),
                        );

                        if (resultado != null) {
                          vm.reporte.direccion = resultado['direccion'] ?? '';
                          vm.reporte.distrito = resultado['distrito'] ?? '';
                          vm.reporte.latitud = resultado['lat'];
                          vm.reporte.longitud = resultado['lng'];

                          direccionCtrl.text =
                              vm.reporte.direccion; // 🧠 autocompleta
                        }
                      },
                    ),
                  ),
              onChanged: (v) => vm.reporte.direccion = v,
              validator: (v) =>
                  (v == null || v.isEmpty) ? "Ingrese la dirección" : null,
            ),
            const SizedBox(height: 8),
            if (vm.reporte.distrito.isNotEmpty)
              Row(
                children: [
                  const Icon(
                    Icons.location_city,
                    color: Colors.blueAccent,
                    size: 20,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "Distrito: ${vm.reporte.distrito}",
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.blueAccent,
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 12),
            _input(
              "Puntos de referencia",
              onChanged: (v) => vm.reporte.referencia = v,
            ),
            const SizedBox(height: 12),
            _input(
              "¿Cómo se perdió?",
              onChanged: (v) => vm.reporte.circunstancia = v,
              validator: (v) =>
                  (v == null || v.isEmpty) ? "Describa cómo se perdió" : null,
            ),

            const SizedBox(height: 24),

            // 🔘 Navegación
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _outlinedNavButton("Atrás", onTap: vm.pasoAnterior),
                _gradientNavButton(
                  "Continuar",
                  onTap: () {
                    if (vm.formKeyPaso2.currentState!.validate()) {
                      vm.siguientePaso();
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 🔹 Paso 3: Resumen + guardar
class Paso3Resumen extends StatelessWidget {
  const Paso3Resumen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ReporteMascotaVM>();
    final r = vm.reporte;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle("Resumen del reporte"),
          const SizedBox(height: 10),
          if (r.fotos.isNotEmpty)
            _card(
              child: SizedBox(
                height: 200,
                child: PageView.builder(
                  itemCount: r.fotos.length,
                  controller: PageController(viewportFraction: 0.9),
                  itemBuilder: (context, i) => ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(r.fotos[i], fit: BoxFit.cover),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 16),
          _infoRow("🐾 Nombre", r.nombre),
          _infoRow("📌 Tipo", "${r.tipo} • ${r.raza}"),
          _infoRow("📅 Perdido", "${r.fechaPerdida} a las ${r.horaPerdida}"),
          _infoRow("📍 Dirección", r.direccion),
          _infoRow("🧭 Referencia", r.referencia),
          _infoRow("📖 Características especiales", r.caracteristicas),
          const SizedBox(height: 20),
          _input(
            "Recompensa (opcional)",
            onChanged: (v) => r.recompensa = v,
            keyboard: TextInputType.number,
          ),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _outlinedNavButton("Atrás", onTap: vm.pasoAnterior),
              _gradientNavButton(
                vm.cargando ? "Guardando..." : "Publicar reporte",
                onTap: vm.cargando
                    ? null
                    : () async {
                        final ok = await vm.guardarReporte();
                        if (ok && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("✅ Reporte guardado con éxito"),
                            ),
                          );
                          Navigator.pop(context);
                        }
                      },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

//
// 🎨 Widgets de estilo moderno
//
Widget _sectionTitle(String text) => Padding(
  padding: const EdgeInsets.only(bottom: 8),
  child: Text(
    text,
    style: const TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: Colors.black87,
    ),
  ),
);

Widget _card({required Widget child}) => Card(
  color: Colors.white,
  elevation: 1,
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
  child: Padding(padding: const EdgeInsets.all(16), child: child),
);

InputDecoration _inputDecoration(String label) => InputDecoration(
  labelText: label,
  filled: true,
  fillColor: Colors.grey[100],
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(16),
    borderSide: BorderSide(color: Colors.grey[300]!),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(16),
    borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
  ),
);

Widget _input(
  String label, {
  required Function(String) onChanged,
  String? Function(String?)? validator,
  int maxLines = 1,
  TextInputType keyboard = TextInputType.text,
}) {
  return TextFormField(
    decoration: _inputDecoration(label),
    maxLines: maxLines,
    keyboardType: keyboard,
    onChanged: onChanged,
    validator: validator,
  );
}

Widget _infoRow(String label, String value) => Padding(
  padding: const EdgeInsets.symmetric(vertical: 6.0),
  child: Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text("$label: ", style: const TextStyle(fontWeight: FontWeight.bold)),
      Expanded(child: Text(value)),
    ],
  ),
);

Widget _outlinedNavButton(String text, {VoidCallback? onTap}) => OutlinedButton(
  onPressed: onTap,
  style: OutlinedButton.styleFrom(
    side: BorderSide(color: Colors.grey[300]!),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
  ),
  child: Text(
    text,
    style: const TextStyle(color: Colors.black87, fontSize: 16),
  ),
);

Widget _gradientNavButton(String text, {VoidCallback? onTap}) =>
    GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6366F1), Color(0xFF2563EB)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6366F1).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
