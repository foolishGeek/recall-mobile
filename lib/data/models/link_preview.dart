// Recall · LinkPreview — typed view of nodes.link_preview_json jsonb.
// Canonical 7-field response [D-EF-2]; duration_sec/video_id are YouTube-only.

import 'json_utils.dart';

class LinkPreview {
  final String? title;
  final String? description;
  final String? imageUrl;
  final String? canonicalUrl;
  final String? siteName;
  final int? durationSec;
  final String? videoId;

  const LinkPreview({
    this.title,
    this.description,
    this.imageUrl,
    this.canonicalUrl,
    this.siteName,
    this.durationSec,
    this.videoId,
  });

  factory LinkPreview.fromJson(Map<String, dynamic> json) => LinkPreview(
        title: asStringOrNull(json['title']),
        description: asStringOrNull(json['description']),
        imageUrl: asStringOrNull(json['image_url']),
        canonicalUrl: asStringOrNull(json['canonical_url']),
        siteName: asStringOrNull(json['site_name']),
        durationSec: asIntOrNull(json['duration_sec']),
        videoId: asStringOrNull(json['video_id']),
      );

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'image_url': imageUrl,
        'canonical_url': canonicalUrl,
        'site_name': siteName,
        'duration_sec': durationSec,
        'video_id': videoId,
      };

  LinkPreview copyWith({
    String? title,
    String? description,
    String? imageUrl,
    String? canonicalUrl,
    String? siteName,
    int? durationSec,
    String? videoId,
  }) {
    return LinkPreview(
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      canonicalUrl: canonicalUrl ?? this.canonicalUrl,
      siteName: siteName ?? this.siteName,
      durationSec: durationSec ?? this.durationSec,
      videoId: videoId ?? this.videoId,
    );
  }
}
