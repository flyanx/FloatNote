/// 回收站 Provider

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/trash_item.dart';
import '../models/notebook.dart';
import '../models/todolist.dart';
import '../services/trash_service.dart';
import 'notebook_provider.dart';
import 'todolist_provider.dart';

class TrashState {
  final List<TrashItem> items;

  const TrashState({this.items = const []});

  TrashState copyWith({List<TrashItem>? items}) {
    return TrashState(items: items ?? this.items);
  }
}

class TrashNotifier extends StateNotifier<TrashState> {
  final TrashService _service;
  final Ref _ref;

  TrashNotifier(this._service, this._ref) : super(const TrashState()) {
    _load();
  }

  void _load() {
    state = TrashState(items: _service.readAllTrash());
  }

  void addTabTrash(TrashItem item) {
    _service.addToTrash(item);
    _load();
  }

  void addItemTrash(TrashItem item) {
    _service.addToItemTrash(item);
    _load();
  }

  /// 恢复回收站项
  void restore(TrashItem item) {
    if (item.isItem) {
      // 恢复单条笔记或待办
      final data = item.data;
      if (item.type == 'note') {
        final note = Note.fromJson(data);
        _ref.read(notebookProvider.notifier).restoreNote(note);
      } else if (item.type == 'todo') {
        final todo = Todo.fromJson(data);
        _ref.read(todolistProvider.notifier).restoreTodo(todo);
      }
    } else {
      // 恢复标签页
      if (item.type == 'book') {
        final book = Notebook.fromJson(item.data);
        _ref.read(notebookProvider.notifier).restoreNotebook(book);
      } else if (item.type == 'list') {
        final list = TodoList.fromJson(item.data);
        _ref.read(todolistProvider.notifier).restoreTodoList(list);
      }
    }

    _service.restore(item);
    _load();
  }

  /// 永久删除
  void deletePermanently(TrashItem item) {
    _service.deletePermanently(item);
    _load();
  }

  void reload() => _load();
}

// ===== Provider 定义 =====

final trashProvider =
    StateNotifierProvider<TrashNotifier, TrashState>((ref) {
  return TrashNotifier(ref.watch(trashServiceProvider), ref);
});
