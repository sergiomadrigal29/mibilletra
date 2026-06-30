class Categoria {
  final int? id;
  final String nombre;

  Categoria({this.id, required this.nombre});

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id_categoria': id,
      'nombre': nombre,
    };
  }

  factory Categoria.fromMap(Map<String, dynamic> map) {
    return Categoria(
      id: map['id_categoria'] as int?,
      nombre: map['nombre'] as String,
    );
  }
}
