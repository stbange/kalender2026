local function saved()
    local function mask(slot)
        local s = eng.save.read("lantern_" .. slot)
        return tonumber(s and s:match("^1 (%d+)$")) or 0
    end
    return bit.bor(mask("a"), mask("b")) % 16777216
end
function init()
    local r = Hall.new(Hall.due(HostUTC or 0))
    local p = Hall.join(r, 1)
    game.state = {
        room = r,
        id = 1,
        online = false,
        x = p.x,
        z = p.z,
        space = 0,
        yaw = 0,
        pitch = 0,
        weapon = 1,
        seq = 0,
        clock = 0,
        recoil = 0,
        nextFire = 0,
        nextPose = 0,
        awards = saved(),
        outbox = {},
        sounds = {},
        doorGuard = 0,
        connection = "Solo practice",
        flavor = "",
        seenHits = 0,
        seenClears = 0,
    }
    World.build()
    World.update(game.state, 0)
end
local function command(g, msg)
    if g.online then
        g.outbox[#g.outbox + 1] = msg
    else
        Net.command(g.room, g.id, msg, MissionPacks)
    end
end
function host_drain()
    local g = game.state
    local s = table.concat(g.outbox, "\n")
    g.outbox = {}
    return s
end
function host_sound()
    local g = game.state
    local s = table.concat(g.sounds, " ")
    g.sounds = {}
    return s
end
function host_receive(msg)
    local g = game.state
    local id = msg:match("^WELCOME (%d+)$")
    if id then
        g.id = tonumber(id)
        g.online = true
        g.connection = "Live room"
        g.awaiting = true
        g.seq = 0
        g.lastSnapshot = nil
        g.outbox = {}
        return
    end
    if msg:match("^ERROR ") or msg == "DISCONNECTED" then
        local state = Hall.new(Hall.due(HostUTC))
        local p = Hall.join(state, 1)
        g.room, g.online, g.id, g.space, g.x, g.z, g.awaiting = state, false, 1, 0, p.x, p.z, false
        g.connection = msg == "DISCONNECTED" and "Disconnected · solo practice" or msg:sub(7)
        g.outbox = {}
        return
    end
    local r = Net.read(msg)
    local p = r and r.players[g.id]
    if not p or (g.lastSnapshot and r.time < g.lastSnapshot) then
        return
    end
    g.lastSnapshot = r.time
    if g.awaiting or p.space ~= g.space or (p.x - g.x) ^ 2 + (p.z - g.z) ^ 2 > 2.0 then
        g.x, g.z, g.yaw, g.space, g.doorGuard = p.x, p.z, p.yaw, p.space, g.clock + 0.6
    end
    g.awaiting = false
    g.room = r
end
function host_xr(active, ox, oy, oz, dx, dy, dz, turn)
    local g = game.state
    if not active then
        g.xr = nil
        return
    end
    g.yaw = (g.yaw + turn) % 360
    local a = math.rad(g.yaw)
    g.xr = {
        ox = ox * math.cos(a) + oz * math.sin(a),
        oy = oy,
        oz = -ox * math.sin(a) + oz * math.cos(a),
        dx = dx * math.cos(a) + dz * math.sin(a),
        dy = dy,
        dz = -dx * math.sin(a) + dz * math.cos(a),
    }
    g.xr.pitch = math.deg(math.asin(Hall.clamp(dy, -1, 1)))
    g.xr.yaw = math.deg(math.atan2(-g.xr.dx, -g.xr.dz))
end
function host_weapon(w)
    local g = game.state
    g.weapon = 1 + ((w or g.weapon + 1) - 1) % 5
end
local function apply_award(g, p)
    local mask = bit.bor(g.awards, p.awards)
    if mask ~= g.awards then
        local value = "1 " .. mask
        if eng.save.write("lantern_a", value) then
            g.awards = mask
            eng.save.write("lantern_b", value)
        else
            g.flavor = "Could not save ornament"
            g.noteUntil = g.clock + 3
        end
    end
end
local function fire(g)
    g.seq = g.seq + 1
    local yaw, pitch = math.rad(g.yaw), math.rad(g.pitch)
    local a = g.xr
        or {
            dx = -math.sin(yaw) * math.cos(pitch),
            dy = math.sin(pitch),
            dz = -math.cos(yaw) * math.cos(pitch),
            ox = 0,
            oy = 0,
            oz = 0,
        }
    command(
        g,
        string.format(
            "F %d %d %.5f %.5f %.5f %.4f %.4f %.4f",
            g.seq,
            g.weapon,
            a.dx,
            a.dy,
            a.dz,
            Hall.clamp(a.ox, -1, 1),
            Hall.clamp(a.oy, -1.5, 1),
            Hall.clamp(a.oz, -1, 1)
        )
    )
    g.recoil = 0.095
    g.nextFire = g.clock + Hall.weapons[g.weapon].delay
    g.sounds[#g.sounds + 1] = "throw"
end
function host_pack_ready(day, ok)
    local g = game.state
    g.loadingDay = nil
    if ok and pcall(World.prepare, day) then
        return
    end
    g.flavor = "Could not load this door · step closer to retry"
    g.noteUntil = g.clock + 2
    g.doorGuard = g.noteUntil
end
function host_pack_request()
    local g = game.state
    local day = g.assetRequest
    g.assetRequest = nil
    return day or 0
end
function update(dt)
    local g = game.state
    g.clock = g.clock + dt
    g.recoil = math.max(0, g.recoil - dt * 0.64)
    if g.awaiting then
        return
    end
    if g.menu and not g.xr then
        World.update(g, dt)
        return
    end
    local r = g.room
    if not g.online then
        r.hours = Hall.due(HostUTC)
        Hall.step(r, dt)
    end
    local p = r.players[g.id]
    if not p then
        return
    end
    for id = 1, 5 do
        if eng.input.pressed("tool" .. id) then
            host_weapon(id)
        end
    end
    if eng.input.pressed("cycle") then
        host_weapon()
    end
    if eng.input.pressed("practice") then
        command(g, "BELL")
    end
    local dx, dz
    local oldYaw = g.yaw
    g.yaw, g.pitch, dx, dz = eng.camera.fps_steer(g.yaw, g.pitch, Hall.walk_speed(r, p), dt, 0.19)
    if g.xr then
        g.yaw = oldYaw
        g.pitch = 0
    end
    g.yaw = g.yaw % 360
    dx, dz =
        dx + (HostMoveX or 0) * Hall.walk_speed(r, p) * dt, dz + (HostMoveZ or 0) * Hall.walk_speed(r, p) * dt
    g.x, g.z = Hall.move(g.x, g.z, dx, dz, g.space)
    if not g.online then
        p.x, p.z, p.yaw = g.x, g.z, g.yaw
    elseif g.clock >= g.nextPose then
        command(g, string.format("P %.4f %.4f %.3f", g.x, g.z, g.yaw))
        g.nextPose = g.clock + 0.05
    end
    local use = eng.input.pressed("interact")
    if g.space == 0 then
        local day = Hall.near_door(g.x, g.z, 1.1)
        if day and g.clock > g.doorGuard and (MissionPacks[day] or use) then
            if day <= r.hours and MissionPacks[day] and not World.prepared[day] and HostWeb then
                if not g.loadingDay then
                    g.assetRequest = day
                    g.loadingDay = day
                end
            else
                if day <= r.hours and MissionPacks[day] then
                    host_pack_ready(day, true)
                end
                if not MissionPacks[day] or day > r.hours or World.prepared[day] then
                    command(g, "ENTER " .. day)
                    g.doorGuard = g.clock + 0.6
                end
            end
        end
        if eng.input.down("fire") and g.clock >= g.nextFire then
            fire(g)
        end
        if use and (g.x ^ 2 + (g.z + 13) ^ 2) < 16 then
            command(g, "BELL")
        end
    else
        if g.z > 6.4 and g.clock > g.doorGuard then
            command(g, "BACK")
            g.doorGuard = g.clock + 0.6
        elseif use or eng.input.pressed("fire") then
            command(g, "USE")
        end
    end
    if not g.online and g.space ~= p.space then
        g.x, g.z, g.yaw, g.space, g.doorGuard = p.x, p.z, p.yaw, p.space, g.clock + 0.65
    end
    apply_award(g, p)
    if r.hits > g.seenHits then
        g.sounds[#g.sounds + 1] = "bell"
    end
    if r.clears > g.seenClears then
        g.sounds[#g.sounds + 1] = "poof"
    end
    g.seenHits, g.seenClears = r.hits, r.clears
    World.update(g, dt)
end
function host_hud()
    local g = game.state
    local r = g.room
    local count, alive = 0, 0
    for _ in pairs(r.players) do
        count = count + 1
    end
    for _, m in pairs(r.mobs) do
        if m.hp > 0 then
            alive = alive + 1
        end
    end
    local hint = ""
    if g.space > 0 then
        local run = r.instances[g.space]
        hint = run and run.done and "Ornament earned · walk back through the door"
            or "Use the objective · return through the doorway"
    else
        local day = Hall.near_door(g.x, g.z, 4)
        if day then
            local state = day > r.hours and ("Opens " .. day .. " December")
                or (MissionPacks[day] and "Walk through" or "Mission in preparation")
            if math.floor(g.awards / 2 ^ (day - 1)) % 2 == 1 then
                state = "Ornament earned · replay"
            end
            hint = string.format("Door %02d · %s", day, state)
        elseif alive == 0 then
            hint = "Hall clear · ring the practice bell to play again"
        elseif r.players[g.id] and r.players[g.id].slow > r.time then
            hint = "Snow-dusted · movement briefly slowed"
        end
    end
    if g.noteUntil and g.clock < g.noteUntil then
        hint = g.flavor
    end
    if g.loadingDay then
        hint = "Loading door " .. g.loadingDay
    end
    return table.concat(
        {
            Hall.weapons[g.weapon].name,
            g.weapon,
            r.hits,
            alive,
            r.wave,
            r.hours,
            count,
            g.connection,
            hint,
            g.space,
            g.awards,
        },
        "|"
    )
end
function draw()
    local g = game.state
    World.sprites(g)
    local h = host_hud()
    local w = Hall.weapons[g.weapon]
    eng.render.draw_text(
        string.format("%d  %s    |    bells %d    |    wave %d", g.weapon, w.name, g.room.hits, g.room.wave),
        18,
        18,
        1
    )
    eng.render.draw_text(g.connection .. "    /    " .. g.room.hours .. " of 24 doors due", 18, 50, 1)
    local hint = h:match("^[^|]*|[^|]*|[^|]*|[^|]*|[^|]*|[^|]*|[^|]*|[^|]*|([^|]*)")
    if hint and #hint > 0 then
        eng.render.draw_text(hint, 18, 82, 1)
    end
end
