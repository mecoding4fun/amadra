// ignore_for_file: prefer_const_literals_to_create_immutables

import 'package:AMADRA/launcher.dart';
import 'package:AMADRA/login.dart';
import 'package:AMADRA/profile.dart';
import 'package:AMADRA/signup.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart'; 
import 'Home.dart';
import 'sw.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
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
          titleLarge: TextStyle(fontFamily: 'Montserrat', fontSize: 24, fontWeight: FontWeight.bold),
          titleMedium: TextStyle(fontFamily: 'Raleway', fontSize: 20, fontWeight: FontWeight.w600),
          labelLarge: TextStyle(fontFamily: 'ZalandoSans', fontSize: 16),
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            textStyle: TextStyle(fontFamily: 'RobotoCondensed', fontSize: 16),
          ),
        ),
      ),

      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.deepPurple,
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
        ),
        fontFamily: 'Lato',
        textTheme: TextTheme(
          bodyMedium: TextStyle(fontFamily: 'Lato', fontSize: 16, color: Colors.white),
          bodySmall: TextStyle(fontFamily: 'RobotoCondensed', fontSize: 14, color: Colors.white70),
          titleLarge: TextStyle(fontFamily: 'Montserrat', fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          titleMedium: TextStyle(fontFamily: 'Raleway', fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
          labelLarge: TextStyle(fontFamily: 'ZalandoSans', fontSize: 16, color: Colors.white70),
        ),
      ),

      themeMode: ThemeMode.light,

      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasData) {
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

  final List<Widget> pages = [
    HomeScreen(),
    Profile(),
  ];

  void ontap(int index) {
    setState(() {
      ind = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[ind],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: ind,
        onTap: ontap,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home, color: Colors.black),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle, color: Colors.black),
            label: "Profile",
          ),
        ],
      ),
    );
  }
}