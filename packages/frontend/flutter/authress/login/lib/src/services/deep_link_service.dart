import 'dart:async';

import 'package:app_links/app_links.dart';

import '../models/deep_link_config.dart';

/// Service for handling deep links with configurable schemes and timeouts
class DeepLinkService {
  final DeepLinkConfig _config;
  final AppLinks _appLinks;

  StreamSubscription<Uri>? _linkSubscription;
  Completer<Map<String, String>?>? _authCompleter;
  Timer? _timeoutTimer;

  /// Create a DeepLinkService with optional AppLinks injection for testing
  /// If [appLinks] is not provided, creates a default AppLinks instance
  DeepLinkService([
    this._config = const DeepLinkConfig(),
    AppLinks? appLinks,
  ]) : _appLinks = appLinks ?? AppLinks();

  /// Initialize deep link handling
  Future<void> initialize() async {
    try {
      // Handle initial link when app is opened from deep link
      final initialLink = await _appLinks.getInitialLink();
      if (initialLink != null) {
        _processDeepLink(initialLink);
      }

      // Listen to ongoing links while app is running
      _linkSubscription = _appLinks.uriLinkStream.listen(
        _processDeepLink,
        onError: (error) {
          _completeWithError('Deep link error: $error');
        },
      );
    } catch (e) {}
  }

  /// Wait for an authentication deep link with timeout
  Future<Map<String, String>?> waitForAuthCallback() async {
    if (_authCompleter != null && !_authCompleter!.isCompleted) {
      _authCompleter!.complete(null);
    }

    _authCompleter = Completer<Map<String, String>?>();

    // Set timeout
    _timeoutTimer = Timer(_config.timeoutDuration, () {
      if (_authCompleter != null && !_authCompleter!.isCompleted) {
        _authCompleter!.complete(null);
      }
    });

    return _authCompleter!.future;
  }

  /// Process incoming deep link
  void _processDeepLink(Uri uri) {
    if (!_config.matches(uri)) {
      return;
    }

    final params = uri.queryParameters;

    if (_authCompleter != null && !_authCompleter!.isCompleted) {
      _timeoutTimer?.cancel();
      _authCompleter!.complete(params);
    }
  }

  /// Complete auth flow with error
  void _completeWithError(String error) {
    if (_authCompleter != null && !_authCompleter!.isCompleted) {
      _timeoutTimer?.cancel();
      _authCompleter!.completeError(Exception(error));
    }
  }

  /// Cancel any ongoing auth flow
  void cancelAuthFlow() {
    if (_authCompleter != null && !_authCompleter!.isCompleted) {
      _timeoutTimer?.cancel();
      _authCompleter!.complete(null);
    }
  }

  /// Get the callback URL for this service
  String get callbackUrl => _config.callbackUrl;

  void dispose() {
    _timeoutTimer?.cancel();
    _linkSubscription?.cancel();
    if (_authCompleter != null && !_authCompleter!.isCompleted) {
      _authCompleter!.complete(null);
    }
  }
}
