<!-- Badge CI/CD Pipeline Status -->
![CI Status](https://github.com/AntonyChata/SM2_Examen_CICD/actions/workflows/ci-pipeline.yml/badge.svg)

# SOS Mascotas – Examen CI/CD

Proyecto en Flutter orientado a reportar y encontrar mascotas perdidas. Este README sirve como informe del Examen de DevOps Móvil (Automatización de Pruebas y Despliegue).

---
## 1. Datos del Alumno
**Nombre:** Antony Chata
**Carrera / Curso:** Desarrollo de Aplicaciones Móviles
**Tecnología usada:** Flutter (Dart)

## 2. Enlace al Repositorio
Repositorio público: https://github.com/AntonyChata/SM2_Examen_CICD

## 3. Objetivo del Pipeline
Implementar un flujo CI/CD automático que al hacer push o pull request a `main`:
1. Verifique lógica de negocio (tests unitarios).
2. Audite calidad del código (lint/análisis).
3. Compile y genere el APK listo para distribución.
4. Publique el artefacto (`.apk`) como descarga en la ejecución de Actions.

## 4. Funciones y Pruebas Implementadas
Archivo: `lib/utils/validator.dart`
| Función | Descripción | Criterio Test |
|---------|-------------|---------------|
| `isValidEmail` | Retorna true si contiene `@` y `.` | Emails válidos/ inválidos |
| `isStrongPassword` | Longitud > 6 | Cadenas 6 y 7 caracteres |
| `calcularDescuento` | Precio final tras aplicar % | Verificación numérica y redondeo |
| `rangoValido` | Número entre 1 y 10 | Bordes y fuera de rango |
| `capitalizar` | Texto a mayúsculas | Conversión completa |

Ubicación de tests: `test/validator_test.dart`.

## 5. Workflow de GitHub Actions
Archivo: `.github/workflows/ci-pipeline.yml`
Resumen de pasos:
- Checkout del código
- Setup Flutter (`subosito/flutter-action`) versión 3.19.0
- Instalación dependencias: `flutter pub get`
- Lint: `flutter analyze`
- Tests: `flutter test`
- Build: `flutter build apk --release`
- Artifact: publica `build/app/outputs/flutter-apk/*.apk`

## 6. Evidencia (Incluir Capturas)
Agrega aquí las imágenes (arrástralas o usa markdown) una vez ejecutado el pipeline en GitHub:

### 6.1 Badge Verde (Passing)
Inserta captura donde se vea el badge en verde.

### 6.2 Logs de Tests
Captura del paso "Run Unit Tests" mostrando los 5 tests pasando.

### 6.3 Lint Correcto
Captura del paso "Code Quality Check" sin errores fatales.

### 6.4 Artefacto APK
Captura de la sección "Artifacts" con el archivo `app-release` listo para descargar.

## 7. Cómo Ejecutar Localmente
```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --release
```
Resultado del build: `build/app/outputs/flutter-apk/app-release.apk`.

## 8. Creación y Publicación del Repositorio (Guía Rápida)
```bash
git init
git remote add origin https://github.com/AntonyChata/SM2_Examen_CICD.git
git add .
git commit -m "Inicio examen CI/CD"
git branch -M main
git push -u origin main
```

Verifica luego en GitHub: pestaña Actions debe mostrar la ejecución automática.

## 9. Exportar README a PDF
Opciones:
1. Usar extensión VS Code "Markdown PDF" (clic derecho > Export PDF).
2. Usar `pandoc`:
	```bash
	pandoc README.md -o Informe_Examen_CICD.pdf
	```
3. Imprimir desde navegador (vista previa markdown) a PDF.

## 10. Notas de Calidad
- Si el workflow falla (rojo) la nota es 0 según el enunciado; asegurar que los tests pasan localmente antes de push.
- No modificar manualmente el artifact en la ejecución; debe ser generado por el build.

## 11. Próximas Mejores Prácticas (Opcional)
- Añadir cobertura: `flutter test --coverage` y subir reporte.
- Firmado del APK con `keystore` y variantes release.
- Cache de dependencias (`actions/cache`) para acelerar pipeline.

---
## Recursos Flutter
- [Codelab Inicial](https://docs.flutter.dev/get-started/codelab)
- [Cookbook](https://docs.flutter.dev/cookbook)
- [Documentación Oficial](https://docs.flutter.dev/)

---

**Nota Importante:** Una vez que hagas push de estos cambios a GitHub, el pipeline se ejecutará automáticamente. Cuando termine exitosamente:
1. Toma captura del badge verde en el README de GitHub
2. Entra a la pestaña "Actions" y selecciona la ejecución más reciente
3. Captura los logs del paso "Run Unit Tests" mostrando los 5 tests pasando
4. Captura los logs del paso "Code Quality Check" sin errores
5. Al final de la página, en la sección "Artifacts", captura el archivo `app-release` disponible para descarga
6. Agrega todas las capturas en la sección 6 de este README
7. Exporta el README completo a PDF para entregarlo en la plataforma
