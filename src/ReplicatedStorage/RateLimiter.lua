--!native
local RateLimiter = {}

function RateLimiter.InitProfile(PlayerName: string)
    local T ={
        Move = {
            Limit = 13,
            LastMove = DateTime.now().UnixTimestampMillis,
            Count = 0
        },
        StopMove = {
            Limit = 13,
            LastMove = DateTime.now().UnixTimestampMillis,
            Count = 0
        },
        Jump = {
            Limit = 8,
            LastMove = DateTime.now().UnixTimestampMillis,
            Count = 0
        },
    }
    RateLimiter[PlayerName] = T
    return T 
end

function RateLimiter.ClientCheck(PlayerName: string, TypeToCheck: string)
    local RateProfile =  RateLimiter[PlayerName] 
    local TypeTable = RateProfile[TypeToCheck] 
    local Count =  TypeTable.Count
    local LastTime = TypeTable.LastMove
    TypeTable.Count += 1
    local LastCheck: number = DateTime.now().UnixTimestampMillis - LastTime 
    if LastCheck > 1000 then TypeTable.Count = 0; TypeTable.LastMove = DateTime.now().UnixTimestampMillis end 
    return Count > TypeTable.Limit -1 and LastCheck < 1000
end
function RateLimiter.ServerCheck(player: Player, TypeToCheck: string)
    local RateProfile =  RateLimiter[player.Name] 
    local TypeTable = RateProfile[TypeToCheck] 
    local Count =  TypeTable.Count
    local LastTime = TypeTable.LastMove
    TypeTable.Count += 1
    local LastCheck: number = DateTime.now().UnixTimestampMillis - LastTime 
    if LastCheck > 1000 then TypeTable.Count = 0; TypeTable.LastMove = DateTime.now().UnixTimestampMillis end 
    if  Count > TypeTable.Limit and LastCheck < 1000 then
        task.synchronize(); player:Kick("Please check your internet connection and try again. \n (Error Code 277)"); return true 
    end
    return
end



return RateLimiter