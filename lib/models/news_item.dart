class NewsItem {
  final String id;
  final String title;
  final String description;
  final String img;

  NewsItem({
    required this.id,
    required this.title,
    required this.description,
    required this.img,
  });

  factory NewsItem.fromJson(Map<String, dynamic> json) {
    return NewsItem(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      img: json['img']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'img': img,
    };
  }
}
