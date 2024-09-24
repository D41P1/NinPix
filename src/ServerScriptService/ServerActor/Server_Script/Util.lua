local UID_Seed = Random.new()
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local Shared = ReplicatedStorage.Shared

-- local PlayerBan_Manager = require(script.Parent.PlayerBan_Manager)
local HB = require(Shared.Hitbox)
local Util = {}
-- local charset = "qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDFGHJKLZXCVBNM1234567890!:@~<>?}]~#;-+=&|/.,_`'" -- 85
local randomString = function(length, lowerBoundary:number, UpperBoundary:number)
    local UID = UID_Seed:NextInteger(lowerBoundary, UpperBoundary)
    return UID
    --[[ string version
    -- local result = {}
	-- for i = 1, length do 
    --     task.wait()
    --     local randomIndex = math.random(1, #charset); 
    --     table.insert(result, charset:sub(randomIndex, randomIndex)) 
    -- end
	-- local UID = table.concat(result)
    -- local Find
    -- local Success, Error = pcall(function(...)  Find = string.gsub(charset, UID, "") end)
    -- if not Success then print("Error with making UID : \n|\n", Error) end 
    -- charset = Find
    -- return UID

    ]]
    
end
function Util.GUID(Length:number, lowerBoundary:number, UpperBoundary:number): string
    local UID:string 
    local PotentialCharacter
    repeat  
        UID = randomString(Length, lowerBoundary, UpperBoundary);
        PotentialCharacter = CollectionService:GetTagged(tostring(UID))
        task.wait()
    until #PotentialCharacter < 1
    return tostring(UID)     
end
function Util.Cleanup(UID:string)
    local Instances
    Instances = CollectionService:GetTagged(UID)
    task.synchronize()
    for _, V in Instances do 
        V:Destroy()
        warn("Removing Tag", typeof(V), UID)    
    end
end
function Util.SpawnPoint()
    local R = math.random
    local Origin =     Vector3.new(R(-200, 200), 258, R(-200, 200))
    local End = Origin + Vector3.new(0, -1, 0)
    return HB:Raycasting(Origin, End, 259) --TODO in future ServerRaycasting
end
return Util