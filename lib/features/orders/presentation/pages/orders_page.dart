import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📑 Замовлення клієнта'),
        backgroundColor: AppTheme.accentColor,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.accentColor.withOpacity(0.1), Colors.transparent],
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.shopping_cart, size: 120, color: AppTheme.accentColor),
              SizedBox(height: 24),
              Text(
                'Замовлення клієнта',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.accentColor,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Функція в розробці',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
              SizedBox(height: 32),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  'Тут буде функціонал для управління замовленнями клієнтів, включаючи створення, редагування та відстеження статусу замовлень.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
