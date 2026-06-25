// Recall · NodeAsset model — `node_assets` row (PDF/image storage references).

import 'json_utils.dart';

class NodeAsset {
  final String id;
  final String nodeId;
  final String storagePath;
  final String mimeType;
  final int? fileSizeBytes;
  final int? pageCount;
  final int sortOrder;
  final DateTime? createdAt;

  const NodeAsset({
    required this.id,
    required this.nodeId,
    this.storagePath = '',
    this.mimeType = '',
    this.fileSizeBytes,
    this.pageCount,
    this.sortOrder = 0,
    this.createdAt,
  });

  factory NodeAsset.fromJson(Map<String, dynamic> json) => NodeAsset(
        id: asString(json['id']),
        nodeId: asString(json['node_id']),
        storagePath: asString(json['storage_path']),
        mimeType: asString(json['mime_type']),
        fileSizeBytes: asIntOrNull(json['file_size_bytes']),
        pageCount: asIntOrNull(json['page_count']),
        sortOrder: asInt(json['sort_order']),
        createdAt: asDateTime(json['created_at']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'node_id': nodeId,
        'storage_path': storagePath,
        'mime_type': mimeType,
        'file_size_bytes': fileSizeBytes,
        'page_count': pageCount,
        'sort_order': sortOrder,
        'created_at': dateToJson(createdAt),
      };

  NodeAsset copyWith({
    String? id,
    String? nodeId,
    String? storagePath,
    String? mimeType,
    int? fileSizeBytes,
    int? pageCount,
    int? sortOrder,
    DateTime? createdAt,
  }) {
    return NodeAsset(
      id: id ?? this.id,
      nodeId: nodeId ?? this.nodeId,
      storagePath: storagePath ?? this.storagePath,
      mimeType: mimeType ?? this.mimeType,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      pageCount: pageCount ?? this.pageCount,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
