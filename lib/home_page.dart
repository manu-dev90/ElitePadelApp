import 'package:elitepadelapp/profile_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'classification_page.dart';
import 'matches_page.dart' hide HomeDashboard;
import 'login_page.dart';
import 'home_dashboard.dart';

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  String? nombreUsuario;

  @override
  void initState() {
    super.initState();
    _cargarNombreUsuario();
  }

  Future<void> _cargarNombreUsuario() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final doc = await FirebaseFirestore.instance.collection('usuarios').doc(uid).get();
      setState(() {
        nombreUsuario = doc.data()?['nombre'] ?? 'Usuario';
      });
    }
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => LoginPage()),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  final List<Widget> _pages = [
    HomeDashboard(),
    ClassificationPage(),
    MatchesPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: nombreUsuario == null
            ? Text('Cargando...')
            : Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Bienvenido $nombreUsuario 👋', style: TextStyle(fontSize: 25)),
            IconButton(
              icon: Icon(Icons.logout),
              onPressed: _logout,
              tooltip: 'Cerrar sesión',
            ),
          ],
        ),
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.black54,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.emoji_events), label: 'Clasificación'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Partidos'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }
}
