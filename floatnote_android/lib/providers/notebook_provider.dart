/// 笔记本 Provider
/// 管理笔记本列表和当前激活笔记本的 CRUD 操作

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notebook.dart';
import '../models/trash_item.dart';
import '../services/id_generator.dart';
import '../services/storage_service.dart';
import '../services/trash_service.dart';
import 'trash_provider.dart';

const String _notebooksKey = 'sn-notebooks';
const String _activeBookKey = 'sn-active-book';

class NotebookState {
  final List<Notebook> notebooks;
  final int activeBookId;

  const NotebookState({this.notebooks = const [], this.activeBookId = 0});

  Notebook? get activeBook {
    if (notebooks.isEmpty) return null;
    return notebooks.where((b) => b.id == activeBookId).firstOrNull ??
        notebooks.first;
  }

  NotebookState copyWith({List<Notebook>? notebooks, int? activeBookId}) {
    return NotebookState(
      notebooks: notebooks ?? this.notebooks,
      activeBookId: activeBookId ?? this.activeBookId,
    );
  }
}

class NotebookNotifier extends StateNotifier<NotebookState> {
  final StorageService _storage;
  final Ref _ref;

  NotebookNotifier(this._storage, this._ref) : super(const NotebookState()) {
    _load();
  }

  void _load() {
    final list = _storage.readJSON<List>(_notebooksKey, []);
    final notebooks =
        list.map((e) => Notebook.fromJson(e as Map<String, dynamic>)).toList();

    // 如果没有笔记本，创建默认
    if (notebooks.isEmpty) {
      final defaultBook = Notebook(id: IdGenerator.generate(), name: '记事本 1');
      notebooks.add(defaultBook);
      _save(notebooks);
    }

    final savedActiveId = _storage.getInt(_activeBookKey);
    final activeId = savedActiveId ?? notebooks.first.id;

    state = NotebookState(notebooks: notebooks, activeBookId: activeId);
  }

  void _save([List<Notebook>? notebooks]) {
    final list = notebooks ?? state.notebooks;
    _storage.writeJSON(_notebooksKey, list.map((b) => b.toJson()).toList());
  }

  // ===== 笔记本管理 =====

  void addNotebook() {
    final book = Notebook(
      id: IdGenerator.generate(),
      name: '记事本 ${state.notebooks.length + 1}',
    );
    final updated = [...state.notebooks, book];
    _save(updated);
    state = state.copyWith(notebooks: updated, activeBookId: book.id);
    _storage.setInt(_activeBookKey, book.id);
  }

  void deleteNotebook(int id) {
    final book = state.notebooks.where((b) => b.id == id).firstOrNull;
    if (book == null || book.locked || state.notebooks.length <= 1) return;

    // 移入回收站
    _ref.read(trashProvider.notifier).addTabTrash(TrashItem(
          id: book.id,
          name: book.name,
          type: 'book',
          deletedAt: DateTime.now().millisecondsSinceEpoch,
          data: book.toJson(),
        ));

    final updated = state.notebooks.where((b) => b.id != id).toList();
    _save(updated);

    var newActiveId = state.activeBookId;
    if (newActiveId == id) {
      newActiveId = updated.first.id;
      _storage.setInt(_activeBookKey, newActiveId);
    }
    state = NotebookState(notebooks: updated, activeBookId: newActiveId);
  }

  void renameNotebook(int id, String newName) {
    final updated = state.notebooks.map((b) {
      if (b.id == id) return b.copyWith(name: newName);
      return b;
    }).toList();
    _save(updated);
    state = state.copyWith(notebooks: updated);
  }

  void switchBook(int id) {
    state = state.copyWith(activeBookId: id);
    _storage.setInt(_activeBookKey, id);
  }

  void setBookColor(int id, String? color) {
    final updated = state.notebooks.map((b) {
      if (b.id == id) return b.copyWith(color: color, clearColor: color == null);
      return b;
    }).toList();
    _save(updated);
    state = state.copyWith(notebooks: updated);
  }

  void toggleLock(int id) {
    final updated = state.notebooks.map((b) {
      if (b.id == id) return b.copyWith(locked: !b.locked);
      return b;
    }).toList();
    _save(updated);
    state = state.copyWith(notebooks: updated);
  }

  // ===== 笔记管理 =====

  void addNote(int bookId) {
    final note = Note(id: IdGenerator.generate(), title: '', content: '');
    final updated = state.notebooks.map((b) {
      if (b.id == bookId) {
        return b.copyWith(notes: [note, ...b.notes]);
      }
      return b;
    }).toList();
    _save(updated);
    state = state.copyWith(notebooks: updated);
  }

  void updateNote(int bookId, int noteId, {String? title, String? content}) {
    final updated = state.notebooks.map((b) {
      if (b.id == bookId) {
        final notes = b.notes.map((n) {
          if (n.id == noteId) {
            return n.copyWith(title: title, content: content);
          }
          return n;
        }).toList();
        return b.copyWith(notes: notes);
      }
      return b;
    }).toList();
    _save(updated);
    state = state.copyWith(notebooks: updated);
  }

  void deleteNote(int bookId, int noteId) {
    final book = state.notebooks.where((b) => b.id == bookId).firstOrNull;
    final note = book?.notes.where((n) => n.id == noteId).firstOrNull;
    if (book == null || note == null) return;

    // 移入项目回收站
    _ref.read(trashProvider.notifier).addItemTrash(TrashItem(
          id: note.id,
          name: note.title.isEmpty ? '无标题' : note.title,
          type: 'note',
          deletedAt: DateTime.now().millisecondsSinceEpoch,
          data: note.toJson(),
          isItem: true,
        ));

    final updated = state.notebooks.map((b) {
      if (b.id == bookId) {
        return b.copyWith(notes: b.notes.where((n) => n.id != noteId).toList());
      }
      return b;
    }).toList();
    _save(updated);
    state = state.copyWith(notebooks: updated);
  }

  void pinNote(int bookId, int noteId) {
    final updated = state.notebooks.map((b) {
      if (b.id == bookId) {
        final notes = b.notes.map((n) {
          if (n.id == noteId) return n.copyWith(pinned: !n.pinned);
          return n;
        }).toList();
        return b.copyWith(notes: notes);
      }
      return b;
    }).toList();
    _save(updated);
    state = state.copyWith(notebooks: updated);
  }

  void setNoteColor(int bookId, int noteId, String? color) {
    final updated = state.notebooks.map((b) {
      if (b.id == bookId) {
        final notes = b.notes.map((n) {
          if (n.id == noteId) return n.copyWith(color: color, clearColor: color == null);
          return n;
        }).toList();
        return b.copyWith(notes: notes);
      }
      return b;
    }).toList();
    _save(updated);
    state = state.copyWith(notebooks: updated);
  }

  void moveNoteUp(int bookId, int noteId) {
    final updated = state.notebooks.map((b) {
      if (b.id == bookId) {
        final notes = List<Note>.from(b.notes);
        final idx = notes.indexWhere((n) => n.id == noteId);
        if (idx > 0) {
          final temp = notes[idx];
          notes[idx] = notes[idx - 1];
          notes[idx - 1] = temp;
        }
        return b.copyWith(notes: notes);
      }
      return b;
    }).toList();
    _save(updated);
    state = state.copyWith(notebooks: updated);
  }

  void moveNoteDown(int bookId, int noteId) {
    final updated = state.notebooks.map((b) {
      if (b.id == bookId) {
        final notes = List<Note>.from(b.notes);
        final idx = notes.indexWhere((n) => n.id == noteId);
        if (idx >= 0 && idx < notes.length - 1) {
          final temp = notes[idx];
          notes[idx] = notes[idx + 1];
          notes[idx + 1] = temp;
        }
        return b.copyWith(notes: notes);
      }
      return b;
    }).toList();
    _save(updated);
    state = state.copyWith(notebooks: updated);
  }

  /// 恢复笔记本到回收站
  void restoreNotebook(Notebook book) {
    final newId = IdGenerator.generate();
    final restored = book.copyWith(id: newId, notes: []);
    final updated = [...state.notebooks, restored];
    _save(updated);
    state = state.copyWith(notebooks: updated, activeBookId: newId);
    _storage.setInt(_activeBookKey, newId);
  }

  /// 恢复笔记到指定笔记本
  void restoreNote(Note note, {int? bookId}) {
    final targetId = bookId ?? state.activeBookId;
    final newNote = note.copyWith(id: IdGenerator.generate());
    final updated = state.notebooks.map((b) {
      if (b.id == targetId) {
        return b.copyWith(notes: [newNote, ...b.notes]);
      }
      return b;
    }).toList();
    _save(updated);
    state = state.copyWith(notebooks: updated);
  }

  /// 外部数据刷新（云同步后调用）
  void reload() => _load();
}

// ===== Provider 定义 =====

final storageServiceProvider = Provider<StorageService>((ref) {
  throw UnimplementedError('Must be overridden in ProviderScope');
});

final trashServiceProvider = Provider<TrashService>((ref) {
  return TrashService(ref.watch(storageServiceProvider));
});

final notebookProvider =
    StateNotifierProvider<NotebookNotifier, NotebookState>((ref) {
  return NotebookNotifier(ref.watch(storageServiceProvider), ref);
});
