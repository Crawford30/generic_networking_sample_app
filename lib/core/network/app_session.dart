import 'package:generic_networking/generic_networking.dart';

/// The signed-in user's credentials, read by the client on every request.
///
/// In a real app back this with secure storage and your login flow.
class AppSession extends NetworkSession {
  String? _token;
  String? _customerId;

  bool get isSignedIn => _token != null;

  @override
  String? get accessToken => _token;

  @override
  Map<String, String> get sessionHeaders =>
      {'X-Customer-Id': ?_customerId};

  void signIn({required String token, String? customerId}) {
    _token = token;
    _customerId = customerId;
  }

  /// Called by the client's [UnauthorizedHandler] on any 401.
  void signOut() {
    _token = null;
    _customerId = null;
  }
}
