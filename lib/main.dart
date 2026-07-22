import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'core/config/env.dart';
import 'core/network/supabase_client.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  await initializeDateFormatting('de_CH');
  await initializeDateFormatting('de');

  if (Env.isConfigured) {
    await initializeSupabase();
  }

  runApp(
    const ProviderScope(
      child: CircleApp(),
    ),
  );
}
