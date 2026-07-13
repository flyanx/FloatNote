/// 记事本主页面 - 笔记本选择 + 笔记列表

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/notebook_provider.dart';
import '../../models/notebook.dart';
import '../../utils/color_constants.dart';
import '../../utils/text_utils.dart';
import 'note_editor_screen.dart';

class NotebookScreen extends ConsumerWidget {
  const NotebookScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notebookProvider);
    final notifier = ref.read(notebookProvider.notifier);
    final activeBook = state.activeBook;

    return Scaffold(
      appBar: AppBar(
        title: _buildBookSelector(context, state, notifier),
        actions: [
          // 管理笔记本
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 20),
            onSelected: (val) {
              switch (val) {
                case 'add':
                  notifier.addNotebook();
                  break;
                case 'rename':
                  _showRenameDialog(context, notifier, activeBook!);
                  break;
                case 'color':
                  _showColorPicker(context, notifier, activeBook!);
                  break;
                case 'lock':
                  notifier.toggleLock(activeBook!.id);
                  break;
                case 'delete':
                  _confirmDelete(context, notifier, activeBook!, state.notebooks.length);
                  break;
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'add', child: ListTile(
                leading: Icon(Icons.add), title: Text('新建笔记本'), dense: true,
              )),
              if (activeBook != null) ...[
                const PopupMenuItem(value: 'rename', child: ListTile(
                  leading: Icon(Icons.edit), title: Text('重命名'), dense: true,
                )),
                const PopupMenuItem(value: 'color', child: ListTile(
                  leading: Icon(Icons.palette_outlined), title: Text('颜色'), dense: true,
                )),
                PopupMenuItem(value: 'lock', child: ListTile(
                  leading: Icon(activeBook.locked ? Icons.lock_open : Icons.lock),
                  title: Text(activeBook.locked ? '解锁' : '锁定'), dense: true,
                )),
                if (state.notebooks.length > 1 && !activeBook.locked)
                  const PopupMenuItem(value: 'delete', child: ListTile(
                    leading: Icon(Icons.delete_outline, color: Colors.red),
                    title: Text('删除', style: TextStyle(color: Colors.red)), dense: true,
                  )),
              ],
            ],
          ),
        ],
      ),
      body: _buildNoteList(context, ref, activeBook),
      floatingActionButton: activeBook != null
          ? FloatingActionButton(
              onPressed: () {
                notifier.addNote(activeBook.id);
                // 导航到编辑器编辑新笔记
                final newNote = ref.read(notebookProvider).activeBook?.notes.first;
                if (newNote != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => NoteEditorScreen(
                        bookId: activeBook.id,
                        noteId: newNote.id,
                      ),
                    ),
                  );
                }
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildBookSelector(BuildContext context, NotebookState state, NotebookNotifier notifier) {
    return PopupMenuButton<int>(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (state.activeBook?.color != null)
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: Color(int.parse(state.activeBook!.color!.replaceFirst('#', '0xFF'))),
                shape: BoxShape.circle,
              ),
            ).padRight(8),
          Text(
            state.activeBook?.name ?? '记事本',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.arrow_drop_down, size: 20),
        ],
      ),
      onSelected: (id) => notifier.switchBook(id),
      itemBuilder: (_) => [
        for (final book in state.notebooks)
          PopupMenuItem<int>(
            value: book.id,
            child: Row(
              children: [
                if (book.color != null)
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: Color(int.parse(book.color!.replaceFirst('#', '0xFF'))),
                      shape: BoxShape.circle,
                    ),
                  ),
                if (book.locked) const Icon(Icons.lock, size: 12).padRight(4),
                Expanded(child: Text(book.name)),
                if (book.id == state.activeBookId)
                  const Icon(Icons.check, size: 16, color: Colors.green),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildNoteList(BuildContext context, WidgetRef ref, Notebook? book) {
    if (book == null) {
      return const Center(child: Text('无笔记本'));
    }

    final notes = book.notes;
    if (notes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.note_add_outlined, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text('暂无笔记', style: TextStyle(color: Colors.grey.shade500)),
            const SizedBox(height: 4),
            Text('点击右下角 + 创建', style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: notes.length,
      itemBuilder: (context, idx) {
        final note = notes[idx];
        return _NoteListTile(
          note: note,
          bookId: book.id,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => NoteEditorScreen(bookId: book.id, noteId: note.id),
            ),
          ),
        );
      },
    );
  }

  void _showRenameDialog(BuildContext context, NotebookNotifier notifier, Notebook book) {
    final controller = TextEditingController(text: book.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('重命名笔记本'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 50,
          decoration: const InputDecoration(hintText: '输入名称'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                notifier.renameNotebook(book.id, name);
              }
              Navigator.pop(ctx);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _showColorPicker(BuildContext context, NotebookNotifier notifier, Notebook book) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('标签颜色', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                // 无颜色
                _colorChip(null, book.color, (c) {
                  notifier.setBookColor(book.id, c);
                  Navigator.pop(ctx);
                }),
                for (final c in ColorConstants.tabColors.skip(1))
                  _colorChip(c, book.color, (c) {
                    notifier.setBookColor(book.id, c);
                    Navigator.pop(ctx);
                  }),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _colorChip(String? color, String? selected, void Function(String?) onTap) {
    final isSelected = color == selected;
    return GestureDetector(
      onTap: () => onTap(color),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color == null ? Colors.grey.shade200 : Color(int.parse(color.replaceFirst('#', '0xFF'))),
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.black : Colors.transparent,
            width: 2,
          ),
        ),
        child: isSelected ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
      ),
    );
  }

  void _confirmDelete(BuildContext context, NotebookNotifier notifier, Notebook book, int totalBooks) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除笔记本'),
        content: Text('确定要删除「${book.name}」吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              notifier.deleteNotebook(book.id);
              Navigator.pop(ctx);
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}

/// 笔记列表项
class _NoteListTile extends ConsumerWidget {
  final Note note;
  final int bookId;
  final VoidCallback onTap;

  const _NoteListTile({required this.note, required this.bookId, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(notebookProvider.notifier);
    final color = note.pinned
        ? Theme.of(context).colorScheme.primary
        : note.color != null
            ? Color(int.parse(note.color!.replaceFirst('#', '0xFF')))
            : Colors.transparent;

    return Dismissible(
      key: ValueKey(note.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red.withOpacity(0.1),
        child: const Icon(Icons.delete_outline, color: Colors.red),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('删除笔记'),
            content: Text('确定要删除「${note.title.isEmpty ? "无标题" : note.title}」吗？'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('删除'),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) => notifier.deleteNote(bookId, note.id),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: InkWell(
          onTap: onTap,
          onLongPress: () => _showOptions(context, ref),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // 左侧颜色条
                Container(
                  width: 3,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                // 内容
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (note.pinned)
                            Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: Icon(Icons.push_pin, size: 12, color: Theme.of(context).colorScheme.primary),
                            ),
                          Expanded(
                            child: Text(
                              note.title.isEmpty ? '无标题' : note.title,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                color: note.title.isEmpty ? Colors.grey : null,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        TextUtils.getPreview(note.content, maxLen: 40),
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showOptions(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(notebookProvider.notifier);
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(note.pinned ? Icons.push_pin : Icons.push_pin_outlined),
              title: Text(note.pinned ? '取消置顶' : '置顶笔记'),
              onTap: () {
                notifier.pinNote(bookId, note.id);
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.palette_outlined),
              title: const Text('设置颜色'),
              onTap: () {
                Navigator.pop(ctx);
                _showColorPicker(context, ref);
              },
            ),
            ListTile(
              leading: const Icon(Icons.arrow_upward),
              title: const Text('上移'),
              onTap: () {
                notifier.moveNoteUp(bookId, note.id);
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.arrow_downward),
              title: const Text('下移'),
              onTap: () {
                notifier.moveNoteDown(bookId, note.id);
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('删除', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(ctx);
                notifier.deleteNote(bookId, note.id);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showColorPicker(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(notebookProvider.notifier);
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('笔记颜色', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                GestureDetector(
                  onTap: () {
                    notifier.setNoteColor(bookId, note.id, null);
                    Navigator.pop(ctx);
                  },
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      shape: BoxShape.circle,
                    ),
                    child: note.color == null ? const Icon(Icons.check, size: 16) : null,
                  ),
                ),
                for (final c in ColorConstants.noteColors)
                  GestureDetector(
                    onTap: () {
                      notifier.setNoteColor(bookId, note.id, c);
                      Navigator.pop(ctx);
                    },
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Color(int.parse(c.replaceFirst('#', '0xFF'))),
                        shape: BoxShape.circle,
                      ),
                      child: note.color == c
                          ? const Icon(Icons.check, size: 16, color: Colors.white)
                          : null,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// Extension for padding
extension _PadExtension on Widget {
  Widget padRight(double padding) => Padding(
        padding: EdgeInsets.only(right: padding),
        child: this,
      );
}
