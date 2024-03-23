local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared
local NetworkEvents = Shared.NetworkPartitionEvents
local DictionaryEvents = {}
local CurrentPartition: number

local Connected: UnreliableRemoteEvent
local Network_Handler = {}

function Network_Handler:CheckNetworkPartition(NetworkPartitionNumber: number)    
    if CurrentPartition ~= NetworkPartitionNumber then
        local Event: UnreliableRemoteEvent = DictionaryEvents[NetworkPartitionNumber]
        CurrentPartition = NetworkPartitionNumber 
        Connected =  Event
        return Connected
    end
    return 
end
function Network_Handler:InitEvents(CurrentSection: string)    
    for _ , Events in NetworkEvents:GetDescendants() do
        if Events:IsA("UnreliableRemoteEvent") then
            DictionaryEvents[Events.Name] = Events
        end
    end
end


return Network_Handler


--[[ Info
Module is for Connecting and disconnecting from the Partitioned events
The Network Partitioning will be following ////Octree/// NOT Hexadeca//////// 
A Partition here will be 512x512 
The Partition Event will have a Varadic function attached to it the FunctionName and its args will be recieved through here
Have a dictionary of the functions in a submodule
]]

--[[ Modules needed
Event_Manager
]]
--[[
    From Client {
        the Current partitionNumnber, PartitionCentrePos  of the Client 
        Connect to the Partition Event and disconnect 
        From Map_Manager {
            Disconnect from unrendered Partitions
        }
    }
]]
