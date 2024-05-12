local ReplicatedStorage: ReplicatedStorage = game:GetService("ReplicatedStorage")
local HitBox = require(ReplicatedStorage.Shared.Hitbox)
local HipHeightTypes = { Humanoid = 2.7}

local Spawning = {}
function Spawning:Spawn(HipType: string, Origin)
    local Spawn:BasePart = workspace.Map.Spawn
    Origin = Origin + Vector3.new(0, 20, 0)
    local End: Vector3 = Spawn.Position + Vector3.new(0, -50, 0)
    local Distance: number= 50
    local RR:RaycastResult?  = HitBox:Raycasting(Origin, End, Distance, {workspace.Map})
    if RR then return RR.Position + Vector3.new(0, HipHeightTypes[HipType] , 0) end
    return
end
return Spawning


--[[ Info 
    Handles Spawnning / Respawning of characters  
]]
