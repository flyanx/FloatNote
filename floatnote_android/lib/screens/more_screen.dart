/// 更多页面 - 云同步、回收站、主题、关于

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/settings_provider.dart';
import 'sync/sync_screen.dart';
import 'trash/trash_screen.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(settingsProvider).themeMode;
    final isDark = themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            MediaQuery.of(context).platformBrightness == Brightness.dark);

    return Scaffold(
      appBar: AppBar(
        title: const Text('更多'),
      ),
      body: ListView(
        children: [
          // 云同步
          ListTile(
            leading: const Icon(Icons.cloud_sync_outlined),
            title: const Text('云同步'),
            subtitle: const Text('Supabase 推送/拉取'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SyncScreen()),
            ),
          ),
          const Divider(),
          // 回收站
          ListTile(
            leading: const Icon(Icons.delete_outline),
            title: const Text('回收站'),
            subtitle: const Text('30天内可恢复'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TrashScreen()),
            ),
          ),
          const Divider(),
          // 主题切换
          ListTile(
            leading: Icon(isDark ? Icons.dark_mode : Icons.light_mode),
            title: const Text('主题'),
            subtitle: Text(isDark ? '暗黑模式' : '明亮模式'),
            trailing: Switch(
              value: isDark,
              onChanged: (val) {
                ref.read(settingsProvider.notifier).setThemeMode(
                      val ? ThemeMode.dark : ThemeMode.light,
                    );
              },
            ),
          ),
          const Divider(),
          // 关于
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('关于'),
            subtitle: Text('灵签 FloatNote v1.2.0\n轻盈桌面便签 · 记事本 & 待办事项'),
          ),
        ],
      ),
    );
  }
}
