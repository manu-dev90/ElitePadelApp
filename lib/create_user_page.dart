import 'package:elitepadelapp/main.dart';
import 'package:flutter/material.dart';
import 'package:elitepadelapp/login_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CreateUser extends StatefulWidget {
  @override
  State<CreateUser> createState() => _CreateUser();
}

class _CreateUser extends State<CreateUser> {
  final _nameUser = TextEditingController();
  final _emailUser = TextEditingController();
  final _passwordUser = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  void _createAccount() async {
    String name = _nameUser.text.trim();
    String email = _emailUser.text.trim();
    String pass = _passwordUser.text.trim();
    String confirmPass = _confirmPassword.text.trim();

    if (name.isEmpty || email.isEmpty || pass.isEmpty || confirmPass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Rellena todos los campos')),
      );
      return;
    }

    if (pass != confirmPass) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Las contraseñas no coinciden')),
      );
      return;
    }

    try {
      // Crear el usuario con Firebase
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: pass,
      );

      // Enviar correo de verificación
      await userCredential.user?.sendEmailVerification();

      // Guardar usuario en Firestore
      await FirebaseFirestore.instance.collection('usuarios').doc(userCredential.user!.uid).set({
        'nombre': name,
        'email': email,
        'fechaRegistro': Timestamp.now(),
        'emailVerificado': false,
        'puntos': 0,

      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Usuario creado. Revisa tu correo para verificar la cuenta.')),
      );


      // Navega al Home o login si lo prefieres
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => LoginPage()),
      );
    } on FirebaseAuthException catch (e) {
      String error = 'Ha ocurrido un error';
      if (e.code == 'email-already-in-use') {
        error = 'El correo ya está en uso';
      } else if (e.code == 'invalid-email') {
        error = 'Correo no válido';
      } else if (e.code == 'weak-password') {
        error = 'La contraseña es muy débil';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(40),
        child: Column(
          children: [
            SizedBox(height: 80),
            Text(
              'Crear usuario',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 40),
            TextField(
              controller: _nameUser,
              decoration: InputDecoration(
                hintText: 'Nombre',
                filled: true,
                fillColor: Colors.grey[100],
                prefixIcon: Icon(Icons.person),
                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade600, width: 1),
                ),
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _emailUser,
              decoration: InputDecoration(
                hintText: 'Email',
                filled: true,
                fillColor: Colors.grey[100],
                prefixIcon: Icon(Icons.email),
                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade600, width: 1),
                ),
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _passwordUser,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                hintText: 'Contraseña',
                filled: true,
                fillColor: Colors.grey[100],
                prefixIcon: Icon(Icons.lock),
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
                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade600, width: 1),
                ),
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _confirmPassword,
              obscureText: _obscureConfirm,
              decoration: InputDecoration(
                hintText: 'Confirmar contraseña',
                filled: true,
                fillColor: Colors.grey[100],
                prefixIcon: Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureConfirm = !_obscureConfirm;
                    });
                  },
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade600, width: 1),
                ),
              ),
            ),
            SizedBox(height: 60),
            ElevatedButton(
              onPressed: _createAccount,
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
              child: Text('Crear cuenta'),
            ),
            TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => LoginPage()),
                  );
                },
              child: Text('¿Ya tienes cuenta? Inicia sesión',
              style: TextStyle(
                  color: Colors.black,
                  fontSize: 15,
                  fontWeight: FontWeight.w400,),
              )
            )
          ],
        ),
      ),
    );
  }
}
