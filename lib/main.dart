import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:dekorin_apps/app.dart';
import 'package:dekorin_apps/data/datasources/local/data_preferences.dart';

void main() async {
  // Ensure flutter bindings are initialized before calling async methods
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize SharedPreferences via DataPreferences
  await DataPreferences.init();

  // Initialize locale data for Indonesian formatting
  await initializeDateFormatting('id_ID', null);

  runApp(
    // ProviderScope stores the state of all providers
    const ProviderScope(
      child: DekorinApp(),
    ),
  );
}
