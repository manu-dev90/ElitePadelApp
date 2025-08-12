import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';

class MatchesPage extends StatefulWidget {
  @override
  State<MatchesPage> createState() => _MatchesPageState();
}

class _MatchesPageState extends State<MatchesPage> {
  List<Map<String, dynamic>> usuarios = [];
  String? currentUserName;
  String? userNombre;

  String? jugador1;
  String? jugador2;
  String? jugador3;
  String? jugador4;

  final TextEditingController set1Pareja1 = TextEditingController();
  final TextEditingController set1Pareja2 = TextEditingController();
  final TextEditingController set2Pareja1 = TextEditingController();
  final TextEditingController set2Pareja2 = TextEditingController();
  final TextEditingController set3Pareja1 = TextEditingController();
  final TextEditingController set3Pareja2 = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cargarUsuarios();
    _obtenerNombreUsuarioActual();
  }

  Future<void> _cargarUsuarios() async {
    final snapshot = await FirebaseFirestore.instance.collection('usuarios').get();
    final currentUser = FirebaseAuth.instance.currentUser;

    setState(() {
      usuarios = snapshot.docs.map((doc) => {
        'nombre': doc['nombre'],
        'email': doc['email'],
      }).toList();

      final usuarioActual = usuarios.firstWhere(
            (u) => u['email'] == currentUser?.email,
        orElse: () => {'nombre': null},
      );

      currentUserName = usuarioActual['nombre'];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Historial de Partidos')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('partidos')
            .orderBy('fecha', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          final docs = (snapshot.data?.docs ?? [])
              .map((doc) => doc.data() as Map<String, dynamic>)
              .where((partido) {
            final jugadores = [
              partido['jugador1'],
              partido['jugador2'],
              partido['jugador3'],
              partido['jugador4']
            ];
            return jugadores.contains(userNombre);
          })
              .toList();

          if (docs.isEmpty) {
            return Center(child: Text('No hay partidos aún'));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final partido = docs[index];

              bool estaEnPareja1 = partido['pareja1'].contains(userNombre);
              bool estaEnPareja2 = partido['pareja2'].contains(userNombre);

              Color bgColor = Colors.grey[400]!; // empate por defecto

              if (partido['ganador'] == 'pareja1' && estaEnPareja1) {
                bgColor = Colors.green[200]!;
              } else if (partido['ganador'] == 'pareja2' && estaEnPareja2) {
                bgColor = Colors.green[200]!;
              } else if (partido['ganador'] == 'pareja1' && estaEnPareja2) {
                bgColor = Colors.red[200]!;
              } else if (partido['ganador'] == 'pareja2' && estaEnPareja1) {
                bgColor = Colors.red[200]!;
              }

              return Card(
                color: bgColor,
                margin: EdgeInsets.all(10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Partido fecha ${_formatearFecha(partido['fecha'])}',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                      ),
                      SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${partido['jugador1']} / ${partido['jugador2']}',
                            style: TextStyle(fontSize: 18),
                          ),
                          Text('vs', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                          Text(
                            '${partido['jugador3']} / ${partido['jugador4']}',
                            style: TextStyle(fontSize: 18),
                            textAlign: TextAlign.right,
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      _buildSetRow('Set 1', partido['sets']['set1']['pareja1'], partido['sets']['set1']['pareja2']),
                      _buildSetRow('Set 2', partido['sets']['set2']['pareja1'], partido['sets']['set2']['pareja2']),
                      _buildSetRow('Set 3', partido['sets']['set3']['pareja1'], partido['sets']['set3']['pareja2']),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarDialogoCrearPartido(context),
        child: Icon(Icons.add),
        backgroundColor: Colors.white,
      ),
    );
  }

  Widget _buildSetRow(String setName, int p1, int p2) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('$setName:', style: TextStyle(fontSize: 16)),
          SizedBox(width: 16),
          Text('$p1', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          SizedBox(width: 8),
          Text('-', style: TextStyle(fontSize: 16)),
          SizedBox(width: 8),
          Text('$p2', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  void _mostrarDialogoCrearPartido(BuildContext context) {
    resetearCampos();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: Text('Crear nuevo partido'),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  _buildDropdown('Pareja 1', jugador1, (val) => setState(() => jugador1 = val), _nombresDisponiblesPara(jugador1)),
                  _buildDropdown('Pareja 1', jugador2, (val) => setState(() => jugador2 = val), _nombresDisponiblesPara(jugador2)),
                  _buildDropdown('Pareja 2', jugador3, (val) => setState(() => jugador3 = val), _nombresDisponiblesPara(jugador3)),
                  _buildDropdown('Pareja 2', jugador4, (val) => setState(() => jugador4 = val), _nombresDisponiblesPara(jugador4)),
                  Divider(),
                  Text('Set 1'), _setInput(set1Pareja1, set1Pareja2),
                  Text('Set 2'), _setInput(set2Pareja1, set2Pareja2),
                  Text('Set 3'), _setInput(set3Pareja1, set3Pareja2),
                ],
              ),
            ),
            actions: [
              TextButton(child: Text('Cancelar'), onPressed: () => Navigator.of(context).pop()),
              ElevatedButton(
                child: Text('Guardar'),
                onPressed: () async {
                  final partido = {
                    'jugador1': jugador1,
                    'jugador2': jugador2,
                    'jugador3': jugador3,
                    'jugador4': jugador4,
                    'pareja1': [jugador1, jugador2],
                    'pareja2': [jugador3, jugador4],
                    'sets': {
                      'set1': {
                        'pareja1': int.tryParse(set1Pareja1.text) ?? 0,
                        'pareja2': int.tryParse(set1Pareja2.text) ?? 0,
                      },
                      'set2': {
                        'pareja1': int.tryParse(set2Pareja1.text) ?? 0,
                        'pareja2': int.tryParse(set2Pareja2.text) ?? 0,
                      },
                      'set3': {
                        'pareja1': int.tryParse(set3Pareja1.text) ?? 0,
                        'pareja2': int.tryParse(set3Pareja2.text) ?? 0,
                      },
                    },
                    'ganador': _calcularGanador(),
                    'fecha': Timestamp.now(),
                    'finalizado': true,
                  };
                  await FirebaseFirestore.instance.collection('partidos').add(partido);

                  // Calcular puntos según resultado
                  final ganador = partido['ganador'];
                  final puntos = {
                    'pareja1': ganador == 'pareja1' ? 3 : (ganador == 'empate' ? 1 : 0),
                    'pareja2': ganador == 'pareja2' ? 3 : (ganador == 'empate' ? 1 : 0),
                  };

                  // Sumar puntos a cada jugador
                  await _sumarPuntosJugador(jugador1!, puntos['pareja1']!);
                  await _sumarPuntosJugador(jugador2!, puntos['pareja1']!);
                  await _sumarPuntosJugador(jugador3!, puntos['pareja2']!);
                  await _sumarPuntosJugador(jugador4!, puntos['pareja2']!);

                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        });
      },
    );
  }

  String _calcularGanador() {
    int setsPareja1 = 0;
    int setsPareja2 = 0;

    final sets = [
      [int.tryParse(set1Pareja1.text) ?? 0, int.tryParse(set1Pareja2.text) ?? 0],
      [int.tryParse(set2Pareja1.text) ?? 0, int.tryParse(set2Pareja2.text) ?? 0],
      [int.tryParse(set3Pareja1.text) ?? 0, int.tryParse(set3Pareja2.text) ?? 0],
    ];

    for (var set in sets) {
      if (set[0] > set[1]) {
        setsPareja1++;
      } else if (set[1] > set[0]) {
        setsPareja2++;
      }
    }

    if (setsPareja1 > setsPareja2) return 'pareja1';
    if (setsPareja2 > setsPareja1) return 'pareja2';
    return 'empate';
  }

  Widget _setInput(TextEditingController pareja1, TextEditingController pareja2) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Expanded(
          child: TextField(
            controller: pareja1,
            decoration: InputDecoration(labelText: 'Pareja 1'),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(1),
              FilteringTextInputFormatter.allow(RegExp(r'[0-7]')),
            ],
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: pareja2,
            decoration: InputDecoration(labelText: 'Pareja 2'),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(1),
              FilteringTextInputFormatter.allow(RegExp(r'[0-7]')),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown(String label, String? value, Function(String?) onChanged, List<String> opciones) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(labelText: label),
      items: opciones.map((nombre) {
        return DropdownMenuItem<String>(
          value: nombre,
          child: Text(nombre),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  List<String> _nombresDisponiblesPara(String? actual) {
    final seleccionados = [jugador1, jugador2, jugador3, jugador4];
    final todos = usuarios.map((u) => u['nombre'] as String).toList();

    return todos.where((nombre) => nombre == actual || !seleccionados.contains(nombre)).toList();
  }

  String _formatearFecha(Timestamp timestamp) {
    final fecha = timestamp.toDate();
    return '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year.toString().substring(2)}';
  }

  void resetearCampos() {
    jugador1 = null;
    jugador2 = null;
    jugador3 = null;
    jugador4 = null;

    set1Pareja1.clear();
    set1Pareja2.clear();
    set2Pareja1.clear();
    set2Pareja2.clear();
    set3Pareja1.clear();
    set3Pareja2.clear();
  }

  void _obtenerNombreUsuarioActual() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .get();
      if (userDoc.exists) {
        setState(() {
          userNombre = userDoc.data()?['nombre'];
          print("Nombre del usuario actual: $userNombre");
        });
      }
    }
  }

  Future<void> _sumarPuntosJugador(String nombreJugador, int puntosASumar) async {
    final usuarios = await FirebaseFirestore.instance
        .collection('usuarios')
        .where('nombre', isEqualTo: nombreJugador)
        .get();

    if (usuarios.docs.isNotEmpty) {
      final doc = usuarios.docs.first;
      final docRef = doc.reference;
      final puntosActuales = doc['puntos'] ?? 0;

      await docRef.update({'puntos': puntosActuales + puntosASumar});
    }
  }
}
