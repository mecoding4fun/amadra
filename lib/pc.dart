import 'package:AMADRA/main.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

void main(){
  runApp(
    MaterialApp(
      home: CreatePostPage(),
    )
  );
}
class CreatePostPage extends StatefulWidget {
  @override
  State<CreatePostPage> createState()=> Cpstate();
}
class Cpstate extends State<CreatePostPage>{
  final formKey = GlobalKey<FormState>();

  final TextEditingController Headcontroller = TextEditingController();
  final TextEditingController Bodycontroller = TextEditingController();

Future<void> createpost()async{
  try{
    final user = FirebaseAuth.instance.currentUser;
    if(user==null) return;

    final userDoc = await FirebaseFirestore.instance.collection("users").doc(user.uid).get();

    final username = userDoc.data()?['username'] ?? "Anonymous";

    await FirebaseFirestore.instance.collection("posts").doc().set({
    "username":username,
    "heading":Headcontroller.text.trim(),
    "content":Bodycontroller.text.trim(),
    "uid": FirebaseAuth.instance.currentUser!.uid.trim(),
    "timestamp":FieldValue.serverTimestamp()
  });
  }
  catch(e){
    print(e);
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Post")),
      body: SingleChildScrollView(   
        child: Padding(
          padding: const EdgeInsets.all(16.0), 
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: Headcontroller,
                  decoration: const InputDecoration(labelText: "Heading"),
                  validator: (value) =>
                      value == null || value.isEmpty ? "Enter heading" : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: Bodycontroller,
                  decoration: const InputDecoration(labelText: "Body"),
                  validator: (value) =>
                      value == null || value.isEmpty ? "Enter body" : null,
                ),
                const SizedBox(height: 20),
                Center(
                  child: ElevatedButton(
                    onPressed: () async {
                      if (formKey.currentState!.validate()) {
                        await createpost();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Post created successfully")),
                        );
                        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>BottomAppDem()));
                      }
                    },
                    child: const Text("Post"),
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