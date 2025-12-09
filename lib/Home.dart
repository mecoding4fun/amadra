import 'package:AMADRA/NotificationsPage.dart';
import 'package:AMADRA/ViewProfile.dart';
import 'package:AMADRA/pc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:AMADRA/components/post_popup.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:AMADRA/components/PostCard.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> with AutomaticKeepAliveClientMixin {
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

    final Set<String> uniqueComms = {};
    for (var c in fetched) {
      if (c != null && c.toString().trim().isNotEmpty) {
        uniqueComms.add(c.toString().trim());
      }
    }

    uniqueComms.add('common');

    final List<String> finalCommunities = uniqueComms
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
    super.build(context);
    final activeCommunities = selectedCommunities.isEmpty
        ? userCommunities
        : selectedCommunities.toList();

    return Scaffold(
      
      appBar: AppBar(
        // backgroundColor: Color(0xFFBBDEFB), 
        automaticallyImplyLeading: false,
        title: Text("AMADRA", style: Theme.of(context).textTheme.titleLarge),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => NotificationsPage()),
              );
            },
            icon: const Icon(Icons.notifications),
          ),
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
      body: AnimatedOpacity(
        opacity: userCommunities.isEmpty ? 0 : 1, 
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOut,
        child: userCommunities.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Container(
            // decoration: const BoxDecoration(
            //     gradient: LinearGradient(
            //       colors: [
            //         Color(0xFFBBDEFB), 
            //         Color(0xFF90CAF9), 
            //         Color(0xFF64B5F6), 
            //       ],
            //       begin: Alignment.topLeft,
            //       end: Alignment.bottomRight,
            //     ),
            //   ),          
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                  child: Row(
                    children: userCommunities.map((community) {
                      final selected = selectedCommunities.contains(community);
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeInOut,
                          decoration: BoxDecoration(
                            color: selected ? Colors.deepPurple.withOpacity(0.15) : Colors.grey[200],
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: selected
                                ? [BoxShadow(color: Colors.deepPurple.withOpacity(0.25), blurRadius: 4, offset: Offset(0, 2))]
                                : [],
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(22),
                            onTap: () {
                              setState(() {
                                if (selected) {
                                  selectedCommunities.remove(community);
                                } else {
                                  selectedCommunities.add(community);
                                }
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              child: Text(
                                community,
                                style: TextStyle(
                                  color: selected ? Colors.deepPurple : Colors.grey[800],
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
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
                          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                          itemCount: posts.length,
                          itemBuilder: (context, index) {
                            final postData = posts[index].data() as Map<String, dynamic>;
                            final postId = posts[index].id;
                            final postOwnerId = postData['uid'];
                            final community = postData['community'] ?? 'Unknown';
                            final postTime = postData['timestamp'] as Timestamp?;
                            final formattedTime = postTime != null ? formatTimestamp(postTime) : '';

                            final userId = FirebaseAuth.instance.currentUser!.uid;

                            Widget postCardWidget;
                            if (_userCache.containsKey(postOwnerId)) {
                              final authorData = _userCache[postOwnerId]!;
                              postCardWidget = PostCard(
                                postId: postId,
                                post: postData,
                                authorData: authorData,
                                postOwnerId: postOwnerId,
                                currentUserId: userId,
                                community: community,
                                formattedTime: formattedTime,
                              );
                            } else {
                              postCardWidget = FutureBuilder<DocumentSnapshot>(
                                future: FirebaseFirestore.instance.collection('users').doc(postOwnerId).get(),
                                builder: (context, userSnapshot) {
                                  if (!userSnapshot.hasData) {
                                    return const SizedBox.shrink();
                                  }
                                  final authorData = userSnapshot.data!.data() as Map<String, dynamic>;
                                  _userCache[postOwnerId] = authorData;
                                  return PostCard(
                                    postId: postId,
                                    post: postData,
                                    authorData: authorData,
                                    postOwnerId: postOwnerId,
                                    currentUserId: userId,
                                    community: community,
                                    formattedTime: formattedTime,
                                  );
                                },
                              );
                            }

                            // Animate posts as they appear
                            return TweenAnimationBuilder(
                              tween: Tween<double>(begin: 0, end: 1),
                              duration: Duration(milliseconds: 450 + (index * 40)),
                              curve: Curves.easeOutCubic,
                              builder: (context, value, child) {
                                return Opacity(
                                  opacity: value,
                                  child: Transform.translate(
                                    offset: Offset(0, 30 * (1 - value)),
                                    child: child,
                                  ),
                                );
                              },
                              child: postCardWidget,
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
      )
    );
  }

  @override
  bool get wantKeepAlive => true;
}

  Widget _buildPostCard({
    required BuildContext context,
    required String postId,
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
                postId:postId, 
                post: post,
                userData: userData,
                userId: userId,
                formattedTime: formattedTime)
        );
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
                              : NetworkImage('https://www.shutterstock.com/image-vector/user-profile-icon-vector-avatar-600nw-2558760599.jpg'),
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
                      color: Colors.purple.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      community,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.deepPurple,
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
              if (post['imageUrl'] != null &&
                (post['imageUrl'] as String).trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.95, end: 1.0),
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                builder: (context, scale, child) {
                  return Transform.scale(
                    scale: scale,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl: post['imageUrl'],
                        fit: BoxFit.cover,
                        memCacheHeight: 800,
                        fadeInDuration: const Duration(milliseconds: 400),
                        fadeOutDuration: const Duration(milliseconds: 200),
                        progressIndicatorBuilder: (context, url, progress) {
                          return Container(
                            height: 220,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              gradient: LinearGradient(
                                colors: [
                                  Colors.grey.shade200,
                                  Colors.grey.shade300,
                                  Colors.grey.shade200
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Center(
                              child: CircularProgressIndicator(
                                value: progress.progress,
                                strokeWidth: 2,
                                color: Colors.deepPurpleAccent,
                              ),
                            ),
                          );
                        },
                        errorWidget: (context, url, error) => Container(
                          height: 220,
                          color: Colors.grey.shade200,
                          alignment: Alignment.center,
                          child: const Icon(Icons.broken_image,
                              color: Colors.grey, size: 40),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],

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