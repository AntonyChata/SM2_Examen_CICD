import 'dart:io';
import 'dart:math';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class ServicioTFLite {
  static Interpreter? _detectorAnimales;
  static Interpreter? _extractorEmbeddings;

  /// 🔹 Inicializa ambos modelos con soporte GPU
  static Future<void> inicializarModelos() async {
    final opciones = InterpreterOptions()..threads = 4; // CPU multi-hilo

    _detectorAnimales ??= await Interpreter.fromAsset(
      'assets/model/animales.tflite',
      options: opciones,
    );

    _extractorEmbeddings ??= await Interpreter.fromAsset(
      'assets/model/extractor_animales.tflite',
      options: opciones,
    );
  }

  /// 🔹 Detecta tipo de animal y devuelve etiqueta + probabilidad
  static Future<Map<String, dynamic>> detectarAnimal(File imagen) async {
    await inicializarModelos();

    final input = _preprocesarImagen(imagen, 224, 224);
    final output = List<double>.filled(3, 0.0).reshape([1, 3]);
    _detectorAnimales!.run(input, output);

    // 🔍 Etiquetas en orden alfabético de entrenamiento
    final etiquetas = ["gato", "otro", "perro"];
    final List<double> resultados = output[0].cast<double>();

    final maxValor = resultados.reduce((a, b) => a > b ? a : b);
    final pred = resultados.indexOf(maxValor);

    final etiqueta = etiquetas[pred];
    final confianza = maxValor;

    print("🔍 Salida del modelo: $output");
    print(
      "🐾 Clase predicha: $etiqueta (${(confianza * 100).toStringAsFixed(2)}%)",
    );

    return {"etiqueta": etiqueta, "confianza": confianza};
  }

  /// 🔹 Extrae el vector de características (embedding de 1280 dimensiones)
  static Future<List<double>> extraerEmbeddings(File imagen) async {
    await inicializarModelos();
    final input = _preprocesarImagen(imagen, 224, 224);

    final output = List.filled(1280, 0.0).reshape([1, 1280]);
    _extractorEmbeddings!.run(input, output);

    return output[0];
  }

  /// 🔹 Compara dos imágenes y devuelve la similitud coseno (0 a 1)
  static Future<double> compararImagenes(File img1, File img2) async {
    final emb1 = await extraerEmbeddings(img1);
    final emb2 = await extraerEmbeddings(img2);

    final dot = _productoPunto(emb1, emb2);
    final norma1 = sqrt(_productoPunto(emb1, emb1));
    final norma2 = sqrt(_productoPunto(emb2, emb2));

    final similitud = dot / (norma1 * norma2);
    return similitud.clamp(0.0, 1.0);
  }

  /// 🧩 Convierte una imagen en tensor 224x224x3 normalizado [0,1]
  static List<List<List<List<double>>>> _preprocesarImagen(
    File archivo,
    int width,
    int height,
  ) {
    final bytes = archivo.readAsBytesSync();
    img.Image? image = img.decodeImage(bytes);
    image = img.copyResize(image!, width: width, height: height);

    final input = List.generate(
      1,
      (_) => List.generate(
        height,
        (y) => List.generate(width, (x) {
          final pixel = image!.getPixel(x, y);
          final r = pixel.r / 255.0;
          final g = pixel.g / 255.0;
          final b = pixel.b / 255.0;
          return [r, g, b];
        }),
      ),
    );

    return input;
  }

  /// 🔹 Producto punto entre dos vectores
  static double _productoPunto(List<double> a, List<double> b) {
    double suma = 0;
    for (int i = 0; i < a.length; i++) {
      suma += a[i] * b[i];
    }
    return suma;
  }
}
