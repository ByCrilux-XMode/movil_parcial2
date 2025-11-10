class Marca{
  final int id;
  final String nombre;
  Marca({required this.id, required this.nombre});

  factory Marca.fromJson(Map<String, dynamic> json){
    return Marca(
      id: json['id'],
      nombre: json['nombre'],
    );
  }

}