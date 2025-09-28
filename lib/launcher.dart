import 'package:AMADRA/login.dart';
import 'package:AMADRA/signup.dart';
import 'package:flutter/material.dart';

void main(){
  runApp(
    MaterialApp(
      home: launcher()
    )
  );
}

class launcher extends StatefulWidget{
  @override
  State<launcher> createState() => launcherState();
}

class launcherState extends State<launcher>{
  @override 
  Widget build(BuildContext context){
    return Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/amadra.png'),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  SizedBox(width: 30,),
                  ElevatedButton(
                    onPressed: (){
                      Navigator.push(context, MaterialPageRoute(builder: (context)=>SignUp()));
                    }, 
                    child: Text("Sign Up")
                  ),
                  ElevatedButton(
                    onPressed: (){
                      Navigator.push(context, MaterialPageRoute(builder: (context)=>LoginPage()));
                    }, 
                    child: Text("Login")
                  ),
                  SizedBox(width: 30,)
                ],
              ),
              SizedBox(height: 60,)
            ],
          ),
        ),
      ),
    );
  }
}