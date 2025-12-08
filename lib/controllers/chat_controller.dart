import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/message_model.dart';

class ChatController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<List<MessageModel>> getMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MessageModel.fromMap(doc.data(), doc.id))
            .toList())
        .handleError((error) {
          return <MessageModel>[];
        });
  }

  Future<void> sendMessage(String chatId, String text) async {
    try {
      final user = _auth.currentUser;
      if (user == null || text.trim().isEmpty || chatId.isEmpty) return;

      final message = MessageModel(
        id: '',
        chatId: chatId,
        senderId: user.uid,
        text: text.trim(),
        timestamp: DateTime.now(),
        isRead: false,
      );

      // Use batch write for better performance
      final batch = _firestore.batch();
      
      // Add message
      final messageRef = _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc();
      batch.set(messageRef, message.toMap());
      
      // Update chat metadata
      final chatRef = _firestore.collection('chats').doc(chatId);
      batch.update(chatRef, {
        'lastMessage': text.trim(),
        'lastMessageTime': DateTime.now(),
      });
      
      await batch.commit();
    } catch (e) {
      rethrow;
    }
  }

  Future<String> createOrGetChatId(String otherUserId, {String? chatType}) async {
    try {
      final user = _auth.currentUser;
      if (user == null || otherUserId.isEmpty) return '';

      // Determine chat type
      String finalChatType;
      if (chatType != null) {
        finalChatType = chatType;
      } else {
        // Get current user's mode to determine chat type
        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        final isCompanyMode = userDoc.data()?['isCompanyMode'] ?? false;
        finalChatType = isCompanyMode ? 'company' : 'personal';
      }

      final participants = [user.uid, otherUserId]..sort();
      final chatId = '${finalChatType}_${participants.join('_')}';

      final chatDoc = await _firestore.collection('chats').doc(chatId).get();
      
      if (!chatDoc.exists) {
        final chatData = {
          'participants': participants,
          'type': finalChatType,
          'createdAt': DateTime.now(),
          'lastMessage': '',
          'lastMessageTime': DateTime.now(),
        };
        
        // For company chats, store company name
        if (finalChatType == 'company') {
          try {
            final companyQuery = await _firestore
                .collection('companies')
                .where('ownerId', isEqualTo: otherUserId)
                .limit(1)
                .get();
            
            if (companyQuery.docs.isNotEmpty) {
              chatData['companyName'] = companyQuery.docs.first.data()['name'];
            }
          } catch (e) {
            // Continue without company name if lookup fails
          }
        }
        
        await _firestore.collection('chats').doc(chatId).set(chatData);
      }

      return chatId;
    } catch (e) {
      return '';
    }
  }
  

  Future<void> markMessagesAsRead(String chatId, String userId) async {
    try {
      final messagesQuery = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('senderId', isNotEqualTo: userId)
          .get();
      
      final batch = _firestore.batch();
      bool hasUpdates = false;
      
      for (var doc in messagesQuery.docs) {
        final data = doc.data();
        if (data['isRead'] != true) {
          batch.update(doc.reference, {'isRead': true});
          hasUpdates = true;
        }
      }
      
      if (hasUpdates) {
        await batch.commit();
      }
    } catch (e) {
      // Handle error silently
    }
  }
  
  Future<int> getUnreadMessageCount(String chatId, String userId) async {
    try {
      final unreadQuery = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('senderId', isNotEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();
      
      return unreadQuery.docs.length;
    } catch (e) {
      return 0;
    }
  }
}

final chatControllerProvider = Provider<ChatController>((ref) {
  return ChatController();
});