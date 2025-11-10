import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:movil_parcial2/settings/conf.dart';
import "package:movil_parcial2/structures/product_detail.dialog.dart";
class Store extends StatefulWidget {
  const Store({super.key});

  @override
  State<Store> createState() => _StoreState();
}

class _StoreState extends State<Store> {
  List<Map<String, dynamic>> _marcas = [];
  List<Map<String, dynamic>> _productos = [];
  int? _selectedMarcaId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchMarcas();
  }

  Future<void> _fetchMarcas() async {
    final url = Uri.parse('${Config.baseUrl}/producto/marca');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(response.body);
        setState(() {
          _marcas = jsonData.map((e) {
            return {"id": e["id"], "nombre": e["nombre"]};
          }).toList();

          // Marca por defecto (la primera)
          if (_marcas.isNotEmpty) {
            _selectedMarcaId = _marcas.first["id"];
            _fetchProductosByMarca(_selectedMarcaId!);
          }
        });
      } else {
        throw Exception('Error al cargar marcas');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al obtener marcas: $e")),
      );
    }
  }

  Future<void> _fetchProductosByMarca(int marcaId) async {
    setState(() => _isLoading = true);
    final url = Uri.parse('${Config.baseUrl}/producto/producto/marca/$marcaId');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(response.body);
        setState(() {
          _productos = jsonData.map((e) {
            return {
              "id": e["id"],
              "nombre": e["nombre"],
              "precio": e["precio"] ?? 0,
              "stock": e["stock"] ?? 0,
              "imagen": e["imagen"] ?? "",
            };
          }).toList();
        });
      } else {
        throw Exception('Error al obtener productos');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error al cargar productos")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _onMarcaChanged(int? marcaId) {
    if (marcaId != null) {
      setState(() {
        _selectedMarcaId = marcaId;
      });
      _fetchProductosByMarca(marcaId);
    }
  }

  ///diálogo con el ID del producto
  void _mostrarDetalleProducto(Map<String, dynamic> producto) {
    showDialog(
      context: context,
      builder: (context) => ProductDetailDialog(
        productoId: producto["id"],
        productoNombre: producto["nombre"],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(8.0),
          child: Text(
            "Filtrar:",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: DropdownButton<int>(
            isExpanded: true,
            hint: const Text("Selecciona una marca"),
            value: _selectedMarcaId,
            items: _marcas
                .map<DropdownMenuItem<int>>(
                  (marca) => DropdownMenuItem<int>(
                value: marca["id"] as int,
                child: Text(marca["nombre"]),
              ),
            )
                .toList(),
            onChanged: _onMarcaChanged,
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _productos.isEmpty
              ? const Center(child: Text("No hay productos disponibles"))
              : GridView.builder(
            padding: const EdgeInsets.all(10),
            gridDelegate:
            const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.75,
            ),
            itemCount: _productos.length,
            itemBuilder: (context, index) {
              final producto = _productos[index];
              return GestureDetector(
                onTap: () => _mostrarDetalleProducto(producto),
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: producto["imagen"] != ""
                            ? Image.network(
                          producto["imagen"],
                          fit: BoxFit.cover,
                        )
                            : Container(
                          color: Colors.grey[300],
                          child: const Icon(
                            Icons.image_not_supported,
                            size: 50,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Text(
                              producto["nombre"] ?? "Producto",
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold),
                            ),
                            Text(
                              "Precio: \$${producto["precio"]}",
                              style: const TextStyle(
                                  color: Colors.green),
                            ),
                            Text("Stock: ${producto["stock"]}"),
                            const SizedBox(height: 5),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}


