import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swipic/app.dart';
import 'package:swipic/providers/app_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('onboarding appears on first launch', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      const ProviderScope(child: SwipicApp()),
    );
    await tester.pumpAndSettle();
    expect(find.text('Swipic'), findsWidgets);
    expect(find.text('继续并授权'), findsOneWidget);
  });

  testWidgets('home appears after onboarding complete', (tester) async {
    SharedPreferences.setMockInitialValues({
      'swipic_permissions_requested': true,
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          useDemoLibraryProvider.overrideWith((ref) => true),
        ],
        child: const SwipicApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('相册'), findsOneWidget);
    expect(find.text('相似与重复'), findsOneWidget);
    expect(find.text('待删除'), findsOneWidget);
  });
}
