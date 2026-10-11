# Multiplayer Network Racing Game

A small top-down multiplayer racing project originally built in 2022 to explore TCP sockets and client–server networking in GML. Updated in October 2026 for GameMaker LTS 2026, with keyboard driving and a three-lap race system. The original track and car artwork are retained.

## Features

- A separate TCP server supports up to five clients, with usernames and synchronized player movement.
- Arrow-key acceleration, braking and steering, with track boundaries.
- A host-controlled countdown, ordered checkpoints, three laps, race times and finish order.
- Shared player and server chat, with bounded message lengths and history.
- Packet checks, movement corrections, socket/resource cleanup and connection-loss detection.

## Build and run

Open `SERVER/SERVER.yyp` and `CLIENT/CLIENT.yyp` in **GameMaker LTS 2026**. The tested setup uses IDE **2026.0.0.16**, runtime **2026.0.0.23**, macOS **13 or newer**, and **YYC** native compilation. Xcode and GameMaker's native macOS compiler module are required for this target. Other platforms have not been verified in this update.

1. Select macOS and YYC, then build/run the server.
2. Build/run a client, enter a username, and press Enter to connect.
3. Repeat for additional clients, up to five players.
4. Focus the server and press Space to start the countdown.

The client currently connects to `127.0.0.1:10000`, so run the server and clients on the same computer for this demo. Configure the address in `CLIENT/objects/obj_client/Create_0.gml` if adapting it for a LAN.

Mac build output uses `~/gamemakerstudio2`. Keep the generated apps outside `/tmp`: the tested runner failed to locate its game resources when launched from a temporary bundle path. The VM runner also failed before loading the game on the tested Mac; use YYC. Compiled apps are not included in this source repository.

## Controls and race rules

| Control | Action |
| --- | --- |
| Up | Hold to accelerate |
| Down | Hold to brake |
| Left / Right | Steer while moving |
| Enter | Open chat, then send the typed message |
| Space, in the server window | Start or restart a race |

Join before the countdown to participate. Players joining an active race wait for the next start. Drive clockwise through the right, bottom and left checkpoints, then across the chequered finish line. All checkpoints must be visited in order to complete a lap; crossing the finish line alone does not count. Complete three laps to finish. The server records the elapsed time and finish order.

Track edges stop the car. Chat pauses the local driver's movement. If server updates stop for five seconds, clients return to their connection screen. Restart the server and press Enter in each client to reconnect.

## Implementation and cleanup

The server maintains socket-to-player maps and relays binary movement and chat packets. Socket IDs use 32-bit fields, and positions and angles use floating-point fields. Join packets preserve existing players' positions and directions. Local drivers do not receive stale echoes of their own movement.

The server validates packet lengths, terminated strings, numeric values, sender identity, track positions and movement distances. Invalid movement receives a position correction. Names are capped at 24 characters, chat messages at 120 characters and history at five messages; visible chat wraps within the window. Incoming packets are limited to 1 KiB. Incomplete handshakes, duplicate joins and missing player instances are guarded, and sockets, buffers, lists and maps are cleaned up.

Race progress is tracked by the server. Movement is still calculated on clients, making this an approachable teaching demo rather than a fully authoritative simulation or competitive anti-cheat system. Cars do not collide with one another. There is no persistent high-score database.

## Validation

Both native YYC apps compiled successfully. Runtime checks covered two-player joins, arrow-key movement synchronization, player/server chat, countdown and restart, a truncated movement packet, and client recovery after server loss and immediate restart.

A disposable test client crossed the finish early without receiving a lap, then completed three ordered circuits and received first place. The final integration test reported:

```text
RACE_TEST_PASS: three ordered laps, first place, elapsed 29.32
```

## Project history

The original 2022 source remains in Git history. The 2026 update migrates project resources, replaces the blocking username prompt with an asynchronous dialog, and adds the racing and networking fixes described above.
