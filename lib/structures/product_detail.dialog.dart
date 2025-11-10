import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:movil_parcial2/settings/conf.dart';

class ProductDetailDialog extends StatefulWidget {
  final int productoId;
  final String productoNombre;

  const ProductDetailDialog({
    super.key,
    required this.productoId,
    required this.productoNombre,
  });

  @override
  State<ProductDetailDialog> createState() => _ProductDetailDialogState();
}

class _ProductDetailDialogState extends State<ProductDetailDialog> {
  bool _loading = true;
  List<Map<String, dynamic>> _variantes = [];
  int _cantidad = 1;
  @override
  void initState() {
    super.initState();
    _fetchVariantes();
  }

  Future<void> _fetchVariantes() async {
    final url = Uri.parse(
        '${Config.baseUrl}/inventario/prod-variante/producto/${widget.productoId}');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _variantes = data.map((v) {
            return {
              "id": v["id"],
              "color": v["color"]["nombre"],
              "talla": v["talla"]["talla"],
              "stock": v["stock"],
              "precio": v["precio"],
              "codHexa": v["color"]["codHexa"],
            };
          }).toList();
        });
      } else {
        throw Exception('Error al obtener variantes');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al cargar variantes: $e")),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _addToCart(Map<String, dynamic> variante, int cantidad) async {
    final url = Uri.parse('${Config.baseUrl}/venta/itemcarrito');
    final token = await Config().obtenerDato('token');
    final idCarrito = await Config().obtenerDato('idCarrito');
    final responde = await http.post(url,
        headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token'},
        body: jsonEncode({
        "carritoId": idCarrito,
        "prodVarianteId": variante["id"],
        "cantidad": cantidad,})
    );
    if (responde.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Variante ${variante["id"]} ${variante["color"]} (${variante["talla"]}) añadida al carrito",
          ),
        ),
      );
      Navigator.pop(context);
    }else{
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error")),
      );
      print("--------");
      print(responde.body);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.productoNombre),
      content: SizedBox(
        width: double.maxFinite,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _variantes.isEmpty
            ? const Text("No hay variantes disponibles")
            : ListView.builder(
          shrinkWrap: true,
          itemCount: _variantes.length,
          itemBuilder: (context, index) {
            final variante = _variantes[index];
            return Card(color: Colors.orange.shade300,
              margin: const EdgeInsets.symmetric(vertical: 5),
              child: Column(
                children: [
                  Text("Variante ${variante["id"]}"),
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Color(
                        int.parse(
                          variante["codHexa"].substring(1),
                          radix: 16,
                        ) +
                            0xFF000000,
                      ),
                    ),
                    title: Text(
                      "Color: ${variante["color"]} | Talla: ${variante["talla"]}",
                    ),
                    subtitle: Text(
                      "Stock: ${variante["stock"]} | Precio: \$${variante["precio"]}",
                    ),
                  ),
                  ElevatedButton(
                        onPressed: () => _addToCart(variante,_cantidad),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                        ),
                        child: const Text("Añadir",style: TextStyle(color: Colors.white)),
                  ),
                ],
              )
            );
          },
        ),
      ),
      actions: [
        Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(onPressed:(){
              setState(() {
                _cantidad++;
              });
            }, icon: Icon(Icons.add),iconSize: 40,

            ),
            Text(_cantidad.toString(),style: TextStyle(fontSize: 30)),
            IconButton(onPressed:(){
              if(_cantidad > 1){
                setState(() {
                  _cantidad--;
                });
              }
            }, icon: Icon(Icons.remove),iconSize: 40,

            )
          ],
        ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cerrar"),
        ),

      ],
    );
  }
}
