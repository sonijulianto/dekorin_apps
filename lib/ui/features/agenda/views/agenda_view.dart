import 'package:flutter/material.dart';
import 'package:dekorin_apps/config/theme/app_theme.dart';

class AgendaView extends StatelessWidget {
  const AgendaView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_month, size: 80, color: AppTheme.primaryGold),
            SizedBox(height: 16),
            Text(
              'Agenda',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('Fitur kalender booking akan hadir di sini.'),
          ],
        ),
      ),
    );
  }
}
