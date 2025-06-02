import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shelf_mate/main.dart';
import 'to_read.dart';
import 'roullete.dart';
import 'books.dart';
import 'nearby_bookstores.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String nick = '';
  String quote = '';
  final List<String> quotes = [
    '“A room without books is like a body without a soul.” – Cicero',
    '“So many books, so little time.” – Frank Zappa',
    '“The only thing you absolutely have to know is the location of the library.” – Einstein',
    '“Reading is essential for those who seek to rise above the ordinary.” – Jim Rohn',
    '“Today a reader, tomorrow a leader.” – Margaret Fuller',
    '“Books are a uniquely portable magic.” – Stephen King',
    '“You can never get a cup of tea large enough or a book long enough to suit me.” – C.S. Lewis',
    '“We read to know we\'re not alone.” – William Nicholson',
    '“Once you learn to read, you will be forever free.” – Frederick Douglass',
    '“Reading gives us someplace to go when we have to stay where we are.” – Mason Cooley',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _setRandomQuote();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      nick = prefs.getString('nick') ?? 'User';
    });
  }

  void _setRandomQuote() {
    final randomIndex = Random().nextInt(quotes.length);
    quote = quotes[randomIndex];
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('nick');
    await prefs.remove('id');
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MyHomePage()),
      );
    }
  }

  void _navigate(String route) {
    Navigator.of(context).pushNamed(route);
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome, $nick!'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          )
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: primaryColor),
              child: Text(
                'Menu',
                style: const TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              onTap: () {
                Navigator.pop(context); // Close drawer
              },
            ),
            ListTile(
              leading: const Icon(Icons.search),
              title: const Text('Search Book'),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const BooksPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.list),
              title: const Text('To-Read List'),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const ToReadPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.casino),
              title: const Text('Book Roulette'),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const RoulettePage()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.location_on),
              title: Text('Nearby Bookstores'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => NearbyBookstoresPage()),
                );
              },
            ),
          ],
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            quote,
            style: const TextStyle(fontSize: 18, fontStyle: FontStyle.italic),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
