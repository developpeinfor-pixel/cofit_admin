import 'package:flutter/material.dart';

import 'core/storage/secure_storage.dart';
import 'features/auth/login/login_screen.dart';
import 'features/home/home_screen.dart';

void main() {
  runApp(const CofitAdminApp());
}

class CofitAdminApp extends StatelessWidget {
  const CofitAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SessionGate(),
    );
  }
}

class SessionGate extends StatelessWidget {
  const SessionGate({super.key});

  @override
  Widget build(BuildContext context) {
    final storage = SecureStorage();
    return FutureBuilder<String?>(
      future: storage.getToken(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final token = snapshot.data;
        if (token != null && token.isNotEmpty) {
          return const AdminHomeScreen();
        }
        return const LoginScreen();
      },
    );
  }
}
