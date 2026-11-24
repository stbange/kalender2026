-- Shared by the local game, the room service and the unit tests.
Hall = {}
local H = Hall
H.version = "lantern-1"
H.spawn = { x = 0, z = 17 }
H.limit = 23.6
H.speed = 5.3
H.weapons = {
    { name = "Snowball Pistol", file = "pistol", speed = 30, delay = 0.28, power = 2 },
    { name = "Flurry Fan", file = "fan", speed = 24, delay = 0.68, power = 1, spread = 0.14 },
    { name = "Snow Spinner", file = "spinner", speed = 28, delay = 0.115, power = 1 },
    { name = "Bankshot", file = "bank", speed = 20, delay = 0.47, power = 2, bounce = 3 },
    { name = "Snow Rocket", file = "rocket", speed = 13, delay = 0.95, power = 3, splash = 3.4 },
}
H.visitors = {
    { name = "Scarf Snowman", file = "snowman", speed = 0.65, hp = 3 },
    { name = "Gingerbread Skipper", file = "gingerbread", speed = 0.88, hp = 2 },
    { name = "Penguin Skater", file = "penguin", speed = 1.05, hp = 2 },
    { name = "Clockwork Guard", file = "guard", speed = 0.74, hp = 3 },
    { name = "Frost Wisp", file = "wisp", speed = 0.70, hp = 1 },
}
H.targets = { { -5, 1.8, -14 }, { -2.6, 2.45, -16 }, { 0, 1.85, -15 }, { 2.6, 2.45, -16 }, { 5, 1.8, -14 } }
local nests = { { -7, 6 }, { 6, 7 }, { -9, -6 }, { 8, -5 }, { 0, -10 } }
function H.clamp(n, low, high)
    return math.max(low, math.min(high, n))
end
function H.due(now)
    -- 1 December 2026 at 00:00 Europe/Warsaw = 30 November at 23:00 UTC.
    return H.clamp(1 + math.floor((now - 1796079600) / 86400), 0, 24)
end
function H.door(day)
    local wing = math.floor((day - 1) / 6)
    local along = ((day - 1) % 6 - 2.5) * 7
    if wing == 0 then
        return -23, -along, 1, 0
    end
    if wing == 1 then
        return along, -23, 0, 1
    end
    if wing == 2 then
        return 23, along, -1, 0
    end
    return -along, 23, 0, -1
end
function H.near_door(x, z, range)
    for day = 1, 24 do
        local dx, dz = H.door(day)
        if (x - dx) ^ 2 + (z - dz) ^ 2 < range ^ 2 then
            return day
        end
    end
end
function H.move(x, z, dx, dz, space)
    local limit = space == 0 and H.limit or 7.5
    x, z = H.clamp(x + dx, -limit, limit), H.clamp(z + dz, -limit, limit)
    if space == 0 and x * x + z * z < 2.25 ^ 2 then
        local length = math.sqrt(x * x + z * z)
        if length < 0.001 then
            return 0, 2.25
        end
        x, z = x * 2.25 / length, z * 2.25 / length
    end
    return x, z
end
function H.wave(r)
    r.wave = r.wave + 1
    r.mobs = {}
    for kind, nest in ipairs(nests) do
        r.mobs[kind] = {
            kind = kind,
            x = nest[1],
            y = 1,
            z = nest[2],
            hp = H.visitors[kind].hp,
            wake = r.time + (kind - 1) * 1.7,
            angle = kind,
            heading = 0,
        }
    end
end
function H.new(days)
    local r = {
        players = {},
        shots = {},
        mobs = {},
        targets = { 0, 0, 0, 0, 0 },
        hours = days or 0,
        time = 0,
        hits = 0,
        wave = 0,
        clears = 0,
        serial = 0,
        instances = {},
        next_run = 0,
    }
    H.wave(r)
    return r
end
function H.join(r, id)
    r.players[id] = {
        x = H.spawn.x + (id - 1) * 0.45,
        z = H.spawn.z,
        yaw = 0,
        space = 0,
        slow = 0,
        cool = 0,
        seq = 0,
        weapon = 1,
        awards = 0,
        notice = "",
        last_pose = r.time,
    }
    return r.players[id]
end
function H.leave_space(r, p, returned)
    local run = r.instances[p.space]
    if not run then
        return
    end
    if run.pack.exit then
        run.pack.exit(run, p, returned)
    end
    if returned and not run.returned then
        H.wave(r)
        run.returned = true
    end
    run.members = run.members - 1
    if run.members == 0 then
        r.instances[p.space] = nil
    end
end
function H.leave(r, id)
    local p = r.players[id]
    if p then
        H.leave_space(r, p, false)
        r.players[id] = nil
    end
end
function H.enter(r, p, day, packs)
    if p.space ~= 0 or H.near_door(p.x, p.z, 2.1) ~= day then
        return false
    end
    if day > r.hours then
        p.notice = "Opens on December " .. day
        return false
    end
    if not packs[day] then
        p.notice = "Mission in preparation"
        return false
    end
    local run = r.instances[day]
    if not run then
        r.next_run = r.next_run + 1
        run = { id = r.next_run, members = 0, progress = 0, returned = false, pack = packs[day] }
        r.instances[day] = run
        if packs[day].start then
            packs[day].start(run)
        end
    end
    run.members = run.members + 1
    p.space, p.x, p.z, p.yaw, p.slow, p.notice = day, 0, 5, 0, 0, ""
    if run.pack.enter then
        run.pack.enter(run, p)
    end
    return true
end
function H.back(r, p)
    if p.space == 0 then
        return false
    end
    local x, z, ix, iz = H.door(p.space)
    H.leave_space(r, p, true)
    p.space, p.x, p.z, p.yaw, p.notice = 0, x + ix * 2.5, z + iz * 2.5, math.deg(math.atan2(-ix, -iz)), ""
    return true
end
function H.objective(r, p, packs)
    local run = r.instances[p.space]
    local pack = packs[p.space]
    if not run or not pack or run.done then
        return false
    end
    if pack.act(run, p) then
        run.done = true
        local mark = 2 ^ (p.space - 1)
        for _, friend in pairs(r.players) do
            if friend.space == p.space and math.floor(friend.awards / mark) % 2 == 0 then
                friend.awards = friend.awards + mark
            end
        end
    end
    return true
end
function H.practice(r)
    for _, m in pairs(r.mobs) do
        if m.hp > 0 then
            return false
        end
    end
    H.wave(r)
    return true
end
local function damage(r, m, amount)
    if m.hp <= 0 or m.wake > r.time then
        return
    end
    m.hp = math.max(0, m.hp - amount)
    if m.hp == 0 then
        r.clears = r.clears + 1
    end
end
local function ring(r, i)
    if r.targets[i] <= r.time then
        r.targets[i] = r.time + 1.2
        r.hits = r.hits + 1
    end
end
local function burst(r, s)
    for _, m in pairs(r.mobs) do
        if (m.x - s.x) ^ 2 + (m.y - s.y) ^ 2 + (m.z - s.z) ^ 2 < s.splash ^ 2 then
            damage(r, m, s.power)
        end
    end
    for i, t in ipairs(H.targets) do
        if (t[1] - s.x) ^ 2 + (t[2] - s.y) ^ 2 + (t[3] - s.z) ^ 2 < s.splash ^ 2 then
            ring(r, i)
        end
    end
end
function H.fire(r, p, seq, weapon, dx, dy, dz, ox, oy, oz)
    local w = H.weapons[weapon]
    local length = math.sqrt(dx * dx + dy * dy + dz * dz)
    if not w or p.space ~= 0 or seq <= p.seq or p.cool > r.time or length < 0.01 or #r.shots > 110 then
        return false
    end
    p.seq, p.cool, p.weapon = seq, r.time + w.delay, weapon
    dx, dy, dz = dx / length, dy / length, dz / length
    local spread = w.spread and { -w.spread, 0, w.spread } or { 0 }
    for _, angle in ipairs(spread) do
        r.serial = r.serial + 1
        local cs, sn = math.cos(angle), math.sin(angle)
        r.shots[#r.shots + 1] = {
            id = r.serial,
            kind = weapon,
            owner = p.id,
            x = p.x + (ox or 0),
            y = 1.55 + (oy or 0),
            z = p.z + (oz or 0),
            vx = (dx * cs + dz * sn) * w.speed,
            vy = dy * w.speed,
            vz = (dz * cs - dx * sn) * w.speed,
            power = w.power,
            bounces = w.bounce or 0,
            splash = w.splash,
            life = 3,
        }
    end
    return true
end
local function projectile(r, s, dt)
    s.life = s.life - dt
    s.x, s.y, s.z = s.x + s.vx * dt, s.y + s.vy * dt, s.z + s.vz * dt
    if s.kind == 4 then
        s.vy = s.vy - 4 * dt
    end
    local impact = false
    for _, m in pairs(r.mobs) do
        if
            m.hp > 0
            and m.wake <= r.time
            and (m.x - s.x) ^ 2 + (m.y - s.y) ^ 2 + (m.z - s.z) ^ 2 < 0.82 ^ 2
        then
            if not s.splash then
                damage(r, m, s.power)
            end
            impact = true
            break
        end
    end
    if not impact then
        for i, t in ipairs(H.targets) do
            if
                r.targets[i] <= r.time and (t[1] - s.x) ^ 2 + (t[2] - s.y) ^ 2 + (t[3] - s.z) ^ 2 < 0.8 ^ 2
            then
                ring(r, i)
                impact = true
                break
            end
        end
    end
    local limit = 23.7
    if not impact and (math.abs(s.x) > limit or math.abs(s.z) > limit or s.y < 0.18 or s.y > 9) then
        if s.bounces > 0 then
            if math.abs(s.x) > limit then
                s.vx = -s.vx
                s.x = H.clamp(s.x, -limit, limit)
            end
            if math.abs(s.z) > limit then
                s.vz = -s.vz
                s.z = H.clamp(s.z, -limit, limit)
            end
            if s.y < 0.18 or s.y > 9 then
                s.vy = -s.vy
                s.y = H.clamp(s.y, 0.18, 9)
            end
            s.bounces = s.bounces - 1
        else
            impact = true
        end
    end
    if impact and s.splash then
        burst(r, s)
    end
    return impact or s.life <= 0
end
local function visitors(r, dt)
    for i, m in pairs(r.mobs) do
        if m.hp > 0 and m.wake <= r.time then
            local nearest, best = nil, 1e9
            for _, p in pairs(r.players) do
                local d = (p.x - m.x) ^ 2 + (p.z - m.z) ^ 2
                if p.space == 0 and d < best then
                    nearest, best = p, d
                end
            end
            if nearest then
                local heading = math.atan2(nearest.x - m.x, nearest.z - m.z)
                local speed = H.visitors[i].speed
                if i == 2 then
                    speed = speed * (0.55 + 0.45 * math.cos(r.time * 3) ^ 2)
                elseif i == 3 then
                    heading = heading + 0.55 * math.sin(r.time * 1.5)
                elseif i == 4 then
                    heading = math.floor(heading / (math.pi / 4) + 0.5) * math.pi / 4
                elseif i == 5 then
                    heading = heading + 0.7 * math.cos(r.time)
                end
                m.x, m.z = H.move(m.x, m.z, math.sin(heading) * speed * dt, math.cos(heading) * speed * dt, 0)
                m.heading = math.deg(heading)
                m.y = i == 5 and 1.4 + 0.3 * math.sin(r.time * 2) or 1
                for _, p in pairs(r.players) do
                    if p.space == 0 and (p.x - m.x) ^ 2 + (p.z - m.z) ^ 2 < 1.25 ^ 2 then
                        p.slow = r.time + 1.3
                    end
                end
            end
        end
    end
end
function H.step(r, elapsed)
    local dt = H.clamp(elapsed, 0, 0.25)
    r.time = r.time + dt
    visitors(r, dt)
    while dt > 0.000001 do
        local delta = math.min(dt, 0.015)
        for i = #r.shots, 1, -1 do
            if projectile(r, r.shots[i], delta) then
                table.remove(r.shots, i)
            end
        end
        dt = dt - delta
    end
end
function H.walk_speed(r, p)
    return H.speed * (p.slow > r.time and 0.56 or 1)
end
