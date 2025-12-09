import 'package:AMADRA/components/Comments.dart';
import 'package:AMADRA/components/Likes.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:AMADRA/ViewProfile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:transparent_image/transparent_image.dart';


class PostPopup extends StatelessWidget {
  final String postId;
  final Map<String, dynamic> post;
  final Map<String, dynamic> userData;
  final String userId;
  final String formattedTime;

  const PostPopup({
    super.key,
    required this.postId,
    required this.post,
    required this.userData,
    required this.userId,
    required this.formattedTime,
  });

  Future<void> _deletePost(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this post?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance.collection('posts').doc(postId).delete();
        Navigator.of(context, rootNavigator: true).pop(); 
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post deleted successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting post: $e')),
        );
      }
    }
  }

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
              borderRadius: BorderRadius.circular(20),
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: progress.expectedTotalBytes != null
                          ? progress.cumulativeBytesLoaded /
                              progress.expectedTotalBytes!
                          : null,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Center(
                      child: Icon(Icons.error, size: 50, color: Colors.red));
                },
              ),
            ),
          ),
        );
      },
    );
  }

  void openLikesSheet(BuildContext context) {
    final likedBy = List<String>.from(post['likedBy']??[]);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => LikesSheet(likedBy: likedBy),
    );
  }

  void openCommentsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => CommentsSheet(
        postId: postId,
        postOwnerId: userId,
      ),
    );
  }

Future<int?> commentCount(String postId) async{
    final query = FirebaseFirestore.instance
      .collection('posts')
      .doc(postId)
      .collection('comments');

  final aggregateQuery = await query.count().get();
  return aggregateQuery.count;
  }
  int get likeCount => post['likedBy']?.length ?? 0;

  @override
  Widget build(BuildContext context) {
    final heading = post['heading'] ?? 'No Heading';
    final content = post['content'] ?? '';
    final community = post['community'] ?? 'Unknown';
    final displayName = userData['name'] ?? userData['username'] ?? 'Unknown';
    final username =
        userData['username'] != null ? "@${userData['username']}" : '';
    final imageUrl = (post['imageUrl'] ?? '').toString().trim();
    final likedBy = List<String>.from(post['likedBy'] ?? []);

    return Dialog(
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
  elevation: 8,
  backgroundColor: Colors.white,
  child: ConstrainedBox(
    constraints: const BoxConstraints(maxHeight: 650, minWidth: 300),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    Expanded(
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ViewProfile(userId: userId)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: Colors.blue.shade100,
              backgroundImage: userData['profilePic'] != null
                  ? NetworkImage(userData['profilePic'])
                  : null,
              child: userData['profilePic'] == null
                  ? const Icon(Icons.person, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 17),
                    overflow: TextOverflow.ellipsis, 
                  ),
                  Text(
                    username,
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
    Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (userId == FirebaseAuth.instance.currentUser!.uid)
          IconButton(
            onPressed: () => _deletePost(context),
            icon: const Icon(Icons.delete_outline),
            color: Colors.redAccent,
          ),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    ),
  ],
),
            const SizedBox(height: 16),
            Text(heading,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            SelectableText(content,
                style:
                    TextStyle(fontSize: 15, color: Colors.grey[800], height: 1.4)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(20)),
              child: Text(
                community,
                style: const TextStyle(
                    fontSize: 14,
                    color: Colors.blueAccent,
                    fontWeight: FontWeight.w600),
              ),
            ),
            if (imageUrl.isNotEmpty) ...[
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => showImageDialog(context, imageUrl),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: InteractiveViewer(
                    minScale: 1.0,
                    maxScale: 4.0,
                    child: FadeInImage(
                      placeholder: MemoryImage(kTransparentImage),
                      image: NetworkImage(imageUrl),
                      fit: BoxFit.contain,
                      height: 350,
                      width: double.infinity,
                      imageErrorBuilder: (context, error, stackTrace) =>
                          Container(
                        height: 350,
                        color: Colors.grey.shade200,
                        alignment: Alignment.center,
                        child: const Icon(Icons.broken_image,
                            color: Colors.grey, size: 40),
                      ),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('posts')
                  .doc(postId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const SizedBox.shrink();
                }

                final postData = snapshot.data!.data() as Map<String, dynamic>;
                final likeCount = (postData['likedBy'] as List?)?.length ?? 0;
                final currentUserId = FirebaseAuth.instance.currentUser!.uid;
                final isLiked = likedBy.contains(currentUserId);

                return Row(
                  children: [
                    IconButton(
                      icon: Icon(
                    isLiked ? Icons.favorite : Icons.favorite_border,
                    color: isLiked ? Colors.red : Colors.grey,
                  ),
                      onPressed: () => openLikesSheet(context),
                    ),
                    Text('$likeCount', style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 20),
                    IconButton(
                      icon: const Icon(Icons.comment_outlined),
                      onPressed: () => openCommentsSheet(context),
                    ),
                    FutureBuilder<int?>(
                      future: commentCount(postId),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Text('…');
                        }
                        if (snapshot.hasError) {
                          return const Text('Err');
                        }
                        return Text('${snapshot.data ?? 0}');
                      },
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                formattedTime,
                style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                    fontStyle: FontStyle.italic),
              ),
            )
          ],
        ),
      ),
    ),
  ),
);

  }
}
