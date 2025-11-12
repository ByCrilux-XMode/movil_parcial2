// lib/store/staff/forms/AddVariantePage.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:movil_parcial2/settings/conf.dart';

class AddVariantePage extends StatefulWidget {
  const AddVariantePage({super.key});

  @override
  _AddVariantePageState createState() => _AddVariantePageState();
}

class _AddVariantePageState extends State<AddVariantePage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true; // Para cargar dropdowns
  bool _isSaving = false; // Para guardar formulario

  // Controladores
  final _costoController = TextEditingController();
  final _precioController = TextEditingController();
  final _skuController = TextEditingController();
  final _stockController = TextEditingController();

  // Datos para los Dropdowns
  List<Map<String, dynamic>> _productos = [];
  List<Map<String, dynamic>> _colores = [];
  List<Map<String, dynamic>> _tallas = [];

  // Valores seleccionados
  int? _selectedProductoId;
  int? _selectedColorId;
  int? _selectedTallaId;

  @override
  void initState() {
    super.initState();
    _loadDropdownData();
  }

  @override
  void dispose() {
    _costoController.dispose();
    _precioController.dispose();
    _skuController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _loadDropdownData() async {
    try {
      final token = await Config().obtenerDato('token');
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token'
      };

      // Cargar productos, colores y tallas en paralelo
      final futures = {
        'productos': http.get(Uri.parse('${Config.baseUrl}/producto/producto'), headers: headers),
        'colores': http.get(Uri.parse('${Config.baseUrl}/inventario/color'), headers: headers),
        'tallas': http.get(Uri.parse('${Config.baseUrl}/inventario/talla'), headers: headers),
      };

      final results = await Future.wait(futures.values);
      final Map<String, dynamic> data = {
        'productos': jsonDecode(results[0].body),
        'colores': jsonDecode(results[1].body),
        'tallas': jsonDecode(results[2].body),
      };

      for (var i = 0; i < results.length; i++) {
        if (results[i].statusCode != 200) {
          throw Exception('Error al cargar ${futures.keys.elementAt(i)}: ${results[i].body}');
        }
      }
      print("---------------");
      print(data['productos']);
      print("---------------");
      setState(() {
        _productos = List<Map<String, dynamic>>.from(data['productos'].map((item) => {'id': item['id'], 'nombre': item['nombre']}));
        _colores = List<Map<String, dynamic>>.from(data['colores'].map((item) => {'id': item['id'], 'nombre': item['nombre']}));
        _tallas = List<Map<String, dynamic>>.from(data['tallas'].map((item) => {'id': item['id'], 'talla': item['talla']}));
        _isLoading = false;
      });
    } catch (e) {
      _showErrorSnackBar('Error al cargar datos: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      _showErrorSnackBar('Por favor, completa todos los campos requeridos.');
      return;
    }

    setState(() { _isSaving = true; });

    try {
      final token = await Config().obtenerDato('token');
      final url = Uri.parse('${Config.baseUrl}/inventario/prod-variante');

      // Este es el payload del ProdVarianteRequestDTO
      final body = jsonEncode({
        "producto": _selectedProductoId,
        "color": _selectedColorId,
        "talla": _selectedTallaId,
        "costo": double.tryParse(_costoController.text) ?? 0.0,
        "precio": double.tryParse(_precioController.text) ?? 0.0,
        "sku": _skuController.text,
        "stock": int.tryParse(_stockController.text) ?? 0,
      });

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) { // 200 OK (Spring Boot)
        _showSuccessSnackBar('Variante creada con éxito');
        Navigator.of(context).pop(true);
      } else {
        throw Exception('Error al crear la variante (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      _showErrorSnackBar('Error: $e');
    } finally {
      setState(() { _isSaving = false; });
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Añadir Variante de Stock'),
        backgroundColor: Colors.blueGrey,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- Dropdowns ---
              DropdownButtonFormField<int>(
                value: _selectedProductoId,
                hint: const Text('Seleccionar Producto Base'),
                items: _productos.map((item) => DropdownMenuItem<int>(value: item['id'],
                    child: Text('${item['nombre']} ${item['id']}')
                )
                ).toList(),
                onChanged: (value) { setState(() { _selectedProductoId = value; }); },
                validator: (value) => value == null ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: _selectedColorId,
                hint: const Text('Seleccionar Color'),
                items: _colores.map((item) => DropdownMenuItem<int>(value: item['id'], child: Text(item['nombre']))).toList(),
                onChanged: (value) { setState(() { _selectedColorId = value; }); },
                validator: (value) => value == null ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: _selectedTallaId,
                hint: const Text('Seleccionar Talla'),
                items: _tallas.map((item) => DropdownMenuItem<int>(value: item['id'], child: Text(item['talla']))).toList(),
                onChanged: (value) { setState(() { _selectedTallaId = value; }); },
                validator: (value) => value == null ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 24),

              // --- Campos de Texto ---
              TextFormField(
                controller: _skuController,
                decoration: const InputDecoration(labelText: 'SKU (Código único)'),
                validator: (value) => value!.isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _stockController,
                decoration: const InputDecoration(labelText: 'Stock Inicial'),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _costoController,
                decoration: const InputDecoration(labelText: 'Costo'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) => value!.isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _precioController,
                decoration: const InputDecoration(labelText: 'Precio de Venta'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) => value!.isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 32),

              // --- Botón de Guardar ---
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.blueGrey,
                    foregroundColor: Colors.white
                ),
                onPressed: _isSaving ? null : _submitForm,
                child: _isSaving
                    ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
                    : const Text('Guardar Variante'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}