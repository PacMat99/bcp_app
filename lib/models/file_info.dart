class FileInfo {
  final String name;
  final int size; // bytes
  final DateTime? date;
  bool isDownloaded;
  String? localPath;

  FileInfo({
    required this.name,
    required this.size,
    this.date,
    this.isDownloaded = false,
    this.localPath,
  });

  String get sizeFormatted {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  factory FileInfo.fromJson(Map<String, dynamic> json) {
    return FileInfo(
      name: json['name'] ?? '',
      size: json['size'] ?? 0,
      date: json['date'] != null ? DateTime.tryParse(json['date']) : null,
    );
  }
}
