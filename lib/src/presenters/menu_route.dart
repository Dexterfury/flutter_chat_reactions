import 'dart:ui' show ImageFilter;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'reactions_menu_context.dart';

/// Transparent popup route used by the built-in presenters. Provides the
/// barrier (tap outside), Escape, system back and focus trapping via
/// [ModalRoute], plus an animated tint and blur.
class ReactionsMenuRoute extends PopupRoute<void> {
  /// Creates the route.
  ReactionsMenuRoute({
    required this.menu,
    required this.builder,
    required this.duration,
    required this.curve,
    required String barrierLabel,
    this.barrierTint,
    this.blurSigma = 0,
  }) : _barrierLabel = barrierLabel;

  /// The menu this route shows.
  final ReactionsMenuContext menu;

  /// Builds the content; the animation is already curved.
  final Widget Function(BuildContext context, Animation<double> animation)
  builder;

  /// Transition duration.
  final Duration duration;

  /// Transition curve.
  final Curve curve;

  /// Tint painted behind the content (animated).
  final Color? barrierTint;

  /// Backdrop blur (animated); 0 disables.
  final double blurSigma;

  final String _barrierLabel;

  @override
  Color? get barrierColor => null;

  @override
  bool get barrierDismissible => true;

  @override
  String? get barrierLabel => _barrierLabel;

  @override
  Duration get transitionDuration => duration;

  @override
  Duration get reverseTransitionDuration => duration;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    final curved = CurvedAnimation(parent: animation, curve: curve);
    final tint = barrierTint;
    return _DismissOnResize(
      onResize: menu.dismiss,
      child: Stack(
        children: [
          if (tint != null || blurSigma > 0)
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: curved,
                  builder: (context, _) {
                    final t = curved.value;
                    Widget layer = ColoredBox(
                      color: (tint ?? const Color(0x00000000)).withValues(
                        alpha: (tint?.a ?? 0) * t,
                      ),
                    );
                    if (blurSigma > 0) {
                      layer = BackdropFilter(
                        filter: ImageFilter.blur(
                          sigmaX: blurSigma * t,
                          sigmaY: blurSigma * t,
                        ),
                        child: layer,
                      );
                    }
                    return layer;
                  },
                ),
              ),
            ),
          Positioned.fill(child: builder(context, curved)),
        ],
      ),
    );
  }
}

/// Pushes [route] on the root navigator and wires [menu.dismiss] to close it.
Future<void> showReactionsMenuRoute(
  BuildContext context,
  ReactionsMenuContext menu,
  ReactionsMenuRoute route,
) {
  final navigator = Navigator.of(context, rootNavigator: true);
  menu.setDismissHandler(() => closeRouteSafely(navigator, route));
  return navigator.push(route);
}

/// Pops [route] if it is still active, deferring when the tree is locked
/// (e.g. when called from `dispose`).
void closeRouteSafely(NavigatorState navigator, Route<dynamic> route) {
  void close() {
    if (!route.isActive || !navigator.mounted) return;
    if (route.isCurrent) {
      navigator.pop();
    } else {
      navigator.removeRoute(route);
    }
  }

  final phase = SchedulerBinding.instance.schedulerPhase;
  if (phase == SchedulerPhase.persistentCallbacks ||
      phase == SchedulerPhase.midFrameMicrotasks) {
    SchedulerBinding.instance.addPostFrameCallback((_) => close());
  } else {
    close();
  }
}

class _DismissOnResize extends StatefulWidget {
  const _DismissOnResize({required this.onResize, required this.child});

  final VoidCallback onResize;
  final Widget child;

  @override
  State<_DismissOnResize> createState() => _DismissOnResizeState();
}

class _DismissOnResizeState extends State<_DismissOnResize> {
  Size? _initial;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final size = MediaQuery.sizeOf(context);
    final initial = _initial ??= size;
    if (size != initial) {
      SchedulerBinding.instance.addPostFrameCallback((_) => widget.onResize());
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
