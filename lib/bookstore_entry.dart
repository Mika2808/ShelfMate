class Bookstore {
  final int id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;

  Bookstore({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
  });

  factory Bookstore.fromJson(Map<String, dynamic> json) {
    return Bookstore(
      id: json['id'],
      name: json['name'],
      address: json['address'],
      latitude: json['latitude'].toDouble(),
      longitude: json['longitude'].toDouble(),
    );
  }
}
