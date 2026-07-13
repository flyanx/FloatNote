/// 待办列表 + 待办项 + 子任务数据模型
/// 与 PC 版 sn-todolists JSON 格式完全兼容

class Subtask {
  final String text;
  final bool done;

  const Subtask({
    this.text = '',
    this.done = false,
  });

  factory Subtask.fromJson(Map<String, dynamic> json) {
    return Subtask(
      text: json['text'] as String? ?? '',
      done: json['done'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {'text': text, 'done': done};

  Subtask copyWith({String? text, bool? done}) {
    return Subtask(text: text ?? this.text, done: done ?? this.done);
  }
}

class Todo {
  final int id;
  final String text;
  final bool done;
  final String priority; // 'high' | 'mid' | 'low'
  final String? dueDate; // 'YYYY-MM-DD' 或 null
  final int createdAt;
  final List<Subtask>? subtasks;
  final String? note; // 可选备注，最长500字

  const Todo({
    required this.id,
    this.text = '',
    this.done = false,
    this.priority = 'mid',
    this.dueDate,
    required this.createdAt,
    this.subtasks,
    this.note,
  });

  factory Todo.fromJson(Map<String, dynamic> json) {
    final subtasksList = (json['subtasks'] as List<dynamic>?)
        ?.map((e) => Subtask.fromJson(e as Map<String, dynamic>))
        .toList();
    return Todo(
      id: json['id'] as int? ?? 0,
      text: json['text'] as String? ?? '',
      done: json['done'] as bool? ?? false,
      priority: json['priority'] as String? ?? 'mid',
      dueDate: json['dueDate'] as String?,
      createdAt: json['createdAt'] as int? ?? 0,
      subtasks: subtasksList,
      note: json['note'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'id': id,
      'text': text,
      'done': done,
      'priority': priority,
      'createdAt': createdAt,
    };
    if (dueDate != null) map['dueDate'] = dueDate;
    if (subtasks != null) {
      map['subtasks'] = subtasks!.map((s) => s.toJson()).toList();
    }
    if (note != null) map['note'] = note;
    return map;
  }

  Todo copyWith({
    int? id,
    String? text,
    bool? done,
    String? priority,
    String? dueDate,
    int? createdAt,
    List<Subtask>? subtasks,
    String? note,
    bool clearDueDate = false,
    bool clearSubtasks = false,
    bool clearNote = false,
  }) {
    return Todo(
      id: id ?? this.id,
      text: text ?? this.text,
      done: done ?? this.done,
      priority: priority ?? this.priority,
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      createdAt: createdAt ?? this.createdAt,
      subtasks: clearSubtasks ? null : (subtasks ?? this.subtasks),
      note: clearNote ? null : (note ?? this.note),
    );
  }
}

class TodoList {
  final int id;
  final String name;
  final String? color;
  final bool locked;
  final List<Todo> todos;

  const TodoList({
    required this.id,
    this.name = '待办页',
    this.color,
    this.locked = false,
    this.todos = const [],
  });

  factory TodoList.fromJson(Map<String, dynamic> json) {
    final todosList = (json['todos'] as List<dynamic>?)
            ?.map((e) => Todo.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    return TodoList(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '待办页',
      color: json['color'] as String?,
      locked: json['locked'] as bool? ?? false,
      todos: todosList,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'id': id,
      'name': name,
      'locked': locked,
      'todos': todos.map((t) => t.toJson()).toList(),
    };
    if (color != null) map['color'] = color;
    return map;
  }

  TodoList copyWith({
    int? id,
    String? name,
    String? color,
    bool? locked,
    List<Todo>? todos,
    bool clearColor = false,
  }) {
    return TodoList(
      id: id ?? this.id,
      name: name ?? this.name,
      color: clearColor ? null : (color ?? this.color),
      locked: locked ?? this.locked,
      todos: todos ?? this.todos,
    );
  }
}
