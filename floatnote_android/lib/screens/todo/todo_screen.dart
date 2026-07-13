/// 待办主页面 - 待办列表管理、筛选、进度

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/todolist_provider.dart';
import '../../models/todolist.dart';
import '../../utils/color_constants.dart';
import '../../utils/date_utils.dart';

class TodoScreen extends ConsumerStatefulWidget {
  const TodoScreen({super.key});

  @override
  ConsumerState<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends ConsumerState<TodoScreen> {
  final _inputCtrl = TextEditingController();
  String _newPriority = 'mid';
  String? _newDueDate;
  bool _filterVisible = false;
  int? _expandedTodoId;

  @override
  void dispose() {
    _inputCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(todolistProvider);
    final notifier = ref.read(todolistProvider.notifier);
    final activeList = state.activeList;

    return Scaffold(
      appBar: AppBar(
        title: _buildListSelector(context, state, notifier),
        actions: [
          if (state.doneCount > 0)
            TextButton(
              onPressed: () => _confirmClearDone(context, notifier, state.doneCount),
              child: Text('清除 ${state.doneCount}', style: const TextStyle(fontSize: 13)),
            ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 20),
            onSelected: (val) {
              switch (val) {
                case 'add':
                  notifier.addTodoList();
                  break;
                case 'rename':
                  _showRenameDialog(context, notifier, activeList!);
                  break;
                case 'color':
                  _showListColorPicker(context, notifier, activeList!);
                  break;
                case 'delete':
                  _confirmDeleteList(context, notifier, activeList!, state.todoLists.length);
                  break;
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'add', child: ListTile(
                leading: Icon(Icons.add), title: Text('新建待办页'), dense: true,
              )),
              if (activeList != null) ...[
                const PopupMenuItem(value: 'rename', child: ListTile(
                  leading: Icon(Icons.edit), title: Text('重命名'), dense: true,
                )),
                const PopupMenuItem(value: 'color', child: ListTile(
                  leading: Icon(Icons.palette_outlined), title: Text('颜色'), dense: true,
                )),
                if (state.todoLists.length > 1 && !activeList.locked)
                  const PopupMenuItem(value: 'delete', child: ListTile(
                    leading: Icon(Icons.delete_outline, color: Colors.red),
                    title: Text('删除', style: TextStyle(color: Colors.red)), dense: true,
                  )),
              ],
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // 添加待办栏
          _buildInputBar(context, notifier, activeList),
          // 进度条
          if (state.totalCount > 0) _buildProgressBar(state),
          // 筛选栏
          if (_filterVisible) _buildFilterBar(state, notifier),
          // 待办列表
          Expanded(child: _buildTodoList(context, ref, state, notifier)),
        ],
      ),
      floatingActionButton: _filterVisible
          ? null
          : FloatingActionButton.small(
              onPressed: () => setState(() => _filterVisible = true),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.filter_list, size: 16),
                  if (state.statusFilter != StatusFilter.all ||
                      state.priorityFilter != PriorityFilter.all)
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.only(left: 2),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildListSelector(BuildContext context, TodoListState state, TodoListNotifier notifier) {
    return PopupMenuButton<int>(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (state.activeList?.color != null)
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: Color(int.parse(state.activeList!.color!.replaceFirst('#', '0xFF'))),
                shape: BoxShape.circle,
              ),
            ).padRight(8),
          Text(
            state.activeList?.name ?? '待办页',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.arrow_drop_down, size: 20),
        ],
      ),
      onSelected: (id) => notifier.switchList(id),
      itemBuilder: (_) => [
        for (final list in state.todoLists)
          PopupMenuItem<int>(
            value: list.id,
            child: Row(
              children: [
                if (list.color != null)
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: Color(int.parse(list.color!.replaceFirst('#', '0xFF'))),
                      shape: BoxShape.circle,
                    ),
                  ),
                if (list.locked) const Icon(Icons.lock, size: 12).padRight(4),
                Expanded(child: Text(list.name)),
                if (list.id == state.activeListId)
                  const Icon(Icons.check, size: 16, color: Colors.green),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildInputBar(BuildContext context, TodoListNotifier notifier, TodoList? activeList) {
    if (activeList == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _inputCtrl,
              decoration: const InputDecoration(
                hintText: '添加待办...',
                border: OutlineInputBorder(),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              maxLength: 200,
              onSubmitted: (_) => _addTodo(notifier),
            ),
          ),
          const SizedBox(width: 4),
          // 优先级
          for (final p in ColorConstants.priorities)
            GestureDetector(
              onTap: () => setState(() => _newPriority = p['val']!),
              child: Container(
                width: 20,
                height: 20,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: Color(int.parse(p['color']!.replaceFirst('#', '0xFF'))),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _newPriority == p['val'] ? Colors.black : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
            ),
          // 日期
          IconButton(
            icon: Icon(
              Icons.calendar_today,
              size: 18,
              color: _newDueDate != null ? Theme.of(context).colorScheme.primary : null,
            ),
            onPressed: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime.now().subtract(const Duration(days: 365)),
                lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
              );
              setState(() {
                _newDueDate = date != null ? AppDateUtils.toDateString(date) : null;
              });
            },
          ),
          // 添加按钮
          IconButton(
            icon: const Icon(Icons.add_circle, color: Color(0xFF5b5ef4)),
            onPressed: () => _addTodo(notifier),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(TodoListState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          if (!_filterVisible)
            GestureDetector(
              onTap: () => setState(() => _filterVisible = true),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.filter_list, size: 10),
                    const SizedBox(width: 4),
                    Text('筛选', style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
                    if (state.statusFilter != StatusFilter.all ||
                        state.priorityFilter != PriorityFilter.all)
                      Container(
                        width: 5,
                        height: 5,
                        margin: const EdgeInsets.only(left: 3),
                        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                      ),
                  ],
                ),
              ),
            ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: state.progress / 100.0,
                minHeight: 6,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${state.doneCount}/${state.totalCount}',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(TodoListState state, TodoListNotifier notifier) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 0.5)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // 收起按钮
              IconButton(
                icon: const Icon(Icons.expand_less, size: 18),
                onPressed: () => setState(() => _filterVisible = false),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              ),
              const SizedBox(width: 8),
              // 状态筛选
              for (final f in [
                {'val': StatusFilter.all, 'label': '全部'},
                {'val': StatusFilter.pending, 'label': '待完成'},
                {'val': StatusFilter.done, 'label': '已完成'},
              ])
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: FilterChip(
                    label: Text(f['label'] as String, style: const TextStyle(fontSize: 12)),
                    selected: state.statusFilter == f['val'],
                    onSelected: (_) => notifier.setStatusFilter(f['val'] as StatusFilter),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const SizedBox(width: 36),
              for (final f in [
                {'val': PriorityFilter.all, 'label': '全部', 'color': null},
                {'val': PriorityFilter.high, 'label': '高', 'color': '#e8453c'},
                {'val': PriorityFilter.mid, 'label': '中', 'color': '#f59e0b'},
                {'val': PriorityFilter.low, 'label': '低', 'color': '#22c55e'},
              ])
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: FilterChip(
                    avatar: f['color'] != null
                        ? Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: Color(int.parse((f['color'] as String).replaceFirst('#', '0xFF'))),
                              shape: BoxShape.circle,
                            ),
                          )
                        : null,
                    label: Text(f['label'] as String, style: const TextStyle(fontSize: 12)),
                    selected: state.priorityFilter == f['val'],
                    onSelected: (_) => notifier.setPriorityFilter(f['val'] as PriorityFilter),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTodoList(BuildContext context, WidgetRef ref, TodoListState state, TodoListNotifier notifier) {
    final todos = state.filteredTodos;
    if (todos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              state.totalCount == 0 ? '暂无待办' : '没有匹配项',
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    // 排序：置顶(pinned) > 未完成 > 已完成
    final sorted = List<Todo>.from(todos)
      ..sort((a, b) {
        if (a.done != b.done) return a.done ? 1 : -1;
        final priOrder = {'high': 0, 'mid': 1, 'low': 2};
        return (priOrder[a.priority] ?? 1).compareTo(priOrder[b.priority] ?? 1);
      });

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: sorted.length,
      itemBuilder: (context, idx) {
        final todo = sorted[idx];
        return _TodoItemTile(
          todo: todo,
          listId: state.activeListId,
          isExpanded: _expandedTodoId == todo.id,
          onToggle: () => notifier.toggleTodo(todo.id),
          onExpand: () => setState(() {
            _expandedTodoId = _expandedTodoId == todo.id ? null : todo.id;
          }),
          onAddSubtask: (text) => notifier.addSubtask(todo.id, text),
          onToggleSubtask: (idx) => notifier.toggleSubtask(todo.id, idx),
          onDelete: () => notifier.deleteTodo(todo.id),
          onUpdate: (text) => notifier.updateTodo(todo.id, text: text),
          onSetPriority: (p) => notifier.updateTodo(todo.id, priority: p),
          onSetDueDate: (d) => notifier.updateTodo(todo.id, dueDate: d),
        );
      },
    );
  }

  void _addTodo(TodoListNotifier notifier) {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty) return;
    notifier.addTodo(text, priority: _newPriority, dueDate: _newDueDate);
    _inputCtrl.clear();
    setState(() {
      _newPriority = 'mid';
      _newDueDate = null;
    });
  }

  void _showRenameDialog(BuildContext context, TodoListNotifier notifier, TodoList list) {
    final ctrl = TextEditingController(text: list.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('重命名待办页'),
        content: TextField(controller: ctrl, autofocus: true, maxLength: 50),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            onPressed: () {
              final name = ctrl.text.trim();
              if (name.isNotEmpty) notifier.renameTodoList(list.id, name);
              Navigator.pop(ctx);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _showListColorPicker(BuildContext context, TodoListNotifier notifier, TodoList list) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('标签颜色', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final c in ColorConstants.tabColors)
                  GestureDetector(
                    onTap: () {
                      notifier.setListColor(list.id, c.isEmpty ? null : c);
                      Navigator.pop(ctx);
                    },
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: c.isEmpty ? Colors.grey.shade200 : Color(int.parse(c.replaceFirst('#', '0xFF'))),
                        shape: BoxShape.circle,
                        border: Border.all(color: list.color == (c.isEmpty ? null : c) ? Colors.black : Colors.transparent, width: 2),
                      ),
                      child: list.color == (c.isEmpty ? null : c)
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

  void _confirmClearDone(BuildContext context, TodoListNotifier notifier, int count) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('清除已完成'),
        content: Text('确定清除 $count 个已完成的待办？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              notifier.clearDone();
              Navigator.pop(ctx);
            },
            child: const Text('清除'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteList(BuildContext context, TodoListNotifier notifier, TodoList list, int total) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除待办页'),
        content: Text('确定要删除「${list.name}」吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              notifier.deleteTodoList(list.id);
              Navigator.pop(ctx);
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}

// ===== 待办项 Widget =====

class _TodoItemTile extends StatelessWidget {
  final Todo todo;
  final int listId;
  final bool isExpanded;
  final VoidCallback onToggle;
  final VoidCallback onExpand;
  final void Function(String) onAddSubtask;
  final void Function(int) onToggleSubtask;
  final VoidCallback onDelete;
  final void Function(String) onUpdate;
  final void Function(String) onSetPriority;
  final void Function(String?) onSetDueDate;

  const _TodoItemTile({
    required this.todo,
    required this.listId,
    required this.isExpanded,
    required this.onToggle,
    required this.onExpand,
    required this.onAddSubtask,
    required this.onToggleSubtask,
    required this.onDelete,
    required this.onUpdate,
    required this.onSetPriority,
    required this.onSetDueDate,
  });

  @override
  Widget build(BuildContext context) {
    final priColor = _priorityColor(todo.priority);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Column(
        children: [
          // 主行
          InkWell(
            onTap: onExpand,
            onLongPress: () => _showOptions(context),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  // Checkbox
                  GestureDetector(
                    onTap: onToggle,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: todo.done ? Colors.green : Colors.transparent,
                        border: Border.all(
                          color: todo.done ? Colors.green : Colors.grey.shade400,
                          width: 2,
                        ),
                      ),
                      child: todo.done
                          ? const Icon(Icons.check, size: 14, color: Colors.white)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  // 文本
                  Expanded(
                    child: Text(
                      todo.text,
                      style: TextStyle(
                        decoration: todo.done ? TextDecoration.lineThrough : null,
                        color: todo.done ? Colors.grey : null,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  // 元数据
                  if (!todo.done) ...[
                    if (todo.dueDate != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        margin: const EdgeInsets.only(right: 6),
                        decoration: BoxDecoration(
                          color: AppDateUtils.isOverdue(todo.dueDate) ? Colors.red.withOpacity(0.1) : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          AppDateUtils.formatDueDate(todo.dueDate),
                          style: TextStyle(
                            fontSize: 11,
                            color: AppDateUtils.isOverdue(todo.dueDate) ? Colors.red : Colors.grey.shade600,
                          ),
                        ),
                      ),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(color: priColor, shape: BoxShape.circle),
                    ),
                  ],
                  if (todo.subtasks != null && todo.subtasks!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Text(
                        '${todo.subtasks!.where((s) => s.done).length}/${todo.subtasks!.length}',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                      ),
                    ),
                  // 展开指示器
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 18,
                    color: Colors.grey.shade400,
                  ),
                ],
              ),
            ),
          ),
          // 展开区域：子任务
          if (isExpanded && todo.subtasks != null)
            ...todo.subtasks!.asMap().entries.map((entry) {
              final i = entry.key;
              final sub = entry.value;
              return Padding(
                padding: const EdgeInsets.only(left: 48, right: 12, bottom: 4),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => onToggleSubtask(i),
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: sub.done ? Colors.green : Colors.transparent,
                          border: Border.all(color: sub.done ? Colors.green : Colors.grey.shade400, width: 1.5),
                        ),
                        child: sub.done ? const Icon(Icons.check, size: 10, color: Colors.white) : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        sub.text,
                        style: TextStyle(
                          decoration: sub.done ? TextDecoration.lineThrough : null,
                          color: sub.done ? Colors.grey : null,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          // 展开区域：添加子任务
          if (isExpanded)
            _SubtaskInput(onSubmit: onAddSubtask),
        ],
      ),
    );
  }

  Color _priorityColor(String p) {
    switch (p) {
      case 'high':
        return const Color(0xFFe8453c);
      case 'low':
        return const Color(0xFF22c55e);
      default:
        return const Color(0xFFf59e0b);
    }
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 优先级
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  const Text('优先级', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const Spacer(),
                  for (final p in ColorConstants.priorities)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: GestureDetector(
                        onTap: () {
                          onSetPriority(p['val']!);
                          Navigator.pop(ctx);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: todo.priority == p['val']
                                ? Color(int.parse(p['color']!.replaceFirst('#', '0xFF'))).withOpacity(0.15)
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(p['label']!, style: const TextStyle(fontSize: 13)),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('设置到期日'),
              onTap: () async {
                Navigator.pop(ctx);
                // This will be handled by parent
              },
            ),
            if (todo.dueDate != null)
              ListTile(
                leading: const Icon(Icons.event_busy),
                title: const Text('清除到期日'),
                onTap: () {
                  onSetDueDate(null);
                  Navigator.pop(ctx);
                },
              ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('删除', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(ctx);
                onDelete();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SubtaskInput extends StatefulWidget {
  final void Function(String) onSubmit;

  const _SubtaskInput({required this.onSubmit});

  @override
  State<_SubtaskInput> createState() => _SubtaskInputState();
}

class _SubtaskInputState extends State<_SubtaskInput> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(48, 0, 12, 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _ctrl,
              decoration: const InputDecoration(
                hintText: '添加子任务...',
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                border: OutlineInputBorder(),
              ),
              maxLength: 150,
              onSubmitted: (_) => _submit(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add, size: 18),
            onPressed: _submit,
          ),
        ],
      ),
    );
  }

  void _submit() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    widget.onSubmit(text);
    _ctrl.clear();
  }
}

extension _PadExt on Widget {
  Widget padRight(double p) => Padding(padding: EdgeInsets.only(right: p), child: this);
}
