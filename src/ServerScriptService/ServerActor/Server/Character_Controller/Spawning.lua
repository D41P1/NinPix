local RP = game:GetService("ReplicatedStorage")
local WorkSpace = require(RP.Shared.Workspace)
local workspace:WorkSpace.workspace = workspace
local HitBox = require(RP.Shared.Hitbox)

local HipHeightTypes = { Humanoid = 3}

local Spawning = {}
function Spawning:Spawn(HipType: string)
    local Spawn:BasePart = workspace.Map.Spawn
    local Origin = Spawn.Position
    local End = Spawn.Position + Vector3.new(0, -50, 0)
    local Distance = 50
    local RR:RaycastResult?  = HitBox:Raycasting(Origin, End, Distance, {workspace.Map})
    if RR then return RR.Position + Vector3.new(0, HipHeightTypes[HipType] , 0) end
    return
end
return Spawning


--[[ Info 
    Handles Spawnning / Respawning of characters  
]]
