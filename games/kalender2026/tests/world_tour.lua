-- Play through the shipping input loop. Take a real hit before firing back.
local visited, hurt, rooftopHit, finished, last, stalled = {}, false, false, false, 0, 0
local function face(g, x, z)
    g.yaw = math.deg(math.atan2(g.x - x, g.z - z)) % 360
end
local function walk(g, x, z)
    face(g, x, z)
    eng.input.inject("up", true)
end
local function clear(map, x, z, tx, tz)
    for _, b in ipairs(map.blocks) do
        local low, high = 0, 1
        local function crosses(pos, delta, min, max)
            if math.abs(delta) < 0.0001 then
                return pos >= min and pos <= max
            end
            local a, b = (min - pos) / delta, (max - pos) / delta
            low, high = math.max(low, math.min(a, b)), math.min(high, math.max(a, b))
            return low <= high
        end
        if
            crosses(x, tx - x, b.x - b.w / 2 - 0.02, b.x + b.w / 2 + 0.02)
            and crosses(z, tz - z, b.z - b.d / 2 - 0.02, b.z + b.d / 2 + 0.02)
        then
            return false
        end
    end
    return true
end

function playtest_frame(f)
    local g = game.state
    eng.input.inject("fire", false)
    eng.input.inject("up", false)
    eng.input.inject("interact", false)
    if g.space == 0 then
        if finished then
            g.playtest_done = true
            return
        end
        walk(g, Hall.door(1))
        return
    end
    local run = g.room.instances[1]
    local p = g.room.players[g.id]
    if not run.seed then
        if p.vital < 5 then
            rooftopHit = true
        end
        eng.input.inject("interact", rooftopHit and f % 2 == 0)
        return
    end
    local map = run.layout
    local phase = run.progress
    if last ~= phase then
        last, stalled = phase, f
        visited[map.city] = true
    end
    if f - stalled > 7000 then
        local nx, nz = MissionPacks[1].destination(run, p)
        eng.log.info(string.format("waypoint %.2f %.2f phase %d", nx, nz, phase))
        for _, a in ipairs(run.actors) do
            if a.hp > 0 then
                eng.log.info(
                    string.format(
                        "remaining kind %d hp %d at %.2f %.2f clear %s",
                        a.kind,
                        a.hp,
                        a.x,
                        a.z,
                        tostring(clear(map, g.x, g.z, a.x, a.z))
                    )
                )
            end
        end
        error(
            "Stuck in sector "
                .. phase
                .. " at "
                .. g.x
                .. ","
                .. g.z
                .. " / "
                .. MissionPacks[1].hint(run, p)
        )
    end
    if run.done then
        finished = true
        eng.input.inject("interact", f % 2 == 0)
        return
    end
    if p.vital < 5 then
        hurt = true
    end
    if not hurt then
        return
    end
    local court = map.rooms[(phase - 1) % 3 + 1]
    local tx, tz = court.gate, court.back + 1.7
    local alive = false
    for _, a in ipairs(run.actors) do
        if a.hp > 0 then
            alive = true
            tx, tz = a.x, a.z
            if (tx - g.x) ^ 2 + (tz - g.z) ^ 2 < 31 ^ 2 and clear(map, g.x, g.z, tx, tz) then
                host_weapon(3)
                face(g, tx, tz)
                g.pitch = 0
                eng.input.inject("fire", true)
                return
            end
        end
    end
    if not alive and (tx - g.x) ^ 2 + (tz - g.z) ^ 2 < 2.4 then
        eng.input.inject("interact", f % 2 == 0)
        return
    end
    local nx, nz = MissionPacks[1].destination(run, p)
    walk(g, nx, nz)
end
function playtest_verify()
    eng.test.assert_true(
        eng,
        hurt and rooftopHit,
        "Incoming enemy fire took a heart from a stationary player"
    )
    eng.test.assert_true(eng, visited[1] and visited[2] and visited[3] and last == 9, "Played all three maps")
    eng.test.assert_true(
        eng,
        finished and game.state.space == 0 and game.state.awards % 2 == 1,
        "Returned with ornament"
    )
end
