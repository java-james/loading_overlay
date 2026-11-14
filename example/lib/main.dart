// Keep this example compatible with the library's SDK Material widgets.
// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:loading_overlay/loading_overlay.dart';
import 'dart:async';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'loading_overlay demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: LoginPage(onSignIn: () => debugPrint('login successful!')),
    );
  }
}

class LoginPage extends StatefulWidget {
  final VoidCallback onSignIn;

  const LoginPage({super.key, required this.onSignIn});

  @override
  LoginPageState createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> signIn() async {
    // Also guard keyboard activation and taps before the next frame is drawn.
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;
    widget.onSignIn();

    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Optionally can use [LoadingOverlay.withFuture] and pass in the Future from signIn too!
      body: LoadingOverlay(
        color: const Color(0x80000000),
        isLoading: _isLoading,
        child: SafeArea(
          child: Column(
            children: [
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: 'Username'),
              ),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
              ElevatedButton(onPressed: signIn, child: const Text('Login')),
            ],
          ),
        ),
      ),
    );
  }
}
