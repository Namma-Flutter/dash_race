# AGENTS.md

This file provides guidance to agents when working with code in this repository.

## Project Overview

Dash Race is a real-time local multiplayer desktop car racing game. The **Flutter desktop app** acts as both the game host and WebSocket server. Players use a **React web app** on their phones as controllers, connecting over the local network.

## Commands

### Flutter (Desktop Game)

```bash
# Install dependencies
flutter pub get

# Run on macOS (primary platform)
flutter run -d macos

# Lint/analyze
flutter analyze

# Run tests
flutter test

# Run a single test file
flutter test test/some_test.dart
```

> This project uses FVM (Flutter Version Manager) pinned to Flutter **3.41.7** (see `.fvmrc`). Use `fvm flutter` instead of `flutter` if FVM is active in your shell.

### React Controller App (`controller/`)

```bash
cd controller
npm install
npm start        # dev server (Vite, default port 5173)
npm run build
```

## Architecture

### Flutter App

The app uses **Provider** for state management with three interconnected providers:

- **`GameProvider`** (`lib/providers/game.dart`) — Core game logic: car physics (`updateCar`), pixel-perfect collision detection via a grayscale collision mask (`isRoadPixel`, `isCarMostlyOnRoad`), checkpoint-based lap scoring, player management, and Redis leaderboard access.
- **`ServerProvider`** (`lib/providers/server.dart`) — Runs a `dart:shelf` HTTP + WebSocket server on port `4040`. Handles player join/leave and routes controller input messages to `GameProvider`. Depends on `GameProvider` via `ChangeNotifierProxyProvider`.
- **`ScreenControlProvider`** (`lib/providers/screen.dart`) — Manages which panel is shown on the right side of the split layout (`HomeScreen`, `LobbyScreen`, `GamePlayScreen`).

Providers are accessed in widgets via convenience extensions on `BuildContext` defined in `lib/helpers/extensions.dart` (`context.game`, `context.watchGame`, `context.screen`, `context.watchServer`, etc.).

### Layout

`GameScreen` (`lib/screens/game.dart`) is the single root widget. It uses a fixed `1600×1200` window with a permanent **left panel** (1000px wide — the `Track` widget with canvas rendering) and an **animated right panel** (remaining width) that switches between screens via `ScreenControlProvider`.

### Game Loop

`GameScreen` drives the game loop via Flutter's `Ticker` (60fps). Each tick calls `GameProvider.gameLoop()` → `updateCar()` for each player → `updatePlayerScore()` → `notifyListeners()`.

### Collision Detection

Track boundaries are enforced by pixel-sampling a grayscale **collision mask image** (`assets/images/cm{id}.png`). White pixels (R,G,B > 200) are driveable road. The mask is loaded at game init into `CollisionData` (raw RGBA bytes) via `lib/helpers/image_utils.dart`. Nine probe points around the car body are sampled; the car is blocked if more than 2 probes hit off-road pixels.

### Scoring / Leaderboard

Scoring uses two ordered **checkpoints** (A at `835,180`, B at `120,700`) — currently hardcoded for Track S. Passing A then B increments the player's lap score. Scores are persisted to a **Redis sorted set** (`leaderboard` key) using `ZADD GT` at game end. Redis runs locally at `localhost:6379`.

### Tracks

`Track` model maps an ID (1–4) to image/collision-mask asset paths (`assets/images/track{id}.png`, `assets/images/cm{id}.png`). Track U supports 4 players; all others are capped at 2.

### React Controller

Single-file app (`controller/src/App.jsx`). Connects to the game server WebSocket at the **hardcoded** `serverIP` constant at the top of the file — update this before running. Sends `{type: "join", name}` on connect, then `{type: "input", left, right, up, down}` on any button state change.

## Key Known Limitations / TODOs

- `serverIP` in `controller/src/App.jsx` is hardcoded and must be updated manually per session.
- Checkpoints A and B are hardcoded coordinates for Track S only — other tracks don't have correct scoring.
- `lib/helpers/game.dart` (`handleKeyEvent`) and car collision resolution code exist but are currently commented out in `GameScreen` and `GameProvider`.
- `result` and `gameOver` screen states in `ScreenControlProvider` throw `UnimplementedError`.
- `HomeScreen` calls `context.game.getTop10()` inside a `FutureBuilder` on every rebuild — noted as a known re-build issue.
- Max players: Track U = 4, all others = 2 (enforced in `GameProvider.canJoin()`).

## Prerequisites

- Redis must be running locally at `localhost:6379` before launching the Flutter app.
- All devices must be on the same WiFi network; firewall must allow port `4040`.
- The React dev server runs on port `5173` (the QR code in `LobbyScreen` points to `http://{ip}:5173`).
