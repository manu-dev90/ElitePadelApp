
import 'package:elitepadelapp/home_page.dart';
import 'package:flutter/material.dart';
import 'package:elitepadelapp/create_user_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginPage extends StatefulWidget {
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _userController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  void _login() async {
    String email = _userController.text.trim();
    String password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Introduce usuario y contraseña')),
      );
      return;
    }

    try {
      // Inicia sesión con Firebase Auth
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      User? user = FirebaseAuth.instance.currentUser;

      if (user != null && !user.emailVerified) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Por favor, verifica tu correo antes de continuar.')),
        );
        await FirebaseAuth.instance.signOut();
        return;
      }

      // 🔎 Verificar si existe en la colección 'usuarios'
      final userDoc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user!.uid)
          .get();

      if (!userDoc.exists) {
        await FirebaseAuth.instance.signOut();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tu cuenta ha sido eliminada o no existe en la base de datos.')),
        );
        return;
      }

      // ✅ Actualizar verificado si es necesario
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .update({'emailVerificado': true});

      // 🎉 Acceder a la app
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomePage()),
      );
    } on FirebaseAuthException catch (e) {
      print('Código de error: ${e.code}');
      String errorMessage = 'Error al iniciar sesión';

      if (e.code == 'user-not-found') {
        errorMessage = 'No existe ninguna cuenta con ese correo.';
      } else if (e.code == 'wrong-password') {
        errorMessage = 'La contraseña es incorrecta.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'El correo no tiene un formato válido.';
      } else if (e.code == 'user-disabled') {
        errorMessage = 'La cuenta ha sido deshabilitada.';
      } else if (e.code == 'invalid-credential') {
        errorMessage = 'Correo o contraseña incorrectos.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    }
  }

  void _createUser() {
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => CreateUser()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(top: 100, left: 40, right: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset('assets/nuevoelite.png', height: 250),
              SizedBox(height: 0),
              TextField(
                controller: _userController,
                decoration: InputDecoration(
                  hintText: 'Email',
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              SizedBox(height: 10),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: 'Contraseña',
                  filled: true,
                  fillColor: Colors.white,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
              ),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    final TextEditingController emailResetController = TextEditingController();

                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('Recuperar contraseña'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Introduce tu correo para enviarte un enlace de recuperación.'),
                            SizedBox(height: 10),
                            TextField(
                              controller: emailResetController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                hintText: 'Correo electrónico',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text('Cancelar'),
                          ),
                          TextButton(
                            onPressed: () {
                              final email = emailResetController.text.trim();

                              if (email.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Introduce un correo válido')),
                                );
                                return;
                              }

                              FirebaseAuth.instance
                                  .sendPasswordResetEmail(email: email)
                                  .then((_) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Correo de recuperación enviado')),
                                );
                              }).catchError((e) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error al enviar el correo')),
                                );
                              });
                            },
                            child: Text('Enviar'),
                          ),
                        ],
                      ),
                    );
                  },

                  child: Text(
                    '¿Olvidaste tu contraseña?',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 50),
              ElevatedButton(
                onPressed: _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  elevation: 3,
                  shadowColor: Colors.grey[500],
                  minimumSize: Size(250, 45),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Text('Iniciar sesión'),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _createUser,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  elevation: 3,
                  shadowColor: Colors.grey[500],
                  minimumSize: Size(250, 45),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Text('Crear Usuario'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
