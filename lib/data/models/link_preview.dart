// Recall · LinkPreview — typed view of nodes.link_preview_json jsonb.
// Canonical response [D-EF-2]; duration_sec/video_id are YouTube-only.
// read_time_sec is for articles; view_count is for YouTube.

import 'json_utils.dart';

class LinkPreview {
  final String? title;
  final String? description;
  final String? imageUrl;
  final String? canonicalUrl;
  final String? siteName;
  final int? durationSec;
  final String? videoId;
  final int? readTimeSec;
  final int? viewCount;

  const LinkPreview({
    this.title,
    this.description,
    this.imageUrl,
    this.canonicalUrl,
    this.siteName,
    this.durationSec,
    this.videoId,
    this.readTimeSec,
    this.viewCount,
  });

  factory LinkPreview.fromJson(Map<String, dynamic> json) => LinkPreview(
        title: asStringOrNull(json['title']),
        description: asStringOrNull(json['description']),
        imageUrl: asStringOrNull(json['image_url']),
        canonicalUrl: asStringOrNull(json['canonical_url']),
        siteName: asStringOrNull(json['site_name']),
        durationSec: asIntOrNull(json['duration_sec']),
        videoId: asStringOrNull(json['video_id']),
        readTimeSec: asIntOrNull(json['read_time_sec']),
        viewCount: asIntOrNull(json['view_count']),
      );

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'image_url': imageUrl,
        'canonical_url': canonicalUrl,
        'site_name': siteName,
        'duration_sec': durationSec,
        'video_id': videoId,
        'read_time_sec': readTimeSec,
        'view_count': viewCount,
      };

  LinkPreview copyWith({
    String? title,
    String? description,
    String? imageUrl,
    String? canonicalUrl,
    String? siteName,
    int? durationSec,
    String? videoId,
    int? readTimeSec,
    int? viewCount,
  }) {
    return LinkPreview(
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      canonicalUrl: canonicalUrl ?? this.canonicalUrl,
      siteName: siteName ?? this.siteName,
      durationSec: durationSec ?? this.durationSec,
      videoId: videoId ?? this.videoId,
      readTimeSec: readTimeSec ?? this.readTimeSec,
      viewCount: viewCount ?? this.viewCount,
    );
  }
}
