import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ClassificationPage extends StatefulWidget {
  @override
  _ClassificationPageState createState() => _ClassificationPageState();
}

class _ClassificationPageState extends State<ClassificationPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Clasificación', style: TextStyle(fontSize: 24)),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('usuarios')
            .orderBy('puntos', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          final users = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final usuario = users[index];
              final nombre = usuario['nombre'];
              final puntos = usuario['puntos'] ?? 0;

              Color avatarColor;
              switch (index) {
                case 0:
                  avatarColor = Colors.amber;
                  break;
                case 1:
                  avatarColor = Colors.grey;
                  break;
                case 2:
                  avatarColor = Colors.brown[300]!;
                  break;
                default:
                  avatarColor = Colors.grey.shade300;
              }

              return Card(
                elevation: 3,
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  leading: CircleAvatar(
                    radius: 24,
                    backgroundColor: avatarColor,
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  title: Text(
                    nombre,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                  trailing: Text(
                    '$puntos pts',
                    style: TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
