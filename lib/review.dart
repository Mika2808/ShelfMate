import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'config.dart';
import 'books.dart';
import 'book_entry.dart';

class BookDetailsPage extends StatefulWidget {
  final int bookId;

  const BookDetailsPage({super.key, required this.bookId});

  @override
  State<BookDetailsPage> createState() => _BookDetailsPageState();
}

class _BookDetailsPageState extends State<BookDetailsPage> {
  BookEntry? _book;
  List<dynamic> _comments = [];
  String _newComment = '';
  String? _token;
  String _addStatus = '';
  bool _isLoading = true;
  
  final TextEditingController _commentController = TextEditingController();
  
  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadToken().then((_) {
      _fetchBook();
      _fetchComments();
    });
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
  }

  Future<void> _fetchBook() async {
    try {
      final res = await http.get(
        Uri.parse('${AppConfig.baseUrl}/books/${widget.bookId}'),
        headers: {'Authorization': 'Bearer $_token'},
      );
      if (res.statusCode == 200) {
        setState(() {
          _book = BookEntry.fromJson(json.decode(res.body));
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load book');
      }
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchComments() async {
    try {
      final res = await http.get(
        Uri.parse('${AppConfig.baseUrl}/books/${widget.bookId}/reviews'),
        headers: {'Authorization': 'Bearer $_token'},
      );
      if (res.statusCode == 200) {
        setState(() {
          _comments = json.decode(res.body);
        });
      }
    } catch (_) {
      // handle silently
    }
  }

  Future<void> _submitComment() async {
    try {
      await http.post(
        Uri.parse('${AppConfig.baseUrl}/books/${widget.bookId}/reviews'),
        headers: {'Authorization': 'Bearer $_token', 'Content-Type': 'application/json'},
        body: json.encode({'review': _newComment}),
      );
      setState(() {
        _newComment = '';
        _commentController.clear(); 
      });
      _fetchComments();
    } catch (_) {
      // handle silently
    }
  }

  Future<void> _addToToRead() async {
    try {
      setState(() => _addStatus = 'adding');
      await http.post(
        Uri.parse('${AppConfig.baseUrl}/to-read/books/${widget.bookId}'),
        headers: {'Authorization': 'Bearer $_token'},
      );
      setState(() => _addStatus = 'added');
      Future.delayed(const Duration(seconds: 4), () => setState(() => _addStatus = ''));
    } catch (_) {
      setState(() => _addStatus = 'error');
      Future.delayed(const Duration(seconds: 4), () => setState(() => _addStatus = ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _book == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const BooksPage()),
            );
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 130,
                  height: 180,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.grey[300],
                  ),
                  child: _book!.cover != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(_book!.cover!, fit: BoxFit.cover),
                        )
                      : const Icon(Icons.image_not_supported, size: 60),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_book!.title,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('by ${_book!.author}',
                          style: const TextStyle(fontSize: 18, fontStyle: FontStyle.italic)),
                      const SizedBox(height: 8),
                      if (_book!.category != null)
                        Text('Category: ${_book!.category}'),
                      if (_book!.price != null)
                        Text('Price: \$${_book!.price!.toStringAsFixed(2)}'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _addToToRead,
                        child: Text(
                          _addStatus == 'adding'
                              ? 'Adding...'
                              : _addStatus == 'added'
                                  ? '✅ Book added!'
                                  : _addStatus == 'error'
                                      ? '❌ Failed to add'
                                      : 'Add to To-Read List',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Comments', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: _commentController,
              minLines: 2,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: 'Add your comment...',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => _newComment = value,
            ),
            const SizedBox(height: 8),
            ElevatedButton(onPressed: _submitComment, child: const Text('Submit')),
            const SizedBox(height: 24),
            const Text('Other comments:', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            ..._comments.map(
              (c) => Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  title: Text(c['nick'] ?? 'Anonymous'),
                  subtitle: Text(c['review'] ?? ''),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
