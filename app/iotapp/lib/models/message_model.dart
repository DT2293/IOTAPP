class Message {
  final String title;
  final String content;
  final DateTime timestamp;
  bool isRead;

  Message({
    required this.title,
    required this.content,
    required this.timestamp,
    this.isRead = false,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'content': content,
        'timestamp': timestamp.toIso8601String(),
        'isRead': isRead,
      };

  factory Message.fromJson(Map<String, dynamic> json) => Message(
        title: json['title'],
        content: json['content'],
        timestamp: DateTime.parse(json['timestamp']),
        isRead: json['isRead'],
      );
}
