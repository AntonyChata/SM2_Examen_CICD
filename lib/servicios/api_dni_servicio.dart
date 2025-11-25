import 'dart:convert';
import 'package:http/http.dart' as http;

/// Nota: NO pongas el token en el código en producción.
/// Usa Firebase Remote Config, Cloud Functions o variables de entorno.
class ApiDniServicio {
  final String baseUrl = "https://miapi.cloud/v1/dni";
  final String bearerToken; // inyectar desde VM o configuración

  ApiDniServicio({required this.bearerToken});

  Future<Map<String, dynamic>?> consultarDni(String dni) async {
    final uri = Uri.parse("$baseUrl/$dni");
    try {
      final resp = await http.get(
        uri,
        headers: {
          "Authorization": "Bearer $bearerToken",
          "Content-Type": "application/json",
        },
      );
      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body);
        if (body["success"] == true && body["datos"] != null) {
          return Map<String, dynamic>.from(body["datos"]);
        }
      }
      return null;
    } catch (e) {
      // log si hace falta
      return null;
    }
  }
}
