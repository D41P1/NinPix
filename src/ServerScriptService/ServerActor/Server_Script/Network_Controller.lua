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
local Event = ReplicatedStorage.FromServer.NotifyEvent
local Map: {Vector3} = Map_Manager:GetMapType("NetworkHashMap")
local Network_Controller = { NetParts = {} }
local PlayerNetParts:{ [string]: { [string]: Player } } = Network_Controller["NetParts"]
local PlayersCurrentNetPartNumber = {}

function Network_Controller:Fire(player: Player, Partition: number, ... : any) 
    local IndexPart = tostring(Partition)
    local players:{ [string]: Player } = Network_Controller:GiveNetPartTable(player, Partition, IndexPart)
    Event_Manager:FireToNetPart(Event, players, ...)
end
function Network_Controller:Insert(player: Player, Partition: number, IndexPart: string)
    local PlayerName: string = player.Name
    Network_Controller:Cleanup(player.Name)
    local T: { [string]: Player }  = PlayerNetParts[IndexPart]
    if not T then T = MakeT(Partition , IndexPart);  end
    T[PlayerName] = player
    Network_Controller:SetPartition(PlayerName, Partition)
    return T    
end 
function Network_Controller:GiveNetPartTable(player: Player, Partition, IndexPart, Raw: boolean?)
    local T = PlayerNetParts[tostring(Partition)]
    if not T and not Raw then  return Network_Controller:Insert(player, Partition, IndexPart)  end
    return T
end
function MakeT(Partition: number, IndexPart: string) PlayerNetParts[IndexPart] = {}; return PlayerNetParts[IndexPart] end

function Network_Controller:Cleanup(playerName: string)
    local NetPartNumber = PlayersCurrentNetPartNumber[playerName]
    local Table = PlayerNetParts[tostring(NetPartNumber)]
    if not Table then return end 
    local Empty = true
    for i: string, V: {[string]: Player} in Table do 
        Empty = false
        break
    end
    if not Empty then return end 
    PlayerNetParts[tostring(NetPartNumber)] =  nil
end
function Network_Controller:FireToPlayer(player: Player,  ... : any) Event_Manager:FireToClient(player, Event, ...) end
function  Network_Controller:GetPosFromNetPartition(PartitionNumber: number) return Map[PartitionNumber] :: Vector3 end
function  Network_Controller:GiveNetMap() return Map :: {Vector3}  end
function Network_Controller:SetPartition(PlayerName: string, Partition: number) PlayersCurrentNetPartNumber[PlayerName] = Partition end
function Network_Controller:GetPartition(PlayerName: string) return PlayersCurrentNetPartNumber[PlayerName] end
return Network_Controller
