import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../core/storage/secure_storage.dart';
import '../../home/home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final apiClient = ApiClient();
  final storage = SecureStorage();

  bool isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> login() async {
    setState(() => isLoading = true);

    try {
      final response = await apiClient.dio.post(
        '/auth/login',
        data: {
          'email': emailController.text.trim(),
          'password': passwordController.text,
        },
      );

      final token = response.data['access_token'];
      final user = response.data['user'];
      final role = user is Map<String, dynamic> ? user['role'] : null;
      if (token is! String || token.isEmpty) {
        throw DioException(
          requestOptions: response.requestOptions,
          error: 'Token manquant dans la reponse',
        );
      }

      await storage.saveToken(token);
      if (role is String && role.isNotEmpty) {
        await storage.saveRole(role);
      }

      if (!mounted) {
        return;
      }
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AdminHomeScreen()),
        (route) => false,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login admin reussi')),
      );
    } on DioException catch (e) {
      final responseData = e.response?.data;
      final message =
          responseData is Map<String, dynamic> && responseData['message'] != null
              ? responseData['message'].toString()
              : (responseData?.toString() ?? 'Login echoue');

      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $message')),
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Login')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 30),
            isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: login,
                    child: const Text('Se connecter'),
                  ),
          ],
        ),
      ),
    );
  }
}
