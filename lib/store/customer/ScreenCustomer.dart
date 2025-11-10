import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:movil_parcial2/settings/conf.dart';
import 'package:movil_parcial2/store/customer/options/Store.dart';
import 'package:movil_parcial2/store/customer/options/Cart.dart';
import 'package:http/http.dart' as http;
class ScreenCustomer extends StatefulWidget{
  const ScreenCustomer({super.key});
  @override
  State<ScreenCustomer> createState() => _ScreenCustomerState();
}

class _ScreenCustomerState extends State<ScreenCustomer> {

  late String _optionSelected;
  final List<String> _options = ['Tienda', 'Carrito', 'Compras', 'Perfil'];
  @override
  void initState() {
    _optionSelected = _options[0];
    _carritoVerificacion();
    super.initState();
  }

  Future<void> _carritoVerificacion() async{
    final id = await Config().obtenerDato('id');
    final url = Uri.parse('${Config.baseUrl}/venta/carrito/porcliente/$id');
    final token = await Config().obtenerDato('token');
    final response = await http.get(url);
    final data = jsonDecode(response.body);
    if(data is List && data.isEmpty){
      final url = Uri.parse('${Config.baseUrl}/venta/carrito');
      final response = await http.post(url,
          headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
          body: jsonEncode({'clienteId': id})
      );
      final data = jsonDecode(response.body);
      Config().GuardarAlgunDato('idCarrito', data['id']);
    }else{
        print("------------------------");
        print("----ya tiene carrito---");
        final idCarrito = await Config().obtenerDato('idCarrito');
        print('idCarrito: $idCarrito');
        print("------------------------");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clientes'),
        centerTitle: true,
        backgroundColor: Colors.green.shade500,
        elevation: 5,
        shadowColor: Colors.black,
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(decoration: BoxDecoration(color:Colors.green.shade500),
              child: Center(child: Text("Trendora", style: TextStyle(color: Colors.white,fontSize: 50, fontWeight: FontWeight.bold))), //texto manuscrito
            ),
            for (final option in _options)
              ListTile(
                  title: Text(option),
                  onTap: () {
                    setState(() {
                      _optionSelected = option;
                    });
                    Navigator.pop(context);
                  }
              )
          ],
        ),
      ),
      body: _getBody()
    );
  }

  Widget _getBody(){
    switch (_optionSelected) {
      case 'Tienda':
        return const Store();
      case 'Carrito':
        return const CartPage();
      case 'Compras':
        return const Text('construccion');
      case 'Perfil':
        return const Text('perfil');
      default: {
        return const Text('Bienvenido');
      }
    }
  }
}

