import 'package:flutter_test/flutter_test.dart';
import 'package:sos_mascotas/utils/validator.dart';

void main() {
  group('Validator Tests', () {
    test('Validar Email', () {
      expect(Validator.isValidEmail('usuario@dominio.com'), isTrue);
      expect(Validator.isValidEmail('usuario.dominio.com'), isFalse);
      expect(Validator.isValidEmail(''), isFalse);
    });

    test('Seguridad Contraseña (>6 chars)', () {
      expect(Validator.isStrongPassword('1234567'), isTrue);
      expect(Validator.isStrongPassword('123456'), isFalse);
    });

    test('Calculadora Descuento', () {
      // 100 con 10% => 90.00
      expect(Validator.calcularDescuento(100, 10), 90.00);
      // 59.99 con 15% => 50.99 (redondeado a 2 decimales)
      expect(Validator.calcularDescuento(59.99, 15), 50.99);
    });

    test('Rango Válido (1..10)', () {
      expect(Validator.rangoValido(1), isTrue);
      expect(Validator.rangoValido(10), isTrue);
      expect(Validator.rangoValido(0), isFalse);
      expect(Validator.rangoValido(11), isFalse);
    });

    test('Texto a Mayúsculas', () {
      expect(Validator.capitalizar('hola mundo'), 'HOLA MUNDO');
      expect(Validator.capitalizar('MiXeD'), 'MIXED');
    });
  });
}
