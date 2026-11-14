/// Centralized configuration and version definitions for the Tasco Shell host.
///
/// This serves as the single source of truth for the framework version across
/// the shell, eliminating disparate hardcoded strings and allowing CI parity
/// gates to verify alignment with release tags. The app's own version is not
/// kept here: `ClientIdentity` reads it from the installed package.
abstract final class AppConfig {
  /// The framework version of this host shell.
  ///
  /// This version is communicated to Web Mini-Apps via [WebMiniAppDependencies.hostVersion]
  /// to enforce bundle manifest `minHostVersion` constraints (ADR-0020).
  ///
  /// Enforced to match the release tag by `scripts/check_constraint_parity.sh`.
  static const String frameworkVersion = '5.2.7';
}
