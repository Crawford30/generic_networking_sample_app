import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:generic_networking/generic_networking.dart';

import 'api_endpoints.dart';
import 'app_session.dart';

/// Riverpod is the DI container: repositories `ref.watch` these providers,
/// and tests replace them with `overrideWithValue`.
final appSessionProvider = Provider<AppSession>((ref) => AppSession());

/// The single [NetworkingClient] the whole app shares.
final networkingClientProvider = Provider<NetworkingClient>((ref) {
  final session = ref.watch(appSessionProvider);
  return DioNetworkingClient(
    config: NetworkConfig(
      baseUrl: ApiEndpoints.baseUrl,
      applicationVersion: '1.0.0',
      applicationPlatform: defaultTargetPlatform.name,
      originCountryCode: 'KE',
      connectTimeout: const Duration(seconds: 20),
    ),
    session: session,
    unauthorizedHandler: CallbackUnauthorizedHandler((_) => session.signOut()),
  );
});

/// Riverpod 3 retries failing providers by default. Only retry errors that
/// can succeed on a second attempt; a 404 or 400 fails immediately.
Duration? retryTransientErrors(int retryCount, Object error) {
  if (retryCount >= 3) return null;
  if (error is! ApiException) return null;
  return switch (error.type) {
    NetworkErrorType.noConnection || NetworkErrorType.timeout || NetworkErrorType.server =>
      Duration(milliseconds: 500 * (1 << retryCount)),
    _ => null,
  };
}

/// User-facing text for any error surfaced by a provider.
String errorMessage(Object error) =>
    error is ApiException ? error.message : 'Something went wrong. Please try again.';
