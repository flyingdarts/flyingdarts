import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io' show Platform;
import 'dart:math';

// WebView handled via url_launcher for now
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
// JWT parsing will be done manually to avoid dependency issues
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/auth_config.dart';
import '../models/auth_state.dart';
import '../models/user_profile.dart';

/// Main client for Authress authentication
class AuthressLoginClient extends ChangeNotifier {
  static const String _tokenKey = 'authress_access_token';
  static const String _refreshTokenKey = 'authress_refresh_token';
  static const String _userProfileKey = 'authress_user_profile';
  static const String _tokenExpiryKey = 'authress_token_expiry';

  final AuthressConfiguration _config;
  AuthState _state = const AuthStateUnauthenticated();
  Timer? _tokenRefreshTimer;

  AuthressLoginClient(this._config) {
    _initializeSession();
  }

  /// Current authentication state
  AuthState get state => _state;

  /// Whether the user is currently authenticated
  bool get isAuthenticated => _state is AuthStateAuthenticated;

  /// Get the current access token if available
  String? get accessToken => _state is AuthStateAuthenticated ? (_state as AuthStateAuthenticated).accessToken : null;

  /// Get the current user profile if available
  UserProfile? get userProfile => _state is AuthStateAuthenticated ? (_state as AuthStateAuthenticated).user : null;

  /// Check if a user session exists and is valid
  Future<bool> userSessionExists() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);
      final expiryStr = prefs.getString(_tokenExpiryKey);

      if (token == null || expiryStr == null) {
        return false;
      }

      final expiry = DateTime.parse(expiryStr);
      if (DateTime.now().isAfter(expiry)) {
        // Token expired, try to refresh
        return await _refreshTokenIfAvailable();
      }

      // Validate token and load user profile
      await _loadStoredSession();
      return _state is AuthStateAuthenticated;
    } catch (e) {
      debugPrint('Error checking user session: $e');
      return false;
    }
  }

  /// Authenticate user with specified parameters
  Future<void> authenticate({
    String? connectionId,
    String? tenantLookupIdentifier,
    String? redirectUrl,
    Map<String, String>? additionalParams,
  }) async {
    _setState(const AuthStateLoading());

    try {
      final authUrl = await _getAuthenticationUrl(
        connectionId: connectionId,
        tenantLookupIdentifier: tenantLookupIdentifier,
        redirectUrl: redirectUrl ?? _config.redirectUrl,
        additionalParams: additionalParams,
      );

      developer.log(authUrl);
      developer.log('🚀 Launching authentication flow...');

      final result = await _launchWebViewFlow(authUrl);

      developer.log(
        '🔄 WebView flow completed, result: ${result != null ? 'SUCCESS' : 'NULL'}',
      );

      if (result != null) {
        developer.log('✅ Processing authentication result...');
        await _handleAuthenticationResult(result);
      } else {
        developer.log('❌ Authentication was cancelled or timed out');
        _setState(
          const AuthStateError(message: 'Authentication was cancelled'),
        );
      }
    } catch (e) {
      _setState(
        AuthStateError(
          message: 'Authentication failed: ${e.toString()}',
          error: e,
        ),
      );
    }
  }

  /// Ensure we have a valid access token, refreshing if necessary
  Future<String?> ensureToken() async {
    if (_state is AuthStateAuthenticated) {
      final authState = _state as AuthStateAuthenticated;

      if (authState.isTokenExpired || authState.willExpireSoon) {
        final refreshed = await _refreshTokenIfAvailable();
        if (!refreshed) {
          return null;
        }
      }

      return (_state as AuthStateAuthenticated).accessToken;
    }

    return null;
  }

  /// Get user profile information
  Future<UserProfile?> getUserProfile() async {
    final token = await ensureToken();
    if (token == null) return null;

    try {
      final response = await http.get(
        Uri.parse(_buildUrl('/v1/users/me')),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return UserProfile.fromJson(data);
      }
    } catch (e) {
      debugPrint('Error fetching user profile: $e');
    }

    return null;
  }

  /// Log out the current user
  Future<void> logout() async {
    _cancelTokenRefreshTimer();

    // Clear stored tokens
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_userProfileKey);
    await prefs.remove(_tokenExpiryKey);

    _setState(const AuthStateUnauthenticated());
  }

  /// Initialize session from stored data
  Future<void> _initializeSession() async {
    final sessionExists = await userSessionExists();
    if (!sessionExists) {
      _setState(const AuthStateUnauthenticated());
    }
  }

  /// Load stored session data
  Future<void> _loadStoredSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    final userProfileJson = prefs.getString(_userProfileKey);
    final expiryStr = prefs.getString(_tokenExpiryKey);
    final refreshToken = prefs.getString(_refreshTokenKey);

    if (token != null && userProfileJson != null && expiryStr != null) {
      final userProfile = UserProfile.fromJson(json.decode(userProfileJson));
      final expiry = DateTime.parse(expiryStr);

      _setState(
        AuthStateAuthenticated(
          user: userProfile,
          accessToken: token,
          refreshToken: refreshToken,
          expiresAt: expiry,
        ),
      );

      _scheduleTokenRefresh(expiry);
    }
  }

  /// Get authentication URL from Authress server (matches JavaScript implementation)
  Future<String> _getAuthenticationUrl({
    String? connectionId,
    String? tenantLookupIdentifier,
    String? redirectUrl,
    Map<String, String>? additionalParams,
  }) async {
    final selectedRedirectUrl = redirectUrl ?? _config.redirectUrl ?? '';

    // Generate PKCE codes for OAuth security
    final pkceCodes = _generatePKCECodes();

    // Calculate anti-abuse hash for security
    final antiAbuseHashProps = {
      'connectionId': connectionId,
      'tenantLookupIdentifier': tenantLookupIdentifier,
      'applicationId': _config.applicationId,
    };
    final antiAbuseHash = await _calculateAntiAbuseHash(antiAbuseHashProps);

    // Build request body exactly like JavaScript implementation
    final requestBody = {
      'antiAbuseHash': antiAbuseHash,
      'redirectUrl': selectedRedirectUrl,
      'codeChallengeMethod': 'S256',
      'codeChallenge': pkceCodes['codeChallenge'],
      'applicationId': _config.applicationId,
    };

    // Add optional parameters
    if (connectionId != null) {
      requestBody['connectionId'] = connectionId;
    }

    if (tenantLookupIdentifier != null) {
      requestBody['tenantLookupIdentifier'] = tenantLookupIdentifier;
    }

    if (additionalParams != null) {
      requestBody.addAll(additionalParams);
    }

    try {
      final uri = Uri.parse(_buildUrl('/api/authentication'));
      final headers = {
        'Content-Type': 'application/json',
        'X-Powered-By': 'Authress Login SDK; Flutter; 1.0.0',
      };
      final body = json.encode(requestBody);

      // DEBUG: Log the exact request being made
      developer.log('=== FLUTTER REQUEST DEBUG ===');
      developer.log('URL: $uri');
      developer.log('Headers: $headers');
      developer.log('Body: $body');
      developer.log('================================');

      final response = await http.post(uri, headers: headers, body: body);

      developer.log('Response Status: ${response.statusCode}');
      developer.log('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Store PKCE verifier for later use in token exchange
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          'authress_code_verifier',
          pkceCodes['codeVerifier']!,
        );

        return data['authenticationUrl'] as String;
      } else {
        throw Exception(
          'Failed to get authentication URL: ${response.statusCode} ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Failed to get authentication URL: $e');
    }
  }

  // Completer for handling authentication callbacks
  Completer<Map<String, String>?>? _authCompleter;

  /// Handle authentication callback from deep link
  /// This should be called by the consuming app when it receives an auth deep link
  Future<void> handleAuthCallback(Uri uri) async {
    developer.log('🔄 AuthClient.handleAuthCallback called with: $uri');

    if (uri.scheme == 'flyingdarts' && uri.host == 'auth') {
      final params = uri.queryParameters;
      developer.log('📋 Auth callback params: $params');

      if (_authCompleter != null && !_authCompleter!.isCompleted) {
        developer.log('✅ Completing auth flow with params');
        _authCompleter!.complete(params);
      } else {
        developer.log('⚠️  No active auth completer or already completed');
        developer.log('   - _authCompleter is null: ${_authCompleter == null}');
        developer.log(
          '   - already completed: ${_authCompleter?.isCompleted ?? 'N/A'}',
        );
      }
    } else {
      developer.log('🚫 URI scheme/host mismatch: ${uri.scheme}://${uri.host}');
    }
  }

  /// Launch WebView for authentication flow
  Future<Map<String, String>?> _launchWebViewFlow(String authUrl) async {
    developer.log('🌐 _launchWebViewFlow starting');
    _authCompleter = Completer<Map<String, String>?>();

    try {
      if (await canLaunchUrl(Uri.parse(authUrl))) {
        // Use different approaches based on platform
        if (Platform.isIOS) {
          developer.log(
            '🚀 Launching in-app WebView for iOS (prevents "Return to Safari" issue)...',
          );
          // Using inAppWebView on iOS prevents the "Return to Safari" button issue
          // The WebView will close automatically when the deep link is triggered
          await launchUrl(
            Uri.parse(authUrl),
            mode: LaunchMode.inAppWebView,
            webViewConfiguration: const WebViewConfiguration(
              enableJavaScript: true,
              enableDomStorage: true,
            ),
          );
        } else {
          developer.log('🚀 Launching external browser...');
          await launchUrl(
            Uri.parse(authUrl),
            mode: LaunchMode.externalApplication,
          );
        }

        developer.log('⏱️  Setting 5-minute timeout...');
        // Set a timeout for the authentication flow
        Timer(const Duration(minutes: 5), () {
          if (_authCompleter != null && !_authCompleter!.isCompleted) {
            developer.log('⏰ Authentication timed out');
            _authCompleter!.complete(null);
          }
        });

        developer.log('⏳ Waiting for deep link callback...');
        // Wait for the deep link callback
        final result = await _authCompleter!.future;
        developer.log(
          '📨 Deep link callback received: ${result != null ? 'SUCCESS' : 'TIMEOUT/CANCEL'}',
        );
        return result;
      } else {
        developer.log('❌ Cannot launch URL');
        _authCompleter!.complete(null);
        return null;
      }
    } catch (e) {
      developer.log('💥 Exception in _launchWebViewFlow: $e');
      if (_authCompleter != null && !_authCompleter!.isCompleted) {
        _authCompleter!.completeError(e);
      }
      rethrow;
    }
  }

  /// Handle authentication result from callback
  Future<void> _handleAuthenticationResult(Map<String, String> params) async {
    developer.log('🎯 _handleAuthenticationResult called');
    developer.log('📋 Received params: $params');

    final code = params['code'];
    final error = params['error'];
    final nonce = params['nonce'];

    if (error != null) {
      developer.log('❌ Authentication error: $error');
      throw Exception('Authentication error: $error');
    }

    if (code == null) {
      developer.log('❌ No authorization code in params');
      developer.log('📋 Available keys: ${params.keys.toList()}');
      throw Exception('No authorization code received');
    }

    if (nonce == null) {
      developer.log('❌ No nonce in params');
      developer.log('📋 Available keys: ${params.keys.toList()}');
      throw Exception('No nonce received');
    }

    developer.log('✅ Authorization code received, length: ${code.length}');
    developer.log('✅ Nonce received, length: ${nonce.length}');
    developer.log('🔄 Starting token exchange...');

    // Exchange code for tokens (JavaScript style)
    await _exchangeCodeForTokensWithNonce(code, nonce);

    developer.log('🎉 Authentication flow completed successfully!');
  }

  /// Exchange authorization code for access tokens (JavaScript-style with nonce)
  Future<void> _exchangeCodeForTokensWithNonce(
    String code,
    String nonce,
  ) async {
    // Retrieve the stored PKCE code verifier
    final prefs = await SharedPreferences.getInstance();
    final codeVerifier = prefs.getString('authress_code_verifier');

    if (codeVerifier == null) {
      throw Exception(
        'Code verifier not found - authentication flow may have been corrupted',
      );
    }

    // Calculate anti-abuse hash exactly like JavaScript
    final antiAbuseHash = await _calculateAntiAbuseHash({
      'client_id': _config.applicationId,
      'authenticationRequestId': nonce,
      'code': code,
    });

    final requestBody = {
      'grant_type': 'authorization_code',
      'redirect_uri': _config.redirectUrl ?? '',
      'client_id': _config.applicationId,
      'code': code,
      'code_verifier': codeVerifier,
      'antiAbuseHash': antiAbuseHash,
    };

    developer.log('Token exchange request body: $requestBody');

    // Use JavaScript-style endpoint: /api/authentication/{nonce}/tokens
    final response = await http.post(
      Uri.parse(_buildUrl('/api/authentication/$nonce/tokens')),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(requestBody),
    );

    // Clean up the stored code verifier
    await prefs.remove('authress_code_verifier');

    developer.log('Token exchange response status: ${response.statusCode}');
    developer.log('Token exchange response body: ${response.body}');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final accessToken = data['access_token'] as String;
      final idToken = data['id_token'] as String; // User info is in id_token!
      final refreshToken = data['refresh_token'] as String?;
      final expiresIn = data['expires_in'] as int? ?? 3600;

      developer.log('Received access token, expires in: $expiresIn seconds');

      // Decode id_token to get user info (not access_token!)
      try {
        final payload = _parseJwtPayload(idToken);
        developer.log('JWT payload from id_token: $payload');

        final userProfile = UserProfile.fromJson(payload);
        final expiresAt = DateTime.now().add(Duration(seconds: expiresIn));

        // Store tokens
        await _storeTokens(accessToken, refreshToken, userProfile, expiresAt);

        developer.log('User authenticated successfully: ${userProfile.email}');

        _setState(
          AuthStateAuthenticated(
            user: userProfile,
            accessToken: accessToken,
            refreshToken: refreshToken,
            expiresAt: expiresAt,
          ),
        );

        _scheduleTokenRefresh(expiresAt);
      } catch (e) {
        developer.log('Failed to parse JWT or create user profile: $e');
        throw Exception('Failed to process authentication token: $e');
      }
    } else {
      throw Exception(
        'Failed to exchange code for tokens: ${response.statusCode} - ${response.body}',
      );
    }
  }

  /// Store tokens securely
  Future<void> _storeTokens(
    String accessToken,
    String? refreshToken,
    UserProfile userProfile,
    DateTime expiresAt,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, accessToken);
    await prefs.setString(_userProfileKey, json.encode(userProfile.toJson()));
    await prefs.setString(_tokenExpiryKey, expiresAt.toIso8601String());

    if (refreshToken != null) {
      await prefs.setString(_refreshTokenKey, refreshToken);
    }
  }

  /// Refresh token if available
  Future<bool> _refreshTokenIfAvailable() async {
    final prefs = await SharedPreferences.getInstance();
    final refreshToken = prefs.getString(_refreshTokenKey);

    if (refreshToken == null) return false;

    try {
      final response = await http.post(
        Uri.parse(
          _buildUrl('/v1/clients/${_config.applicationId}/oauth/tokens'),
        ),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'grant_type': 'refresh_token',
          'client_id': _config.applicationId,
          'refresh_token': refreshToken,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final newAccessToken = data['access_token'] as String;
        final newRefreshToken = data['refresh_token'] as String?;
        final expiresIn = data['expires_in'] as int? ?? 3600;

        final payload = _parseJwtPayload(newAccessToken);
        final userProfile = UserProfile.fromJson(payload);
        final expiresAt = DateTime.now().add(Duration(seconds: expiresIn));

        await _storeTokens(
          newAccessToken,
          newRefreshToken ?? refreshToken,
          userProfile,
          expiresAt,
        );

        _setState(
          AuthStateAuthenticated(
            user: userProfile,
            accessToken: newAccessToken,
            refreshToken: newRefreshToken ?? refreshToken,
            expiresAt: expiresAt,
          ),
        );

        _scheduleTokenRefresh(expiresAt);
        return true;
      }
    } catch (e) {
      debugPrint('Token refresh failed: $e');
    }

    return false;
  }

  /// Schedule token refresh before expiry
  void _scheduleTokenRefresh(DateTime expiresAt) {
    _cancelTokenRefreshTimer();

    final refreshTime = expiresAt.subtract(const Duration(minutes: 5));
    final delay = refreshTime.difference(DateTime.now());

    if (delay.isNegative) return;

    _tokenRefreshTimer = Timer(delay, () async {
      await _refreshTokenIfAvailable();
    });
  }

  /// Cancel token refresh timer
  void _cancelTokenRefreshTimer() {
    _tokenRefreshTimer?.cancel();
    _tokenRefreshTimer = null;
  }

  /// Helper method to construct URLs properly (avoiding double slashes)
  String _buildUrl(String path) {
    final baseUrl = _config.authressApiUrl.endsWith('/')
        ? _config.authressApiUrl.substring(0, _config.authressApiUrl.length - 1)
        : _config.authressApiUrl;
    return '$baseUrl$path';
  }

  /// Generate PKCE codes for OAuth security (matches JavaScript implementation)
  Map<String, String> _generatePKCECodes() {
    final random = Random.secure();
    final codeVerifierBytes = List.generate(32, (_) => random.nextInt(256));
    final codeVerifier = base64Url.encode(codeVerifierBytes).replaceAll('=', '');

    // Generate code challenge using SHA256
    final bytes = utf8.encode(codeVerifier);
    final digest = sha256.convert(bytes);
    final codeChallenge = base64Url.encode(digest.bytes).replaceAll('=', '');

    return {'codeVerifier': codeVerifier, 'codeChallenge': codeChallenge};
  }

  /// Calculate anti-abuse hash (matches JavaScript proof-of-work implementation)
  Future<String> _calculateAntiAbuseHash(Map<String, String?> props) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final valueString = props.values.where((v) => v != null && v.isNotEmpty).join('|');

    developer.log('Anti-abuse hash props: $props');
    developer.log('Value string: "$valueString"');

    int fineTuner = 0;
    String hash = '';

    // Proof-of-work: find hash starting with "00"
    while (true) {
      fineTuner++;
      final input = '$timestamp;$fineTuner;$valueString';
      final bytes = utf8.encode(input);
      final digest = sha256.convert(bytes);
      hash = base64Url.encode(digest.bytes).replaceAll('=', '');

      if (hash.startsWith('00')) {
        developer.log('Anti-abuse hash found after $fineTuner iterations');
        break;
      }

      // Safety valve - don't run forever
      if (fineTuner > 100000) {
        developer.log(
          'WARNING: Anti-abuse hash calculation took more than 100k iterations',
        );
        break;
      }
    }

    final result = 'v2;$timestamp;$fineTuner;$hash';
    developer.log('Final anti-abuse hash: $result');
    return result;
  }

  /// Parse JWT payload without external dependencies
  Map<String, dynamic> _parseJwtPayload(String token) {
    final parts = token.split('.');
    if (parts.length != 3) {
      throw Exception('Invalid JWT token format');
    }

    // Decode the payload (second part)
    String payload = parts[1];

    // Add padding if needed
    switch (payload.length % 4) {
      case 2:
        payload += '==';
        break;
      case 3:
        payload += '=';
        break;
    }

    final decodedBytes = base64Decode(payload);
    final decodedString = utf8.decode(decodedBytes);
    final decodedPayload = json.decode(decodedString) as Map<String, dynamic>;

    return decodedPayload;
  }

  /// Set the authentication state and notify listeners
  void _setState(AuthState newState) {
    _state = newState;
    notifyListeners();
  }

  @override
  void dispose() {
    _cancelTokenRefreshTimer();
    super.dispose();
  }
}
