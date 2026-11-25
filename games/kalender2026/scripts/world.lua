World = {
    meshes = {},
    mobs = {},
    joints = {},
    prints = {},
    fxTextures = {},
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
local lampColors = {
    amber = { 1.8, 0.66, 0.095 },
    ruby = { 1.4, 0.027, 0.012 },
    green = { 0.026, 1.02, 0.17 },
    blue = { 0.047, 0.31, 1.65 },
    rose = { 1.28, 0.06, 0.39 },
    flame = { 2.9, 1.23, 0.23 },
    coal = { 0.77, 0.060, 0.008 },
    star = { 0.75, 0.30, 0.045 },
}
-- The forward shader recognizes the floor (-2) and projected silhouettes (-3).
local function shadowed(name, model, x, y, z)
    local body = object(name, model, x, y, z)
    local shadow = object(name .. " shadow", model, 0, 0, 0, 0, W.shadowMaterial)
    eng.scene.set_parent(shadow, body)
    return body, shadow
end
function W.build()
    W.palette = eng.asset.load_texture("assets/palette.png", true)
    W.snow = eng.asset.load_texture("assets/snow.png", true)
    W.ember = eng.asset.load_texture("assets/ember.png", true)
    for _, name in ipairs({
        "powder",
        "crumb",
        "gear",
        "mote",
        "boot",
        "footprint",
        "bellcue",
        "clearcue",
        "practicecue",
        "doorcue",
        "rearleft",
        "rearright",
        "ticks",
        "finish",
        "scratch",
        "stamp",
        "boot-contrast",
        "ticks-contrast",
        "finish-contrast",
    }) do
        W.fxTextures[name] = eng.asset.load_texture("assets/" .. name .. ".png", true)
    end
    W.fxTextures.ring = W.fxTextures.powder
    W.box = eng.asset.box(1, 1, 1)
    W.wreath = eng.asset.voxel_ascii({ "02220", "22022", "20002", "22022", "02220" }, 5, 5, 1, 0.13)
    W.floorTex = eng.asset.load_texture("assets/hall-floor.png", true)
    W.shadowMaterial = { tex = W.floorTex, metallic = -3, roughness = 0.94, cast_shadow = false }
    object(
        "Flagstones and runners",
        mesh("hall-floor"),
        0,
        0,
        0,
        0,
        { tex = W.floorTex, metallic = -2, roughness = 0.94, cast_shadow = false }
    )
    object("Timber galleries", mesh("great-hall"), 0, 0, 0)
    object(
        "Brass portal numerals",
        mesh("door-numerals"),
        0,
        0,
        0,
        0,
        { tex = W.palette, roughness = 0.65, emissive = { 0.115, 0.062, 0.021 } }
    )
    object(
        "Christmas mantel and fixtures",
        mesh("christmas-fittings"),
        0,
        0,
        0,
        0,
        { tex = W.palette, metallic = -1, roughness = 0.85, cast_shadow = false }
    )
    object(
        "Norway spruce sprays",
        mesh("spruce-boughs"),
        0,
        0,
        0,
        0,
        { tex = eng.asset.load_texture("assets/spruce-spray.png", true), metallic = -1, roughness = 0.93 }
    )
    object(
        "Firebrick",
        mesh("hearth-masonry"),
        0,
        0,
        0,
        0,
        { tex = eng.asset.load_texture("assets/hearth-brick.png", true), metallic = -1, roughness = 0.95 }
    )
    for name, glow in pairs({
        ["winter-ridges"] = { 0.019, 0.041, 0.090 },
        ["winter-snow"] = { 0.087, 0.151, 0.224 },
        ["winter-pines"] = { 0.005, 0.013, 0.022 },
    }) do
        object(name, mesh(name), 0, 0, 0, 0, { emissive = glow, roughness = -1, cast_shadow = false })
    end
    object(
        "Glass baubles",
        mesh("glass-ornaments"),
        0,
        0,
        0,
        0,
        { tex = W.palette, metallic = 0.46, roughness = 0.22 }
    )
    for name, color in pairs(lampColors) do
        object(
            name .. " glass",
            mesh("lamp-" .. name),
            0,
            0,
            0,
            0,
            { tex = W.palette, emissive = color, roughness = 0.34 }
        )
    end
    W.glow = eng.asset.load_texture("assets/lamp-halo.png", true)
    W.fireFrames = {}
    for i = 1, 16 do
        W.fireFrames[i] = eng.asset.load_texture(string.format("assets/hearth-fire-%02d.png", i), true)
    end
    eng.render.set_sky(0.004, 0.007, 0.015, 0.016, 0.019, 0.032, 0.011, 0.008, 0.007)
    for i, lamp in ipairs(HallLights) do
        local handle = eng.render.add_light(lamp)
        if i == 1 then
            W.fireLight = handle
        end
    end
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
        W.mobs[i] = shadowed(m.name, mesh(m.file), 0, -40, 0)
        W.joints[i] = Visitors.build(i, W.mobs[i], shadowed, mesh)
    end
    for i, t in ipairs(Hall.targets) do
        W.bells[i] = object("Range bell " .. i, mesh("bell"), t[1], t[2], t[3])
    end
    W.friendShadows = {}
    for i = 1, 8 do
        W.friends[i], W.friendShadows[i] = shadowed("Friend " .. i, mesh("friend"), 0, -40, 0)
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
        local state = Hall.door_state(day, r.hours, MissionPacks)
        local due = state ~= "locked"
        local ready = state == "ready"
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
                mesh(MissionPacks[day] and MissionPacks[day].ornament or "bell"),
                math.cos(a) * 1.9,
                2.8 + (day % 4) * 0.5,
                math.sin(a) * 1.9
            )
            scale(W.ornaments[day], 0.4, 0.4, 0.4)
            local badge = object(
                "Completed door " .. day,
                mesh(MissionPacks[day] and MissionPacks[day].ornament or "bell"),
                x + ix * 0.3,
                3.1,
                z + iz * 0.3
            )
            scale(badge, 0.65, 0.65, 0.65)
        end
    end
    W.lastDay, W.lastAwards = r.hours, awards
end
local F = Feedback
local function prints(g)
    local used = 0
    local f = g.feedback
    for i = 1, F.limit(g) do
        local e = f.effects[i]
        if e.plane and g.space == 0 and g.clock < e.start + e.life and e.life > 0 then
            used = used + 1
            local node = W.prints[used]
            if not node then
                node = object("Snow print " .. used, mesh("snow-print"), 0, -40, 0)
                W.prints[used] = node
            end
            pos(node, e.x, e.y, e.z)
            rot(node, e.plane == 3 and 90 or 0, e.angle, e.plane == 1 and 90 or 0)
            scale(node, e.size * (e.kind == "scratch" and 0.3 or 1), e.size, e.size)
        end
    end
    for i = used + 1, #W.prints do
        pos(W.prints[i], 0, -40, 0)
    end
end
function W.update(g, dt)
    local r = g.room
    doors(r, g.awards)
    for i, e in ipairs(W.mobs) do
        Visitors.update(g, i, e, W.joints[i], dt)
    end
    local f = g.feedback
    f.quietWake = false
    local motion = f.prefs[1] / 100
    local burn = g.clock * motion
    local heat = 1 + (0.045 * math.sin(burn * 5.1) + 0.035 * math.sin(burn * 9.7)) * motion
    local fire = HallLights[1].color
    eng.render.set_light(W.fireLight, { color = { fire[1] * heat, fire[2] * heat, fire[3] * heat } })
    for i, e in ipairs(W.bells) do
        local remaining = (r.targets[i] or 0) - r.time
        local tilt = 0
        if remaining > 0 then
            local t = Hall.clamp((F.bellReset - remaining) / F.swingTime, 0, 1)
            tilt = F.on("HALL-01") and 18 + motion * 37 * (1 - t) ^ 2 * math.cos(2 * math.pi * t) or 55
        end
        rot(e, tilt, 0, 0)
    end
    for day, at in pairs(f.lastKnock) do
        local _, _, ix, iz = Hall.door(day)
        local t = math.min(1, (g.clock - at) / 0.12)
        rot(W.markers[day], 0, math.deg(math.atan2(ix, iz)), 4 * math.sin(t * math.pi) * motion)
    end
    prints(g)
    for i, e in ipairs(W.friends) do
        local p = r.players[i]
        if p and i ~= g.id then
            local x, _, z = eng.scene.get_pos(e)
            local blend = g.online and math.min(1, dt * 16) or 1
            if (x - p.x) ^ 2 + (z - p.z) ^ 2 > 6 then
                blend = 1
            end
            eng.scene.set_pocket(e, W.pockets[p.space] or 0)
            eng.scene.set_pocket(W.friendShadows[i], W.pockets[p.space] or 0)
            local tiny = p.tiny and r.instances[p.space] and r.instances[p.space].progress == 15
            local height = tiny and 0.36 or 1
            scale(e, height, height, height)
            pos(e, x + (p.x - x) * blend, height, z + (p.z - z) * blend)
            rot(e, 0, p.yaw + 180, 0)
        else
            pos(e, 0, -40, 0)
        end
    end
    local live = {}
    for index, s in ipairs(r.shots) do
        if not W.balls[index] then
            W.balls[index] = object("Flying snow", mesh("snowball"), s.x, s.y, s.z)
        end
        local e = W.balls[index]
        local size = s.kind == 5 and 2.1 or 1
        pos(e, s.x, s.y, s.z)
        scale(e, size, size, size)
        if s.kind == 5 and F.on("FIRE-07") and g.space == 0 then
            local last = f.trails[s.id]
            if last then
                local dx, dy, dz = last.x - s.x, last.y - s.y, last.z - s.z
                local len = math.sqrt(dx * dx + dy * dy + dz * dz)
                if len > 0.001 then
                    last.dx, last.dy, last.dz = dx / len, dy / len, dz / len
                    last.at = g.clock
                end
                last.x, last.y, last.z = s.x, s.y, s.z
            else
                f.trails[s.id] = { x = s.x, y = s.y, z = s.z, at = -1 }
            end
            live[s.id] = true
        end
    end
    for id in pairs(f.trails) do
        if not live[id] then
            f.trails[id] = nil
        end
    end
    for i = #r.shots + 1, #W.balls do
        pos(W.balls[i], 0, -40, 0)
    end
    local yaw, pitch = math.rad(g.yaw), math.rad(g.pitch)
    local fx, fy, fz = -math.sin(yaw) * math.cos(pitch), math.sin(pitch), -math.cos(yaw) * math.cos(pitch)
    local gun = W.gun
    if W.selected ~= g.weapon and not (MissionPacks[g.space] and MissionPacks[g.space].render) then
        eng.scene.set_mesh(
            gun,
            mesh(Hall.weapons[g.weapon].file),
            { tex = W.palette, roughness = 0.72, emissive = 0.06 }
        )
        scale(gun, 0.56, 0.56, 0.56)
        W.selected = g.weapon
    end
    eng.scene.set_pocket(gun, W.pockets[g.space] or 0)
    if g.xr then
        pos(gun, g.x + g.xr.ox, 1.55 + g.xr.oy, g.z + g.xr.oz)
        rot(gun, g.xr.pitch, g.xr.yaw, 0)
    else
        local reach = 0.62 - g.recoil
        local stride = math.pi * (f.step + f.stride / F.stride)
        local gait = F.on("HALL-05")
                and 0.008 * motion * math.max(0, 1 - (g.clock - (f.walkAt or -1)) / 0.12) * (g.recoil > 0 and 0.25 or 1)
            or 0
        local dip = F.on("FIRE-08") and 0.04 * motion * math.max(0, 1 - (g.clock - f.swapStart) / F.handover)
            or 0
        pos(
            gun,
            g.x + fx * reach + math.cos(yaw) * (0.26 + gait * math.sin(stride)),
            1.55 + fy * reach - 0.18 * math.cos(pitch) - dip + gait * math.cos(2 * stride),
            g.z + fz * reach - math.sin(yaw) * (0.26 + gait * math.sin(stride))
        )
        rot(gun, g.pitch + g.recoil * 50, g.yaw, 0)
    end
    local pack = MissionPacks[g.space]
    local eye = 1.55
    if pack and pack.render then
        eye = pack.render(g, dt)
    end
    eng.camera.set(
        g.x,
        g.xr and eye - 1.55 or eye,
        g.z,
        g.xr and 0 or g.pitch,
        g.yaw,
        0,
        W.pockets[g.space] or 0
    )
    if g.menu and not g.xr then
        pos(gun, 0, -40, 0)
        eng.camera.look_at(-6, 2.35, 13, -3, 3.0, 0)
    end
end
function W.sprites(g)
    local f = g.feedback
    local function sprite(kind, x, y, z, size)
        eng.render.draw_sprite(x, y, z, size, size, W.fxTextures[kind])
    end
    local limit = F.limit(g)
    local used = 0
    for i = 1, limit do
        local e = f.effects[i]
        local age = g.clock - (e.start or 0)
        if age < e.life then
            used = used + 1
            if not e.plane then
                local motion = f.prefs[1] / 100
                local t = age * motion
                if e.kind == "ring" then
                    t = age * motion + e.life * (1 - motion)
                end
                sprite(
                    e.kind,
                    e.x + t * e.vx,
                    e.y + t * e.vy,
                    e.z + t * e.vz,
                    e.size * (1 - 0.48 * age / e.life * motion)
                )
            end
        end
    end
    local contrast = f.prefs[7] == 1 and "-contrast" or ""
    if g.xr then
        if f.prefs[5] == 1 and g.clock < f.markUntil then
            sprite(f.mark .. contrast, f.mx, f.my + 0.09, f.mz, 0.24)
        end
        local hand = g.xr
        if (f.slow and F.on("VIS-02")) or g.clock < f.recovery then
            sprite("boot" .. contrast, g.x + hand.ox, 1.70 + hand.oy, g.z + hand.oz, 0.10)
        end
        if f.prefs[6] == 1 then
            for i, c in ipairs(f.captions) do
                sprite(c.icon, c.x, c.y + 0.10 * i, c.z, 0.24)
                sprite(c.icon, g.x + hand.ox + 0.07 * i, 1.82 + hand.oy, g.z + hand.oz, 0.06)
            end
        end
    end
    if g.space ~= 0 then
        local pack = MissionPacks[g.space]
        if pack and pack.sprites then
            pack.sprites(g)
        end
        f.drawn = used
        return
    end
    for _, v in pairs(f.trails) do
        if v.dx and g.clock - v.at < 0.1 then
            for k = 1, math.min(3, limit - used) do
                sprite(
                    "powder",
                    v.x + v.dx * k * 0.15,
                    v.y + v.dy * k * 0.15,
                    v.z + v.dz * k * 0.15,
                    0.13 - k * 0.023
                )
                used = used + 1
            end
        end
    end
    if g.clock < math.max(f.answer, f.invite) and used < limit then
        local anim = f.prefs[1] / 100
        sprite(
            "bellcue",
            g.clock < f.answer and 0.18 * anim * math.sin((f.answer - g.clock) * 25) or 0,
            2 + anim * 0.16 * math.sin((f.invite - g.clock) * 4),
            -13,
            0.40
        )
        used = used + 1
    end
    f.drawn = used
    local t = g.room.time
    for n = 1, 34 do
        local x = ((n * 17) % 41) - 20 + math.sin(t + n) * 0.15
        local z = ((n * 13) % 43) - 21
        eng.render.draw_sprite(x, 6.7 - (t * 0.42 + n * 0.37) % 6.2, z, 0.075, 0.075, W.snow)
    end
    local fireTime = g.clock * f.prefs[1] / 100
    local frame = math.floor(fireTime * 12) % #W.fireFrames
    eng.render.draw_sprite(
        -22.94,
        0.54,
        -0.19,
        1.68,
        1.33,
        W.fireFrames[1 + (frame + 7) % 16],
        0.80,
        0.58,
        0.35,
        0,
        true
    )
    eng.render.draw_sprite(-22.71, 0.56, 0.16, 1.49, 1.24, W.fireFrames[1 + frame], 0.91, 0.74, 0.46, 0, true)
    if f.prefs[2] > 0 then
        for _, h in ipairs(HallHalos) do
            local c = lampColors[h[1]]
            eng.render.draw_sprite(
                h[2],
                h[3] - h[5] * 0.5,
                h[4],
                h[5],
                h[5],
                W.glow,
                c[1] * 0.60,
                c[2] * 0.60,
                c[3] * 0.60,
                0,
                true
            )
        end
        if f.prefs[1] > 0 then
            for i = 1, 4 do
                local age = (fireTime * 0.58 + i * 0.27) % 1
                local size = 0.075 * (1 - age)
                eng.render.draw_sprite(
                    -22.54,
                    0.78 + age,
                    (i - 2.5) * 0.30 + 0.08 * math.sin(6 * age + i),
                    size,
                    size,
                    W.glow,
                    1.6,
                    0.40,
                    0.05,
                    0,
                    true
                )
            end
        end
    end
    local today = g.room.hours
    if today > 0 then
        local x, z, ix, iz = Hall.door(today)
        for i = 1, 5 do
            eng.render.draw_sprite(x + ix * i, 0.12, z + iz * i, 0.25, 0.25, W.ember)
        end
    end
end
