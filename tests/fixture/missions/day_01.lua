MissionPacks[1] = {
    title = "Co-op test room",
    start = function(run)
        run.progress = 0
    end,
    act = function(run, player)
        if player.z > 3 then
            return false
        end
        run.progress = run.progress + 1
        return run.progress >= 2
    end,
}
