import 'package:AMADRA/ViewProfile.dart';
import 'package:AMADRA/pc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:AMADRA/components/post_popup.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  List<String> userCommunities = [];
  Set<String> selectedCommunities = {};
  final Map<String, Map<String, dynamic>> _userCache = {};

  String formatTimestamp(Timestamp timestamp) {
    final dateTime = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '${weeks}w ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  Future<void> fetchCommunities() async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    final List<dynamic> fetched = doc.data()?['communities'] ?? ['common'];

    // Deduplicate ignoring case and trimming whitespace
    final Set<String> uniqueComms = {};
    for (var c in fetched) {
      if (c != null && c.toString().trim().isNotEmpty) {
        uniqueComms.add(c.toString().trim().toLowerCase());
      }
    }

    // Ensure 'common' is included
    uniqueComms.add('common');

    // Map back to original capitalization if needed, else just capitalize first letter
    final List<String> finalCommunities = uniqueComms
        // .map((e) => e[0].toUpperCase() + e.substring(1))
        .toList();

    print("Fetched communities (raw): $fetched");
    print("Fetched communities (unique): $finalCommunities");

    setState(() {
      userCommunities = finalCommunities;
    });
  } catch (e) {
    print("Error fetching communities: $e");
  }
}


  @override
  void initState() {
    super.initState();
    fetchCommunities();
  }

  @override
  Widget build(BuildContext context) {
    final activeCommunities = selectedCommunities.isEmpty
        ? userCommunities
        : selectedCommunities.toList();

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text("AMADRA", style: Theme.of(context).textTheme.titleLarge),
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
      body: userCommunities.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: userCommunities.map((community) {
                      final selected = selectedCommunities.contains(community);
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(
                            community,
                            style: TextStyle(
                              color: selected
                                  ? Colors.deepPurple
                                  : Colors.grey[800],
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          selected: selected,
                          onSelected: (bool value) {
                            setState(() {
                              if (value)
                                selectedCommunities.add(community);
                              else
                                selectedCommunities.remove(community);
                            });
                          },
                          selectedColor: Colors.deepPurple.withOpacity(0.25),
                          backgroundColor: Colors.grey[200],
                          checkmarkColor: Colors.deepPurple,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('posts')
                        .where('community', whereIn: activeCommunities)
                        .orderBy('timestamp', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Center(
                          child: Text(
                            "No posts yet",
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                        );
                      }

                      final posts = snapshot.data!.docs;

                      return RefreshIndicator(
                        onRefresh: () async {
                          await fetchCommunities();
                          setState(() {});
                        },
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: posts.length,
                          itemBuilder: (context, index) {
                            final post = posts[index].data() as Map<String, dynamic>;
                            final userId = post['uid'];
                            final community = post['community'] ?? 'Unknown';
                            final postTime = post['timestamp'] as Timestamp?;
                            final formattedTime = postTime != null
                                ? formatTimestamp(postTime)
                                : '';

                            if (_userCache.containsKey(userId)) {
                              final userData = _userCache[userId]!;
                              return _buildPostCard(
                                context: context,
                                post: post,
                                userData: userData,
                                userId: userId,
                                community: community,
                                formattedTime: formattedTime,
                              );
                            } else {
                              return FutureBuilder<DocumentSnapshot>(
                                future: FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(userId)
                                    .get(),
                                builder: (context, userSnapshot) {
                                  if (!userSnapshot.hasData) {
                                    return const SizedBox.shrink();
                                  }
                                  final userData = userSnapshot.data!.data() as Map<String, dynamic>;
                                  _userCache[userId] = userData;
                                  return _buildPostCard(
                                    context: context,
                                    post: post,
                                    userData: userData,
                                    userId: userId,
                                    community: community,
                                    formattedTime: formattedTime,
                                  );
                                },
                              );
                            }
                          },
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

  Widget _buildPostCard({
    required BuildContext context,
    required Map<String, dynamic> post,
    required Map<String, dynamic> userData,
    required String userId,
    required String community,
    required String formattedTime,
  }) {
    final displayName = userData['name'] ?? userData['username'] ?? 'Unknown';
    final username =
        userData['username'] != null ? "@${userData['username']}" : '';
    final heading = post['heading'] ?? 'No Heading';
    final content = post['content'] ?? '';

    return GestureDetector(
      onTap: () {
        showDialog(
            context: context,
            builder: (context) => PostPopup(
                post: post,
                userData: userData,
                userId: userId,
                formattedTime: formattedTime));
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.grey[300],
                          backgroundImage: userData['profilePic'] != null
                              ? NetworkImage(userData['profilePic'])
                              : null,
                          child: userData['profilePic'] == null 
                              ? const Icon(Icons.person,
                                  color: Color.fromARGB(179, 255, 255, 255))
                              : null,
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              username,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      community,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.deepPurple.withOpacity(1),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                heading,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                content,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.bottomRight,
                child: Text(
                  formattedTime,
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
  }