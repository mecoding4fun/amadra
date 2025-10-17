// ignore_for_file: unused_import, unnecessary_import

import 'package:AMADRA/main.dart';
import 'package:AMADRA/signup.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() {
  runApp(MaterialApp(
    home: LoginPage(),
  ));
}

class LoginPage extends StatefulWidget {
  @override
  State<LoginPage> createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> {
  final formKey = GlobalKey<FormState>();

  final TextEditingController EMcontroller = TextEditingController();
  final TextEditingController PAcontroller = TextEditingController();

  Future<void> login() async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: EMcontroller.text.trim(), password: PAcontroller.text.trim());
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
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE0F7FA),
      body: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 16,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset('assets/amadra.png', height: 140),
                  const SizedBox(height: 24),
                  const Text(
                    "Welcome",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Here you log in securely",
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: EMcontroller,
                    decoration: inputDecoration("Email"),
                    validator: (value) =>
                        value == null || value.isEmpty ? "Enter email" : null,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: PAcontroller,
                    decoration: inputDecoration("Password"),
                    obscureText: true,
                    validator: (value) => value == null || value.isEmpty
                        ? "Enter password"
                        : null,
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFE0F7FA),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      onPressed: () {
                        if (formKey.currentState!.validate()) {
                          login();
                        }
                      },
                      child: const Text(
                        "Log in",
                        style:
                            TextStyle(fontSize: 18, color: Colors.deepPurple),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        // backgroundColor: Color(0xFFE0F7FA),
                        side: BorderSide(color: Color(0xFFE0F7FA), width: 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SignUp(),
                          ),
                        );
                      },
                      child: Text(
                        "Sign Up",
                        style: TextStyle(
                          fontSize: 18,
                          color: Color.fromARGB(255, 152, 203, 209),
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) => ForgotPassword()),
                      );
                    },
                    child: Text(
                      "Forgot Password?",
                      style: TextStyle(
                        // color: Colors.blue.shade700,
                        // fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ForgotPassword extends StatefulWidget {
  @override
  State<ForgotPassword> createState() => FpState();
}

class FpState extends State<ForgotPassword> {
  final formKey = GlobalKey<FpState>();
  final TextEditingController EMcontroller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Reset Password")),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Form(
              key: formKey,
              child: Column(
                children: [
                  Text("Reset password"),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: EMcontroller,
                    decoration: const InputDecoration(labelText: "Email"),
                    validator: (value) =>
                        value == null || value.isEmpty ? "Enter email" : null,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                      onPressed: () async {
                        try {
                          await FirebaseAuth.instance.sendPasswordResetEmail(
                              email: EMcontroller.text.trim());
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => LoginPage()));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text("Password reset mail sent!")),
                          );
                        } catch (e) {
                          print(e);
                        }
                      },
                      child: Text("Reset"))
                ],
              )),
        ),
      ),
    );
  }
}
