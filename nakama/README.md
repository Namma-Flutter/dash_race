# Dash Race — Nakama server

Self-hosted Nakama that acts as the **password gate + single-game gatekeeper +
input relay**. The game simulation stays **client-authoritative** on the Flutter
display — Nakama never runs physics.

```
Display (Flutter Web, ROLE=host)  ─┐
                                   ├─ wss ─▶  Nakama (this stack)  ─▶ Postgres
Controllers (React, ROLE=controller) ┘         • beforeAuthenticateCustom → password gate
                                               • authoritative match "dashrace" (singleton)
                                               • max players (2-4), one host
                                               • relays OP_INPUT / OP_STATE
```

## What's here

| File | Purpose |
|------|---------|
| `docker-compose.yml` | Nakama + Postgres (+ optional Caddy TLS via `--profile tls`) |
| `local.yml.example` | Nakama config + secrets (copy → `local.yml`) |
| `.env.example` | docker-compose vars (copy → `.env`) |
| `Caddyfile` | Auto-HTTPS reverse proxy for production |
| `modules/src/main.ts` | The runtime module (auth gate, match handler, relay) |

## First-time setup

```bash
cd nakama

# 1. Secrets & config
cp .env.example .env                 # set POSTGRES_PASSWORD, (later) domains
cp local.yml.example local.yml       # set all CHANGE_ME values
#   generate keys with:  openssl rand -hex 32
#   keep POSTGRES_PASSWORD (.env) == password in local.yml database.address

# 2. Build the runtime module (produces modules/build/index.js)
cd modules && npm install && npm run build && cd ..

# 3. Boot (no TLS — quick IP testing)
docker compose up -d
docker compose logs -f nakama        # look for "Dash Race module loaded"
```

Clients now connect to `http://<SERVER_IP>:7350` with `useSSL = false`.
Admin console: `http://<SERVER_IP>:7351` (console user/pass from `local.yml`).

> Rebuilt the TS module? `docker compose restart nakama` to reload it.

## Production TLS (browsers on HTTPS need `wss://`)

1. Point DNS `A` records for `DASHRACE_DOMAIN` / `DASHRACE_CONSOLE_DOMAIN` at the box.
2. Set those in `.env`, open ports 80 + 443.
3. `docker compose --profile tls up -d`

Clients then use `host=<domain>`, `port=443`, `useSSL=true`.

## Access model (matches your requirements)

- **Password:** `ACCESS_PASSWORD` in `local.yml`. Sent as an auth var; validated in
  `beforeAuthenticateCustom`. Wrong password → auth rejected, no session. The
  secret stays server-side (never in the client bundle).
- **One game at a time:** `find_or_create_game` returns the single existing match;
  a second host is rejected in `matchJoinAttempt`.
- **2-4 players:** `MAX_PLAYERS` in `local.yml`; the 5th controller is rejected —
  *even with the correct password.*
- **Auto-reset:** when the host disconnects (or the match sits empty ~30s) the match
  ends, freeing a fresh game for the next session.

## Opcode protocol (mirrors the old local WebSocket)

| Opcode | Direction | Payload |
|--------|-----------|---------|
| `1` JOIN | controller → host | `{ name }` |
| `2` INPUT | controller → host | `{ up, down, left, right }` |
| `3` JOIN_RESULT | host → controller | `{ accepted, reason }` |
| `4` STATE | host → controllers | optional game state |

## Moving to a Raspberry Pi later

Both images publish `arm64` tags, so no code changes:

```bash
# on the Pi
scp -r nakama/ pi@raspberrypi:~/          # copy stack + local.yml + .env
cd ~/nakama && docker compose up -d       # (rebuild modules if node available)
```

Then update `host` in the client configs to the Pi's LAN IP / DDNS domain. Nothing
else changes — that portability is the whole reason we anchored on Nakama-in-Docker.

## Notes / troubleshooting

- Pin `nakama-runtime` in `modules/package.json` to match your Nakama server version
  if the type build complains.
- If `--runtime.env` values don't appear in `ctx.env`, confirm they're under
  `runtime.env:` in `local.yml` (they are in the template).
- The `modules/build` folder is mounted read-only into the container at
  `/nakama/data/modules`; Nakama loads `index.js` on boot.
