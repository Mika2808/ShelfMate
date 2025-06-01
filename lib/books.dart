import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'book_entry.dart';
import 'config.dart';

class BooksPage extends StatefulWidget {
  const BooksPage({super.key});

  @override
  State<BooksPage> createState() => _BooksPageState();
}

class _BooksPageState extends State<BooksPage> {
  List<BookEntry> _allBooks = [];
  int _page = 1;
  final int _booksPerPage = 5;
  String? _token;
  bool _isLoading = true;
  Map<int, String> _addStatusMap = {};

  @override
  void initState() {
    super.initState();
    _loadToken().then((_) => _fetchBooks());
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
  }

  Future<void> _fetchBooks() async {
    setState(() => _isLoading = true);
    try {
      final res = await http.get(
        Uri.parse('${AppConfig.baseUrl}/books'),
        headers: {'Authorization': 'Bearer $_token'},
      );

      if (res.statusCode == 200) {
        final List<dynamic> data = json.decode(res.body);
        setState(() {
          _allBooks = data.map((json) => BookEntry.fromJson(json)).toList();
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load books');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error loading books')),
      );
    }
  }

  List<BookEntry> get _paginatedBooks {
    final start = (_page - 1) * _booksPerPage;
    final end = (_page * _booksPerPage).clamp(0, _allBooks.length);
    return _allBooks.sublist(start, end);
  }

  Future<void> _addToToRead(int bookId) async {
    setState(() {
      _addStatusMap[bookId] = 'adding';
    });

    try {
      await http.post(
        Uri.parse('${AppConfig.baseUrl}/to-read/books/$bookId'),
        headers: {'Authorization': 'Bearer $_token'},
      );
      setState(() {
        _addStatusMap[bookId] = 'added';
      });
      Future.delayed(const Duration(seconds: 3), () {
        setState(() => _addStatusMap.remove(bookId));
      });
    } catch (_) {
      setState(() {
        _addStatusMap[bookId] = 'error';
      });
      Future.delayed(const Duration(seconds: 3), () {
        setState(() => _addStatusMap.remove(bookId));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalPages = (_allBooks.length / _booksPerPage).ceil();

    return Scaffold(
      appBar: AppBar(title: const Text('Books Page')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: _paginatedBooks.length,
                    itemBuilder: (context, index) {
                      final book = _paginatedBooks[index];
                      return Card(
                        margin: const EdgeInsets.all(8),
                        child: ListTile(
                          leading: book.cover != null
                              ? Image.network(book.cover!, width: 50, fit: BoxFit.cover)
                              : const Icon(Icons.image_not_supported),
                          title: Text(book.title),
                          subtitle: Text('by ${book.author}'),
                          trailing: _addStatusMap[book.id] == 'adding'
                              ? const CircularProgressIndicator()
                              : ElevatedButton(
                                  onPressed: () => _addToToRead(book.id),
                                  child: Text(_addStatusMap[book.id] == 'added'
                                      ? '✓ Added'
                                      : _addStatusMap[book.id] == 'error'
                                          ? 'Error'
                                          : 'Add'),
                                ),
                          onTap: () {
                            Navigator.pushNamed(context, '/books/${book.id}');
                          },
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: _page > 1 ? () => setState(() => _page--) : null,
                      ),
                      Text('Page $_page of $totalPages'),
                      IconButton(
                        icon: const Icon(Icons.arrow_forward),
                        onPressed: _page < totalPages
                            ? () => setState(() => _page++)
                            : null,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
