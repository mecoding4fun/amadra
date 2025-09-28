import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserData {
  final String username;
  final String name;
  final String bio;
  final String profilePic;

  UserData({
    required this.username,
    required this.bio,
    required this.name,
    required this.profilePic,
  });
}
class PostsData {
  final String heading;
  final String content;
  final String username;
  final String timestamp;

  PostsData({
    required this.heading,
    required this.username,
    required this.content,
    required this.timestamp
  });
}


Future<UserData> fetchUserData(String userId) async {
  final doc =
      await FirebaseFirestore.instance.collection('users').doc(userId).get();
  final data = doc.data()!;
  return UserData(
    username: data['username'] ?? 'Unknown',
    name: data['name'] ?? '',
    bio: data['bio'] ?? '',
    profilePic: data['profilePic'] ?? '',
  );
}

Future<List<PostsData>> fetchUserPosts(String userId) async {
  final querySnapshot = await FirebaseFirestore.instance
      .collection("posts")
      .where('uid', isEqualTo: userId)
      .get();

  return querySnapshot.docs.map((doc) {
    final data = doc.data();
    return PostsData(
      heading: data['heading'],
      username: data['username'],
      content: data['content'],
      timestamp: data['timestamp'],
    );
  }).toList();
}
class ProfileData {
  final UserData user;
  final List<PostsData> posts;

  ProfileData({required this.user, required this.posts});
}
Future<ProfileData> fetchUserProfileAndPosts(String userId) async {
  final userDoc =
      await FirebaseFirestore.instance.collection('users').doc(userId).get();

  if (!userDoc.exists || userDoc.data() == null) {
    throw Exception("User not found");
  }

  final userData = userDoc.data()!;
  final user = UserData(
    username: userData['username'] ?? 'Unknown',
    name: userData['name'] ?? '',
    bio: userData['bio'] ?? '',
    profilePic: userData['profilePic'] ?? '',
  );

  final querySnapshot = await FirebaseFirestore.instance
      .collection("posts")
      .where('uid', isEqualTo: userId)
      .get();

  final posts = querySnapshot.docs.map((doc) {
    final data = doc.data();
    return PostsData(
      heading: data['heading'] ?? "",
      username: data['username'] ?? "",
      content: data['content'] ?? "",
      timestamp: data['timestamp']?.toString() ?? "",
    );
  }).toList();

  return ProfileData(user: user, posts: posts);
}


class ViewProfile extends StatelessWidget {
  final String userId;
  const ViewProfile({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Profile")),
      body: FutureBuilder<ProfileData>(
      future: fetchUserProfileAndPosts(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData) {
          return const Center(child: Text("User not found"));
        }

        final profile = snapshot.data!;
        final user = profile.user;
        final posts = profile.posts;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: posts.length + 1, 
          itemBuilder: (context, index) {
            if (index == 0) {
              return Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: NetworkImage(user.profilePic),
                  ),
                  const SizedBox(height: 12),
                  Text(user.name, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text("@${user.username}", style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 8),
                  Text(user.bio, textAlign: TextAlign.center),
                  const Divider(height: 32, thickness: 1),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text("Posts", style: Theme.of(context).textTheme.titleMedium),
                  ),
                  const SizedBox(height: 12),
                ],
              );
            }

            final post = posts[index - 1]; 
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                title: Text(post.heading, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(post.content),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            );
          },
        );
      },
    )

    );
  }

}
