/// Central place for Dash Race server credentials (the game display / host).
///
/// Fill these in with your Linode Nakama server details. When you later move
/// the server to a Raspberry Pi, usually only [host] (and maybe [port]/[useSsl])
/// changes — nothing else.
///
/// NOTE: the access password is NOT stored here. It is entered at runtime on
/// the host screen and validated by the Nakama server, so the secret never
/// ships inside the built web app.
class ServerConfig {
  ServerConfig._();

  // ---------------------------------------------------------------------------
  // Nakama connection — CHANGE THESE
  // ---------------------------------------------------------------------------

  /// Linode public IP or domain pointing at your Nakama server.
  /// Examples: '172.104.xx.xx'  or  'xxx.example.com'
  static const String host = 'xxx.xxx.xx';

  /// Nakama client API port. MUST match controller/src/config.js.
  /// You front Nakama with nginx on 443, so go through it with TLS.
  static const int port = 443;

  /// true  -> wss/https (REQUIRED when the web app itself is served over HTTPS)
  /// false -> ws/http   (only for quick local / IP testing)
  static const bool useSsl = true;

  /// Must equal `socket.server_key` in the server's local.yml.
  static const String serverKey = 'xxxx';

  // ---------------------------------------------------------------------------
  // Role — this build is the game display / host (it runs the physics sim).
  // ---------------------------------------------------------------------------
  static const String role = 'host';

  /// URL of the hosted React controller that players open on their phones.
  /// Shown as the lobby QR code. During local testing this can be the Vite
  /// dev server, e.g. `http://YOUR_IP:5173`.
  // For local testing this is the Vite dev server on your machine's LAN IP so a
  // phone on the same WiFi can scan it. Update the IP if yours differs
  // (`npm run dev` prints the Network URL). Only affects the lobby QR.
  static const String controllerUrl = 'http://192.168.0.6:5173';

  // ---------------------------------------------------------------------------
  // Admin console (for your reference only — the app does not use this):
  //   URL:  http(s)://<host>:7351   (or your console subdomain behind Caddy)
  //   user/pass: set via console.username / console.password in local.yml
  // ---------------------------------------------------------------------------
}
