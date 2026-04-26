import { useState, useEffect, useRef } from "react";
import {
  FaArrowLeft,
  FaArrowRight,
  FaArrowUp,
  FaArrowDown
} from "react-icons/fa";

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

export default function App() {
  const [socket, setSocket] = useState(null);
  const [name, setName] = useState("");
  const [joined, setJoined] = useState(false);
  const [connected, setConnected] = useState(false);
  const [inputState, setInputState] = useState({
    left: false,
    right: false,
    up: false,
    down: false
  });

  const serverIP = "ws://192.168.0.4:4040/ws";

  function connect() {
    goFullscreen();
    lockLandscape();

    const ws = new WebSocket(serverIP);

    ws.onopen = () => {
      setConnected(true);
      ws.send(JSON.stringify({ type: "join", name }));
      setJoined(true);
    };

    ws.onclose = () => {
      setConnected(false);
      setJoined(false);
    };

    setSocket(ws);
  }

  useEffect(() => {
    document.body.style.margin = "0";
    document.body.style.overflow = "hidden";
    document.body.style.background = "#111";
  }, []);

  const prevState = useRef(inputState);

  useEffect(() => {
    if (!socket) return;
    const changed =
      JSON.stringify(prevState.current) !== JSON.stringify(inputState);
    if (changed) {
      socket.send(JSON.stringify({ type: "input", ...inputState }));
      prevState.current = inputState;
    }
  }, [inputState, socket]);

  function hold(key) {
    setInputState(prev => ({ ...prev, [key]: true }));
  }

  function release(key) {
    setInputState(prev => ({ ...prev, [key]: false }));
  }

  if (!joined) {
    return (
      <div style={styles.joinScreen}>
        <div style={styles.joinCard}>
          <h2 style={styles.joinTitle}>🏎 Join Race</h2>
          <input
            style={styles.input}
            placeholder="Enter player name"
            value={name}
            onChange={e => setName(e.target.value)}
            onKeyDown={e => e.key === "Enter" && name && connect()}
          />
          <button
            style={{
              ...styles.connectBtn,
              opacity: name ? 1 : 0.4,
              cursor: name ? "pointer" : "not-allowed"
            }}
            onClick={connect}
            disabled={!name}
          >
            Connect &amp; Play
          </button>
          <p style={styles.statusText}>
            <span
              style={{
                ...styles.statusDot,
                background: connected ? "#4ade80" : "#888"
              }}
            />
            {connected ? "Connected" : "Not connected"}
          </p>
        </div>
      </div>
    );
  }

  const ArrowBtn = ({ dir, icon, active }) => (
    <button
      style={{
        ...styles.btn,
        background: active ? "#e03030" : "#222",
        transform: active ? "scale(0.94)" : "scale(1)"
      }}
      onPointerDown={() => hold(dir)}
      onPointerUp={() => release(dir)}
      onPointerCancel={() => release(dir)}
      onPointerLeave={() => release(dir)}
    >
      {icon}
    </button>
  );

  return (
    <div style={styles.controller}>

      {/* LEFT SIDE — Up / Down (throttle / brake) */}
      <div style={styles.verticalGroup}>
        <ArrowBtn
          dir="up"
          icon={<FaArrowUp size={40} />}
          active={inputState.up}
        />
        <ArrowBtn
          dir="down"
          icon={<FaArrowDown size={40} />}
          active={inputState.down}
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
          dir="left"
          icon={<FaArrowLeft size={40} />}
          active={inputState.left}
        />
        <ArrowBtn
          dir="right"
          icon={<FaArrowRight size={40} />}
          active={inputState.right}
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