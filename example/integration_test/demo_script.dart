import 'package:example/app/demo_id.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_reactions/flutter_chat_reactions.dart';
import 'package:flutter_test/flutter_test.dart';

/// Waits [duration]: fake time in widget tests, real time when recording.
typedef Pace = Future<void> Function(Duration duration);

/// A scripted interaction for one demo.
typedef DemoScript = Future<void> Function(WidgetTester tester, Pace pace);

/// Pause between steps.
const Duration beat = Duration(milliseconds: 700);

/// Pause at the end so the final state is visible in recordings.
const Duration linger = Duration(milliseconds: 1500);

/// Scripts for every demo that has one.
final Map<DemoId, DemoScript> demoScripts = {
  DemoId.quickStart: _quickStart,
  DemoId.messenger: _messenger,
};

/// Runs [id]'s script.
Future<void> runDemoScript(
  WidgetTester tester,
  DemoId id, {
  required Pace pace,
}) => demoScripts[id]!(tester, pace);

/// The visible body of message [id].
Finder messageFinder(String id) => find.byKey(ValueKey('msg-$id'));

/// The reactions summary of message [id].
Finder summaryFinder(String id) => find.byKey(ValueKey('summary-$id'));

/// [emoji] inside the open reaction bar. Shortcodes (`:x:`) are found by
/// their `emoji-<shortcode>` key, unicode emoji by text.
Finder reactionInBar(String emoji) => find.descendant(
  of: find.byType(ReactionBar),
  matching: emoji.startsWith(':')
      ? find.byKey(ValueKey('emoji-$emoji'))
      : find.text(emoji),
);

/// Long-presses message [id] to open its reactions menu.
Future<void> openMenu(WidgetTester tester, String id, Pace pace) async {
  await tester.longPress(messageFinder(id));
  await pace(beat);
}

/// Taps [finder] and waits a beat.
Future<void> tapAndPace(WidgetTester tester, Finder finder, Pace pace) async {
  await tester.tap(finder);
  await pace(beat);
}

/// Asserts that [matching] is shown in message [id]'s summary.
void expectInSummary(String id, Finder matching) => expect(
  find.descendant(of: summaryFinder(id), matching: matching),
  findsOneWidget,
);

Future<void> _quickStart(WidgetTester tester, Pace pace) async {
  await pace(beat);
  await openMenu(tester, 'm1', pace);
  await tapAndPace(tester, reactionInBar('😂'), pace);
  expectInSummary('m1', find.text('😂'));
  await openMenu(tester, 'm1', pace);
  await tapAndPace(tester, reactionInBar('😮'), pace);
  expectInSummary('m1', find.text('😮'));
  await pace(linger);
}

Future<void> _messenger(WidgetTester tester, Pace pace) async {
  await pace(beat);
  // Priya's message already has your ❤️: pick 😂 to replace it.
  await openMenu(tester, 'm3', pace);
  await tapAndPace(tester, reactionInBar('😂'), pace);
  expectInSummary('m3', find.text('😂'));
  // Change your mind.
  await openMenu(tester, 'm3', pace);
  await tapAndPace(tester, reactionInBar('😮'), pace);
  expectInSummary('m3', find.text('😮'));
  // Run an action: delete your own message.
  await openMenu(tester, 'm5', pace);
  await tapAndPace(tester, find.text('Delete'), pace);
  expect(messageFinder('m5'), findsNothing);
  await pace(linger);
}
