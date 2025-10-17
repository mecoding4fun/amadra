// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, unused_import

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() {
  runApp(MaterialApp(
    home: TodoScreen(),
  ));
}

class TodoScreen extends StatefulWidget {
  const TodoScreen({super.key});

  @override
  State<TodoScreen> createState() => TodoScreenState();
}

class TodoScreenState extends State<TodoScreen> {
  List<Map<String, dynamic>> todos = [];
  final TextEditingController todoc = TextEditingController();
  String priority = "Low";

  @override
  void initState() {
    super.initState();
    loadTodos();
  }

  Future<void> saveTodos() async {
    final prefs = await SharedPreferences.getInstance();
    String encoded = jsonEncode(todos);
    await prefs.setString("todos", encoded);
  }

  Future<void> loadTodos() async {
    final prefs = await SharedPreferences.getInstance();
    String? encoded = prefs.getString("todos");
    if (encoded != null) {
      setState(() {
        todos = List<Map<String, dynamic>>.from(jsonDecode(encoded));
      });
    }
  }

  void addTodo() {
    if (todoc.text.isNotEmpty) {
      setState(() {
        todos.add({
          "task": todoc.text,
          "done": false,
          "priority": priority,
        });
        todoc.clear();
        priority = "Low";
      });
      saveTodos(); // save after adding
    }
  }

  void toggleDone(int index) {
    setState(() {
      todos[index]["done"] = !todos[index]["done"];
    });
    saveTodos(); // save after update
  }

  void deleteTodo(int index) {
    setState(() {
      todos.removeAt(index);
    });
    saveTodos(); // save after delete
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Todo Page with Checkboxes")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: TextField(
                    controller: todoc,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: "Add a new task",
                    ),
                  ),
                ),
                SizedBox(height: 20),
                DropdownButton<String>(
                  value: priority,
                  items: ["High", "Medium", "Low"]
                      .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                      .toList(),
                  onChanged: (val) {
                    setState(() {
                      priority = val!;
                    });
                  },
                ),
                IconButton(
                  onPressed: addTodo,
                  icon: Icon(Icons.add),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: todos.length,
              itemBuilder: (context, index) {
                return CheckboxListTile(
                  title: Text(
                    "${todos[index]["task"]} (${todos[index]["priority"]})",
                    style: TextStyle(
                      decoration: todos[index]["done"]
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                    ),
                  ),
                  value: todos[index]["done"],
                  onChanged: (value) => toggleDone(index),
                  secondary: IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () => deleteTodo(index),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
