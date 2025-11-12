import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:movil_parcial2/settings/conf.dart';

// -----------------------------------------------------------------
// WIDGET PRINCIPAL: Muestra la lista de "Compras Pagadas"
// -----------------------------------------------------------------
class SalesPage extends StatefulWidget {
  const SalesPage({super.key});

  @override
  State<SalesPage> createState() => _SalesPageState();
}

class _SalesPageState extends State<SalesPage> {
  List<dynamic> _sales = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchPaidSales();
  }

  Future<void> _fetchPaidSales() async {
    setState(() {
      _loading = true;
    });

    try {
      final token = await Config().obtenerDato('token');
      final clienteId = await Config().obtenerDato('id');
      final url = Uri.parse(
          '${Config.baseUrl}/venta/venta/porclienteyestado?clienteId=$clienteId&estado=pagado');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _sales = jsonDecode(response.body);
          _loading = false;
        });
      } else {
        throw Exception('Error al cargar las compras: ${response.body}');
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
          'Aún no has realizado ninguna compra.',
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchPaidSales,
      child: ListView.builder(
        itemCount: _sales.length,
        itemBuilder: (context, index) {
          final sale = _sales[index];
          // Usamos ExpansionTile para mostrar el detalle al hacer clic
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: ExpansionTile(
              title: Text(
                'Compra Nro: ${sale['numeroVenta']}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                  'Fecha: ${sale['fechaVenta'].substring(0, 10)} - Total: ${sale['montoTotal']} Bs.'),
              leading: const Icon(Icons.receipt_long, color: Colors.green),
              children: [
                // Este widget carga y muestra los detalles (productos)
                // de esta venta específica.
                _SaleDetailView(ventaId: sale['id'])
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
    final url =
    Uri.parse('${Config.baseUrl}/venta/detalle/porventa/$ventaId');
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    print("AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA");
    print(response.body);
    print(response.statusCode);
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
            child: Center(
                child:
                Text('Error: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red))),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: Text('No se encontraron detalles.')),
          );
        }

        final details = snapshot.data!;

        // Construimos una lista (no editable) de los productos
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            // ---- INICIO DE LA MODIFICACIÓN ----
            children: details.map((item) {

              // 1. Obtenemos las variables de forma segura
              final variante = item['prodVariante'];
              final producto = (variante != null) ? variante['producto'] : null;

              // 2. Comprobamos si los datos son nulos
              if (producto == null || variante == null) {
                return const ListTile(
                  leading: Icon(Icons.error_outline, color: Colors.red),
                  title: Text('Error: Datos de producto no disponibles',
                      style: TextStyle(color: Colors.red)),
                );
              }

              // 3. Si todo está bien, construimos el widget
              return ListTile(
                title: Text(
                  producto['nombre'] ?? 'Nombre no disponible', // Añadimos '??' por si acaso
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: Text(
                  'SKU: ${variante['sku'] ?? 'N/A'}\nCant: ${item['cantidad']} x ${item['precio_unit']} Bs.',
                ),
                trailing: Text(
                  '${item['subtotal']} Bs.',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
                isThreeLine: true,
              );
            }).toList(),
            // ---- FIN DE LA MODIFICACIÓN ----
          ),
        );
      },
    );
  }
}