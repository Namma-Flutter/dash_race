// Dash Race controller — Nakama server config.
// Fill these in to match your Linode (later Raspberry Pi) Nakama server.
//
// The access password is NOT stored here — players type it on the join screen
// and the Nakama server validates it, so the secret never ships in the bundle.

export const NAKAMA_CONFIG = {
  // Linode public IP or domain pointing at Nakama.
  host: "xxx.xxx.xxx",

  // You front Nakama with nginx on 443, so connect through it with TLS.
  port: 443,

  // true = wss/https (REQUIRED when this app is served over HTTPS), false = ws/http.
  useSSL: true,

  // Must equal socket.server_key in the server's local.yml.
  serverKey: "xxx",

  // Role for this client.
  role: "controller",
};
