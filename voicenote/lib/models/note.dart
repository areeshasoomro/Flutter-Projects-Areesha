class Note {
  String title;
  String content;
  DateTime timestamp;

  Note({
    required this.title,
    required this.content,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory Note.fromMap(Map<dynamic, dynamic> map) {
    return Note(
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      timestamp: DateTime.parse(map['timestamp']),
    );
  }
}
