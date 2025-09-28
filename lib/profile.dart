import 'dart:io';

import 'package:AMADRA/Todo.dart';
import 'package:AMADRA/login.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Profile extends StatefulWidget {
  @override
  State<Profile> createState() => ProfileState();
}

class ProfileState extends State<Profile> {
  String? _profilePicPath;
  String username = '';
  String name = '';
  String email = '';
  String bio = '';

  @override
  void initState() {
    super.initState();
    _loadProfilePic();
    fetch();
  }

  Future<void> fetch() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final userDoc =
          await FirebaseFirestore.instance.collection("users").doc(user.uid).get();

      setState(() {
        username = userDoc.data()?['username'] ?? '';
        name = userDoc.data()?['name'] ?? '';
        email = userDoc.data()?['email'] ?? '';
        bio = userDoc.data()?['bio']??'';
      });
    } catch (e) {
      print(e);
    }
  }

  Future<void> _loadProfilePic() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _profilePicPath = prefs.getString('profilePicPath');
    });
  }

  Future<void> _pickAndSaveProfilePic() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profilePicPath', pickedFile.path);

      setState(() {
        _profilePicPath = pickedFile.path;
      });
    }
  }

  Future<void> logout()async{
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>LoginPage()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Profile"),
        centerTitle: true,
        elevation: 0,
        actions: [IconButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context)=>AlertDialog(
                title: Text("Logout?"),
                actions: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      ElevatedButton(
                        onPressed: (){logout();},
                        child: Text("Yes")
                      ),
                      ElevatedButton(
                        onPressed: (){Navigator.pop(context);},
                        child: Text("No")
                      ),
                    ],
                  )
                ],
              ));
            },
            icon: Icon(Icons.logout))],
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: _pickAndSaveProfilePic,
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.grey[300],
                  backgroundImage: _profilePicPath != null
                      ? FileImage(File(_profilePicPath!))
                      : null,
                  child: _profilePicPath == null
                      ? Icon(Icons.account_circle,
                          size: 120, color: Colors.grey[600])
                      : null,
                ),
              ),
              SizedBox(height: 20),
              Text(
                name.isNotEmpty ? name : "Your Name",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 6),
              Text(
                username.isNotEmpty ? "@$username" : "@username",
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              SizedBox(height: 20),
              Card(
                margin: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: Icon(Icons.person, color: Colors.blueGrey),
                  title: Text(
                    username.isNotEmpty ? username : "No username",
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
              Card(
                margin: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: Icon(Icons.email, color: Colors.blueGrey),
                  title: Text(
                    email.isNotEmpty ? email : "Email not set",
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
              Card(
                margin: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: Icon(Icons.info, color: Colors.blueGrey),
                  title: Text(
                    bio.isNotEmpty ? bio : "",
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
