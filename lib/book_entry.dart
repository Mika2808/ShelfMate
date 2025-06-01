class BookEntry {
  final int id;
  final String title;
  final String author;
  final String? cover;

  BookEntry({
    required this.id,
    required this.title,
    required this.author,
    this.cover,
  });

  factory BookEntry.fromJson(Map<String, dynamic> json) {
    return BookEntry(
      id: json['id'],
      title: json['title'],
      author: json['author'],
      cover: json['cover'], // this can be null, and that's fine
    );
  }
}
