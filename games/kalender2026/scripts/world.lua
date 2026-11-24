World = {
    meshes = {},
    mobs = {},
    bells = {},
    doors = {},
    markers = {},
    friends = {},
    balls = {},
    ornaments = {},
    pockets = {},
    prepared = {},
    pedestals = {},
    entrances = {},
}
local W = World
local function mesh(name)
    if not W.meshes[name] then
        W.meshes[name] = eng.asset.load_mesh("assets/" .. name .. ".glb")
    end
    return W.meshes[name]
end
local function object(name, model, x, y, z, pocket, opt)
    local e = eng.scene.spawn(name)
    eng.scene.set_mesh(e, model, opt or { tex = W.palette, roughness = 0.85, cast_shadow = false })
    eng.scene.set_pos(e, x, y, z)
    if pocket then
        eng.scene.set_pocket(e, pocket)
    end
    return e
end
local pos, rot, scale = eng and eng.scene.set_pos, eng and eng.scene.set_rot_deg, eng and eng.scene.set_scale
function W.build()
    W.palette = eng.asset.load_texture("assets/palette.png", true)
    W.snow = eng.asset.load_texture("assets/snow.png", true)
    W.ember = eng.asset.load_texture("assets/ember.png", true)
    W.box = eng.asset.box(1, 1, 1)
    W.wreath = eng.asset.voxel_ascii({ "02220", "22022", "20002", "22022", "02220" }, 5, 5, 1, 0.13)
    object("Timber galleries", mesh("great-hall"), 0, 0, 0)
    eng.render.set_sky(0.018, 0.035, 0.085, 0.14, 0.25, 0.33, 0.10, 0.14, 0.13)
    eng.render.add_light({ type = "dir", dir = { -0.35, -0.9, -0.4 }, color = { 1.6, 1.47, 1.28 }, shadow = false })
    eng.render.add_light({ type = "point", pos = { 0, 5, 1 }, color = { 2.4, 1.75, 0.8 }, range = 19 })
    eng.render.add_light({ type = "point", pos = { -19, 2.5, 0 }, color = { 2.7, 1.0, 0.35 }, range = 14 })
    eng.render.add_light({ type = "point", pos = { 11, 6, -10 }, color = { 0.7, 1.2, 2.0 }, range = 22 })
    for day = 1, 24 do
        local x, z, ix, iz = Hall.door(day)
        local yaw = math.deg(math.atan2(ix, iz))
        local pane = object(
            "Door " .. day,
            W.box,
            x - ix * 0.84,
            1.44,
            z - iz * 0.84,
            0,
            { color = { 0.055, 0.14, 0.16, 1 }, roughness = 0.7 }
        )
        rot(pane, 0, yaw, 0)
        scale(pane, 2.65, 2.85, 0.16)
        W.doors[day] = pane
        local mark = object(
            "Wreath " .. day,
            W.wreath,
            x - ix * 0.67,
            1.73,
            z - iz * 0.67,
            0,
            { color = { 0.48, 0.95, 0.64, 1 }, emissive = 0.16 }
        )
        rot(mark, 0, yaw, 0)
        W.markers[day] = mark
        local pack = MissionPacks[day]
        if pack then
            local space = eng.scene.register_pocket("day_" .. day)
            W.pockets[day] = space
            local src = eng.scene.spawn("Walk into day " .. day)
            pos(src, x, 1.45, z)
            rot(src, 0, yaw, 0)
            W.entrances[day] = src
            local dst = eng.scene.spawn("Return from day " .. day)
            eng.scene.set_pocket(dst, space)
            pos(dst, 0, 1.45, 6.9)
            eng.portal.link(src, dst, 2.65, 2.85, 1, true, true)
            local floor =
                object("Mission floor", W.box, 0, -0.2, 0, space, { color = { 0.23, 0.30, 0.33, 1 } })
            scale(floor, 16, 0.4, 16)
            local pedestal = object("Mission objective", mesh("bell"), 0, 1.55, 0, space)
            eng.render.add_light({
                type = "dir",
                dir = { -0.4, -1, -0.2 },
                color = { 1.6, 1.5, 1.2 },
                pocket = "day_" .. day,
                shadow = false,
            })
            W.pedestals[day] = pedestal
        end
    end
    for i, m in ipairs(Hall.visitors) do
        W.mobs[i] = object(m.name, mesh(m.file), 0, -40, 0)
    end
    for i, t in ipairs(Hall.targets) do
        W.bells[i] = object("Range bell " .. i, mesh("bell"), t[1], t[2], t[3])
    end
    for i = 1, 8 do
        W.friends[i] = object("Friend " .. i, mesh("friend"), 0, -40, 0)
    end
    W.gun = object("Snowcaster", mesh("pistol"), 0, -40, 0)
    scale(W.gun, 0.56, 0.56, 0.56)
    W.lastDay, W.lastAwards, W.selected = -1, -1, 0
end
function W.prepare(day)
    if W.prepared[day] then
        return
    end
    local pack = MissionPacks[day]
    if pack.build then
        pack.build(W.pockets[day], W.pedestals[day])
    end
    W.prepared[day] = true
end
local function doors(r, awards)
    if W.lastDay == r.hours and W.lastAwards == awards then
        return
    end
    for day, e in ipairs(W.doors) do
        local x, z, ix, iz = Hall.door(day)
        local due = day <= r.hours
        local ready = due and MissionPacks[day]
        local marked = math.floor(awards / 2 ^ (day - 1)) % 2 == 1
        local color = ready and { 0.35, 0.72, 0.55, 1 }
            or due and { 0.37, 0.23, 0.11, 1 }
            or { 0.065, 0.13, 0.16, 1 }
        eng.scene.set_mesh(e, W.box, { color = color, emissive = due and 0.3 or 0.02 })
        pos(e, x - ix * 0.84, ready and -6 or 1.44, z - iz * 0.84)
        if W.entrances[day] then
            pos(W.entrances[day], x, ready and 1.45 or -35, z)
        end
        local icon = W.markers[day]
        pos(icon, x - ix * 0.60, (ready and 3.75 or 1.8), z - iz * 0.60)
        scale(icon, due and 1.3 or 1, due and 0.65 or 1, 1)
        if marked and not W.ornaments[day] then
            local a = day * 2.4
            W.ornaments[day] = object(
                "Earned ornament " .. day,
                mesh("bell"),
                math.cos(a) * 1.9,
                2.8 + (day % 4) * 0.5,
                math.sin(a) * 1.9
            )
            scale(W.ornaments[day], 0.4, 0.4, 0.4)
            local badge = object("Completed door " .. day, mesh("bell"), x + ix * 0.3, 3.1, z + iz * 0.3)
            scale(badge, 0.65, 0.65, 0.65)
        end
    end
    W.lastDay, W.lastAwards = r.hours, awards
end
function W.update(g, dt)
    local r = g.room
    doors(r, g.awards)
    for i, e in ipairs(W.mobs) do
        local m = r.mobs[i]
        if m and m.hp > 0 and m.wake <= r.time then
            pos(e, m.x, m.y + 0.04 * math.sin(r.time * 4 + i), m.z)
            rot(e, 0, m.heading or 0, 0)
        else
            pos(e, 0, -40, 0)
        end
    end
    for i, e in ipairs(W.bells) do
        rot(e, (r.targets[i] or 0) > r.time and 55 or 0, 0, 0)
    end
    for i, e in ipairs(W.friends) do
        local p = r.players[i]
        if p and i ~= g.id then
            local x, _, z = eng.scene.get_pos(e)
            local blend = g.online and math.min(1, dt * 16) or 1
            if (x - p.x) ^ 2 + (z - p.z) ^ 2 > 6 then
                blend = 1
            end
            eng.scene.set_pocket(e, W.pockets[p.space] or 0)
            pos(e, x + (p.x - x) * blend, 1, z + (p.z - z) * blend)
            rot(e, 0, p.yaw + 180, 0)
        else
            pos(e, 0, -40, 0)
        end
    end
    for index, s in ipairs(r.shots) do
        if not W.balls[index] then
            W.balls[index] = object("Flying snow", mesh("snowball"), s.x, s.y, s.z)
        end
        local e = W.balls[index]
        local size = s.kind == 5 and 2.1 or 1
        pos(e, s.x, s.y, s.z)
        scale(e, size, size, size)
    end
    for i = #r.shots + 1, #W.balls do
        pos(W.balls[i], 0, -40, 0)
    end
    local yaw, pitch = math.rad(g.yaw), math.rad(g.pitch)
    local fx, fy, fz = -math.sin(yaw) * math.cos(pitch), math.sin(pitch), -math.cos(yaw) * math.cos(pitch)
    local gun = W.gun
    if W.selected ~= g.weapon then
        eng.scene.set_mesh(
            gun,
            mesh(Hall.weapons[g.weapon].file),
            { tex = W.palette, roughness = 0.72, emissive = 0.06 }
        )
        W.selected = g.weapon
    end
    eng.scene.set_pocket(gun, W.pockets[g.space] or 0)
    if g.xr then
        pos(gun, g.x + g.xr.ox, 1.55 + g.xr.oy, g.z + g.xr.oz)
        rot(gun, g.xr.pitch, g.xr.yaw, 0)
    else
        local reach = 0.62 - g.recoil
        pos(
            gun,
            g.x + fx * reach + math.cos(yaw) * 0.26,
            1.55 + fy * reach - 0.18 * math.cos(pitch),
            g.z + fz * reach - math.sin(yaw) * 0.26
        )
        rot(gun, g.pitch + g.recoil * 50, g.yaw, 0)
    end
    eng.camera.set(g.x, g.xr and 0 or 1.55, g.z, g.xr and 0 or g.pitch, g.yaw, 0, W.pockets[g.space] or 0)
    if g.menu and not g.xr then
        pos(gun, 0, -40, 0)
        eng.camera.look_at(-6, 2.35, 13, -3, 3.0, 0)
    end
end
function W.sprites(g)
    if g.space ~= 0 then
        return
    end
    local t = g.room.time
    for n = 1, 34 do
        local x = ((n * 17) % 41) - 20 + math.sin(t + n) * 0.15
        local z = ((n * 13) % 43) - 21
        eng.render.draw_sprite(x, 6.7 - (t * 0.42 + n * 0.37) % 6.2, z, 0.075, 0.075, W.snow)
    end
    eng.render.draw_sprite(-21, 1.55, 0, 1.5, 1.8 + 0.15 * math.sin(t * 8), W.ember)
    local today = g.room.hours
    if today > 0 then
        local x, z, ix, iz = Hall.door(today)
        for i = 1, 5 do
            eng.render.draw_sprite(x + ix * i, 0.12, z + iz * i, 0.25, 0.25, W.ember)
        end
    end
end
