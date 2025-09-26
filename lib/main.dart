// ignore_for_file: prefer_const_literals_to_create_immutables

import 'package:AMADRA/login.dart';
import 'package:flutter/material.dart';
import 'Todo.dart';
import 'net.dart';
import 'package:firebase_core/firebase_core.dart';
import 'form.dart';
import 'sw.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget{
  const MyApp({super.key});

  @override
  Widget build(BuildContext context){
    return MaterialApp(
      home: LoginPage(),
    );
  }
}

class BottomAppDem extends StatefulWidget{
  @override

  State<BottomAppDem> createState()=> BottomAppDemState();
}

class BottomAppDemState extends State<BottomAppDem>{
  int ind = 0;

  final List<Widget> pages=[
    FormA(),
    Changer(),
    TodoScreen(),
    NetworkPage()
  ];

  void ontap(int index){
    setState(() {
      ind = index;
    });
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      body: pages[ind],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: ind,
        onTap: ontap,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.article, color: Colors.black,), label: "Form"),
          BottomNavigationBarItem(icon: Icon(Icons.add, color: Colors.black,), label: "Counter"),
          BottomNavigationBarItem(icon: Icon(Icons.checklist, color: Colors.black,), label: "Todo"),
          BottomNavigationBarItem(icon: Icon(Icons.network_cell, color: Colors.black,), label: "Network"),

        ],
      ),
    );
  }
}