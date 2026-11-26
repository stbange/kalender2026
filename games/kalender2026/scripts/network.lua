-- Hall gameplay payloads carried inside engine WebSocket channel frames.
Net = {}
function Net.words(line)
    local out = {}
    for s in string.gmatch(line, "%S+") do
        out[#out + 1] = s
    end
    return out
end
local function number(s, low, high)
    local n = tonumber(s)
    if n and n >= low and n <= high then
        return n
    end
end
function Net.command(r, id, line, packs)
    local p = r.players[id]
    if not p or #line > 255 then
        return
    end
    local w = Net.words(line)
    if w[1] == "P" then
        local bound = p.space == 0 and 24 or 512
        local x, z, yaw = number(w[2], -bound, bound), number(w[3], -bound, bound), number(w[4], -360, 360)
        if not x or not z or not yaw then
            return
        end
        local dx, dz = x - p.x, z - p.z
        local distance = math.sqrt(dx ^ 2 + dz ^ 2)
        local budget = Hall.walk_speed(r, p) * Hall.clamp(r.time - p.last_pose, 0, 0.5) + 0.10
        local ratio = distance > budget and budget / distance or 1
        p.x, p.z = Hall.move(p.x, p.z, dx * ratio, dz * ratio, p.space, r.instances[p.space], p)
        p.yaw, p.last_pose = yaw, r.time
    elseif w[1] == "F" then
        local seq, k = number(w[2], 1, 1000000000), number(w[3], 1, 5)
        local dx, dy, dz = number(w[4], -1, 1), number(w[5], -1, 1), number(w[6], -1, 1)
        local ox, oy, oz = number(w[7] or 0, -1, 1), number(w[8] or 0, -1.5, 1), number(w[9] or 0, -1, 1)
        if seq and k and dx and dy and dz and ox and oy and oz then
            local run = r.instances[p.space]
            if run and run.pack.fire then
                if not run.done then
                    run.pack.fire(run, p, seq, k, dx, dy, dz, r, ox, oy, oz)
                end
            else
                Hall.fire(r, p, seq, k, dx, dy, dz, ox, oy, oz)
            end
        end
    elseif w[1] == "K" then
        local run = r.instances[p.space]
        local seq, yaw = number(w[2], 1, 1000000000), number(w[3], -360, 360)
        if seq and yaw and run and not run.done and run.pack.kick then
            run.pack.kick(run, p, seq, yaw)
        end
    elseif w[1] == "ENTER" then
        local day = number(w[2], 1, 24)
        if day and day == math.floor(day) then
            Hall.enter(r, p, day, packs)
        end
    elseif w[1] == "BACK" then
        local run = r.instances[p.space]
        if run and (p.z > 5.9 or (run.pack.canReturn and run.pack.canReturn(run, p))) then
            Hall.back(r, p)
        end
    elseif w[1] == "USE" then
        Hall.objective(r, p, packs)
    elseif w[1] == "BELL" and p.space == 0 then
        Hall.practice(r)
    end
end
function Net.snapshot(r)
    local rows = { string.format("S %d %.3f %d %d %d", r.hours, r.time, r.hits, r.clears, r.wave) }
    rows[#rows + 1] = string.format("I %d", r.eventId)
    for _, e in ipairs(r.events) do
        rows[#rows + 1] = string.format(
            "E %d %.3f %d %d %d %d %d %d %d %.3f %.3f %.3f %.3f",
            e.id,
            e.time,
            e.code,
            e.owner,
            e.seat,
            e.seq,
            e.ball,
            e.weapon,
            e.target,
            e.x,
            e.y,
            e.z,
            e.value
        )
    end
    for id, p in pairs(r.players) do
        rows[#rows + 1] = string.format("O %d %d", id, p.seat)
        local run = r.instances[p.space]
        rows[#rows + 1] = string.format(
            "P %d %.3f %.3f %.2f %d %.3f %d %d %d %d",
            id,
            p.x,
            p.z,
            p.yaw,
            p.space,
            p.slow,
            p.weapon,
            p.awards,
            run and run.progress or 0,
            run and run.done and 1 or 0
        )
    end
    for day, run in pairs(r.instances) do
        if run.pack.snapshot then
            run.pack.snapshot(rows, run, r.players, day)
        end
    end
    for i, m in pairs(r.mobs) do
        rows[#rows + 1] =
            string.format("M %d %.3f %.3f %.3f %d %.3f %.1f", i, m.x, m.y, m.z, m.hp, m.wake, m.heading)
    end
    for _, b in ipairs(r.shots) do
        rows[#rows + 1] = string.format("B %d %d %.3f %.3f %.3f", b.id, b.kind, b.x, b.y, b.z)
    end
    for i, reset in ipairs(r.targets) do
        rows[#rows + 1] = string.format("T %d %.3f", i, reset)
    end
    return table.concat(rows, "\n")
end
function Net.read(s)
    local r = { players = {}, mobs = {}, shots = {}, targets = {}, instances = {}, events = {}, seats = {} }
    for line in s:gmatch("[^\n]+") do
        local w = Net.words(line)
        for i = 2, #w do
            w[i] = tonumber(w[i])
            if not w[i] or math.abs(w[i]) == math.huge or w[i] ~= w[i] then
                return nil
            end
        end
        if w[1] == "S" and #w == 6 then
            r.hours, r.time, r.hits, r.clears, r.wave = w[2], w[3], w[4], w[5], w[6]
        elseif w[1] == "I" and #w == 2 then
            r.eventId = w[2]
        elseif w[1] == "O" and #w == 3 then
            r.seats[w[2]] = w[3]
        elseif w[1] == "E" and #w == 14 then
            local prev = r.events[#r.events]
            local code, target = w[4], w[10]
            if
                #r.events >= Hall.history
                or w[2] ~= math.floor(w[2])
                or (prev and w[2] <= prev.id)
                or code ~= math.floor(code)
                or code < 1
                or code > 9
                or w[5] < 0
                or w[5] > 8
                or w[9] < 0
                or w[9] > 5
                or target ~= math.floor(target)
                or (code >= 2 and code <= 4 and (target < 1 or target > 5))
            then
                return nil
            end
            r.events[#r.events + 1] = {
                id = w[2],
                time = w[3],
                code = w[4],
                owner = w[5],
                seat = w[6],
                seq = w[7],
                ball = w[8],
                weapon = w[9],
                target = w[10],
                x = w[11],
                y = w[12],
                z = w[13],
                value = w[14],
            }
        elseif w[1] == "P" and #w == 11 then
            r.players[w[2]] = {
                id = w[2],
                x = w[3],
                z = w[4],
                yaw = w[5],
                space = w[6],
                slow = w[7],
                weapon = w[8],
                awards = w[9],
            }
            if w[6] > 0 then
                r.instances[w[6]] =
                    { progress = w[10], done = w[11] == 1, pack = MissionPacks and MissionPacks[w[6]] }
            end
        elseif w[1] == "D" and MissionPacks and MissionPacks[w[2]] and MissionPacks[w[2]].read then
            if not MissionPacks[w[2]].read(r, w) then
                return nil
            end
        elseif w[1] == "M" and #w == 8 then
            r.mobs[w[2]] =
                { kind = w[2], x = w[3], y = w[4], z = w[5], hp = w[6], wake = w[7], heading = w[8] }
        elseif w[1] == "B" and #w == 6 then
            r.shots[#r.shots + 1] = { id = w[2], kind = w[3], x = w[4], y = w[5], z = w[6] }
        elseif w[1] == "T" and #w == 3 then
            r.targets[w[2]] = w[3]
        else
            return nil
        end
    end
    if
        r.time
        and r.eventId
        and #r.targets == 5
        and (#r.events == 0 or r.events[#r.events].id <= r.eventId)
    then
        for id, p in pairs(r.players) do
            local pack = MissionPacks and MissionPacks[p.space]
            if
                not r.seats[id]
                or (pack and pack.validSnapshot and not pack.validSnapshot(r.instances[p.space], p))
            then
                return nil
            end
            p.seat = r.seats[id]
        end
        return r
    end
end
-- Each service connection has a stable slot for its lifetime. A room starts on its first join.
Service = { rooms = {}, clients = {} }
function Service.disconnect(slot)
    local c = Service.clients[slot]
    if c then
        local r = Service.rooms[c.room]
        Hall.leave(r, c.id)
        if not next(r.players) then
            Service.rooms[c.room] = nil
        end
        Service.clients[slot] = nil
    end
end
function Service.receive(slot, line, utc)
    local c = Service.clients[slot]
    if c then
        if line == "BYE" then
            Service.disconnect(slot)
        else
            Net.command(Service.rooms[c.room], c.id, line, MissionPacks)
        end
        return ""
    end
    local verb, version, room = line:match("^(%u+%d*) ([%w_%-%.]+) ([%w_%-]+)$")
    if verb ~= "HELLO3" or version ~= Hall.version or #room > 32 then
        return "ERROR Refresh the game and check the room code"
    end
    local r = Service.rooms[room]
    if not r then
        r = Hall.new(Hall.due(utc))
        Service.rooms[room] = r
    end
    for id = 1, 8 do
        if not r.players[id] then
            Hall.join(r, id)
            Service.clients[slot] = { room = room, id = id }
            return "WELCOME " .. id
        end
    end
    return "ERROR Room full"
end
function Service.step(dt, utc)
    for _, r in pairs(Service.rooms) do
        r.hours = Hall.due(utc)
        Hall.step(r, dt)
    end
end
function Service.snapshot(slot)
    local c = Service.clients[slot]
    return c and Net.snapshot(Service.rooms[c.room]) or ""
end
