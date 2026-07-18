import 'dart:typed_data';

/// A file the user picked (PDF or image) that hasn't been uploaded yet.
class PickedFile {
  final Uint8List bytes;
  final String name;
  final String mimeType;
  final bool isPdf;

  const PickedFile({
    required this.bytes,
    required this.name,
    required this.mimeType,
    required this.isPdf,
  });

  int get sizeBytes => bytes.lengthInBytes;
}
