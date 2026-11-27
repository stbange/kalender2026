-- Last Launch from Tinseltown. Coordinates are metres, with Luna to the north.
local M = {
    speed = 8.25,
    title = "Last Launch from Tinseltown",
    ornament = "brass-rocket",
    tools = { "Snow Pistol", "Freezer", "Snow Rocket", "Shrink Ray", "Twin Tinsel Launchers" },
    delays = { 0.20, 0.28, 0.72, 0.32, 0.12 },
}
MissionPacks[1] = M
-- The brass beacon marks the current destination and doubles as a landmark in VR.
local stops = {
    { "Rooftop", "Use the striped vent to enter the cinema.", -8, -9 },
    { "Midnight cinema", "Use the projector. Where is the courier taking that sack?", 9, -21 },
    { "Moon Bowl matinee", "Shoot the striped latch to drop the plywood Moon.", 0, -34 },
    { "Dead-letter diner", "Freeze the boar (2). Tap Use beside it to ring the till.", -5, -55 },
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
    { "Moon Bowl", "Clear the hatchlings. Lead the Queen to the lit goalpost.", 0, -278 },
    { "Sideline cart", "Shoot the red target on the sideline cart to crate the Queen!", 0, -288 },
    { "Return to sender", "Collect the brass rocket at midfield.", 0, -296 },
}
M.stops = stops
-- Two or three short volleys guard one plainly marked exit in each shootout.
local shootouts = { [2] = 3, [6] = 3, [9] = 3, [16] = 4 }
-- Open-front sets widen the main aisle. Both lanes rejoin before the exit.
local bays = {
    [2] = { side = 1, z = -23, width = 29 },
    [6] = { side = -1, z = -80, width = 33 },
    [9] = { side = -1, z = -124, width = 35 },
    [16] = { side = 1, z = -233, width = 31 },
}
-- Waist-high supplies and access cards are walk-over pickups. Supplies are
-- personal; a key opens its reader for everyone in the instance.
local supplies = {
    { "medkit", -6, -16 },
    { "vest", 18, -21 },
    { "medkit", 7, -62 },
    { "vest", -18, -83 },
    { "medkit", 5, -111 },
    { "medkit", -2, -153 },
    { "vest", 7, -193 },
    { "medkit", 16, -230 },
    { "medkit", -9, -267 },
    { "vest", 9, -273 },
}
local passes = { [6] = { -18, -76 }, [9] = { -21, -120 } }
local crates = { { 18, -27 }, { -22, -86 }, { -21, -128 }, { 20, -237 } }
local function boxCross(x, z, tx, tz, cx, cz, rx, rz)
    local first, last = 0, 1
    local function slab(pos, delta, lo, hi)
        if math.abs(delta) < 0.00001 then
            return pos >= lo and pos <= hi
        end
        local a, b = (lo - pos) / delta, (hi - pos) / delta
        first = math.max(first, math.min(a, b))
        last = math.min(last, math.max(a, b))
        return first <= last
    end
    local hit = slab(x, tx - x, cx - rx, cx + rx) and slab(z, tz - z, cz - rz, cz + rz)
    return hit, first, last
end
local function crateBlocks(x, z, tx, tz, pad)
    for _, c in ipairs(crates) do
        if boxCross(x, z, tx, tz, c[1], c[2], 1.2 + pad, 1.2 + pad) then
            return true
        end
    end
    return false
end
local function held(mask, i)
    return math.floor(mask / 2 ^ (i - 1)) % 2 == 1
end
local function remaining(run, observer)
    local count, target, nearest = 0, nil, math.huge
    for _, actor in ipairs(run.actors) do
        if actor.hp > 0 then
            count = count + 1
            local distance = observer and ((actor.x - observer.x) ^ 2 + (actor.z - observer.z) ^ 2) or 0
            if distance < nearest then
                target, nearest = actor, distance
            end
        end
    end
    return count, target
end
-- Fizzy concessions can be popped once per encounter for a crowd clear.
local soda = { [2] = { -4, -22, 4 }, [6] = { 3, -80, 8 } }
local posts = { { 0, -278 }, { -8, -266 }, { 8, -289 } }
local Tour
local function destination(run, observer)
    if run.seed then
        return Tour.destination(run, observer)
    end
    if run.progress == 19 then
        local x, z = M.cart(run)
        return x, z, stops[19][2]
    end
    if run.progress == 18 then
        local post = posts[run.drive]
        return post[1], post[2], "Clear the hatchlings, then shoot the Queen. The lit post also stuns her."
    end
    local pass = passes[run.progress]
    if pass and not run.key and remaining(run) > 0 then
        return pass[1], pass[2], "Grab the access card or clear the patrol."
    end
    local waves = shootouts[run.progress]
    if waves and not run.key then
        local count, target = remaining(run, observer)
        if count > 0 then
            return target.x,
                target.z,
                string.format("Clear the room  %d/%d  ·  %d left", run.wave, waves, count)
        elseif run.wave < waves then
            local stop = stops[run.progress]
            return stop[3], stop[4], "Incoming reinforcements"
        end
    end
    local s = stops[run.progress]
    return s[3], s[4], s[2]
end
M.destination = destination
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
    p.armor, p.claimed, p.kickAt = 0, p.claimed or 0, -1
    p.lastHurt = nil
    p.immunity = run.clock + (p.immunity and 2 or 0.8)
    if run.seed then
        Tour.arrive(run, p)
    end
end
function M.exit(_, p)
    p.tiny, p.vital, p.armor, p.claimed, p.kickAt = nil, nil, nil, nil, nil
    p.immunity, p.lastHurt, p.respawned = nil, nil, nil
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
function M.stageCount(run)
    return run.seed and 9 or #stops
end
function M.unlocked(run)
    return run.seed and (2 + math.ceil(run.progress / 3)) or toolsAt(run.progress)
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
-- All clients reconstruct the same city from the seed chosen at departure.
Tour = {
    names = { "Los Angeles", "Luna", "Bettinghausen" },
    places = {
        { "Sunset Boulevard", "Midnight Pictures", "Launch lot" },
        { "Tranquility Base", "Relay yard", "Earthrise terminal" },
        { "Oberdorf", "Ahse bridge", "Unterdorf" },
    },
}
local function section(run)
    return (run.progress - 1) % 3 + 1
end
local function leg(run)
    return math.floor((run.progress - 1) / 3) + 1
end
-- Carve a connected graph on five columns. Adjacent occupied squares may
-- have a wall between them: links are the passages players actually traverse.
local directions = { { 0, 1 }, { 1, 0 }, { 0, -1 }, { -1, 0 } }
local function layout(run)
    local city = leg(run)
    if run.layout and run.layout.city == city and run.layout.seed == run.seed then
        return run.layout
    end
    -- Snapshots replace the client run table. Reuse immutable geometry there.
    if Tour.cached and Tour.cached.city == city and Tour.cached.seed == run.seed then
        run.layout = Tour.cached
        return run.layout
    end
    local state = 1 + (run.seed + city * 17389) % 2147483646
    local function roll(n)
        state = state * 48271 % 2147483647
        return state % n
    end
    local size = ({ 10, 11, 9 })[city]
    local x, front = city * 100, -26
    local map = {
        city = city,
        seed = run.seed,
        x = x,
        size = size,
        front = front,
        rooms = {},
        blocks = {},
        tiles = {},
        cells = {},
    }
    local function tile(c, row)
        local id = (row - 1) * 5 + c
        local v = map.tiles[id]
        if not v then
            v = {
                id = id,
                col = c,
                row = row,
                x = x + (c - 3) * size,
                z = front - (row - 0.5) * size,
                links = {},
            }
            map.tiles[id] = v
            map.cells[#map.cells + 1] = v
        end
        return v
    end
    local function link(a, b, dir)
        a.links[dir] = b.id
        b.links[(dir + 1) % 4 + 1] = a.id
        return b
    end
    local function across(a, c)
        while a.col ~= c do
            local step = c > a.col and 1 or -1
            a = link(a, tile(a.col + step, a.row), step == 1 and 2 or 4)
        end
        return a
    end
    local function block(bx, bz, w, d, h, style)
        map.blocks[#map.blocks + 1] = { x = bx, z = bz, w = w, d = d, h = h, style = style }
    end
    local entry = 3
    for sector = 1, 3 do
        local row = 1 + (sector - 1) * 3
        local first = tile(entry, row)
        if sector > 1 then
            link(map.rooms[sector - 1].exit, first, 1)
        end
        local exits = {}
        for c = 1, 5 do
            if math.abs(c - entry) >= 2 then
                exits[#exits + 1] = c
            end
        end
        local finish = exits[1 + roll(#exits)]
        local bend = 1 + roll(5)
        local a = across(first, bend)
        a = link(a, tile(bend, row + 1), 1)
        a = across(a, finish)
        local exit = link(a, tile(finish, row + 2), 1)
        local room = {
            entry = first,
            exit = exit,
            heading = bend == entry and 0 or (bend > entry and -55 or 55),
            gate = exit.x,
            front = first.z + size / 2,
            back = exit.z - size / 2,
            spawns = {},
        }
        map.rooms[sector] = room
        -- Grow spurs from the main route, then open a subset of adjoining
        -- walls to produce loops. Frontiers always attach to a reachable tile.
        for j = 1, 2 + roll(4) do
            local candidates = {}
            for _, v in ipairs(map.cells) do
                if v.row >= row then
                    for dir, delta in ipairs(directions) do
                        local c, r = v.col + delta[1], v.row + delta[2]
                        if
                            c >= 1
                            and c <= 5
                            and r >= row
                            and r <= row + 2
                            and not map.tiles[(r - 1) * 5 + c]
                        then
                            candidates[#candidates + 1] = { v, dir, c, r }
                        end
                    end
                end
            end
            if #candidates > 0 then
                local f = candidates[1 + roll(#candidates)]
                link(f[1], tile(f[3], f[4]), f[2])
            end
        end
        local sites = {}
        for _, v in ipairs(map.cells) do
            if v.row >= row then
                for dir = 1, 2 do
                    local delta = directions[dir]
                    local c, r = v.col + delta[1], v.row + delta[2]
                    local adjacent = c <= 5 and map.tiles[(r - 1) * 5 + c]
                    if adjacent and not v.links[dir] and roll(3) == 0 then
                        link(v, adjacent, dir)
                    end
                end
                if v ~= first then
                    sites[#sites + 1] = v
                end
            end
        end
        -- Keep tile centers and the four center-to-center lanes walkable.
        for j = #sites, 2, -1 do
            local n = 1 + roll(j)
            sites[j], sites[n] = sites[n], sites[j]
        end
        for i, v in ipairs(sites) do
            if i % 2 == 1 and v ~= exit then
                local sx, sz = roll(2) * 2 - 1, roll(2) * 2 - 1
                block(
                    v.x + sx * size * 0.25,
                    v.z + sz * size * 0.25,
                    2 + 0.5 * roll(2),
                    2 + 0.5 * roll(2),
                    2.5,
                    "cover"
                )
                v.cover = map.blocks[#map.blocks]
            end
        end
        for j = 1, 10 do
            local v = j <= 2 and first or sites[1 + (j - 3) % #sites]
            room.spawns[j] = {
                x = v.x + (j % 2 == 1 and -1 or 1) * 1.35,
                z = v.z - (j <= 2 and size * 0.26 or 0.5),
                kind = ({ 1, 2, 4 })[1 + roll(3)],
            }
        end
        room.spawns[1].kind, room.spawns[2].kind, room.spawns[3].kind = 1, 2, 4
        entry = finish
    end
    for _, v in ipairs(map.cells) do
        for dir, delta in ipairs(directions) do
            if not v.links[dir] then
                local c, r = v.col + delta[1], v.row + delta[2]
                local neighbor = c >= 1 and c <= 5 and map.tiles[(r - 1) * 5 + c]
                if not neighbor or v.id < neighbor.id then
                    local side = delta[1] ~= 0
                    block(
                        v.x + delta[1] * size / 2,
                        v.z - delta[2] * size / 2,
                        side and 0.42 or size,
                        side and size or 0.42,
                        2.4 + roll(3) * 0.5,
                        "wall"
                    )
                end
            end
        end
    end
    run.layout = map
    Tour.cached = map
    return map
end
local function tileAt(map, x, z)
    local c = math.floor((x - map.x) / map.size + 3.5)
    if c < 1 or c > 5 then
        return nil
    end
    return map.tiles[math.floor((map.front - z) / map.size) * 5 + c]
end
-- Follow open links even when the last defender is around a blind corner.
-- Each block of cover has room around all four sides. A defender may stop
-- behind it within the same street tile, so guide the last few metres too.
local function aroundCover(cell, x, z, tx, tz)
    local b = cell.cover
    if not b then
        return tx, tz
    end
    local w, d = b.w / 2 + 0.25, b.d / 2 + 0.25
    local function clear(x, z, tx, tz)
        return not boxCross(x, z, tx, tz, b.x, b.z, w, d)
    end
    if clear(x, z, tx, tz) then
        return tx, tz
    end
    local corners = {}
    for _, sx in ipairs({ -1, 1 }) do
        for _, sz in ipairs({ -1, 1 }) do
            corners[#corners + 1] = { b.x + sx * (w + 0.18), b.z + sz * (d + 0.18) }
        end
    end
    local best, px, pz = math.huge, tx, tz
    for _, a in ipairs(corners) do
        if clear(x, z, a[1], a[2]) then
            for _, e in ipairs(corners) do
                if (a[1] == e[1] or a[2] == e[2]) and clear(e[1], e[2], tx, tz) then
                    local length = math.sqrt(dist(x, z, a[1], a[2]))
                        + math.abs(a[1] - e[1])
                        + math.abs(a[2] - e[2])
                        + math.sqrt(dist(e[1], e[2], tx, tz))
                    if length < best then
                        best, px, pz = length, a[1], a[2]
                    end
                end
            end
        end
    end
    return px, pz
end

local function waypoint(map, x, z, tx, tz)
    local from, to = tileAt(map, x, z), tileAt(map, tx, tz)
    if not from or not to then
        return tx, tz
    end
    if from == to then
        return aroundCover(from, x, z, tx, tz)
    end
    local queue, prev = { from }, { [from.id] = from }
    local index = 1
    while queue[index] and not prev[to.id] do
        local current = queue[index]
        for dir = 1, 4 do
            local id = current.links[dir]
            if id and not prev[id] then
                prev[id] = current
                queue[#queue + 1] = map.tiles[id]
            end
        end
        index = index + 1
    end
    local step = to
    while prev[step.id] and prev[step.id] ~= from do
        step = prev[step.id]
    end
    -- Align with the opening before turning; a diagonal can cut a solid corner.
    if
        step.row == from.row and math.abs(z - from.z) > 0.65
        or step.col == from.col and math.abs(x - from.x) > 0.65
    then
        return aroundCover(from, x, z, from.x, from.z)
    end
    return aroundCover(from, x, z, step.x, step.z)
end
local function tourBlocked(run, x, z, tx, tz, pad, y, ty)
    local minX, maxX = math.min(x, tx) - pad, math.max(x, tx) + pad
    local minZ, maxZ = math.min(z, tz) - pad, math.max(z, tz) + pad
    for _, b in ipairs(layout(run).blocks) do
        if
            minX <= b.x + b.w / 2
            and maxX >= b.x - b.w / 2
            and minZ <= b.z + b.d / 2
            and maxZ >= b.z - b.d / 2
        then
            local hit, first, last = boxCross(x, z, tx, tz, b.x, b.z, b.w / 2 + pad, b.d / 2 + pad)
            if hit and (not y or math.min(y + first * (ty - y), y + last * (ty - y)) <= b.h) then
                return true
            end
        end
    end
    return false
end
function Tour.destination(run, observer)
    local map = layout(run)
    local room = map.rooms[section(run)]
    local tx, tz = room.gate + 1.45, room.back + 1.65
    if observer then
        local _, a = remaining(run, observer)
        if a then
            tx, tz = a.x, a.z
        end
        tx, tz = waypoint(map, observer.x, observer.z, tx, tz)
    end
    return tx, tz, Tour.places[leg(run)][section(run)]
end
function Tour.move(run, x, z, dx, dz)
    local map = layout(run)
    local room = map.rooms[section(run)]
    local nx = Hall.clamp(x + dx, map.x - 2.5 * map.size + 0.5, map.x + 2.5 * map.size - 0.5)
    if tourBlocked(run, x, z, nx, z, 0.25) then
        nx = x
    end
    local nz = Hall.clamp(z + dz, room.back + 0.8, map.rooms[1].front - 0.7)
    if tourBlocked(run, nx, z, nx, nz, 0.25) then
        nz = z
    end
    return nx, nz
end
function Tour.spawn(run)
    local area = layout(run).rooms[section(run)]
    run.actors, run.hostile, run.burst = {}, {}, nil
    for i = 1, math.min(10, 5 + leg(run) + math.floor(run.members / 2) + section(run) - 1) do
        local s = area.spawns[i]
        mob(run, s.kind, s.x, s.z, s.kind == 4 and 4 or 2)
    end
end
function Tour.arrive(run, p)
    local map = layout(run)
    local i = section(run)
    p.x = i == 1 and map.x or map.rooms[i - 1].gate
    p.z = map.rooms[i].front - 2
    p.yaw = map.rooms[i].heading
end
function Tour.act(run, p, r)
    if not run.seed then
        -- Keep the departure sequence outside the room: an empty room is
        -- destroyed, and a recreated room can have the same id and clock.
        Tour.lastSeed = Tour.lastSeed and Tour.lastSeed * 48271 % 2147483647
            or 1 + ((HostUTC or 0) + math.floor(run.clock * 1000) * 131 + run.id * 7919) % 2147483600
        run.seed = Tour.lastSeed
        run.progress = 1
    else
        local room = layout(run).rooms[section(run)]
        if remaining(run) > 0 or not near(p, room.gate, room.back + 1.7, 3.6) then
            return
        end
        if run.progress == 9 then
            return true
        end
        run.progress = run.progress + 1
    end
    Tour.spawn(run)
    if section(run) == 1 then
        for _, member in pairs(r.players) do
            if member.space == 1 then
                Tour.arrive(run, member)
                member.vital, member.armor, member.immunity = 5, 1, run.clock + 0.8
            end
        end
    end
end

local function spawnWave(run)
    local stop = stops[run.progress]
    local count = math.min(9, 3 + run.members + run.wave)
    run.actors = {}
    for i = 1, count do
        local side = (i + run.wave) % 2 == 0 and 1 or -1
        local x = side * (2.4 + (i * 3 + run.wave) % 7)
        local z = stop[4] + 3 - (i * 5 + run.wave * 2) % 8
        if run.wave > 1 and i % 2 == 1 then
            local bay = bays[run.progress]
            x = bay.side * (bay.width - 4 - (3 * i + run.wave) % 10)
            z = bay.z + 6 - (i * 5) % 13
        end
        if crateBlocks(x, z, x, z, 0.5) then
            z = z + 3.6
        end
        local kind = run.progress == 16 and i % 3 ~= 0 and 7 or (i + run.wave) % 2 + 1
        mob(run, kind, x, z, kind == 7 and 1 or 2)
    end
end
local function advance(run)
    run.progress = math.min(#stops, run.progress + 1)
    run.wave, run.changed, run.key, run.reinforceAt = 1, run.clock, false, nil
    local k = run.progress
    if k == 9 then
        run.liftoff = run.clock
    end
    if shootouts[k] then
        spawnWave(run)
        return
    end
    if k == 4 or k == 8 or k == 10 or k == 11 or k == 13 or k == 18 then
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
    run.secrets, run.wave, run.liftoff, run.drive, run.changed = 0, 1, 0, 1, 0
    run.hostile = {}
    mob(run, 1, -3, 0, 2)
    mob(run, 1, 3, -4, 2)
end
function M.move(x, z, dx, dz, run, p)
    if run.seed then
        return Tour.move(run, x, z, dx, dz)
    end
    if math.floor(run.secrets / 2) % 2 == 1 and math.abs(z + 261) < 2.8 and (x > 13.4 or x + dx > 13.4) then
        return Hall.clamp(x + dx, -13.4, 21.4), Hall.clamp(z + dz, -263.7, -258.3)
    end
    local width = M.area(z) == 4 and 5.5 or 13.4
    local phase = run.progress
    local stop = stops[phase]
    local edge = phase == 1 and roofEnd - 2 or stop[4] - 5
    if bays[phase] then
        edge = bays[phase].z - 10
    end
    if phase == 12 then
        edge = -163
    end
    if phase == 18 then
        edge = -301
    end
    if phase == 15 and not p.tiny then
        edge = -199
    end
    local low, high = -width, width
    local nextZ = z + dz
    for _, bay in pairs(bays) do
        if math.abs(z - bay.z) < 9.5 then
            if x * bay.side > 13.4 then
                nextZ = Hall.clamp(nextZ, bay.z - 9.45, bay.z + 9.45)
            end
            if math.abs(nextZ - bay.z) < 9.5 then
                if bay.side > 0 then
                    high = bay.width - 0.45
                else
                    low = -bay.width + 0.45
                end
            end
            break
        end
    end
    local nx = Hall.clamp(x + dx, low, high)
    local nz = Hall.clamp(nextZ, edge, 7.4)
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
    if crateBlocks(x, z, nx, z, 0.24) then
        nx = x
    end
    if crateBlocks(nx, z, nx, nz, 0.24) then
        nz = z
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
local function visible(run, x, z, tx, tz, y, ty)
    if run.seed then
        return not tourBlocked(run, x, z, tx, tz, 0, y, ty)
    end
    if crateBlocks(x, z, tx, tz, 0) then
        return false
    end
    for _, edge in ipairs(boundaries) do
        if (z - edge) * (tz - edge) < 0 and math.abs(x + (tx - x) * (edge - z) / (tz - z)) > 3.1 then
            return false
        end
    end
    -- A shot crossing an outer wall must pass through the open bay front.
    for _, side in ipairs({ -1, 1 }) do
        local start, finish = x * side, tx * side
        if (start - 14) * (finish - 14) < 0 then
            local crossing = z + (tz - z) * (14 - start) / (finish - start)
            local open = false
            for _, bay in pairs(bays) do
                if bay.side == side and math.abs(crossing - bay.z) < 10 then
                    open = true
                    break
                end
            end
            if not open then
                return false
            end
        end
    end
    return true
end
local function damage(run, p, amount)
    if p.immunity > run.clock then
        return
    end
    local absorbed = math.min(p.armor or 0, amount)
    p.armor = (p.armor or 0) - absorbed
    p.vital = p.vital - amount + absorbed
    p.immunity, p.lastHurt = run.clock + 1.15, run.clock
    if p.vital <= 0 then
        M.enter(run, p)
        p.lastHurt, p.respawned = run.clock, run.clock
    end
end
local function pickups(run, p)
    for i, item in ipairs(supplies) do
        if not held(p.claimed, i) and near(p, item[2], item[3], 1.45) then
            local vest = item[1] == "vest"
            local stat = vest and "armor" or "vital"
            local cap = vest and 3 or 5
            if p[stat] < cap then
                p[stat] = math.min(cap, p[stat] + (vest and 2 or 3))
                p.claimed = p.claimed + 2 ^ (i - 1)
            end
        end
    end
    local pass = passes[run.progress]
    if pass and near(p, pass[1], pass[2], 1.55) then
        run.key = true
    end
end
local function moveBolts(run, r, dt)
    for i = #run.hostile, 1, -1 do
        local b = run.hostile[i]
        local tx, ty, tz = b.x + b.vx * dt, b.y + b.vy * dt, b.z + b.vz * dt
        local spent = run.clock >= b.expires or not visible(run, b.x, b.z, tx, tz, b.y, ty)
        if not spent then
            local best, hit = 2, nil
            local dx, dy, dz = tx - b.x, ty - b.y, tz - b.z
            local length = math.max(0.000001, dx * dx + dy * dy + dz * dz)
            for _, p in pairs(r.players) do
                if p.space == 1 then
                    local cy = eyeHeight(p) - (p.tiny and 0.15 or 0.55)
                    local u =
                        Hall.clamp(((p.x - b.x) * dx + (cy - b.y) * dy + (p.z - b.z) * dz) / length, 0, 1)
                    if
                        u < best
                        and dist(p.x, p.z, b.x + u * dx, b.z + u * dz) + (cy - b.y - u * dy) ^ 2
                            < (p.tiny and 0.36 or 0.72) ^ 2
                    then
                        hit, best = p, u
                    end
                end
            end
            if hit then
                damage(run, hit, b.heavy and 2 or 1)
                spent = true
            end
        end
        if spent then
            table.remove(run.hostile, i)
        else
            b.x, b.y, b.z = tx, ty, tz
        end
    end
end
local function ranged(run, a, p, distance, dt)
    if a.ice > run.clock or a.small > run.clock or (a.impact and run.clock - a.impact.at < 0.22) then
        a.windup, a.second = nil, nil
        a.nextAttack = run.clock + 0.65
        return
    end
    local sight = distance < 32
        and (run.seed or M.area(a.z) == M.area(p.z) or math.abs(a.z - p.z) < 10)
        and visible(run, a.x, a.z, p.x, p.z, a.kind == 2 and 2.05 or 1.2, eyeHeight(p) - 0.55)
    if a.windup then
        if run.clock >= a.windup then
            a.windup = nil
            if sight and #run.hostile < 24 then
                a.firedAt = run.clock
                local speed = a.kind == 4 and 19 or a.kind == 2 and 12 or 15
                local y = roofHeight(a.z) + (a.kind == 2 and 2.05 or 1.2)
                local fan = a.kind == 2 and 1 or a.kind == 4 and 2 or 0
                for ray = -fan, fan do
                    local angle = ray * (a.kind == 4 and 0.16 or 0.23)
                    if #run.hostile < 24 then
                        run.hostile[#run.hostile + 1] = {
                            x = a.x,
                            y = y,
                            z = a.z,
                            vx = (a.ax * math.cos(angle) - a.az * math.sin(angle)) * speed,
                            vy = a.ay * speed,
                            vz = (a.ax * math.sin(angle) + a.az * math.cos(angle)) * speed,
                            expires = run.clock + 2.7,
                            heavy = a.kind == 4,
                        }
                    end
                end
                if run.seed and a.kind == 1 and not a.second then
                    a.windup, a.second = run.clock + 0.25, true
                    return
                end
            end
            a.second = nil
            a.nextAttack = run.clock + 1.45 + (a.id % 4) * 0.23
        end
        return
    end
    a.nextAttack = a.nextAttack or run.clock + 0.75 + (a.id % 5) * 0.18
    if sight and run.clock >= a.nextAttack then
        local dy = eyeHeight(p) - (p.tiny and 0.15 or 0.55) - roofHeight(a.z) - (a.kind == 2 and 2.05 or 1.2)
        local d = math.max(0.01, math.sqrt(distance * distance + dy * dy))
        a.ax, a.ay, a.az = (p.x - a.x) / d, dy / d, (p.z - a.z) / d
        a.windup = run.clock + (a.kind == 4 and 0.90 or a.kind == 2 and 0.60 or 0.42)
        a.yaw = math.deg(math.atan2(a.ax, a.az))
        return
    end
    if distance < 0.01 or distance > 34 then
        return
    end
    local dx, dz = (p.x - a.x) / distance, (p.z - a.z) / distance
    local advance = a.kind == 4 and 0 or distance > 10 and 2.5 or distance < 4 and -1.5 or 0
    local side = a.kind == 2 and 1.9 * math.sin(run.clock * 1.2 + a.id) or 0
    local nx, nz = a.x + (advance * dx - side * dz) * dt, a.z + (advance * dz + side * dx) * dt
    if visible(run, a.x, a.z, nx, nz) then
        a.x, a.z = M.move(a.x, a.z, nx - a.x, nz - a.z, run, p)
    end
end
function M.step(run, r, dt)
    run.clock = run.clock + dt
    moveBolts(run, r, dt)
    local waves = not run.seed and shootouts[run.progress]
    if waves and not run.key and run.wave < waves and remaining(run) == 0 then
        run.reinforceAt = run.reinforceAt or run.clock + 0.85
        if run.clock >= run.reinforceAt then
            run.wave, run.reinforceAt = run.wave + 1, nil
            spawnWave(run)
        end
    end
    for _, p in pairs(r.players) do
        if p.space == 1 and run.progress > 15 then
            p.tiny = false
        end
        if p.space == 1 and not run.seed then
            pickups(run, p)
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
                if a.ice <= run.clock and not a.windup then
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
                    and (run.seed or a.kind == 5 or a.kind <= 2 or a.kind == 7)
                then
                    a.hp = 0
                    a.impact =
                        { at = run.clock, owner = player.id, seq = player.seq, dx = 0, dz = 0, result = 2 }
                    if a.kind == 5 and run.progress == 13 then
                        advance(run)
                    end
                elseif a.kind <= 2 or (run.seed and a.kind == 4) then
                    ranged(run, a, player, len, dt)
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
                    damage(run, player, 1)
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
-- The rooftop slope joins two level floors. Intersect the shot with
-- each floor section so a downward shot can burst between enemies.
local function floorImpact(origin, dx, dy, dz)
    local eye = origin.eye + origin.oy
    local cuts = { 0, 36 }
    if math.abs(dz) > 0.0001 then
        for _, z in ipairs({ roofEnd, roofEnd + 3.25 / 0.2955 }) do
            local t = (z - origin.z) / dz
            if t > 0 and t < 36 then
                cuts[#cuts + 1] = t
            end
        end
    end
    table.sort(cuts)
    local last = eye - roofHeight(origin.z)
    for i = 2, #cuts do
        local t = cuts[i]
        local above = eye + dy * t - roofHeight(origin.z + dz * t)
        if last > 0 and above <= 0 then
            local at = cuts[i - 1] + (t - cuts[i - 1]) * last / (last - above)
            return origin.x + dx * at, origin.z + dz * at
        end
        last = above
    end
end
function M.fire(run, p, seq, k, dx, dy, dz, r, ox, oy, oz)
    local length = math.sqrt(dx * dx + dy * dy + dz * dz)
    if
        k % 1 ~= 0
        or k < 1
        or seq % 1 ~= 0
        or seq <= p.seq
        or k > M.unlocked(run)
        or p.cool > r.time
        or length < 0.1
    then
        return
    end
    dx, dy, dz = dx / length, dy / length, dz / length
    p.seq, p.cool, p.weapon = seq, r.time + M.delays[k], k
    local origin = { x = p.x + (ox or 0), z = p.z + (oz or 0), eye = eyeHeight(p), oy = oy or 0 }
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
            and visible(run, origin.x, origin.z, a.x, a.z, origin.eye + origin.oy, height + roofHeight(a.z))
            and aimed(origin, a.x, a.z, dx, dy, dz, height + roofHeight(a.z), radius)
        then
            closest, distance = a, d
        end
    end
    local can = not run.seed and soda[run.progress]
    if
        can
        and math.floor(run.secrets / can[3]) % 2 == 0
        and dist(origin.x, origin.z, can[1], can[2]) < distance
        and visible(run, origin.x, origin.z, can[1], can[2])
        and aimed(origin, can[1], can[2], dx, dy, dz, 1.16, 0.85)
    then
        run.secrets = bit.bor(run.secrets, can[3])
        for _, a in ipairs(run.actors) do
            if
                a.hp > 0
                and dist(a.x, a.z, can[1], can[2]) < 7 ^ 2
                and visible(run, can[1], can[2], a.x, a.z)
            then
                a.hp = 0
                a.impact = { at = run.clock, owner = p.id, seq = seq, dx = dx, dz = dz, result = 2 }
            end
        end
        return
    end
    if not run.seed and (run.progress == 3 or run.progress == 19) then
        local x, z = M.cart(run)
        if run.progress == 3 then
            x = 0
        end
        if
            dist(origin.x, origin.z, x, z) < distance
            and visible(run, origin.x, origin.z, x, z)
            and aimed(origin, x, z, dx, dy, dz, 1.65, 1.1)
        then
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
    local bx, bz
    if k == 3 then
        if closest then
            bx, bz = closest.x, closest.z
        end
        local fx, fz = floorImpact(origin, dx, dy, dz)
        if
            fx
            and dist(origin.x, origin.z, fx, fz) < distance
            and visible(run, origin.x, origin.z, fx, fz, origin.eye + origin.oy, roofHeight(fz))
        then
            bx, bz, closest = fx, fz, nil
        end
        if bx then
            run.burst = { x = bx, z = bz, at = run.clock }
        end
    end
    for _, a in ipairs(run.actors) do
        local hit = a == closest or (bx and dist(a.x, a.z, bx, bz) < 20 and visible(run, bx, bz, a.x, a.z))
        if hit and a.hp > 0 then
            local hp = a.hp
            local frozen = a.ice > run.clock
            local result = 1 -- hit, defeat, armor, freeze, shrink

            local grunt = run.seed or a.kind <= 2 or a.kind == 7
            if a.kind == 6 and run.progress == 18 and clearEggs(run) then
                a.hp = math.max(1, a.hp - (k == 3 and 4 or k == 5 and 2 or 1))
                if a.hp == 1 then
                    advance(run)
                end
            elseif a.kind == 6 or (not run.seed and a.kind == 4 and k ~= 3) or (a.kind == 5 and k ~= 4) then
                result = 3
            elseif grunt and frozen then
                a.hp = 0
            elseif k == 2 then
                result, a.ice = 4, run.clock + 12
            elseif k == 4 then
                result, a.small = 5, run.clock + 16
            elseif not run.seed and a.kind == 4 and k == 3 and run.progress == 8 then
                a.hp = 0
                advance(run)
            elseif a.kind == 3 and not run.slide and not a.mascot then
                a.hp = a.hp - 1
                if a.hp <= 0 then
                    a.hp, a.x, a.z, a.ice, a.mascot = 4, -5, -55, 0, true
                end
            elseif grunt then
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
function M.kick(run, p, seq, yaw)
    if seq <= p.seq or seq % 1 ~= 0 or run.clock - (p.kickAt or -1) < 0.46 then
        return
    end
    p.kickAt, p.seq = run.clock, seq
    local dx, dz = -math.sin(math.rad(yaw)), -math.cos(math.rad(yaw))
    local target, best = nil, 2.6 ^ 2
    for _, a in ipairs(run.actors) do
        local d = dist(p.x, p.z, a.x, a.z)
        if
            a.hp > 0
            and d < best
            and (a.x - p.x) * dx + (a.z - p.z) * dz >= math.sqrt(d) * 0.45
            and visible(run, p.x, p.z, a.x, a.z)
        then
            target, best = a, d
        end
    end
    if not target then
        return
    end
    local a = target
    local result = 3
    if a.kind <= 2 or a.kind == 7 or (run.seed and (a.ice > run.clock or a.small > run.clock)) then
        a.hp = (a.ice > run.clock or a.small > run.clock) and 0 or math.max(0, a.hp - 1)
        result = a.hp == 0 and 2 or 1
    end
    a.impact = { at = run.clock, owner = p.id, seq = seq, dx = dx, dz = dz, result = result }
end
function M.act(run, p, room)
    if run.seed or (room and run.progress == 1 and near(p, 1.6, 2.7, 3.25)) then
        return Tour.act(run, p, room)
    end
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
                -- The till's magnet pulls a frozen skater home from either side.
                local dx, dz = 9 - a.x, -66 - a.z
                local length = math.max(0.01, math.sqrt(dx * dx + dz * dz))
                run.slide, run.slideX, run.slideZ = true, dx / length, dz / length
                a.ice = run.clock + 5
            end
        end
        return
    end
    if shootouts[k] and not run.key and (run.wave < shootouts[k] or remaining(run) > 0) then
        return
    end
    local s = stops[k]
    if not near(p, s[3], s[4], 3.4) then
        return
    end
    if k == 3 or k == 8 or k == 13 or k == 18 or k == 19 then
        return
    end
    if k == 12 and run.clock - run.launch < 12 then
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
    if k == 20 then
        return true
    end
    advance(run)
end
function M.hint(run, p)
    local hit = p.respawned and run.clock - p.respawned < 1.4 and "Back at checkpoint.  "
        or p.lastHurt and run.clock - p.lastHurt < 0.85 and "HIT!  "
        or ""
    if run.seed then
        local map = layout(run)
        if math.abs(p.x - map.x) < 2 and p.z > map.rooms[1].front - 1.7 then
            return "Walk past the return sign to leave for the hall."
        end
        local room = map.rooms[section(run)]
        local count = remaining(run)
        local goal = run.done and "Ornament earned - Use to return"
            or count > 0 and string.format("%d hostiles", count)
            or string.format("Use the lit exit  [%dm]", math.sqrt(dist(p.x, p.z, room.gate, room.back + 1.7)))
        return hit
            .. Tour.names[leg(run)]
            .. "  /  "
            .. Tour.places[leg(run)][section(run)]
            .. "  /  "
            .. goal
            .. "  #"
            .. run.seed
    end
    if run.progress == 1 and near(p, 1.6, 2.7, 4.7) then
        return hit .. "Use the World Tour sign for three random maps, or take the vent for Tinseltown."
    end
    if run.done then
        return "RETURN TO SENDER  /  Ornament earned - walk through the north tunnel"
    end
    local s = stops[run.progress]
    if near(p, -11, -27, 3) and run.secrets % 2 == 1 then
        return "OUT OF ORDER - the usher would like a word."
    end
    if near(p, 11, -261, 3) and math.floor(run.secrets / 2) % 2 == 1 then
        return "FAMILY SIZE - popcorn has opened the viewing box."
    end
    local x, z, hint = destination(run, p)
    local distance = math.sqrt(dist(p.x, p.z, x, z))
    local bearing = math.deg(math.atan2(p.x - x, p.z - z))
    local angle = (bearing - p.yaw + 180) % 360 - 180
    local direction = math.abs(angle) < 30 and "ahead"
        or math.abs(angle) > 140 and "behind"
        or angle > 0 and "left"
        or "right"
    if run.progress == 12 then
        hint = hint .. " " .. math.ceil(math.max(0, 12 - run.clock + run.launch)) .. "s"
    end
    return hit .. string.format("%s / %s  [%dm %s]", s[1], hint, distance, direction)
end
function M.atExit(run, p)
    if run.seed then
        local map = layout(run)
        return math.abs(p.x - map.x) < 1.7 and p.z > map.rooms[1].front - 1.05
    end
    return run.done and p.z < -300 and near(p, 0, -302, 4)
end
function M.canReturn(run, p)
    if run.seed then
        local map = layout(run)
        return run.done or near(p, map.x, map.rooms[1].front - 1, 2.2)
    end
    return p.z > 5.9 or (run.done and near(p, 0, -302, 4))
end

-- Numeric rows travel on the room's existing engine snapshot channel.
function M.snapshot(rows, run, players, day)
    local function emit(format, ...)
        rows[#rows + 1] = string.format("D %d " .. format, day, ...)
    end
    emit(
        "0 %.3f %.3f %d %.3f %d %d %.3f %d %.3f %d",
        run.clock,
        run.launch,
        run.secrets,
        run.charge,
        run.slide and 1 or 0,
        run.wave,
        run.liftoff,
        run.drive,
        run.changed,
        run.key and 1 or 0
    )
    if run.seed then
        emit("5 %d", run.seed)
    end
    for _, a in ipairs(run.actors) do
        local h = a.impact
        emit(
            "1 %d %.2f %.2f %d %.2f %.2f %d %d %.1f %.2f %.3f %d %d %.2f %.2f %d %.3f %.3f",
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
            h and h.result or 0,
            a.windup or 0,
            a.firedAt or -1
        )
    end
    if run.burst and run.clock - run.burst.at < 0.35 then
        emit("4 %.3f %.3f %.3f", run.burst.x, run.burst.z, run.burst.at)
    end
    for _, b in ipairs(run.hostile) do
        emit("3 %.3f %.3f %.3f %.3f %.3f %.3f %d", b.x, b.y, b.z, b.vx, b.vy, b.vz, b.heavy and 1 or 0)
    end
    for id, p in pairs(players) do
        if p.space == day then
            emit(
                "2 %d %d %d %d %d %d %.3f %.3f %.3f",
                id,
                p.tiny and 1 or 0,
                p.vital,
                p.seq,
                p.armor,
                p.claimed,
                p.kickAt,
                p.lastHurt or -1,
                p.respawned or -1
            )
        end
    end
end
function M.read(r, w)
    local run = r.instances[w[2]]
    if not run or not stops[run.progress] then
        return false
    end
    if
        w[3] == 0
        and #w == 13
        and posts[w[11]]
        and w[9] % 1 == 0
        and w[9] >= 1
        and w[9] <= (shootouts[run.progress] or 1)
    then
        run.clock, run.launch, run.secrets, run.charge, run.slide = w[4], w[5], w[6], w[7], w[8] == 1
        run.wave, run.liftoff, run.drive = w[9], w[10], w[11]
        run.changed = w[12]
        run.actors, run.hostile, run.key = {}, {}, w[13] == 1
    elseif
        w[3] == 1
        and #w == 21
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
            windup = w[20] > 0 and w[20] or nil,
            firedAt = w[21] >= 0 and w[21] or nil,
        }
        if w[19] > 0 and w[19] <= 5 then
            a.impact = { at = w[14], owner = w[15], seq = w[16], dx = w[17], dz = w[18], result = w[19] }
        end
        run.actors[#run.actors + 1] = a
    elseif
        w[3] == 5
        and #w == 4
        and w[4] >= 1
        and w[4] < 2147483647
        and w[4] % 1 == 0
        and run.progress <= 9
    then
        run.seed = w[4]
    elseif w[3] == 4 and #w == 6 then
        run.burst = { x = w[4], z = w[5], at = w[6] }
    elseif w[3] == 3 and #w == 10 and run.hostile and #run.hostile < 24 then
        run.hostile[#run.hostile + 1] =
            { x = w[4], y = w[5], z = w[6], vx = w[7], vy = w[8], vz = w[9], heavy = w[10] == 1 }
    elseif w[3] == 2 and #w == 12 and r.players[w[4]] then
        local p = r.players[w[4]]
        p.tiny, p.vital, p.seq, p.armor, p.claimed, p.kickAt = w[5] == 1, w[6], w[7], w[8], w[9], w[10]
        p.lastHurt = w[11] >= 0 and w[11] or nil
        p.respawned = w[12] >= 0 and w[12] or nil
    else
        return false
    end
    return true
end

function M.validSnapshot(run, player)
    return run and run.actors and player.vital and run.wave ~= nil
end

-- Client-only presentation. The dedicated service loads no artwork.
local art, nodes, actors, eggs = {}, {}, {}, {}
local gunArt = { "sidearm", "freezer", "rpg", "shrinker", "twins" }
local bolts = {}
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
-- The generator supplies geometry for movement, enemy sight, and this pool.
-- Only the current map is dressed, and its entities are reused on a replay.
local tourScene = { pool = {} }
local tourColors = {
    { { 0.17, 0.16, 0.22 }, { 0.45, 0.28, 0.32 }, { 0.89, 0.28, 0.42 }, { 0.48, 0.36, 0.23 } },
    { { 0.38, 0.40, 0.46 }, { 0.35, 0.37, 0.44 }, { 0.32, 0.70, 0.84 }, { 0.57, 0.57, 0.52 } },
    { { 0.35, 0.45, 0.22 }, { 0.24, 0.36, 0.17 }, { 0.82, 0.68, 0.28 }, { 0.52, 0.36, 0.19 } },
}
local function dressTour(run)
    local map = layout(run)
    local city = map.city
    if tourScene.seed == run.seed and tourScene.city == city then
        return
    end
    tourScene.seed, tourScene.city = run.seed, city
    local used = 0
    local colors = tourColors[city]
    local function mesh(model, x, y, z, w, h, d, material, yaw)
        used = used + 1
        local e = tourScene.pool[used]
        if not e then
            e = eng.scene.spawn("World Tour scenery")
            tourScene.pool[used] = e
            eng.scene.set_pocket(e, pocket)
        end
        eng.scene.set_mesh(e, model, material)
        eng.scene.set_pos(e, x, y, z)
        eng.scene.set_rot_deg(e, 0, yaw or 0, 0)
        eng.scene.set_scale(e, w, h, d)
    end
    local function box(x, y, z, w, h, d, color, glow)
        mesh(World.box, x, y, z, w, h, d, { color = color, emissive = glow or 0.04 })
    end
    local function landmark(name, x, y, z, size, yaw)
        mesh(
            art[name],
            x,
            y,
            z,
            size,
            size,
            size,
            { tex = World.palette, metallic = -4, roughness = 0.85 },
            yaw
        )
    end
    local buildings = { "tour-sunset", "tour-relay", "tour-farm" }
    local horizon = { "tour-skyline", "tour-earthrise", "tour-borde" }
    for _, cell in ipairs(map.cells) do
        local span = map.size
        box(cell.x, -0.19, cell.z, span, 0.38, span, colors[1])
        if city == 2 and cell.id % 3 == 0 then
            landmark("tour-craters", cell.x, 0, cell.z, 0.40, 0)
        end
        for dir = 1, 4 do
            if cell.links[dir] then
                local dx, dz = directions[dir][1], -directions[dir][2]
                local w = dx == 0 and 0.22 or span * 0.25
                local d = dx == 0 and span * 0.25 or 0.22
                if city == 3 then
                    w = dx == 0 and 2.8 or span * 0.5
                    d = dx == 0 and span * 0.5 or 2.8
                end
                box(
                    cell.x + dx * span * 0.25,
                    0.012,
                    cell.z + dz * span * 0.25,
                    w,
                    0.024,
                    d,
                    city == 3 and colors[4] or colors[3]
                )
            end
        end
    end
    for i, room in ipairs(map.rooms) do
        local cell = room.exit
        -- The landmark faces an open lane from the outside of the perimeter.
        for _, v in ipairs(map.cells) do
            if v.row == cell.row and math.abs(v.x - map.x) > math.abs(cell.x - map.x) then
                cell = v
            end
        end
        local side = cell.x >= map.x and 1 or -1
        landmark(buildings[city], cell.x + side * (map.size / 2 + 4), 0, cell.z, 1.25, -side * 58)
        if city == 3 and i == 1 then
            box(room.gate, 0.04, room.back, map.size, 0.085, 3.4, { 0.12, 0.44, 0.62 })
            for n = -4, 4 do
                box(room.gate, 0.105, room.back + n * 0.42, 4.8, 0.13, 0.38, colors[4])
            end
            for _, side in ipairs({ -1, 1 }) do
                box(room.gate + 2.28 * side, 0.82, room.back, 0.12, 0.13, 3.9, colors[4])
                for n = -1, 1 do
                    box(room.gate + 2.28 * side, 0.44, room.back + n * 1.8, 0.18, 0.88, 0.18, colors[4])
                end
            end
        end
        landmark("switch", room.gate + 1.45, 0.12, room.back + 1.65, 0.85, 0)
    end
    landmark("tour-return", map.x + 1.7, 0, map.rooms[1].front - 0.25, 0.8, 180)
    for _, b in ipairs(map.blocks) do
        local cover = b.style == "cover"
        local color = cover and colors[4] or colors[2]
        if cover then
            local prop = ({ "tour-props", "tour-lander", "tour-hay" })[city]
            mesh(art[prop], b.x, 0, b.z, b.w / 3, b.h / 2.5, b.d / 3, { tex = World.palette, metallic = -4 })
        else
            box(b.x, b.h / 2, b.z, b.w, b.h, b.d, color)
            box(b.x, b.h - 0.17, b.z, b.w + 0.04, 0.19, b.d + 0.04, colors[3], 0.12)
        end
    end
    landmark(horizon[city], map.x, 0, map.rooms[3].back - 9, 1.1, 0)
    for i = used + 1, #tourScene.pool do
        eng.scene.set_pos(tourScene.pool[i], 0, -100, 0)
    end
end

function M.build(space, pedestal)
    pocket = space
    crewTexture = eng.asset.load_texture("missions/day_01/crew-hide.png", true)
    eng.scene.set_pos(pedestal, 0, -50, 0)
    for _, name in ipairs({
        "tour-return",
        "tour-kiosk",
        "tour-sunset",
        "tour-relay",
        "tour-farm",
        "tour-skyline",
        "tour-earthrise",
        "tour-borde",
        "tour-hay",
        "tour-lander",
        "tour-props",
        "tour-craters",
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
        "switch",
        "fizz",
        "medkit",
        "vest",
        "freight-crate",
        "keycard",
        "quick-boot",
        "sidearm",
        "rpg",
        "freezer",
        "shrinker",
        "twins",
    }) do
        art[name] = eng.asset.load_mesh("missions/day_01/" .. name .. ".glb")
        assert(art[name] and art[name] ~= 0, "Missing Day 1 art: " .. name)
    end
    for i, name in ipairs(gunArt) do
        bolts[i] = eng.asset.load_texture("missions/day_01/shot-" .. name .. ".png", true)
    end
    nodes.tourKiosk = place("World Tour departures", "tour-kiosk", 1.6, roofHeight(2.7), 2.7, 0.87)
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
    for _, name in ipairs({ "wall-brick", "wall-bulkhead", "wall-hive", "floor-deck", "floor-regolith" }) do
        local path = "missions/day_01/" .. name
        art[name] = eng.asset.load_mesh(path .. ".glb")
        local face = place(name, name, 0, 0, 0, 1)
        eng.scene.set_mesh(
            face,
            art[name],
            { tex = eng.asset.load_texture(path .. ".png", true), metallic = -4, roughness = 0.92 }
        )
    end
    for _, name in ipairs({ "cart", "rocket", "plywood", "earth", "score", "out", "corn" }) do
        nodes[name] = place(name, name, 0, -80, 0, 1)
    end
    art.ornament = eng.asset.load_mesh("assets/brass-rocket.glb")
    for i, box in ipairs(crates) do
        place("Freight cover", "freight-crate", box[1], 0, box[2], 1)
    end
    nodes.supplies = {}
    for i, item in ipairs(supplies) do
        nodes.supplies[i] = place(item[1], item[1], item[2], 0.2, item[3], 1)
    end
    nodes.card = place("Access card", "keycard", 0, -80, 0, 1)
    nodes.boot = place("Quick kick", "quick-boot", 0, -80, 0, 1)
    nodes.prize = place("Brass ornament", "ornament", 0, -80, 0, 0.68)
    nodes.boxDoor = eng.scene.spawn("Concession shutter")
    eng.scene.set_pocket(nodes.boxDoor, pocket)
    eng.scene.set_mesh(nodes.boxDoor, World.box, { color = { 0.42, 0.19, 0.12, 1 } })
    eng.scene.set_scale(nodes.boxDoor, 0.32, 4, 6.4)
    for _, name in ipairs({ "action", "secondAction" }) do
        nodes[name] = eng.scene.spawn("Weapon mechanism")
        eng.scene.set_parent(nodes[name], World.gun)
        eng.scene.set_pocket(nodes[name], pocket)
    end
    nodes.switch = place("Exit switch", "switch", 0, -80, 0, 1)
    nodes.soda = place("Fizzy concession", "fizz", 0, -80, 0, 1)
    nodes.beacon = place("Dispatch beacon", "rocket", 0, -80, 0, 0.22)
    nodes.latch = place("Striped stage target", "bullseye", 0, -80, 0, 1)
    nodes.parcel = place("Live cargo", "cart", 0, -80, 0, 0.8)
    nodes.gate = eng.scene.spawn("Freight shutter")
    eng.scene.set_pocket(nodes.gate, pocket)
    eng.scene.set_mesh(nodes.gate, World.box, { color = { 0.40, 0.15, 0.10, 1 }, emissive = 0.07 })
    eng.scene.set_scale(nodes.gate, 6, 3.7, 0.25)
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
    if
        a.firedAt
        and a.firedAt >= g.feedback.dayJoined
        and t - a.firedAt < 0.3
        and (slot.shotId ~= a.id or slot.shotAt ~= a.firedAt)
    then
        slot.shotId, slot.shotAt = a.id, a.firedAt
        Feedback.sound(
            g,
            a.kind == 4 and "d1-launch" or "d1-slide",
            0.53,
            a.kind == 2 and 1.4 or 0.78,
            2,
            a.x,
            1.4,
            a.z,
            32
        )
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
    local fallen = a.hp <= 0 and math.min(1, age / (a.kind == 2 and 0.95 or 0.68)) or 0
    local crash = fallen * fallen
    local tumble = math.sin(fallen * math.pi) * motion
    local recoil = hit * hit * motion
    local dx, dz = h and h.dx or 0, h and h.dz or 0
    local visible = a.kind ~= 7 and (a.hp > 0 or fallen < 1)
    eng.scene.set_pos(
        slot.node,
        a.x + dx * (0.32 * recoil + fallen * 0.75 * motion),
        visible and y - crash * (a.kind == 2 and 0.85 or 0.18) + tumble * (a.kind == 2 and 0.55 or 0.12)
            or -80,
        a.z + dz * (0.32 * recoil + fallen * 0.75 * motion)
    )
    local windup = a.kind == 6 and run.progress == 18 and run.charge - t > 3.8
    local facing = math.rad(a.yaw or 0)
    local forward = dx * math.sin(facing) + dz * math.cos(facing)
    local side = dx * math.cos(facing) - dz * math.sin(facing)
    eng.scene.set_rot_deg(
        slot.node,
        (windup and -18 or a.windup and a.kind == 4 and 11 or 0) * motion
            + 19 * forward * recoil
            + fallen * 65 * motion,
        (a.yaw or 0) + (a.kind == 2 and fallen * 245 * motion or 0),
        (a.kind == 4 and crash * 78 or a.kind == 2 and tumble * 75 or 0) * motion
            + (a.kind == 3 and 11 or 4) * gait
            - side * 19 * recoil
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
            if fallen > 0 then
                angle = angle + (leg and -42 or -85) * tumble
            end
            if a.windup and j == 4 then
                angle = -75
            end
            if frozen then
                angle, roll = 0, 0
            end
            eng.scene.set_rot_deg(node, angle, 0, roll)
        end
    end
end

function M.presentShot(g, aim)
    local sounds = { "d1-slide", "d1-freeze", "d1-launch", "d1-shrink", "d1-twins" }
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
    set(nodes.tourKiosk, 1.6, (not run.seed and phase == 1) and roofHeight(2.7) or -80, 2.7)
    if run.seed then
        dressTour(run)
    end
    set(nodes.cart, cx, (phase == 3 or phase == 19) and 0 or -80, cz)
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
    local orbit = Hall.clamp((t - run.launch) / 12, 0, 1)
    local cabin = M.area(p.z) == 4
    set(nodes.earth, cabin and -3.8 or 8, cabin and 1.4 or 14, cabin and -165.2 or -243)
    local earthSize = cabin and 2.1 - orbit * 1.65 or 3
    size(nodes.earth, earthSize, earthSize, earthSize)
    set(nodes.score, 0, run.done and 4.1 or -80, -301)
    set(nodes.out, -11, run.secrets % 2 == 1 and 1.8 or -80, -27)
    set(nodes.corn, 11, math.floor(run.secrets / 2) % 2 == 1 and 0.1 or -80, -261)
    size(nodes.corn, 2, 2, 2)
    set(nodes.boxDoor, 14, math.floor(run.secrets / 2) % 2 == 1 and 6.3 or 2, -261)
    set(
        nodes.parcel,
        phase <= 2 and 2 * math.sin(t) or -8,
        phase <= 2 and 2.4 or 0.2,
        phase <= 2 and -35 or -234
    )
    set(nodes.prize, phase == 20 and 0 or -8, phase >= 16 and 1.1 or -80, phase == 20 and -296 or -234)
    spin(nodes.prize, 0, t * 42, 0)
    for i, item in ipairs(supplies) do
        set(nodes.supplies[i], item[2], held(p.claimed, i) and -80 or roofHeight(item[3]) + 0.12, item[3])
    end
    local pass = passes[phase]
    if pass and not run.key then
        set(nodes.card, pass[1], 1.1, pass[2])
        spin(nodes.card, 0, 25 + t * 65 * motion, 0)
    else
        set(nodes.card, 0, -80, 0)
    end
    local kickAge = t - (p.kickAt or -1)
    if kickAge >= 0 and kickAge < 0.32 then
        local kick = math.sin(math.pi * kickAge / 0.32) * motion
        local yaw = math.rad(g.yaw)
        local reach = 0.52 + 0.45 * kick
        set(
            nodes.boot,
            g.x - math.sin(yaw) * reach + 0.12 * math.cos(yaw),
            eyeHeight(p) - 0.34 + kick * 0.14,
            g.z - math.cos(yaw) * reach - 0.12 * math.sin(yaw)
        )
        spin(nodes.boot, 8 + kick * 16, g.yaw, 8)
    else
        set(nodes.boot, 0, -80, 0)
    end
    if g.feedback.dayJoined and g.dukeRun == run.id then
        if g.dukeHealth and p.vital + p.armor < g.dukeHealth then
            Feedback.sound(g, "thup2", 0.72, 0.75, 3)
        end
        if g.dukeClaimed ~= p.claimed or (run.key and not g.dukeKey) then
            Feedback.sound(g, "bell", 0.48, 1.4, 2)
        end
        if p.lastHurt and p.lastHurt ~= g.tourHurt and t - p.lastHurt < 0.9 then
            g.flavor = (p.respawned == p.lastHurt and "Back at checkpoint" or "Hit!")
                .. "  /  "
                .. p.vital
                .. " hearts"
            g.noteUntil = g.clock + 0.75
        end
        if p.kickAt ~= g.dukeKick and kickAge < 0.32 and p.kickAt >= 0 then
            Feedback.sound(g, "throw", 0.55, 0.85, 2)
        end
    end
    g.tourHurt = p.lastHurt
    g.dukeRun, g.dukeHealth, g.dukeClaimed, g.dukeKey, g.dukeKick =
        run.id, p.vital + p.armor, p.claimed, run.key, p.kickAt
    local tx, tz = destination(run, p)
    local can = soda[phase]
    local full = can and math.floor(run.secrets / can[3]) % 2 == 0
    if can then
        set(nodes.soda, can[1], full and 0 or -80, can[2])
        if not full and g.fullCan == phase then
            Feedback.sound(g, "poof", 0.72, 1.35, 3, can[1], 1.2, can[2], 28)
            Feedback.caption(g, "Extra fizzy!", can[1], 2.1, can[2], "finish", 0.8)
            for j = 1, 12 do
                Feedback.particle(
                    g,
                    "powder",
                    can[1],
                    1.2,
                    can[2],
                    3 * math.sin(j * 2.4),
                    1.8 + j % 4,
                    3 * math.cos(j * 2.4),
                    0.14,
                    0.45
                )
            end
        end
    else
        set(nodes.soda, 0, -80, 0)
    end
    g.fullCan = full and phase or nil
    local console = (
        shootouts[phase]
        or phase == 7
        or phase == 10
        or phase == 11
        or phase == 15
        or phase == 17
    )
    set(nodes.switch, s[3], console and 0 or -80, s[4])
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
        local gunMesh = art[gunArt[g.weapon]]
        local metal = { tex = crewTexture, metallic = -4, roughness = 0.75 }
        eng.scene.set_mesh(World.gun, gunMesh, metal)
        local piece = gunArt[g.weapon] .. "-action"
        art[piece] = art[piece] or eng.asset.load_mesh("missions/day_01/" .. piece .. ".glb")
        eng.scene.set_mesh(nodes.action, art[piece], metal)
        if g.weapon == 5 then
            eng.scene.set_mesh(nodes.secondAction, art[piece], metal)
        end
        local visible = g.weapon == 5 and 1 or 0
        size(nodes.secondAction, visible, visible, visible)
        eng.scene.set_scale(World.gun, 0.40, 0.40, 0.40)
        World.selected = 100 + g.weapon
    end
    local shot = g.dayShot
    local cycle = shot and shot.tool == g.weapon and math.max(0, 1 - (g.clock - shot.at) / 0.16) ^ 2 * motion
        or 0
    if g.weapon == 5 then
        local left = shot and shot.seq % 2 == 1
        set(nodes.action, -0.93, 0, left and 0.20 * cycle or 0)
        set(nodes.secondAction, 0.07, 0, left and 0 or 0.20 * cycle)
    else
        set(nodes.action, 0, 0, 0.16 * cycle)
    end
    spin(nodes.action, 0, 0, g.weapon == 4 and 34 * cycle or 0)
    local gx, gy, gz = eng.scene.get_pos(World.gun)
    set(World.gun, gx, gy + eye - 1.55, gz)
    return eye
end
function M.sprites(g)
    local run = g.room.instances[1]
    if run.burst then
        local b = run.burst
        local age = run.clock - b.at
        if age >= 0 and age < 0.28 then
            local radius = 0.3 + age * 12
            for i = 1, 8 do
                local angle = math.pi * i / 4
                eng.render.draw_sprite(
                    b.x + radius * math.cos(angle),
                    roofHeight(b.z) + 0.3 + age,
                    b.z + radius * math.sin(angle),
                    0.45,
                    0.45,
                    bolts[3]
                )
            end
        end
    end
    local fraction = Hall.clamp(g.clock - (g.sampleAt or g.clock), 0, 0.08)
    for _, b in ipairs(run.hostile) do
        local x, y, z = b.x + fraction * b.vx, b.y + fraction * b.vy, b.z + fraction * b.vz
        local width = b.heavy and 0.72 or 0.46
        eng.render.draw_sprite(x, y, z, width, width, bolts[b.heavy and 4 or 3])
        eng.render.draw_sprite(x - 0.022 * b.vx, y - 0.022 * b.vy, z - 0.022 * b.vz, 0.18, 0.18, bolts[5])
    end
    for _, a in ipairs(run.actors) do
        local charge = a.windup and a.windup > run.clock
        local muzzle = a.firedAt and run.clock - a.firedAt < 0.13
        if a.hp > 0 and (charge or muzzle) and a.ice <= run.clock then
            local diameter = muzzle and 0.63 or a.kind == 4 and 0.51 or 0.34
            local angle = math.rad(a.yaw)
            eng.render.draw_sprite(
                a.x + 0.62 * math.sin(angle) + 0.4 * math.cos(angle),
                roofHeight(a.z) + (a.kind == 2 and 2.05 or 1.2),
                a.z + 0.62 * math.cos(angle) - 0.4 * math.sin(angle),
                diameter,
                diameter,
                bolts[a.kind == 4 and 4 or 1]
            )
        end
    end
    local tx, tz = destination(run, g.room.players[g.id])
    local cue = run.done and "home"
        or shootouts[run.progress] and not passes[run.progress] and remaining(run) > 0 and "aim"
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
    eng.render.draw_sprite(
        tx,
        3.1,
        tz,
        2.25,
        0.60,
        labels[run.seed and (remaining(run) > 0 and "clear" or "use") or cue]
    )
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
        local offset = shot.tool == 5 and (shot.seq % 2 == 1 and -0.24 or 0.16) or 0
        local age = g.clock - shot.at
        local count = ({ 1, 3, 2, 4, 2 })[shot.tool]
        local speed = ({ 95, 38, 46, 77, 72 })[shot.tool]
        local diameter = ({ 0.16, 0.23, 0.32, 0.25, 0.18 })[shot.tool]
        for i = 1, count do
            local d = 0.72 + age * speed + (i - 1) * 0.43
            local size = diameter * (1 - 0.10 * (i - 1))
            eng.render.draw_sprite(
                shot.x + shot.dx * d - shot.dz * offset,
                shot.y + shot.dy * d,
                shot.z + shot.dz * d + shot.dx * offset,
                size,
                size,
                bolts[shot.tool]
            )
        end
    end
end
