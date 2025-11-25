class Validator {
  static bool isValidEmail(String value) {
    if (value.isEmpty) return false;
    return value.contains('@') && value.contains('.');
  }

  static bool isStrongPassword(String value) {
    return value.length > 6; // strictly greater than 6 per requirement
  }

  static double calcularDescuento(double precio, double porcentaje) {
    if (precio < 0) {
      throw ArgumentError('El precio no puede ser negativo');
    }
    if (porcentaje < 0 || porcentaje > 100) {
      throw ArgumentError('Porcentaje fuera de rango 0-100');
    }
    final descuento = precio * (porcentaje / 100);
    final resultado = precio - descuento;
    return double.parse(resultado.toStringAsFixed(2));
  }

  static bool rangoValido(int numero) {
    return numero >= 1 && numero <= 10;
  }

  static String capitalizar(String texto) {
    return texto.toUpperCase();
  }
}
