"use strict";
const $ = (id) => document.getElementById(id);
const canvas = $("canvas");
const params = new URLSearchParams(location.search);
const touch = matchMedia("(pointer:coarse)").matches || navigator.maxTouchPoints > 0;
document.body.classList.toggle("touch", touch);
let ready = false;
let settings = { endpoint: "", room: "friends" };
let hudText = "";
let lastOrnaments;
function storageWarning() {
  const output = $("storageWarning");
  output.hidden = false;
  output.textContent = "Browser storage is unavailable. Ornaments last for this visit.";
}
function call(name, types = [], args = [], result = null) {
  return Module.ccall("hall_" + name, result, types, args);
}
function action(name, on) {
  if (ready) call("action", ["string", "number"], [name, Number(on)]);
}
function menu(show) {
  if (ready) call("menu", ["number"], [Number(show)]);
  document.body.dataset.mode = show ? "menu" : "play";
  $("menu").hidden = show;
  if (show && document.pointerLockElement) document.exitPointerLock();
  if (!show) {
    canvas.focus();
    if (!touch && canvas.requestPointerLock) {
      const pending = canvas.requestPointerLock();
      if (pending && pending.catch) pending.catch(() => {});
    }
  }
}
function panel(which) {
  $("dialogContent").replaceChildren($(which + "Panel").content.cloneNode(true));
  $("dialog").showModal();
  if (which !== "join") return;
  const form = $("roomForm");
  form.elements.server.value = settings.endpoint;
  form.elements.room.value = settings.room;
  function read() {
    const endpoint = form.elements.server.value.trim(),
      room = form.elements.room.value.trim();
    try {
      const u = new URL(endpoint);
      if (!(u.protocol === "wss:" || (u.protocol === "ws:" && location.protocol === "http:"))) throw Error();
      if (!/^[\w-]{1,32}$/.test(room)) throw Error();
    } catch {
      $("joinStatus").textContent = "Enter a valid WebSocket address and room code.";
      return null;
    }
    return { endpoint, room };
  }
  form.onsubmit = (event) => {
    event.preventDefault();
    const input = read();
    if (!input || !ready) return;
    settings = input;
    try {
      localStorage.setItem("lantern-room", JSON.stringify(input));
    } catch {}
    if (call("connect", ["string", "string"], [input.endpoint, input.room], "number")) {
      $("dialog").close();
      menu(false);
    } else $("joinStatus").textContent = "Connection failed. Check the service address and try again.";
  };
  $("solo").onclick = () => {
    if (!ready) return;
    settings = { endpoint: "", room: "friends" };
    try {
      localStorage.setItem("lantern-room", JSON.stringify(settings));
    } catch {}
    call("connect", ["string", "string"], ["", "friends"], "number");
    $("dialog").close();
    menu(false);
  };
  $("invite").onclick = async () => {
    const input = read();
    if (!input) return;
    const url = new URL(location.href);
    url.search = new URLSearchParams({ server: input.endpoint, room: input.room });
    try {
      await navigator.clipboard.writeText(url.href);
      $("joinStatus").textContent = "Invitation copied.";
    } catch {
      $("joinStatus").textContent = url.href;
    }
  };
}
$("join").onclick = () => panel("join");
$("controls").onclick = () => panel("control");
$("credits").onclick = () => panel("credit");
$("close").onclick = () => $("dialog").close();
$("enter").onclick = () => menu(false);
$("menu").onclick = () => menu(true);
document.addEventListener("pointerlockchange", () => {
  if (!ready) return;
  call("lock", ["number"], [Number(document.pointerLockElement === canvas)]);
  if (!touch && !document.pointerLockElement && document.body.dataset.mode === "play") menu(true);
});
function tap(name) {
  action(name, true);
  setTimeout(() => action(name, false), 100);
}
const movement = {
  KeyW: "up",
  ArrowUp: "up",
  KeyS: "down",
  ArrowDown: "down",
  KeyA: "left",
  ArrowLeft: "left",
  KeyD: "right",
  ArrowRight: "right",
  KeyR: "practice",
  KeyE: "interact",
};
function keyInput(e) {
  if (!ready || document.body.dataset.mode !== "play" || $("dialog").open) return;
  const down = e.type === "keydown",
    name = movement[e.code];
  if (name) action(name, down);
  else if (/^Digit[1-5]$/.test(e.code) || e.code === "KeyQ") {
    if (down && !e.repeat) call("choose", ["number"], [e.code === "KeyQ" ? 0 : Number(e.code.slice(-1))]);
  } else if (e.code === "Escape") {
    if (down) menu(true);
  } else return;
  e.preventDefault();
  e.stopImmediatePropagation();
}
window.addEventListener("keydown", keyInput, true);
window.addEventListener("keyup", keyInput, true);
canvas.addEventListener("pointerdown", (e) => {
  if (!touch && document.body.dataset.mode === "play" && e.button === 0) action("fire", true);
});
window.addEventListener("pointerup", (e) => {
  if (!touch && e.button === 0) action("fire", false);
});
$("practice").onclick = () => tap("practice");
for (const b of document.querySelectorAll("[data-weapon]"))
  b.onclick = () => call("choose", ["number"], [Number(b.dataset.weapon)]);
function bindButton(id, name) {
  const b = $(id);
  b.onpointerdown = (e) => {
    e.preventDefault();
    b.setPointerCapture(e.pointerId);
    action(name, true);
  };
  b.onpointerup = b.onpointercancel = b.onlostpointercapture = () => action(name, false);
}
bindButton("fire", "fire");
bindButton("use", "interact");
let moving = null,
  looking = null,
  px = 0,
  py = 0;
const stick = $("stick");
function move(e) {
  const rect = stick.getBoundingClientRect(),
    x = (e.clientX - rect.left - rect.width / 2) / (rect.width / 2),
    y = (e.clientY - rect.top - rect.height / 2) / (rect.height / 2);
  for (const [name, down] of [
    ["left", x < -0.2],
    ["right", x > 0.2],
    ["up", y < -0.2],
    ["down", y > 0.2],
  ])
    action(name, down);
  const magnitude = Math.max(1, Math.hypot(x, y));
  stick.firstElementChild.style.transform =
    "translate(" + (x / magnitude) * 28 + "px," + (y / magnitude) * 28 + "px)";
}
function releaseMove() {
  moving = null;
  for (const name of ["left", "right", "up", "down"]) action(name, false);
  stick.firstElementChild.style.transform = "";
}
stick.onpointerdown = (e) => {
  if (moving !== null) return;
  e.preventDefault();
  moving = e.pointerId;
  stick.setPointerCapture(moving);
  move(e);
};
stick.onpointermove = (e) => {
  if (e.pointerId === moving) move(e);
};
stick.onpointerup = stick.onpointercancel = stick.onlostpointercapture = releaseMove;
canvas.addEventListener("pointerdown", (e) => {
  if (!touch || looking !== null || document.body.dataset.mode !== "play") return;
  e.preventDefault();
  looking = e.pointerId;
  px = e.clientX;
  py = e.clientY;
  canvas.setPointerCapture(looking);
  if (ready) call("lock", ["number"], [1]);
});
canvas.addEventListener("pointermove", (e) => {
  if (e.pointerId !== looking || !ready) return;
  call("look", ["number", "number"], [e.clientX - px, e.clientY - py]);
  px = e.clientX;
  py = e.clientY;
});
function resetInput() {
  releaseMove();
  looking = null;
  for (const name of ["fire", "interact", "practice"]) action(name, false);
}
canvas.onpointerup = canvas.onpointercancel = () => {
  looking = null;
};
window.addEventListener("blur", resetInput);
window.addEventListener("pagehide", () => {
  if (ready) call("connect", ["string", "string"], ["", "friends"], "number");
});
window.addEventListener("pageshow", (e) => {
  if (e.persisted && ready && settings.endpoint)
    call("connect", ["string", "string"], [settings.endpoint, settings.room], "number");
});
function resize() {
  if (ready)
    call("resize", ["number", "number"], [Math.round(canvas.clientWidth), Math.round(canvas.clientHeight)]);
}
window.addEventListener("resize", () => {
  resetInput();
  resize();
});
function updateHUD(text) {
  if (text === hudText) return;
  hudText = text;
  const [weapon, number, bells, visitors, wave, days, players, connection, hint, space, ornaments] =
    text.split("|");
  if (lastOrnaments !== undefined && lastOrnaments !== ornaments)
    Module.FS.syncfs(false, (e) => {
      if (e) storageWarning();
    });
  lastOrnaments = ornaments;
  $("weaponName").textContent = weapon;
  $("bells").textContent = bells;
  $("visitors").textContent = visitors;
  $("days").textContent = days;
  $("connection").textContent = connection + (connection === "Live room" ? " · " + players + "/8" : "");
  $("hint").textContent = hint;
  $("practice").hidden = Number(visitors) > 0;
  for (const b of document.querySelectorAll("[data-weapon]"))
    b.classList.toggle("selected", b.dataset.weapon === number);
}
async function fileIntoFS(path) {
  const response = await fetch(path);
  if (!response.ok) throw Error("Could not load " + path);
  const data = new Uint8Array(await response.arrayBuffer());
  const slash = path.lastIndexOf("/");
  if (slash >= 0) Module.FS.mkdirTree("/" + path.slice(0, slash));
  Module.FS.writeFile("/" + path, data);
}
var Module = {
  canvas,
  noInitialRun: true,
  hallHUD: updateHUD,
  printErr: (msg) => console.warn(msg),
  onRuntimeInitialized: async () => {
    try {
      const resp = await fetch("manifest.json", { cache: "no-cache" });
      if (!resp.ok) throw Error("Could not load the game manifest");
      const manifest = await resp.json();
      Module.fetchHallPack = async (day) => {
        try {
          await Promise.all((manifest.missions[day] || []).map(fileIntoFS));
          Module._hall_pack_ready(day, 1);
        } catch (e) {
          console.warn(e);
          Module._hall_pack_ready(day, 0);
        }
      };
      await Promise.all(manifest.files.map(fileIntoFS));
      await Promise.allSettled(manifest.entries.map(fileIntoFS));
      Module.FS.mkdirTree("/profile");
      try {
        Module.FS.mount(Module.IDBFS, {}, "/profile");
        await new Promise((resolve, reject) => Module.FS.syncfs(true, (e) => (e ? reject(e) : resolve())));
      } catch {
        storageWarning();
      }
      const config = JSON.parse(Module.FS.readFile("/server.json", { encoding: "utf8" }));
      let saved = {};
      try {
        saved = JSON.parse(localStorage.getItem("lantern-room") || "{}") || {};
      } catch {}
      settings = {
        endpoint: params.get("server") || saved.endpoint || config.endpoint || "",
        room: params.get("room") || saved.room || config.room || "friends",
      };
      const args = ["--root", "/"];
      if (settings.endpoint) args.push("--endpoint", settings.endpoint, "--room", settings.room);
      Module.callMain(args);
      ready = true;
      resize();
      menu(true);
      $("enter").disabled = false;
      $("enter").textContent = "Enter the hall";
      $("loading").textContent = "";
      if (window.installHallXR) window.installHallXR();
    } catch (e) {
      $("loading").textContent = "The hall could not open. " + (e.message || e);
      console.error(e);
    }
  },
};
