import 'package:AMADRA/ViewProfile.dart';
import 'package:AMADRA/pc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  String? community;

  Future<void> comms()async{
    try{
      final user = FirebaseAuth.instance.currentUser;
      if(user==null) return;
      final doc = await FirebaseFirestore.instance
                                         .collection('users')
                                         .doc(user.uid)
                                         .get();
      
      setState(() {
        community = doc['community'];
      });
    }
    catch(e){
      print("Error: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    comms(); 
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text("AMADRA",style: Theme.of(context).textTheme.titleLarge,),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CreatePostPage()),
              );
            },
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: community == null
            ? const Center(child: CircularProgressIndicator())
            : StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('posts')
                    .where('community', isEqualTo: community)
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text("No posts yet",style: Theme.of(context).textTheme.labelLarge,));
          }

          final posts = snapshot.data!.docs;

          return ListView.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index].data() as Map<String, dynamic>;
              final userId = post['uid'];

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData) {
                    return const SizedBox.shrink();
                  }
                  final userData = userSnapshot.data!.data() as Map<String, dynamic>;
                  final username = userData['username'] ?? 'Unknown User';

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      title: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ViewProfile(userId: userId),
                                ),
                              );
                            },
                            child: Text(
                              username,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                          Text(
                            post['heading'] ?? 'No Heading',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                      subtitle: Text(post['content'] ?? ''),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

