import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../routes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    Timer(const Duration(seconds: 2), () {
      final user = AuthService().currentUser;

      if (!mounted) return;

      if (user == null) {
        Navigator.pushReplacementNamed(context, Routes.login);
      } else {
        Navigator.pushReplacementNamed(context, Routes.home);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(
                Icons.favorite,
                size: 76,
                color: Color(0xFFE53935),
              ),
              SizedBox(height: 14),
              Text(
                'sparks',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'connections beyond classrooms',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),
              SizedBox(height: 22),
              CircularProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}
