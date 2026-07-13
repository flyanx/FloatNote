/// 云同步服务
/// 直连 Supabase REST API，与 PC 版 syncService.js 完全兼容

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/sync_payload.dart';
import 'storage_service.dart';

class SyncService {
  /// 需要同步的所有 localStorage 键（与 PC 版 SYNC_KEYS 一致）
  static const List<String> syncKeys = [
    'sn-notebooks',
    'sn-todolists',
    'sn-trash',
    'sn-item-trash',
    'sn-theme',
    'sn-accent',
    'sn-opacity',
    'sn-sidebar-visible',
    'sn-tabbar-visible',
    'sn-screenshot-hotkey',
    'sn-dev-mode',
    'sn-minimal-mode',
    'sn-active-book',
    'sn-active-todolist',
  ];

  final StorageService _storage;
  final http.Client _http;

  SyncService(this._storage, {http.Client? client})
      : _http = client ?? http.Client();

  // ===== 配置读取 =====

  String? get supabaseUrl => _storage.getString('sn-supabase-url');
  String? get supabaseKey => _storage.getString('sn-supabase-key');

  bool get isConfigured =>
      (supabaseUrl?.isNotEmpty ?? false) && (supabaseKey?.isNotEmpty ?? false);

  Future<void> saveConfig(String url, String key) async {
    await _storage.setString('sn-supabase-url', url.trim().replaceAll(RegExp(r'/+$'), ''));
    await _storage.setString('sn-supabase-key', key.trim());
  }

  // ===== 数据收集 =====

  SyncPayload collectLocalData() {
    final data = <String, String>{};
    for (final key in syncKeys) {
      final val = _storage.getString(key);
      if (val != null) data[key] = val;
    }
    return SyncPayload(
      meta: SyncMeta(exportedAt: DateTime.now().millisecondsSinceEpoch),
      data: data,
    );
  }

  /// 将远程数据写回本地
  int applyRemoteData(SyncPayload payload) {
    int count = 0;
    for (final key in syncKeys) {
      if (payload.data.containsKey(key)) {
        _storage.setString(key, payload.data[key]!);
        count++;
      }
    }
    return count;
  }

  // ===== Supabase HTTP 请求 =====

  Map<String, String> _headers({String? prefer}) {
    final h = <String, String>{
      'apikey': supabaseKey!,
      'Authorization': 'Bearer ${supabaseKey!}',
      'Content-Type': 'application/json',
    };
    if (prefer != null) h['Prefer'] = prefer;
    return h;
  }

  /// 推送到云端
  Future<SyncResult> pushToCloud() async {
    if (!isConfigured) {
      return const SyncResult(success: false, message: '请先配置 Supabase URL 和 API Key');
    }

    try {
      final payload = collectLocalData();
      final url = Uri.parse('${supabaseUrl!}/rest/v1/app_data');

      final response = await _http.post(
        url,
        headers: _headers(prefer: 'resolution=merge-duplicates,return=minimal'),
        body: jsonEncode({
          'id': 'main',
          'payload': payload.toJson(),
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode < 300) {
        final now = DateTime.now().millisecondsSinceEpoch;
        await _storage.setString('sn-last-sync-time', now.toString());
        return const SyncResult(success: true, message: '推送成功');
      } else {
        return SyncResult(success: false, message: '推送失败: HTTP ${response.statusCode}\n${response.body}');
      }
    } catch (e) {
      return SyncResult(success: false, message: '推送失败: $e');
    }
  }

  /// 从云端拉取
  Future<SyncResult> pullFromCloud() async {
    if (!isConfigured) {
      return const SyncResult(success: false, message: '请先配置 Supabase URL 和 API Key');
    }

    try {
      final url = Uri.parse('${supabaseUrl!}/rest/v1/app_data?id=eq.main&select=payload,updated_at');

      final response = await _http.get(
        url,
        headers: _headers(),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode < 300) {
        final rows = jsonDecode(response.body) as List;
        if (rows.isEmpty) {
          return const SyncResult(success: false, message: '云端暂无数据，请先推送到云端');
        }

        final payloadJson = rows[0]['payload'] as Map<String, dynamic>?;
        if (payloadJson == null) {
          return const SyncResult(success: false, message: '云端数据格式无效');
        }

        final payload = SyncPayload.fromJson(payloadJson);
        final count = applyRemoteData(payload);

        final now = DateTime.now().millisecondsSinceEpoch;
        await _storage.setString('sn-last-sync-time', now.toString());

        final serverTime = rows[0]['updated_at']?.toString() ?? '未知';
        return SyncResult(success: true, message: '拉取成功 ($count 项)\n云端时间: $serverTime');
      } else {
        return SyncResult(success: false, message: '拉取失败: HTTP ${response.statusCode}\n${response.body}');
      }
    } catch (e) {
      return SyncResult(success: false, message: '拉取失败: $e');
    }
  }

  /// 测试连接
  Future<SyncResult> testConnection() async {
    if (!isConfigured) {
      return const SyncResult(success: false, message: '请先填写 URL 和 API Key');
    }

    try {
      final url = Uri.parse('${supabaseUrl!}/rest/v1/app_data?id=eq.main&select=id,updated_at');

      final response = await _http.get(
        url,
        headers: _headers(),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 401 || response.statusCode == 403) {
        return const SyncResult(success: false, message: 'API Key 无效或权限不足');
      }

      if (response.statusCode == 404) {
        return const SyncResult(
            success: false,
            message: 'app_data 表不存在\n请在 Supabase SQL Editor 中建表');
      }

      if (response.statusCode < 300) {
        final rows = jsonDecode(response.body) as List;
        if (rows.isEmpty) {
          return const SyncResult(success: true, message: '连接正常！\n尚未推送过数据');
        }
        final updated = rows[0]['updated_at']?.toString() ?? '无';
        return SyncResult(success: true, message: '连接正常！\n上次更新: $updated');
      }

      return SyncResult(success: false, message: 'HTTP ${response.statusCode}');
    } catch (e) {
      return SyncResult(success: false, message: '连接失败: $e');
    }
  }

  // ===== 本地备份 =====

  /// 导出为 JSON 字符串
  String exportToJson() {
    final payload = collectLocalData();
    return const JsonEncoder.withIndent('  ').convert(payload.toJson());
  }

  /// 从 JSON 字符串导入
  SyncResult importFromJson(String jsonStr) {
    try {
      final parsed = jsonDecode(jsonStr) as Map<String, dynamic>;
      if (!parsed.containsKey('data')) {
        return const SyncResult(success: false, message: '数据格式无效：缺少 data 字段');
      }
      final payload = SyncPayload.fromJson(parsed);
      final count = applyRemoteData(payload);
      return SyncResult(success: true, message: '导入成功 ($count 项)');
    } catch (e) {
      return SyncResult(success: false, message: '导入失败: $e');
    }
  }

  void dispose() {
    _http.close();
  }
}
