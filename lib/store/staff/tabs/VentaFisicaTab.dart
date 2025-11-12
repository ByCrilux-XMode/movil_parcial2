import 'package:flutter/material.dart';
import 'package:movil_parcial2/store/staff/forms/AddVariantePage.dart';
class VentaFisicaTab extends StatefulWidget {
  const VentaFisicaTab({super.key});

  @override
  State<VentaFisicaTab> createState() => _VentaFisicaTabState();
}

class _VentaFisicaTabState extends State<VentaFisicaTab> {
  // TODO: Implementar lógica de venta física
  // 1. Un buscador de Clientes (para obtener clienteId)
  // 2. Un buscador de Productos/Variantes (para obtener prodVarianteId y precio)
  // 3. Un botón "Registrar Venta" que llame a POST /venta/venta
  //    enviando tipoVenta: "PRESENCIAL"
  // 4. Tras crear la Venta, registrar los DetalleVenta (POST /venta/detalle)

  void _navigateToAddVariante() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddVariantePage()),
    ).then((result) {
      if (result == true) {
        print("¡Variante añadida!");
        // Aquí podrías refrescar cualquier lista de variantes si la tuvieras
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.point_of_sale, size: 100, color: Colors.grey),
              const SizedBox(height: 20),
              Text(
                'Punto de Venta (Físico)',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const Text(
                'Esta sección permitirá registrar ventas presenciales.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              // Placeholder para la funcionalidad futura
              ElevatedButton.icon(
                onPressed: () {
                  // TODO: Iniciar flujo de búsqueda de cliente
                },
                icon: const Icon(Icons.search),
                label: const Text('Buscar Cliente'),
              ),
              ElevatedButton.icon(
                onPressed: _navigateToAddVariante,
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('Añadir Variante de Producto'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}