import 'package:AMADRA/components/post_popup.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:AMADRA/components/PostCard.dart';


class UserData {
  final String username;
  final String name;
  final String bio;
  final String profilePic;
  final List<String> communities;

  UserData({
    required this.username,
    required this.bio,
    required this.name,
    required this.profilePic,
    required this.communities,
  });
}

class PostsData {
  final String id;
  final String heading;
  final String content;
  final String username;
  final Timestamp timestamp;
  final String community;
  final String? imageUrl;

  PostsData({
    required this.id,
    required this.heading,
    required this.username,
    required this.content,
    required this.timestamp,
    required this.community,
    this.imageUrl,
  });
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
  final commList = List<String>.from(userData['communities'] ?? ['common']);

  final user = UserData(
    username: userData['username'] ?? 'Unknown',
    name: userData['name'] ?? '',
    bio: userData['bio'] ?? '',
    profilePic: userData['profilePic'] ?? '',
    communities: commList,
  );

  final querySnapshot = await FirebaseFirestore.instance
      .collection("posts")
      .where('uid', isEqualTo: userId)
      .orderBy('timestamp', descending: true)
      .get();

  final posts = querySnapshot.docs.map((doc) {
    final data = doc.data();
    return PostsData(
      id: doc.id,
      heading: data['heading'] ?? "",
      username: data['username'] ?? "",
      content: data['content'] ?? "",
      timestamp: data['timestamp'] ?? Timestamp.now(),
      community: data['community'] ?? 'common',
      imageUrl: data['imageUrl'] ?? '',
    );
  }).toList();

  return ProfileData(user: user, posts: posts);
}

String formatTimestamp(Timestamp timestamp) {
  final now = DateTime.now();
  final date = timestamp.toDate();
  final diff = now.difference(date);

  if (diff.inSeconds < 60) {
    return '${diff.inSeconds}s ago';
  } else if (diff.inMinutes < 60) {
    return '${diff.inMinutes}m ago';
  } else if (diff.inHours < 24) {
    return '${diff.inHours}h ago';
  } else if (diff.inDays < 7) {
    return '${diff.inDays}d ago';
  } else if (diff.inDays < 30) {
    return '${(diff.inDays / 7).floor()}w ago';
  } else if (diff.inDays < 365) {
    return '${(diff.inDays / 30).floor()}mo ago';
  } else {
    return '${(diff.inDays / 365).floor()}y ago';
  }
}

class ViewProfile extends StatelessWidget {
  final String userId;
  const ViewProfile({super.key, required this.userId});

 void showImageDialog(BuildContext context, String imageUrl) {
  showDialog(
    context: context,
    builder: (context) {
      return Dialog(
        backgroundColor: Colors.transparent, 
        insetPadding: EdgeInsets.all(10), 
        child: GestureDetector(
          onTap: () => Navigator.of(context).pop(), 
          child: ClipRRect(
            borderRadius: BorderRadius.circular(1000),
            child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Center(child: Icon(Icons.error, size: 50, color: Colors.red));
                },
              ), 
            ),
          ),
      );
    },
  );
}

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
                    GestureDetector(
                      onTap: (){
                        showImageDialog(context, user.profilePic);
                      },
                      child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.white,
                      backgroundImage: user.profilePic.isNotEmpty
                          ? NetworkImage(user.profilePic)
                          : NetworkImage("https://www.shutterstock.com/image-vector/avatar-gender-neutral-silhouette-vector-600nw-2470054311.jpg"),
                      child: user.profilePic.isEmpty
                          ? Icon(Icons.account_circle,
                              size: 100, color: Colors.grey[600])
                          : null,
                    ),
                    ),
                    const SizedBox(height: 12),
                    Text(user.name,
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text("@${user.username}",
                        style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: user.communities.map((c) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                c,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(user.bio, textAlign: TextAlign.center),
                    const Divider(height: 32, thickness: 1),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text("Posts",
                          style: Theme.of(context).textTheme.titleMedium),
                    ),
                    const SizedBox(height: 12),
                  ],
                );
              }

              final postData = posts[index - 1];

              final postMap = {
                'id': postData.id,
                'heading': postData.heading,
                'username': postData.username,
                'content': postData.content,
                'timestamp': postData.timestamp,
                'community': postData.community,
                'imageUrl': postData.imageUrl ?? '',
              };
              final userMap = {
                'username': user.username,
                'name': user.name,
                'bio': user.bio,
                'profilePic': user.profilePic,
                'communities': user.communities,
              };
              final imageUrl = postData.imageUrl ?? '';
              return GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => PostPopup(
                      postId: postData.id, 
                      post: postMap,
                      userData: userMap,
                      userId: userId,
                      formattedTime: formatTimestamp(postData.timestamp),
                    ),
                  );
                },
                child: Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          postData.heading,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(postData.content),
                        if (imageUrl.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              imageUrl,
                              width: double.infinity,
                              fit: BoxFit.contain,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  height: 200,
                                  color: Colors.grey[200],
                                  child: const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) => Container(
                                height: 200,
                                color: Colors.grey[300],
                                alignment: Alignment.center,
                                child: const Icon(Icons.broken_image, color: Colors.grey),
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: Text(
                            formatTimestamp(postData.timestamp),
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
       
              );
            },
            
          );
        },
      ),
    );
  }
}
