class DocumentItem {
  final String title;
  final String? filePath;
  final bool isUploaded;

  DocumentItem({
    required this.title,
    this.filePath,
    this.isUploaded = false,
  });

  DocumentItem copyWith({
    String? title,
    String? filePath,
    bool? isUploaded,
  }) {
    return DocumentItem(
      title: title ?? this.title,
      filePath: filePath ?? this.filePath,
      isUploaded: isUploaded ?? this.isUploaded,
    );
  }
}
