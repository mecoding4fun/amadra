import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:AMADRA/main.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(
    MaterialApp(
      home: CreatePostPage(),
    ),
  );
}

class CreatePostPage extends StatefulWidget {
  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  bool isPosting = false;
  final formKey = GlobalKey<FormState>();

  final TextEditingController Headcontroller = TextEditingController();
  final TextEditingController Bodycontroller = TextEditingController();
  final TextEditingController CommunityController = TextEditingController();

  List<String> userCommunities = [];
  String? selectedCommunity;

  File? selectedImage;
  final ImagePicker picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    fetchUserCommunities();
  }

  Future<void> fetchUserCommunities() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final data = doc.data();
      if (data == null) return;

      final List<String> comms =
          List<String>.from(data['communities'] ?? ['common']);

      setState(() {
        userCommunities = comms;
        selectedCommunity = comms.first; 
      });
    } catch (e) {
      print("Error fetching communities: $e");
    }
  }

  Future<void> pickImage() async {
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        selectedImage = File(image.path);
      });
    }
  }

  Future<String?> uploadImageToSupabase(File image) async {
    try {
      final supabase = Supabase.instance.client;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${image.path.split('/').last}';
      final storageResponse = await supabase.storage.from('post-images').upload(fileName, image);
      if (storageResponse.error != null) {
        print('Supabase upload error: ${storageResponse.error!.message}');
        return null;
      }
      final publicUrl = supabase.storage.from('post-images').getPublicUrl(fileName);
      return publicUrl;
    } catch (e) {
      print('Error uploading image to Supabase: $e');
      print(Supabase.instance.client.accessToken);
      return null;
    }
  }

  Future<void> createPost() async {
    if (isPosting) return;
    if (!formKey.currentState!.validate()) return;
    if (selectedCommunity == null || selectedCommunity!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a community")),
      );
      return;
    }

    setState(() {
      isPosting = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final userDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .get();
      final username = userDoc.data()?['username'] ?? "Anonymous";

      String imageUrl = '';
      if (selectedImage != null) {
        final uploadedUrl = await uploadImageToSupabase(selectedImage!);
        if (uploadedUrl != null) {
          imageUrl = uploadedUrl;
        }
      }

      await FirebaseFirestore.instance.collection("posts").add({
        "username": username,
        "heading": Headcontroller.text.trim(),
        "content": Bodycontroller.text.trim(),
        "uid": user.uid.trim(),
        "timestamp": FieldValue.serverTimestamp(),
        "community": selectedCommunity,
        "imageUrl": imageUrl,
      });

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => BottomAppDem()),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Post created successfully")),
        );
      }
    } catch (e) {
      print("Error creating post: $e");
    } finally {
      if (mounted) {
        setState(() {
          isPosting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Post")),
      body: userCommunities.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: pickImage,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeInOut,
                        width: double.infinity,
                        height: selectedImage == null ? 250 : 300,
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.blue.shade200,
                            width: 2,
                          ),
                          boxShadow: [
                            if (selectedImage != null)
                              BoxShadow(
                                color: Colors.blue.shade100.withOpacity(0.5),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                          ],
                        ),
                        child: selectedImage == null
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_a_photo_outlined,
                                      size: 42, color: Colors.blue.shade400),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Tap to add an image',
                                    style: TextStyle(color: Colors.blue.shade600, fontSize: 15),
                                  ),
                                ],
                              )
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(
                                  selectedImage!,
                                  fit: BoxFit.contain,
                                  width: double.infinity,
                                  height: double.infinity,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: Headcontroller,
                      decoration: InputDecoration(
                        labelText: "Heading",
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
                      validator: (value) => value == null || value.isEmpty
                          ? "Enter heading"
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: Bodycontroller,
                      decoration: InputDecoration(
                        labelText: "Body",
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
                      validator: (value) =>
                          value == null || value.isEmpty ? "Enter body" : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: selectedCommunity,
                      decoration: InputDecoration(
                        labelText: "Select Community",
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
                      items: userCommunities
                          .map((c) => DropdownMenuItem(
                                value: c,
                                child: Text(c),
                              ))
                          .toList(),
                      onChanged: (val) {
                        setState(() {
                          selectedCommunity = val;
                        });
                      },
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: ElevatedButton(
                        onPressed: isPosting ? null : createPost,
                        child: isPosting
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : const Text("Post"),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

extension on String {
  get error => null;
}
