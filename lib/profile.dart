import 'dart:io';
import 'package:AMADRA/login.dart';
import 'package:AMADRA/profileUpdate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class Profile extends StatefulWidget {
  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  String username = '';
  String name = '';
  String email = '';
  String bio = '';
  List<String> comms = [];
  String? _profileUrl;

  @override
  void initState() {
    super.initState();
    fetch();
  }

  Future<void> fetch() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .get();

      final data = userDoc.data();
      if (data == null) return;

      final List<dynamic>? comdata = data['communities'];
      final List<String> commList = comdata != null && comdata.isNotEmpty
          ? List<String>.from(comdata)
          : ['common'];

      setState(() {
        username = data['username'] ?? '';
        name = data['name'] ?? '';
        email = data['email'] ?? '';
        bio = data['bio'] ?? '';
        _profileUrl = data['profilePic'] ?? '';
        comms = commList;
      });
    } catch (e) {
      print("Error fetching profile: $e");
    }
  }

  Future<void> _pickAndUploadProfilePic() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    final file = File(pickedFile.path);
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final fileName = '$userId/profile.jpg';

    try {
      await supabase.storage.from('profile_pics').upload(
            fileName,
            file,
            fileOptions: FileOptions(upsert: true),
          );

      final url = supabase.storage.from('profile_pics').getPublicUrl(fileName);

      setState(() {
        _profileUrl = url;
      });

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({'profilePic': url});
    } catch (e) {
      print('Supabase upload error: $e');
    }
  }

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (context) => LoginPage()));
  }

  Future<void> fetchUserCommunities() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    try {
      final userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (userDoc.exists) {
        final List<dynamic>? data = userDoc.data()?['communities'];
        if (data != null && data.isNotEmpty) {
          setState(() {
            comms = List<String>.from(data);
          });
        } else {
          setState(() {
            comms = ['common']; // default
          });
        }
      }
    } catch (e) {
      print('Error fetching communities: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => ProfileUpdate()));
            },
            icon: Icon(Icons.edit)),
        title: Text("Profile"),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
              onPressed: () {
                showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                          title: Text("Logout?"),
                          actions: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                ElevatedButton(
                                    onPressed: logout, child: Text("Yes")),
                                ElevatedButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                    child: Text("No")),
                              ],
                            )
                          ],
                        ));
              },
              icon: Icon(Icons.logout))
        ],
      ),
      body: Center(
          child: RefreshIndicator(
        onRefresh: () async {
          await fetch();
        },
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: _pickAndUploadProfilePic,
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.grey[300],
                  backgroundImage:
                      _profileUrl != null && _profileUrl!.isNotEmpty
                          ? NetworkImage(_profileUrl!)
                          : null,
                  child: _profileUrl == null || _profileUrl!.isEmpty
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
              SizedBox(height: 6),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  // Deduplicate comms for display
                  Builder(
                    builder: (context) {
                      final uniqueComms = comms.where((c) => c.trim().isNotEmpty).toSet().toList();
                      return Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: uniqueComms.map((c) {
                          return Chip(
                            label: Text(
                              c,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.deepPurple,
                              ),
                            ),
                            backgroundColor: Colors.deepPurple.withOpacity(0.15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
              SizedBox(height: 20),
              Card(
                margin: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: Icon(Icons.person, color: Colors.deepPurple),
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
                  leading: Icon(Icons.email, color: Colors.deepPurple),
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
                  leading: Icon(Icons.info, color: Colors.deepPurple),
                  title: Text(
                    bio.isNotEmpty ? bio : "",
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      )),
    );
  }
}
