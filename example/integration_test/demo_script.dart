import 'package:example/app/demo_id.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_reactions/flutter_chat_reactions.dart';
import 'package:flutter_test/flutter_test.dart';

/// Platforms where the reactions menu's default trigger is a long press.
const _touchPlatforms = {
  TargetPlatform.iOS,
  TargetPlatform.android,
  TargetPlatform.fuchsia,
};

/// Waits [duration]: fake time in widget tests, real time when recording.
typedef Pace = Future<void> Function(Duration duration);

/// A scripted interaction for one demo.
typedef DemoScript = Future<void> Function(WidgetTester tester, Pace pace);

/// Pause between steps.
const Duration beat = Duration(milliseconds: 700);

/// Pause at the end so the final state is visible in recordings.
const Duration linger = Duration(milliseconds: 1500);

/// Whether the scripts' pointer events are dispatched as *device* events
/// rather than *test* events.
///
/// flutter_test's live binding paints a crosshair marker for every pointer
/// that goes down with source [TestBindingEventSource.test] (what
/// [WidgetTester.tap] and friends use), and those markers end up in the
/// recorded GIFs. Device events are not painted.
///
/// Only set this when the binding delivers device events to the app, i.e.
/// [LiveTestWidgetsFlutterBinding.shouldPropagateDevicePointerEvents] is true
/// (the live runner, `demo_script_test.dart`, does both). Otherwise the live
/// binding drops the events and no gesture reaches the app. Leave it false in
/// fake-time widget tests.
bool hideTouchIndicators = false;

/// Pointer ids for [hideTouchIndicators] gestures: well clear of the ids
/// [WidgetTester] hands out (which start at 1), and unique per gesture.
int _nextDevicePointer = 1000;

/// Puts a pointer down at [location]; see [hideTouchIndicators].
Future<TestGesture> _startGesture(
  WidgetTester tester,
  Offset location, {
  PointerDeviceKind kind = PointerDeviceKind.touch,
  int buttons = kPrimaryButton,
}) async {
  if (!hideTouchIndicators) {
    return tester.startGesture(location, kind: kind, buttons: buttons);
  }
  final binding = tester.binding;
  assert(
    binding is! LiveTestWidgetsFlutterBinding ||
        binding.shouldPropagateDevicePointerEvents,
    'hideTouchIndicators needs shouldPropagateDevicePointerEvents = true',
  );
  final gesture = TestGesture(
    dispatcher: (event) async => binding.handlePointerEventForSource(
      event,
      source: TestBindingEventSource.device,
    ),
    pointer: _nextDevicePointer++,
    kind: kind,
    buttons: buttons,
  );
  await gesture.down(location);
  return gesture;
}

/// Taps [location]: [WidgetTester.tapAt], or a device-event tap when
/// [hideTouchIndicators] is set.
Future<void> _tapAt(WidgetTester tester, Offset location) async {
  if (!hideTouchIndicators) return tester.tapAt(location);
  final gesture = await _startGesture(tester, location);
  await gesture.up();
}

/// Taps the center of [finder]: [WidgetTester.tap], or a device-event tap
/// when [hideTouchIndicators] is set.
Future<void> _tap(
  WidgetTester tester,
  Finder finder, {
  PointerDeviceKind kind = PointerDeviceKind.touch,
  int buttons = kPrimaryButton,
}) async {
  if (!hideTouchIndicators) {
    return tester.tap(finder, kind: kind, buttons: buttons);
  }
  final gesture = await _startGesture(
    tester,
    tester.getCenter(finder),
    kind: kind,
    buttons: buttons,
  );
  await gesture.up();
}

/// Scripts for every demo that has one.
final Map<DemoId, DemoScript> demoScripts = {
  DemoId.quickStart: _quickStart,
  DemoId.messenger: _messenger,
  DemoId.team: _team,
  DemoId.telegram: _telegram,
  DemoId.custom: _custom,
  DemoId.theming: _theming,
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

/// Opens message [id]'s reactions menu: long-press on touch platforms,
/// right-click (the default trigger there) on desktop platforms. Scrolls the
/// message into view first, so scripts also work on small phones.
Future<void> openMenu(WidgetTester tester, String id, Pace pace) async {
  await tester.ensureVisible(messageFinder(id));
  await tester.pumpAndSettle();
  final platform = Theme.of(tester.element(messageFinder(id))).platform;
  if (_touchPlatforms.contains(platform)) {
    // Hold the pointer down for a fixed duration via `pace` (fake time in
    // widget tests, real time when recording), comfortably past
    // kLongPressTimeout.
    final gesture = await _startGesture(
      tester,
      tester.getCenter(messageFinder(id)),
    );
    await pace(const Duration(milliseconds: 800));
    await gesture.up();
  } else {
    await _tap(
      tester,
      messageFinder(id),
      buttons: kSecondaryButton,
      kind: PointerDeviceKind.mouse,
    );
  }
  await pace(beat);
  expect(
    _menuIsOpen(),
    isTrue,
    reason:
        'menu did not open for $id on $platform '
        '(message at ${tester.getRect(messageFinder(id).first)})',
  );
}

/// Whether a reactions menu is showing, for any presenter the demos use: the
/// focused overlay and compact bar show a [ReactionBar], the bottom sheet
/// shows one inside the sheet, and the custom demo's radial menu shows items
/// keyed `radial-<emoji>`.
bool _menuIsOpen() =>
    find.byType(ReactionBar).evaluate().isNotEmpty ||
    find.byType(BottomSheet).evaluate().isNotEmpty ||
    find
        .byWidgetPredicate(
          (widget) =>
              widget.key is ValueKey<String> &&
              (widget.key! as ValueKey<String>).value.startsWith('radial-'),
        )
        .evaluate()
        .isNotEmpty;

/// Taps [finder] and waits a beat.
Future<void> tapAndPace(WidgetTester tester, Finder finder, Pace pace) async {
  await _tap(tester, finder);
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

Future<void> _team(WidgetTester tester, Pace pace) async {
  await pace(beat);
  await openMenu(tester, 'm1', pace);
  await tapAndPace(tester, reactionInBar('🎉'), pace);
  await openMenu(tester, 'm1', pace);
  await tapAndPace(tester, reactionInBar(':party:'), pace);
  // Multiple reactions per user: both stay.
  expectInSummary('m1', find.text('🎉'));
  expectInSummary('m1', find.byKey(const ValueKey('emoji-:party:')));
  // Tap an existing chip to +1 it.
  await tapAndPace(
    tester,
    find.descendant(of: summaryFinder('m2'), matching: find.text('👍')),
    pace,
  );
  expectInSummary('m2', find.text('3'));
  await pace(linger);
}

Future<void> _telegram(WidgetTester tester, Pace pace) async {
  await pace(beat);
  // The sheet shows who reacted before you pick.
  await openMenu(tester, 'm2', pace);
  await pace(beat);
  await tapAndPace(tester, reactionInBar('🙏'), pace);
  expectInSummary('m2', find.text('🙏'));
  // Run an action: pin a message.
  await openMenu(tester, 'm1', pace);
  await tapAndPace(tester, find.text('Pin'), pace);
  expect(find.byKey(const ValueKey('pinned-banner')), findsOneWidget);
  await pace(linger);
}

Future<void> _custom(WidgetTester tester, Pace pace) async {
  await pace(beat);
  await openMenu(tester, 'm2', pace);
  await pace(beat);
  await tapAndPace(tester, find.byKey(const ValueKey('radial-🙏')), pace);
  expectInSummary('m2', find.text('🙏'));
  await openMenu(tester, 'm3', pace);
  await tapAndPace(tester, find.byKey(const ValueKey('radial-😂')), pace);
  expectInSummary('m3', find.text('😂'));
  await pace(linger);
}

Future<void> _theming(WidgetTester tester, Pace pace) async {
  await pace(beat);
  await openMenu(tester, 'm1', pace);
  await tapAndPace(tester, reactionInBar('❤️'), pace);
  // Switch to the opposite of the starting brightness, so light and dark
  // recordings both show a switch.
  final startsDark =
      Theme.of(tester.element(messageFinder('m1'))).brightness ==
      Brightness.dark;
  await tapAndPace(
    tester,
    find.descendant(
      of: find.byKey(const ValueKey('control-brightness')),
      matching: find.text(startsDark ? 'Light' : 'Dark'),
    ),
    pace,
  );
  await tapAndPace(
    tester,
    find.descendant(
      of: find.byKey(const ValueKey('control-style')),
      matching: find.text('Cupertino'),
    ),
    pace,
  );
  await openMenu(tester, 'm1', pace);
  await pace(beat);
  await tapAndPace(tester, reactionInBar('😮'), pace);
  expectInSummary('m1', find.text('😮'));
  await tapAndPace(tester, find.byKey(const ValueKey('control-rtl')), pace);
  await openMenu(tester, 'm2', pace);
  await pace(linger);
  // Dismiss by tapping the barrier near the view's bottom-left corner.
  final size = tester.view.physicalSize / tester.view.devicePixelRatio;
  await _tapAt(tester, Offset(8, size.height - 8));
  await pace(beat);
  expect(find.byType(ReactionBar), findsNothing);
}
