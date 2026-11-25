The Lantern Hall 0.3.0 moves multiplayer to the updated engine. Windows, Linux, browsers and WebXR share the engine’s binary WebSocket format. Each room accommodates eight friends. The Linux service can host six full rooms.

Upgrade the Linux room service and the clients together. Enter the same room code and service URL in **Join friends** or in the native **F2** panel. Private-CA hosts can still use `--ca`. Room addresses, feedback preferences and ornaments are saved on the player’s device.

- Extract the Windows or Linux client archive and launch Lantern, or [play the Web edition](https://stbange.github.io/kalender2026/).
- Extract the Linux room archive and run `./lantern --server --port 8787`. The included Caddy and systemd examples support public secure invites.
- The Web archive can be served from HTTPS or localhost. Scripts, art and sounds are editable alongside each build.

Original code uses MIT. Original art and audio use CC BY 4.0.
