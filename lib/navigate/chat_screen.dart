import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../controllers/chat_controller.dart';
import '../models/message_model.dart';
import '../widgets/loading_screen.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String otherUserId;
  final String otherUserName;
  final String? chatType;
  final String? companyId;
  
  const ChatScreen({super.key, required this.otherUserId, required this.otherUserName, this.chatType, this.companyId});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> with WidgetsBindingObserver {
  final _messageController = TextEditingController();
  String? _chatId;
  final _currentUserId = FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeChat();
    _updateUserPresence(true);
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _updateUserPresence(false);
    _messageController.dispose();
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _chatId != null && _currentUserId != null) {
      final chatController = ref.read(chatControllerProvider);
      chatController.markMessagesAsRead(_chatId!, _currentUserId);
      _updateUserPresence(true);
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      _updateUserPresence(false);
    }
  }

  Future<void> _initializeChat() async {
    if (!mounted) return;
    try {
      final chatController = ref.read(chatControllerProvider);
      final chatId = await chatController.createOrGetChatId(
        widget.otherUserId, 
        chatType: widget.chatType,
        companyId: widget.companyId,
      );
      if (!mounted) return;
      if (chatId.isNotEmpty) {
        setState(() {
          _chatId = chatId;
        });
        
        // Mark messages as read when chat is opened
        if (_currentUserId != null && mounted) {
          await chatController.markMessagesAsRead(chatId, _currentUserId);
        }
      } else {
        setState(() {
          _chatId = 'error';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _chatId = 'error';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_chatId == null) {
      return const LoadingScreen();
    }
    
    if (_chatId == 'error') {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Error'),
          backgroundColor: Colors.deepPurple,
        ),
        body: const Center(
          child: Text('Failed to load chat'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            widget.chatType == 'company'
                ? FutureBuilder<DocumentSnapshot>(
                    future: widget.companyId != null
                        ? FirebaseFirestore.instance.collection('companies').doc(widget.companyId).get()
                        : FirebaseFirestore.instance
                            .collection('companies')
                            .where('ownerId', isEqualTo: widget.otherUserId)
                            .limit(1)
                            .get()
                            .then((snapshot) => snapshot.docs.first),
                    builder: (context, snapshot) {
                      String? photoUrl;
                      if (snapshot.hasData && snapshot.data!.data() != null) {
                        final data = snapshot.data!.data() as Map<String, dynamic>;
                        photoUrl = data['photoUrl'];
                      }
                      return Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: photoUrl != null
                            ? ClipOval(
                                child: Image.network(
                                  photoUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Center(
                                    child: Text(
                                      widget.otherUserName.substring(0, 1),
                                      style: const TextStyle(
                                        color: Colors.deepPurple,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            : Center(
                                child: Text(
                                  widget.otherUserName.substring(0, 1),
                                  style: const TextStyle(
                                    color: Colors.deepPurple,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                      );
                    },
                  )
                : FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance.collection('users').doc(widget.otherUserId).get(),
                    builder: (context, snapshot) {
                      String? profilePicUrl;
                      if (snapshot.hasData && snapshot.data!.data() != null) {
                        final data = snapshot.data!.data() as Map<String, dynamic>;
                        profilePicUrl = data['profilePicUrl'];
                      }
                      return Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: profilePicUrl != null
                            ? ClipOval(
                                child: Image.network(
                                  profilePicUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Center(
                                    child: Text(
                                      widget.otherUserName.substring(0, 1),
                                      style: const TextStyle(
                                        color: Colors.deepPurple,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            : Center(
                                child: Text(
                                  widget.otherUserName.substring(0, 1),
                                  style: const TextStyle(
                                    color: Colors.deepPurple,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                      );
                    },
                  ),
            const SizedBox(width: 12),
            Expanded(
              child: widget.chatType == 'company'
                  ? FutureBuilder<List<DocumentSnapshot>>(
                      future: Future.wait([
                        widget.companyId != null
                            ? FirebaseFirestore.instance.collection('companies').doc(widget.companyId).get()
                            : FirebaseFirestore.instance.collection('chats').doc(_chatId).get().then((chat) async {
                                final chatData = chat.data() as Map<String, dynamic>?;
                                final companyId = chatData?['companyId'];
                                if (companyId != null) {
                                  return await FirebaseFirestore.instance.collection('companies').doc(companyId).get();
                                }
                                return chat;
                              }),
                        FirebaseFirestore.instance.collection('users').doc(widget.otherUserId).get(),
                      ]),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          final companyData = snapshot.data![0].data() as Map<String, dynamic>?;
                          final userData = snapshot.data![1].data() as Map<String, dynamic>?;
                          
                          final companyName = companyData?['name'] ?? widget.otherUserName;
                          final senderName = userData?['name'] ?? 'User';
                          
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                companyName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                'from $senderName',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          );
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.otherUserName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Text(
                              'Company Chat',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        );
                      },
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.otherUserName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        StreamBuilder<DocumentSnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('users')
                              .doc(widget.otherUserId)
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.hasData && snapshot.data!.exists) {
                              final userData = snapshot.data!.data() as Map<String, dynamic>;
                              final isOnline = userData['isOnline'] ?? false;
                              final lastSeen = userData['lastSeen']?.toDate();
                              
                              if (isOnline) {
                                return Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: Colors.green,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Text(
                                      'Online',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                );
                              } else if (lastSeen != null) {
                                final now = DateTime.now();
                                final difference = now.difference(lastSeen);
                                String lastSeenText;
                                
                                if (difference.inMinutes < 1) {
                                  lastSeenText = 'Just now';
                                } else if (difference.inMinutes < 60) {
                                  lastSeenText = '${difference.inMinutes}m ago';
                                } else if (difference.inHours < 24) {
                                  lastSeenText = '${difference.inHours}h ago';
                                } else {
                                  lastSeenText = '${difference.inDays}d ago';
                                }
                                
                                return Text(
                                  'Last seen $lastSeenText',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                );
                              }
                            }
                            return const Text(
                              'Offline',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (widget.chatType == 'company') 
            FutureBuilder<bool>(
              future: _checkIfCompanyOwner(),
              builder: (context, snapshot) {
                if (snapshot.data == true) {
                  return IconButton(
                    icon: const Icon(Icons.business, color: Colors.white),
                    onPressed: _showInviteToCompanyDialog,
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          IconButton(
            icon: const Icon(Icons.call, color: Colors.white),
            onPressed: _initiateCall,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              switch (value) {
                case 'clear':
                  _showClearChatDialog();
                  break;
                case 'block':
                  _showBlockUserDialog();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.clear_all, color: Colors.grey),
                    SizedBox(width: 8),
                    Text('Clear Chat'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'block',
                child: Row(
                  children: [
                    Icon(Icons.block, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Block User', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _chatId == null || _chatId!.isEmpty
                ? const LoadingScreen()
                : StreamBuilder<List<MessageModel>>(
              stream: ref.read(chatControllerProvider).getMessages(_chatId!),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const LoadingScreen();
                }
                
                final messages = snapshot.data!;
                
                if (messages.isEmpty) {
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
                        Text(
                          'Start a conversation with ${widget.otherUserName}',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }
                
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final reversedIndex = messages.length - 1 - index;
                    final message = messages[reversedIndex];
                    final isMe = message.senderId == _currentUserId;
                    
                    return Column(
                      crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
                        if (widget.chatType == 'company')
                          FutureBuilder<DocumentSnapshot>(
                            future: FirebaseFirestore.instance.collection('users').doc(message.senderId).get(),
                            builder: (context, snapshot) {
                              final userName = snapshot.hasData && snapshot.data!.data() != null
                                  ? (snapshot.data!.data() as Map<String, dynamic>)['name'] ?? 'User'
                                  : 'User';
                              return Padding(
                                padding: const EdgeInsets.only(left: 12, right: 12, bottom: 4),
                                child: Text(
                                  isMe ? 'Sent by you' : 'Message from $userName',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            },
                          )
                        else
                          Padding(
                            padding: const EdgeInsets.only(left: 12, right: 12, bottom: 4),
                            child: Text(
                              isMe ? 'Sent by you' : 'Message from ${widget.otherUserName}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        Align(
                          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.75,
                            ),
                            decoration: BoxDecoration(
                              color: isMe ? Colors.deepPurple : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.1),
                                  spreadRadius: 1,
                                  blurRadius: 3,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: _buildMessageContent(message, isMe),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: Row(
              children: [
                if (widget.chatType == 'company') ...[
                  IconButton(
                    icon: Icon(Icons.note_add, color: Colors.grey[600]),
                    onPressed: _showCreateNoteDialog,
                  ),
                  IconButton(
                    icon: Icon(Icons.camera_alt, color: Colors.grey[600]),
                    onPressed: _showImagePicker,
                  ),
                ] else
                  IconButton(
                    icon: Icon(Icons.attach_file, color: Colors.grey[600]),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('File attachment coming soon!'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: 'Type a message...',
                        border: InputBorder.none,
                        hintStyle: TextStyle(color: Colors.grey),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                      maxLines: null,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(
                    Icons.emoji_emotions_outlined,
                    color: Colors.grey[600],
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Emoji picker coming soon!'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: Colors.deepPurple,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _checkInternetConnection() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return !connectivityResult.contains(ConnectivityResult.none);
  }

  void _showConnectionError() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Connection error. Please check your internet and try again.'),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _sendMessage() async {
    if (!mounted || _messageController.text.trim().isEmpty) return;
    
    if (!await _checkInternetConnection()) {
      if (mounted) _showConnectionError();
      return;
    }
    
    // Check if chat is archived (company deleted)
    try {
      final chatDoc = await FirebaseFirestore.instance.collection('chats').doc(_chatId!).get();
      if (!mounted) return;
      if (chatDoc.exists) {
        final chatData = chatDoc.data() as Map<String, dynamic>;
        if (chatData['isArchived'] == true) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Cannot send message. Company no longer exists.'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
      }
    } catch (e) {
      // Continue with normal flow if check fails
    }
    
    if (!mounted) return;
    final chatController = ref.read(chatControllerProvider);
    await chatController.sendMessage(_chatId!, _messageController.text);
    if (mounted) _messageController.clear();
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(timestamp.year, timestamp.month, timestamp.day);
    
    final hour = timestamp.hour == 0 ? 12 : (timestamp.hour > 12 ? timestamp.hour - 12 : timestamp.hour);
    final minute = timestamp.minute.toString().padLeft(2, '0');
    final period = timestamp.hour >= 12 ? 'PM' : 'AM';
    final timeStr = '$hour:$minute $period';
    
    if (messageDate == today) {
      return 'Today $timeStr';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday $timeStr';
    } else {
      final day = timestamp.day.toString().padLeft(2, '0');
      final month = timestamp.month.toString().padLeft(2, '0');
      return '$day/$month/${timestamp.year} $timeStr';
    }
  }

  void _showClearChatDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Chat'),
        content: const Text('Are you sure you want to clear this chat? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Clear chat feature coming soon!'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text(
              'Clear',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
  
  void _showBlockUserDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Block ${widget.otherUserName}'),
        content: Text('Are you sure you want to block ${widget.otherUserName}? You will no longer receive messages from them.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Block user feature coming soon!'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text(
              'Block',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageContent(MessageModel message, bool isMe) {
    // Check if this is a collaboration message
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('chats')
          .doc(_chatId!)
          .collection('messages')
          .doc(message.id)
          .get(),
      builder: (context, snapshot) {
        final messageData = snapshot.data?.data() as Map<String, dynamic>?;
        final messageType = messageData?['messageType'];
        
        if (messageType == 'collaboration_invite' || messageType == 'collaboration_request') {
          return _buildCollaborationMessage(message, messageData!, isMe);
        }
        
        if (messageType == 'company_invitation') {
          return _buildCompanyInvitationMessage(message, messageData!, isMe);
        }
        
        if (messageType == 'note') {
          return _buildNoteMessage(message, messageData!, isMe);
        }
        
        if (messageType == 'image') {
          return _buildImageMessage(message, messageData!, isMe);
        }
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: TextStyle(
                color: isMe ? Colors.white : Colors.black87,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(message.timestamp),
                  style: TextStyle(
                    color: isMe ? Colors.white70 : Colors.grey,
                    fontSize: 10,
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    message.isRead ? Icons.done_all : (message.isDelivered ? Icons.done : Icons.access_time),
                    size: 12,
                    color: message.isRead ? Colors.blue : (isMe ? Colors.white70 : Colors.grey),
                  ),
                ],
              ],
            ),
          ],
        );
      },
    );
  }
  
  Widget _buildCollaborationMessage(MessageModel message, Map<String, dynamic> messageData, bool isMe) {
    final messageType = messageData['messageType'];
    final isResolved = messageData['resolved'] ?? false;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                messageType == 'collaboration_invite' ? Icons.business : Icons.handshake,
                color: Colors.blue,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                messageType == 'collaboration_invite' ? 'Company Invitation' : 'Collaboration Request',
                style: const TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          message.text,
          style: TextStyle(
            color: isMe ? Colors.white : Colors.black87,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        if (!isMe && !isResolved) ...[
          Row(
            children: [
              ElevatedButton(
                onPressed: () => _handleCollaborationResponse(message.id, messageData, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
                child: const Text('Accept', style: TextStyle(color: Colors.white, fontSize: 12)),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => _handleCollaborationResponse(message.id, messageData, false),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
                child: const Text('Decline', style: TextStyle(color: Colors.white, fontSize: 12)),
              ),
            ],
          ),
        ] else if (isResolved) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: messageData['accepted'] == true ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              messageData['accepted'] == true ? 'Accepted' : 'Declined',
              style: TextStyle(
                color: messageData['accepted'] == true ? Colors.green : Colors.red,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _formatTime(message.timestamp),
              style: TextStyle(
                color: isMe ? Colors.white70 : Colors.grey,
                fontSize: 10,
              ),
            ),
            if (isMe) ...
            [
              const SizedBox(width: 4),
              Icon(
                message.isRead ? Icons.done_all : (message.isDelivered ? Icons.done : Icons.access_time),
                size: 12,
                color: message.isRead ? Colors.blue : (isMe ? Colors.white70 : Colors.grey),
              ),
            ],
          ],
        ),
      ],
    );
  }
  
  Future<void> _handleCollaborationResponse(String messageId, Map<String, dynamic> messageData, bool accepted) async {
    if (!await _checkInternetConnection()) {
      _showConnectionError();
      return;
    }
    
    try {
      final messageType = messageData['messageType'];
      
      // Update message as resolved
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(_chatId!)
          .collection('messages')
          .doc(messageId)
          .update({
        'resolved': true,
        'accepted': accepted,
      });
      
      if (accepted) {
        if (messageType == 'collaboration_invite') {
          // Show dialog to get position and ID number
          await _showCollaborationDetailsDialog(messageData['companyId']);
        } else {
          // Send confirmation message
          await ref.read(chatControllerProvider).sendMessage(
            _chatId!,
            'Collaboration accepted!',
          );
        }
      } else {
        await ref.read(chatControllerProvider).sendMessage(
          _chatId!,
          'Collaboration declined.',
        );
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(accepted ? 'Collaboration accepted!' : 'Collaboration declined.'),
          backgroundColor: accepted ? Colors.green : Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to respond to collaboration'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showCollaborationDetailsDialog(String companyId) async {
    final positionController = TextEditingController();
    final idController = TextEditingController();
    
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Complete Your Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please provide your position and ID number to complete the collaboration.'),
            const SizedBox(height: 16),
            TextField(
              controller: positionController,
              decoration: const InputDecoration(
                labelText: 'Position',
                prefixIcon: Icon(Icons.work),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: idController,
              decoration: const InputDecoration(
                labelText: 'ID Number',
                prefixIcon: Icon(Icons.badge),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Send decline message if cancelled
              ref.read(chatControllerProvider).sendMessage(
                _chatId!,
                'Collaboration cancelled.',
              );
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (positionController.text.isNotEmpty && idController.text.isNotEmpty) {
                await _completeCollaboration(companyId, positionController.text, idController.text);
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Complete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
  
  Future<bool> _checkIfCompanyOwner() async {
    try {
      final companiesQuery = await FirebaseFirestore.instance
          .collection('companies')
          .where('ownerId', isEqualTo: _currentUserId)
          .limit(1)
          .get();
      return companiesQuery.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  void _showInviteToCompanyDialog() async {
    try {
      // Check if current user owns any companies
      final companiesQuery = await FirebaseFirestore.instance
          .collection('companies')
          .where('ownerId', isEqualTo: _currentUserId)
          .get();
      
      if (companiesQuery.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You need to own a company to send invitations'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      
      final companies = companiesQuery.docs;
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Invite to Company'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Select a company to invite ${widget.otherUserName}:'),
              const SizedBox(height: 16),
              ...companies.map((doc) {
                final data = doc.data();
                return ListTile(
                  leading: const Icon(Icons.business),
                  title: Text(data['name'] ?? 'Unknown Company'),
                  subtitle: Text(data['industry'] ?? 'No industry'),
                  onTap: () {
                    Navigator.pop(context);
                    _sendCompanyInvitation(doc.id, data['name'] ?? 'Company');
                  },
                );
              }),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to load companies'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  Future<void> _sendCompanyInvitation(String companyId, String companyName) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Invitation'),
        content: Text('Send company invitation for "$companyName" to ${widget.otherUserName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _sendInvitationMessage(companyId, companyName);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
            child: const Text('Send Invitation', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
  
  Future<void> _sendInvitationMessage(String companyId, String companyName) async {
    if (!await _checkInternetConnection()) {
      _showConnectionError();
      return;
    }
    
    try {
      final messageText = 'You have been invited to join "$companyName" in the construction industry. Accept this invitation to become part of our team!';
      
      // Send special invitation message
      final messageRef = FirebaseFirestore.instance
          .collection('chats')
          .doc(_chatId!)
          .collection('messages')
          .doc();
      
      await messageRef.set({
        'chatId': _chatId!,
        'senderId': _currentUserId,
        'text': messageText,
        'timestamp': DateTime.now(),
        'isRead': false,
        'isDelivered': true,
        'messageType': 'company_invitation',
        'companyId': companyId,
        'companyName': companyName,
        'resolved': false,
      });
      
      // Update chat's last message
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(_chatId!)
          .update({
        'lastMessage': 'Company invitation sent',
        'lastMessageTime': DateTime.now(),
        'lastSenderId': _currentUserId,
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Company invitation sent!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to send invitation'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _completeCollaboration(String companyId, String position, String idNumber) async {
    if (!await _checkInternetConnection()) {
      _showConnectionError();
      return;
    }
    
    try {
      // Get company owner's building number
      final companyDoc = await FirebaseFirestore.instance
          .collection('companies')
          .doc(companyId)
          .get();
      
      final ownerId = companyDoc.data()!['ownerId'];
      
      final ownerMemberDoc = await FirebaseFirestore.instance
          .collection('company_members')
          .doc('${companyId}_$ownerId')
          .get();
      
      final ownerBuildingNo = ownerMemberDoc.data()?['buildingNo'] ?? '';
      
      // Add user as collaborator with same building number
      await FirebaseFirestore.instance
          .collection('company_members')
          .doc('${companyId}_$_currentUserId')
          .set({
        'companyId': companyId,
        'userId': _currentUserId,
        'position': position,
        'buildingNo': ownerBuildingNo,
        'idNumber': idNumber,
        'joinedAt': DateTime.now(),
      });
      
      await FirebaseFirestore.instance
          .collection('companies')
          .doc(companyId)
          .update({
        'memberIds': FieldValue.arrayUnion([_currentUserId])
      });
      
      // Send confirmation message
      await ref.read(chatControllerProvider).sendMessage(
        _chatId!,
        'Collaboration completed! Welcome to the team.',
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Successfully joined the company!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to complete collaboration'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  Widget _buildCompanyInvitationMessage(MessageModel message, Map<String, dynamic> messageData, bool isMe) {
    final isResolved = messageData['resolved'] ?? false;
    final companyName = messageData['companyName'] ?? 'Company';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.business,
                color: Colors.orange,
                size: 16,
              ),
              const SizedBox(width: 8),
              const Text(
                'Company Invitation',
                style: TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          message.text,
          style: TextStyle(
            color: isMe ? Colors.white : Colors.black87,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        if (!isMe && !isResolved) ...[
          Row(
            children: [
              ElevatedButton(
                onPressed: () => _handleInvitationResponse(message.id, messageData, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
                child: const Text('Accept', style: TextStyle(color: Colors.white, fontSize: 12)),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => _handleInvitationResponse(message.id, messageData, false),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
                child: const Text('Decline', style: TextStyle(color: Colors.white, fontSize: 12)),
              ),
            ],
          ),
        ] else if (isResolved) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: messageData['accepted'] == true ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              messageData['accepted'] == true ? 'Invitation Accepted' : 'Invitation Declined',
              style: TextStyle(
                color: messageData['accepted'] == true ? Colors.green : Colors.red,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _formatTime(message.timestamp),
              style: TextStyle(
                color: isMe ? Colors.white70 : Colors.grey,
                fontSize: 10,
              ),
            ),
            if (isMe) ...
            [
              const SizedBox(width: 4),
              Icon(
                message.isRead ? Icons.done_all : (message.isDelivered ? Icons.done : Icons.access_time),
                size: 12,
                color: message.isRead ? Colors.blue : (isMe ? Colors.white70 : Colors.grey),
              ),
            ],
          ],
        ),
      ],
    );
  }
  
  Future<void> _handleInvitationResponse(String messageId, Map<String, dynamic> messageData, bool accepted) async {
    if (!await _checkInternetConnection()) {
      _showConnectionError();
      return;
    }
    
    try {
      // Update message as resolved
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(_chatId!)
          .collection('messages')
          .doc(messageId)
          .update({
        'resolved': true,
        'accepted': accepted,
      });
      
      if (accepted) {
        // Show dialog to get position and ID number
        await _showJoinCompanyDialog(messageData['companyId'], messageData['companyName']);
      } else {
        await ref.read(chatControllerProvider).sendMessage(
          _chatId!,
          'Company invitation declined.',
        );
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(accepted ? 'Invitation accepted!' : 'Invitation declined.'),
          backgroundColor: accepted ? Colors.green : Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to respond to invitation'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  Future<void> _showJoinCompanyDialog(String companyId, String companyName) async {
    final positionController = TextEditingController();
    final idController = TextEditingController();
    
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Join $companyName'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Please provide your details to join $companyName:'),
            const SizedBox(height: 16),
            TextField(
              controller: positionController,
              decoration: const InputDecoration(
                labelText: 'Position',
                prefixIcon: Icon(Icons.work),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: idController,
              decoration: const InputDecoration(
                labelText: 'ID Number',
                prefixIcon: Icon(Icons.badge),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(chatControllerProvider).sendMessage(
                _chatId!,
                'Company invitation cancelled.',
              );
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (positionController.text.isNotEmpty && idController.text.isNotEmpty) {
                await _joinCompany(companyId, companyName, positionController.text, idController.text);
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Join Company', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
  
  void _initiateCall() async {
    // Get user's phone number from Firestore
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.otherUserId)
          .get();
      
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        final phoneNumber = userData['phoneNumber'];
        
        if (phoneNumber != null && phoneNumber.isNotEmpty) {
          _showCallDialog(phoneNumber);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User has no phone number registered'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to get contact information'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  void _showCallDialog(String phoneNumber) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Call ${widget.otherUserName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.phone, size: 48, color: Colors.green),
            const SizedBox(height: 16),
            Text('Call $phoneNumber?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _makeCall(phoneNumber);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Call', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
  
  Future<void> _makeCall(String phoneNumber) async {
    try {
      final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
      
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
        
        // Send call notification message
        await ref.read(chatControllerProvider).sendMessage(
          _chatId!,
          'Voice call initiated',
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cannot make calls on this device'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to make call'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _updateUserPresence(bool isOnline) async {
    if (_currentUserId == null || !mounted) return;
    
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUserId)
          .update({
        'isOnline': isOnline,
        'lastSeen': DateTime.now(),
      });
    } catch (e) {
      // Ignore presence update errors
    }
  }

  void _toggleNoteItem(String messageId, Map<String, dynamic> noteData, int index) async {
    if (!mounted) return;
    try {
      final items = List<Map<String, dynamic>>.from(noteData['items']);
      items[index]['checked'] = !(items[index]['checked'] ?? false);
      
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(_chatId!)
          .collection('messages')
          .doc(messageId)
          .update({
        'noteData.items': items,
      });
      
      // Send update notification message
      final now = DateTime.now();
      final timeStr = _formatTime(now);
      await ref.read(chatControllerProvider).sendMessage(
        _chatId!,
        'Note checklist updated on $timeStr',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update note'), backgroundColor: Colors.red),
        );
      }
    }
  }
  
  void _editNote(String messageId, String currentTitle, List<Map<String, dynamic>> currentItems) {
    final titleController = TextEditingController(text: currentTitle);
    final List<Map<String, dynamic>> checkItems = currentItems.map((item) => {
      'controller': TextEditingController(text: item['text']),
      'checked': item['checked'] ?? false,
    }).toList();
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Note'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Note Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Checklist Items:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...checkItems.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  return Row(
                    children: [
                      Checkbox(
                        value: item['checked'],
                        onChanged: (value) {
                          setState(() {
                            checkItems[index]['checked'] = value ?? false;
                          });
                        },
                      ),
                      Expanded(
                        child: TextField(
                          controller: item['controller'],
                          decoration: const InputDecoration(
                            hintText: 'Task item',
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            checkItems.removeAt(index);
                          });
                        },
                      ),
                    ],
                  );
                }),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      checkItems.add({
                        'controller': TextEditingController(),
                        'checked': false,
                      });
                    });
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Item'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.isNotEmpty) {
                  _updateNote(messageId, titleController.text, checkItems);
                  Navigator.pop(context);
                }
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _updateNote(String messageId, String title, List<Map<String, dynamic>> items) async {
    final noteData = {
      'title': title,
      'items': items.map((item) => {
        'text': item['controller'].text,
        'checked': item['checked'],
      }).toList(),
    };
    
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(_chatId!)
        .collection('messages')
        .doc(messageId)
        .update({
      'text': 'Note: $title',
      'noteData': noteData,
    });
    
    // Send update notification message
    final now = DateTime.now();
    final timeStr = _formatTime(now);
    await ref.read(chatControllerProvider).sendMessage(
      _chatId!,
      'Note "$title" was edited on $timeStr',
    );
  }
  
  void _showCreateNoteDialog() {
    final titleController = TextEditingController();
    final List<Map<String, dynamic>> checkItems = [];
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Create Note'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Note Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Checklist Items:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...checkItems.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  return Row(
                    children: [
                      Checkbox(
                        value: item['checked'],
                        onChanged: (value) {
                          setState(() {
                            checkItems[index]['checked'] = value ?? false;
                          });
                        },
                      ),
                      Expanded(
                        child: TextField(
                          controller: item['controller'],
                          decoration: const InputDecoration(
                            hintText: 'Task item',
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            checkItems.removeAt(index);
                          });
                        },
                      ),
                    ],
                  );
                }),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      checkItems.add({
                        'controller': TextEditingController(),
                        'checked': false,
                      });
                    });
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Item'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.isNotEmpty) {
                  _sendNoteMessage(titleController.text, checkItems);
                  Navigator.pop(context);
                }
              },
              child: const Text('Send Note'),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showImagePicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        _uploadAndSendImageWeb(bytes, pickedFile.name);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to pick image'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  Future<void> _uploadAndSendImageWeb(Uint8List imageBytes, String fileName) async {
    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('chat_images')
          .child('${DateTime.now().millisecondsSinceEpoch}.jpg');
      
      await storageRef.putData(imageBytes);
      final downloadUrl = await storageRef.getDownloadURL();
      await _sendImageMessage(downloadUrl);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Upload failed'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  Future<void> _uploadAndSendImage(File imageFile) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Uploading image...'),
          ],
        ),
      ),
    );
    
    try {
      // Check internet connection first
      if (!await _checkInternetConnection()) {
        Navigator.pop(context); // Close loading dialog
        _showConnectionError();
        return;
      }
      
      // Validate file size (max 10MB)
      final fileSize = await imageFile.length();
      if (fileSize > 10 * 1024 * 1024) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image too large. Please select an image smaller than 10MB.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('chat_images')
          .child('${_currentUserId}_${DateTime.now().millisecondsSinceEpoch}.jpg');
      
      final uploadTask = storageRef.putFile(imageFile);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      Navigator.pop(context); // Close loading dialog
      await _sendImageMessage(downloadUrl);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Image sent successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      String errorMessage = 'Failed to upload image';
      
      if (e.toString().contains('network')) {
        errorMessage = 'Network error. Please check your connection.';
      } else if (e.toString().contains('permission')) {
        errorMessage = 'Permission denied. Please check app permissions.';
      } else if (e.toString().contains('storage')) {
        errorMessage = 'Storage error. Please try again.';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: () => _uploadAndSendImage(imageFile),
          ),
        ),
      );
    }
  }
  
  Future<void> _sendNoteMessage(String title, List<Map<String, dynamic>> items) async {
    final noteData = {
      'title': title,
      'items': items.map((item) => {
        'text': item['controller'].text,
        'checked': item['checked'],
      }).toList(),
    };
    
    final messageRef = FirebaseFirestore.instance
        .collection('chats')
        .doc(_chatId!)
        .collection('messages')
        .doc();
    
    await messageRef.set({
      'chatId': _chatId!,
      'senderId': _currentUserId,
      'text': 'Note: $title',
      'timestamp': DateTime.now(),
      'isRead': false,
      'isDelivered': true,
      'messageType': 'note',
      'noteData': noteData,
    });
    
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(_chatId!)
        .update({
      'lastMessage': 'Note: $title',
      'lastMessageTime': DateTime.now(),
      'lastSenderId': _currentUserId,
    });
  }
  
  Future<void> _sendImageMessage(String imageUrl) async {
    final messageRef = FirebaseFirestore.instance
        .collection('chats')
        .doc(_chatId!)
        .collection('messages')
        .doc();
    
    await messageRef.set({
      'chatId': _chatId!,
      'senderId': _currentUserId,
      'text': 'Photo',
      'timestamp': DateTime.now(),
      'isRead': false,
      'isDelivered': true,
      'messageType': 'image',
      'imageUrl': imageUrl,
    });
    
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(_chatId!)
        .update({
      'lastMessage': 'Photo',
      'lastMessageTime': DateTime.now(),
      'lastSenderId': _currentUserId,
    });
  }
  
  Widget _buildNoteMessage(MessageModel message, Map<String, dynamic> messageData, bool isMe) {
    final noteData = messageData['noteData'] as Map<String, dynamic>;
    final title = noteData['title'] as String;
    final items = List<Map<String, dynamic>>.from(noteData['items']);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(Icons.note, color: Colors.orange, size: 16),
              const SizedBox(width: 8),
              const Text(
                'Note',
                style: TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              if (isMe)
                GestureDetector(
                  onTap: () => _editNote(message.id, title, items),
                  child: Icon(
                    Icons.edit,
                    color: isMe ? Colors.white70 : Colors.grey,
                    size: 16,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: TextStyle(
            color: isMe ? Colors.white : Colors.black87,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: GestureDetector(
              onTap: isMe ? () => _toggleNoteItem(message.id, noteData, index) : null,
              child: Row(
                children: [
                  Icon(
                    item['checked'] ? Icons.check_box : Icons.check_box_outline_blank,
                    color: item['checked'] ? Colors.green : (isMe ? Colors.white70 : Colors.grey),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item['text'],
                      style: TextStyle(
                        color: isMe ? Colors.white : Colors.black87,
                        fontSize: 14,
                        decoration: item['checked'] ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _formatTime(message.timestamp),
              style: TextStyle(
                color: isMe ? Colors.white70 : Colors.grey,
                fontSize: 10,
              ),
            ),
            if (isMe) ...[
              const SizedBox(width: 4),
              Icon(
                message.isRead ? Icons.done_all : (message.isDelivered ? Icons.done : Icons.access_time),
                size: 12,
                color: message.isRead ? Colors.blue : (isMe ? Colors.white70 : Colors.grey),
              ),
            ],
          ],
        ),
      ],
    );
  }
  
  Widget _buildImageMessage(MessageModel message, Map<String, dynamic> messageData, bool isMe) {
    final imageUrl = messageData['imageUrl'] as String;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          constraints: const BoxConstraints(maxWidth: 250, maxHeight: 300),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              imageUrl,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  height: 200,
                  color: Colors.grey[300],
                  child: const Center(child: CircularProgressIndicator()),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 200,
                  color: Colors.grey[300],
                  child: const Center(
                    child: Icon(Icons.error, color: Colors.red),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _formatTime(message.timestamp),
              style: TextStyle(
                color: isMe ? Colors.white70 : Colors.grey,
                fontSize: 10,
              ),
            ),
            if (isMe) ...[
              const SizedBox(width: 4),
              Icon(
                message.isRead ? Icons.done_all : (message.isDelivered ? Icons.done : Icons.access_time),
                size: 12,
                color: message.isRead ? Colors.blue : (isMe ? Colors.white70 : Colors.grey),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Future<void> _joinCompany(String companyId, String companyName, String position, String idNumber) async {
    try {
      // Get company owner's building number
      final companyDoc = await FirebaseFirestore.instance
          .collection('companies')
          .doc(companyId)
          .get();
      
      final ownerId = companyDoc.data()!['ownerId'];
      
      final ownerMemberDoc = await FirebaseFirestore.instance
          .collection('company_members')
          .doc('${companyId}_$ownerId')
          .get();
      
      final ownerBuildingNo = ownerMemberDoc.data()?['buildingNo'] ?? '';
      
      // Add user as company member
      await FirebaseFirestore.instance
          .collection('company_members')
          .doc('${companyId}_$_currentUserId')
          .set({
        'companyId': companyId,
        'userId': _currentUserId,
        'position': position,
        'buildingNo': ownerBuildingNo,
        'idNumber': idNumber,
        'joinedAt': DateTime.now(),
      });
      
      await FirebaseFirestore.instance
          .collection('companies')
          .doc(companyId)
          .update({
        'memberIds': FieldValue.arrayUnion([_currentUserId])
      });
      
      // Send confirmation message
      await ref.read(chatControllerProvider).sendMessage(
        _chatId!,
        'Successfully joined $companyName! Welcome to the team.',
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully joined $companyName!'),
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