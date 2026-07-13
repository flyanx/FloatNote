/// 回收站页面

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/trash_provider.dart';
import '../../models/trash_item.dart';
import '../../utils/date_utils.dart';

class TrashScreen extends ConsumerWidget {
  const TrashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(trashProvider);
    final notifier = ref.read(trashProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('回收站'),
            Text(
              '30天内可恢复',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.normal),
            ),
          ],
        ),
      ),
      body: state.items.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.delete_outline, size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  Text('回收站是空的', style: TextStyle(color: Colors.grey.shade500)),
                ],
              ),
            )
          : ListView.builder(
              itemCount: state.items.length,
              itemBuilder: (context, idx) {
                final item = state.items[idx];
                return _TrashItemTile(
                  item: item,
                  onRestore: () => notifier.restore(item),
                  onDelete: () => _confirmPermanentDelete(context, notifier, item),
                );
              },
            ),
    );
  }

  void _confirmPermanentDelete(BuildContext context, TrashNotifier notifier, TrashItem item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('永久删除'),
        content: Text('确定要永久删除「${item.name}」吗？\n此操作不可恢复。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              notifier.deletePermanently(item);
              Navigator.pop(ctx);
            },
            child: const Text('永久删除'),
          ),
        ],
      ),
    );
  }
}

class _TrashItemTile extends StatelessWidget {
  final TrashItem item;
  final VoidCallback onRestore;
  final VoidCallback onDelete;

  const _TrashItemTile({
    required this.item,
    required this.onRestore,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            // 类型图标
            Text(item.typeEmoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 10),
            // 信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name.isEmpty ? '未命名' : item.name,
                    style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    AppDateUtils.formatRelativeDate(item.deletedAt),
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
            // 操作按钮
            TextButton(
              onPressed: onRestore,
              child: const Text('恢复', style: TextStyle(fontSize: 13)),
            ),
            TextButton(
              onPressed: onDelete,
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('删除', style: TextStyle(fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }
}
