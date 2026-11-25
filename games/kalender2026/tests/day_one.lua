-- Deterministic, no teleports. Drive the shipping solo input loop through Door 1.
local phaseAt, phaseSeen, launchWait = 0, 0, 0
local wings = { [2] = { 1, -21 }, [6] = { -1, -80 }, [9] = { -1, -125 }, [16] = { 1, -234 } }
local edges = { -41, -97, -143, -168, -253 }
local function path(x, z, tx, tz, wing)
    if wing then
        local side, center = wing[1], wing[2]
        local a, b = x * side, tx * side
        local walls = { { 14, 0 }, { 14 + 23 * 2.85, -8 }, { 14 + 42 * 2.85, 8 }, { 14 + 61 * 2.85, -8 } }
        if a > b then
            walls = { walls[4], walls[3], walls[2], walls[1] }
        end
        for _, wall in ipairs(walls) do
            local u, v = wall[1], center + wall[2]
            if (a < u + 1.2 and b > u + 2) or (a > u - 1.2 and b < u - 2) then
                if math.abs(z - v) > 1.2 then
                    return (a < b and u - 2.1 or u + 2.1) * side, v
                end
                return (a < b and u + 2.6 or u - 2.6) * side, v
            end
        end
    end
    for _, edge in ipairs(edges) do
        if z > edge - 0.8 and tz < edge - 1 then
            if math.abs(x) > 1.8 then
                return 0, edge + 1.5
            end
            return 0, edge - 3
        end
    end
    return tx, tz
end
local function face(g, x, z)
    g.yaw = math.deg(math.atan2(g.x - x, g.z - z)) % 360
    g.pitch = 0
end
local function walk(g, x, z, stop)
    face(g, x, z)
    local distance = math.sqrt((x - g.x) ^ 2 + (z - g.z) ^ 2)
    eng.input.inject("up", distance > stop)
    return distance <= stop
end
function playtest_frame(f)
    HostUTC = 1796079599
    local g = game.state
    eng.input.inject("fire", false)
    eng.input.inject("interact", false)
    eng.input.inject("up", false)
    if g.space == 0 then
        if phaseSeen == 20 then
            if walk(g, 0, -11, 0.4) then
                local bell = Hall.targets[3]
                host_weapon(1)
                face(g, bell[1], bell[3])
                g.pitch = math.deg(math.atan2(bell[2] - 1.55, math.abs(g.z - bell[3])))
                eng.input.inject("fire", true)
            end
            g.playtest_done = g.room.hits > 0
            return
        end
        local x, z = Hall.door(1)
        walk(g, x, z, 0.4)
        return
    end
    local m = MissionPacks[1]
    local run = g.room.instances[1]
    local p = g.room.players[g.id]
    local k = run.progress
    if k ~= phaseSeen then
        phaseSeen, phaseAt = k, f
    end
    if f - phaseAt > 32000 then
        error("No progress at " .. m.hint(run, p) .. " position " .. g.x .. "," .. g.z)
    end
    local x, z = m.destination(run)
    local wing = wings[k]
    local function action()
        eng.input.inject("interact", f % 3 == 0)
    end
    local function shot(tool, ax, az, repeatFire)
        host_weapon(tool)
        face(g, ax, az)
        eng.input.inject("fire", repeatFire or f % 4 == 0)
    end
    if run.done then
        if walk(g, 0, -302, 1) then
            action()
            phaseAt = f
        end
        return
    end
    -- Put down the ushers and couriers before operating the machinery.
    for _, a in ipairs(run.actors) do
        if (a.kind <= 2 or a.kind == 7) and a.hp > 0 and (a.x - g.x) ^ 2 + (a.z - g.z) ^ 2 < 45 then
            local available = m.unlocked(run)
            local tool = available >= 5 and 5 or available >= 3 and 3 or 1
            shot(tool, a.x, a.z, true)
            return
        end
    end
    if k == 3 or k == 19 then
        local cx, cz = m.cart(run)
        local ax, az = path(g.x, g.z, 0, cz + 5)
        if walk(g, ax, az, 0.8) and math.abs(g.z - cz) < 7 then
            shot(1, k == 3 and 0 or cx, cz, true)
        end
        return
    end
    if k == 4 or k == 8 or k == 13 then
        local kind = ({ [4] = 3, [8] = 4, [13] = 5 })[k]
        for _, a in ipairs(run.actors) do
            if a.kind == kind then
                local ax, az = path(g.x, g.z, a.x, a.z + 0.75)
                if walk(g, ax, az, 0.45) or (math.abs(g.x - a.x) < 3 and math.abs(g.z - a.z) < 3) then
                    if k == 4 and a.ice > run.clock then
                        if not run.slide and walk(g, a.x - 1.15, a.z + 0.95, 0.35) then
                            action()
                        end
                    elseif k ~= 13 or a.small <= run.clock then
                        shot(({ [4] = 2, [8] = 3, [13] = 4 })[k], a.x, a.z, true)
                    end
                end
                return
            end
        end
    end
    if k == 18 then
        local ax, az = path(g.x, g.z, x, z + 0.5)
        walk(g, ax, az, 0.35)
        for _, a in ipairs(run.actors) do
            if a.kind == 7 and a.hp > 0 and (a.x - g.x) ^ 2 + (a.z - g.z) ^ 2 < 100 then
                eng.input.inject("up", false)
                shot(5, a.x, a.z, true)
                return
            end
        end
        return
    end
    local ax, az = path(g.x, g.z, x, z, wing)
    if walk(g, ax, az, (ax == x and az == z) and 1.3 or 0.32) and (g.x - x) ^ 2 + (g.z - z) ^ 2 < 6 then
        if wing and m.inTransit(run) then
            action()
        elseif wing and run.job == 1 and k ~= 2 then
            shot(({ [6] = 2, [9] = 3, [16] = 4 })[k], x, z, true)
        else
            action()
        end
    end
    if k == 12 then
        launchWait = launchWait + 1
    end
end
function playtest_verify()
    local g = game.state
    eng.log.info(string.format("Day 1 scripted solo route %.1f simulated minutes", g.clock / 60))
    eng.test.assert_eq(eng, phaseSeen, 20, "Reached the Moon Bowl finish")
    eng.test.assert_eq(eng, g.space, 0, "Walked back to the hall")
    eng.test.assert_true(
        eng,
        g.awards % 2 == 1 and g.seq > 5,
        "Earned and saved Day 1 by firing the mission weapons"
    )
    eng.test.assert_true(eng, g.room.hits > 0, "Rang a hall bell after returning")
    eng.test.assert_true(eng, launchWait > 60, "Played the mail flight")
end
