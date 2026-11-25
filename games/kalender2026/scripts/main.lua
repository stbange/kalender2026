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
        feedback = Feedback.new(),
        doorGuard = 0,
        connection = "Solo practice",
        flavor = "",
    }
    Feedback.baseline(game.state, false)
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
        Feedback.baseline(g, true)
        g.connection = msg == "DISCONNECTED" and "Disconnected · solo practice" or msg:sub(7)
        g.outbox = {}
        return
    end
    local r = Net.read(msg)
    local p = r and r.players[g.id]
    if not p or (g.lastSnapshot and r.time < g.lastSnapshot) then
        return
    end
    local baseline = g.awaiting or p.space ~= g.space
    g.lastSnapshot = r.time
    if g.awaiting or p.space ~= g.space or (p.x - g.x) ^ 2 + (p.z - g.z) ^ 2 > 2.0 then
        g.x, g.z, g.yaw, g.space, g.doorGuard = p.x, p.z, p.yaw, p.space, g.clock + 0.6
    end
    g.awaiting = false
    g.room = r
    if g.feedback.resume then
        baseline = true
        g.feedback.resume = false
    end
    if baseline then
        Feedback.baseline(g, true)
    else
        Feedback.consume(g)
    end
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
    local nextTool = 1 + ((w or g.weapon + 1) - 1) % 5
    local pack = MissionPacks[g.space]
    if pack and pack.unlocked then
        nextTool = 1 + (nextTool - 1) % pack.unlocked(g.room.instances[g.space])
    end
    if nextTool ~= g.weapon then
        Feedback.switch(g)
        g.weapon = nextTool
    end
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
    local pack = MissionPacks[g.space]
    if pack and pack.presentShot then
        pack.presentShot(g, a)
    else
        Feedback.shot(g, a)
    end
    g.nextFire = g.clock + (pack and pack.delays and pack.delays[g.weapon] or Hall.weapons[g.weapon].delay)
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
    local pack = MissionPacks[g.space]
    local run = r.instances[g.space]
    if pack and pack.move then
        if not g.online and (g.x ~= p.x or g.z ~= p.z) then
            g.x, g.z = p.x, p.z
        end
        local unlocked = pack.unlocked(run)
        if g.lastUnlock ~= unlocked then
            g.weapon = unlocked
            g.lastUnlock = unlocked
        end
    else
        g.lastUnlock = nil
    end
    local oldX, oldZ = g.x, g.z
    g.x, g.z = Hall.move(g.x, g.z, dx, dz, g.space, run, p)
    Feedback.walk(g, g.x - oldX, g.z - oldZ)
    if not g.online then
        p.x, p.z, p.yaw = g.x, g.z, g.yaw
    elseif g.clock >= g.nextPose then
        command(g, string.format("P %.4f %.4f %.3f", g.x, g.z, g.yaw))
        g.nextPose = g.clock + 0.05
    end
    local use = eng.input.pressed("interact")
    if g.space == 0 then
        local day = Hall.near_door(g.x, g.z, 1.1)
        local state = day and Hall.door_state(day, r.hours, MissionPacks)
        if use and state == "locked" then
            Feedback.knock(g, day)
        end
        if day and g.clock > g.doorGuard and (state == "ready" or use) then
            if state == "ready" and not World.prepared[day] and HostWeb then
                if not g.loadingDay then
                    g.assetRequest = day
                    g.loadingDay = day
                end
            else
                if state == "ready" then
                    host_pack_ready(day, true)
                end
                if state ~= "ready" or World.prepared[day] then
                    command(g, "ENTER " .. day)
                    g.doorGuard = g.clock + 0.6
                end
            end
        end
        if eng.input.down("fire") then
            if g.clock >= g.nextFire then
                fire(g)
            end
        else
            Feedback.endBurst(g)
        end
        if use and (g.x ^ 2 + (g.z + 13) ^ 2) < 16 then
            command(g, "BELL")
        end
    else
        if (g.z > 6.4 or (pack and pack.atExit and pack.atExit(run, p))) and g.clock > g.doorGuard then
            command(g, "BACK")
            g.doorGuard = g.clock + 0.6
        elseif pack and pack.fire then
            if use then
                if run.done and pack.canReturn(run, p) then
                    command(g, "BACK")
                else
                    command(g, "USE")
                end
            end
            local held = eng.input.down("fire")
            if held and (g.weapon ~= 1 or not g.triggerHeld) and g.clock >= g.nextFire then
                fire(g)
            end
            g.triggerHeld = held
            if not held then
                Feedback.endBurst(g)
            end
        elseif use or eng.input.pressed("fire") then
            command(g, "USE")
        end
    end
    if not g.online and g.space ~= p.space then
        g.x, g.z, g.yaw, g.space, g.doorGuard = p.x, p.z, p.yaw, p.space, g.clock + 0.65
    end
    if g.space == 0 then
        g.triggerHeld = nil
    end
    apply_award(g, p)
    Feedback.tick(g)
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
        local pack = MissionPacks[g.space]
        hint = run and pack and pack.hint and pack.hint(run, r.players[g.id])
            or run and run.done and "Ornament earned · walk back through the door"
            or "Use the objective · return through the doorway"
    else
        local day = Hall.near_door(g.x, g.z, 4)
        if day then
            local state = Hall.door_state(day, r.hours, MissionPacks)
            local label = state == "locked" and ("Opens " .. day .. " December") or "Mission in preparation"
            if state == "ready" then
                label = math.floor(g.awards / 2 ^ (day - 1)) % 2 == 1 and "Ornament earned · replay"
                    or "Walk through"
            end
            hint = string.format("Door %02d · %s", day, label)
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
    return table.concat({
        MissionPacks[g.space] and MissionPacks[g.space].tools and MissionPacks[g.space].tools[g.weapon]
            or Hall.weapons[g.weapon].name,
        g.weapon,
        r.hits,
        alive,
        r.wave,
        Hall.ready_count(r.hours, MissionPacks),
        count,
        g.connection,
        hint,
        g.space,
        g.awards,
        Feedback.hud(g),
        MissionPacks[g.space] and MissionPacks[g.space].tools and table.concat(
            MissionPacks[g.space].tools,
            ","
        ) or "",
        MissionPacks[g.space] and MissionPacks[g.space].unlocked and MissionPacks[g.space].unlocked(
            r.instances[g.space]
        ) or 5,
        r.players[g.id] and r.players[g.id].vital or "",
        r.instances[g.space] and r.instances[g.space].progress or "",
    }, "|")
end
function draw()
    local g = game.state
    World.sprites(g)
    local h = host_hud()
    local pack = MissionPacks[g.space]
    local name = pack and pack.tools and pack.tools[g.weapon] or Hall.weapons[g.weapon].name
    local f = g.feedback
    if f.slow then
        eng.render.draw_text("Slowed", 40, 112, 1)
    end
    if f.rearIcon and f.rearIcon.untilTime > g.clock then
        eng.render.draw_text(f.rearIcon.text, 18, 235, 1)
    end
    if f.prefs[6] == 1 then
        for i, c in ipairs(f.captions) do
            eng.render.draw_text(c.text, 18, 116 + i * 24, 1)
        end
    end
    if g.clock < f.hintUntil then
        eng.render.draw_text(f.dayText, 18, 198, 1)
    end
    eng.render.draw_text(
        pack
                and pack.tools
                and ("DAY 01   /   " .. name .. "   /   Snow hearts " .. (g.room.players[g.id].vital or 5))
            or string.format(
                "%d  %s    |    bells %d    |    wave %d",
                g.weapon,
                name,
                g.room.hits,
                g.room.wave
            ),
        18,
        18,
        1
    )
    eng.render.draw_text(
        g.connection .. "    /    " .. Hall.ready_count(g.room.hours, MissionPacks) .. " of 24 doors playable",
        18,
        50,
        1
    )
    local hint = h:match("^[^|]*|[^|]*|[^|]*|[^|]*|[^|]*|[^|]*|[^|]*|[^|]*|([^|]*)")
    if hint and #hint > 0 then
        eng.render.draw_text(hint, 18, 82, 1)
    end
end
