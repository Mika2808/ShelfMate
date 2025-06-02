import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import '../config.dart';
import 'bookstore_entry.dart';

class NearbyBookstoresPage extends StatefulWidget {
  const NearbyBookstoresPage({Key? key}) : super(key: key);

  @override
  _NearbyBookstoresPageState createState() => _NearbyBookstoresPageState();
}

class _NearbyBookstoresPageState extends State<NearbyBookstoresPage> {
  List<Bookstore> _bookstores = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchNearbyBookstores();
  }

  Future<void> _fetchNearbyBookstores() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        permission = await Geolocator.requestPermission();
        if (permission != LocationPermission.whileInUse &&
            permission != LocationPermission.always) {
          setState(() => _error = 'Location permission denied.');
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      final url = Uri.parse(
          '${AppConfig.baseUrl}/bookstores/nearby?lat=${position.latitude}&lng=${position.longitude}');

      final res = await http.get(url);

      if (res.statusCode == 200) {
        final List data = json.decode(res.body);
        setState(() {
          _bookstores = data.map((json) => Bookstore.fromJson(json)).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to fetch bookstores';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'An error occurred: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Nearby Bookstores')),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _bookstores.isEmpty
                  ? Center(child: Text('No bookstores found nearby.'))
                  : ListView.builder(
                      itemCount: _bookstores.length,
                      itemBuilder: (context, index) {
                        final store = _bookstores[index];
                        return ListTile(
                          leading: Icon(Icons.store),
                          title: Text(store.name),
                          subtitle: Text(store.address),
                        );
                      },
                    ),
    );
  }
}
