import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'config.dart';
import 'home.dart'; 

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nickController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isSubmitting = false;

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final nick = _nickController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    setState(() => _isSubmitting = true);

    try {
      // Register user
      final registerRes = await http.post(
        Uri.parse('${AppConfig.baseUrl}/users/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'nick': nick, 'email': email, 'password': password}),
      );

      if (registerRes.statusCode != 201) {
        final err = jsonDecode(registerRes.body);
        throw Exception(err['error'] ?? 'Registration failed.');
      }

      // Auto-login
      final loginRes = await http.post(
        Uri.parse('${AppConfig.baseUrl}/users/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (loginRes.statusCode == 200) {
        final data = jsonDecode(loginRes.body);

        // saving data in "local storage"
        final prefs = await  SharedPreferences.getInstance();
        await prefs.setString('token', data['token']);
        await prefs.setString('nick', data['nick']);
        await prefs.setString('id', data['id']);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Welcome ${data['nick']}!')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      } else {
        final body = jsonDecode(loginRes.body);
        throw Exception(body['error'] ?? 'Login failed after registration.');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Register'),
        backgroundColor: color,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const SizedBox(height: 24),
              TextFormField(
                controller: _nickController,
                decoration: const InputDecoration(
                  labelText: 'Nickname',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) =>
                    value != null && value.length >= 2 ? null : 'Enter a nickname',
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) =>
                    value != null && value.contains('@') ? null : 'Enter a valid email',
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
                validator: (value) =>
                    value != null && value.length >= 6 ? null : 'Password must be at least 6 characters',
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmPasswordController,
                decoration: const InputDecoration(
                  labelText: 'Confirm Password',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                obscureText: true,
                validator: (value) => value == _passwordController.text
                    ? null
                    : 'Passwords do not match',
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _handleRegister,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(_isSubmitting ? 'Registering...' : 'Register'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
