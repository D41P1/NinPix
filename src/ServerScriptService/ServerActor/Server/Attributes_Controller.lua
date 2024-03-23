--[[ Handles Player Attributes
]]

local Shared = game:GetService("ReplicatedStorage").Shared
local CleanupManager = require(Shared.Cleanup_Manager) 
local Task = require(Shared.CustomTask)
local Respawn_Controller = require(script.Parent.Respawn_Controller)
local Attributes_Controller = {}
local function AttributeConnections(player: Player)
    CleanupManager:Insert(player:GetAttributeChangedSignal("Health"):ConnectParallel(function()  
        local Health = player:GetAttribute("Health")
        if Health <= 0 then
            Respawn_Controller:Respawn(player)

            Task.Delay(3, function() Attributes_Controller:InitAttributes(player, {}) end)
        end
    end))
end


function Attributes_Controller:InitAttributes(player: Player, Data, Connect: boolean?) -- TODO future data affects attributes
    local NetworkPartition = 1 
    player:SetAttribute("Health", 100)
    player:SetAttribute("Section", 1)-- 1-4    
    player:SetAttribute("NetworkPartition", NetworkPartition) -- 1-16
    
    local PossiblePartitions = {
        [1] = NetworkPartition , 
        [2] = NetworkPartition + 1,
        [3] = NetworkPartition + 8,
        [4] = NetworkPartition + 8 + 1
    }
    player:SetAttribute("RenderPartition", PossiblePartitions[math.random(1, 4)]) 
 


    if Connect then AttributeConnections(player) end 
end


return Attributes_Controller