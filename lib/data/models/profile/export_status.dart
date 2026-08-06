// Recall · ExportStatus — the `export-user-data` Edge Function response [D-EF-5].
// One zip per user; `signedUrl` is short-lived (re-minted via the "status"
// action), while the file itself lives until `fileExpiresAt` (12h, cron-pruned).

import 'json_utils.dart';

class ExportStatus {
  final bool ready;
  final String? signedUrl;
  final DateTime? urlExpiresAt;
  final DateTime? fileExpiresAt;
  final DateTime? generatedAt;

  const ExportStatus({
    this.ready = false,
    this.signedUrl,
    this.urlExpiresAt,
    this.fileExpiresAt,
    this.generatedAt,
  });

  /// A downloadable export exists with a usable signed URL.
  bool get hasFile => ready && (signedUrl?.isNotEmpty ?? false);

  factory ExportStatus.none() => const ExportStatus();

  factory ExportStatus.fromJson(Map<String, dynamic> json) => ExportStatus(
        ready: asString(json['status']) == 'ready',
        signedUrl: asStringOrNull(json['signed_url']),
        urlExpiresAt: asDateTime(json['url_expires_at']),
        fileExpiresAt: asDateTime(json['file_expires_at']),
        generatedAt: asDateTime(json['generated_at']),
      );
}
