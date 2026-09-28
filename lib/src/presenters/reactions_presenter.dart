import 'package:flutter/widgets.dart';

import 'reactions_menu_context.dart';

/// Shows the reactions UI for a message. Implement this for a fully custom
/// presentation (headless mode), or use `CustomPresenter`.
abstract class ReactionsPresenter {
  /// Const constructor for subclasses.
  const ReactionsPresenter();

  /// Shows the menu described by [menu]. The returned future completes after
  /// the menu has been dismissed. [context] belongs to the message.
  Future<void> show(BuildContext context, ReactionsMenuContext menu);
}
