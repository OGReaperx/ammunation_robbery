-- function to check for player job
function IsPlayerRestricted(source)
    local player = exports.qbx_core:GetPlayer(source)

    if not player or not player.PlayerData or not player.PlayerData.job then
        return false  -- If no job info is found, assume the player is not restricted
    end

    local playerJob = player.PlayerData.job.name  --

    for _, restrictedJob in ipairs(Config.RestrictedJobs) do
        if playerJob == restrictedJob then
            return true
        end
    end

    return false
end