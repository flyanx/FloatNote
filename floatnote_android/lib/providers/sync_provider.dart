/// 云同步 Provider

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/sync_payload.dart';
import '../services/sync_service.dart';
import 'notebook_provider.dart';
import 'todolist_provider.dart';
import 'trash_provider.dart';

class SyncStatus {
  final String status; // 'idle' | 'syncing' | 'success' | 'error'
  final int? lastSyncTime;
  final String message;
  final bool configured;

  const SyncStatus({
    this.status = 'idle',
    this.lastSyncTime,
    this.message = '',
    this.configured = false,
  });

  SyncStatus copyWith({
    String? status,
    int? lastSyncTime,
    String? message,
    bool? configured,
  }) {
    return SyncStatus(
      status: status ?? this.status,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      message: message ?? this.message,
      configured: configured ?? this.configured,
    );
  }
}

class SyncNotifier extends StateNotifier<SyncStatus> {
  final SyncService _service;
  final Ref _ref;

  SyncNotifier(this._service, this._ref) : super(const SyncStatus()) {
    _loadConfig();
  }

  void _loadConfig() {
    final configured = _service.isConfigured;
    final storage = _ref.read(storageServiceProvider);
    final lastTimeStr = storage.getString('sn-last-sync-time');
    final lastTime = lastTimeStr != null ? int.tryParse(lastTimeStr) : null;
    state = state.copyWith(configured: configured, lastSyncTime: lastTime);
  }

  Future<void> saveConfig(String url, String key) async {
    await _service.saveConfig(url, key);
    state = state.copyWith(configured: true);
  }

  Future<SyncResult> push() async {
    state = state.copyWith(status: 'syncing', message: '推送中...');
    final result = await _service.pushToCloud();
    if (result.success) {
      final storage = _ref.read(storageServiceProvider);
      final lastTimeStr = storage.getString('sn-last-sync-time');
      final lastTime = int.tryParse(lastTimeStr ?? '') ??
          DateTime.now().millisecondsSinceEpoch;
      state = state.copyWith(
        status: 'success',
        message: result.message,
        lastSyncTime: lastTime,
      );
    } else {
      state = state.copyWith(status: 'error', message: result.message);
    }
    return result;
  }

  Future<SyncResult> pull() async {
    state = state.copyWith(status: 'syncing', message: '拉取中...');
    final result = await _service.pullFromCloud();
    if (result.success) {
      // 刷新所有 Provider
      _ref.read(notebookProvider.notifier).reload();
      _ref.read(todolistProvider.notifier).reload();
      _ref.read(trashProvider.notifier).reload();
      state = state.copyWith(
        status: 'success',
        message: result.message,
        lastSyncTime: DateTime.now().millisecondsSinceEpoch,
      );
    } else {
      state = state.copyWith(status: 'error', message: result.message);
    }
    return result;
  }

  Future<SyncResult> test() async {
    state = state.copyWith(status: 'syncing', message: '测试连接中...');
    final result = await _service.testConnection();
    state = state.copyWith(
      status: result.success ? 'success' : 'error',
      message: result.message,
    );
    return result;
  }

  String exportToJson() => _service.exportToJson();

  SyncResult importFromJson(String json) {
    final result = _service.importFromJson(json);
    if (result.success) {
      _ref.read(notebookProvider.notifier).reload();
      _ref.read(todolistProvider.notifier).reload();
      _ref.read(trashProvider.notifier).reload();
    }
    return result;
  }
}

// ===== Provider 定义 =====

final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(ref.watch(storageServiceProvider));
});

final syncProvider = StateNotifierProvider<SyncNotifier, SyncStatus>((ref) {
  return SyncNotifier(ref.watch(syncServiceProvider), ref);
});
