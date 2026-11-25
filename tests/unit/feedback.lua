-- Execute the shipped Lua on both sides of the same contacts.
HostUTC = 0
init()
local g = game.state
local f = g.feedback
local F, E = Feedback, Hall.event
local r = Hall.new(0)
local a, b = Hall.join(r, 1), Hall.join(r, 2)
g.id = 1
host_receive("WELCOME 1")
r.hits, r.clears = 12, 3
host_receive(Net.snapshot(r))
assert(host_sound() == "" and f.cursor == 0)
local function sync()
    host_receive(Net.snapshot(r))
end
local function timing(dt)
    g.clock = g.clock + dt
    Hall.step(r, dt)
    sync()
    F.tick(g)
    World.update(g, dt)
    World.sprites(g)
end
local function fire(p, weapon, dx, dy, dz)
    return Hall.fire(r, p, p.seq + 1, weapon, dx, dy, dz)
end
assert(host_tune(77, 20) == 0 and host_tune(9, 0) == 0)
f.saved = false
host_tune(9, 1)
assert(host_tune(8, -1) == 1 and host_tune(2, -1) == 25)
host_tune(8, 0)
for i, v in ipairs({ 80, 70, 60, 70, 1, 1, 1 }) do
    assert(host_tune(i, v) == v)
end
local restored = F.new()
assert(restored.saved and restored.prefs[1] == 80 and restored.prefs[6] == 1)
host_tune(8, 1)
assert(F.new().prefs[2] == 25 and host_tune(8, -1) == 1)
local save = eng.save.write
eng.save.write = function()
    return false
end
host_tune(6, 1)
assert(g.flavor:find("save"))
eng.save.write = save
host_tune(8, 0)
f.saved = true
host_tune(9, 1)
assert(host_tune(1, -1) == 100)
-- Duplicate private hits and co-op source identity.
for _, m in pairs(r.mobs) do
    m.wake = 99
end
r.mobs[1].wake = 0
r.mobs[1].x, r.mobs[1].z = 0, 14
assert(fire(a, 1, 0, 0, -1))
timing(0.12)
assert(r.mobs[1].hp == 1 and f.mark == "ticks" and f.markUntil > g.clock)
assert(host_sound():find("thup"))
assert(host_flat_marks():sub(1, 1) == "1")
sync()
assert(host_sound() == "" and f.flinch[1])
timing(0.20)
assert(fire(b, 1, 0, 0, -1))
timing(0.12)
assert(r.mobs[1].hp == 0 and not (f.markUntil > g.clock))
assert(host_sound():find("poof"))
-- Fan across two targets, same local sequence produces one private thup.
a.cool = 0
r.mobs[2].wake, r.mobs[2].hp, r.mobs[2].x, r.mobs[2].z = 0, 8, 0.2, 15.5
assert(fire(a, 2, 0, 0, -1))
timing(0.08)
local _, count = host_sound():gsub("thup", "")
assert(count == 1)
-- A stale rocket must not credit the next occupant of the same slot.
local old = a
a.cool = 0
assert(fire(a, 5, 0, 0, -1))
Hall.leave(r, 1)
a = Hall.join(r, 1)
assert(old.seat ~= a.seat)
host_receive("WELCOME 1")
sync()
timing(0.20)
assert(f.markUntil <= g.clock)
-- Wire identity, bounded history, duplicate and malformed event rejection.
for i = 1, 40 do
    b.cool = 0
    assert(fire(b, 1, 1, 0, 0))
end
assert(#r.events == 32)
local wire = Net.snapshot(r)
local parsed = assert(Net.read(wire))
assert(#parsed.events == 32 and parsed.players[1].seat == a.seat)
local e = wire:match("(E [^\n]+)")
assert(not Net.read(wire .. "\n" .. e))
assert(not Net.read(wire .. "\nE 1 0 99 0 0 0 0 0 0 0 0 0 0"))
r.shots = {}
sync()
host_sound()
-- Actual clock/collider determine bounce, expiry, burst, practice and private finish.
a.x, a.z = 0, 0
a.cool = 0
assert(fire(a, 4, 1, 0, 0))
for i = 1, 3 do
    local s = r.shots[1]
    s.x, s.vx = 23.69, 20
    timing(0.015)
    assert(r.events[#r.events].code == E.bounce and r.events[#r.events].value == i)
end
local s = r.shots[1]
s.x, s.vx = 23.69, 20
timing(0.015)
assert(r.events[#r.events].code == E.wall)
a.cool = 0
assert(fire(a, 5, 0, 1, 0))
timing(0.02)
timing(0.02)
assert(next(f.trails))
r.shots[1].y = 8.99
timing(0.04)
assert(not next(f.trails))
local bursts = 0
for _, event in ipairs(r.events) do
    if event.code == E.burst then
        bursts = bursts + 1
    end
end
assert(bursts == 1)
for _, m in pairs(r.mobs) do
    m.hp = 0
end
r.mobs[5].hp, r.mobs[5].wake, r.mobs[5].x, r.mobs[5].y, r.mobs[5].z = 1, 0, 0, 1.55, -7
a.x, a.z = 0, -4
a.cool = 0
assert(fire(a, 5, 0, 0, -1))
timing(0.25)
assert(f.mark == "finish" and g.clock < f.markUntil and g.clock < f.invite)
assert(host_flat_marks():sub(1, 1) == "2" and host_sound():find("cadence"))
assert(Hall.practice(r))
sync()
assert(g.clock < f.answer and host_sound():find("practice"))
assert(not Hall.practice(r))
sync()
assert(host_sound() == "")
-- When a target is the source, its specific position, pitch and id survive snapshots.
a.x, a.z = 0, -12
a.cool = 0
assert(fire(a, 1, 0, 0, -1))
timing(0.12)
assert(host_sound():find("bell") and g.clock < f.tallyUntil)
assert(F.hud(g):find("Bell 3"))
-- Status and contact coexist with ordinary door text and repeated contact stays quiet.
g.awards, g.noteUntil = 0, 0
g.x, g.z = Hall.door(2)
g.room.players[1].slow = g.room.time + 1.3
F.tick(g)
assert(host_hud():find("Opens") and F.hud(g):find("Slowed"))
F.knock(g, 1)
F.knock(g, 1)
local _, knocks = host_sound():gsub("knock", "")
assert(knocks == 1)
g.room.players[1].slow = 0
F.tick(g)
assert(host_sound():find("brush") and F.hud(g):find("Recovered"))
g.room.hours = 5
F.tick(g)
assert(F.hud(g):find("Door 05 due") and host_sound():find("midnight"))
-- Exercise actual poses at every joint, visitor accents, and an optional right-hand pulse.
local rotations = {}
local rotate = eng.scene.set_rot_deg
eng.scene.set_rot_deg = function(id, x, y, z)
    rotations[id] = { x, y, z }
end
g.x, g.z = 0, 0
for i, m in ipairs(g.room.mobs) do
    m.hp, m.wake, m.x, m.z, m.heading = 3, 0, i * 0.1, 1.75, 0
end
g.room.time, g.clock = 10, 10
World.update(g, 0.05)
for i = 1, 24 do
    g.room.time, g.clock = g.room.time + 0.11, g.clock + 0.11
    for k, m in ipairs(g.room.mobs) do
        m.z = m.z - 0.035
        m.heading = (m.heading + 45) % 360
    end
    World.update(g, 0.11)
    World.sprites(g)
end
assert(f.rearIcon and f.rearIcon.text:find("Behind"))
assert(#World.joints[2] == 4 and math.abs(rotations[World.joints[4][1]][1]) > 0.1)
assert(f.visitors[3].beat >= 0 and f.visitors[4].nextAccent > 10)
host_tune(1, 0)
World.update(g, 0.02)
for _, parts in ipairs(World.joints) do
    for _, id in ipairs(parts) do
        local v = rotations[id]
        assert(v[1] == 0 and v[2] == 0 and v[3] == 0)
    end
end
eng.scene.set_rot_deg = rotate
host_tune(1, 100)
local aim = { ox = 0, oy = 0, oz = 0, dx = 0, dy = 0, dz = -1 }
host_xr(true, 0, 0, 0, 0, 0, -1, 0)
for i = 1, 5 do
    host_weapon(i)
    F.shot(g, aim)
    assert(host_pulse() > 0 and host_pulse() == 0)
    assert(#host_sound() > 0)
end
host_weapon(3)
for i = 1, 3 do
    F.shot(g, aim)
end
F.endBurst(g)
assert(host_sound():find("release"))
F.mark(g, { seq = 724, x = 0, y = 1.55, z = -3 }, true)
F.mark(g, { seq = 724, x = 0, y = 1.55, z = -3 }, false)
assert(f.mark == "finish")
f.slow = true
F.caption(g, "Behind", 0, 1, 2, "footprint")
World.update(g, 0.02)
World.sprites(g)
host_xr(false)
-- Warm a full effects pool and replace only distant decorations. Exercise the stamp sub-budget.
F.baseline(g, false)
for i = 1, F.spriteLimit do
    F.particle(g, "powder", 24, 1, 24, 0, 0, 0, 0.05, 1)
end
assert(F.particle(g, "crumb", 0, 1, 1, 0, 0, 0, 0.05, 1))
for i = 1, 12 do
    F.particle(g, "stamp", 0, 0.18, i / 20, 0, 0, 0, 0.14, 0.60, 2)
end
local stamps = 0
for _, p in ipairs(f.effects) do
    if p.life > 0 and p.kind == "stamp" then
        stamps = stamps + 1
    end
end
assert(stamps == 8)
TouchHall = true
World.update(g, 0.02)
World.sprites(g)
assert(f.drawn <= 24)
host_tune(2, 0)
assert(not F.particle(g, "powder", 0, 0, 0, 0, 0, 0, 0.05, 1))
World.update(g, 0.02)
World.sprites(g)
assert(f.drawn == 0)
TouchHall = false
host_tune(3, 0)
F.sound(g, "bell", 1, 1, 3)
assert(host_sound() == "")
host_tune(3, 100)
for i = 1, 12 do
    F.sound(g, "gear", 1, 1, 1, i, 1, 0)
end
F.sound(g, "bell", 1, 1, 3, 0, 1, 0)
F.sound(g, "gear", 1, 1, 1, 40, 1, 0, 6)
assert(#f.sounds == 8 and f.sounds[1].line:match("^bell"))
F.caption(g, "one", 0, 1, 1, "bellcue")
F.caption(g, "one", 0, 1, 1, "bellcue")
F.caption(g, "two", 0, 1, 1, "bellcue")
F.caption(g, "three", 0, 1, 1, "bellcue")
assert(#f.captions == 2)
g.clock = g.clock + 4
F.tick(g)
assert(#f.captions == 0)
F.walk(g, 2, 0)
assert(host_sound():find("cloth"))
g.x, g.z = 6, 6
F.walk(g, 2, 0)
assert(host_sound():find("stone"))
print(
    "Confirmed outcomes, quiet joins, five articulated gaits, accessible controls and effect budgets passed."
)
