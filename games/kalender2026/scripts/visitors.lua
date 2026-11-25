-- Each pivot is in the visitor body's local coordinates. Gait uses distance travelled,
-- so an interrupted walk never keeps marching feet against a stationary body.
Visitors = {}
local V = Visitors
local F = Feedback
V.joints = {
    { { "scarf", 0.22, 0.26, 0.33 }, { "left", -0.32, 0.08, 0 }, { "right", 0.32, 0.08, 0 } },
    {
        { "left-leg", -0.20, -0.33, 0 },
        { "right-leg", 0.20, -0.33, 0 },
        { "left-arm", -0.30, 0.16, 0 },
        {
            "right-arm",
            0.30,
            0.16,
            0,
        },
    },
    {
        { "left-leg", -0.30, -0.86, 0 },
        { "right-leg", 0.30, -0.86, 0 },
        { "left-arm", -0.30, 0.15, 0 },
        {
            "right-arm",
            0.30,
            0.15,
            0,
        },
    },
    {
        { "left-leg", -0.18, -0.31, 0 },
        { "right-leg", 0.18, -0.31, 0 },
        { "left-arm", -0.36, 0.28, 0 },
        {
            "right-arm",
            0.36,
            0.28,
            0,
        },
    },
    { { "left", -0.23, 0.12, 0 }, { "right", 0.23, 0.12, 0 } },
}
V.strides = { 0.85, 0.60, 1.35, 0.72, 1.00 }
function V.build(i, root, make, mesh)
    local parts = {}
    for k, j in ipairs(V.joints[i]) do
        local e =
            make(Hall.visitors[i].name .. " " .. j[1], mesh(Hall.visitors[i].file .. "-" .. j[1]), 0, 0, 0)
        eng.scene.set_parent(e, root)
        eng.scene.set_pos(e, j[2], j[3], j[4])
        parts[k] = e
    end
    return parts
end
local function nearby(g, v, m)
    local dx, dz = m.x - g.x, m.z - g.z
    local d = dx * dx + dz * dz
    if d > F.rearm ^ 2 then
        v.rearArmed = true
    end
    if d > F.approach ^ 2 or not v.rearArmed or not F.on("VIS-04") then
        return
    end
    local a = math.rad(g.headYaw or g.yaw)
    if dx * math.sin(a) + dz * math.cos(a) <= 0 then
        return
    end
    if g.clock < g.feedback.nextRear then
        return
    end
    v.rearArmed = false
    g.feedback.nextRear = g.clock + 2
    local side = dx * math.cos(a) - dz * math.sin(a)
    local text = math.abs(side) < 0.28 and "Behind" or (side < 0 and "Behind left" or "Behind right")
    g.feedback.rearIcon = { text = text, untilTime = g.clock + 0.35 }
    F.sound(g, "rustle", 0.42, 1, 2, m.x, m.y, m.z, 6)
    F.caption(
        g,
        text,
        m.x,
        m.y + 0.6,
        m.z,
        math.abs(side) < 0.28 and "footprint" or (side < 0 and "rearleft" or "rearright")
    )
end
local function accents(g, i, v, m, moving, turn)
    if not moving or g.clock < v.nextAccent then
        return
    end
    if i == 2 and F.on("VIS-06") then
        local beat = math.floor(v.phase / math.pi)
        if beat ~= v.beat then
            local a = math.rad(v.travelYaw)
            local side = beat % 2 == 0 and 0.20 or -0.20
            local x = v.renderX + side * math.cos(a) - 0.13 * math.sin(a)
            local z = v.renderZ - side * math.sin(a) - 0.13 * math.cos(a)
            F.particle(g, "crumb", x, 0.10, z, -0.13, 0.2, 0.1, 0.065, 0.18)
            F.particle(g, "crumb", x, 0.10, z, 0.12, 0.3, -0.09, 0.05, 0.18)
            v.nextAccent = g.clock + 0.35
        end
        v.beat = beat
    elseif i == 3 and F.on("VIS-07") then
        local kind = math.cos(v.phase) > 0 and 1 or 0
        if v.beat ~= kind then
            local scratch = F.particle(g, "scratch", m.x, 0.09, m.z, 0, 0, 0, 0.22, 0.22, 2)
            if scratch then
                scratch.angle = v.travelYaw
            end
            v.nextAccent = g.clock + 0.30
        end
        v.beat = kind
    elseif i == 4 and math.abs(turn) >= 44 and F.on("VIS-08") then
        F.sound(g, "gear", 0.32, 1, 1, m.x, m.y, m.z, 6)
        v.nextAccent = g.clock + 0.30
    elseif i == 5 and F.on("VIS-09") then
        for side = -1, 1, 2 do
            F.particle(g, "mote", m.x + side * 0.10, m.y - 0.43, m.z, side * 0.15, -0.35, 0, 0.085, 0.16)
        end
        v.nextAccent = g.clock + 0.50
    end
end
function V.update(g, i, root, parts, dt)
    local f, r = g.feedback, g.room
    local m = r.mobs[i]
    local v = f.visitors[i]
    if not m or m.hp <= 0 or m.wake > r.time then
        eng.scene.set_pos(root, 0, -40, 0)
        f.visitors[i] = nil
        return
    end
    if not v or v.wave ~= r.wave then
        v = {
            renderX = m.x,
            renderZ = m.z,
            renderY = m.y,
            renderHeading = m.heading or 0,
            visualTime = r.time,
            heading = m.heading or 0,
            phase = i * 0.59,
            lag = 0,
            beat = -1,
            wave = r.wave,
            nextAccent = g.clock,
            rearArmed = true,
            travelYaw = m.heading or 0,
        }
        f.visitors[i] = v
        if not f.quietWake and g.space == 0 and F.on("VIS-01") then
            F.particle(g, "footprint", m.x, 0.13, m.z, 0, 0, 0, 0.35, 0.19)
        end
    end
    local smooth = g.online and math.min(1, dt * 19) or 1
    local dx, dz = (m.x - v.renderX) * smooth, (m.z - v.renderZ) * smooth
    v.renderX, v.renderZ = v.renderX + dx, v.renderZ + dz
    v.renderY = v.renderY + (m.y - v.renderY) * smooth
    v.visualTime = g.online and math.min(r.time + 0.1, math.max(r.time, v.visualTime + dt)) or r.time
    v.renderHeading = v.renderHeading + (((m.heading or 0) - v.renderHeading + 180) % 360 - 180) * smooth
    local dist = math.sqrt(dx * dx + dz * dz)
    local turn = ((m.heading or 0) - v.heading + 180) % 360 - 180
    if dist > 0.0001 then
        v.phase = v.phase + dist / V.strides[i] * math.pi * 2
        v.travelYaw = math.deg(math.atan2(dx, dz))
    end
    if g.space == 0 and (not g.menu or g.xr) then
        nearby(g, v, m)
        accents(g, i, v, m, dist > 0.0001, turn)
    end
    v.lag = Hall.clamp(v.lag - turn, -8, 8) * math.max(0, 1 - dt / 0.14)
    v.heading = m.heading or 0
    local motion = f.prefs[1] / 100
    local gait = math.sin(v.phase)
    local beat = math.abs(gait)
    local lift, lean, roll = 0, 0, 0
    local function joint(k, pitch, yaw, bank)
        eng.scene.set_rot_deg(parts[k], pitch * motion, yaw * motion, bank * motion)
    end
    if i == 1 then
        lift, roll = 0.035 * beat, 4 * gait
        joint(1, 5 * gait, F.on("VIS-05") and v.lag or 0, 5 * gait)
        joint(2, 12 * gait, 0, -3 * beat)
        joint(3, -12 * gait, 0, 3 * beat)
    elseif i == 2 then
        lift, lean, roll = 0.14 * beat, 6 * beat, 4 * gait
        joint(1, 32 * gait, 0, 0)
        joint(2, -32 * gait, 0, 0)
        joint(3, -26 * gait, 0, -8 * beat)
        joint(4, 26 * gait, 0, 8 * beat)
    elseif i == 3 then
        roll = 10 * gait
        joint(1, 8 * gait, 13 * gait, 4 * beat)
        joint(2, -8 * gait, -13 * gait, -4 * beat)
        joint(3, -10 * gait, 0, -18 - 14 * gait)
        joint(4, 10 * gait, 0, 18 - 14 * gait)
    elseif i == 4 then
        local march = Hall.clamp(gait * 1.6, -1, 1)
        lift, roll = 0.055 * beat, 2 * march
        joint(1, 31 * march, 0, 0)
        joint(2, -31 * march, 0, 0)
        joint(3, -27 * march, 0, 0)
        joint(4, 27 * march, 0, 0)
    else
        local drift = math.sin(v.visualTime * 2 + i)
        lean, roll = 5 * drift, 8 * math.cos(v.visualTime * 2)
        joint(1, 8 * drift, 0, 17 * drift)
        joint(2, -8 * drift, 0, -17 * drift)
    end
    local hit = f.flinch[i]
    if hit then
        local amount = F.flinchDegrees * math.max(0, 1 - (g.clock - hit.start) / F.flinchTime)
        local angle = math.rad(hit.angle - v.renderHeading)
        lean, roll = lean + math.cos(angle) * amount, roll - math.sin(angle) * amount
    end
    eng.scene.set_pos(root, v.renderX, v.renderY + lift * motion, v.renderZ)
    eng.scene.set_rot_deg(root, lean * motion, v.renderHeading, roll * motion)
end
