import 'package:AMADRA/components/Comments.dart';
import 'package:AMADRA/components/Likes.dart';
import 'package:flutter/material.dart';
import 'package:AMADRA/ViewProfile.dart';
import 'package:AMADRA/components/post_popup.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class PostCard extends StatefulWidget {
  final String postId;
  final Map<String, dynamic> post;       
  final Map<String, dynamic> authorData; 
  final String postOwnerId;              
  final String currentUserId;           
  final String community;
  final String formattedTime;

  const PostCard({
    super.key,
    required this.postId,
    required this.post,
    required this.authorData,
    required this.postOwnerId,
    required this.currentUserId,
    required this.community,
    required this.formattedTime,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> with SingleTickerProviderStateMixin{
  late Map<String, dynamic> postData;
  late AnimationController _controller;

  @override
void initState() {
  super.initState();
  postData = widget.post;

  _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 100),
    lowerBound: 0.0,
    upperBound: 1.0,
  );
}

@override
void dispose() {
  _controller.dispose();
  super.dispose();
}

  Future<int?> commentCount(String postId) async{
    final query = FirebaseFirestore.instance
      .collection('posts')
      .doc(postId)
      .collection('comments');

  final aggregateQuery = await query.count().get();
  return aggregateQuery.count;
  }

  bool get isLiked => postData['likedBy']?.contains(widget.currentUserId) == true;
  int get likeCount => postData['likedBy']?.length ?? 0;
  
  Future<void> toggleLike() async {
  final postRef = FirebaseFirestore.instance.collection('posts').doc(widget.postId);
  final likedBy = List<String>.from(postData['likedBy'] ?? []);
  final userId = widget.currentUserId;
  final postOwnerId = widget.postOwnerId; 

  bool wasLiked = likedBy.contains(userId);

  setState(() {
    if (wasLiked) {
      likedBy.remove(userId);
    } else {
      likedBy.add(userId);
    }
    postData['likedBy'] = likedBy;
  });

  await postRef.update({'likedBy': likedBy});

  if (!wasLiked) {
    await sendLikeNotification(postOwnerId, widget.postId);
  }
}
  Future<void> sendLikeNotification(String postOwnerId, String postId) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null || user.uid == postOwnerId) return; 

  await FirebaseFirestore.instance.collection('notifications').add({
    'recipientId': postOwnerId,
    'senderId': user.uid,
    'postId': postId,
    'type': 'like',
    'timestamp': FieldValue.serverTimestamp(),
  });
}

  void openCommentsBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => CommentsSheet(postId: widget.postId,postOwnerId: widget.postOwnerId,),
    );
  }

  void openLikesBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => LikesSheet(likedBy: List<String>.from(postData['likedBy'] ?? [])),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayName = widget.authorData['name'] ?? widget.authorData['username'] ?? 'Unknown';
    final username = widget.authorData['username'] != null ? "@${widget.authorData['username']}" : '';
    final heading = postData['heading'] ?? 'No Heading';
    final content = postData['content'] ?? '';

    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => PostPopup(
            postId: widget.postId,
            post: postData,
            userData: widget.authorData,
            userId: widget.postOwnerId, 
            formattedTime: widget.formattedTime,
          ),
        );
      },
      child: GestureDetector(
  onTapDown: (_) => _controller.forward(),
  onTapUp: (_) => _controller.reverse(),
  onTapCancel: () => _controller.reverse(),
  onTap: () {
    showDialog(
      context: context,
      builder: (context) => PostPopup(
        postId: widget.postId,
        post: postData,
        userData: widget.authorData,
        userId: widget.postOwnerId,
        formattedTime: widget.formattedTime,
      ),
    );
  },
  child: ScaleTransition(
    scale: Tween(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    ),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            spreadRadius: 2,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
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
                      builder: (context) => ViewProfile(userId: widget.postOwnerId),
                    ),
                  );
                },
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.grey[300],
                      backgroundImage: widget.authorData['profilePic'] != null
                          ? NetworkImage(widget.authorData['profilePic'])
                          : const NetworkImage(
                              'https://www.shutterstock.com/image-vector/user-profile-icon-vector-avatar-600nw-2558760599.jpg',
                            ),
                      onBackgroundImageError: (_, __) {
                      },
                      child: widget.authorData['profilePic'] == null
                          ? const Icon(Icons.person, color: Colors.white70)
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        Text(
                          username,
                          style: TextStyle(color: Colors.grey[600], fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.purple.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  widget.community,
                  style: const TextStyle(
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
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(fontSize: 14, color: Colors.grey[700], height: 1.4),
          ),

          if (postData['imageUrl'] != null &&
              (postData['imageUrl'] as String).trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: postData['imageUrl'],
                fit: BoxFit.cover,
                memCacheHeight: 800,
                fadeInDuration: const Duration(milliseconds: 300),
                fadeOutDuration: const Duration(milliseconds: 150),
                progressIndicatorBuilder: (context, url, progress) {
                  final value = progress.progress;
                  return Container(
                    height: 220,
                    color: Colors.grey[100],
                    child: Center(
                      child: CircularProgressIndicator(
                        value: value,
                        strokeWidth: 2.5,
                        color: Colors.blueAccent,
                      ),
                    ),
                  );
                },
                errorWidget: (context, url, error) => Container(
                  height: 220,
                  color: Colors.grey[200],
                  alignment: Alignment.center,
                  child: const Icon(Icons.broken_image, color: Colors.grey),
                ),
              ),
            ),
          ],

          const SizedBox(height: 10),
          Row(
            children: [
              GestureDetector(
                onLongPress: openLikesBottomSheet,
                child: IconButton(
                  icon: Icon(
                    isLiked ? Icons.favorite : Icons.favorite_border,
                    color: isLiked ? Colors.red : Colors.grey,
                  ),
                  onPressed: toggleLike,
                ),
              ),
              GestureDetector(
                onTap: openLikesBottomSheet,
                child: Text('$likeCount'),
              ),
              
              const SizedBox(width: 16),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.comment, color: Colors.grey),
                    onPressed: openCommentsBottomSheet,
                  ),
                  FutureBuilder<int?>(
                    future: commentCount(widget.postId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Text('…'); 
                      }
                      if (snapshot.hasError) {
                        return const Text('Err');
                      }
                      return Text('${snapshot.data ?? 0}');
                    },
                  )

                ],
              )
            ],
          ),

          Align(
            alignment: Alignment.bottomRight,
            child: Text(
              widget.formattedTime,
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
)
    );
  }
}
