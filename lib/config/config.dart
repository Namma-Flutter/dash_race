/// Server config for the game display (host), read at BUILD TIME from
/// `--dart-define` values (Flutter has no runtime `.env`).
///
/// Provide them one of these ways:
///   • local:  flutter run  -d chrome --dart-define-from-file=dart_defines.json
///   • Vercel: vercel-build.sh maps the project's env vars into --dart-define
///
/// The access password is NOT here — it's entered at runtime on the host screen
/// and validated by Nakama, so the secret never ships in the built web app.
/// (host/port/ssl/serverKey ARE baked into the bundle; none of them is secret.)
class ServerConfig {
  ServerConfig._();

  /// Domain / IP of your Nakama server.
  static const String host =
      String.fromEnvironment('NAKAMA_HOST', defaultValue: 'localhost');

  /// Nakama client API port. MUST match the controller's VITE_NAKAMA_PORT.
  /// 443 when fronted by nginx/Caddy TLS; 7350 for direct / IP testing.
  static const int port =
      int.fromEnvironment('NAKAMA_PORT', defaultValue: 7350);

  /// true  -> wss/https (REQUIRED when the web app itself is served over HTTPS)
  /// false -> ws/http   (only for quick local / IP testing)
  static const bool useSsl =
      bool.fromEnvironment('NAKAMA_SSL', defaultValue: false);

  /// Must equal `socket.server_key` in the server's local.yml.
  static const String serverKey =
      String.fromEnvironment('NAKAMA_SERVER_KEY', defaultValue: 'defaultkey');

  /// This build is the game display / host (it runs the physics sim).
  static const String role = 'host';

  /// URL of the hosted React controller that players open on their phones.
  /// Shown as the lobby QR code. For local testing point it at the Vite dev
  /// server on your LAN IP (e.g. http://192.168.0.6:5173).
  static const String controllerUrl = String.fromEnvironment(
    'CONTROLLER_URL',
    defaultValue: 'http://localhost:5173',
  );
}
