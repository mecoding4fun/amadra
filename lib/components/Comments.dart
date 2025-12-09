import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CommentsSheet extends StatefulWidget {
  final String postId;
  final String postOwnerId;
  const CommentsSheet({super.key, required this.postId,required this.postOwnerId});

  @override
  State<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<CommentsSheet> {
  final TextEditingController _controller = TextEditingController();

  Future<void> postComment() async {
  final text = _controller.text.trim();
  if (text.isEmpty) return;

  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  final commentsRef = FirebaseFirestore.instance
      .collection('posts')
      .doc(widget.postId)
      .collection('comments');

  await commentsRef.add({
    'userId': user.uid,
    'text': text,
    'timestamp': FieldValue.serverTimestamp(),
  });

  if (widget.postOwnerId != user.uid) {
    await FirebaseFirestore.instance.collection('notifications').add({
      'recipientId': widget.postOwnerId,
      'senderId': user.uid,
      'postId': widget.postId,
      'type': 'comment',
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  _controller.clear();
}


  String formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final date = timestamp.toDate();
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<Map<String, dynamic>> getUserData(String uid) async {
    final doc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    return doc.data() ?? {};
  }

  String getProfilePicUrl(String uid) {
    return 'https://vgwllhhomzbgolazgaba.supabase.co/storage/v1/object/public/profile_pics/$uid/profile.jpg';
  }

  @override
  Widget build(BuildContext context) {
    final commentsRef = FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId)
        .collection('comments')
        .orderBy('timestamp', descending: true);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: commentsRef.snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final comments = snapshot.data!.docs;

                  return ListView.builder(
                    reverse: true,
                    itemCount: comments.length,
                    itemBuilder: (context, index) {
                      final comment = comments[index];
                      final uid = comment['userId'] ?? 'Unknown';
                      final text = comment['text'] ?? '';
                      final timestamp = comment['timestamp'] as Timestamp?;

                      return FutureBuilder<Map<String, dynamic>>(
                        future: getUserData(uid),
                        builder: (context, userSnapshot) {
                          final user = userSnapshot.data ?? {};
                          final displayName =
                              user['name'] ?? user['username'] ?? 'Unknown';
                          final profileUrl = getProfilePicUrl(uid);

                          return ListTile(
                            leading: CircleAvatar(
                              radius: 22,
                              backgroundColor: Colors.grey[300],
                              child: ClipOval(
                                child: Image.network(
                                  profileUrl,
                                  fit: BoxFit.cover,
                                  width: 44,
                                  height: 44,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Image.network(
                                      'https://www.shutterstock.com/image-vector/user-profile-icon-vector-avatar-600nw-2558760599.jpg',
                                      fit: BoxFit.cover,
                                      width: 44,
                                      height: 44,
                                      errorBuilder: (context, error, stackTrace) {
                                        return const Icon(Icons.account_circle, size: 44, color: Colors.white);
                                      },
                                    );
                                  },
                                ),
                              ),
                            ),
                            title: Row(
                              children: [
                                Text(
                                  displayName,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  formatTimestamp(timestamp),
                                  style: TextStyle(
                                      color: Colors.grey[500], fontSize: 12),
                                ),
                              ],
                            ),
                            subtitle: Text(text),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: 'Write a comment...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: postComment,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
