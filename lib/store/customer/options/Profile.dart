import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:movil_parcial2/settings/conf.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true; // Para la carga inicial
  bool _isSaving = false; // Para el botón de guardar

  Map<String, dynamic>? _addressData;

  final _departamentoController = TextEditingController();
  final _zonaController = TextEditingController();
  final _calleController = TextEditingController();
  final _numeroCasaController = TextEditingController();
  final _referenciaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchAddress();
  }

  @override
  void dispose() {
    _departamentoController.dispose();
    _zonaController.dispose();
    _calleController.dispose();
    _numeroCasaController.dispose();
    _referenciaController.dispose();
    super.dispose();
  }

  /// Carga la dirección existente del cliente
  Future<void> _fetchAddress() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final token = await Config().obtenerDato('token');
      final clienteId = await Config().obtenerDato('id');
      final url =
      Uri.parse('${Config.baseUrl}/usuario/direccion/porcliente/$clienteId');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List && data.isNotEmpty) {
          // El cliente SÍ tiene una dirección, la cargamos
          setState(() {
            _addressData = data[0]; // Asumimos que solo tiene una dirección
            _prefillForm();
          });
        } else {
          // El cliente NO tiene dirección
          setState(() {
            _addressData = null;
          });
        }
      } else {
        throw Exception('Error al cargar la dirección: ${response.body}');
      }
    } catch (e) {
      _showErrorSnackBar('Error al cargar datos: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Rellena el formulario si ya existe una dirección
  void _prefillForm() {
    if (_addressData != null) {
      _departamentoController.text = _addressData!['departamento'] ?? '';
      _zonaController.text = _addressData!['zona'] ?? '';
      _calleController.text = _addressData!['calle'] ?? '';
      _numeroCasaController.text = _addressData!['numeroCasa'] ?? '';
      _referenciaController.text = _addressData!['referencia'] ?? '';
    }
  }

  /// Guarda los cambios (Crea o Actualiza)
  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) {
      return; // No hacer nada si el formulario no es válido
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final token = await Config().obtenerDato('token');
      final clienteId = await Config().obtenerDato('id');

      // 1. Preparar el body del RequestDTO
      final body = jsonEncode({
        "usuarioId": clienteId,
        "departamento": _departamentoController.text,
        "zona": _zonaController.text,
        "calle": _calleController.text,
        "numeroCasa": _numeroCasaController.text,
        "referencia": _referenciaController.text,
      });

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      http.Response response;

      // 2. Decidir si es POST (Crear) o PUT (Actualizar)
      if (_addressData == null) {
        // --- CREAR NUEVA DIRECCIÓN (POST) ---
        final url = Uri.parse('${Config.baseUrl}/usuario/direccion');
        response = await http.post(url, headers: headers, body: body);

        if (response.statusCode == 201) {
          _showSuccessSnackBar('Dirección creada con éxito');
          // Actualizamos los datos locales para que ahora sepa que existe
          setState(() {
            _addressData = jsonDecode(response.body);
          });
        } else {
          throw Exception('Error al crear: ${response.body}');
        }
      } else {
        // --- ACTUALIZAR DIRECCIÓN (PUT) ---
        final addressId = _addressData!['id'];
        final url = Uri.parse('${Config.baseUrl}/usuario/direccion/$addressId');
        response = await http.put(url, headers: headers, body: body);

        if (response.statusCode == 200) {
          _showSuccessSnackBar('Dirección actualizada con éxito');
          // Actualizamos los datos locales
          setState(() {
            _addressData = jsonDecode(response.body);
          });
        } else {
          throw Exception('Error al actualizar: ${response.body}');
        }
      }
    } catch (e) {
      _showErrorSnackBar('Error al guardar: $e');
    } finally {
      setState(() {
        _isSaving = false;
      });
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
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
      onRefresh: _fetchAddress,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _addressData == null
                    ? 'Añadir Dirección'
                    : 'Editar Dirección',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _departamentoController,
                decoration:
                const InputDecoration(labelText: 'Departamento'),
                validator: (value) =>
                value!.isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _zonaController,
                decoration: const InputDecoration(labelText: 'Zona'),
                validator: (value) =>
                value!.isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _calleController,
                decoration: const InputDecoration(labelText: 'Calle'),
                validator: (value) =>
                value!.isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _numeroCasaController,
                decoration: const InputDecoration(labelText: 'N° de Casa'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _referenciaController,
                decoration: const InputDecoration(labelText: 'Referencia'),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: _isSaving ? null : _saveAddress,
                child: _isSaving
                    ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                    : Text(_addressData == null
                    ? 'Crear Dirección'
                    : 'Actualizar Dirección'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}