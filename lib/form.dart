import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FormA extends StatefulWidget {
  const FormA({super.key});

  @override
  FormAState createState() => FormAState();
}

class FormAState extends State<FormA> {
  final formKey = GlobalKey<FormState>();

  final TextEditingController FNcontroller = TextEditingController();
  final TextEditingController LNcontroller = TextEditingController();
  final TextEditingController EMcontroller = TextEditingController();
  final TextEditingController PAcontroller = TextEditingController();

  Future<void> addUser() async {
    await FirebaseFirestore.instance.collection("users").add({
      "firstName": FNcontroller.text,
      "lastName": LNcontroller.text,
      "email": EMcontroller.text,
      "password": PAcontroller.text,
      "timestamp": FieldValue.serverTimestamp(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("SimpleForm")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                controller: FNcontroller,
                decoration: const InputDecoration(labelText: "First Name"),
                validator: (value) =>
                    value == null || value.isEmpty ? "Enter first name" : null,
              ),
              TextFormField(
                controller: LNcontroller,
                decoration: const InputDecoration(labelText: "Last Name"),
              ),
              TextFormField(
                controller: EMcontroller,
                decoration: const InputDecoration(labelText: "Email"),
                validator: (value) =>
                    value == null || value.isEmpty ? "Enter email" : null,
              ),
              TextFormField(
                controller: PAcontroller,
                decoration: const InputDecoration(labelText: "Password"),
                obscureText: true,
                validator: (value) =>
                    value == null || value.isEmpty ? "Enter password" : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    await addUser();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("User added to Firebase!")),
                    );
                  }
                },
                child: const Text("Submit"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
