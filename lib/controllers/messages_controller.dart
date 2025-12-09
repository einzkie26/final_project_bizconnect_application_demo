import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatPreview {
  final String chatId;
  final String otherUserId;
  final String otherUserName;
  final String? otherUserRealName;
  final String lastMessage;
  final DateTime lastMessageTime;
  final bool hasUnread;
  final int unreadCount;
  final String? companyId;

  ChatPreview({
    required this.chatId,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserRealName,
    required this.lastMessage,
    required this.lastMessageTime,
    this.hasUnread = false,
    this.unreadCount = 0,
    this.companyId,
  });
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatPreview && other.otherUserId == otherUserId;
  }
  
  @override
  int get hashCode => otherUserId.hashCode;
}

class MessagesController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<List<ChatPreview>> getPersonalChats() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection('chats')
        .where('participants', arrayContains: user.uid)
        .where('type', isEqualTo: 'personal')
        .snapshots()
        .asyncMap((snapshot) async {
      return _processChats(snapshot, user.uid, false);
    }).handleError((error) {
      return <ChatPreview>[];
    });
  }

  Stream<List<ChatPreview>> getCompanyChats() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection('chats')
        .where('participants', arrayContains: user.uid)
        .where('type', isEqualTo: 'company')
        .snapshots()
        .asyncMap((snapshot) async {
      return _processChats(snapshot, user.uid, true);
    }).handleError((error) {
      return <ChatPreview>[];
    });
  }

  Future<List<ChatPreview>> _processChats(QuerySnapshot snapshot, String currentUserId, bool isCompanyMode) async {
    if (snapshot.docs.isEmpty) {
      return <ChatPreview>[];
    }
    
    Map<String, ChatPreview> uniqueChats = {};
    
    for (var doc in snapshot.docs) {
      try {
        final data = doc.data() as Map<String, dynamic>;
        final participants = List<String>.from(data['participants'] ?? []);
        final otherUserId = participants.firstWhere((id) => id != currentUserId, orElse: () => '');
        
        if (otherUserId.isEmpty) continue;
        
        // Use chatId as unique key for company chats to distinguish different companies
        final uniqueKey = isCompanyMode ? doc.id : otherUserId;
        
        // Skip if we already have this exact chat
        if (uniqueChats.containsKey(uniqueKey)) {
          continue;
        }
        
        String otherUserName = 'User';
        String? otherUserRealName;
        
        try {
          final userDoc = await _firestore.collection('users').doc(otherUserId).get();
          if (userDoc.exists && userDoc.data() != null) {
            final userData = userDoc.data()!;
            final realName = userData['name'] ?? 'User';
            
            if (isCompanyMode) {
              final storedCompanyName = data['companyName'];
              if (storedCompanyName != null) {
                otherUserName = storedCompanyName;
                otherUserRealName = realName;
              } else {
                try {
                  final companyQuery = await _firestore
                      .collection('companies')
                      .where('ownerId', isEqualTo: otherUserId)
                      .limit(1)
                      .get();
                  
                  if (companyQuery.docs.isNotEmpty) {
                    final companyData = companyQuery.docs.first.data();
                    otherUserName = companyData['name'] ?? realName;
                    otherUserRealName = realName;
                  } else {
                    otherUserName = realName;
                  }
                } catch (e) {
                  otherUserName = realName;
                }
              }
            } else {
              // For personal chats, always show personal name
              otherUserName = realName;
            }
          }
        } catch (e) {
          otherUserName = 'User';
        }
        
        // Check for unread messages
        bool hasUnread = false;
        int unreadCount = 0;
        try {
          final unreadQuery = await _firestore
              .collection('chats')
              .doc(doc.id)
              .collection('messages')
              .where('senderId', isNotEqualTo: currentUserId)
              .get();
          
          unreadCount = unreadQuery.docs.where((msgDoc) {
            final msgData = msgDoc.data();
            return msgData['isRead'] != true;
          }).length;
          
          hasUnread = unreadCount > 0;
        } catch (e) {
          hasUnread = false;
          unreadCount = 0;
        }
        
        uniqueChats[uniqueKey] = ChatPreview(
          chatId: doc.id,
          otherUserId: otherUserId,
          otherUserName: otherUserName,
          otherUserRealName: otherUserRealName,
          lastMessage: data['lastMessage'] ?? 'No messages yet',
          lastMessageTime: data['lastMessageTime']?.toDate() ?? DateTime.now(),
          hasUnread: hasUnread,
          unreadCount: unreadCount,
          companyId: data['companyId'],
        );
      } catch (e) {
        continue;
      }
    }
    
    // Convert to list and sort by last message time
    final chatsList = uniqueChats.values.toList();
    chatsList.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
    return chatsList;
  }
}

final messagesControllerProvider = Provider<MessagesController>((ref) {
  return MessagesController();
});