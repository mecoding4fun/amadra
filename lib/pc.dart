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

  @override
  void initState() {
    super.initState();
    fetchUserCommunities();
  }

  /// Fetch user's communities from Firestore
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
        selectedCommunity = comms.first; // Default to first community
      });
    } catch (e) {
      print("Error fetching communities: $e");
    }
  }

  /// Create a post and upload to Firestore
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

      await FirebaseFirestore.instance.collection("posts").add({
        "username": username,
        "heading": Headcontroller.text.trim(),
        "content": Bodycontroller.text.trim(),
        "uid": user.uid.trim(),
        "timestamp": FieldValue.serverTimestamp(),
        "community": selectedCommunity,
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
                    TextFormField(
                      controller: Headcontroller,
                      decoration: const InputDecoration(labelText: "Heading"),
                      validator: (value) => value == null || value.isEmpty
                          ? "Enter heading"
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: Bodycontroller,
                      decoration: const InputDecoration(labelText: "Body"),
                      validator: (value) =>
                          value == null || value.isEmpty ? "Enter body" : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedCommunity,
                      decoration: const InputDecoration(
                        labelText: "Select Community",
                        border: OutlineInputBorder(),
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
                            : const Text("Create"),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
