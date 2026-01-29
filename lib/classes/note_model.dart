class Note {
  final int id;
  final int? parentId;
  final String title;
  final String body;
  final DateTime createdAt;
  final DateTime updatedAt;

  Note({
    required this.id,
    this.parentId,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'],
      parentId: map['parent_id'],
      title: map['title'],
      body: map['body'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  factory Note.fromSql(Map<String, dynamic> map) {
    return Note(
      id: map['id'],
      parentId: map['parent_id'],
      title: map['title'],
      body: map['body'],
      createdAt: map['created_at'],
      updatedAt: map['updated_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'parent_id': parentId,
      'title': title,
      'body': body,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
