-- Runs inside the real engine with the same bindings and frame lifecycle as a player.
local startZ
local tools={}
function playtest_frame(f)
    local g=game.state
    startZ=startZ or g.z
    HostUTC=1796079599
    eng.input.inject("up",f<30)
    eng.input.inject("fire",f>5 and f<230)
    if f%40==3 and f<205 then
        local n=1+math.floor(f/40)%5
        host_weapon(n); tools[n]=true
    end
    if f==250 then g.playtest_done=true end
end
function playtest_verify()
    local g=game.state
    eng.test.assert_true(eng,g.z<startZ-.5,"Forward input moves the first-person camera")
    eng.test.assert_eq(eng,g.room.hours,0,"The range works before Advent")
    eng.test.assert_eq(eng,#World.doors,24,"Twenty-four physical doorways")
    eng.test.assert_eq(eng,#World.bells,5,"Five shared targets")
    eng.test.assert_eq(eng,#World.mobs,5,"Five enemy types")
    eng.test.assert_true(eng,tools[1] and tools[2] and tools[3] and tools[4] and tools[5],"All five tools selectable")
    eng.test.assert_true(eng,g.seq>4,"Normal fire input throws projectiles")
end
