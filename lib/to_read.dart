// pages/to_read_page.dart
import 'dart:convert';
import 'dart:ffi';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shelf_mate/home.dart';
import 'book_entry.dart';
import 'config.dart';

class ToReadPage extends StatefulWidget {
  const ToReadPage({Key? key}) : super(key: key);

  @override
  _ToReadPageState createState() => _ToReadPageState();
}

class _ToReadPageState extends State<ToReadPage> {
  List<BookEntry> _books = [];
  bool _isLoading = true;
  String? _token;
  int? _userId;

  @override
  void initState() {
    super.initState();
    _loadUserData().then((_) => _fetchBooks());
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _token = prefs.getString('token');
      _userId = prefs.getInt('id');
    });
  }

  Future<void> _fetchBooks() async {
    if (_token == null || _userId == null) return;
    
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/to-read/list/$_userId'),
        headers: {'Authorization': 'Bearer $_token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _books = data
              .map((entry) => BookEntry.fromJson(entry['book']))
              .toList();
          _isLoading = false;
        });
      } else {
        // Handle error
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load books')),
        );
      }
    } catch (e) {
      // Handle error
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred')),
      );
    }
  }

  Future<void> _deleteBook(int bookId) async {
    if (_token == null) return;

    try {
      final response = await http.delete(
        Uri.parse('${AppConfig.baseUrl}/to-read/books/$bookId'),
        headers: {'Authorization': 'Bearer $_token'},
      );

      if (response.statusCode == 200) {
        setState(() {
          _books.removeWhere((book) => book.id == bookId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Book deleted')),
        );
      } else {
        // Handle error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete book')),
        );
      }
    } catch (e) {
      // Handle error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
        return false; // Prevent default pop behavior
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('To-Read List'),
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HomePage()),
              );
            },
          ),
        ),
        body: _isLoading
            ? Center(child: CircularProgressIndicator())
            : _books.isEmpty
                ? Center(child: Text('No books available.'))
                : ListView.builder(
                    itemCount: _books.length,
                    itemBuilder: (context, index) {
                      final book = _books[index];
                      return ListTile(
                        title: Text(book.title),
                        subtitle: Text('by ${book.author}'),
                        trailing: IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () => _deleteBook(book.id),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
