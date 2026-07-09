import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:circle/app.dart';

void main() {
  testWidgets('CircleApp startet ohne Supabase-Konfiguration', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: CircleApp(),
      ),
    );

    expect(find.text('Willkommen bei Circle'), findsOneWidget);
  });
}
