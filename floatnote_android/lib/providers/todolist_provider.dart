/// 待办列表 Provider

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/todolist.dart';
import '../models/trash_item.dart';
import '../services/id_generator.dart';
import '../services/storage_service.dart';
import 'notebook_provider.dart';
import 'trash_provider.dart';

const String _todolistsKey = 'sn-todolists';
const String _activeTodoListKey = 'sn-active-todolist';

/// 筛选状态
enum StatusFilter { all, pending, done }
enum PriorityFilter { all, high, mid, low }

class TodoListState {
  final List<TodoList> todoLists;
  final int activeListId;
  final StatusFilter statusFilter;
  final PriorityFilter priorityFilter;

  const TodoListState({
    this.todoLists = const [],
    this.activeListId = 0,
    this.statusFilter = StatusFilter.all,
    this.priorityFilter = PriorityFilter.all,
  });

  TodoList? get activeList {
    if (todoLists.isEmpty) return null;
    return todoLists.where((l) => l.id == activeListId).firstOrNull ??
        todoLists.first;
  }

  /// 筛选后的待办列表
  List<Todo> get filteredTodos {
    final list = activeList;
    if (list == null) return [];
    var result = list.todos.toList();

    if (statusFilter == StatusFilter.pending) {
      result = result.where((t) => !t.done).toList();
    } else if (statusFilter == StatusFilter.done) {
      result = result.where((t) => t.done).toList();
    }

    if (priorityFilter != PriorityFilter.all) {
      final pf = priorityFilter.name;
      result = result.where((t) => t.priority == pf).toList();
    }

    return result;
  }

  int get doneCount => activeList?.todos.where((t) => t.done).length ?? 0;
  int get totalCount => activeList?.todos.length ?? 0;
  int get pendingCount => activeList?.todos.where((t) => !t.done).length ?? 0;
  int get progress => totalCount > 0 ? (doneCount * 100 / totalCount).round() : 0;

  TodoListState copyWith({
    List<TodoList>? todoLists,
    int? activeListId,
    StatusFilter? statusFilter,
    PriorityFilter? priorityFilter,
  }) {
    return TodoListState(
      todoLists: todoLists ?? this.todoLists,
      activeListId: activeListId ?? this.activeListId,
      statusFilter: statusFilter ?? this.statusFilter,
      priorityFilter: priorityFilter ?? this.priorityFilter,
    );
  }
}

class TodoListNotifier extends StateNotifier<TodoListState> {
  final StorageService _storage;
  final Ref _ref;

  TodoListNotifier(this._storage, this._ref)
      : super(const TodoListState()) {
    _load();
  }

  void _load() {
    final list = _storage.readJSON<List>(_todolistsKey, []);
    final todoLists =
        list.map((e) => TodoList.fromJson(e as Map<String, dynamic>)).toList();

    if (todoLists.isEmpty) {
      final defaultList = TodoList(id: IdGenerator.generate(), name: '待办页 1');
      todoLists.add(defaultList);
      _save(todoLists);
    }

    final savedActiveId = _storage.getInt(_activeTodoListKey);
    final activeId = savedActiveId ?? todoLists.first.id;

    state = TodoListState(todoLists: todoLists, activeListId: activeId);
  }

  void _save([List<TodoList>? lists]) {
    final l = lists ?? state.todoLists;
    _storage.writeJSON(_todolistsKey, l.map((t) => t.toJson()).toList());
  }

  // ===== 待办列表管理 =====

  void addTodoList() {
    final list = TodoList(
      id: IdGenerator.generate(),
      name: '待办页 ${state.todoLists.length + 1}',
    );
    final updated = [...state.todoLists, list];
    _save(updated);
    state = state.copyWith(todoLists: updated, activeListId: list.id);
    _storage.setInt(_activeTodoListKey, list.id);
  }

  void deleteTodoList(int id) {
    final list = state.todoLists.where((l) => l.id == id).firstOrNull;
    if (list == null || list.locked || state.todoLists.length <= 1) return;

    _ref.read(trashProvider.notifier).addTabTrash(TrashItem(
          id: list.id,
          name: list.name,
          type: 'list',
          deletedAt: DateTime.now().millisecondsSinceEpoch,
          data: list.toJson(),
        ));

    final updated = state.todoLists.where((l) => l.id != id).toList();
    _save(updated);

    var newActiveId = state.activeListId;
    if (newActiveId == id) {
      newActiveId = updated.first.id;
      _storage.setInt(_activeTodoListKey, newActiveId);
    }
    state = TodoListState(todoLists: updated, activeListId: newActiveId);
  }

  void renameTodoList(int id, String newName) {
    final updated = state.todoLists.map((l) {
      if (l.id == id) return l.copyWith(name: newName);
      return l;
    }).toList();
    _save(updated);
    state = state.copyWith(todoLists: updated);
  }

  void switchList(int id) {
    state = state.copyWith(activeListId: id);
    _storage.setInt(_activeTodoListKey, id);
  }

  void setListColor(int id, String? color) {
    final updated = state.todoLists.map((l) {
      if (l.id == id) return l.copyWith(color: color, clearColor: color == null);
      return l;
    }).toList();
    _save(updated);
    state = state.copyWith(todoLists: updated);
  }

  void toggleLock(int id) {
    final updated = state.todoLists.map((l) {
      if (l.id == id) return l.copyWith(locked: !l.locked);
      return l;
    }).toList();
    _save(updated);
    state = state.copyWith(todoLists: updated);
  }

  // ===== 待办项管理 =====

  void addTodo(String text, {String priority = 'mid', String? dueDate}) {
    final listId = state.activeListId;
    final todo = Todo(
      id: IdGenerator.generate(),
      text: text,
      priority: priority,
      dueDate: dueDate,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );

    final updated = state.todoLists.map((l) {
      if (l.id == listId) {
        return l.copyWith(todos: [todo, ...l.todos]);
      }
      return l;
    }).toList();
    _save(updated);
    state = state.copyWith(todoLists: updated);
  }

  void toggleTodo(int todoId) {
    final listId = state.activeListId;
    final updated = state.todoLists.map((l) {
      if (l.id == listId) {
        final todos = l.todos.map((t) {
          if (t.id == todoId) return t.copyWith(done: !t.done);
          return t;
        }).toList();
        return l.copyWith(todos: todos);
      }
      return l;
    }).toList();
    _save(updated);
    state = state.copyWith(todoLists: updated);
  }

  void updateTodo(int todoId, {String? text, String? priority, String? dueDate, bool clearDueDate = false}) {
    final listId = state.activeListId;
    final updated = state.todoLists.map((l) {
      if (l.id == listId) {
        final todos = l.todos.map((t) {
          if (t.id == todoId) {
            return t.copyWith(text: text, priority: priority, dueDate: dueDate, clearDueDate: clearDueDate);
          }
          return t;
        }).toList();
        return l.copyWith(todos: todos);
      }
      return l;
    }).toList();
    _save(updated);
    state = state.copyWith(todoLists: updated);
  }

  void deleteTodo(int todoId) {
    final listId = state.activeListId;
    final list = state.todoLists.where((l) => l.id == listId).firstOrNull;
    final todo = list?.todos.where((t) => t.id == todoId).firstOrNull;
    if (list == null || todo == null) return;

    _ref.read(trashProvider.notifier).addItemTrash(TrashItem(
          id: todo.id,
          name: todo.text,
          type: 'todo',
          deletedAt: DateTime.now().millisecondsSinceEpoch,
          data: todo.toJson(),
          isItem: true,
        ));

    final updated = state.todoLists.map((l) {
      if (l.id == listId) {
        return l.copyWith(todos: l.todos.where((t) => t.id != todoId).toList());
      }
      return l;
    }).toList();
    _save(updated);
    state = state.copyWith(todoLists: updated);
  }

  void clearDone() {
    final listId = state.activeListId;
    final updated = state.todoLists.map((l) {
      if (l.id == listId) {
        return l.copyWith(todos: l.todos.where((t) => !t.done).toList());
      }
      return l;
    }).toList();
    _save(updated);
    state = state.copyWith(todoLists: updated);
  }

  // ===== 子任务 =====

  void addSubtask(int todoId, String text) {
    final listId = state.activeListId;
    final updated = state.todoLists.map((l) {
      if (l.id == listId) {
        final todos = l.todos.map((t) {
          if (t.id == todoId) {
            final subs = List<Subtask>.from(t.subtasks ?? []);
            subs.add(Subtask(text: text));
            return t.copyWith(subtasks: subs, done: false);
          }
          return t;
        }).toList();
        return l.copyWith(todos: todos);
      }
      return l;
    }).toList();
    _save(updated);
    state = state.copyWith(todoLists: updated);
  }

  void toggleSubtask(int todoId, int subIdx) {
    final listId = state.activeListId;
    final updated = state.todoLists.map((l) {
      if (l.id == listId) {
        final todos = l.todos.map((t) {
          if (t.id == todoId && t.subtasks != null) {
            final subs = List<Subtask>.from(t.subtasks!);
            if (subIdx < subs.length) {
              subs[subIdx] = subs[subIdx].copyWith(done: !subs[subIdx].done);
            }
            return t.copyWith(subtasks: subs);
          }
          return t;
        }).toList();
        return l.copyWith(todos: todos);
      }
      return l;
    }).toList();
    _save(updated);
    state = state.copyWith(todoLists: updated);
  }

  // ===== 筛选 =====

  void setStatusFilter(StatusFilter f) {
    state = state.copyWith(statusFilter: f);
  }

  void setPriorityFilter(PriorityFilter f) {
    state = state.copyWith(priorityFilter: f);
  }

  // ===== 恢复 =====

  void restoreTodoList(TodoList list) {
    final newId = IdGenerator.generate();
    final restored = list.copyWith(id: newId, todos: []);
    final updated = [...state.todoLists, restored];
    _save(updated);
    state = state.copyWith(todoLists: updated, activeListId: newId);
    _storage.setInt(_activeTodoListKey, newId);
  }

  void restoreTodo(Todo todo, {int? listId}) {
    final targetId = listId ?? state.activeListId;
    final newTodo = todo.copyWith(id: IdGenerator.generate());
    final updated = state.todoLists.map((l) {
      if (l.id == targetId) {
        return l.copyWith(todos: [newTodo, ...l.todos]);
      }
      return l;
    }).toList();
    _save(updated);
    state = state.copyWith(todoLists: updated);
  }

  void reload() => _load();
}

// ===== Provider 定义 =====

final todolistProvider =
    StateNotifierProvider<TodoListNotifier, TodoListState>((ref) {
  return TodoListNotifier(ref.watch(storageServiceProvider), ref);
});
