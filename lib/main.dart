
import 'package:AMADRA/launcher.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabaseLib;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'Home.dart';
import 'profile.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'splash_screen.dart'; 

Future<void> saveDeviceToken(String uid) async {
  final fcm = FirebaseMessaging.instance;
  final token = await fcm.getToken();
  if (token != null) {
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'fcmToken': token,
    }, SetOptions(merge: true));
  }

  FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'fcmToken': newToken,
    }, SetOptions(merge: true));
  });
}

Future<String?> getImage() async {
  final docSnapshot = await FirebaseFirestore.instance
      .collection('users')
      .doc(FirebaseAuth.instance.currentUser!.uid)
      .get();

  if (docSnapshot.exists) {
    return docSnapshot.data()?['profilePic'] as String?;
  } else {
    return null;
  }
}


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await supabaseLib.Supabase.initialize(
    url: 'SUPABASEURL',
    anonKey:
        'SUPABASEANON',
  );

  await FirebaseMessaging.instance.requestPermission();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // title: "AMADRA",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.deepPurple,
        scaffoldBackgroundColor: Colors.white,
        colorScheme: const ColorScheme.light(
          primary: Colors.deepPurple,
          surface: Colors.white,
          onPrimary: Colors.black,
          onSurface: Colors.black,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: Colors.deepPurple,
          unselectedItemColor: Colors.grey,
        ),
        fontFamily: 'Lato',
        textTheme: TextTheme(
          bodyMedium: const TextStyle(fontFamily: 'Lato', fontSize: 16),
          bodySmall:
              const TextStyle(fontFamily: 'RobotoCondensed', fontSize: 14),
          titleLarge: const TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 24,
              fontWeight: FontWeight.bold),
          titleMedium: const TextStyle(
              fontFamily: 'Raleway', fontSize: 20, fontWeight: FontWeight.w600),
          labelLarge: const TextStyle(fontFamily: 'ZalandoSans', fontSize: 16),
          labelSmall: TextStyle(color: Colors.grey[600], fontSize: 14),
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
              fontFamily: 'RobotoCondensed',
              fontSize: 14,
              color: Colors.white70),
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
          labelLarge: TextStyle(
              fontFamily: 'ZalandoSans', fontSize: 16, color: Colors.white70),
        ),
      ),
      themeMode: ThemeMode.light,
      home: SplashScreen(),
    );
  }
}

class BottomAppDem extends StatefulWidget {
  @override
  State<BottomAppDem> createState() => BottomAppDemState();
}

class BottomAppDemState extends State<BottomAppDem> {
  String imageUrl="";
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
        // backgroundColor: Color(0xFF64B5F6),
        currentIndex: ind,
        onTap: ontap,
        selectedItemColor: Colors.deepPurple.shade400,
        unselectedItemColor: Colors.black,
        items:  [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: FutureBuilder<String?>(
              future: getImage(), 
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Icon(Icons.account_circle, size: 30);
                } else if (snapshot.hasError || snapshot.data == null || snapshot.data!.isEmpty||snapshot.data=="") {
                  return Icon(Icons.account_circle, size: 30);
                } else {
                  return ClipOval(
                    child: Image.network(
                      snapshot.data!,
                      width: 30,
                      height: 30,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Icon(Icons.account_circle, size: 30),
                    ),
                  );
                }
              },
            ),
            label: "Profile",
          )
        ],
      ),
    );
  }
}
