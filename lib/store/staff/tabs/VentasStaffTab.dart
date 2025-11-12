import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:movil_parcial2/settings/conf.dart';

class VentasStaffTab extends StatefulWidget {
  const VentasStaffTab({super.key});

  @override
  State<VentasStaffTab> createState() => _VentasStaffTabState();
}

class _VentasStaffTabState extends State<VentasStaffTab> {
  List<dynamic> _sales = [];
  bool _loading = true;
  @override
  void initState() {
    super.initState();
    _fetchStaffSales();
  }

  Future<void> _fetchStaffSales() async {
    setState(() {
      _loading = true;
    });

    try {
      final token = await Config().obtenerDato('token');
      final vendedorId = await Config().obtenerDato('id'); // ID del staff logueado

      // Endpoint para ventas POR VENDEDOR
      final url =
      Uri.parse('${Config.baseUrl}/venta/venta/porvendedor/$vendedorId');
      print("aqui se stan cargando");

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      print(response.body);
      if (response.statusCode == 200) {
        setState(() {
          _sales = jsonDecode(response.body);
          _loading = false;
        });
      } else {
        throw Exception('Error al cargar las ventas: ${response.body}');
      }
    } catch (e) {
      setState(() {
        _loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_sales.isEmpty) {
      return const Center(
        child: Text(
          'Aún no has registrado ninguna venta.',
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchStaffSales,
      child: ListView.builder(
        itemCount: _sales.length,
        itemBuilder: (context, index) {
          final sale = _sales[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: ExpansionTile(
              title: Text(
                'Venta Nro: ${sale['numeroVenta']}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                  'Tipo: ${sale['tipoVenta']} - Total: ${sale['montoTotal']} Bs.- ${sale['estadoPedido']}',
                style: TextStyle(color: sale['estadoPedido'] == 'pendiente' ? Colors.deepOrange : Colors.green)),
              leading: Icon(
                sale['tipoVenta'] == 'Online' ? Icons.public : Icons.store,
                color: Colors.blueGrey,
              ),
              children: [
                _SaleDetailView(ventaId: sale['id']) // Widget de detalle
              ],
            ),
          );
        },
      ),
    );
  }
}

// -----------------------------------------------------------------
// WIDGET SECUNDARIO: Carga y muestra los productos de UNA Venta
// (Este código es idéntico al de Sales.dart)
// -----------------------------------------------------------------
class _SaleDetailView extends StatefulWidget {
  final int ventaId;

  const _SaleDetailView({required this.ventaId});

  @override
  State<_SaleDetailView> createState() => _SaleDetailViewState();
}

class _SaleDetailViewState extends State<_SaleDetailView> {
  Future<List<dynamic>>? _detailsFuture;

  @override
  void initState() {
    super.initState();
    _detailsFuture = _fetchSaleDetails(widget.ventaId);
  }

  Future<List<dynamic>> _fetchSaleDetails(int ventaId) async {
    final token = await Config().obtenerDato('token');
    // USA EL ENDPOINT QUE YA FUNCIONA
    final url =
    Uri.parse('${Config.baseUrl}/venta/detalle/porventa/$ventaId');
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error al cargar los detalles de la venta.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: _detailsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red))),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: Text('No se encontraron detalles.')),
          );
        }
        final details = snapshot.data!;
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: details.map((item) {
              // Hacemos la comprobación de nulos que corregimos antes
              final variante = item['prodVariante'];
              final producto = (variante != null) ? variante['producto'] : null;

              if (producto == null || variante == null) {
                return const ListTile(
                  leading: Icon(Icons.error_outline, color: Colors.red),
                  title: Text('Error: Datos de producto no disponibles', style: TextStyle(color: Colors.red)),
                );
              }

              return ListTile(
                title: Text(
                  producto['nombre'] ?? 'Nombre no disponible',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: Text(
                  'SKU: ${variante['sku'] ?? 'N/A'}\nCant: ${item['cantidad']} x ${item['precio_unit']} Bs.',
                ),
                trailing: Text(
                  '${item['subtotal']} Bs.',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                isThreeLine: true,
              );
            }).toList(),
          ),
        );
      },
    );
  }
}