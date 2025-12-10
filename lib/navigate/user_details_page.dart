import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import 'chat_screen.dart';

class UserDetailsPage extends StatefulWidget {
  final UserModel user;

  const UserDetailsPage({super.key, required this.user});

  @override
  State<UserDetailsPage> createState() => _UserDetailsPageState();
}

class _UserDetailsPageState extends State<UserDetailsPage> {
  bool _isFollowing = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkFollowStatus();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkFollowStatus();
  }

  Future<void> _checkFollowStatus() async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final followQuery = await FirebaseFirestore.instance
          .collection('follows')
          .where('followerId', isEqualTo: currentUserId)
          .where('followingId', isEqualTo: widget.user.id)
          .get();

      if (mounted) {
        setState(() {
          _isFollowing = followQuery.docs.isNotEmpty;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _toggleFollow() async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    try {
      if (_isFollowing) {
        final followQuery = await FirebaseFirestore.instance
            .collection('follows')
            .where('followerId', isEqualTo: currentUserId)
            .where('followingId', isEqualTo: widget.user.id)
            .get();

        for (var doc in followQuery.docs) {
          await doc.reference.delete();
        }

        if (mounted) {
          setState(() => _isFollowing = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Unfollowed'), backgroundColor: Colors.orange),
          );
        }
      } else {
        await FirebaseFirestore.instance.collection('follows').add({
          'followerId': currentUserId,
          'followingId': widget.user.id,
          'createdAt': DateTime.now(),
        });

        if (mounted) {
          setState(() => _isFollowing = true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Following!'), backgroundColor: Colors.green),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.user.name),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.deepPurple.withOpacity(0.8), Colors.purple.withOpacity(0.6)],
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child: ClipOval(
                      child: widget.user.profilePicUrl != null
                          ? Image.network(
                              widget.user.profilePicUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: Colors.white,
                                child: Icon(Icons.person, size: 50, color: Colors.deepPurple),
                              ),
                            )
                          : Container(
                              color: Colors.white,
                              child: Icon(Icons.person, size: 50, color: Colors.deepPurple),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.user.name,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  Text(
                    widget.user.email,
                    style: const TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _toggleFollow,
                          icon: Icon(_isFollowing ? Icons.check : Icons.person_add),
                          label: Text(_isFollowing ? 'Following' : 'Follow'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isFollowing ? Colors.green : Colors.deepPurple,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            final currentUserId = FirebaseAuth.instance.currentUser?.uid;
                            if (currentUserId == widget.user.id) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('You cannot message yourself'), backgroundColor: Colors.orange),
                              );
                              return;
                            }
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChatScreen(
                                  otherUserId: widget.user.id,
                                  otherUserName: widget.user.name,
                                  chatType: 'personal',
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.message),
                          label: const Text('Message'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (widget.user.bio != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.withOpacity(0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('About', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text(widget.user.bio!, style: const TextStyle(fontSize: 14)),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Contact Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.email, size: 16, color: Colors.grey),
                            const SizedBox(width: 8),
                            Expanded(child: Text(widget.user.email, style: const TextStyle(fontSize: 14))),
                          ],
                        ),
                        if (widget.user.phoneNumber != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.phone, size: 16, color: Colors.grey),
                              const SizedBox(width: 8),
                              Expanded(child: Text(widget.user.phoneNumber!, style: const TextStyle(fontSize: 14))),
                            ],
                          ),
                        ],
                        if (widget.user.location != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.location_on, size: 16, color: Colors.grey),
                              const SizedBox(width: 8),
                              Expanded(child: Text(widget.user.location!, style: const TextStyle(fontSize: 14))),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  FutureBuilder<QuerySnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('company_members')
                        .where('userId', isEqualTo: widget.user.id)
                        .get(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const SizedBox();
                      }

                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.withOpacity(0.2)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Collaborations (${snapshot.data!.docs.length})',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            ...snapshot.data!.docs.map((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              return FutureBuilder<DocumentSnapshot>(
                                future: FirebaseFirestore.instance
                                    .collection('companies')
                                    .doc(data['companyId'])
                                    .get(),
                                builder: (context, companySnapshot) {
                                  if (!companySnapshot.hasData) return const SizedBox();
                                  final companyData = companySnapshot.data!.data() as Map<String, dynamic>?;
                                  if (companyData == null) return const SizedBox();

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.business, color: Colors.deepPurple),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(companyData['name'],
                                                  style: const TextStyle(fontWeight: FontWeight.bold)),
                                              Text('Position: ${data['position'] ?? 'Member'}',
                                                  style: TextStyle(color: Colors.grey[600])),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            }),
                          ],
                        ),
                      );
                    },
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
