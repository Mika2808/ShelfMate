class BookEntry {
  final int id;
  final String title;
  final String author;

  BookEntry({required this.id, required this.title, required this.author});

  factory BookEntry.fromJson(Map<String, dynamic> json) {
    return BookEntry(
      id: json['id'],
      title: json['title'],
      author: json['author'],
    );
  }
}
