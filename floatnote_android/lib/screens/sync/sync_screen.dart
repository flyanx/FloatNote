/// 云同步设置页

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/sync_provider.dart';
import '../../utils/date_utils.dart';

class SyncScreen extends ConsumerStatefulWidget {
  const SyncScreen({super.key});

  @override
  ConsumerState<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends ConsumerState<SyncScreen> {
  late final TextEditingController _urlCtrl;
  late final TextEditingController _keyCtrl;
  bool _obscureKey = true;

  @override
  void initState() {
    super.initState();
    final service = ref.read(syncServiceProvider);
    _urlCtrl = TextEditingController(text: service.supabaseUrl ?? '');
    _keyCtrl = TextEditingController(text: service.supabaseKey ?? '');
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    _keyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sync = ref.watch(syncProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('云同步')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 状态区
          _buildStatusCard(sync),
          const SizedBox(height: 16),

          // 操作按钮
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  icon: const Icon(Icons.cloud_upload, size: 18),
                  label: const Text('推送到云端'),
                  onPressed: sync.status == 'syncing' || !sync.configured
                      ? null
                      : () => ref.read(syncProvider.notifier).push(),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  icon: const Icon(Icons.cloud_download, size: 18),
                  label: const Text('从云端拉取'),
                  onPressed: sync.status == 'syncing' || !sync.configured
                      ? null
                      : () => ref.read(syncProvider.notifier).pull(),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.wifi, size: 18),
            label: const Text('测试连接'),
            onPressed: sync.status == 'syncing' || !sync.configured
                ? null
                : () => ref.read(syncProvider.notifier).test(),
          ),

          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 8),

          // 本地备份
          const Text('本地备份', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.file_download_outlined, size: 18),
                  label: const Text('导出 JSON'),
                  onPressed: _exportJson,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.file_upload_outlined, size: 18),
                  label: const Text('导入 JSON'),
                  onPressed: _importJson,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 8),

          // Supabase 配置
          const Text('Supabase 配置', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 8),
          TextField(
            controller: _urlCtrl,
            decoration: const InputDecoration(
              labelText: 'Project URL',
              hintText: 'https://xxx.supabase.co',
              prefixIcon: Icon(Icons.link),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _keyCtrl,
            decoration: InputDecoration(
              labelText: 'API Key (anon)',
              hintText: 'eyJ...',
              prefixIcon: const Icon(Icons.key),
              suffixIcon: IconButton(
                icon: Icon(_obscureKey ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _obscureKey = !_obscureKey),
              ),
            ),
            obscureText: _obscureKey,
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () async {
              await ref.read(syncProvider.notifier).saveConfig(
                    _urlCtrl.text.trim(),
                    _keyCtrl.text.trim(),
                  );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('配置已保存')),
                );
              }
            },
            child: const Text('保存配置'),
          ),

          const SizedBox(height: 24),
          // 建表 SQL 提示
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                Row(
                  children: [
                    const Icon(Icons.info_outline, size: 16, color: Colors.blue),
                    const SizedBox(width: 8),
                    Text('首次使用？', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.blue.shade700)),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  '在 Supabase SQL Editor 中执行以下 SQL 创建数据表：',
                  style: TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const SelectableText(
                    'CREATE TABLE app_data (\n'
                    '  id TEXT PRIMARY KEY,\n'
                    '  payload JSONB,\n'
                    '  updated_at TIMESTAMPTZ DEFAULT now()\n'
                    ');',
                    style: TextStyle(fontSize: 12, fontFamily: 'monospace'),
                  ),
                ),
                const SizedBox(height: 4),
                TextButton.icon(
                  icon: const Icon(Icons.copy, size: 14),
                  label: const Text('复制 SQL'),
                  onPressed: () {
                    Clipboard.setData(const ClipboardData(
                      text: 'CREATE TABLE app_data (\n  id TEXT PRIMARY KEY,\n  payload JSONB,\n  updated_at TIMESTAMPTZ DEFAULT now()\n);',
                    ));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('已复制')),
                    );
                  },
                ),
              ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(SyncStatus sync) {
    Color statusColor;
    IconData statusIcon;
    switch (sync.status) {
      case 'success':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'error':
        statusColor = Colors.red;
        statusIcon = Icons.error;
        break;
      case 'syncing':
        statusColor = Colors.blue;
        statusIcon = Icons.sync;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.cloud_off;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(statusIcon, color: statusColor, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sync.status == 'idle' ? '未同步' :
                    sync.status == 'syncing' ? '同步中...' :
                    sync.status == 'success' ? '同步成功' : '同步失败',
                    style: TextStyle(fontWeight: FontWeight.w600, color: statusColor),
                  ),
                  if (sync.lastSyncTime != null)
                    Text(
                      '上次: ${AppDateUtils.formatDateTime(sync.lastSyncTime)}',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  if (sync.message.isNotEmpty)
                    Text(
                      sync.message,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      maxLines: 3,
                    ),
                ],
              ),
            ),
            if (sync.status == 'syncing')
              const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
          ],
        ),
      ),
    );
  }

  void _exportJson() {
    final json = ref.read(syncProvider.notifier).exportToJson();
    Clipboard.setData(ClipboardData(text: json));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('备份数据已复制到剪贴板\n（安卓版暂不支持文件保存，请使用文件管理器手动保存）')),
    );
  }

  void _importJson() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('导入 JSON'),
        content: SizedBox(
          width: double.maxFinite,
          height: 200,
          child: TextField(
            controller: ctrl,
            maxLines: null,
            expands: true,
            decoration: const InputDecoration(
              hintText: '粘贴 JSON 备份数据...',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            onPressed: () {
              if (ctrl.text.trim().isEmpty) return;
              final result = ref.read(syncProvider.notifier).importFromJson(ctrl.text);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(result.message)),
              );
            },
            child: const Text('导入'),
          ),
        ],
      ),
    );
  }
}
