import 'dart:async';
import 'package:elitepadelapp/home_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter/material.dart';

import 'package:elitepadelapp/login_page.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(ElitePadelApp());
}

class ElitePadelApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Élite Pádel',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: SplashScreen(), // mostramos primero el splash
    );
  }
}

class SplashScreen extends StatefulWidget {
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navegarSegunLogin();
  }

  void _navegarSegunLogin() async {
    await Future.delayed(Duration(seconds: 3));

    final user = FirebaseAuth.instance.currentUser;

    final siguientePantalla = user != null ? HomePage(): LoginPage();

    Navigator.of(context).pushReplacement(_crearRutaFade(siguientePantalla));
  }

  PageRouteBuilder _crearRutaFade(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      transitionDuration: Duration(milliseconds: 800),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF4CAF50), // fondo verde
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/nuevoelite.png', // logo
              width: 350,
              height: 350,
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
