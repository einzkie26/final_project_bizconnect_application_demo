import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../controllers/messages_controller.dart';
import '../models/user_model.dart';
import '../widgets/loading_screen.dart';
import 'chat_screen.dart';

class MessagesPage extends ConsumerStatefulWidget {
  const MessagesPage({super.key});
  
  @override
  ConsumerState<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends ConsumerState<MessagesPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Please log in')));
    }
    
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return _buildProfileIncompleteScreen();
        }
        
        final userData = snapshot.data!.data() as Map<String, dynamic>;
        final hasPhone = userData['phoneNumber']?.toString().isNotEmpty == true;
        final hasBio = userData['bio']?.toString().isNotEmpty == true;
        final hasProfilePic = userData['profilePicUrl']?.toString().isNotEmpty == true;
        
        if (!hasPhone || !hasBio || !hasProfilePic) {
          return _buildProfileIncompleteScreen();
        }
        
        return _buildMessagesScreen();
      },
    );
  }
  
  Widget _buildProfileIncompleteScreen() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_outline,
                size: 80,
                color: Colors.orange,
              ),
              const SizedBox(height: 24),
              const Text(
                'Complete Your Profile',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'You need to complete your profile with phone number, bio, and profile picture before you can chat with others.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  // Switch to profile tab (index 3)
                  Navigator.of(context).popUntil((route) => route.isFirst);
                  // This will close the messages page and show profile tab
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                child: const Text(
                  'Complete Profile',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildMessagesScreen() {
    final messagesController = ref.read(messagesControllerProvider);
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    'Messages',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TabBar(
                    controller: _tabController,
                    labelColor: Colors.deepPurple,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: Colors.deepPurple,
                    tabs: const [
                      Tab(text: 'Personal'),
                      Tab(text: 'Company'),
                    ],
                  ),
                ],
              ),
            ),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('messages')
                  .where('receiverId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                  .where('isRead', isEqualTo: false)
                  .snapshots(),
              builder: (context, invitationSnapshot) {
                if (invitationSnapshot.hasData) {
                  final invitations = invitationSnapshot.data!.docs
                      .where((doc) => (doc.data() as Map<String, dynamic>)['message']
                          .toString().startsWith('Company invitation:'))
                      .toList();
                  
                  if (invitations.isNotEmpty) {
                    return Container(
                      margin: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Company Invitations',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          ...invitations.map((doc) => 
                            _buildInvitationMessage(context, ref, doc)
                          ),
                        ],
                      ),
                    );
                  }
                }
                return const SizedBox.shrink();
              },
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  setState(() {});
                },
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildPersonalMessages(messagesController),
                    _buildCompanyMessages(messagesController),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showUserSearch(context),
        backgroundColor: Colors.deepPurple,
        child: const Icon(
          Icons.person_search,
          color: Colors.white,
        ),
      ),
    );
  }
  
  Widget _buildPersonalMessages(messagesController) {
    return StreamBuilder<List<ChatPreview>>(
      stream: messagesController.getPersonalChats(),
      builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const LoadingScreen();
                  }
                  
                  if (snapshot.hasError) {
                    return const Center(
                      child: Text(
                        'Error loading chats',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    );
                  }
                  
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  final chats = snapshot.data!;
                  
                  if (chats.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 80,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No conversations yet',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Start connecting with people and companies',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () => _showUserSearch(context),
                            icon: const Icon(Icons.person_search, color: Colors.white),
                            label: const Text(
                              'Find People',
                              style: TextStyle(color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: chats.length,
                    itemBuilder: (context, index) {
                      final chat = chats[index];
                      
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatScreen(
                                otherUserId: chat.otherUserId,
                                otherUserName: chat.otherUserName,
                                chatType: 'personal',
                              ),
                            ),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: chat.hasUnread ? Colors.purple.withOpacity(0.05) : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: chat.hasUnread ? Colors.deepPurple.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                spreadRadius: 1,
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              FutureBuilder<DocumentSnapshot>(
                                future: FirebaseFirestore.instance.collection('users').doc(chat.otherUserId).get(),
                                builder: (context, snapshot) {
                                  String? profilePicUrl;
                                  if (snapshot.hasData && snapshot.data!.data() != null) {
                                    final data = snapshot.data!.data() as Map<String, dynamic>;
                                    profilePicUrl = data['profilePicUrl'];
                                  }
                                  return Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.deepPurple.withOpacity(0.8),
                                          Colors.purple.withOpacity(0.6),
                                        ],
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: profilePicUrl != null
                                        ? ClipOval(
                                            child: Image.network(
                                              profilePicUrl,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) => Center(
                                                child: Text(
                                                  chat.otherUserName.substring(0, 1),
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 18,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          )
                                        : Center(
                                            child: Text(
                                              chat.otherUserName.substring(0, 1),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18,
                                              ),
                                            ),
                                          ),
                                  );
                                },
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                chat.otherUserName,
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: chat.hasUnread ? FontWeight.bold : FontWeight.w600,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                              if (chat.otherUserRealName != null)
                                                Text(
                                                  chat.otherUserRealName!,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey[600],
                                                    fontWeight: FontWeight.normal,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                        Text(
                                          _formatTime(chat.lastMessageTime),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: chat.hasUnread ? Colors.deepPurple : Colors.grey,
                                            fontWeight: chat.hasUnread ? FontWeight.w600 : FontWeight.normal,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            chat.lastMessage.isEmpty ? 'No messages yet' : chat.lastMessage,
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: chat.hasUnread ? Colors.black87 : Colors.grey[600],
                                              fontWeight: chat.hasUnread ? FontWeight.w500 : FontWeight.normal,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (chat.hasUnread)
                                          Container(
                                            margin: const EdgeInsets.only(left: 8),
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.deepPurple,
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Text(
                                              '${chat.unreadCount}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
        },
      );
  }
  
  Widget _buildCompanyMessages(messagesController) {
    return StreamBuilder<List<ChatPreview>>(
      stream: messagesController.getCompanyChats(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingScreen();
        }
        
        if (snapshot.hasError) {
          return const Center(
            child: Text(
              'Error loading company chats',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          );
        }
        
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final companyChats = snapshot.data!;
        
        if (companyChats.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.business_center,
                  size: 80,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 16),
                const Text(
                  'No company conversations',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Connect with companies to start conversations',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: companyChats.length,
          itemBuilder: (context, index) {
            final chat = companyChats[index];
            
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(
                      otherUserId: chat.otherUserId,
                      otherUserName: chat.otherUserName,
                      chatType: 'company',
                      companyId: chat.companyId,
                    ),
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: chat.hasUnread ? Colors.blue.withOpacity(0.05) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: chat.hasUnread ? Colors.blue.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance.collection('companies').doc(chat.otherUserId).get(),
                      builder: (context, snapshot) {
                        String? photoUrl;
                        if (snapshot.hasData && snapshot.data!.data() != null) {
                          final data = snapshot.data!.data() as Map<String, dynamic>;
                          photoUrl = data['photoUrl'];
                        }
                        return Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: photoUrl != null
                              ? ClipOval(
                                  child: Image.network(
                                    photoUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(Icons.business, color: Colors.blue, size: 24),
                                  ),
                                )
                              : const Icon(Icons.business, color: Colors.blue, size: 24),
                        );
                      },
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      chat.otherUserName,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: chat.hasUnread ? FontWeight.bold : FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    if (chat.otherUserRealName != null)
                                      Text(
                                        'by ${chat.otherUserRealName}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                          fontWeight: FontWeight.normal,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Text(
                                _formatTime(chat.lastMessageTime),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: chat.hasUnread ? Colors.blue : Colors.grey,
                                  fontWeight: chat.hasUnread ? FontWeight.w600 : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  chat.lastMessage.isEmpty ? 'No messages yet' : chat.lastMessage,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: chat.hasUnread ? Colors.black87 : Colors.grey[600],
                                    fontWeight: chat.hasUnread ? FontWeight.w500 : FontWeight.normal,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (chat.hasUnread)
                                Container(
                                  margin: const EdgeInsets.only(left: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.blue,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${chat.unreadCount}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '1w ago';
    }
  }
  
  void _showUserSearch(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    if (!doc.exists) return;
    
    final userData = doc.data()!;
    final hasPhone = userData['phoneNumber']?.toString().isNotEmpty == true;
    final hasBio = userData['bio']?.toString().isNotEmpty == true;
    final hasProfilePic = userData['profilePicUrl']?.toString().isNotEmpty == true;
    
    if (!hasPhone || !hasBio || !hasProfilePic) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Complete your profile first to chat with others'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const UserSearchBottomSheet(),
    );
  }

  Widget _buildInvitationMessage(BuildContext context, WidgetRef ref, DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final message = data['message'] as String;
    final companyId = message.replaceFirst('Company invitation: ', '');
    
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('companies').doc(companyId).get(),
      builder: (context, companySnapshot) {
        if (!companySnapshot.hasData) return const SizedBox();
        
        final companyData = companySnapshot.data!.data() as Map<String, dynamic>;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.business, color: Colors.blue, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'You are invited to join',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    Text(
                      companyData['name'],
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () => _showJoinCompanyDialog(context, companyId, companyData['name'], doc.id),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                child: const Text('Join', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      },
    );
  }
  


  void _showJoinCompanyDialog(BuildContext context, String companyId, String companyName, String messageId) {
    final positionController = TextEditingController();
    final idController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Join $companyName'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: positionController,
              decoration: const InputDecoration(
                labelText: 'Position',
                hintText: 'e.g., Developer, Manager',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: idController,
              decoration: const InputDecoration(
                labelText: 'ID Number',
                hintText: 'Your employee ID',
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Your request will be sent to the company for approval.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (positionController.text.isNotEmpty && idController.text.isNotEmpty) {
                await _submitJoinRequest(context, companyId, companyName, positionController.text, idController.text, messageId);
                Navigator.pop(context);
              }
            },
            child: const Text('Submit Request'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _submitJoinRequest(BuildContext context, String companyId, String companyName, String position, String idNumber, String messageId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    try {
      // Add user to company members
      await FirebaseFirestore.instance
          .collection('company_members')
          .doc('${companyId}_${user.uid}')
          .set({
        'companyId': companyId,
        'userId': user.uid,
        'position': position,
        'buildingNo': '',
        'idNumber': idNumber,
        'joinedAt': DateTime.now(),
      });
      
      // Add user to company memberIds
      await FirebaseFirestore.instance
          .collection('companies')
          .doc(companyId)
          .update({
        'memberIds': FieldValue.arrayUnion([user.uid])
      });
      
      // Mark message as read
      await FirebaseFirestore.instance.collection('messages').doc(messageId).update({
        'isRead': true,
      });
      
      // Send notification to company owner
      final companyDoc = await FirebaseFirestore.instance.collection('companies').doc(companyId).get();
      final ownerId = companyDoc.data()!['ownerId'];
      
      await FirebaseFirestore.instance.collection('messages').add({
        'senderId': user.uid,
        'receiverId': ownerId,
        'message': 'User has joined your company $companyName as $position.',
        'type': 'join_accepted',
        'timestamp': DateTime.now(),
        'isRead': false,
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Successfully joined the company!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to join company'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  

}

class UserSearchBottomSheet extends StatefulWidget {
  const UserSearchBottomSheet({super.key});

  @override
  State<UserSearchBottomSheet> createState() => _UserSearchBottomSheetState();
}

class _UserSearchBottomSheetState extends State<UserSearchBottomSheet> {
  final _searchController = TextEditingController();
  List<UserModel> _users = [];
  bool _isLoading = false;

  Future<bool> _checkInternetConnection() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return !connectivityResult.contains(ConnectivityResult.none);
  }

  void _showConnectionError() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('No internet connection. Please check your network and try again.'),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Find People',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by name or email...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onChanged: _searchUsers,
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _users.length,
                    itemBuilder: (context, index) {
                      final user = _users[index];
                      return ListTile(
                        leading: FutureBuilder<DocumentSnapshot>(
                          future: FirebaseFirestore.instance.collection('users').doc(user.id).get(),
                          builder: (context, snapshot) {
                            String? profilePicUrl;
                            if (snapshot.hasData && snapshot.data!.data() != null) {
                              final data = snapshot.data!.data() as Map<String, dynamic>;
                              profilePicUrl = data['profilePicUrl'];
                            }
                            return CircleAvatar(
                              backgroundColor: Colors.deepPurple,
                              backgroundImage: profilePicUrl != null ? NetworkImage(profilePicUrl) : null,
                              child: profilePicUrl == null
                                  ? Text(
                                      user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                                      style: const TextStyle(color: Colors.white),
                                    )
                                  : null,
                            );
                          },
                        ),
                        title: Text(user.name),
                        subtitle: Text(user.email),
                        onTap: () {
                          Navigator.pop(context);
                          _followAndChat(context, user.id, user.name);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _searchUsers(String query) async {
    if (query.isEmpty) {
      setState(() {
        _users = [];
      });
      return;
    }

    if (!await _checkInternetConnection()) {
      _showConnectionError();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isGreaterThanOrEqualTo: query.toLowerCase())
          .where('email', isLessThan: '${query.toLowerCase()}z')
          .limit(10)
          .get();

      final users = querySnapshot.docs
          .map((doc) => UserModel.fromMap(doc.data(), doc.id))
          .where((user) => user.id != currentUser.uid)
          .toList();

      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _users = [];
        _isLoading = false;
      });
    }
  }

  void _followAndChat(BuildContext context, String userId, String userName) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          otherUserId: userId,
          otherUserName: userName,
          chatType: 'personal',
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}