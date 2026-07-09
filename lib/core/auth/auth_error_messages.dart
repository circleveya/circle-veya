import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;

import '../errors/exceptions.dart';
import '../errors/failures.dart';

/// Zeigt Auth-Fehler verständlich auf Deutsch an.
String formatAuthError(Object? error) {
  if (error == null) return 'Unbekannter Fehler';

  if (error is AuthFailure || error is AppAuthException) {
    return error.toString();
  }

  if (error is AuthException) {
    return _mapSupabaseAuth(error);
  }

  final text = error.toString();

  if (text.contains('Invalid login credentials') ||
      text.contains('invalid_credentials')) {
    return 'E-Mail oder Passwort ist falsch.';
  }

  if (text.contains('email_not_confirmed') ||
      text.contains('Email not confirmed')) {
    return 'Bitte bestätige zuerst deine E-Mail-Adresse (Link in deinem Postfach).';
  }

  if (text.contains('Failed to fetch') ||
      text.contains('ClientException') ||
      text.contains('AuthRetryableFetchException')) {
    return 'Verbindung zu Supabase fehlgeschlagen. Bitte Seite neu laden.';
  }

  return text.replaceFirst('Exception: ', '').trim();
}

String mapSupabaseAuthException(AuthException error) {
  return _mapSupabaseAuth(error);
}

String _mapSupabaseAuth(AuthException error) {
  final code = error.code?.toLowerCase();
  final message = error.message.toLowerCase();

  if (code == 'invalid_credentials' ||
      message.contains('invalid login credentials')) {
    return 'E-Mail oder Passwort ist falsch.';
  }

  if (code == 'email_not_confirmed' ||
      message.contains('email not confirmed')) {
    return 'Bitte bestätige zuerst deine E-Mail-Adresse (Link in deinem Postfach).';
  }

  if (code == 'user_banned' || message.contains('user is banned')) {
    return 'Dieses Konto wurde gesperrt.';
  }

  if (code == 'over_request_rate_limit') {
    return 'Zu viele Versuche. Bitte kurz warten und erneut versuchen.';
  }

  if (error.message.isNotEmpty) {
    return error.message;
  }

  return 'Anmeldung fehlgeschlagen.';
}
