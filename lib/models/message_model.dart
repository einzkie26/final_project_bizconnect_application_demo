class MessageModel {
  final String id;
  final String chatId;
  final String senderId;
  final String text;
  final DateTime timestamp;
  final bool isRead;
  final bool isDelivered;

  MessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.text,
    required this.timestamp,
    this.isRead = false,
    this.isDelivered = true,
  });

  factory MessageModel.fromMap(Map<String, dynamic> map, String id) {
    return MessageModel(
      id: id,
      chatId: map['chatId'] ?? '',
      senderId: map['senderId'] ?? '',
      text: map['text'] ?? '',
      timestamp: map['timestamp']?.toDate() ?? DateTime.now(),
      isRead: map['isRead'] ?? false,
      isDelivered: map['isDelivered'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'chatId': chatId,
      'senderId': senderId,
      'text': text,
      'timestamp': timestamp,
      'isRead': isRead,
      'isDelivered': isDelivered,
    };
  }
}