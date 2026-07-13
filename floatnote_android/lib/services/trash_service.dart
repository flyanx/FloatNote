/// 回收站服务
/// 管理删除项的存储和 30 天自动清理

import '../models/trash_item.dart';
import 'storage_service.dart';

class TrashService {
  static const String _trashKey = 'sn-trash';
  static const String _itemTrashKey = 'sn-item-trash';

  final StorageService _storage;

  TrashService(this._storage);

  // ===== 标签页回收站 (sn-trash) =====

  List<TrashItem> readTrash() {
    final list = _storage.readJSON<List>(_trashKey, []);
    return list
        .map((e) => TrashItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveTrash(List<TrashItem> items) async {
    final cutoff = DateTime.now().millisecondsSinceEpoch - 30 * 24 * 60 * 60 * 1000;
    final filtered = items.where((t) => t.deletedAt > cutoff).toList();
    await _storage.writeJSON(_trashKey, filtered.map((t) => t.toJson()).toList());
  }

  Future<void> addToTrash(TrashItem item) async {
    final trash = readTrash();
    trash.add(item);
    await saveTrash(trash);
  }

  // ===== 项目回收站 (sn-item-trash) =====

  List<TrashItem> readItemTrash() {
    final list = _storage.readJSON<List>(_itemTrashKey, []);
    return list
        .map((e) => TrashItem.fromJson(e as Map<String, dynamic>, isItem: true))
        .toList();
  }

  Future<void> saveItemTrash(List<TrashItem> items) async {
    final cutoff = DateTime.now().millisecondsSinceEpoch - 30 * 24 * 60 * 60 * 1000;
    final filtered = items.where((t) => t.deletedAt > cutoff).toList();
    await _storage.writeJSON(_itemTrashKey, filtered.map((t) => t.toJson()).toList());
  }

  Future<void> addToItemTrash(TrashItem item) async {
    final trash = readItemTrash();
    trash.add(item);
    await saveItemTrash(trash);
  }

  // ===== 合并列表 =====

  List<TrashItem> readAllTrash() {
    final tabTrash = readTrash();
    final itemTrash = readItemTrash();
    final all = [...tabTrash, ...itemTrash];
    all.sort((a, b) => b.deletedAt.compareTo(a.deletedAt));
    return all;
  }

  /// 恢复回收站项
  Future<bool> restore(TrashItem item) async {
    if (item.isItem) {
      final trash = readItemTrash();
      trash.removeWhere((t) => t.id == item.id && t.deletedAt == item.deletedAt);
      await saveItemTrash(trash);
    } else {
      final trash = readTrash();
      trash.removeWhere((t) => t.id == item.id && t.deletedAt == item.deletedAt);
      await saveTrash(trash);
    }
    return true;
  }

  /// 永久删除
  Future<void> deletePermanently(TrashItem item) async {
    if (item.isItem) {
      final trash = readItemTrash();
      trash.removeWhere((t) => t.id == item.id && t.deletedAt == item.deletedAt);
      await saveItemTrash(trash);
    } else {
      final trash = readTrash();
      trash.removeWhere((t) => t.id == item.id && t.deletedAt == item.deletedAt);
      await saveTrash(trash);
    }
  }
}
