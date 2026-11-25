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
local function jobs(phase)
    for i = 1, 4 do
        while m.inTransit(run) do
            pos(run.loadX, run.loadZ + 1)
            use()
            -- Keep the escort clear while testing switch order and cargo travel.
            for _, a in ipairs(run.actors) do
                if a.kind <= 2 or a.kind == 7 then
                    a.hp = 0
                end
            end
            Hall.step(r, 0.25)
        end
        local x, z = m.destination(run)
        pos(x, z + 1)
        local tool = i == 2 and ({ [6] = 2, [9] = 3, [16] = 4 })[phase]
        if tool then
            fire(tool, x, z)
        else
            use()
        end
        assert(run.job == i, phase .. "-" .. i)
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

-- Internal barriers and entrances permit sliding around walls.
local x, z = m.move(34, -21, 1, 0, run, p)
assert(x == 35)
x, z = m.move(78.5, -21, 0.8, 0, run, p)
assert(x == 78.5)
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
        end
        jobs(phase)
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
        tick(12)
        assert(not run.slide and run.progress == 4)
        pos(a.x, a.z + 1.5)
        fire(2, a.x, a.z)
        assert(a.ice > run.clock)
        use()
        tick(24)
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
MissionPacks = old
print("Day 1 from the cinema to the Moon Bowl, with shared tools, joins and rewards, passed.")
