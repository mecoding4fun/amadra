import 'package:AMADRA/login.dart';
import 'package:AMADRA/signup.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(
    MaterialApp(
      home: launcher(),
    ),
  );
}

class launcher extends StatefulWidget {
  @override
  State<launcher> createState() => _LauncherState();
}

class _LauncherState extends State<launcher> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/amadra.png',
                  height: 200,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(context,
                            MaterialPageRoute(builder: (context) => SignUp()));
                      },
                      child: Text("Sign Up"),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => LoginPage()));
                      },
                      child: Text("Login"),
                    ),
                  ],
                ),
                SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
