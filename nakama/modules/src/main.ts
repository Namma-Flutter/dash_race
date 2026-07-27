// =============================================================================
// Dash Race — Nakama runtime module
// =============================================================================
// This module keeps the game simulation CLIENT-AUTHORITATIVE: the Flutter
// display client still runs all the physics. Nakama only:
//
//   1. Gates access with a shared password (beforeAuthenticateCustom).
//   2. Hosts a SINGLE global game at a time (authoritative match, one host).
//   3. Enforces a max player count (2-4, configurable).
//   4. Relays input/state opcodes between controllers and the host.
//
// The opcode protocol mirrors the old shelf WebSocket messages 1:1 so the game
// logic in GameProvider barely changes.
// =============================================================================

const MATCH_MODULE = 'dashrace';
const MATCH_LABEL = 'dashrace';
const TICK_RATE = 30; // relay ticks/sec; inputs are edge-triggered so this is plenty

// Opcodes — same payloads you already send over the local WebSocket.
const OP_JOIN = 1; // controller -> host : { name }
const OP_INPUT = 2; // controller -> host : { up, down, left, right }
const OP_JOIN_RESULT = 3; // host -> controller : { accepted, reason }
const OP_STATE = 4; // host -> controllers : optional game state

interface MatchState {
  presences: { [userId: string]: nkruntime.Presence };
  // The host's userId is baked in at match creation (see the RPC below), so the
  // server — not the client — decides who the host is. Race-proof and works
  // even though the Dart client can't pass join metadata.
  expectedHostId: string | null;
  hostId: string | null;
  maxControllers: number;
  emptyTicks: number;
}

// -----------------------------------------------------------------------------
// InitModule — registration entry point (Nakama calls this on boot).
// -----------------------------------------------------------------------------
function InitModule(
  ctx: nkruntime.Context,
  logger: nkruntime.Logger,
  nk: nkruntime.Nakama,
  initializer: nkruntime.Initializer,
): void {
  initializer.registerBeforeAuthenticateCustom(beforeAuthCustom);
  initializer.registerRpc('find_or_create_game', rpcFindOrCreateGame);
  initializer.registerMatch(MATCH_MODULE, {
    matchInit: matchInit,
    matchJoinAttempt: matchJoinAttempt,
    matchJoin: matchJoin,
    matchLeave: matchLeave,
    matchLoop: matchLoop,
    matchTerminate: matchTerminate,
    matchSignal: matchSignal,
  });
  logger.info('Dash Race module loaded (max players from env MAX_PLAYERS)');
}

// -----------------------------------------------------------------------------
// Password gate — every client must authenticate with the shared password.
// The real secret lives in the server's local.yml (runtime.env ACCESS_PASSWORD)
// and is NEVER shipped in the client bundle.
// -----------------------------------------------------------------------------
function beforeAuthCustom(
  ctx: nkruntime.Context,
  logger: nkruntime.Logger,
  nk: nkruntime.Nakama,
  data: nkruntime.AuthenticateCustomRequest,
): nkruntime.AuthenticateCustomRequest {
  const expected = ctx.env['ACCESS_PASSWORD'];
  const vars = data.account ? data.account.vars : undefined;
  const provided = vars ? vars['password'] : undefined;

  if (!expected || provided !== expected) {
    throw Error('unauthorized'); // rejects the auth attempt with 401
  }
  return data;
}

// -----------------------------------------------------------------------------
// RPC: find the running game, or create it (host only).
//   payload: { "role": "host" | "controller" }
//   returns: { "matchId": "..." }
// -----------------------------------------------------------------------------
function rpcFindOrCreateGame(
  ctx: nkruntime.Context,
  logger: nkruntime.Logger,
  nk: nkruntime.Nakama,
  payload: string,
): string {
  let input: any = {};
  try {
    input = payload ? JSON.parse(payload) : {};
  } catch (e) {
    input = {};
  }
  const wantHost = input.role === 'host';

  const matches = nk.matchList(1, true, MATCH_LABEL);
  if (matches.length > 0 && matches[0].matchId) {
    return JSON.stringify({ matchId: matches[0].matchId });
  }

  if (wantHost) {
    // Bake the creator's userId into the match so matchJoinAttempt can
    // recognise the host purely server-side.
    const matchId = nk.matchCreate(MATCH_MODULE, { hostUserId: ctx.userId });
    return JSON.stringify({ matchId: matchId });
  }

  throw Error('no active game'); // controller arrived before the host opened
}

// -----------------------------------------------------------------------------
// Match handler (relay only — no physics runs here).
// -----------------------------------------------------------------------------
function matchInit(
  ctx: nkruntime.Context,
  logger: nkruntime.Logger,
  nk: nkruntime.Nakama,
  params: { [key: string]: string },
): { state: nkruntime.MatchState; tickRate: number; label: string } {
  const maxControllers = parseInt(ctx.env['MAX_PLAYERS'] || '4', 10);
  const state: MatchState = {
    presences: {},
    expectedHostId: params['hostUserId'] || null,
    hostId: null,
    maxControllers: maxControllers,
    emptyTicks: 0,
  };
  return { state: state, tickRate: TICK_RATE, label: MATCH_LABEL };
}

function matchJoinAttempt(
  ctx: nkruntime.Context,
  logger: nkruntime.Logger,
  nk: nkruntime.Nakama,
  dispatcher: nkruntime.MatchDispatcher,
  tick: number,
  state: nkruntime.MatchState,
  presence: nkruntime.Presence,
  metadata: { [key: string]: any },
): { state: nkruntime.MatchState; accept: boolean; rejectMessage?: string } {
  const s = state as MatchState;
  const isHost = s.expectedHostId !== null && presence.userId === s.expectedHostId;

  if (isHost) {
    if (s.hostId !== null && s.hostId !== presence.userId) {
      return { state: state, accept: false, rejectMessage: 'A host is already running the game' };
    }
  } else {
    let controllers = 0;
    const ids = Object.keys(s.presences);
    for (let i = 0; i < ids.length; i++) {
      if (ids[i] !== s.hostId) controllers++;
    }
    if (controllers >= s.maxControllers) {
      return { state: state, accept: false, rejectMessage: 'Game is full' };
    }
  }

  return { state: state, accept: true };
}

function matchJoin(
  ctx: nkruntime.Context,
  logger: nkruntime.Logger,
  nk: nkruntime.Nakama,
  dispatcher: nkruntime.MatchDispatcher,
  tick: number,
  state: nkruntime.MatchState,
  presences: nkruntime.Presence[],
): { state: nkruntime.MatchState } {
  const s = state as MatchState;
  presences.forEach(function (p) {
    s.presences[p.userId] = p;
    if (p.userId === s.expectedHostId) {
      s.hostId = p.userId;
    }
  });
  return { state: state };
}

function matchLeave(
  ctx: nkruntime.Context,
  logger: nkruntime.Logger,
  nk: nkruntime.Nakama,
  dispatcher: nkruntime.MatchDispatcher,
  tick: number,
  state: nkruntime.MatchState,
  presences: nkruntime.Presence[],
): { state: nkruntime.MatchState } | null {
  const s = state as MatchState;
  let hostLeft = false;
  presences.forEach(function (p) {
    delete s.presences[p.userId];
    if (p.userId === s.hostId) {
      hostLeft = true;
      s.hostId = null;
    }
  });

  // Host gone -> end the game so a fresh one can be created next time.
  if (hostLeft) {
    return null;
  }
  return { state: state };
}

function matchLoop(
  ctx: nkruntime.Context,
  logger: nkruntime.Logger,
  nk: nkruntime.Nakama,
  dispatcher: nkruntime.MatchDispatcher,
  tick: number,
  state: nkruntime.MatchState,
  messages: nkruntime.MatchMessage[],
): { state: nkruntime.MatchState } | null {
  const s = state as MatchState;

  // Self-terminate if the match sits completely empty (~30s).
  if (Object.keys(s.presences).length === 0) {
    s.emptyTicks++;
    if (s.emptyTicks > TICK_RATE * 30) {
      return null;
    }
  } else {
    s.emptyTicks = 0;
  }

  for (let i = 0; i < messages.length; i++) {
    const m = messages[i];
    const data: any = m.data;

    if (m.opCode === OP_INPUT || m.opCode === OP_JOIN) {
      // controller -> host
      const host = s.hostId ? s.presences[s.hostId] : null;
      if (host) {
        dispatcher.broadcastMessage(m.opCode, data, [host], m.sender);
      }
    } else if (m.opCode === OP_JOIN_RESULT || m.opCode === OP_STATE) {
      // host -> all controllers
      const targets: nkruntime.Presence[] = [];
      const ids = Object.keys(s.presences);
      for (let j = 0; j < ids.length; j++) {
        if (ids[j] !== s.hostId) targets.push(s.presences[ids[j]]);
      }
      if (targets.length > 0) {
        dispatcher.broadcastMessage(m.opCode, data, targets, m.sender);
      }
    }
  }

  return { state: state };
}

function matchTerminate(
  ctx: nkruntime.Context,
  logger: nkruntime.Logger,
  nk: nkruntime.Nakama,
  dispatcher: nkruntime.MatchDispatcher,
  tick: number,
  state: nkruntime.MatchState,
  graceSeconds: number,
): { state: nkruntime.MatchState } {
  return { state: state };
}

function matchSignal(
  ctx: nkruntime.Context,
  logger: nkruntime.Logger,
  nk: nkruntime.Nakama,
  dispatcher: nkruntime.MatchDispatcher,
  tick: number,
  state: nkruntime.MatchState,
  data: string,
): { state: nkruntime.MatchState; data?: string } {
  return { state: state, data: data };
}

// Keep InitModule referenced so the bundler/compiler does not drop it.
// (Nakama's Goja runtime invokes the global InitModule on startup.)
!InitModule && InitModule.bind(null);
