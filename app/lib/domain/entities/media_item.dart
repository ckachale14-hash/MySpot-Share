class MediaItem {
  const MediaItem({
    required this.url,
    this.type = 'image',
    this.thumbUrl = '',
    this.width = 0,
    this.height = 0,
  });

  final String url;
  final String type; // image | video
  final String thumbUrl;
  final int width;
  final int height;

  Map<String, dynamic> toMap() => {
        'url': url,
        'type': type,
        'thumbUrl': thumbUrl,
        'width': width,
        'height': height,
      };

  factory MediaItem.fromMap(Map<String, dynamic> m) => MediaItem(
        url: (m['url'] ?? '') as String,
        type: (m['type'] ?? 'image') as String,
        thumbUrl: (m['thumbUrl'] ?? '') as String,
        width: (m['width'] ?? 0) as int,
        height: (m['height'] ?? 0) as int,
      );
}
