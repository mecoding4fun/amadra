import 'package:flutter/material.dart';

void main() {
  runApp(MaterialApp(
    home: Changer(),
  ));
}

class Changer extends StatefulWidget {
  const Changer({super.key});

  @override
  _Changer createState() => _Changer();
}

class _Changer extends State<Changer> {
  int count = 0;

  void inc() {
    setState(() {
      count++;
    });
  }

  void dec() {
    setState(() {
      count--;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Counter"),
      ),
      body: Center(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("Count: $count", style: TextStyle(fontSize: 24)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                onPressed: () {
                  inc();
                },
                icon: Icon(Icons.add),
                color: Colors.white,
                style: IconButton.styleFrom(
                  backgroundColor: Color.fromRGBO(197, 148, 124, 1),
                ),
              ),
              IconButton(
                onPressed: () {
                  dec();
                },
                icon: Icon(Icons.remove),
                color: Colors.white,
                style: IconButton.styleFrom(
                  backgroundColor: Color.fromRGBO(197, 148, 124, 1),
                ),
              )
            ],
          )
        ],
      )),
    );
  }
}
