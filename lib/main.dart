// ignore_for_file: prefer_const_literals_to_create_immutables

import 'dart:io';
import 'package:AMADRA/launcher.dart';
import 'package:AMADRA/login.dart';
import 'package:AMADRA/signup.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabaseLib;
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'Home.dart';
import 'profile.dart';
import 'sw.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

Future<void> saveDeviceToken(String uid) async {
  final fcm = FirebaseMessaging.instance;
  final token = await fcm.getToken();
  if (token != null) {
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'fcmToken': token,
    }, SetOptions(merge: true));
  }

  // Keep Firestore updated when token refreshes
  FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'fcmToken': newToken,
    }, SetOptions(merge: true));
  });
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await supabaseLib.Supabase.initialize(
    url: 'https://vgwllhhomzbgolazgaba.supabase.co',
    anonKey: 'your-anon-key-here',
  );

  final fcm = FirebaseMessaging.instance;

  // Ask permissions (especially on iOS)
  await fcm.requestPermission();

  // Local notifications setup




  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "AMADRA",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.deepPurple,
        fontFamily: 'Lato',
        textTheme: TextTheme(
          bodyMedium: TextStyle(fontFamily: 'Lato', fontSize: 16),
          bodySmall: TextStyle(fontFamily: 'RobotoCondensed', fontSize: 14),
          titleLarge: TextStyle(
              fontFamily: 'Montserrat', fontSize: 24, fontWeight: FontWeight.bold),
          titleMedium: TextStyle(
              fontFamily: 'Raleway', fontSize: 20, fontWeight: FontWeight.w600),
          labelLarge: TextStyle(fontFamily: 'ZalandoSans', fontSize: 16),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
              textStyle: TextStyle(fontFamily: 'RobotoCondensed', fontSize: 16)),
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.deepPurple,
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: const AppBarTheme(backgroundColor: Colors.black),
        fontFamily: 'Lato',
        textTheme: TextTheme(
          bodyMedium:
              TextStyle(fontFamily: 'Lato', fontSize: 16, color: Colors.white),
          bodySmall: TextStyle(
              fontFamily: 'RobotoCondensed', fontSize: 14, color: Colors.white70),
          titleLarge: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white),
          titleMedium: TextStyle(
              fontFamily: 'Raleway',
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white),
          labelLarge:
              TextStyle(fontFamily: 'ZalandoSans', fontSize: 16, color: Colors.white70),
        ),
      ),
      themeMode: ThemeMode.light,
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          if (snapshot.hasData) {
            // ✅ Save device token whenever user logs in
            saveDeviceToken(snapshot.data!.uid);
            return BottomAppDem();
          }
          return launcher();
        },
      ),
    );
  }
}

class BottomAppDem extends StatefulWidget {
  @override
  State<BottomAppDem> createState() => BottomAppDemState();
}

class BottomAppDemState extends State<BottomAppDem> {
  int ind = 0;
  final List<Widget> pages = [HomeScreen(), Profile()];

  void ontap(int index) {
    setState(() => ind = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[ind],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: ind,
        onTap: ontap,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home, color: Colors.black), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.account_circle, color: Colors.black), label: "Profile"),
        ],
      ),
    );
  }
}
