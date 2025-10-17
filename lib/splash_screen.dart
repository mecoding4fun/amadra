import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:AMADRA/launcher.dart';
import 'package:AMADRA/main.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 2), checkLoginStatus);
  }

  Future<void> saveDeviceToken(String uid) async {
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'deviceToken': token,
      });
    }
  }

  void checkLoginStatus() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      saveDeviceToken(user.uid);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => BottomAppDem()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => launcher()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Replace with your actual app logo asset
            Image.asset(
              'assets/amadra.png',
              height: 240,
              width: 240,
            ),
            const SizedBox(height: 20),
            const Text(
              "AMADRA",
              style: TextStyle(
                color: Color.fromARGB(255, 0, 0, 0),
                fontSize: 28,
                fontWeight: FontWeight.bold,
                fontFamily: 'Raleway',
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
