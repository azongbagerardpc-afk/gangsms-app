class Message {
  final String id;
  final String roomId;
  final String sender;
  final String? content;
  final String type;
  final String? fileUrl;
  final DateTime createdAt;

  Message({
    required this.id,
    required this.roomId,
    required this.sender,
    this.content,
    required this.type,
    this.fileUrl,
    required this.createdAt,
  });

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      id: map['id'],
      roomId: map['room_id'],
      sender: map['sender'],
      content: map['content'],
      type: map['type'] ?? 'text',
      fileUrl: map['file_url'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}
