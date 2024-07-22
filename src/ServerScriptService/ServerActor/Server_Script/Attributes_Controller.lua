--[[ Handles Player Attributes
]]
local Shared = game:GetService("ReplicatedStorage").Shared
local CleanupManager = require(Shared.Cleanup_Manager) 
local Task = require(Shared.CustomTask)
local Respawn_Controller = require(script.Parent.Respawn_Controller)
-- Function to generate a random string of a given length

local Attributes_Controller = {
    ["Humanoid"] = {
        BodyType = "Humanoid",
        Hip = 2.7
    },
}
Attributes_Controller["Dummy"] = Attributes_Controller.Humanoid
Attributes_Controller["HitDummy"] = Attributes_Controller.Humanoid


local function AttributeConnections(player: Player)
    local UID = player:GetAttribute("UID")
    CleanupManager:Insert(UID, player:GetAttributeChangedSignal("Health"):ConnectParallel(function()  
        local Health = player:GetAttribute("Health")
        if Health <= 0 then
            Respawn_Controller:Respawn(player)
            Task.Delay(3, function() Attributes_Controller:InitAttributes(player, {}) end)
        end
    end))
end
function Attributes_Controller:InitAttributes(player: Player?, Data, UID: string?,Connect: boolean?) -- TODO future data affects attributes
    local NetworkPartition = 1
    if not player then return end
    --mainly for Combat Machine these attributes 
    player:SetAttribute("Health", 100)
    player:SetAttribute("NetworkPartition", NetworkPartition) -- 1-64
    player:SetAttribute("UID", UID)
    player:SetAttribute("WalkSpeed", Data.WalkSpeed)
    player:SetAttribute("BaseWalkSpeed", Data.WalkSpeed)
    player:SetAttribute("WallRun", true)
    if Connect then AttributeConnections(player) end 
    return UID
end
type HipTable  = {
    BodyType: string,
    Hip:number
}
function Attributes_Controller.GiveHip(BodyType:string)
    local T:HipTable = Attributes_Controller[BodyType]
    if not  T then warn("Invalid BodyType: ", BodyType, "\n: ", Attributes_Controller); return end
    return T.Hip
end
function Attributes_Controller:CharacterAttributes(Character: Model, BodyType: string)
    for AttributeName, AttributeValue in Attributes_Controller[BodyType] do Character:SetAttribute(AttributeName, AttributeValue) end
end
return Attributes_Controller