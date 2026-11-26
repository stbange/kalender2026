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
    local steps = math.max(1, math.ceil(math.sqrt((tx - x) ^ 2 + (tz - z) ^ 2) * 2))
    for i = 0, steps do
        for _, b in ipairs(map.blocks) do
            if
                math.abs(x + (tx - x) * i / steps - b.x) < b.w / 2 + 0.3
                and math.abs(z + (tz - z) * i / steps - b.z) < b.d / 2 + 0.3
            then
                return false
            end
        end
    end
    return true
end
local route = 1
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
        last, stalled, route = phase, f, 1
        visited[map.city] = true
    end
    if f - stalled > 7000 then
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
    for _, a in ipairs(run.actors) do
        if a.hp > 0 then
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
    if (tx - g.x) ^ 2 + (tz - g.z) ^ 2 < 2.4 then
        eng.input.inject("interact", f % 2 == 0)
        return
    end
    local index = (phase - 1) % 3 + 1
    local entry = index == 1 and map.x or map.rooms[index - 1].gate
    local points = { { entry, court.front - 3.2 }, { map.x, court.front - 3.2 }, { map.x, court.back + 3.3 } }
    local dest = points[route]
    if dest and (dest[1] - g.x) ^ 2 + (dest[2] - g.z) ^ 2 < 0.4 then
        route = route + 1
        dest = points[route]
    end
    walk(g, dest and dest[1] or tx, dest and dest[2] or tz)
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
