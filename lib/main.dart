import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:movil_parcial2/settings/conf.dart';
import 'package:http/http.dart' as http;
import 'package:movil_parcial2/store/customer/ScreenCustomer.dart';
import 'package:movil_parcial2/store/staff/ScreenStaff.dart';
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Trendora",
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const LoginPage()
    );
  }
}

class LoginPage extends StatefulWidget{
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>{

  //
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  //

  void _login() async{
    final url = Uri.parse('${Config.baseUrl}/auth/login');
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });


    try{
      final response = await http.post(url,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "username": _usernameController.text,
            "password": _passwordController.text,
          })
      );
    if(response.statusCode == 200){
      print("---------------------------------------");
      print("----logeo correcto---");
      final data = jsonDecode(response.body);
      Config().GuardarAlgunDato("token", data["token"]);
      Config().GuardarAlgunDato("id", data["usuario"]["id"]);
      Config().GuardarAlgunDato("rol", data["usuario"]["rolNombre"]);

      //ROLE_CLIENTE, ROLE_VENDEDOR, ROLE_ADMIN
      final String rol = data["usuario"]["rolNombre"];

      FocusScope.of(context).unfocus();

      if(rol == "ROLE_CLIENTE"){
        Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ScreenCustomer())
        );
      } else if (rol == "ROLE_VENDEDOR" || rol == "ROLE_ADMIN") {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => ScreenStaff(rol: rol)
            )
        );
      } else {
        // Maneja un rol inesperado
        setState(() {
          _errorMessage = "Rol de usuario no reconocido.";
        });
        print("Rol desconocido: $rol");
      }
    }
    }catch (valor){
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error al iniciar sesión"))
      );
    }finally{
      setState(() {
        _isLoading = false;
        _errorMessage = "Error al iniciar sesión";
      });
    }
  }

  void _goToRegister(){
    Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterPage()));
  }
  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('login'),),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ////
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(labelText: 'Usuario', border: OutlineInputBorder()),
            ),
            ////
            const SizedBox(height: 16),
            ////
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Contraseña', border: OutlineInputBorder()),
            ),
            ////
            const SizedBox(height: 16),
            ////
            _isLoading? const CircularProgressIndicator()
                :ElevatedButton(
                onPressed: _login,
                child: const Text('Iniciar Sesión'),
              ),
            ////
            const SizedBox(height: 16,),
            ////
            GestureDetector(
              onTap: _goToRegister,
              child: const Text('Registrarse', style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline),),
            ),
            ////
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text( _errorMessage!, style: const TextStyle(color: Colors.blue),),
              )

          ],
        ),
      ),
    );
  }
}

class RegisterPage extends StatefulWidget{
  const RegisterPage({super.key});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>{
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _apellidoController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _telefonoController.dispose();
    super.dispose();
  }
  void _register() async {
    if (!_formKey.currentState!.validate()) return;
    final url = Uri.parse('${Config.baseUrl}/auth/register');
    print(url);
    setState(() {
      _isLoading = true;
    });
    try{
      final response = await http.post(url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "nombre":_nombreController.text,
          "apellido":_apellidoController.text,
          "email": _emailController.text,
          "username": _usernameController.text,
          "password":_passwordController.text,
          "telefono":_telefonoController.text,
          "rolId": "2",
        })
      );
      if(response.statusCode == 200){
        Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginPage()));
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Creacion Exitosa"))
        );
      }else{
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("el codigo de estado es: ${response.statusCode}"))
        );
      }
    }catch(valor){
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al registrarse"))
      );
    }finally{
      setState(() {
        _isLoading = false;
      });
    };

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrarse'),),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(key: _formKey,
          child: Column(
            children: [
              ////
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: (value) =>
                    value!.isEmpty ? 'Por favor ingrese su nombre' : null,
              ),
              ////
              const SizedBox(height: 10),
              ////
              TextFormField(
                controller: _apellidoController,
                decoration: const InputDecoration(labelText: 'Apellido'),
                validator: (value) =>
                    value!.isEmpty ? 'Por favor ingrese su apellido' : null,
              ),
              ////
              const SizedBox(height: 10),
              ////
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Correo electrónico'),
                validator: (value) =>
                    value!.isEmpty ? 'Por favor ingrese su correo electrónico' : null,
              ),
              ////
              const SizedBox(height: 10),
              ////
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: 'Nombre de usuario'),
                validator: (value) =>
                    value!.isEmpty ? 'Por favor ingrese su nombre de usuario' : null,
              ),
              ////
              const SizedBox(height: 10),
              ////
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Contraseña'),
                validator: (value) =>
                    value!.isEmpty ? 'Por favor ingrese su contraseña' : null,
              ),
              ////
              const SizedBox(height: 10),
              TextFormField(
                controller: _telefonoController,
                decoration: const InputDecoration(labelText: 'Teléfono'),
                validator: (value) =>
                    value!.isEmpty ? 'Por favor ingrese su teléfono' : null,
              ),
              ////
              const SizedBox(height: 10),
              ////
              _isLoading? const CircularProgressIndicator()
                  :ElevatedButton(
                onPressed: _register,
                child: const Text('Registrarse'),
              ),
            ],
          ),
        ),
      ),
    );
  }

}