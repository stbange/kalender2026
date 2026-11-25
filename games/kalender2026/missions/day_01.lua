-- Last Launch from Tinseltown. Coordinates are metres, with Luna to the north.
local M = {
    title = "Last Launch from Tinseltown",
    ornament = "brass-rocket",
    tools = { "Snow Pistol", "Freezer", "Snow Rocket", "Shrink Ray", "Twin Tinsel Launchers" },
    delays = { 0.20, 0.28, 0.72, 0.32, 0.12 },
}
MissionPacks[1] = M
-- The brass beacon marks the current destination and doubles as a landmark in VR.
local stops = {
    { "Rooftop", "Walk to the striped air vent. Use to drop inside.", -8, -9 },
    { "Midnight cinema", "Use the projector. Where is the courier taking that sack?", 9, -21 },
    { "Moon Bowl matinee", "Shoot the striped latch to drop the plywood Moon.", 0, -34 },
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
    { "Sideline cart", "Shoot the red target on the sideline cart to crate the Queen!", 0, -288 },
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
    p.x, p.z, p.tiny, p.vital = 0, checkpoint(run), false, 5
    p.lastHurt = nil
    p.immunity = run.clock + 6
end
function M.exit(_, p)
    p.tiny, p.vital = nil, nil
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
    run.nextActor = (run.nextActor or 0) + 1
    run.actors[#run.actors + 1] = {
        id = run.nextActor,
        yaw = 0,
        stride = 0,
        kind = kind,
        x = x,
        z = z,
        hp = hp,
        ice = 0,
        small = 0,
        dx = 0,
        dz = 0,
    }
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
local function roofHeight(z)
    return Hall.clamp((z + 9) * 0.2955, 0, 3.25)
end
local function eyeHeight(p)
    return p.tiny and 0.56 or 1.55 + roofHeight(p.z)
end
function M.start(run)
    run.progress, run.clock, run.launch, run.charge, run.actors = 1, 0, 0, 0, {}
    run.secrets, run.job, run.liftoff, run.drive, run.changed = 0, 0, 0, 1, 0
    run.track, run.loadX, run.loadZ, run.boost, run.raid = 0, 0, 0, 0, 0
    mob(run, 1, -3, 0, 2)
    mob(run, 1, 3, -4, 2)
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
                local oldX, oldZ = a.x, a.z
                if a.ice <= run.clock then
                    a.yaw = math.deg(math.atan2(dx, dz))
                end
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
                    elseif run.progress == 19 then
                        -- The stunned Queen staggers into the shipping crate behind its painted target.
                        local cx, cz = -a.x, -290 - a.z
                        local reach = math.sqrt(cx * cx + cz * cz)
                        local step = math.min(1, dt * 3 / math.max(0.01, reach))
                        a.x, a.z = a.x + cx * step, a.z + cz * step
                    end
                elseif
                    a.small > run.clock
                    and best < 1.8 ^ 2
                    and (a.kind == 5 or a.kind <= 2 or a.kind == 7)
                then
                    a.hp = 0
                    a.impact =
                        { at = run.clock, owner = player.id, seq = player.seq, dx = 0, dz = 0, result = 2 }
                    if a.kind == 5 and run.progress == 13 then
                        advance(run)
                    end
                elseif a.kind ~= 4 and a.ice <= run.clock and best < 18 ^ 2 and best > 1.2 then
                    local speed = a.kind == 7 and 2.3 or 1.1
                    a.x, a.z = a.x + dx / len * dt * speed, a.z + dz / len * dt * speed
                end
                a.stride = (a.stride + math.sqrt(dist(oldX, oldZ, a.x, a.z))) % 256
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
    local ax, ay, az = x - p.x, y - (p.eye or eyeHeight(p)) - (p.oy or 0), z - p.z
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
    local origin = { x = p.x + (ox or 0), z = p.z + (oz or 0), eye = eyeHeight(p), oy = oy or 0 }
    if not inTransit(run) and jobTool(run) == k then
        local tx, tz = destination(run)
        if aimed(origin, tx, tz, dx, dy, dz, 1.4, 1.8) then
            finishJob(run)
        end
    end
    local closest, distance = nil, math.huge
    for _, a in ipairs(run.actors) do
        local d = dist(origin.x, origin.z, a.x, a.z)
        local height = a.kind == 2 and 2.0 or a.kind == 7 and 0.72 or 1.18
        local radius = a.kind == 7 and 0.95 or a.kind >= 4 and 1.8 or 1.05
        if a.small > run.clock then
            height, radius = 0.45, 0.65
        end
        if
            a.hp > 0
            and d < distance
            and aimed(origin, a.x, a.z, dx, dy, dz, height + roofHeight(a.z), radius)
        then
            closest, distance = a, d
        end
    end
    if run.progress == 3 or run.progress == 19 then
        local x, z = M.cart(run)
        if run.progress == 3 then
            x = 0
        end
        if dist(origin.x, origin.z, x, z) < distance and aimed(origin, x, z, dx, dy, dz, 1.65, 1.1) then
            if run.progress == 19 then
                for _, boss in ipairs(run.actors) do
                    if boss.kind == 6 then
                        boss.hp = 0
                        boss.impact =
                            { at = run.clock, owner = p.id, seq = seq, dx = dx, dz = dz, result = 2 }
                    end
                end
            end
            advance(run)
            return
        end
    end
    for _, a in ipairs(run.actors) do
        local hit = a == closest or (k == 3 and closest and dist(a.x, a.z, closest.x, closest.z) < 20)
        if hit and a.hp > 0 then
            local hp = a.hp
            local frozen = a.ice > run.clock
            local result = 1 -- hit, defeat, armor, freeze, shrink

            local grunt = a.kind <= 2 or a.kind == 7
            if a.kind == 6 or (a.kind == 4 and k ~= 3) or (a.kind == 5 and k ~= 4) then
                result = 3
            elseif grunt and frozen then
                a.hp = 0
            elseif k == 2 then
                result, a.ice = 4, run.clock + 12
            elseif k == 4 then
                result, a.small = 5, run.clock + 16
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
            else
                result = 3
            end
            if a.hp == 0 or (a.kind == 3 and hp == 1 and a.mascot) then
                result = 2
            end
            a.impact = { at = run.clock, owner = p.id, seq = seq, dx = dx, dz = dz, result = result }
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
        local h = a.impact
        emit(
            "1 %d %.2f %.2f %d %.2f %.2f %d %d %.1f %.2f %.3f %d %d %.2f %.2f %d",
            a.kind,
            a.x,
            a.z,
            a.hp,
            a.ice,
            a.small,
            a.mascot and 1 or 0,
            a.id,
            a.yaw,
            a.stride,
            h and h.at or 0,
            h and h.owner or 0,
            h and h.seq or 0,
            h and h.dx or 0,
            h and h.dz or 0,
            h and h.result or 0
        )
    end
    for id, p in pairs(players) do
        if p.space == day then
            emit("2 %d %d %d %d", id, p.tiny and 1 or 0, p.vital, p.seq)
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
        and #w == 19
        and run.actors
        and #run.actors < 32
        and w[4] % 1 == 0
        and w[4] >= 1
        and w[4] <= 7
    then
        local a = {
            kind = w[4],
            x = w[5],
            z = w[6],
            hp = w[7],
            ice = w[8],
            small = w[9],
            mascot = w[10] == 1,
            id = w[11],
            yaw = w[12],
            stride = w[13],
        }
        if w[19] > 0 and w[19] <= 5 then
            a.impact = { at = w[14], owner = w[15], seq = w[16], dx = w[17], dz = w[18], result = w[19] }
        end
        run.actors[#run.actors + 1] = a
    elseif w[3] == 2 and #w == 7 and r.players[w[4]] then
        local p = r.players[w[4]]
        p.tiny, p.vital, p.seq = w[5] == 1, w[6], w[7]
    else
        return false
    end
    return true
end

function M.validSnapshot(run, player)
    return run and run.actors and player.vital and (not wings[run.progress] or run.track ~= nil)
end

-- Client-only presentation. The dedicated service loads no artwork.
local art, nodes, actors, eggs = {}, {}, {}, {}
local gunArt = { "pistol", "freezer", "rocket", "shrinker", "twins" }
local pocket, crewTexture
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
    crewTexture = eng.asset.load_texture("missions/day_01/crew-hide.png", true)
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
        "cart",
        "rocket",
        "plywood",
        "earth",
        "score",
        "out",
        "corn",
        "poster",
        "bullseye",
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
        "aim",
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
    nodes.latch = place("Striped stage target", "bullseye", 0, -80, 0, 1)
    nodes.parcel = place("Live cargo", "cart", 0, -80, 0, 0.8)
    nodes.gate = eng.scene.spawn("Freight shutter")
    eng.scene.set_pocket(nodes.gate, pocket)
    eng.scene.set_mesh(nodes.gate, World.box, { color = { 0.40, 0.15, 0.10, 1 }, emissive = 0.07 })
    eng.scene.set_scale(nodes.gate, 6, 3.7, 0.25)
    art.pistol = eng.asset.load_mesh("assets/pistol.glb")
end
local actorModels = { "usher", "courier", "skater", "loader", "guard", "queen" }
-- The hip and shoulder pivots match the loose limb meshes made by make_day_one.py.
local modelScale = { 1, 0.85, 1, 1.65, 1.3, 2.15, 0.53 }
local strideRate = { 3.8, 4, 2.2, 2.8, 3.2, 1.8, 5.5 }
local impactNames = { "Hit", "Cleared", "Armored", "Frozen", "Shrunk" }
local impactSounds = { "thup1", "poof", "tok", "d1-freeze", "d1-shrink" }
local function contact(g, a, h)
    local owned = h.owner == g.id
    local y = roofHeight(a.z) + (a.kind == 2 and 2.1 or a.kind == 7 and 0.65 or 1.2)
    if owned and h.result ~= 3 then
        Feedback.mark(g, { seq = h.seq, x = a.x, y = y, z = a.z }, h.result == 2)
    end
    if owned and h.result ~= 1 then
        Feedback.caption(
            g,
            impactNames[h.result],
            a.x,
            y + 0.5,
            a.z,
            h.result == 2 and "finish" or "ticks",
            0.4
        )
    end
    Feedback.sound(
        g,
        impactSounds[h.result],
        h.result == 2 and 0.58 or 0.42,
        0.95 + 0.045 * (h.seq % 3),
        owned and 3 or 1,
        a.x,
        y,
        a.z,
        34
    )
    local kind = (h.result == 3 or (h.result == 2 and a.ice > h.at)) and "gear"
        or h.result == 5 and "mote"
        or "powder"
    local count = h.result == 2 and 8 or 4
    for i = 1, count do
        local theta = i * 2.4 + h.seq
        Feedback.particle(
            g,
            kind,
            a.x,
            y,
            a.z,
            math.cos(theta) * 2 - h.dx,
            0.4 + i % 3,
            math.sin(theta) * 2 - h.dz,
            0.10 + i % 3 * 0.035,
            0.22 + i % 3 * 0.055
        )
    end
end

local function animateActor(g, run, a, i, t, motion)
    local slot = actors[i]
    if not slot then
        slot = { node = eng.scene.spawn("Dispatch crew"), limbs = {} }
        eng.scene.set_pocket(slot.node, pocket)
        actors[i] = slot
    end
    local h = a.impact
    local age = h and math.max(0, t - h.at) or 100
    local hit = math.max(0, 1 - age / 0.24)
    local frozen = a.ice > t
    local flash = hit > 0.55 and motion > 0 and g.feedback.prefs[2] > 25
    local model = actorModels[a.kind] or "hatchling"
    local style = model .. tostring(frozen) .. tostring(flash) .. tostring(a.mascot)
    local scale = modelScale[a.kind]
    if slot.style ~= style then
        local material = {
            tex = crewTexture,
            metallic = -4,
            roughness = 0.82,
            emissive = frozen and { 0.12, 0.35, 0.53 } or flash and { 0.34, 0.23, 0.10 } or 0.002,
            color = a.mascot and { 0.55, 1, 0.75, 1 } or { 1, 1, 1, 1 },
        }
        if a.kind ~= 7 then
            eng.scene.set_mesh(slot.node, art[model], material)
            for j = 1, 4 do
                local leg = j <= 2
                local part = model .. (leg and "-leg" or "-arm")
                if j == 4 and (a.kind == 1 or a.kind == 2) then
                    part = model .. "-armed"
                end
                art[part] = art[part] or eng.asset.load_mesh("missions/day_01/" .. part .. ".glb")
                if not slot.limbs[j] then
                    slot.limbs[j] = place(part, part, 0, 0, 0, 1)
                    eng.scene.set_parent(slot.limbs[j], slot.node)
                end
                local side = j % 2 == 1 and -1 or 1
                eng.scene.set_mesh(slot.limbs[j], art[part], material)
                eng.scene.set_pos(
                    slot.limbs[j],
                    side * (leg and 0.26 or 0.55) * scale,
                    (leg and 0.58 or 1.26) * scale,
                    0
                )
                eng.scene.set_scale(slot.limbs[j], scale, scale, scale)
            end
        end
        slot.style = style
    end
    if
        h
        and age < 0.40
        and h.at >= g.feedback.dayJoined
        and (slot.id ~= a.id or slot.seq ~= h.seq or slot.owner ~= h.owner or slot.at ~= h.at)
    then
        contact(g, a, h)
        slot.id, slot.seq, slot.owner, slot.at = a.id, h.seq, h.owner, h.at
    end
    local stride = (a.stride or 0) * strideRate[a.kind]
    local gait = frozen and 0 or math.sin(stride) * motion
    local hover = frozen and 0 or math.sin(t * 4 + i) * motion
    local y = roofHeight(a.z) + (a.kind == 2 and 0.85 + hover * 0.16 or 0.09 * math.abs(gait))
    local fallen = a.hp <= 0 and math.min(1, age / 0.32) or 0
    local recoil = hit * hit * motion
    local dx, dz = h and h.dx or 0, h and h.dz or 0
    local visible = a.kind ~= 7 and (a.hp > 0 or fallen < 1)
    eng.scene.set_pos(
        slot.node,
        a.x + dx * 0.32 * recoil,
        visible and y - fallen * 0.22 or -80,
        a.z + dz * 0.32 * recoil
    )
    local windup = a.kind == 6 and run.progress == 18 and run.charge - t > 3.8
    local facing = math.rad(a.yaw or 0)
    local forward = dx * math.sin(facing) + dz * math.cos(facing)
    local side = dx * math.cos(facing) - dz * math.sin(facing)
    eng.scene.set_rot_deg(
        slot.node,
        (windup and -18 or 0) * motion + 19 * forward * recoil + fallen * 65 * motion,
        a.yaw or 0,
        (a.kind == 3 and 11 or 4) * gait - side * 19 * recoil
    )
    local size = (a.small > t and 0.27 or 1) * (1 - fallen * 0.65)
    eng.scene.set_scale(slot.node, size, size * (1 - 0.09 * recoil), size)
    if a.kind ~= 7 then
        for j, node in ipairs(slot.limbs) do
            local leg = j <= 2
            local swing = (j % 2 == 1 and 1 or -1) * gait
            local angle = leg and swing * 32 or -swing * 28 - 32 * recoil
            local roll = 0
            if a.kind == 2 then
                angle = leg and 18 + hover * 7 or -25 - hover * 13
            elseif a.kind == 3 or a.kind == 6 then
                roll = swing * (leg and 18 or -24)
            elseif a.kind == 4 then
                angle = leg and 0 or -12 - 32 * recoil + hover * 4
            end
            if frozen then
                angle, roll = 0, 0
            end
            eng.scene.set_rot_deg(node, angle, 0, roll)
        end
    end
end

function M.presentShot(g, aim)
    local sounds = { "snap" .. (1 + g.seq % 3), "d1-freeze", "rocketthrow", "d1-shrink", "d1-twins" }
    Feedback.sound(g, sounds[g.weapon], 0.72, g.weapon == 5 and (0.93 + 0.13 * (g.seq % 2)) or 1, 3)
    if g.xr and Feedback.on("FIRE-09") and g.feedback.prefs[4] > 0 then
        g.feedback.pulse = Feedback.pulseMs[g.weapon] * 1000
            + math.floor(g.feedback.prefs[4] * Feedback.pulseGain[g.weapon])
    end
    g.feedback.kickStart, g.recoil = g.clock, Feedback.kick[g.weapon] * g.feedback.prefs[1] / 100
    local eye = eyeHeight(g.room.players[g.id])
    local side = g.xr and 0 or 0.12
    local x = g.x + aim.ox - aim.dz * side
    local y = eye + aim.oy - (g.xr and 0 or 0.09)
    local z = g.z + aim.oz + aim.dx * side
    g.dayShot = {
        at = g.clock,
        dx = aim.dx,
        dy = aim.dy,
        dz = aim.dz,
        x = x,
        y = y,
        z = z,
        tool = g.weapon,
        seq = g.seq,
    }
    if g.feedback.prefs[1] > 0 then
        Feedback.particle(
            g,
            "powder",
            x + aim.dx * 0.72,
            y + aim.dy * 0.72,
            z + aim.dz * 0.72,
            aim.dx,
            0.3 + aim.dy,
            aim.dz,
            0.075,
            0.08
        )
    end
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
        set(nodes.latch, phase == 19 and cx or 0, (phase == 19 or phase == 3) and 1.65 or -80, cz + 0.28)
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
    if g.sampleClock ~= t then
        g.sampleClock, g.sampleAt = t, g.clock
    end
    local animTime = t + Hall.clamp(g.clock - g.sampleAt, 0, 0.15)
    g.feedback.dayJoined = g.feedback.dayJoined or t
    for i, a in ipairs(run.actors) do
        animateActor(g, run, a, i, animTime, motion)
    end
    for i = #run.actors + 1, #actors do
        set(actors[i].node, 0, -80, 0)
    end
    -- The roof, freight lift and midfield lift use the same camera path as walking.
    local eye = eyeHeight(p)
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
            [3] = "aim",
            [4] = "freeze",
            [8] = "rocket",
            [10] = "launch",
            [13] = "shrink",
            [18] = "clear",
            [19] = "aim",
        })[run.progress]
        or "use"
    if not inTransit(run) and jobTool(run) then
        cue = ({ [2] = "freeze", [3] = "rocket", [4] = "shrink" })[jobTool(run)]
    end
    eng.render.draw_sprite(tx, 3.1, tz, 2.25, 0.60, labels[cue])
    for i, a in ipairs(run.actors) do
        if a.kind == 7 and a.hp > 0 then
            local motion = g.feedback.prefs[1] / 100
            local step = (a.ice > run.clock or motion == 0) and 0 or (a.stride or 0) * 6
            local frame = math.floor(step) % 4
            local bump = a.impact and Hall.clamp(1 - (run.clock - a.impact.at) / 0.24, 0, 1) * motion or 0
            local size = a.small > run.clock and 0.55 or 1.3
            eng.render.draw_sprite(
                a.x + (a.impact and a.impact.dx or 0) * bump * 0.25,
                0.5 + 0.20 * math.abs(math.sin(step)) * motion,
                a.z + (a.impact and a.impact.dz or 0) * bump * 0.25,
                size * (1 + bump * 0.2),
                size * (1 - bump * 0.2),
                eggs[frame]
            )
        end
    end
    local shot = g.dayShot
    if shot and g.clock - shot.at < 0.13 and g.feedback.prefs[2] > 0 then
        local offset = shot.tool == 5 and ((shot.seq % 2) * 0.44 - 0.22) or 0
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
        })[shot.tool]
        for i = 1, 4 do
            local d = 0.50 + (g.clock - shot.at) * 70 + i * 0.23
            eng.render.draw_sprite(
                shot.x + shot.dx * d - shot.dz * offset,
                shot.y + shot.dy * d,
                shot.z + shot.dz * d + shot.dx * offset,
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
