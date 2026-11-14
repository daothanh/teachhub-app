import 'package:flutter/widgets.dart';

import 'generated/mini_app_localizations.dart';

export 'generated/mini_app_localizations.dart';

extension MiniAppLocalizationsX on BuildContext {
  MiniAppLocalizations get miniAppL10n => MiniAppLocalizations.of(this);
}
