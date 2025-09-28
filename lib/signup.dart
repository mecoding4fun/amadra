// ignore_for_file: unused_import

import 'package:AMADRA/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
void main(){
  runApp(
    MaterialApp(
      home:SignUp(),
    )
  );
}

class SignUp extends StatefulWidget{
  @override
  State<SignUp> createState() => SignUpState();
}

class SignUpState extends State<SignUp>{
   final formKey = GlobalKey<FormState>();

  final TextEditingController EMcontroller = TextEditingController();
  final TextEditingController PAcontroller = TextEditingController();
  final TextEditingController NAcontroller = TextEditingController();
  final TextEditingController Ucontroller = TextEditingController();

  Future<void> signup() async {
    try{
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: EMcontroller.text.trim(),
          password: PAcontroller.text.trim()
        );

        User? user =userCredential.user;
        if(user!=null){
          String uid= user.uid;
          await FirebaseFirestore.instance.collection("users").doc(uid).set({
            "uid":uid,
            "name":NAcontroller.text.trim(),
            "username":Ucontroller.text.trim(),
            "email":EMcontroller.text.trim(),
            "bio":"",
            "profilePic":"",
            "createdAt": FieldValue.serverTimestamp()
          });
        }
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
                Text("Sign Up",style: TextStyle(fontSize: 25,fontWeight: FontWeight.bold)),
                TextFormField(
                  controller: NAcontroller,
                  decoration: const InputDecoration(labelText: "Name"),
                  validator: (value) =>
                      value == null || value.isEmpty ? "Enter Name" : null,
                ),
                TextFormField(
                  controller: Ucontroller,
                  decoration: const InputDecoration(labelText: "Username"),
                  validator: (value) =>
                      value == null || value.isEmpty ? "Enter Username" : null,
                ),
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
                      await signup();
                    }
                  },
                  child: const Text("Sign up"),
                ),
              ],
            ),
          ),
        ),
      )
    );
  }
}