import 'package:AMADRA/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
void main(){
  runApp(
    MaterialApp(
      home:LoginPage(),
    )
  );
}

class LoginPage extends StatefulWidget{
  @override
  State<LoginPage> createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage>{
   final formKey = GlobalKey<FormState>();

  final TextEditingController EMcontroller = TextEditingController();
  final TextEditingController PAcontroller = TextEditingController();

  Future<void> login() async {
    try{
      await FirebaseAuth.instance.signInWithEmailAndPassword(email: EMcontroller.text.trim(), password: PAcontroller.text.trim());
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => BottomAppDem()),
      );
    }
    catch(e){
      showDialog(
        context: context,
        builder: (context){
          return AlertDialog(
            title: Text("Login failed"),
            content: Text("Email or Password entered is wrong!"),
            actions: [
              TextButton(
                onPressed: (){Navigator.pop(context);},
              child: Text("OK"))
            ],
          );
        }
      );
      print(e);
    }
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 75),
                Image.asset('assets/amadra.png', width: 300,height: 300),
                Text("Login",style: TextStyle(fontSize: 25,fontWeight: FontWeight.bold)),
                TextFormField(
                  controller: EMcontroller,
                  decoration: const InputDecoration(labelText: "Email"),
                  validator: (value) =>
                      value == null || value.isEmpty ? "Enter email" : null,
                ),
                TextFormField(
                  controller: PAcontroller,
                  decoration: const InputDecoration(labelText: "Password"),
                  obscureText: true,
                  validator: (value) =>
                      value == null || value.isEmpty ? "Enter password" : null,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      await login();
                    }
                  },
                  child: const Text("Submit"),
                ),
              ],
            ),
          ),
        ),
      )
    );
  }
}