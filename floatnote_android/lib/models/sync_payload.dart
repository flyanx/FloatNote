/// 云同步载荷模型
/// 与 PC 版 collectLocalData / applyRemoteData 格式兼容

class SyncPayload {
  final SyncMeta meta;
  final Map<String, String> data; // key -> JSON string (与 localStorage 一致)

  const SyncPayload({required this.meta, required this.data});

  factory SyncPayload.fromJson(Map<String, dynamic> json) {
    final metaJson = json['_meta'] as Map<String, dynamic>? ?? {};
    final dataJson = json['data'] as Map<String, dynamic>? ?? {};
    return SyncPayload(
      meta: SyncMeta.fromJson(metaJson),
      data: dataJson.map((k, v) => MapEntry(k, v.toString())),
    );
  }

  Map<String, dynamic> toJson() => {
        '_meta': meta.toJson(),
        'data': data,
      };
}

class SyncMeta {
  final int version;
  final String appVersion;
  final int exportedAt;

  const SyncMeta({
    this.version = 1,
    this.appVersion = '1.2.0',
    required this.exportedAt,
  });

  factory SyncMeta.fromJson(Map<String, dynamic> json) {
    return SyncMeta(
      version: json['version'] as int? ?? 1,
      appVersion: json['appVersion'] as String? ?? '1.2.0',
      exportedAt: json['exportedAt'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'version': version,
        'appVersion': appVersion,
        'exportedAt': exportedAt,
      };
}

/// 同步结果
class SyncResult {
  final bool success;
  final String message;

  const SyncResult({required this.success, required this.message});
}
