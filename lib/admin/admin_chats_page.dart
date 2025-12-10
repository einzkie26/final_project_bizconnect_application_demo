import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminChatsPage extends StatelessWidget {
  const AdminChatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat Monitoring'),
        backgroundColor: Colors.deepPurple,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('chats').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final chats = snapshot.data!.docs;

          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index].data() as Map<String, dynamic>;
              final chatId = chats[index].id;
              final participants = List<String>.from(chat['participants'] ?? []);
              
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: const Icon(Icons.chat, color: Colors.deepPurple),
                  title: Text('Chat ID: ${chatId.substring(0, 8)}...'),
                  subtitle: Text('${participants.length} participants'),
                  trailing: IconButton(
                    icon: const Icon(Icons.visibility),
                    onPressed: () => _viewChatMessages(context, chatId, participants),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _viewChatMessages(BuildContext context, String chatId, List<String> participants) async {
    final messages = await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .get();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chat Messages'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: messages.docs.isEmpty
              ? const Center(child: Text('No messages'))
              : ListView.builder(
                  itemCount: messages.docs.length,
                  itemBuilder: (context, index) {
                    final msg = messages.docs[index].data();
                    return ListTile(
                      title: Text(msg['text'] ?? ''),
                      subtitle: Text('From: ${msg['senderId']?.substring(0, 8)}...'),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteChat(context, chatId);
            },
            child: const Text('Delete Chat', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _deleteChat(BuildContext context, String chatId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Chat'),
        content: const Text('Are you sure you want to delete this chat?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('chats').doc(chatId).delete();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Chat deleted successfully')),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
