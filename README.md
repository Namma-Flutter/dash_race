# 🎮 Dash Race - Multilayer Car Game

A realtime local multiplayer car game built with **Flutter (desktop)** and a **React-based controller app**.
Players connect using their phones as controllers over WebSocket.

---

## 🚀 How It Works

1. The **Flutter desktop app** runs the game server.
2. It displays a **local IP address**.
3. Players open the **React controller app** on their phones.
4. They enter the IP and connect as controllers.
5. Inputs are sent via WebSocket → game updates in real-time.

---

## 🧑‍💻 Local Setup Instructions

### 1️⃣ Run the Flutter Game (Desktop Mode)

> ⚠️ This project is designed to run in **desktop mode (Mac/Windows/Linux)** only

#### Enable desktop (if not already)

```bash
flutter config --enable-macos-desktop   # macOS
flutter config --enable-windows-desktop # Windows
flutter config --enable-linux-desktop   # Linux
```

#### Run the app

```bash
flutter pub get
flutter run -d macos   # or windows / linux
```

---

### 2️⃣ Start the Game Server

* Launch the app
* Click **"Play"** (or Start Server)
* The app will display something like:

```
Server running at:
ws://192.168.x.x:4040/ws
http://192.168.x.x:4040
```

👉 **Copy the IP address** (e.g. `192.168.x.x`)

---

### 3️⃣ Run the Controller App (React)

Go to your controller app:

```bash
cd controller
npm install
npm start
```

---

### 4️⃣ Connect Controller to Game

* Open the controller app in your browser (or mobile)
* Find where the server URL/IP is configured
* Replace it with your local IP:

```js
const SERVER_IP = "192.168.x.x:4040";
```

* Save and reload the controller

---

### 5️⃣ Join the Game

* Enter player name
* Tap **Join**
* Your car should appear in the Flutter game 🎉

---

## 📡 Requirements

* All devices must be on the **same WiFi network**
* Firewall should allow port `4040`
* Desktop must stay running as host
* Redis running locally at localhost:6379

---

## 🛠 Tech Stack

* **Flutter (Desktop)** – Game rendering + server
* **Dart Shelf** – WebSocket server
* **React** – Mobile controller UI
* **WebSocket** – Real-time communication
* **Redis** - For leaderboard and scoring

---

## ⚠️ Notes

* Redis should be up and running with permission granted to the desktop app
* Max players 4 but, currently code wise limited to 2players
* Only one host (Flutter app) should run at a time
* If connection fails:

    * Double-check IP
    * Ensure same network
    * Check port `4040`

---

## 💡 Future Improvements

* Reconnection support
* Controller built using flutter
* Game state sync improvements
* Music and SFX
* Online play via internet with support for Web

---

## 🤝 Contributing

PRs and ideas are welcome!

---

## 📜 License

MIT License
