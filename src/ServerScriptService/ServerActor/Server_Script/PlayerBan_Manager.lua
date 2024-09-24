local Players = game:GetService("Players")
local PlayerBan_Manager = {}
do 
    local Messages  = {
        [1] = "Spoofing Avatar Data",
        [2] = "Spoofing Inventory Data",
        [3] = "Spoofing CombatLogic App_Da",
        [4] = "Spoofing Combalogic Block"
    }
    local AltAccounts_Cannot_Play = false
    local BanFunc = function(player:Player, DurationInDays: number, MessageNumber:number)
        local BanMessage = Messages[MessageNumber]
        if not BanMessage then  warn("incorrecnt Message Number: ", MessageNumber);  return  end
        BanMessage = BanMessage .."\n You have been banned for: " .. tostring(DurationInDays) .. " Days"
        local config = {
            ["UserIds"]= {player.UserId},
            ["ApplyToUniverse"] = true, 
            ["Duration"]=  DurationInDays * 6,  --TODO -- 86400
            ["DisplayReason"] = BanMessage,
            ["PrivateReason"] = BanMessage,
            ["ExcludeAltAccounts"] = AltAccounts_Cannot_Play
        } 
        task.synchronize()
        Players:BanAsync(config)        --UserIds , ApplyToUniverse, Duration  DisplayReason, PrivateReason,  
    end
    local UnbanFunc = function(player:Player)
        Players:UnbanAsync({player.UserId}, true)
    end
    --* Insert Funcs into Module
    PlayerBan_Manager["Ban"] = BanFunc
    PlayerBan_Manager["UnBan"] = UnbanFunc
end

return PlayerBan_Manager