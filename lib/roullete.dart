import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'book_entry.dart';
import 'config.dart';
import 'home.dart';

class RoulettePage extends StatefulWidget {
  const RoulettePage({super.key});

  @override
  State<RoulettePage> createState() => _RoulettePageState();
}

class _RoulettePageState extends State<RoulettePage> {
  BookEntry? _randomBook;
  bool _isLoading = false;
  String? _token;

  @override
  void initState() {
    super.initState();
    _loadToken().then((_) => _fetchRandomBook());
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
  }

  Future<void> _fetchRandomBook() async {
    if (_token == null) return;
    setState(() => _isLoading = true);

    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/books/roulette'),
        headers: {'Authorization': 'Bearer $_token'},
      );

      if (response.statusCode == 200) {
        setState(() {
          _randomBook = BookEntry.fromJson(json.decode(response.body));
          _isLoading = false;
        });
      } else {
        _handleError('Failed to fetch book');
      }
    } catch (e) {
      _handleError('Error occurred while fetching book');
    }
  }

  void _handleError(String message) {
    setState(() => _isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _addToToReadList() async {
    if (_randomBook == null || _token == null) return;

    try {
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/to-read/books/${_randomBook!.id}'),
        headers: {'Authorization': 'Bearer $_token'},
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${_randomBook!.title} added to To-Read list!')),
        );
        _fetchRandomBook();
      } else {
        _handleError('Failed to add book');
      }
    } catch (e) {
      _handleError('Error occurred while adding book');
    }
  }

  @override
  Widget build(BuildContext context) {
    final book = _randomBook;

    return Scaffold(
      appBar: AppBar(
          title: Text('Book Roulette'),
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
          ? const Center(child: CircularProgressIndicator())
          : book == null
              ? const Center(child: Text('No book available.'))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        book.title,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text('by ${book.author}', style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _fetchRandomBook,
                            icon: const Icon(Icons.close),
                            label: const Text('Pass'),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          ),
                          ElevatedButton.icon(
                            onPressed: _addToToReadList,
                            icon: const Icon(Icons.favorite),
                            label: const Text('Add'),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
    );
  }
}
