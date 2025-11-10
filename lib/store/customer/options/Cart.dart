import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:movil_parcial2/settings/conf.dart';

class CartPage extends StatefulWidget {
  const CartPage({Key? key}) : super(key: key);

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  List<dynamic> _items = [];
  bool _loading = true;
  bool _isUpdating  = false;

  @override
  void initState() {
    super.initState();
    _fetchCartItems();
  }

  Future<void> _fetchCartItems() async {
    final idCarrito = await Config().obtenerDato('idCarrito');
    final token = await Config().obtenerDato('token');
    final url = Uri.parse('${Config.baseUrl}/venta/itemcarrito/porcarrito/$idCarrito');

    final response = await http.get(url, headers: {
      'Authorization': 'Bearer $token',
    });

    if (response.statusCode == 200) {
      setState(() {
        _items = jsonDecode(response.body);
        _loading = false;
      });
    } else {
      setState(() {
        _items = [];
        _loading = false;
      });
    }
  }



  Future<void> _updateQuantity(int id, int newCantidad, int carritoId, int prodVarianteId) async {
    if (_isUpdating) return; // evita spam de clics seguidos
    setState(() {
      _isUpdating = true;
    });

    try {
      final token = await Config().obtenerDato('token');
      final url = Uri.parse('${Config.baseUrl}/venta/itemcarrito/$id');

      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'carritoId': carritoId,
          'prodVariableId': prodVarianteId,
          'cantidad': newCantidad,
        }),
      );

      if (response.statusCode == 200) {
        await _fetchCartItems(); // refresca la lista
      } else {
        print("Error al actualizar: ${response.statusCode}");
      }
    } catch (e) {
      print("Error: $e");
    } finally {
      setState(() {
        _isUpdating = false;
      });
    }
  }


  Future<void> _deleteItem(int id) async {
    final token = await Config().obtenerDato('token');
    final url = Uri.parse('${Config.baseUrl}/venta/itemcarrito/$id');

    final response = await http.delete(url, headers: {
      'Authorization': 'Bearer $token',
    });

    if (response.statusCode == 204) {
      setState(() {
        _items.removeWhere((item) => item['id'] == id);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: _items.isEmpty
          ? const Center(child: Text('Tu carrito está vacío.'))
          : ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: _items.length,
        itemBuilder: (context, index) {
          final item = _items[index];
          final producto = item['prodVariante']['producto'];
          final color = item['prodVariante']['color'];
          final talla = item['prodVariante']['talla'];
          final cantidad = item['cantidad'];
          final precio = item['prodVariante']['precio'];
          final total = precio * cantidad;

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.shopping_bag, size: 50),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          producto['nombre'],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text('Color: ${color['nombre']} (${color['codHexa']})'),
                        Text('Talla: ${talla['talla']}'),
                        Text('Precio: \$${precio.toStringAsFixed(2)}'),
                        Text('Total: \$${total.toStringAsFixed(2)}'),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed: _isUpdating || cantidad <= 1
                                  ? null
                                  : () => _updateQuantity(
                                item['id'],
                                cantidad - 1,
                                item['carritoId'],
                                item['prodVariante']['id'],
                              ),
                            ),
                            _isUpdating
                                ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                                : Text('$cantidad'),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: _isUpdating
                                  ? null
                                  : () => _updateQuantity(
                                item['id'],
                                cantidad + 1,
                                item['carritoId'],
                                item['prodVariante']['id'],
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: _isUpdating ? null : () => _deleteItem(item['id']),
                            ),
                          ],
                        )

                      ],
                    ),
                  ),
                ],
              ),
            ),
          );

        },
      ),
    );
  }
}
