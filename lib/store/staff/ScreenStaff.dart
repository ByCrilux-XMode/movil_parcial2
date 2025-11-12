import 'package:flutter/material.dart';
import 'package:movil_parcial2/store/staff/tabs/ProductosTab.dart';
import 'package:movil_parcial2/store/staff/tabs/UsuariosTab.dart';
import 'package:movil_parcial2/store/staff/tabs/VentaFisicaTab.dart';
import 'package:movil_parcial2/store/staff/tabs/VentasStaffTab.dart';

class ScreenStaff extends StatefulWidget {
  final String rol;
  const ScreenStaff({super.key, required this.rol});

  @override
  State<ScreenStaff> createState() => _ScreenStaffState();
}

class _ScreenStaffState extends State<ScreenStaff> {
  int _selectedIndex = 0;
  late final List<Widget> _tabsContent;
  late final List<BottomNavigationBarItem> _tabs;

  @override
  void initState() {
    super.initState();

    // --- Pestañas comunes para Vendedor y Admin ---
    final List<BottomNavigationBarItem> commonTabs = [
      const BottomNavigationBarItem(
        icon: Icon(Icons.point_of_sale),
        label: 'Venta Física',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.receipt_long),
        label: 'Mis Ventas',
      ),
    ];

    final List<Widget> commonWidgets = [
      const VentaFisicaTab(),
      const VentasStaffTab(),
    ];

    // --- Pestañas solo para Admin ---
    if (widget.rol == "ROLE_ADMIN") {
      _tabs = [
        ...commonTabs,
        const BottomNavigationBarItem(
          icon: Icon(Icons.inventory_2),
          label: 'Productos',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.people),
          label: 'Usuarios',
        ),
      ];
      _tabsContent = [
        ...commonWidgets,
        const ProductosTab(), // Tab de productos (standby)
        const UsuariosTab(), // Tab de gestión de usuarios
      ];
    } else {
      // --- Pestañas solo para Vendedor ---
      _tabs = commonTabs;
      _tabsContent = commonWidgets;
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Panel de ${widget.rol == "ROLE_ADMIN" ? "Administrador" : "Vendedor"}'),
        backgroundColor: Colors.blueGrey,
      ),
      body: Center(
        child: _tabsContent.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: _tabs,
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blueGrey[800],
        unselectedItemColor: Colors.grey, // Mostrar color en items no seleccionados
        onTap: _onItemTapped,
      ),
    );
  }
}