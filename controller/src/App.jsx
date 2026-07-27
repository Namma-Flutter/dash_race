import { useState, useEffect, useRef } from "react";
import {
  FaArrowLeft,
  FaArrowRight,
  FaArrowUp,
  FaArrowDown
} from "react-icons/fa";
import { Client } from "@heroiclabs/nakama-js";
import { NAKAMA_CONFIG } from "./config";

// Opcodes — must match the Nakama runtime module and the Flutter host.
const OP_JOIN = 1; // controller -> host : { name }
const OP_INPUT = 2; // controller -> host : { up, down, left, right }

function goFullscreen() {
  const elem = document.documentElement;
  if (elem.requestFullscreen) elem.requestFullscreen();
  else if (elem.webkitRequestFullscreen) elem.webkitRequestFullscreen();
  else if (elem.msRequestFullscreen) elem.msRequestFullscreen();
}

function lockLandscape() {
  const screen = window.screen;
  if (screen.orientation && screen.orientation.lock) {
    screen.orientation.lock("landscape").catch(() => {});
  }
}

// Best-effort human-readable text from whatever the Nakama SDK throws.
function errText(e) {
  if (!e) return "";
  if (typeof e === "string") return e;
  const parts = [e.message, e.statusText, e.msg, e.status, e.code];
  return parts.filter(Boolean).join(" ");
}

// Stable per-device id so the same phone maps to the same Nakama user.
function getDeviceId() {
  let id = localStorage.getItem("dashrace_device_id");
  if (!id) {
    id = "ctrl-" + Math.random().toString(36).slice(2) + Date.now();
    localStorage.setItem("dashrace_device_id", id);
  }
  return id;
}

function ArrowBtn({ icon, active, onHold, onRelease }) {
  return (
    <button
      style={{
        ...styles.btn,
        background: active ? "#e03030" : "#222",
        transform: active ? "scale(0.94)" : "scale(1)",
        touchAction: "none"
      }}
      onPointerDown={e => {
        // Capture the pointer so the button shrinking to scale(0.94) — or a
        // slight finger movement — does NOT fire pointerleave and release the
        // key one frame after pressing it. This is what kept the cars still.
        e.currentTarget.setPointerCapture?.(e.pointerId);
        onHold();
      }}
      onPointerUp={onRelease}
      onPointerCancel={onRelease}
      onLostPointerCapture={onRelease}
    >
      {icon}
    </button>
  );
}

export default function App() {
  const [name, setName] = useState("");
  const [password, setPassword] = useState("");
  const [status, setStatus] = useState("idle"); // idle | connecting | connected | error
  const [errorMsg, setErrorMsg] = useState("");
  const [inputState, setInputState] = useState({
    left: false,
    right: false,
    up: false,
    down: false
  });

  const socketRef = useRef(null);
  const matchIdRef = useRef(null);
  const prevState = useRef(inputState);

  useEffect(() => {
    document.body.style.margin = "0";
    document.body.style.overflow = "hidden";
    document.body.style.background = "#111";
  }, []);

  async function connect() {
    if (!name || !password || status === "connecting") return;
    setStatus("connecting");
    setErrorMsg("");

    try {
      // goFullscreen();
      // lockLandscape();

      const { host, port, useSSL, serverKey, role } = NAKAMA_CONFIG;
      const client = new Client(serverKey, host, String(port), useSSL);

      // Password is validated server-side (beforeAuthenticateCustom).
      const session = await client.authenticateCustom(
        getDeviceId(),
        true,
        undefined,
        { password }
      );

      const socket = client.createSocket(useSSL, false);
      socket.ondisconnect = () => {
        setStatus("error");
        setErrorMsg("Disconnected from the game");
      };
      socket.onerror = () => {
        setStatus("error");
        setErrorMsg("Connection error");
      };
      await socket.connect(session, true);

      // Ask the server for the single running game.
      const rpcRes = await socket.rpc(
        "find_or_create_game",
        JSON.stringify({ role })
      );
      const matchId = JSON.parse(rpcRes.payload).matchId;

      await socket.joinMatch(matchId);
      await socket.sendMatchState(matchId, OP_JOIN, JSON.stringify({ name }));

      socketRef.current = socket;
      matchIdRef.current = matchId;
      prevState.current = { left: false, right: false, up: false, down: false };
      setStatus("connected");
    } catch (e) {
      const msg = errText(e).toLowerCase();
      let friendly = "Could not connect to the game";
      if (msg.includes("401") || msg.includes("unauthorized")) {
        friendly = "Wrong password";
      } else if (msg.includes("no active game")) {
        friendly = "No game running yet — ask the host to press Play";
      } else if (msg.includes("full")) {
        friendly = "Game is full";
      }
      try {
        socketRef.current && socketRef.current.disconnect(false);
      } catch {
        /* ignore */
      }
      socketRef.current = null;
      matchIdRef.current = null;
      setStatus("error");
      setErrorMsg(friendly);
    }
  }

  // Send input to the host only when it actually changes.
  useEffect(() => {
    const socket = socketRef.current;
    const matchId = matchIdRef.current;
    if (status !== "connected" || !socket || !matchId) return;

    const changed =
      JSON.stringify(prevState.current) !== JSON.stringify(inputState);
    if (changed) {
      prevState.current = inputState;
      socket
        .sendMatchState(matchId, OP_INPUT, JSON.stringify(inputState))
        .catch(() => {});
    }
  }, [inputState, status]);

  function hold(key) {
    setInputState(prev => ({ ...prev, [key]: true }));
  }

  function release(key) {
    setInputState(prev => ({ ...prev, [key]: false }));
  }

  if (status !== "connected") {
    const busy = status === "connecting";
    const canConnect = !!name && !!password && !busy;
    return (
      <div style={styles.joinScreen}>
        <div style={styles.joinCard}>
          <h2 style={styles.joinTitle}>🏎 Join Race</h2>
          <input
            style={styles.input}
            placeholder="Enter player name"
            value={name}
            onChange={e => setName(e.target.value)}
          />
          <input
            style={styles.input}
            type="password"
            placeholder="Access password"
            value={password}
            onChange={e => setPassword(e.target.value)}
            onKeyDown={e => e.key === "Enter" && canConnect && connect()}
          />
          <button
            style={{
              ...styles.connectBtn,
              opacity: canConnect ? 1 : 0.4,
              cursor: canConnect ? "pointer" : "not-allowed"
            }}
            onClick={connect}
            disabled={!canConnect}
          >
            {busy ? "Connecting…" : "Connect & Play"}
          </button>
          {status === "error" && errorMsg && (
            <p style={styles.errorText}>{errorMsg}</p>
          )}
          <p style={styles.statusText}>
            <span
              style={{
                ...styles.statusDot,
                background: busy ? "#facc15" : "#888"
              }}
            />
            {busy ? "Connecting" : "Not connected"}
          </p>
        </div>
      </div>
    );
  }

  return (
    <div style={styles.controller}>

      {/* LEFT SIDE — Up / Down (throttle / brake) */}
      <div style={styles.verticalGroup}>
        <ArrowBtn
          icon={<FaArrowUp size={40} />}
          active={inputState.up}
          onHold={() => hold("up")}
          onRelease={() => release("up")}
        />
        <ArrowBtn
          icon={<FaArrowDown size={40} />}
          active={inputState.down}
          onHold={() => hold("down")}
          onRelease={() => release("down")}
        />
      </div>

      {/* CENTER LABEL */}
      <div style={styles.centerLabel}>
        <span style={styles.playerName}>{name}</span>
        <span style={styles.labelSub}>CONTROLLER</span>
      </div>

      {/* RIGHT SIDE — Left / Right (steering) */}
      <div style={styles.horizontalGroup}>
        <ArrowBtn
          icon={<FaArrowLeft size={40} />}
          active={inputState.left}
          onHold={() => hold("left")}
          onRelease={() => release("left")}
        />
        <ArrowBtn
          icon={<FaArrowRight size={40} />}
          active={inputState.right}
          onHold={() => hold("right")}
          onRelease={() => release("right")}
        />
      </div>

    </div>
  );
}

const styles = {

  /* ── Join screen ── */
  joinScreen: {
    minHeight: "100vh",
    display: "flex",
    alignItems: "center",
    justifyContent: "center",
    background: "#111",
    fontFamily: "sans-serif"
  },
  joinCard: {
    background: "#1a1a1a",
    border: "1px solid #333",
    borderRadius: 20,
    padding: "36px 40px",
    display: "flex",
    flexDirection: "column",
    gap: 16,
    width: 320
  },
  joinTitle: {
    margin: 0,
    color: "#fff",
    fontSize: 22,
    fontWeight: 600
  },
  input: {
    padding: "12px 16px",
    borderRadius: 12,
    border: "1px solid #444",
    background: "#222",
    color: "#fff",
    fontSize: 16,
    outline: "none"
  },
  connectBtn: {
    padding: "14px 0",
    borderRadius: 12,
    border: "none",
    background: "#e03030",
    color: "#fff",
    fontSize: 16,
    fontWeight: 600,
    letterSpacing: "0.5px"
  },
  errorText: {
    margin: 0,
    color: "#f87171",
    fontSize: 13,
    textAlign: "center"
  },
  statusText: {
    margin: 0,
    color: "#888",
    fontSize: 13,
    display: "flex",
    alignItems: "center",
    gap: 8
  },
  statusDot: {
    width: 8,
    height: 8,
    borderRadius: "50%",
    display: "inline-block"
  },

  /* ── Controller (landscape) ── */
  controller: {
    width: "100vw",
    height: "100vh",
    background: "#111",
    display: "flex",
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "space-between",
    padding: "0 32px",
    boxSizing: "border-box",
    userSelect: "none",
    WebkitUserSelect: "none",
    touchAction: "none",

    /* Force landscape orientation via CSS */
    "@media (orientation: portrait)": {
      transform: "rotate(90deg)",
      transformOrigin: "center center",
      width: "100vh",
      height: "100vw"
    }
  },

  /* Left group — vertical stack (Up / Down) */
  verticalGroup: {
    display: "flex",
    flexDirection: "column",
    gap: 24
  },

  /* Right group — horizontal row (Left / Right) */
  horizontalGroup: {
    display: "flex",
    flexDirection: "row",
    gap: 24
  },

  /* Shared button */
  btn: {
    width: 130,
    height: 130,
    borderRadius: 24,
    border: "none",
    color: "#fff",
    display: "flex",
    alignItems: "center",
    justifyContent: "center",
    cursor: "pointer",
    transition: "background 0.08s, transform 0.08s"
  },

  /* Center label */
  centerLabel: {
    display: "flex",
    flexDirection: "column",
    alignItems: "center",
    gap: 6
  },
  playerName: {
    color: "#fff",
    fontSize: 22,
    fontWeight: 700,
    letterSpacing: "1px",
    textTransform: "uppercase"
  },
  labelSub: {
    color: "#555",
    fontSize: 11,
    letterSpacing: "3px",
    textTransform: "uppercase"
  }
};
