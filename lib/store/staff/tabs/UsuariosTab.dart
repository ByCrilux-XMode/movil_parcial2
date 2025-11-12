import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:movil_parcial2/settings/conf.dart';

class UsuariosTab extends StatefulWidget {
  const UsuariosTab({super.key});

  @override
  State<UsuariosTab> createState() => _UsuariosTabState();
}

class _UsuariosTabState extends State<UsuariosTab> {
  List<dynamic> _allUsers = [];
  List<dynamic> _filteredUsers = [];
  bool _loading = true;
  final _searchController = TextEditingController();

  // IDs de roles (basado en el backend Seeder)
  final Map<String, int> _roles = {
    'ROLE_ADMIN': 1,
    'ROLE_CLIENTE': 2,
    'ROLE_VENDEDOR': 3,
  };

  @override
  void initState() {
    super.initState();
    _fetchUsers();
    _searchController.addListener(_filterUsers);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchUsers() async {
    setState(() {
      _loading = true;
    });

    try {
      final token = await Config().obtenerDato('token');
      // Endpoint para listar todos los usuarios
      final url = Uri.parse('${Config.baseUrl}/usuario/usuario');
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _allUsers = jsonDecode(response.body);
          _filteredUsers = _allUsers;
          _loading = false;
        });
      } else {
        throw Exception('Error al cargar usuarios: ${response.body}');
      }
    } catch (e) {
      _showErrorSnackBar('Error: $e');
      setState(() {
        _loading = false;
      });
    }
  }

  void _filterUsers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredUsers = _allUsers.where((user) {
        final username = user['username']?.toLowerCase() ?? '';
        final email = user['email']?.toLowerCase() ?? '';
        final nombre = user['nombre']?.toLowerCase() ?? '';
        final id = user['id']?.toString() ?? '';

        return username.contains(query) ||
            email.contains(query) ||
            nombre.contains(query) ||
            id.contains(query);
      }).toList();
    });
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

  /// Muestra el diálogo para editar el rol de un usuario
  Future<void> _showEditRoleDialog(Map<String, dynamic> user) async {
    String selectedRole = "ROLE_${user['rolNombre']}"; // Rol actual
    int? newRoleId = _roles[selectedRole];

    if (newRoleId == null) {
      _showErrorSnackBar('Rol desconocido: $selectedRole');
      return;
    }

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Editar Rol de ${user['username']}'),
          content: DropdownButtonFormField<String>(
            value: selectedRole,
            items: _roles.keys.map((String rol) {
              return DropdownMenuItem<String>(
                value: rol,
                child: Text(rol.replaceAll('ROLE_', '')),
              );
            }).toList(),
            onChanged: (newValue) {
              if (newValue != null) {
                selectedRole = newValue;
                newRoleId = _roles[newValue];
              }
            },
          ),
          actions: [
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: const Text('Guardar'),
              onPressed: () {
                if (newRoleId != null) {
                  _updateUserRole(user, newRoleId!);
                  Navigator.of(context).pop();
                } else {
                  _showErrorSnackBar('Rol no válido seleccionado.');
                }
              },
            ),
          ],
        );
      },
    );
  }

  /// Llama al endpoint PUT para actualizar el usuario
  Future<void> _updateUserRole(Map<String, dynamic> user, int newRoleId) async {
    setState(() { _loading = true; }); // Re-usa el loader principal

    try {
      final token = await Config().obtenerDato('token');
      final url = Uri.parse('${Config.baseUrl}/usuario/usuario/${user['id']}');

      // El DTO del backend espera todos los campos, así que los reenviamos
      // El backend requiere un password, mandamos uno dummy si no lo tenemos
      final body = jsonEncode({
        "nombre": user['nombre'],
        "apellido": user['apellido'],
        "email": user['email'],
        "username": user['username'],
        "password": "defaultpassword",
        "telefono": user['telefono'] ?? "",
        "rolId": newRoleId, // El único campo que realmente cambiamos
      });

      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: body,
      );

      if (response.statusCode == 200) {
        _showSuccessSnackBar('Rol de usuario actualizado');
        _fetchUsers(); // Refresca la lista
      } else {
        throw Exception('Error al actualizar: ${response.body}');
      }
    } catch (e) {
      _showErrorSnackBar('Error: $e');
    } finally {
      setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              labelText: 'Buscar por ID, nombre, usuario o email',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
            onRefresh: _fetchUsers,
            child: ListView.builder(
              itemCount: _filteredUsers.length,
              itemBuilder: (context, index) {
                final user = _filteredUsers[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text(user['username'][0].toUpperCase()),
                    ),
                    title: Text(user['username']),
                    subtitle: Text(user['email']),
                    trailing: Text(
                      user['rolNombre'].replaceAll('ROLE_', ''),
                      style: TextStyle(
                        color: user['rolNombre'] == 'ROLE_ADMIN'
                            ? Colors.red
                            : Colors.blueGrey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onTap: () => _showEditRoleDialog(user),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}