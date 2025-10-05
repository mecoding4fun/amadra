import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class ProfileUpdate extends StatefulWidget {
  @override
  State<ProfileUpdate> createState() => _ProfileUpdateState();
}

class _ProfileUpdateState extends State<ProfileUpdate> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController community = TextEditingController();

  String? _profileUrl;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc =
        await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final data = doc.data();
    if (data == null) return;

    setState(() {
      _nameController.text = data['name'] ?? '';
      _usernameController.text = data['username'] ?? '';
      _bioController.text = data['bio'] ?? '';
      _profileUrl = data['profilePic'] ?? '';
      community.text = data['community'];
    });
  }

  Future<void> _pickAndUploadProfilePic() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    setState(() {
      _loading = true;
    });

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
    } catch (e) {
      print('Supabase upload error: $e');
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final userId = FirebaseAuth.instance.currentUser!.uid;

    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'name': _nameController.text.trim(),
      'username': _usernameController.text.trim(),
      'bio': _bioController.text.trim(),
      'profilePic': _profileUrl ?? '',
      'community':community.text.trim()
    });

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Update Profile"),
        centerTitle: true,
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _pickAndUploadProfilePic,
                      child: CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.grey[300],
                        backgroundImage: _profileUrl != null && _profileUrl!.isNotEmpty
                            ? NetworkImage(_profileUrl!)
                            : null,
                        child: _profileUrl == null || _profileUrl!.isEmpty
                            ? Icon(Icons.account_circle, size: 120, color: Colors.grey[600])
                            : null,
                      ),
                    ),
                    SizedBox(height: 20),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Name cannot be empty';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 12),
                    TextFormField(
                      controller: _usernameController,
                      decoration: InputDecoration(
                        labelText: 'Username',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Username cannot be empty';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 12),
                    TextFormField(
                      controller: _bioController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Bio (optional)',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value != null && value.length > 150) {
                          return 'Bio cannot exceed 150 characters';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 12),
                    TextFormField(
                      controller: community,
                      decoration: InputDecoration(
                        labelText: 'Community (optional) default: common',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value != null && value.length > 150) {
                          return 'community name cannot exceed 150 characters';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _saveProfile,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                        child: Text('Save', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
