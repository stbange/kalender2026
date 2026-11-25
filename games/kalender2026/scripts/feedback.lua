-- Client-only presentation. Times are seconds, lengths are hall metres.
Feedback = {
    defaults = { 100, 100, 100, 0, 1, 0, 0 }, -- motion, detail, sound, vibration, marks, captions, contrast
    kick = { 0.05, 0.03, 0.015, 0.04, 0.08 },
    settle = { 0.09, 0.12, 0.065, 0.13, 0.18 },
    pulseMs = { 18, 22, 12, 22, 45 },
    pulseGain = { 0.18, 0.22, 0.12, 0.22, 0.32 },
    sources = {
        "snap1",
        "snap2",
        "snap3",
        "flurry",
        "ratchet1",
        "ratchet2",
        "release",
        "spring",
        "rocketthrow",
        "thup1",
        "thup2",
        "thup3",
        "tok",
        "rustle",
        "brush",
        "gear",
        "knock",
        "cloth1",
        "cloth2",
        "cloth3",
        "stone1",
        "stone2",
        "stone3",
        "cadence",
        "practice",
        "midnight",
        "throw",
        "bell",
        "poof",
        "d1-remote",
        "d1-freeze",
        "d1-shrink",
        "d1-twins",
        "d1-marquee",
        "d1-earthrise",
        "d1-score",
    },
    disabled = {}, -- Set an item ID to true to disable that optional cue, e.g. ["FIRE-07"]=true.
    hitTime = 0.09,
    clearTime = 0.15,
    flinchTime = 0.11,
    flinchDegrees = 6,
    hitMerge = 0.07,
    fresh = 0.25,
    powderTime = 0.14,
    stampTime = 0.60,
    bounceTime = 0.10,
    burstTime = 0.18,
    clearPuff = 0.16,
    bellReset = 1.2,
    swingTime = 0.32,
    tallyTime = 0.12,
    stride = 1.8,
    handover = 0.10,
    captionsTime = 0.85,
    approach = 2.2,
    rearm = 3,
    nearby = 12,
    spriteLimit = 48,
    mobileLimit = 24,
    stampLimit = 8,
    notes = { 523.25, 587.33, 659.25, 783.99, 880 },
    seed = 202612,
}
local F = Feedback
local function clamp(v, lo, hi)
    return math.max(lo, math.min(hi, v))
end
function F.on(id)
    return not F.disabled[id]
end
function F.new()
    local f = {
        prefs = {},
        effects = {},
        sounds = {},
        captions = {},
        visitors = {},
        trails = {},
        cursor = 0,
        flinch = {},
        stride = 0,
        step = 0,
        spinner = 0,
        variant = 0,
        recentHit = -100,
        lastKnock = {},
        markUntil = 0,
        tallyUntil = 0,
        hintUntil = 0,
        pulse = 0,
        kickStart = -1,
        swapStart = -1,
        recovery = 0,
        invite = 0,
        answer = 0,
        nextRear = 0,
    }
    local stored = eng.save.read("hall_feedback")
    f.saved = stored and stored:sub(1, 2) == "1 " or false
    for i, default in ipairs(F.defaults) do
        local v = f.saved and tonumber(stored:match(" " .. i .. "=(%d+)"))
        local max = i <= 4 and 100 or 1
        f.prefs[i] = (v and v <= max and (i > 4 or v % 10 == 0 or (i == 2 and v == 25))) and v or default
    end
    for i = 1, F.spriteLimit do
        f.effects[i] = { life = 0 }
    end
    return f
end
function host_tune(index, value)
    local f = game.state.feedback
    if index == 9 then
        if value == 1 and not f.saved then
            f.prefs[1], f.prefs[2] = 0, 25
        end
        return 0
    end
    if index == 8 then
        if value >= 0 then
            f.prefs[1], f.prefs[2] = value == 0 and 100 or 0, value == 0 and 100 or 25
        else
            return (f.prefs[1] == 0 and f.prefs[2] <= 25) and 1 or 0
        end
    elseif F.defaults[index] ~= nil then
        if value < 0 then
            return f.prefs[index]
        end
        if index <= 4 then
            value = clamp(math.floor((value + 5) / 10) * 10, 0, 100)
        else
            value = clamp(value, 0, 1)
        end
        f.prefs[index] = value
        if index == 3 and value == 0 then
            f.sounds = {}
        end
    else
        return 0
    end
    local parts = { "1" }
    for i, v in ipairs(f.prefs) do
        parts[#parts + 1] = i .. "=" .. v
    end
    f.saved = eng.save.write("hall_feedback", table.concat(parts, " "))
    if not f.saved then
        game.state.flavor = "Could not save feedback preferences"
        game.state.noteUntil = game.state.clock + 3
    end
    return index == 8 and host_tune(8, -1) or f.prefs[index]
end
function host_pulse()
    local f = game.state.feedback
    local pulse = f.pulse
    f.pulse = 0
    return pulse
end
local function distance(g, x, z)
    return (x - g.x) ^ 2 + (z - g.z) ^ 2
end
-- Priority 3 reserves room for a local throw/hit or bell. Within a priority keep nearby cues.
function F.sound(g, name, gain, pitch, priority, x, y, z, far)
    local f = g.feedback
    if f.prefs[3] == 0 then
        return
    end
    local d = x and distance(g, x, z) or 0
    if x and d > (far or F.nearby) ^ 2 then
        return
    end
    local q = f.sounds
    local rank = priority * 1000 - math.sqrt(d)
    if #q == 8 and rank <= q[8].rank then
        return
    end
    local at = math.min(8, #q + 1)
    while at > 1 and q[at - 1].rank < rank do
        q[at] = q[at - 1]
        at = at - 1
    end
    q[at] = {
        rank = rank,
        line = string.format(
            "%s %.3f %.3f %d %d %.3f %.3f %.3f %.2f",
            name,
            gain,
            pitch,
            priority,
            x and 1 or 0,
            x or 0,
            y or 0,
            z or 0,
            far or F.nearby
        ),
    }
end
function host_sound()
    local f = game.state.feedback
    local lines = {}
    for i, cue in ipairs(f.sounds) do
        lines[i] = cue.line
    end
    f.sounds = {}
    return table.concat(lines, "\n")
end
local function vary(f, sequence)
    f[sequence] = (f[sequence] or 0) % 3 + 1
    f.variant = (f.variant + 1) % 997
    return f[sequence], ((f.variant * 37) % 101 - 50) / 50
end
function F.caption(g, text, x, y, z, icon, duration)
    local f = g.feedback
    if f.prefs[6] == 0 then
        return
    end
    for _, c in ipairs(f.captions) do
        if c.text == text then
            c.untilTime = g.clock + (duration or F.captionsTime)
            return
        end
    end
    if #f.captions >= 2 then
        table.remove(f.captions, 1)
    end
    f.captions[#f.captions + 1] =
        { text = text, x = x, y = y, z = z, icon = icon, untilTime = g.clock + (duration or F.captionsTime) }
end
function F.limit(g)
    return math.floor(
        (TouchHall or g.xr) and math.min(F.spriteLimit, F.mobileLimit) * g.feedback.prefs[2] / 100
            or F.spriteLimit * g.feedback.prefs[2] / 100
    )
end
function F.particle(g, kind, x, y, z, vx, vy, vz, size, life, plane)
    local f = g.feedback
    local limit = F.limit(g)
    if limit <= 0 then
        return
    end
    local slot, farSlot, farDist = nil, nil, F.nearby ^ 2
    local marks, oldest = 0, nil
    for i = 1, limit do
        local e = f.effects[i]
        if e.life == 0 or g.clock >= e.start + e.life then
            slot = slot or e
        else
            local d = distance(g, e.x, e.z)
            if d > farDist then
                farSlot, farDist = e, d
            end
            if e.kind == "stamp" then
                marks = marks + 1
                if not oldest or e.start < oldest.start then
                    oldest = e
                end
            end
        end
    end
    if kind == "stamp" and marks >= F.stampLimit then
        slot = oldest
    end
    if not slot and farSlot and distance(g, x, z) < farDist then
        slot = farSlot
    end
    if not slot then
        return
    end
    slot.kind, slot.x, slot.y, slot.z = kind, x, y, z
    slot.vx, slot.vy, slot.vz = vx, vy, vz
    slot.size, slot.life, slot.start, slot.plane, slot.angle = size, life, g.clock, plane, 0
    return slot
end
local function flecks(g, kind, x, y, z, count, size, life, reach)
    local f = g.feedback
    for i = 1, count do
        f.variant = (f.variant + 17) % 997
        local a = i * 2.39996 + f.variant
        F.particle(
            g,
            kind,
            x,
            y,
            z,
            math.sin(a) * reach / life,
            (0.18 + 0.35 * (i % 3)) * reach / life,
            math.cos(a) * reach / life,
            size,
            life
        )
    end
end
function F.shot(g, a)
    local f, w = g.feedback, g.weapon
    f.kickStart, g.recoil, f.swapStart = g.clock, F.kick[w], -1
    local n, j = vary(f, "throwTake")
    if F.on("FIRE-0" .. (w + 1)) then
        local names = { "snap" .. n, "flurry", "ratchet" .. (f.spinner % 2 + 1), "spring", "rocketthrow" }
        F.sound(g, names[w], 0.72, w == 1 and 1 + 0.03 * j or 1, 3)
    end
    f.spinner = w == 3 and f.spinner + 1 or 0
    if w == 2 and F.on("FIRE-03") then
        local spread = Hall.weapons[2].spread
        for side = -1, 1 do
            local co, si = math.cos(side * spread), math.sin(side * spread)
            local dx, dz = a.dx * co + a.dz * si, a.dz * co - a.dx * si
            F.particle(
                g,
                "powder",
                g.x + a.ox + dx * 0.70,
                1.55 + a.oy + a.dy * 0.7 - 0.07,
                g.z + a.oz + dz * 0.70,
                dx * 3,
                a.dy * 3,
                dz * 3,
                0.06,
                0.085
            )
        end
    elseif g.xr then
        F.particle(
            g,
            "powder",
            g.x + a.ox + a.dx * 0.34,
            1.55 + a.oy + a.dy * 0.34,
            g.z + a.oz + a.dz * 0.34,
            a.dx,
            a.dy,
            a.dz,
            0.05,
            0.07
        )
    end
    if g.xr and F.on("FIRE-09") and f.prefs[4] > 0 then
        f.pulse = F.pulseMs[w] * 1000 + math.floor(f.prefs[4] * F.pulseGain[w] + 0.5)
    end
end
function F.endBurst(g)
    local f = g.feedback
    if f.spinner >= 3 and F.on("FIRE-04") then
        F.sound(g, "release", 0.4, 1, 2)
    end
    f.spinner = 0
end
function F.switch(g)
    F.endBurst(g)
    g.feedback.swapStart = g.clock
    g.feedback.kickStart = -1
end
function F.knock(g, day)
    local f = g.feedback
    if F.on("HALL-06") and g.clock >= (f.lastKnock[day] or -1) + 0.9 then
        f.lastKnock[day] = g.clock
        local x, z = Hall.door(day)
        F.sound(g, "knock", 0.5, 1, 1, x, 1.8, z)
    end
end
function F.mark(g, e, finished)
    local f = g.feedback
    if f.prefs[5] == 0 then
        return
    end
    if not finished and f.markSeq == e.seq and f.mark == "finish" then
        return
    end
    f.mark = finished and "finish" or "ticks"
    f.markUntil = g.clock + (finished and F.clearTime or F.hitTime)
    f.markSeq, f.mx, f.my, f.mz = e.seq, e.x, e.y, e.z
end
local function outcome(g, e)
    local f, ev = g.feedback, Hall.event
    local owned = e.owner == g.id and e.seat == g.room.players[g.id].seat
    local code, x, y, z = e.code, e.x, e.y, e.z
    if code == ev.hit or code == ev.clear then
        local done = code == ev.clear
        if owned and F.on(done and "HIT-05" or "HIT-01") then
            F.mark(g, e, done)
        end
        if F.on("HIT-03") then
            flecks(g, "powder", x, y, z, 5, 0.055, F.powderTime, 0.18)
        end
        if done then
            if F.on("VIS-10") then
                local kind = ({ "powder", "crumb", "scratch", "gear", "mote" })[e.target]
                local m = g.room.mobs[e.target]
                if m and m.hp == 0 then
                    x, y, z = m.x, m.y, m.z
                end
                flecks(g, kind, x, y, z, 3, 0.11, F.clearPuff, 0.28)
                F.sound(g, "poof", 0.48, 1, 2, x, y, z)
            end
        else
            if F.on("HIT-02") then
                f.flinch[e.target] = { start = g.clock, angle = e.value }
            end
            if owned and F.on("HIT-04") and (e.seq ~= f.hitSeq or g.clock - f.recentHit >= F.hitMerge) then
                local n, j = vary(f, "hitTake")
                F.sound(g, "thup" .. n, 0.45, 1 + 0.04 * j, 3)
                f.hitSeq, f.recentHit = e.seq, g.clock
            end
        end
    elseif code == ev.launch then
        if not owned and F.on("FIRE-11") and distance(g, x, z) <= F.nearby ^ 2 then
            flecks(g, "powder", x, y, z, 2, 0.08, 0.09, 0.13)
            F.sound(g, "throw", 0.30, 1.06, 1, x, y, z)
        end
    elseif code == ev.bell then
        local t = Hall.targets[e.target]
        if not t then
            return
        end
        if F.on("HALL-02") then
            F.sound(g, "bell", 0.72, F.notes[e.target] / 784, 3, t[1], t[2], t[3], 18)
        else
            F.sound(g, "bell", 0.72, 1, 3)
        end
        if F.on("HIT-03") then
            flecks(g, "powder", x, y, z, 5, 0.05, F.powderTime, 0.18)
        end
        if F.on("HALL-03") then
            f.tallyUntil = g.clock + F.tallyTime
        end
        F.caption(g, "Bell " .. e.target, t[1], t[2] + 0.45, t[3], "bellcue")
    elseif code == ev.burst and F.on("HIT-06") then
        for i = 1, 8 do
            local a = i * math.pi / 4
            F.particle(
                g,
                "ring",
                x,
                y,
                z,
                math.sin(a) * e.value / F.burstTime,
                0,
                math.cos(a) * e.value / F.burstTime,
                0.20,
                F.burstTime
            )
        end
    elseif code == ev.bounce and F.on("HIT-07") then
        F.particle(g, "scratch", x, y, z, 0, 0, 0, 0.12, F.bounceTime, e.target)
        F.sound(g, "tok", 0.58, 1.34 - 0.13 * e.value, 2, x, y, z, 18)
    elseif code == ev.wall and e.weapon ~= 5 and F.on("HIT-08") and not Hall.near_door(x, z, 1.6) then
        F.particle(g, "stamp", x, y, z, 0, 0, 0, 0.14, F.stampTime, e.target)
    elseif code == ev.practice and F.on("HALL-08") then
        f.answer = g.clock + 0.22
        F.sound(g, "practice", 0.6, 1, 2, x, y, z, 18)
        F.caption(g, "Practice wave", x, y, z, "practicecue")
    elseif code == ev.waveClear and F.on("HALL-07") then
        f.invite = g.clock + 0.9
        F.sound(g, "cadence", 0.6, 1, 2)
        F.caption(g, "Hall clear", x, y, z, "clearcue")
    end
end
function F.baseline(g, quiet)
    local f, r = g.feedback, g.room
    f.cursor, f.day, f.wave, f.space = r.eventId, r.hours, r.wave, g.space
    f.slow = g.space == 0 and r.players[g.id] and r.players[g.id].slow > r.time
    f.markUntil, f.tallyUntil, f.invite, f.answer, f.recovery, f.pulse = 0, 0, 0, 0, 0, 0
    f.kickStart, f.swapStart, f.spinner, f.stride, f.step, f.nextRear = -1, -1, 0, 0, 0, 0
    f.hitSeq, f.markSeq, f.rearIcon = nil, nil, nil
    f.hintUntil = 0
    f.sounds, f.captions, f.trails, f.visitors, f.flinch, f.lastKnock = {}, {}, {}, {}, {}, {}
    f.quietWake = quiet
    for _, e in ipairs(f.effects) do
        e.life = 0
    end
end
function F.consume(g)
    local f, r = g.feedback, g.room
    if f.space ~= g.space then
        F.baseline(g, true)
        return
    end
    for _, e in ipairs(r.events) do
        if e.id > f.cursor and g.space == 0 and (not g.menu or g.xr) and r.time - e.time <= F.fresh then
            outcome(g, e)
        end
    end
    f.cursor = r.eventId
end
function F.walk(g, dx, dz)
    local f = g.feedback
    if g.space ~= 0 then
        return
    end
    local dist = math.sqrt(dx * dx + dz * dz)
    f.stride = f.stride + dist
    f.walking = dist > 0.0001
    if f.walking then
        f.walkAt = g.clock
    end
    if f.stride >= F.stride then
        f.stride = f.stride % F.stride
        f.step = f.step + 1
        if F.on("HALL-04") then
            local cloth = math.abs(g.x) <= 2.8 or math.abs(g.z) <= 2.25
            F.sound(
                g,
                (cloth and "cloth" or "stone") .. ((f.step - 1) % 3 + 1),
                0.31,
                f.step % 2 == 1 and 0.98 or 1.02,
                1
            )
        end
    end
end
function F.tick(g)
    local f, r = g.feedback, g.room
    if f.resume then
        F.baseline(g, true)
        f.resume = false
    end
    F.consume(g)
    local slow = r.players[g.id].slow > r.time and g.space == 0
    if f.slow and not slow and F.on("VIS-03") then
        f.recovery = g.clock + 0.10
        F.sound(g, "brush", 0.45, 1, 2)
    end
    f.slow = slow
    if f.day ~= r.hours then
        if r.hours > f.day and r.hours > 0 and F.on("HALL-09") and g.space == 0 then
            local day = r.hours
            f.dayText = string.format(
                "Door %02d due · %s",
                day,
                MissionPacks[day] and "Walk through" or "Mission in preparation"
            )
            f.hintUntil = g.clock + 1.5
            local x, z = Hall.door(day)
            F.caption(g, f.dayText, x, 3, z, "doorcue", 1.5)
            F.sound(g, "midnight", 0.54, 1, 2)
        end
        f.day = r.hours
    end
    for i = #f.captions, 1, -1 do
        if f.captions[i].untilTime <= g.clock then
            table.remove(f.captions, i)
        end
    end
    g.recoil = F.on("FIRE-01")
            and F.kick[g.weapon] * math.max(0, 1 - (g.clock - f.kickStart) / F.settle[g.weapon]) ^ 2 * f.prefs[1] / 100
        or 0
end
function host_flat_marks()
    local g = game.state
    local f = g.feedback
    local mark = 0
    if f.prefs[5] == 1 and g.clock < f.markUntil then
        mark = f.mark == "finish" and 2 or 1
    end
    return string.format(
        "%d %d %d %d %d",
        mark,
        f.prefs[7],
        (f.slow and F.on("VIS-02") or g.clock < f.recovery) and 1 or 0,
        (g.clock < f.tallyUntil and f.prefs[1] > 0) and 1 or 0,
        g.room.hits
    )
end
function F.hud(g)
    local f = g.feedback
    local mark = (f.prefs[5] == 1 and g.clock < f.markUntil) and f.mark or ""
    local slow = f.slow and F.on("VIS-02") and "Slowed" or ((g.clock < f.recovery) and "Recovered" or "")
    local lines = {}
    if f.prefs[6] == 1 then
        for _, c in ipairs(f.captions) do
            lines[#lines + 1] = c.text
        end
    end
    local rear = f.rearIcon and f.rearIcon.untilTime > g.clock and f.rearIcon.text or ""
    return table.concat({
        mark,
        slow,
        table.concat(lines, " / "),
        g.clock < f.tallyUntil and 1 or 0,
        f.prefs[7],
        g.clock < f.hintUntil and f.dayText or "",
        rear,
        f.prefs[1],
    }, "|")
end
