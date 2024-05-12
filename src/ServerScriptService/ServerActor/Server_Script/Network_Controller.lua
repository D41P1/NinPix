--!native
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
local Event_Manager = require(Shared.Event_Manager)
-- Use NetworkMap for verification of clients
local NotifyEvent = ReplicatedStorage.FromServer.NotifyEvent
local Map: {Vector3} = Map_Manager:GetMapType("NetworkHashMap")
local Network_Controller = { NetParts = {} }
local PlayerNetParts = Network_Controller["NetParts"]
local PlayersCurrentNetPartNumber = {}

function Network_Controller:Fire(player: Player, Partition: number, ... : any) 
    local players:{ [string]: Player } = Network_Controller:GiveNetPartTable(player, Partition )
    Event_Manager:FireToNetPart(NotifyEvent, players, ...)
end
function Network_Controller.FireToNetPart(Partition: number, ... : any) 
    local players:{ [string]: Player } = Network_Controller.GetNetPartTable(Partition)
    if not players then return end
    Event_Manager:FireToNetPart(NotifyEvent, players, ...)
end
function Network_Controller.FireAllClient(Event: RemoteEvent ,... : any) 
    Event_Manager:FireToAllClients(Event, ...)
end

function Network_Controller:Insert(player: Player, Partition: number)
    local PlayerName: string = player.Name
    Network_Controller:Cleanup(player.Name, Partition)
    local T  = PlayerNetParts[Partition]
    if not T then T = MakeT(Partition);  end
    T[PlayerName] = player
    Network_Controller:SetPartition(PlayerName, Partition)
    return T    
end 
function Network_Controller.GetNetPartTable(Partition)
    local NetTable = PlayerNetParts[Partition]
    local players
    if NetTable then 
        players = PlayerNetParts[Partition].Players
    end
    return players
end
function Network_Controller:GiveNetPartTable(player: Player, Partition, Raw: boolean?)
    local T = PlayerNetParts[Partition]
    if not T and not Raw then  return Network_Controller:Insert(player, Partition)  end
    return T
end
function MakeT(Partition: number)
    local T = {
        Partition = Partition,
        Players = {}
    }; 
    table.insert(PlayerNetParts, T)
    return PlayerNetParts[Partition] 
end
function Network_Controller:Cleanup(playerName: string, Partition)
    local NetPartNumber 
    for NetTable, PlayerTable in PlayerNetParts do
        local NeedlePartition: number = PlayerTable.Partition
        if PlayerTable.Partition ~= Partition then continue end
        NetPartNumber = NeedlePartition
    end
    local Table = PlayerNetParts[NetPartNumber]
    if not Table then return end 
    local Empty = true
    for i: string, V: {[string]: Player} in Table do 
        Empty = false
        break
    end
    if not Empty then return end 
    
    table.remove(PlayerNetParts, NetPartNumber)
end
function Network_Controller:FireToPlayer(player: Player,  Event,... : any) Event_Manager:FireToClient(player, Event, ...) end
function  Network_Controller:GetPosFromNetPartition(PartitionNumber: number) return Map[PartitionNumber] :: Vector3 end
function  Network_Controller:GiveNetMap() return Map :: {Vector3}  end
function Network_Controller:SetPartition(PlayerName: string, Partition: number) PlayersCurrentNetPartNumber[PlayerName] = Partition end
function Network_Controller:GetPartition(PlayerName: string) return PlayersCurrentNetPartNumber[PlayerName] end
return Network_Controller
