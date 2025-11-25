class Avistamiento {
  String id;
  String reporteId; // opcional, si se relaciona a un reporte de pérdida
  String usuarioId;
  String foto;
  String direccion;
  String distrito;
  double? latitud;
  double? longitud;
  String fechaAvistamiento;
  String horaAvistamiento;
  String descripcion;

  Avistamiento({
    this.id = "",
    this.reporteId = "",
    this.usuarioId = "",
    this.foto = "",
    this.direccion = "",
    this.distrito = "",
    this.latitud,
    this.longitud,
    this.fechaAvistamiento = "",
    this.horaAvistamiento = "",
    this.descripcion = "",
  });

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "reporteId": reporteId,
      "usuarioId": usuarioId,
      "foto": foto,
      "direccion": direccion,
      "distrito": distrito,
      "latitud": latitud,
      "longitud": longitud,
      "fechaAvistamiento": fechaAvistamiento,
      "horaAvistamiento": horaAvistamiento,
      "descripcion": descripcion,
    };
  }

  factory Avistamiento.fromMap(Map<String, dynamic> map) {
    return Avistamiento(
      id: map["id"] ?? "",
      reporteId: map["reporteId"] ?? "",
      usuarioId: map["usuarioId"] ?? "",
      foto: map["foto"] ?? "",
      direccion: map["direccion"] ?? "",
      distrito: map["distrito"] ?? "",
      latitud: (map["latitud"] as num?)?.toDouble(),
      longitud: (map["longitud"] as num?)?.toDouble(),
      fechaAvistamiento: map["fechaAvistamiento"] ?? "",
      horaAvistamiento: map["horaAvistamiento"] ?? "",
      descripcion: map["descripcion"] ?? "",
    );
  }
}
