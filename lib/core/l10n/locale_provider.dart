import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kLocaleKey = 'app_locale';

class LocaleController extends Notifier<Locale> {
  @override
  Locale build() {
    // Sync load; hydrate async after first frame
    Future.microtask(_hydrate);
    return const Locale('de', 'CH');
  }

  Future<void> _hydrate() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_kLocaleKey);
    if (code == null || code.isEmpty) return;
    final next = _fromCode(code);
    if (next.languageCode != state.languageCode) {
      state = next;
    }
  }

  Future<void> setLocale(Locale locale) async {
    state = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLocaleKey, locale.languageCode);
  }

  Locale _fromCode(String code) {
    if (code.startsWith('en')) return const Locale('en');
    return const Locale('de', 'CH');
  }
}

final localeProvider = NotifierProvider<LocaleController, Locale>(
  LocaleController.new,
);
