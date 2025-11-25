import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_trimmer/video_trimmer.dart';
import '../../vistamodelo/reportes/reporte_vm.dart';

class VideoRecortePage extends StatefulWidget {
  final File videoFile;

  const VideoRecortePage({super.key, required this.videoFile});

  @override
  State<VideoRecortePage> createState() => _VideoRecortePageState();
}

class _VideoRecortePageState extends State<VideoRecortePage> {
  final Trimmer _trimmer = Trimmer();
  double _startValue = 0.0;
  double _endValue = 10.0;
  bool _cargando = false;

  @override
  void initState() {
    super.initState();
    _trimmer.loadVideo(videoFile: widget.videoFile);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.read<ReporteMascotaVM>();

    return SafeArea(
      // 👈 evita que el menú o notch tape el contenido
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Recortar video"),
          backgroundColor: Colors.teal,
        ),
        body: Column(
          children: [
            Expanded(child: VideoViewer(trimmer: _trimmer)),
            Center(
              child: TrimViewer(
                trimmer: _trimmer,
                viewerHeight: 50.0,
                viewerWidth: MediaQuery.of(context).size.width,
                maxVideoLength: const Duration(seconds: 10),
                onChangeStart: (value) => _startValue = value,
                onChangeEnd: (value) => _endValue = value,
                onChangePlaybackState: (playing) {},
              ),
            ),
            const SizedBox(height: 20),
            _cargando
                ? const CircularProgressIndicator()
                : ElevatedButton.icon(
                    icon: const Icon(Icons.check),
                    label: const Text("Guardar clip (≤10s)"),
                    onPressed: () async {
                      setState(() => _cargando = true);

                      await _trimmer.saveTrimmedVideo(
                        startValue: _startValue,
                        endValue: _endValue,
                        onSave: (outputPath) async {
                          if (outputPath != null) {
                            final fileClip = File(outputPath);

                            // Subir a Firebase
                            final url = await vm.subirVideo(fileClip);
                            vm.agregarVideo(url);

                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Video recortado y guardado ✅"),
                                ),
                              );
                              Navigator.pop(context);
                            }
                          }
                        },
                      );

                      setState(() => _cargando = false);
                    },
                  ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
