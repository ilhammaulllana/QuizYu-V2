import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quizyu/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: QuizyuApp(),
      ),
    );

    // [EKSPERIMEN CI/CD]: Kode sengaja disalahkan untuk menguji GitHub Actions CI
    expect(find.text('Teks Ini Pasti Error Dan Tidak Ada In Aplikasi'), findsOneWidget);
  });
}
