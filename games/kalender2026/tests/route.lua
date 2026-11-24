-- Walk the complete numbered gallery using the same movement actions as a player.
local day, wall = 1, 0
local function move(x, z)
    eng.input.inject("left", x < -0.18)
    eng.input.inject("right", x > 0.18)
    eng.input.inject("up", z < -0.18)
    eng.input.inject("down", z > 0.18)
end
function playtest_frame()
    HostUTC = 1796079599
    local g = game.state
    if day <= 24 then
        local x, z = Hall.door(day)
        if (x - g.x) ^ 2 + (z - g.z) ^ 2 < 0.28 ^ 2 then
            day = day + 1
            move(0, 0)
        else
            move(x - g.x, z - g.z)
        end
    else
        move(0, 1)
        wall = wall + 1
        if wall >= 48 then
            g.playtest_done = true
        end
    end
end
function playtest_verify()
    eng.test.assert_eq(eng, day, 25, "Reached all 24 numbered thresholds")
    eng.test.assert_eq(eng, game.state.space, 0, "All future thresholds kept us in the hall")
    eng.test.assert_true(eng, math.abs(game.state.z - Hall.limit) < 0.01, "A solid wall stopped movement")
end
