import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProfilePage extends StatefulWidget {
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? nombre;
  String? email;
  String? mano;
  String? posicion;

  int jugados = 0;
  int ganados = 0;
  int empatados = 0;
  int perdidos = 0;

  final user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    cargarDatosUsuario();
    cargarHistorial();
  }

  Future<void> cargarDatosUsuario() async {
    if (user == null) return;

    final doc = await FirebaseFirestore.instance.collection('usuarios').doc(
        user!.uid).get();
    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        nombre = data['nombre'];
        email = data['email'];
        mano = data['mano'] ?? '';
        posicion = data['posicion'] ?? '';
      });
    }
  }

  Future<void> guardarPreferencias() async {
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(user!.uid)
        .update({
      'mano': mano,
      'posicion': posicion,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Datos guardados correctamente")),
    );
  }

  Future<void> cargarHistorial() async {
    final partidosSnap = await FirebaseFirestore.instance
        .collection('partidos')
        .orderBy('fecha', descending: true)
        .get();

    final nombreUsuario = (await FirebaseFirestore.instance.collection(
        'usuarios').doc(user!.uid).get()).data()?['nombre'];

    int j = 0,
        g = 0,
        e = 0,
        p = 0;

    for (var doc in partidosSnap.docs) {
      final data = doc.data();
      final ganador = data['ganador'];
      final pareja1 = List<String>.from(data['pareja1'] ?? []);
      final pareja2 = List<String>.from(data['pareja2'] ?? []);

      if (pareja1.contains(nombreUsuario) || pareja2.contains(nombreUsuario)) {
        j++;

        if (ganador == 'empate') {
          e++;
        } else if ((ganador == 'pareja1' && pareja1.contains(nombreUsuario)) ||
            (ganador == 'pareja2' && pareja2.contains(nombreUsuario))) {
          g++;
        } else {
          p++;
        }
      }
    }

    setState(() {
      jugados = j;
      ganados = g;
      empatados = e;
      perdidos = p;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Mi perfil")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: ListView(
          children: [
            // 📋 Datos personales
            Text("📋 Datos personales",
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),

            Padding(
              padding: EdgeInsets.only(left: 15),
              child: RichText(
                text: TextSpan(
                  style: TextStyle(fontSize: 20, color: Colors.black),
                  children: [
                    TextSpan(text: "Nombre: ",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: nombre),
                  ],
                ),
              ),
            ),
            SizedBox(height: 15),

            Padding(
              padding: EdgeInsets.only(left: 15),
              child: RichText(
                text: TextSpan(
                  style: TextStyle(fontSize: 20, color: Colors.black),
                  children: [
                    TextSpan(text: "Email: ",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: email),
                  ],
                ),
              ),
            ),
            SizedBox(height: 50),

            // 🎾 Datos del jugador
            Text("🎾 Datos del jugador",
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Padding(
              padding: EdgeInsets.only(left: 15.0), // 👈 Aquí defines el margen izquierdo
              child: DropdownButtonFormField<String>(
                value: (mano != null && mano!.isNotEmpty) ? mano : null,
                decoration: InputDecoration(
                  labelText: 'Mano dominante',
                  labelStyle: TextStyle(fontSize: 22), // Aquí defines el tamaño
                ),
                items: ['Izquierda', 'Derecha'].map((value) {
                  return DropdownMenuItem(
                    value: value,
                    child: Text(value, style: TextStyle(fontSize: 22)),
                  );
                }).toList(),
                onChanged: (val) => setState(() => mano = val ?? ''),
              ),
            ),
            SizedBox(height: 15),
            Padding(
              padding: EdgeInsets.only(left: 15.0),
              child: DropdownButtonFormField<String>(
                value: (posicion != null && posicion!.isNotEmpty) ? posicion : null,
                decoration: InputDecoration(
                  labelText: 'Posición preferida',
                  labelStyle: TextStyle(fontSize: 22), // Tamaño más grande del título
                ),
                items: ['Drive', 'Revés'].map((value) {
                  return DropdownMenuItem(
                    value: value,
                    child: Text(value, style: TextStyle(fontSize: 22)),
                  );
                }).toList(),
                onChanged: (val) => setState(() => posicion = val ?? ''),
              ),
            ),
            SizedBox(height: 25),
            ElevatedButton(
              onPressed: guardarPreferencias,
              child: Text("Guardar"),
            ),
            SizedBox(height: 50),

            Padding(
              padding: const EdgeInsets.only(left: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "📊 Historial de partidos",
                    style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 20),

                  // Padding adicional SOLO para los datos de partidos
                  Padding(
                    padding: const EdgeInsets.only(left: 10.0), // Ajusta este valor según desees
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: TextSpan(
                            style: TextStyle(fontSize: 20, color: Colors.black),
                            children: [
                              TextSpan(
                                text: 'Partidos jugados: ',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              TextSpan(text: '$jugados'),
                            ],
                          ),
                        ),
                        SizedBox(height: 15),
                        RichText(
                          text: TextSpan(
                            style: TextStyle(fontSize: 20, color: Colors.black),
                            children: [
                              TextSpan(
                                text: 'Partidos ganados: ',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              TextSpan(text: '$ganados'),
                            ],
                          ),
                        ),
                        SizedBox(height: 15),
                        RichText(
                          text: TextSpan(
                            style: TextStyle(fontSize: 20, color: Colors.black),
                            children: [
                              TextSpan(
                                text: 'Partidos empatados: ',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              TextSpan(text: '$empatados'),
                            ],
                          ),
                        ),
                        SizedBox(height: 15),
                        RichText(
                          text: TextSpan(
                            style: TextStyle(fontSize: 20, color: Colors.black),
                            children: [
                              TextSpan(
                                text: 'Partidos perdidos: ',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              TextSpan(text: '$perdidos'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
