/// 笔记本 + 笔记数据模型
/// 与 PC 版 sn-notebooks JSON 格式完全兼容

class Note {
  final int id;
  final String title;
  final String content;
  final String? richContent; // PC 版 _richContent 字段，保留不破坏
  final bool pinned;
  final String? color;

  const Note({
    required this.id,
    this.title = '',
    this.content = '',
    this.richContent,
    this.pinned = false,
    this.color,
  });

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      richContent: json['_richContent'] as String?,
      pinned: json['pinned'] as bool? ?? false,
      color: json['color'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'id': id,
      'title': title,
      'content': content,
      'pinned': pinned,
    };
    if (richContent != null) map['_richContent'] = richContent;
    if (color != null) map['color'] = color;
    return map;
  }

  Note copyWith({
    int? id,
    String? title,
    String? content,
    String? richContent,
    bool? pinned,
    String? color,
    bool clearRichContent = false,
    bool clearColor = false,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      richContent: clearRichContent ? null : (richContent ?? this.richContent),
      pinned: pinned ?? this.pinned,
      color: clearColor ? null : (color ?? this.color),
    );
  }
}

class Notebook {
  final int id;
  final String name;
  final String? color;
  final bool locked;
  final List<Note> notes;

  const Notebook({
    required this.id,
    this.name = '记事本',
    this.color,
    this.locked = false,
    this.notes = const [],
  });

  factory Notebook.fromJson(Map<String, dynamic> json) {
    final notesList = (json['notes'] as List<dynamic>?)
            ?.map((e) => Note.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    return Notebook(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '记事本',
      color: json['color'] as String?,
      locked: json['locked'] as bool? ?? false,
      notes: notesList,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'id': id,
      'name': name,
      'locked': locked,
      'notes': notes.map((n) => n.toJson()).toList(),
    };
    if (color != null) map['color'] = color;
    return map;
  }

  Notebook copyWith({
    int? id,
    String? name,
    String? color,
    bool? locked,
    List<Note>? notes,
    bool clearColor = false,
  }) {
    return Notebook(
      id: id ?? this.id,
      name: name ?? this.name,
      color: clearColor ? null : (color ?? this.color),
      locked: locked ?? this.locked,
      notes: notes ?? this.notes,
    );
  }
}
