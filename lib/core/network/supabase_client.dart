import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/env.dart';

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

Future<void> initializeSupabase() async {
  if (!Env.isConfigured) {
    throw StateError(
      'Supabase ist nicht konfiguriert. Bitte SUPABASE_URL und '
      'SUPABASE_ANON_KEY als --dart-define übergeben.',
    );
  }

  await Supabase.initialize(
    url: Env.supabaseUrl.trim(),
    publishableKey: Env.supabaseAnonKey.trim(),
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );
}
