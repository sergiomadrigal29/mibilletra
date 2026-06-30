class Movimiento {
  final int? id;
  final int idUsuario;
  final int idCategoria;
  final int idTipo;
  final double monto;
  final String? descripcion;
  final DateTime fecha;
  final String? categoriaNombre;
  final String? tipoNombre;

  Movimiento({
    this.id,
    required this.idUsuario,
    required this.idCategoria,
    required this.idTipo,
    required this.monto,
    this.descripcion,
    DateTime? fecha,
    this.categoriaNombre,
    this.tipoNombre,
  }) : fecha = fecha ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id_movimiento': id,
      'id_usuario': idUsuario,
      'id_categoria': idCategoria,
      'id_tipo': idTipo,
      'monto': monto,
      'descripcion': descripcion,
      'fecha': fecha.toIso8601String(),
    };
  }

  factory Movimiento.fromMap(Map<String, dynamic> map) {
    return Movimiento(
      id: map['id_movimiento'] as int?,
      idUsuario: map['id_usuario'] as int,
      idCategoria: map['id_categoria'] as int,
      idTipo: map['id_tipo'] as int,
      monto: (map['monto'] as num).toDouble(),
      descripcion: map['descripcion'] as String?,
      fecha: DateTime.tryParse(map['fecha']?.toString() ?? '') ?? DateTime.now(),
      categoriaNombre: map['categoria_nombre'] as String?,
      tipoNombre: map['tipo_nombre'] as String?,
    );
  }
}
