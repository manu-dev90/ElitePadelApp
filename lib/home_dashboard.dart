import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HomeDashboard extends StatefulWidget {
  @override
  _HomeDashboardState createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> {
  final user = FirebaseAuth.instance.currentUser;

  Map<String, dynamic>? userStats;
  Map<String, dynamic>? lastMatch;

  @override
  void initState() {
    super.initState();
    fetchUserStats();
    fetchLastMatch();
  }

  Future<void> fetchUserStats() async {
    if (user == null) return;

    final userDoc = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(user!.uid)
        .get();
    final data = userDoc.data();
    final nombreUsuario = data?['nombre'];
    final manoDominante = data?['mano'] ?? 'Añadir';
    final posicionPreferida = data?['posicion'] ?? 'Añadir';

    final partidosSnap = await FirebaseFirestore.instance
        .collection('partidos')
        .orderBy('fecha', descending: true)
        .get();

    int jugados = 0, ganados = 0, empatados = 0, perdidos = 0;

    for (var doc in partidosSnap.docs) {
      final data = doc.data();
      final ganador = data['ganador'];
      final pareja1 = List<String>.from(data['pareja1'] ?? []);
      final pareja2 = List<String>.from(data['pareja2'] ?? []);

      if (pareja1.contains(nombreUsuario) || pareja2.contains(nombreUsuario)) {
        jugados++;
        if (ganador == 'empate') {
          empatados++;
        } else if ((ganador == 'pareja1' && pareja1.contains(nombreUsuario)) ||
            (ganador == 'pareja2' && pareja2.contains(nombreUsuario))) {
          ganados++;
        } else {
          perdidos++;
        }
      }
    }

    setState(() {
      userStats = {
        'jugados': jugados,
        'ganados': ganados,
        'empatados': empatados,
        'perdidos': perdidos,
        'nombre': nombreUsuario,
        'mano': manoDominante,
        'posicion': posicionPreferida,
      };
    });
  }

  Future<void> fetchLastMatch() async {
    if (user == null) return;

    final userDoc = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(user!.uid)
        .get();
    final nombreUsuario = userDoc.data()?['nombre'];

    final partidosSnap = await FirebaseFirestore.instance
        .collection('partidos')
        .orderBy('fecha', descending: true)
        .get();

    for (var doc in partidosSnap.docs) {
      final data = doc.data();
      final pareja1 = List<String>.from(data['pareja1'] ?? []);
      final pareja2 = List<String>.from(data['pareja2'] ?? []);
      if (pareja1.contains(nombreUsuario) || pareja2.contains(nombreUsuario)) {
        setState(() {
          lastMatch = {
            'fecha': (data['fecha'] as Timestamp).toDate(),
            'pareja1': data['pareja1'],
            'pareja2': data['pareja2'],
            'ganador': data['ganador'],
            'sets': data['sets'],
            'usuario': nombreUsuario,
          };
        });
        break;
      }
    }
  }

  String _formatearFecha(DateTime fecha) {
    return '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year.toString().substring(2)}';
  }

  Widget _buildMatchCard(Map<String, dynamic> partido) {
    final userNombre = partido['usuario'];
    final estaEnPareja1 = (partido['pareja1'] as List).contains(userNombre);
    final estaEnPareja2 = (partido['pareja2'] as List).contains(userNombre);

    Color bgColor = Colors.grey[200]!;
    IconData icon = Icons.help;
    Color iconColor = Colors.grey;

    if (partido['ganador'] == 'pareja1' && estaEnPareja1 ||
        partido['ganador'] == 'pareja2' && estaEnPareja2) {
      bgColor = Colors.green[100]!;
      icon = Icons.emoji_events;
      iconColor = Colors.green;
    } else if (partido['ganador'] == 'pareja1' && estaEnPareja2 ||
        partido['ganador'] == 'pareja2' && estaEnPareja1) {
      bgColor = Colors.red[100]!;
      icon = Icons.close;
      iconColor = Colors.red;
    }

    return Card(
      color: bgColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor),
                SizedBox(width: 10),
                Text(
                  'Último partido jugado',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              '(${_formatearFecha(partido['fecha'])})',
              style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${partido['pareja1'][0]} / ${partido['pareja1'][1]}',
                  style: TextStyle(fontSize: 18),
                ),
                Text(
                  'vs',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                Text(
                  '${partido['pareja2'][0]} / ${partido['pareja2'][1]}',
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

  Widget _buildStatRow(String label, int value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500)),
          Text(value.toString(),
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: userStats == null
            ? Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (lastMatch != null)
                _buildMatchCard(lastMatch!),
              SizedBox(height: 20),
              Card(
                elevation: 5,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.bar_chart,
                              color: Colors.green, size: 28),
                          SizedBox(width: 10),
                          Text(
                            "Estadísticas de partidos",
                            style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                      _buildStatRow("Jugados", userStats!['jugados']),
                      _buildStatRow("Ganados", userStats!['ganados']),
                      _buildStatRow("Empatados", userStats!['empatados']),
                      _buildStatRow("Perdidos", userStats!['perdidos']),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 30),
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "🎾 Preferencias del jugador",
                        style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 18),
                      Row(
                        children: [
                          Icon(Icons.pan_tool_alt, color: Colors.green),
                          SizedBox(width: 10),
                          Text(
                            "Mano dominante: ",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 20),
                          ),
                          Expanded(
                            child: Text(
                              userStats!['mano'],
                              style: TextStyle(fontSize: 20),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(Icons.sports_tennis, color: Colors.green),
                          SizedBox(width: 10),
                          Text(
                            "Posición preferida: ",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 20),
                          ),
                          Expanded(
                            child: Text(
                              userStats!['posicion'],
                              style: TextStyle(fontSize: 20),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
