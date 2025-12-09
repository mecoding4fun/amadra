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

  String? _profileUrl;
  bool _loading = false;

  List<String> _allCommunities = [];
  List<String> _selectedCommunities = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _fetchCommunities();
  }

  Future<void> _fetchCommunities() async {
    final snapshot = await FirebaseFirestore.instance.collection('communities').get();
    final communities = snapshot.docs.map((doc) => doc.id).toList();
    setState(() {
      _allCommunities = communities;
      if (!_allCommunities.contains('common')) {
        _allCommunities.add('common');
      }
    });
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final data = doc.data();
    if (data == null) return;
    final commList = List<String>.from(data['communities'] ?? ['common']);

    setState(() {
      _nameController.text = data['name'] ?? '';
      _usernameController.text = data['username'] ?? '';
      _bioController.text = data['bio'] ?? '';
      _profileUrl = data['profilePic'] ?? '';
      _selectedCommunities = commList.isNotEmpty ? commList : ['common'];
      if (!_allCommunities.contains('common')) {
        _allCommunities.add('common');
      }
      for (var comm in _selectedCommunities) {
        if (!_allCommunities.contains(comm)) {
          _allCommunities.add(comm);
        }
      }
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
  final timestamp = DateTime.now().millisecondsSinceEpoch;
  final fileName = '$userId/profile_$timestamp.jpg'; // unique file name

  try {
    // Upload to Supabase
    await supabase.storage.from('profile_pics').upload(
          fileName,
          file,
          fileOptions: FileOptions(upsert: true),
        );

    // Get the public URL
    final url = supabase.storage.from('profile_pics').getPublicUrl(fileName);

    // Update Firebase with the new URL
    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'profileUrl': url, // make sure your user doc uses this field
    });

    // Update local state
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


  Future<void> _addNewCommunity() async {
    await showDialog(
      context: context,
      builder: (context) {
        final _newCommController = TextEditingController();
        return AlertDialog(
          title: Text('Create new community'),
          content: TextField(
            controller: _newCommController,
            decoration: InputDecoration(hintText: 'Community name'),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final input = _newCommController.text.trim();
                if (input.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Community name cannot be empty')));
                  return;
                }
                if (input.length > 150) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Community name cannot exceed 150 characters')));
                  return;
                }

                // CASE-INSENSITIVE CHECK
                final existing = _allCommunities.firstWhere(
                    (c) => c.toLowerCase() == input.toLowerCase(),
                    orElse: () => '');
                if (existing.isNotEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Community already exists: $existing')));
                  return;
                }

                try {
                  await FirebaseFirestore.instance
                      .collection('communities')
                      .doc(input)
                      .set({
                    'createdAt': FieldValue.serverTimestamp(),
                    'createdBy': FirebaseAuth.instance.currentUser?.uid
                  });

                  setState(() {
                    _allCommunities.add(input);
                    if (_selectedCommunities.length < 10) {
                      _selectedCommunities.add(input);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Maximum of 10 communities allowed')));
                    }
                  });
                  Navigator.pop(context);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error adding community')));
                }
              },
              child: Text('Create'),
            ),
          ],
        );
      },
    );
  }


  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCommunities.isEmpty) {
      _selectedCommunities = ['common'];
    }

    if (!_selectedCommunities.contains('common')) {
      _selectedCommunities.add('common');
    }

    if (_selectedCommunities.length > 10) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('You can join up to 10 communities only')));
      return;
    }

    final userId = FirebaseAuth.instance.currentUser!.uid;

    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'name': _nameController.text.trim(),
      'username': _usernameController.text.trim(),
      'bio': _bioController.text.trim(),
      'profilePic': _profileUrl ?? '',
      'communities': _selectedCommunities,
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
    body: Stack(
      children: [
        SingleChildScrollView(
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
                // Name field
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.blue.shade100, width: 2),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.blue, width: 2),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Name cannot be empty';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 12),
                // Username field
                TextFormField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: 'Username',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.blue.shade100, width: 2),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.blue, width: 2),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Username cannot be empty';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 12),
                // Bio field
                TextFormField(
                  controller: _bioController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Bio (optional)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.blue.shade100, width: 2),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.blue, width: 2),
                    ),
                  ),
                  validator: (value) {
                    if (value != null && value.length > 150) {
                      return 'Bio cannot exceed 150 characters';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 12),
                // Communities
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Communities (select up to 10)', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
                SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    ..._allCommunities.map((comm) {
                      final selected = _selectedCommunities.contains(comm);
                      return FilterChip(
                        label: Text(comm),
                        selected: selected,
                        selectedColor: Colors.blue.shade100,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(color: Colors.blue)
                        ),
                        onSelected: (bool value) {
                          if (_loading) return; // prevent changes while loading
                          setState(() {
                            if (value) {
                              if (_selectedCommunities.length < 10) {
                                _selectedCommunities.add(comm);
                              }
                            } else {
                              if (comm == 'common') return;
                              _selectedCommunities.remove(comm);
                            }
                            if (_selectedCommunities.isEmpty) {
                              _selectedCommunities.add('common');
                            }
                          });
                        },
                      );
                    }),
                    ActionChip(
                      label: Text('+ Create new community'),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      onPressed: _loading ? null : _addNewCommunity,
                    ),
                  ],
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _loading ? null : _saveProfile,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                    child: Text('Save', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_loading)
          Container(
            color: Colors.black26,
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
      ],
    )
    );
  }

}
