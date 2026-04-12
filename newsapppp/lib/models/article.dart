class Article {
  final String title;
  final String description;
  final String urlToImage;
  final String content;
  final DateTime publishedAt;
  final String sourceName;
  final String url; // Added URL field

  Article({
    required this.title,
    required this.description,
    required this.urlToImage,
    required this.content,
    required this.publishedAt,
    required this.sourceName,
    required this.url,
  });

  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      title: json['title'] ?? 'No Title',
      description: json['description'] ?? 'No Description',
      urlToImage: (json['urlToImage'] != null && json['urlToImage'].toString().isNotEmpty)
          ? json['urlToImage']
          : 'https://images.unsplash.com/photo-1504711434969-e33886168f5c?q=80&w=800',
      content: json['content'] ?? '',
      publishedAt: DateTime.parse(json['publishedAt'] ?? DateTime.now().toIso8601String()),
      sourceName: (json['source'] != null && json['source']['name'] != null)
          ? json['source']['name']
          : 'Unknown',
      url: json['url'] ?? 'https://news.google.com', // Default to Google News if missing
    );
  }
}
