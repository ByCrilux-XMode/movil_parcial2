import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:movil_parcial2/settings/conf.dart';
import 'package:http_parser/http_parser.dart'; // Asegúrate de tener http_parser en pubspec.yaml

class AddProductoPage extends StatefulWidget {
  const AddProductoPage({super.key});

  @override
  _AddProductoPageState createState() => _AddProductoPageState();
}

class _AddProductoPageState extends State<AddProductoPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  bool _isSaving = false;

  // Controladores
  final _descripcionController = TextEditingController();
  final _nombreController = TextEditingController();
  // El _imagenController YA NO ES NECESARIO para la lógica,
  // pero lo guardamos si quieres mostrar la URL devuelta (opcional)
  final _imagenUrlController = TextEditingController();

  // Datos para los Dropdowns
  List<Map<String, dynamic>> _modelos = [];
  List<Map<String, dynamic>> _categorias = [];
  List<Map<String, dynamic>> _materiales = [];
  List<Map<String, dynamic>> _etiquetas = [];

  // Valores seleccionados
  int? _selectedModeloId;
  int? _selectedCategoriaId;
  int? _selectedMaterialId;
  final Set<int> _selectedEtiquetas = <int>{};

  File? _imageFile; // Archivo de imagen seleccionado

  @override
  void initState() {
    super.initState();
    _loadDropdownData();
  }

  @override
  void dispose() {
    _descripcionController.dispose();
    _nombreController.dispose();
    _imagenUrlController.dispose();
    super.dispose();
  }

  Future<void> _loadDropdownData() async {
    // ... (Este método es idéntico al de la Parte 1, no cambia)
    try {
      final token = await Config().obtenerDato('token');
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token'
      };
      final futures = {
        'modelos': http.get(Uri.parse('${Config.baseUrl}/producto/modelo'), headers: headers),
        'categorias': http.get(Uri.parse('${Config.baseUrl}/producto/categoria'), headers: headers),
        'materiales': http.get(Uri.parse('${Config.baseUrl}/producto/material'), headers: headers),
        'etiquetas': http.get(Uri.parse('${Config.baseUrl}/producto/etiqueta'), headers: headers),
      };
      final results = await Future.wait(futures.values);
      final Map<String, dynamic> data = {
        'modelos': jsonDecode(results[0].body),
        'categorias': jsonDecode(results[1].body),
        'materiales': jsonDecode(results[2].body),
        'etiquetas': jsonDecode(results[3].body),
      };
      for (var i = 0; i < results.length; i++) {
        if (results[i].statusCode != 200) {
          throw Exception('Error al cargar ${futures.keys.elementAt(i)}: ${results[i].body}');
        }
      }
      setState(() {
        _modelos = List<Map<String, dynamic>>.from(data['modelos'].map((item) => {'id': item['id'], 'nombre': item['nombre']}));
        _categorias = List<Map<String, dynamic>>.from(data['categorias'].map((item) => {'id': item['id'], 'nombre': item['nombre']}));
        _materiales = List<Map<String, dynamic>>.from(data['materiales'].map((item) => {'id': item['id'], 'nombre': item['nombre']}));
        _etiquetas = List<Map<String, dynamic>>.from(data['etiquetas'].map((item) => {'id': item['id'], 'nombre': item['nombre']}));
        _isLoading = false;
      });
    } catch (e) {
      _showErrorSnackBar('Error al cargar datos del formulario: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // --- 1. MÉTODO _pickAndUploadImage SIMPLIFICADO ---
  // Ahora solo "elige" la imagen y la guarda en el estado
  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 70);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
        _imagenUrlController.text = pickedFile.name; // Muestra el nombre del archivo
      });
    }
  }
  // --- FIN DEL MÉTODO SIMPLIFICADO ---

  // --- 2. MÉTODO _submitForm MODIFICADO (LA LÓGICA PRINCIPAL) ---
  // --- REEMPLAZA TU MÉTODO _submitForm CON ESTE ---
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      _showErrorSnackBar('Por favor, completa todos los campos requeridos.');
      return;
    }

    if (_selectedModeloId == null || _selectedCategoriaId == null || _selectedMaterialId == null) {
      _showErrorSnackBar('Por favor, selecciona modelo, categoría y material.');
      return;
    }

    if (_selectedEtiquetas.isEmpty) {
      _showErrorSnackBar('Por favor, selecciona al menos una etiqueta.');
      return;
    }

    setState(() { _isSaving = true; });

    try {
      final token = await Config().obtenerDato('token');
      final url = Uri.parse('${Config.baseUrl}/producto/producto');

      var request = http.MultipartRequest('POST', url);
      request.headers['Authorization'] = 'Bearer $token';

      // 1. Crear el JSON de datos del producto
      final productoData = {
        //"nombre": _nombreController.text,
        "descripcion": _descripcionController.text,
        "modelo": _selectedModeloId,
        "categoria": _selectedCategoriaId,
        "material": _selectedMaterialId,
        "etiquetas": _selectedEtiquetas.toList(),
      };

      // --- 2. ESTA ES LA CORRECCIÓN ---
      // En lugar de usar request.fields[], enviamos el JSON como un archivo
      // de "parte" con el Content-Type 'application/json' explícito.
      // Esto evita el error 415.
      request.files.add(
        http.MultipartFile.fromString(
          'producto', // Coincide con @RequestPart("producto")
          jsonEncode(productoData),
          contentType: MediaType('application', 'json'),
        ),
      );
      // -------------------------------

      // 3. Adjuntar el archivo de imagen (si existe)
      if (_imageFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'imagen', // Coincide con @RequestPart("imagen")
            _imageFile!.path,
            contentType: MediaType('image', _imageFile!.path.split('.').last),
          ),
        );
      }

      // 4. Enviar la petición
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        _showSuccessSnackBar('Producto creado con éxito');
        Navigator.of(context).pop(true);
      } else {
        throw Exception('Error al crear el producto (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      _showErrorSnackBar('Error: $e');
    } finally {
      setState(() { _isSaving = false; });
    }
  }
  // --- FIN DEL MÉTODO MODIFICADO ---

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
        title: const Text('Añadir Nuevo Producto'),
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
              // --- 3. WIDGET DE IMAGEN MODIFICADO ---
              _buildImageUploader(),
              const SizedBox(height: 16),
              // ------------------------------------

              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(labelText: 'Nombre del Producto'),
                validator: (value) => value!.isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descripcionController,
                decoration: const InputDecoration(labelText: 'Descripción'),
                maxLines: 3,
                validator: (value) => value!.isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 16),

              // Este campo ya no es necesario o puede ser solo de lectura
              TextFormField(
                controller: _imagenUrlController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Imagen Seleccionada',
                  hintText: 'Sube una imagen...',
                ),
                // La validación ya no es necesaria aquí si la imagen es opcional
                // validator: (value) => value!.isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 16),

              // ... (Todos los Dropdowns y Chips son idénticos) ...
              DropdownButtonFormField<int>(
                value: _selectedModeloId,
                hint: const Text('Seleccionar Modelo'),
                items: _modelos.map((modelo) => DropdownMenuItem<int>(value: modelo['id'], child: Text(modelo['nombre']))).toList(),
                onChanged: (value) { setState(() { _selectedModeloId = value; }); },
                validator: (value) => value == null ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: _selectedCategoriaId,
                hint: const Text('Seleccionar Categoría'),
                items: _categorias.map((cat) => DropdownMenuItem<int>(value: cat['id'], child: Text(cat['nombre']))).toList(),
                onChanged: (value) { setState(() { _selectedCategoriaId = value; }); },
                validator: (value) => value == null ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: _selectedMaterialId,
                hint: const Text('Seleccionar Material'),
                items: _materiales.map((mat) => DropdownMenuItem<int>(value: mat['id'], child: Text(mat['nombre']))).toList(),
                onChanged: (value) { setState(() { _selectedMaterialId = value; }); },
                validator: (value) => value == null ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 24),
              const Text('Etiquetas (Selecciona al menos una)', style: TextStyle(fontWeight: FontWeight.bold)),
              Wrap(
                spacing: 8.0,
                children: _etiquetas.map((etiqueta) {
                  final bool isSelected = _selectedEtiquetas.contains(etiqueta['id']);
                  return FilterChip(
                    label: Text(etiqueta['nombre']),
                    selected: isSelected,
                    onSelected: (bool selected) {
                      setState(() {
                        if (selected) {
                          _selectedEtiquetas.add(etiqueta['id']);
                        } else {
                          _selectedEtiquetas.remove(etiqueta['id']);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.blueGrey,
                    foregroundColor: Colors.white
                ),
                onPressed: _isSaving ? null : _submitForm, // Llama a _submitForm
                child: _isSaving
                    ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
                    : const Text('Guardar Producto'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- 4. WIDGET DE IMAGEN MODIFICADO ---
  Widget _buildImageUploader() {
    return Column(
      children: [
        // Vista Previa (igual que en React)
        AspectRatio(
          aspectRatio: 16 / 9,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey[200],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (_imageFile != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(_imageFile!, fit: BoxFit.cover, width: double.infinity),
                  ),
                if (_imageFile == null)
                  const Icon(Icons.image, size: 80, color: Colors.grey),
                // Ya no necesitamos _isUploading aquí, se muestra en el botón Guardar
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Botones (ahora llaman a _pickImage)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(
              onPressed: _isSaving ? null : () => _pickImage(ImageSource.camera),
              icon: const Icon(Icons.camera_alt),
              label: const Text('Cámara'),
            ),
            ElevatedButton.icon(
              onPressed: _isSaving ? null : () => _pickImage(ImageSource.gallery),
              icon: const Icon(Icons.photo_library),
              label: const Text('Galería'),
            ),
          ],
        ),
      ],
    );
  }
}