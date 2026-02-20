import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:AMADRA/ViewProfile.dart';
import 'package:AMADRA/components/post_popup.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final currentUser = FirebaseAuth.instance.currentUser;

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

  String getProfilePicUrl(String uid) {
    return 'https://xxxxxxxxxxx.supabase.co/storage/v1/object/public/profile_pics/$uid/profile.jpg';
  }

  Future<Map<String, dynamic>> getUserData(String uid) async {
    final doc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    return doc.data() ?? {};
  }

  Future<Map<String, dynamic>?> getPostData(String postId) async {
    final doc =
        await FirebaseFirestore.instance.collection('posts').doc(postId).get();
    return doc.data();
  }

  Future<void> refreshNotifications() async {
    // Just trigger a rebuild to refresh StreamBuilder
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return const Center(child: Text('Not logged in.'));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Colors.blue.shade100,
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: refreshNotifications,
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('notifications')
              .where('recipientId', isEqualTo: currentUser!.uid)
              .orderBy('timestamp', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final notifications = snapshot.data!.docs;

            if (notifications.isEmpty) {
              // Wrapping in SingleChildScrollView so RefreshIndicator can still work
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height - kToolbarHeight,
                  child: const Center(
                    child: Text(
                      "No notifications yet.",
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ),
                ),
              );
            }

            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notif = notifications[index];
                final senderId = notif['senderId'];
                final postId = notif['postId'];
                final type = notif['type'];
                final timestamp = notif['timestamp'] as Timestamp?;

                return FutureBuilder<Map<String, dynamic>>(
                  future: getUserData(senderId),
                  builder: (context, userSnapshot) {
                    if (!userSnapshot.hasData) {
                      return const SizedBox.shrink();
                    }

                    final sender = userSnapshot.data!;
                    final senderName =
                        sender['name'] ?? sender['username'] ?? 'Unknown';
                    final senderPic = getProfilePicUrl(senderId);
                    final time = formatTimestamp(timestamp);

                    String message = '';
                    if (type == 'like') {
                      message = '$senderName liked your post.';
                    } else if (type == 'comment') {
                      message = '$senderName commented on your post.';
                    }

                    return ListTile(
                      leading: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ViewProfile(userId: senderId),
                            ),
                          );
                        },
                        child: CircleAvatar(
                          radius: 22,
                          backgroundColor: Colors.grey[300],
                          child: ClipOval(
                            child: Image.network(
                              senderPic,
                              fit: BoxFit.cover,
                              width: 44,
                              height: 44,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(Icons.account_circle,
                                    size: 44, color: Colors.white);
                              },
                            ),
                          ),
                        ),
                      ),
                      title: Text(
                        message,
                        style: const TextStyle(fontSize: 14),
                      ),
                      subtitle: Text(
                        time,
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      onTap: () async {
                        final postData = await getPostData(postId);
                        if (postData == null) return;

                        final authorData =
                            await getUserData(postData['uid'] ?? '');

                        showDialog(
                          context: context,
                          builder: (context) => PostPopup(
                            postId: postId,
                            post: postData,
                            userData: authorData,
                            userId: postData['uid'],
                            formattedTime:
                                formatTimestamp(postData['timestamp']),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
