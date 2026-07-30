#!/usr/bin/env bash
# Vercel build for the Dash Race controller (React/Vite).
#
# Set these in Vercel → Project Settings → Environment Variables. Vite inlines
# any VITE_*-prefixed var it finds in the environment at build time:
#   VITE_NAKAMA_HOST  VITE_NAKAMA_PORT  VITE_NAKAMA_SSL  VITE_NAKAMA_SERVER_KEY
set -euo pipefail

npm install
npm run build
