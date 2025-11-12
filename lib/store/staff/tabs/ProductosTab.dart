import 'package:flutter/material.dart';
// 1. Importa la nueva página del formulario
import 'package:movil_parcial2/store/staff/forms/AddProductoPage.dart';
import 'package:movil_parcial2/store/staff/forms/AddVariantePage.dart';
class ProductosTab extends StatefulWidget {
  const ProductosTab({super.key});

  @override
  State<ProductosTab> createState() => _ProductosTabState();
}

class _ProductosTabState extends State<ProductosTab> {

  // 2. Método para navegar a la página del formulario
  void _navigateToAddProducto() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddProductoPage()),
    ).then((result) {
      // 3. (Opcional) Si el formulario devuelve 'true', refrescamos
      if (result == true) {
        // TODO: Añadir una función que refresque la lista de productos
        // _fetchProductos();
        print("¡Producto añadido! Refrescando lista...");
      }
    });
  }
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
              const Icon(Icons.inventory_2, size: 100, color: Colors.grey),
              const SizedBox(height: 20),
              Text(
                'Gestión de Productos',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const Text(
                'Aquí podrás añadir, editar y eliminar productos y sus variantes.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // 4. Conecta el botón al nuevo método
              ElevatedButton(
                onPressed: _navigateToAddProducto,
                child: const Text('Añadir Nuevo Producto'),
              ),

              ElevatedButton(
                onPressed: _navigateToAddVariante,
                child: const Text('Añadir Variante de Producto'),
              ),
            ],
          ),
        ),
      ),
      // TODO: Añadir un ListView/GridView aquí para mostrar los productos
    );
  }
}