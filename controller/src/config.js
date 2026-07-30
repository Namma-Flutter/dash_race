// Dash Race controller — Nakama server config, read from Vite env vars.
//
// Set these in Vercel → Project Settings → Environment Variables. They MUST be
// prefixed with VITE_ to be exposed to the browser bundle. For local dev, copy
// `.env.example` to `.env` and fill it in.
//
// The access password is NOT here — players type it on the join screen and the
// Nakama server validates it, so the secret never ships in the bundle.

const env = import.meta.env;

export const NAKAMA_CONFIG = {
  // Domain / IP of your Nakama server.
  host: env.VITE_NAKAMA_HOST ?? "localhost",

  // 443 when fronted by nginx/Caddy TLS; 7350 for direct / IP testing.
  port: Number(env.VITE_NAKAMA_PORT ?? 7350),

  // true = wss/https (required when served over HTTPS), false = ws/http.
  useSSL: String(env.VITE_NAKAMA_SSL ?? "false").toLowerCase() === "true",

  // Must equal socket.server_key in the server's local.yml.
  serverKey: env.VITE_NAKAMA_SERVER_KEY ?? "defaultkey",

  // Role for this client.
  role: "controller",
};
