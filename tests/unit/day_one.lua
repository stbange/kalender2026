-- Exercise the production pack, room commands, snapshot codec and client scene together.
local old = MissionPacks
MissionPacks = {}
dofile("games/kalender2026/missions/day_01.lua")
local m = MissionPacks[1]
local r = Hall.new(1)
local function join(id)
    local p = Hall.join(r, id)
    p.x, p.z = Hall.door(1)
    Net.command(r, id, "ENTER 1", MissionPacks)
    return p
end
local p = join(1)
local run = r.instances[1]
assert(not Net.read((Net.snapshot(r):gsub("D 1 [^\n]+", ""))))
local spectator = Hall.join(r, 8)
local crew = join(2)
local g = game.state
g.space, g.room, g.id, g.weapon, g.x, g.z = 1, r, 1, 1, p.x, p.z
World.prepare(1)
m.build(World.pockets[1], World.pedestals[1])
local function sync()
    local copy = assert(Net.read(Net.snapshot(r)))
    assert(copy.instances[1].progress == run.progress)
    assert(#copy.instances[1].actors == #run.actors)
    assert(copy.players[1].vital == p.vital)
    g.x, g.z, g.weapon = p.x, p.z, m.unlocked(run)
    World.update(g, 0.016)
    m.presentShot(g, { dx = 0, dy = 0, dz = -1, ox = 0, oy = 0, oz = 0 })
    World.sprites(g)
    assert(#m.hint(run, p) > 8)
    assert(#host_hud() > 0)
    draw()
end
local function pos(x, z)
    p.x, p.z = x, z
end
local function use(player)
    Net.command(r, (player or p).id, "USE", MissionPacks)
end
local function fire(k, x, z, player)
    player = player or p
    local dx, dz = x - player.x, z - player.z
    local n = math.sqrt(dx * dx + dz * dz)
    r.time = r.time + 1
    Net.command(
        r,
        player.id,
        string.format("F %d %d %.6f 0 %.6f", player.seq + 1, k, dx / n, dz / n),
        MissionPacks
    )
end
local function tick(n)
    for i = 1, n do
        Hall.step(r, 0.125)
    end
end
local function find(kind)
    for _, a in ipairs(run.actors) do
        if a.kind == kind and a.hp > 0 then
            return a
        end
    end
end
local function clearRoom(phase)
    local waves = phase == 16 and 4 or 3
    for wave = 1, waves do
        assert(run.wave == wave)
        local stop = m.stops[phase]
        pos(stop[3], stop[4])
        use()
        assert(run.progress == phase, "occupied exit must stay locked")
        for _, a in ipairs(run.actors) do
            pos(a.x, a.z + 0.25)
            for shot = 1, 3 do
                if a.hp > 0 then
                    fire(1, a.x, a.z)
                end
            end
            assert(
                a.hp == 0,
                string.format("stage %d wave %d actor %d at %.2f / %.2f", phase, wave, a.id, a.x, a.z)
            )
        end
        if wave < waves then
            pos(stop[3], stop[4])
            use()
            assert(run.progress == phase)
            tick(9)
            local remote = assert(Net.read(Net.snapshot(r))).instances[1]
            assert(remote.wave == wave + 1 and #remote.actors == #run.actors)
        end
    end
end
-- Observe actual shoulder and hip transforms on the two opening ushers.
do
    local joints, rotations = {}, {}
    local parent, rotate = eng.scene.set_parent, eng.scene.set_rot_deg
    eng.scene.set_parent = function(id, root)
        joints[#joints + 1] = id
        parent(id, root)
    end
    eng.scene.set_rot_deg = function(id, x, y, z)
        rotations[id] = x
        rotate(id, x, y, z)
    end
    local actor = run.actors[1]
    local motion = g.feedback.prefs[1]
    g.feedback.prefs[1] = 100
    actor.stride = 0.36
    m.render(g, 0.016)
    assert(#joints == 8 and rotations[joints[1]] * rotations[joints[2]] < 0)
    assert(rotations[joints[1]] * rotations[joints[3]] < 0)
    actor.ice = run.clock + 1
    m.render(g, 0.016)
    assert(rotations[joints[1]] == 0 and rotations[joints[4]] == 0)
    actor.ice, g.feedback.prefs[1] = 0, 0
    m.render(g, 0.016)
    assert(rotations[joints[1]] == 0)
    g.feedback.prefs[1] = motion
    eng.scene.set_parent, eng.scene.set_rot_deg = parent, rotate
end

-- Solid room walls guide players to the central opening.
local x, z = m.move(13, -9, 2, 0, run, p)
assert(x == 13.4)
x, z = m.move(0, 5, 0, 1, run, p)
assert(z == 6)
pos(-11, -27)
use()
assert(m.hint(run, p):find("ORDER"))
for phase = 1, #m.stops do
    assert(run.progress == phase, "phase " .. phase .. " observed " .. run.progress)
    local s = m.stops[phase]
    sync()
    if phase == 2 or phase == 6 or phase == 9 or phase == 16 then
        if phase == 2 then
            local a = find(1)
            pos(a.x, a.z + 3)
            local hp = a.hp
            fire(1, a.x, a.z)
            assert(a.hp == hp - 1 and a.impact.owner == p.id and a.impact.result == 1)
            local snap = assert(Net.read(Net.snapshot(r)))
            for _, other in ipairs(snap.instances[1].actors) do
                if other.id == a.id then
                    assert(other.impact.seq == p.seq and other.impact.result == 1)
                end
            end
            sync()
            assert(g.feedback.mark == "ticks")
            fire(1, a.x, a.z)
            sync()
            assert(a.hp == 0 and a.impact.result == 2 and g.feedback.mark == "finish")
            local nearby = find(2)
            nearby.x, nearby.z = -5, -23
            pos(-4, -20)
            fire(1, -4, -22)
            assert(nearby.hp == 0 and math.floor(run.secrets / 4) % 2 == 1)
            assert(assert(Net.read(Net.snapshot(r))).instances[1].secrets == run.secrets)
            sync()
            assert(m.move(15, -23, 1, 0, run, p) == 16)
            assert(m.move(28, -23, 3, 0, run, p) == 28.55)
        end
        clearRoom(phase)
    end
    pos(s[3], s[4] + 1)
    if phase == 3 or phase == 19 then
        local cx, cz = m.cart(run)
        local x = phase == 3 and 0 or cx
        pos(x, cz + 3)
        fire(1, x + 8, cz + 3)
        assert(run.progress == phase)
        fire(1, x, cz)
        assert(run.progress == phase + 1)
        if phase == 19 then
            assert(not find(6))
        end
    elseif phase == 4 then
        local ordinary = find(1)
        pos(ordinary.x, ordinary.z + 2)
        fire(2, ordinary.x, ordinary.z)
        assert(ordinary.impact.result == 4 and ordinary.hp == 2)
        fire(1, ordinary.x, ordinary.z)
        assert(ordinary.impact.result == 2 and ordinary.hp == 0)
        local a = find(3)
        for i = 1, 4 do
            pos(a.x, a.z + 1.5)
            fire(1, a.x, a.z)
            fire(1, a.x, a.z)
        end
        assert(a.mascot and a.hp > 0)
        pos(a.x + 1.5, a.z)
        fire(2, a.x, a.z)
        use()
        tick(32)
        assert(run.progress == 5)
    elseif phase == 8 then
        local late = join(3)
        assert(late.z == -98)
        local a = find(4)
        pos(a.x, a.z + 3)
        fire(1, a.x, a.z)
        assert(a.hp == 5 and a.impact.result == 3)
        sync()
        fire(3, a.x, a.z)
    elseif phase == 12 then
        use()
        assert(run.progress == 12)
        pos(0, -161)
        tick(245)
        pos(0, -161)
        use()
    elseif phase == 13 then
        assert(join(4).z == -169)
        crew.z = -140
        use(crew)
        assert(crew.z == -169)
        local a = find(5)
        pos(a.x, a.z + 1)
        fire(4, a.x, a.z)
        tick(1)
    elseif phase == 15 then
        Hall.leave(r, 1)
        p = join(1)
        pos(-9, -197)
        use()
        assert(p.tiny)
        pos(s[3], s[4])
        use()
        assert(not p.tiny)
    elseif phase == 18 then
        pos(11, -261)
        use()
        assert(m.hint(run, p):find("FAMILY"))
        local boxX, boxZ = m.move(13, -261, 5, 0, run, p)
        assert(boxX == 18 and boxZ == -261)
        assert(m.move(boxX, boxZ, -6, 0, run, p) == 12)
        for drive = 1, 3 do
            assert(run.drive == drive)
            for _, a in ipairs(run.actors) do
                if a.kind == 7 and a.hp > 0 then
                    pos(a.x, a.z + 0.4)
                    fire(5, a.x, a.z)
                    fire(5, a.x, a.z)
                end
            end
            local x, z = m.destination(run)
            pos(x, z + 0.8)
            for i = 1, 320 do
                if run.drive ~= drive or run.progress ~= 18 then
                    break
                end
                tick(1)
                if p.z > -255 then
                    pos(x, z + 0.8)
                end
            end
        end
    else
        use()
    end
end
use(crew)
assert(m.hint(run, p):find("Ornament earned"))
assert(run.done and p.awards == 1 and crew.awards == 1 and spectator.awards == 0)
pos(0, -300)
Net.command(r, 1, "BACK", MissionPacks)
assert(p.space == 0)
assert(not m.read({ instances = {} }, { "D", 1, 0 }))
-- Exercise the room authority and a remote client's view of the same fight.
do
    local room = Hall.new(1)
    local function player(id)
        local member = Hall.join(room, id)
        member.x, member.z = Hall.door(1)
        Hall.enter(room, member, 1, MissionPacks)
        return member
    end
    local hero, friend = player(1), player(2)
    local battle = room.instances[1]
    local guard = battle.actors[1]
    battle.actors = { guard }
    battle.progress = 4
    hero.x, hero.z, hero.immunity = 0, -52, 0
    friend.x, friend.z = 9, -70
    guard.x, guard.z, guard.nextAttack = 0, -60, 0
    local function step(n)
        for i = 1, n do
            Hall.step(room, 0.05)
        end
    end
    local function remote()
        return assert(Net.read(Net.snapshot(room)))
    end
    local function kick(yaw)
        Net.command(room, hero.id, string.format("K %d %.2f", hero.seq + 1, yaw), MissionPacks)
    end
    step(1)
    assert(guard.windup and remote().instances[1].actors[1].windup)
    hero.x = 4
    step(10)
    assert(#battle.hostile == 1 and #remote().instances[1].hostile == 1)
    step(16)
    assert(hero.vital == 5, "Sidestepping after the tell dodges the locked shot")
    hero.x, hero.armor, guard.nextAttack = 0, 1, 0
    step(29)
    assert(hero.vital == 5 and hero.armor == 0, "Armor takes the next bolt")
    guard.nextAttack, hero.immunity = 0, 0
    step(29)
    assert(hero.vital == 4)
    guard.nextAttack = 0
    step(1)
    assert(guard.windup)
    Net.command(room, 1, "F 1 2 0 0 -1", MissionPacks)
    step(1)
    assert(guard.ice > battle.clock and not guard.windup)
    hero.z = guard.z + 1.8
    kick(180)
    assert(guard.hp == 2)
    kick(0)
    assert(guard.hp == 2 and hero.seq == 2, "Kick cooldown includes misses")
    step(10)
    kick(0)
    assert(guard.hp == 0 and guard.impact.result == 2 and remote().players[1].kickAt > 0)
    local function supply(p, x, z)
        p.x, p.z = x, z
        step(1)
    end
    supply(friend, -6, -16)
    assert(friend.claimed == 0, "Full health leaves a medkit on the floor")
    friend.vital = 1
    supply(friend, -6, -16)
    assert(friend.vital == 4 and friend.claimed == 1)
    supply(hero, -6, -16)
    assert(hero.vital == 5 and hero.claimed == 1)
    supply(hero, 18, -21)
    assert(hero.armor == 2 and remote().players[1].claimed == 3)
    supply(hero, 18, -21)
    assert(hero.armor == 2)
    battle.progress = 6
    guard.hp = 2
    supply(hero, -18, -76)
    assert(remote().instances[1].key)
    friend.x, friend.z = -10, -80
    m.act(battle, friend)
    assert(battle.progress == 7 and guard.hp == 2 and not battle.key)
    battle.progress = 9
    hero.x, hero.z = -21, -125
    guard.x, guard.z, guard.ice, guard.hp = -21, -131, 0, 2
    guard.nextAttack = 0
    step(1)
    assert(not guard.windup)
    local _, stopped = m.move(hero.x, hero.z, 0, -5, battle, hero)
    assert(stopped == hero.z, "Cannot walk through freight cover")
    room.time = room.time + 1
    Net.command(room, 1, "F 5 3 0 0 -1", MissionPacks)
    assert(guard.hp == 2)
    -- The shot lands three metres to the side of the guard. A second guard
    -- within the blast radius on the far side of the crate is sheltered.
    hero.x, hero.z = -21, -119
    guard.x, guard.z = -18, -126
    local shelter =
        { id = 99, kind = 1, x = -21, z = -129.7, hp = 2, ice = 0, small = 0, stride = 0, yaw = 0 }
    battle.actors[2] = shelter
    room.time = room.time + 1
    Net.command(room, 1, "F 6 3 0 -0.22143 -1", MissionPacks)
    assert(guard.hp == 0 and shelter.hp == 2 and remote().instances[1].burst)
    local copy = remote()
    assert(Hall.walk_speed(copy, copy.players[1]) == 8.25 and Hall.walk_speed(room, hero) == 8.25)
end

do
    local room = Hall.new(1)
    local function enter(id)
        local p = Hall.join(room, id)
        p.x, p.z = Hall.door(1)
        Hall.enter(room, p, 1, MissionPacks)
        return p
    end
    local p = enter(1)
    local run = room.instances[1]
    Hall.objective(room, p, MissionPacks)
    assert(run.seed and p.x == 100 and run.progress == 1)
    local buddy = enter(2)
    assert(buddy.x == p.x and buddy.z == p.z)
    local function render()
        local copy = assert(Net.read(Net.snapshot(room)))
        local live = copy.instances[1]
        assert(live.seed == run.seed and #live.actors == #run.actors and #live.hostile == #run.hostile)
        g.room, g.id, g.space, g.x, g.z = copy, 1, 1, p.x, p.z
        m.render(g, 0.016)
        m.sprites(g)
        assert(
            m.hint(live, copy.players[1])
                :find(({ "Los Angeles", "Luna", "Bettinghausen" })[live.layout.city], 1, true)
        )
        return live
    end
    local originalSeed = run.seed
    local originalGate = run.layout.rooms[1].gate
    local layouts = {}
    for i = 1, 20 do
        run.seed = i * 7919
        m.enter(run, buddy)
        local c = run.layout.rooms[1]
        layouts[c.gate .. ":" .. c.back .. ":" .. c.l] = true
        local x, z = m.move(c.gate, c.back + 1.6, 0, -9, run, buddy)
        assert(z > c.back)
        local b
        for _, block in ipairs(run.layout.blocks) do
            if block.style == "cover" then
                b = block
                break
            end
        end
        x, z = m.move(b.x, b.z + b.d / 2 + 0.7, 0, -2, run, buddy)
        assert(z > b.z + b.d / 2)
    end
    local count = 0
    for _ in pairs(layouts) do
        count = count + 1
    end
    assert(count > 15)
    run.seed = originalSeed
    m.enter(run, buddy)
    assert(run.layout.rooms[1].gate == originalGate)
    for sector = 1, 9 do
        assert(run.progress == sector)
        local map = run.layout
        local c = map.rooms[(sector - 1) % 3 + 1]
        local live = render()
        assert(live.layout.rooms[(sector - 1) % 3 + 1].back == c.back)
        p.x, p.z = map.x, c.back + 8
        local byKind = {}
        for _, a in ipairs(run.actors) do
            a.x, a.z = map.x, c.back + 2
            a.nextAttack = 0
            byKind[a.kind] = a
        end
        run.actors = { byKind[1], byKind[2], byKind[4] }
        p.vital, p.armor = 5, 0
        for i = 1, 21 do
            Hall.step(room, 0.05)
        end
        assert(byKind[1].firedAt and byKind[2].firedAt and byKind[4].firedAt)
        local heavy = false
        for _, b in ipairs(render().hostile) do
            heavy = heavy or b.heavy
        end
        assert(heavy)
        for i = 1, 12 do
            Hall.step(room, 0.05)
        end
        render()
        -- Use the actual shot resolver and verify that the exit cannot skip a live defender.
        p.x, p.z = c.gate, c.back + 1.7
        Hall.objective(room, p, MissionPacks)
        assert(run.progress == sector and not run.done)
        for _, a in ipairs(run.actors) do
            for i = 1, 3 do
                if a.hp > 0 then
                    p.x, p.z = a.x, a.z + 1
                    room.time = room.time + 1
                    m.fire(run, p, p.seq + 1, 3, 0, 0, -1, room)
                end
            end
            assert(a.hp == 0)
        end
        Hall.step(room, 0.18)
        if sector == 1 then
            local rotate, motion = eng.scene.set_rot_deg, g.feedback.prefs[1]
            local poses = {}
            g.feedback.prefs[1] = 100
            byKind[1].yaw, byKind[2].yaw, byKind[4].yaw = 43, 113, 67
            eng.scene.set_rot_deg = function(node, pitch, yaw, roll)
                if yaw == 43 and pitch > 10 then
                    poses.fall = true
                end
                if yaw > 150 and yaw < 172 and roll > 20 then
                    poses.spin = true
                end
                if yaw == 67 and roll > 3 then
                    poses.topple = true
                end
                rotate(node, pitch, yaw, roll)
            end
            render()
            eng.scene.set_rot_deg, g.feedback.prefs[1] = rotate, motion
            assert(
                poses.fall and poses.spin and poses.topple,
                "Distinct defeat poses must reach the renderer"
            )
        else
            render()
        end
        if sector == 5 then
            p.vital, p.armor, p.immunity = 1, 0, 0
            run.hostile = {
                {
                    x = p.x,
                    y = 1,
                    z = p.z + 0.2,
                    vx = 0,
                    vy = 0,
                    vz = -10,
                    expires = run.clock + 1,
                    heavy = true,
                },
            }
            Hall.step(room, 0.05)
            assert(p.vital == 5 and p.armor == 0 and p.z == c.front - 2)
            local remote = assert(Net.read(Net.snapshot(room))).players[1]
            assert(remote.respawned == remote.lastHurt and m.hint(run, p):find("checkpoint"))
        end
        p.x, p.z = c.gate, c.back + 1.7
        Hall.objective(room, p, MissionPacks)
    end
    assert(run.done and p.awards == 1 and buddy.awards == 1 and m.canReturn(run, p))
    g.room, g.space = r, 0
end

MissionPacks = old
print("Day 1 from the cinema to the Moon Bowl, with shared tools, joins and rewards, passed.")
