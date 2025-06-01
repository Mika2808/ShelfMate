class BookEntry {
  final int id;
  final String title;
  final String author;
  final String? cover;
  final String? category;  // nullable in case not always present
  final double? price;     // nullable and double for price

  BookEntry({
    required this.id,
    required this.title,
    required this.author,
    this.cover,
    this.category,
    this.price,
  });

  factory BookEntry.fromJson(Map<String, dynamic> json) {
    return BookEntry(
      id: json['id'],
      title: json['title'],
      author: json['author'],
      cover: json['cover'],
      category: json['category'],
      price: json['price'] != null ? (json['price'] as num).toDouble() : null,
    );
  }
}
