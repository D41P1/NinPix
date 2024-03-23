--[[Info
This Module is for Sending / Relaying the Data received From Character_Controller 
Relaying the Data to the Other Clients   
]]
--[[
    Map_Manager
    Event_Manager
]]

--[[
    Use Map_Manager to init the Network Partitions (512x512)
    init all the Network Partition events 16 per section
    Fire To Network Partition Method 
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage") 
local Shared = ReplicatedStorage.Shared
local Map_Manager = require(Shared.Map_Manager)


-- Use NetworkMap for verification of clients
local Map: {{Vector3}} = Map_Manager:GetMapType("NetworkHashMap")

local NetworkEvents = {
    [1] = {},
    [2] = {},
    [3] = {},
    [4] = {},
}
local Network_Controller = {}

function Network_Controller:InitNetworkPartitionEvents()
    for SectionNumber = 1, 4 do
        for Amount = 1, 16 do 
            local Event = Instance.new("UnreliableRemoteEvent")
            Event.Name = tostring(Amount)-- for client syncing
            NetworkEvents[SectionNumber][Amount] = Event
            Event.Parent = Shared.NetworkPartitionEvents["Section"..SectionNumber]
        end
    end    
end

return Network_Controller