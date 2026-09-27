import 'package:example/app/demo_id.dart';
import 'package:example/app/gallery_app.dart';
import 'package:example/widgets/bubble_row.dart';
import 'package:example/widgets/demo_chat_model.dart';
import 'package:example/widgets/message_actions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_reactions/flutter_chat_reactions.dart';

/// Live controls for brightness, visual style, seed colour, text scale and
/// text direction, applied to a preview chat (the menus follow the preview's
/// Theme because presenters capture the message's inherited themes).
class ThemingDemo extends StatefulWidget {
  /// Creates the demo.
  const ThemingDemo({super.key});

  @override
  State<ThemingDemo> createState() => _ThemingDemoState();
}

class _ThemingDemoState extends State<ThemingDemo> {
  static const List<Color> _seeds = [
    Colors.indigo,
    Colors.teal,
    Colors.pink,
    Colors.orange,
  ];

  final _chat = DemoChatModel();
  late Brightness _brightness;
  bool _brightnessSeeded = false;
  ReactionsVisualStyle _style = ReactionsVisualStyle.adaptive;
  Color _seed = Colors.indigo;
  double _textScale = 1;
  bool _rtl = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Start from the app's brightness (e.g. THEME=dark); the toggle owns it
    // afterwards.
    if (!_brightnessSeeded) {
      _brightnessSeeded = true;
      _brightness = Theme.of(context).brightness;
    }
  }

  @override
  void dispose() {
    _chat.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final previewTheme = buildTheme(
      _brightness,
      seed: _seed,
    ).copyWith(extensions: [ChatReactionsTheme(style: _style)]);
    return Scaffold(
      appBar: AppBar(title: Text(DemoId.theming.title)),
      body: Column(
        children: [
          _controls(context),
          const Divider(height: 1),
          Expanded(
            child: Theme(
              data: previewTheme,
              child: Builder(
                builder: (context) => MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: TextScaler.linear(_textScale)),
                  child: Directionality(
                    textDirection: _rtl ? TextDirection.rtl : TextDirection.ltr,
                    child: ColoredBox(
                      color: Theme.of(context).colorScheme.surface,
                      child: ListenableBuilder(
                        listenable: _chat,
                        builder: (context, _) => ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            for (final message in _chat.messages)
                              BubbleRow(
                                message: message,
                                chat: _chat,
                                actionsFor: actionsFor,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _controls(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SegmentedButton<Brightness>(
            key: const ValueKey('control-brightness'),
            segments: const [
              ButtonSegment(
                value: Brightness.light,
                icon: Icon(Icons.light_mode_outlined),
                label: Text('Light'),
              ),
              ButtonSegment(
                value: Brightness.dark,
                icon: Icon(Icons.dark_mode_outlined),
                label: Text('Dark'),
              ),
            ],
            selected: {_brightness},
            onSelectionChanged: (s) => setState(() => _brightness = s.first),
          ),
          SegmentedButton<ReactionsVisualStyle>(
            key: const ValueKey('control-style'),
            segments: const [
              ButtonSegment(
                value: ReactionsVisualStyle.adaptive,
                label: Text('Adaptive'),
              ),
              ButtonSegment(
                value: ReactionsVisualStyle.material,
                label: Text('Material'),
              ),
              ButtonSegment(
                value: ReactionsVisualStyle.cupertino,
                label: Text('Cupertino'),
              ),
            ],
            selected: {_style},
            onSelectionChanged: (s) => setState(() => _style = s.first),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < _seeds.length; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: InkResponse(
                    key: ValueKey('control-seed-$i'),
                    onTap: () => setState(() => _seed = _seeds[i]),
                    child: CircleAvatar(
                      radius: 13,
                      backgroundColor: _seeds[i],
                      child: _seeds[i] == _seed
                          ? const Icon(
                              Icons.check,
                              size: 14,
                              color: Colors.white,
                            )
                          : null,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(
            width: 240,
            child: Row(
              children: [
                Text('Text ${_textScale.toStringAsFixed(2)}×'),
                Expanded(
                  child: Slider(
                    key: const ValueKey('control-text-scale'),
                    min: 1,
                    max: 2,
                    divisions: 4,
                    value: _textScale,
                    onChanged: (v) => setState(() => _textScale = v),
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('RTL'),
              Switch(
                key: const ValueKey('control-rtl'),
                value: _rtl,
                onChanged: (v) => setState(() => _rtl = v),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
