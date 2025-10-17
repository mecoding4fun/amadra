// ignore_for_file: unused_import

import 'package:AMADRA/login.dart';
import 'package:AMADRA/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() {
  runApp(MaterialApp(
    home: SignUp(),
  ));
}

class SignUp extends StatefulWidget {
  @override
  State<SignUp> createState() => SignUpState();
}

class SignUpState extends State<SignUp> {
  final formKey = GlobalKey<FormState>();

  final TextEditingController EMcontroller = TextEditingController();
  final TextEditingController PAcontroller = TextEditingController();
  final TextEditingController NAcontroller = TextEditingController();
  final TextEditingController Ucontroller = TextEditingController();

  Future<void> signup() async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
              email: EMcontroller.text.trim(),
              password: PAcontroller.text.trim());

      User? user = userCredential.user;
      if (user != null) {
        String uid = user.uid;
        await FirebaseFirestore.instance.collection("users").doc(uid).set({
          "uid": uid,
          "name": NAcontroller.text.trim(),
          "username": Ucontroller.text.trim(),
          "email": EMcontroller.text.trim(),
          "bio": "",
          "profilePic": "",
          "createdAt": FieldValue.serverTimestamp(),
          "communities": ['common']
        });
      }
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => BottomAppDem()),
      );
    } catch (e) {
      showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text("Login failed"),
              content: Text("Email or Password entered is wrong!"),
              actions: [
                TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text("OK"))
              ],
            );
          });
      print(e);
    }
  }

  InputDecoration inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade400),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.blue.shade300),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFE0F7FA),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 16,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset('assets/amadra.png', height: 120),
                SizedBox(height: 24),
                Text(
                  "Sign up",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "Create an account, it's free",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                ),
                SizedBox(height: 24),
                Form(
                  key: formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: NAcontroller,
                        decoration: inputDecoration("Name"),
                        validator: (value) => value == null || value.isEmpty
                            ? "Enter Name"
                            : null,
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: Ucontroller,
                        decoration: inputDecoration("Username"),
                        validator: (value) => value == null || value.isEmpty
                            ? "Enter Username"
                            : null,
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: EMcontroller,
                        decoration: inputDecoration("Email"),
                        validator: (value) => value == null || value.isEmpty
                            ? "Enter email"
                            : null,
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: PAcontroller,
                        decoration: inputDecoration("Password"),
                        obscureText: true,
                        validator: (value) => value == null || value.isEmpty
                            ? "Enter password"
                            : null,
                      ),
                      SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (formKey.currentState!.validate()) {
                              await signup();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            padding: EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(
                            "Sign Up",
                            style: TextStyle(fontSize: 18),
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Already have an account? ",
                            style: TextStyle(color: Colors.black54),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => LoginPage()),
                              );
                            },
                            child: Text(
                              "Log In",
                              style: TextStyle(
                                color: Colors.blue.shade700,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          )
                        ],
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
