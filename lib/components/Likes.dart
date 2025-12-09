import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class LikesSheet extends StatelessWidget {
  final List<String> likedBy;
  const LikesSheet({super.key, required this.likedBy});

  String getProfilePicUrl(String uid) => 'https://vgwllhhomzbgolazgaba.supabase.co/storage/v1/object/public/profile_pics/$uid/profile.jpg';

  Future<Map<String, dynamic>> getUserData(String uid) async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    return doc.data() ?? {};
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.6,
      child: Column(children: [
        const SizedBox(height: 8),
        Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(10))),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            itemCount: likedBy.length,
            itemBuilder: (context, index) {
              final uid = likedBy[index];
              return FutureBuilder<Map<String, dynamic>>(
                future: getUserData(uid),
                builder: (context, snap) {
                  final user = snap.data ?? {};
                  final displayName = user['name'] ?? user['username'] ?? 'Unknown';
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
                    title: Text(displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  );
                },
              );
            },
          ),
        ),
      ]),
    );
  }
}