local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared

local Task = require(Shared.CustomTask)
local Map_Manager = require(Shared.Map_Manager)
local NetworkMap  = Map_Manager:GetMapType("NetworkHashMap")

local Switches = {}

local function NetworkPartitionCheck(Character: Model)
    if Switches["NetworkCheck"] then
        Task.DelayParallel(12, function()
            Map_Manager:NetworkPartitionCentrePosCheck(Character, NetworkMap)
            NetworkPartitionCheck(Character)
        end)
    else
        Switches["NetworkCheck"] = nil
    end
end

local Checks = {}

function Checks:InitChecks(Character: Model)
    Switches["NetworkCheck"] = ""
    NetworkPartitionCheck(Character)
end

return Checks

--[[Info
This Module is for the frequent checks that will be happening
Like PartitionCentrePos checks etc

Use CustomTask instead of RunService -- for now
recursive delays
]]

