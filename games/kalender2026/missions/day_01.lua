-- Last Launch from Tinseltown. Coordinates are metres, with Luna to the north.
local M = {
    title = "Last Launch from Tinseltown",
    ornament = "brass-rocket",
    tools = { "Snow Cracker", "Freezer", "Snow Rocket", "Shrink Ray", "Twin Tinsel Launchers" },
    delays = { 0.19, 0.28, 0.72, 0.32, 0.12 },
}
MissionPacks[1] = M
-- The brass beacon marks the current destination and doubles as a landmark in VR.
local stops = {
    { "Rooftop", "Walk to the striped air vent. Use to drop inside.", -8, -9 },
    { "Midnight cinema", "Use the projector. Where is the courier taking that sack?", 9, -21 },
    { "Moon Bowl matinee", "Fire 1 at the cart. Press again beneath the gold latch.", 0, -34 },
    { "Dead-letter diner", "Freeze the skating boar with 2. Use its statue to slide it.", -5, -55 },
    { "Service bell", "Follow the sliding statue to the till. Collect the red ticket.", 9, -66 },
    { "Dead-letter office", "Find the red reader and stamp the dispatch ticket.", -10, -80 },
    { "Freight lift", "Use the red ticket at the gantry lift.", 7, -92 },
    { "Twin silos", "Break the loader armor with the Snow Rocket (3).", 0, -116 },
    { "Overnight dispatch", "The parcel is away! Stamp your ticket OVERNIGHT.", -9, -125 },
    { "Reserve rocket", "Board the striped rocket. Use the launch handle.", 2, -148 },
    { "Special delivery", "In flight. Use the rattling mail locker.", -4, -151 },
    { "Luna approach", "Watch Earth through the porthole. Exit when docked.", 0, -161 },
    { "Lunar customs", "Shrink the customs guard with 4, then walk over it.", 0, -183 },
    { "Parcel sizer", "Use the scale to enter the tabletop sorting railway.", -9, -197 },
    { "Sorting railway", "Follow the brass rails. Pull the lever between the stamps.", 9, -213 },
    { "Incubator", "Inspect the brass mold behind the hatching mail sacks.", -8, -234 },
    { "Players' tunnel", "Open the locker for twin launchers. Take the midfield lift.", 2, -250 },
    { "Moon Bowl", "Clear the eggs with 5. Bait the Queen to the gold goalpost.", 0, -278 },
    { "Sideline cart", "Fire 1 at the cart. Click again beneath the gold latch!", 0, -288 },
    { "Return to sender", "Collect the brass rocket at midfield.", 0, -296 },
}
M.stops = stops
-- Four side routes link back to the main chase. Each threshold has cover and
-- a plainly visible gap. Teammates can work the controls or cover the runner.
local wings = {
    [2] = {
        label = "Film archive",
        z = -21,
        side = 1,
        jobs = {
            "Find the projectionist's spare reel",
            "Use the splicer under the blue lamp",
            "Collect the developed print",
            "Thread the return reel",
        },
    },
    [6] = {
        label = "Parcel exchange",
        z = -80,
        side = -1,
        jobs = {
            "Collect the express sacks",
            "Freeze the runaway belt motor",
            "Stamp the red lunar docket",
            "Unlock the outbound chute",
        },
    },
    [9] = {
        label = "Launch control",
        z = -125,
        side = -1,
        jobs = {
            "Read the captured flight plan",
            "Free the iced relay with a Snow Rocket",
            "Power the reserve gantry",
            "Authorize crew boarding",
        },
    },
    [16] = {
        label = "Alien hatchery",
        z = -234,
        side = 1,
        jobs = {
            "Inspect the first clutch",
            "Shrink the swollen egg in the scanner",
            "Collect the mold serial",
            "Unlock the quarantine hatch",
        },
    },
}
local machines = { { 25, -9 }, { 47, 9 }, { 69, -9 }, { 87, 8 } }
-- Full-sized side galleries follow a zigzag freight track. Each load stops at
-- four working machines; players can boost it and fight alongside it.
local function span(u)
    return 14 + (u - 14) * 2.85
end
local freightRoute = {
    { 14, 0 },
    { 20, -4 },
    { 25, -9 },
    { 37, -8 },
    { 42, 5 },
    { 47, 9 },
    { 56, 8 },
    { 62, -4 },
    { 69, -9 },
    { 75, -8 },
    { 81, 6 },
    { 87, 8 },
}
local sidings = { 3, 6, 9, 12 }
local loads =
    { [2] = "film trolley", [6] = "express sacks", [9] = "gantry carriage", [16] = "specimen cradle" }
local function inTransit(run)
    return wings[run.progress] and run.job < 4 and run.track <= sidings[run.job + 1]
end
M.inTransit = inTransit
local posts = { { 0, -278 }, { -8, -266 }, { 8, -289 } }
local function destination(run)
    if run.progress == 18 then
        local post = posts[run.drive]
        return post[1],
            post[2],
            "Clear hatchlings. Draw her charge to the flashing post (" .. run.drive .. "/3)."
    end
    local wing = wings[run.progress]
    local job = (run.job or 0) + 1
    if wing and machines[job] then
        local m = machines[job]
        if inTransit(run) then
            return run.loadX,
                run.loadZ,
                "Escort the " .. loads[run.progress] .. ". Use nearby to crank it faster."
        end
        return wing.side * span(m[1]), wing.z + m[2], wing.jobs[job]
    end
    local s = stops[run.progress]
    return s[3], s[4], s[2]
end
M.destination = destination
local function wingAt(x, z)
    for _, wing in pairs(wings) do
        if x * wing.side > 13 and math.abs(z - wing.z) < 14 then
            return wing
        end
    end
end
local function wingMove(x, z, dx, dz, wing)
    local u = x * wing.side
    local v = z - wing.z
    local nextU = Hall.clamp(u + dx * wing.side, 0, span(92))
    local nextV = Hall.clamp(v + dz, -13.5, 13.5)
    if math.abs(nextV) > 2.9 and math.min(u, nextU) <= 14.5 then
        nextU = math.max(14.6, u)
    end
    for i = 1, 3 do
        local wall = span(18 + i * 19)
        local gap = (-1) ^ i * 8
        if math.abs(nextV - gap) > 3 and math.abs(nextU - wall) < 0.8 then
            if math.abs(u - wall) >= 0.8 then
                nextU = u
            else
                nextV = v
            end
        end
    end
    return nextU * wing.side, wing.z + nextV
end

local boundaries = { -41, -97, -143, -168, -253, -307 }
local roofEnd = -9
function M.area(z)
    for i, edge in ipairs(boundaries) do
        if z > edge then
            return i
        end
    end
    return 6
end
local function dist(x, z, a, b)
    return (x - a) ^ 2 + (z - b) ^ 2
end
local function near(p, x, z, r)
    return dist(p.x, p.z, x, z) < r * r
end
local function checkpoint(run)
    if run.progress >= 18 then
        return -253
    end
    if run.progress >= 13 then
        return -169
    end
    if run.progress >= 8 then
        return -98
    end
    return 5
end
function M.enter(run, p)
    p.x, p.z, p.tiny, p.cracker, p.vital = 0, checkpoint(run), false, nil, 5
    p.lastHurt = nil
    p.immunity = run.clock + 6
end
function M.exit(_, p)
    p.tiny, p.cracker, p.vital = nil, nil, nil
end
local function toolsAt(k)
    if k >= 17 then
        return 5
    elseif k >= 13 then
        return 4
    elseif k >= 8 then
        return 3
    elseif k >= 4 then
        return 2
    end
    return 1
end
function M.unlocked(run)
    return toolsAt(run.progress)
end
local function mob(run, kind, x, z, hp)
    run.actors[#run.actors + 1] = { kind = kind, x = x, z = z, hp = hp, ice = 0, small = 0, dx = 0, dz = 0 }
end
local function advance(run)
    run.progress = math.min(#stops, run.progress + 1)
    run.job, run.changed = 0, run.clock
    local k = run.progress
    if k == 9 then
        run.liftoff = run.clock
    end
    if wings[k] then
        local w = wings[k]
        run.loadX, run.loadZ = w.side * 14, w.z
        run.track, run.boost, run.raid = 2, 0, 0
    end
    if k == 2 or k == 4 or k == 6 or k == 8 or k == 10 or k == 11 or k == 13 or k == 16 or k == 18 then
        run.actors = {}
        local count = math.min(8, 2 + run.members)
        local z = stops[k][4]
        for i = 1, count do
            mob(run, i % 2 + 1, (-1) ^ i * (4 + i % 5), z + 2 * (i % 3), 2)
        end
        if k == 4 then
            mob(run, 3, -5, -55, 4)
        end
        if k == 8 then
            mob(run, 4, 0, -116, 5)
        end
        if k == 13 then
            mob(run, 5, 0, -183, 5)
        end
        if k == 18 then
            mob(run, 6, 0, -282, 20)
            for i = 1, count do
                mob(run, 7, i - count / 2, -268 - i, 1)
            end
        end
    end
end
function M.start(run)
    run.progress, run.clock, run.launch, run.charge, run.actors = 1, 0, 0, 0, {}
    run.secrets, run.job, run.liftoff, run.drive, run.changed = 0, 0, 0, 1, 0
    run.track, run.loadX, run.loadZ, run.boost, run.raid = 0, 0, 0, 0, 0
end
function M.move(x, z, dx, dz, run, p)
    local wing = wingAt(x, z) or wingAt(x + dx, z + dz)
    if wing and (math.abs(x) > 14.5 or math.abs(z - wing.z) < 3) then
        return wingMove(x, z, dx, dz, wing)
    end
    if run.secrets >= 2 and math.abs(z + 261) < 2.8 and (x > 13.4 or x + dx > 13.4) then
        return Hall.clamp(x + dx, -13.4, 21.4), Hall.clamp(z + dz, -263.7, -258.3)
    end
    local width = M.area(z) == 4 and 5.5 or 13.4
    local phase = run.progress
    local stop = stops[phase]
    local edge = phase == 1 and roofEnd - 2 or stop[4] - 5
    if phase == 12 then
        edge = -163
    end
    if phase == 18 then
        edge = -301
    end
    if phase == 15 and not p.tiny then
        edge = -199
    end
    local nx = Hall.clamp(x + dx, -width, width)
    local nz = Hall.clamp(z + dz, edge, 7.4)
    -- Solid sets occupy the edges. Gaps between rooms are walk-through arches.
    for _, wall in ipairs(boundaries) do
        if math.abs(nx) > 3.1 and math.abs(nz - wall) < 0.7 then
            if math.abs(z - wall) >= 0.7 then
                nz = z
            else
                nx = x
            end
        end
    end
    return nx, nz
end
function M.cart(run)
    local z = run.progress >= 18 and -288 or -34
    return 6 * math.sin(run.clock * 0.9), z
end
local function clearEggs(run)
    for _, a in ipairs(run.actors) do
        if a.kind == 7 and a.hp > 0 then
            return false
        end
    end
    return true
end
local function freight(run, r, dt)
    if not inTransit(run) then
        return
    end
    local escorted = false
    for _, p in pairs(r.players) do
        if p.space == 1 and near(p, run.loadX, run.loadZ, 13) then
            escorted = true
        end
    end
    if not escorted then
        return
    end
    local wing = wings[run.progress]
    local waypoint = freightRoute[run.track]
    local tx, tz = wing.side * span(waypoint[1]), wing.z + waypoint[2]
    local dx, dz = tx - run.loadX, tz - run.loadZ
    local distance = math.sqrt(dx * dx + dz * dz)
    local speed = run.boost > run.clock and 1.40 or 0.88
    if distance <= speed * dt then
        run.loadX, run.loadZ, run.track = tx, tz, run.track + 1
    else
        run.loadX, run.loadZ = run.loadX + dx / distance * speed * dt, run.loadZ + dz / distance * speed * dt
    end
    if run.clock >= run.raid then
        run.raid = run.clock + 17
        local live = 0
        for i = #run.actors, 1, -1 do
            if run.actors[i].hp <= 0 then
                table.remove(run.actors, i)
            else
                live = live + 1
            end
        end
        local count = math.min(2 + math.floor(run.members / 2), 8 - live)
        for i = 1, count do
            local kind = run.progress == 16 and 7 or 1 + (i + run.track) % 2
            mob(run, kind, run.loadX + wing.side * (5 + i), run.loadZ + (-1) ^ i * 4, kind == 7 and 1 or 2)
        end
    end
end
function M.step(run, r, dt)
    run.clock = run.clock + dt
    freight(run, r, dt)
    for _, p in pairs(r.players) do
        if p.space == 1 and run.progress > 15 then
            p.tiny = false
        end
        if p.space == 1 and p.vital < 5 and run.clock - (p.lastHurt or 0) > 8 then
            p.vital = p.vital + 1
            p.lastHurt = run.clock - 6
        end
    end
    for _, a in ipairs(run.actors) do
        if a.hp > 0 then
            local player, best = nil, math.huge
            for _, p in pairs(r.players) do
                local d = dist(a.x, a.z, p.x, p.z)
                if p.space == 1 and d < best then
                    player, best = p, d
                end
            end
            if player then
                local dx, dz = player.x - a.x, player.z - a.z
                local len = math.max(0.01, math.sqrt(best))
                if a.kind == 3 then
                    if run.slide then
                        a.x, a.z = a.x + run.slideX * 9 * dt, a.z + run.slideZ * 9 * dt
                        if dist(a.x, a.z, 9, -66) < 2 and run.progress == 4 then
                            run.slide = false
                            advance(run)
                        elseif math.abs(a.x) > 12 or a.z < -73 or a.z > -44 or a.ice <= run.clock then
                            run.slide = false
                            a.x, a.z, a.ice = -5, -55, 0
                        end
                    elseif a.ice <= run.clock then
                        a.x = -5 + 3 * math.sin(run.clock)
                    end
                elseif a.kind == 6 then
                    if run.progress == 18 and best < 48 ^ 2 then
                        if run.clock >= run.charge then
                            a.dx, a.dz = dx / len, dz / len
                            run.charge = run.clock + 5
                        elseif run.charge - run.clock < 3.8 and run.charge - run.clock > 1.4 then
                            a.x = Hall.clamp(a.x + a.dx * dt * 7, -12, 12)
                            a.z = Hall.clamp(a.z + a.dz * dt * 7, -295, -257)
                        end
                        local post = posts[run.drive]
                        if dist(a.x, a.z, post[1], post[2]) < 3 ^ 2 and clearEggs(run) then
                            if run.drive == 3 then
                                advance(run)
                            else
                                run.drive = run.drive + 1
                                run.charge = 0
                                for i = 1, math.min(8, 3 + run.members) do
                                    mob(run, 7, (-1) ^ i * (6 + i % 4), -278 + (-1) ^ run.drive * i * 1.7, 2)
                                end
                            end
                        end
                    end
                elseif
                    a.small > run.clock
                    and best < 1.8 ^ 2
                    and (a.kind == 5 or a.kind <= 2 or a.kind == 7)
                then
                    a.hp = 0
                    if a.kind == 5 and run.progress == 13 then
                        advance(run)
                    end
                elseif a.kind ~= 4 and a.ice <= run.clock and best < 18 ^ 2 and best > 1.2 then
                    local speed = a.kind == 7 and 2.3 or 1.1
                    a.x, a.z = a.x + dx / len * dt * speed, a.z + dz / len * dt * speed
                end
                if
                    a.hp > 0
                    and a.ice <= run.clock
                    and a.small <= run.clock
                    and best < 1.6 ^ 2
                    and player.immunity <= run.clock
                then
                    player.immunity = run.clock + 2.5
                    player.vital = player.vital - 1
                    player.lastHurt = run.clock
                    player.slow = r.time + 1
                    if player.vital <= 0 then
                        M.enter(run, player)
                    end
                end
            end
        end
    end
end
local function aimed(p, x, z, dx, dy, dz, y, radius)
    local ax, ay, az = x - p.x, y - (p.tiny and 0.6 or 1.55) - (p.oy or 0), z - p.z
    local along = ax * dx + ay * dy + az * dz
    return along >= -0.3 and along < 36 and ax * ax + ay * ay + az * az - along * along < radius * radius
end
local function finishJob(run)
    run.job = run.job + 1
    local count = math.min(5, 1 + run.members)
    for i = #run.actors, 1, -1 do
        if run.actors[i].hp <= 0 then
            table.remove(run.actors, i)
        end
    end
    if run.job < 4 then
        local x, z = destination(run)
        for i = 1, count do
            mob(run, run.progress == 16 and 7 or i % 2 + 1, x + (-1) ^ i * 2, z + i, 2)
        end
    end
end
local function jobTool(run)
    if run.job == 1 then
        return ({ [6] = 2, [9] = 3, [16] = 4 })[run.progress]
    end
end
function M.fire(run, p, seq, k, dx, dy, dz, r, ox, oy, oz)
    local length = math.sqrt(dx * dx + dy * dy + dz * dz)
    if
        k % 1 ~= 0
        or seq % 1 ~= 0
        or seq <= p.seq
        or k > toolsAt(run.progress)
        or p.cool > r.time
        or length < 0.1
    then
        return
    end
    dx, dy, dz = dx / length, dy / length, dz / length
    p.seq, p.cool, p.weapon = seq, r.time + M.delays[k], k
    if not inTransit(run) and jobTool(run) == k then
        local tx, tz = destination(run)
        if aimed(p, tx, tz, dx, dy, dz, 1.4, 1.8) then
            finishJob(run)
        end
    end
    local origin = { x = p.x + (ox or 0), z = p.z + (oz or 0), tiny = p.tiny, oy = oy or 0 }
    local x, z = M.cart(run)
    if k == 1 and not p.cracker then
        local rides = aimed(origin, x, z, dx, dy, dz, 1.2, 2.4)
        local range = 7
        for _, a in ipairs(run.actors) do
            if a.hp > 0 and aimed(origin, a.x, a.z, dx, dy, dz, 1.2, 1.4) then
                range = math.min(range, math.sqrt(dist(p.x, p.z, a.x, a.z)))
            end
        end
        p.cracker = {
            x = rides and x or origin.x + dx * range,
            z = rides and z or origin.z + dz * range,
            rides = rides,
        }
        return
    end
    if k == 1 then
        local c = p.cracker
        p.cracker = nil
        if not c.rides then
            x, z = c.x, c.z
        end
        if c.rides and math.abs(x) < 2.2 and (run.progress == 3 or run.progress == 19) then
            advance(run)
        end
    end
    local closest, distance = nil, math.huge
    for _, a in ipairs(run.actors) do
        local d = dist(p.x, p.z, a.x, a.z)
        if
            a.hp > 0
            and d < distance
            and aimed(origin, a.x, a.z, dx, dy, dz, 1.1, a.kind >= 4 and 2 or 1.3)
        then
            closest, distance = a, d
        end
    end
    for _, a in ipairs(run.actors) do
        local hit = a == closest or (k == 3 and closest and dist(a.x, a.z, closest.x, closest.z) < 20)
        if k == 1 then
            hit = dist(a.x, a.z, x, z) < 25
        end
        if hit and a.hp > 0 then
            if k == 2 then
                a.ice = run.clock + 12
            elseif k == 4 then
                a.small = run.clock + 16
            elseif a.kind == 4 and k == 3 and run.progress == 8 then
                a.hp = 0
                advance(run)
            elseif a.kind == 3 and not run.slide and not a.mascot then
                a.hp = a.hp - 1
                if a.hp <= 0 then
                    a.hp, a.x, a.z, a.ice, a.mascot = 4, -5, -55, 0, true
                end
            elseif a.kind <= 2 or a.kind == 7 then
                a.hp = math.max(0, a.hp - (k == 3 and 4 or 1))
            end
        end
    end
end
function M.act(run, p)
    local k = run.progress
    if near(p, -11, -27, 2.8) then
        run.secrets = bit.bor(run.secrets, 1)
        return
    end
    if near(p, 11, -261, 2.8) then
        run.secrets = bit.bor(run.secrets, 2)
        return
    end
    if k >= 13 and p.z > -168 and p.z < -133 then
        p.x, p.z = 0, -169
        return
    end
    if k == 15 and near(p, -9, -197, 3) then
        p.tiny = true
        return
    end
    if k == 4 then
        for _, a in ipairs(run.actors) do
            if a.kind == 3 and not run.slide and a.ice > run.clock and near(p, a.x, a.z, 3.5) then
                local dx, dz = a.x - p.x, a.z - p.z
                local length = math.max(0.01, math.sqrt(dx * dx + dz * dz))
                local bx, bz = 9 - a.x, -66 - a.z
                local goal = math.sqrt(bx * bx + bz * bz)
                if (dx * bx + dz * bz) / (length * goal) > 0.30 then
                    dx, dz, length = bx, bz, goal
                end
                run.slide, run.slideX, run.slideZ = true, dx / length, dz / length
                a.ice = run.clock + 5
            end
        end
        return
    end
    if inTransit(run) then
        if near(p, run.loadX, run.loadZ, 3.5) and run.boost + 8 < run.clock then
            run.boost = run.clock + 7
        end
        return
    end
    if wings[k] and run.job < 4 then
        local tx, tz = destination(run)
        if near(p, tx, tz, 3.2) and not jobTool(run) then
            finishJob(run)
        end
        return
    end
    local s = stops[k]
    if not near(p, s[3], s[4], 3.4) then
        return
    end
    if k == 3 or k == 8 or k == 13 or k == 18 or k == 19 then
        return
    end
    if k == 12 and run.clock - run.launch < 30 then
        return
    end
    if k == 15 and not p.tiny then
        return
    end
    if k == 10 then
        run.launch = run.clock
    end
    if k == 14 then
        p.tiny = true
    end
    if k == 15 then
        p.tiny = false
    end
    p.vital = math.min(5, p.vital + 1)
    if k == 20 then
        return true
    end
    advance(run)
end
function M.hint(run, p)
    if run.done then
        return "RETURN TO SENDER  /  Ornament earned - walk through the north tunnel"
    end
    local s = stops[run.progress]
    if near(p, -11, -27, 3) and run.secrets % 2 == 1 then
        return "OUT OF ORDER - the usher would like a word."
    end
    if near(p, 11, -261, 3) and run.secrets >= 2 then
        return "FAMILY SIZE - popcorn has opened the viewing box."
    end
    local x, z, hint = destination(run)
    local distance = math.sqrt(dist(p.x, p.z, x, z))
    if wings[run.progress] and run.job < 4 then
        hint = wings[run.progress].label .. " " .. (run.job + 1) .. "/4 - " .. hint
    end
    local bearing = math.deg(math.atan2(p.x - x, p.z - z))
    local angle = (bearing - p.yaw + 180) % 360 - 180
    local direction = math.abs(angle) < 30 and "ahead"
        or math.abs(angle) > 140 and "behind"
        or angle > 0 and "left"
        or "right"
    if run.progress == 12 then
        hint = hint .. " " .. math.ceil(math.max(0, 30 - run.clock + run.launch)) .. "s"
    end
    return string.format("%s / %s  [%dm %s]", s[1], hint, distance, direction)
end
function M.atExit(run, p)
    return run.done and p.z < -300 and near(p, 0, -302, 4)
end
function M.canReturn(run, p)
    return p.z > 5.9 or (run.done and near(p, 0, -302, 4))
end

-- Numeric rows travel on the room's existing engine snapshot channel.
function M.snapshot(rows, run, players, day)
    local function emit(format, ...)
        rows[#rows + 1] = string.format("D %d " .. format, day, ...)
    end
    emit(
        "0 %.3f %.3f %d %.3f %d %d %.3f %d %.3f",
        run.clock,
        run.launch,
        run.secrets,
        run.charge,
        run.slide and 1 or 0,
        run.job,
        run.liftoff,
        run.drive,
        run.changed
    )
    if wings[run.progress] then
        emit("3 %d %.2f %.2f %.2f", run.track, run.loadX, run.loadZ, run.boost)
    end
    for _, a in ipairs(run.actors) do
        emit("1 %d %.2f %.2f %d %.2f %.2f %d", a.kind, a.x, a.z, a.hp, a.ice, a.small, a.mascot and 1 or 0)
    end
    for id, p in pairs(players) do
        if p.space == day then
            local c = p.cracker
            emit(
                "2 %d %d %d %d %.2f %.2f %d",
                id,
                p.tiny and 1 or 0,
                p.vital,
                c and 1 or 0,
                c and c.x or 0,
                c and c.z or 0,
                c and c.rides and 1 or 0
            )
        end
    end
end
function M.read(r, w)
    local run = r.instances[w[2]]
    if not run or not stops[run.progress] then
        return false
    end
    if w[3] == 0 and #w == 12 and posts[w[11]] and w[9] % 1 == 0 and w[9] >= 0 and w[9] <= 4 then
        run.clock, run.launch, run.secrets, run.charge, run.slide = w[4], w[5], w[6], w[7], w[8] == 1
        run.job, run.liftoff, run.drive = w[9], w[10], w[11]
        run.changed = w[12]
        run.actors = {}
    elseif w[3] == 3 and #w == 7 and w[4] % 1 == 0 and w[4] >= 0 and w[4] <= #freightRoute + 1 then
        run.track, run.loadX, run.loadZ, run.boost = w[4], w[5], w[6], w[7]
    elseif
        w[3] == 1
        and #w == 10
        and run.actors
        and #run.actors < 32
        and w[4] % 1 == 0
        and w[4] >= 1
        and w[4] <= 7
    then
        run.actors[#run.actors + 1] =
            { kind = w[4], x = w[5], z = w[6], hp = w[7], ice = w[8], small = w[9], mascot = w[10] == 1 }
    elseif w[3] == 2 and #w == 10 and r.players[w[4]] then
        local p = r.players[w[4]]
        p.tiny, p.vital = w[5] == 1, w[6]
        if w[7] == 1 then
            p.cracker = { x = w[8], z = w[9], rides = w[10] == 1 }
        end
    else
        return false
    end
    return true
end

function M.validSnapshot(run, player)
    return run and run.actors and player.vital and (not wings[run.progress] or run.track ~= nil)
end

-- Client-only presentation. The dedicated service loads no artwork.
local art, nodes, actors, crackers, eggs = {}, {}, {}, {}, {}
local gunArt = { "cracker", "freezer", "rocket", "shrinker", "twins" }
local pocket
local labels = {}
local function place(name, model, x, y, z, size)
    local e = eng.scene.spawn(name)
    eng.scene.set_pocket(e, pocket)
    eng.scene.set_mesh(
        e,
        art[model],
        { tex = World.palette, metallic = -4, roughness = 0.82, cast_shadow = false }
    )
    eng.scene.set_pos(e, x, y, z)
    eng.scene.set_scale(e, size, size, size)
    return e
end
function M.build(space, pedestal)
    pocket = space
    eng.scene.set_pos(pedestal, 0, -50, 0)
    for _, name in ipairs({
        "cinema",
        "diner",
        "silos",
        "cabin",
        "luna",
        "bowl",
        "usher",
        "courier",
        "skater",
        "loader",
        "guard",
        "queen",
        "hatchling",
        "cart",
        "rocket",
        "plywood",
        "earth",
        "score",
        "out",
        "corn",
        "poster",
        "cracker",
        "freezer",
        "shrinker",
        "twins",
    }) do
        art[name] = eng.asset.load_mesh("missions/day_01/" .. name .. ".glb")
        assert(art[name] and art[name] ~= 0, "Missing Day 1 art: " .. name)
    end
    local poster = place("Now showing", "poster", 0, 0, 0, 1)
    eng.scene.set_mesh(
        poster,
        art.poster,
        { tex = eng.asset.load_texture("missions/day_01/matinee.png", true), metallic = -4, roughness = 0.8 }
    )
    for _, name in ipairs({
        "use",
        "freeze",
        "click",
        "shrink",
        "clear",
        "escort",
        "launch",
        "home",
        "rocket",
    }) do
        labels[name] = eng.asset.load_texture("missions/day_01/cue-" .. name .. ".png", true)
    end
    for i = 0, 3 do
        eggs[i] = eng.asset.load_texture("missions/day_01/egg-" .. i .. ".png", true)
    end
    for _, name in ipairs({ "cinema", "diner", "silos", "cabin", "luna", "bowl" }) do
        place(name, name, 0, 0, 0, 1)
    end
    for _, name in ipairs({ "cart", "rocket", "plywood", "earth", "score", "out", "corn" }) do
        nodes[name] = place(name, name, 0, -80, 0, 1)
    end
    nodes.load = place("Tracked consignment", "cart", 0, -80, 0, 1)
    art.ornament = eng.asset.load_mesh("assets/brass-rocket.glb")
    nodes.prize = place("Brass ornament", "ornament", 0, -80, 0, 0.68)
    nodes.boxDoor = eng.scene.spawn("Concession shutter")
    eng.scene.set_pocket(nodes.boxDoor, pocket)
    eng.scene.set_mesh(nodes.boxDoor, World.box, { color = { 0.42, 0.19, 0.12, 1 } })
    eng.scene.set_scale(nodes.boxDoor, 0.32, 4, 6.4)
    nodes.beacon = place("Dispatch beacon", "rocket", 0, -80, 0, 0.22)
    nodes.latch = place("Gold stage latch", "plywood", 0, -80, 0, 0.28)
    nodes.parcel = place("Live cargo", "cart", 0, -80, 0, 0.8)
    nodes.gate = eng.scene.spawn("Freight shutter")
    eng.scene.set_pocket(nodes.gate, pocket)
    eng.scene.set_mesh(nodes.gate, World.box, { color = { 0.40, 0.15, 0.10, 1 }, emissive = 0.07 })
    eng.scene.set_scale(nodes.gate, 6, 3.7, 0.25)
    for i = 1, 8 do
        crackers[i] = place("Remote snow cracker", "cart", 0, -80, 0, 0.21)
    end
end
local actorModels = { "usher", "courier", "skater", "loader", "guard", "queen", "hatchling" }
function M.presentShot(g, aim)
    local sounds = { "d1-remote", "d1-freeze", "rocketthrow", "d1-shrink", "d1-twins" }
    Feedback.sound(g, sounds[g.weapon], 0.72, g.weapon == 5 and (0.93 + 0.13 * (g.seq % 2)) or 1, 3)
    g.feedback.kickStart, g.recoil = g.clock, Feedback.kick[g.weapon]
    g.dayShot = { at = g.clock, dx = aim.dx, dy = aim.dy, dz = aim.dz, ox = aim.ox, oy = aim.oy, oz = aim.oz }
end
function M.render(g, dt)
    local run = g.room.instances[1]
    local p = g.room.players[g.id]
    local phase, t = run.progress, run.clock
    local set = eng.scene.set_pos
    local spin = eng.scene.set_rot_deg
    local size = eng.scene.set_scale
    local s = stops[phase]
    local cx, cz = M.cart(run)
    local motion = g.feedback.prefs[1] / 100
    set(nodes.load, run.loadX or 0, wings[phase] and 0 or -80, run.loadZ or 0)
    set(nodes.cart, cx, 0, cz)
    local post = posts[run.drive]
    if phase == 18 then
        set(nodes.latch, post[1], 2.5 + 0.15 * math.sin(t * 6) * motion, post[2])
    else
        set(nodes.latch, 0, 2.6, cz)
    end
    local drop = (phase == 4 or phase == 20) and math.min(5.1, 14 * (t - run.changed) ^ 2) or 5.1
    set(nodes.plywood, 0, (phase == 3 or phase == 19) and 3.6 or 3.6 - drop, cz - 0.8)
    set(nodes.rocket, -8, phase >= 9 and math.min(65, math.max(0, (t - (run.liftoff or 0)) * 4)) or 0, -123)
    size(nodes.rocket, 2.1, 2.1, 2.1)
    local orbit = Hall.clamp((t - run.launch) / 30, 0, 1)
    local cabin = M.area(p.z) == 4
    set(nodes.earth, cabin and 0 or 8, cabin and 1.4 or 14, cabin and -165.2 or -243)
    local earthSize = cabin and 2.1 - orbit * 1.65 or 3
    size(nodes.earth, earthSize, earthSize, earthSize)
    set(nodes.score, 0, run.done and 4.1 or -80, -301)
    set(nodes.out, -11, run.secrets % 2 == 1 and 1.8 or -80, -27)
    set(nodes.corn, 11, run.secrets >= 2 and 0.1 or -80, -261)
    size(nodes.corn, 2, 2, 2)
    set(nodes.boxDoor, 14, run.secrets >= 2 and 6.3 or 2, -261)
    set(
        nodes.parcel,
        phase <= 2 and 2 * math.sin(t) or -8,
        phase <= 2 and 2.4 or 0.2,
        phase <= 2 and -35 or -234
    )
    set(nodes.prize, phase == 20 and 0 or -8, phase >= 16 and 1.1 or -80, phase == 20 and -296 or -234)
    spin(nodes.prize, 0, t * 42, 0)
    local tx, tz = destination(run)
    set(nodes.beacon, tx, 1.85 + 0.17 * motion * math.sin(t * 3), tz)
    spin(nodes.beacon, 180, t * 55, 0)
    local area = M.area(s[4])
    set(nodes.gate, 0, run.done and -80 or 1.85, boundaries[area])
    if g.scenePhase ~= phase then
        local cue = ({ [1] = "d1-marquee", [11] = "rocketthrow", [13] = "d1-earthrise", [20] = "d1-score" })[phase]
            or "bell"
        Feedback.sound(g, cue, 0.62, phase == 11 and 0.65 or 1, 3)
        g.scenePhase = phase
    end
    for i, a in ipairs(run.actors) do
        local slot = actors[i]
        if not slot then
            slot = { node = place("Lunar dispatch crew", actorModels[a.kind], a.x, 0, a.z, 1) }
            actors[i] = slot
        end
        local frozen = a.ice > t
        if slot.kind ~= a.kind or slot.frozen ~= frozen or slot.mascot ~= a.mascot then
            eng.scene.set_mesh(slot.node, art[actorModels[a.kind]], {
                tex = World.palette,
                metallic = -4,
                color = a.mascot and { 0.55, 1, 0.75, 1 } or { 1, 1, 1, 1 },
                emissive = frozen and { 0.18, 0.48, 0.72 } or 0.04,
            })
            slot.kind, slot.frozen, slot.mascot = a.kind, frozen, a.mascot
        end
        local stride = frozen and 0 or math.sin(t * (a.kind == 7 and 9 or 4) + i) * motion
        local y = a.kind == 2 and 1 + 0.2 * stride or 0.08 * math.abs(stride)
        set(slot.node, a.x, a.hp > 0 and a.kind ~= 7 and y or -80, a.z)
        local windup = a.kind == 6 and phase == 18 and run.charge - t > 3.8
        spin(slot.node, windup and -18 or 0, math.deg(math.atan2(g.x - a.x, g.z - a.z)), stride * 5)
        local factor = a.small > t and 0.27 or 1
        size(slot.node, factor, factor, factor)
    end
    for i = #run.actors + 1, #actors do
        set(actors[i].node, 0, -80, 0)
    end
    for id, e in ipairs(crackers) do
        local friend = g.room.players[id]
        local c = friend and friend.cracker
        set(
            e,
            c and (c.rides and cx or c.x) or 0,
            c and (c.rides and 1.45 or 0.18) or -80,
            c and (c.rides and cz or c.z) or 0
        )
    end
    -- The roof, freight lift and midfield lift use the same camera path as walking.
    local rise = Hall.clamp((p.z + 9) * 0.2955, 0, 3.25)
    local eye = (p.tiny and phase == 15) and 0.56 or 1.55 + rise
    if World.selected ~= 100 + g.weapon then
        local gunMesh = g.weapon == 3 and eng.asset.load_mesh("assets/rocket.glb") or art[gunArt[g.weapon]]
        eng.scene.set_mesh(World.gun, gunMesh, { tex = World.palette, roughness = 0.65, emissive = 0.05 })
        eng.scene.set_scale(World.gun, 0.40, 0.40, 0.40)
        World.selected = 100 + g.weapon
    end
    local gx, gy, gz = eng.scene.get_pos(World.gun)
    set(World.gun, gx, gy + eye - 1.55, gz)
    return eye
end
function M.sprites(g)
    local run = g.room.instances[1]
    local tx, tz = destination(run)
    local cue = run.done and "home"
        or inTransit(run) and "escort"
        or ({
            [3] = "click",
            [4] = "freeze",
            [8] = "rocket",
            [10] = "launch",
            [13] = "shrink",
            [18] = "clear",
            [19] = "click",
        })[run.progress]
        or "use"
    if not inTransit(run) and jobTool(run) then
        cue = ({ [2] = "freeze", [3] = "rocket", [4] = "shrink" })[jobTool(run)]
    end
    eng.render.draw_sprite(tx, 3.1, tz, 2.25, 0.60, labels[cue])
    for i, a in ipairs(run.actors) do
        if a.kind == 7 and a.hp > 0 then
            local frame = math.floor(run.clock * 6 + i) % 4
            eng.render.draw_sprite(a.x, 0.65, a.z, 1.3, 1.3, eggs[frame])
        end
    end
    local shot = g.dayShot
    if shot and g.clock - shot.at < 0.18 then
        local offset = g.weapon == 5 and ((g.seq % 2) * 0.44 - 0.22) or 0
        local color = ({
            { 1, 0.77, 0.3 },
            { 0.42, 0.85, 1 },
            { 1, 0.45, 0.12 },
            { 0.25, 1, 0.57 },
            {
                1,
                0.25,
                0.39,
            },
        })[g.weapon]
        for i = 1, 4 do
            local d = (g.clock - shot.at) * 35 + i * 0.35
            eng.render.draw_sprite(
                g.x + shot.ox + shot.dx * d - shot.dz * offset,
                1.48 + shot.oy + shot.dy * d,
                g.z + shot.oz + shot.dz * d + shot.dx * offset,
                0.17,
                0.17,
                World.snow,
                color[1],
                color[2],
                color[3]
            )
        end
    end
end
