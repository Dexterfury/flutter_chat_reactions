import 'package:example/main.dart';
import 'package:flutter_chat_reactions/flutter_chat_reactions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('long-press a message and react', (tester) async {
    await tester.pumpWidget(const ExampleApp());
    await tester.longPress(
      find.text('Long-press (or right-click) a message to react.'),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('😂'));
    await tester.pumpAndSettle();
    expect(find.byType(ReactionsSummaryView), findsWidgets);
    expect(find.text('😂'), findsOneWidget);
  });
}
