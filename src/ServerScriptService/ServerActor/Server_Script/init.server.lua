local ServerTypes = require(script.ServerTypes)
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
Players.CharacterAutoLoads = false
local PhysicsService = game:GetService("PhysicsService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local CollectionService = game:GetService("CollectionService")

local Shared = ReplicatedStorage.Shared
local CharacterActors = workspace.WorkSpaceFolder.CharacterActors
local CharacterActor = script.CharacterActor
PhysicsService:RegisterCollisionGroup("Characters")
PhysicsService:CollisionGroupSetCollidable("Characters", "Characters", false)
local Cleanup_Manager = require(Shared.Cleanup_Manager)
local Task = require(Shared.CustomTask)
local Attributes_Controller = require(script.Attributes_Controller)

local MessageAPI = require(script.MessageAPI); MessageAPI.InitSSS()
local CharacterBox = require(script.CharacterBox)
-- local Spawning = require(script.Character_Controller.Spawning) -- TODO DELETE THIS MODULE
local Network_Controller = require(script.Network_Controller)
-- MessageAPI

local charset = "qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDFGHJKLZXCVBNM1234567890"
function randomString(length)
	local result = {}
	local charsetLength = #charset
	for i = 1, length do local randomIndex = math.random(1, charsetLength); table.insert(result, charset:sub(randomIndex, randomIndex)) end
	return table.concat(result)
end
function GUID(Length): string
	local UID:string = randomString(Length)
	local check = CollectionService:GetTagged(UID)
	if #check > 0 then  GUID(Length) else return UID :: string end
    return ""
end
local NetMap = Network_Controller:GiveNetMap()
Players.PlayerAdded:Connect(function(player)
    local UID = GUID(2)
    Cleanup_Manager:Profile(UID)
    Attributes_Controller:InitAttributes(player, {}, UID,true)
    local NetPartNumber = player:GetAttribute("NetworkPartition")
    task.synchronize()
    local Character = ServerStorage.Hitbox.Humanoid:Clone()
    Attributes_Controller:CharacterAttributes(Character, "Humanoid")
    
    Character:AddTag(UID)-- REMOVE ????

    Character.Body.Position = NetMap[NetPartNumber] + Vector3.new(0, 2.7, 0) 
    Character.Name = player.Name
    Character.Parent = workspace.CurrentCamera 
    Character:SetAttribute("UID", UID)
    CharacterBox[player.Name] = Character
    
    --grab data here and send to Init_Handler with Task.Delay

    local CharacterActor = CharacterActor:Clone()
    CharacterActor.Name = player.Name
    local CharacterScript = CharacterActor.Character_Script
    CharacterScript.Enabled = true  
    CharacterActor.Parent = CharacterActors 

    local PlayerNetPartTable = Network_Controller:GiveNetPartTable(player, NetPartNumber, tostring(NetPartNumber), true)    
    Network_Controller:Insert(player, NetPartNumber, tostring(NetPartNumber))
    -- local T =DateTime.now().UnixTimestampMillis

    Task.Delay(8,function()
        -- make a new event for this cos CharacterController in a new Actor
        -- Network_Controller:Fire(player, NetPartNumber, "L", NetPartNumber, 2.7, UID) -- PlayerNetPartTable it makes one
        if not PlayerNetPartTable then return end 
        -- means theres players there already
        for playerName: any, Box: any in CharacterBox do
            local OtherCharUID = Box:GetAttribute("UID") 
            local CurrentPos = Box.Body.Position + Vector3.new(0, -2.7, 0) -- 2.7 gets added again on Client  
            Network_Controller:Fire(player, NetPartNumber, "L", NetPartNumber, 2.7, OtherCharUID, CurrentPos)
            -- Network_Controller:Fire(player, NetPartNumber, "T",  OtherCharUID, CurrentPos)
        end
        print("fired Late joined Pre loaded NetPart")
        --[[TODO
            SendCharacterAvatar Data all numbers
        ]]
    end)
    MessageAPI.Players[player.Name] = player
    Cleanup_Manager:Insert(UID, Character)
    Cleanup_Manager:Insert(UID, CharacterActor)
end)
Cleanup_Manager:InsertTable("PlayerNetParts", Network_Controller.NetParts)
Cleanup_Manager:InsertTable("PlayerMessageAPI", MessageAPI.Players)
Cleanup_Manager:InsertTable("CharBox", CharacterBox)
Players.PlayerRemoving:ConnectParallel(function(player: Player)  
    local UID = player:GetAttribute("UID")
    Cleanup_Manager:Start(UID)
    local PlayerName: string = player.Name
    Cleanup_Manager:CleanTable("PlayerNetParts", PlayerName)
    Cleanup_Manager:CleanTable("PlayerMessageAPI", PlayerName)
    Cleanup_Manager:CleanTable("CharBox", PlayerName)
    Network_Controller:Cleanup(PlayerName)
end)





--[[ Modules needed
CustomTask
Data_Controller
Character_Controller
]]
--[[type Data Template
{
    MapLocation = { -- spawn them at the centre of partition
        Partition: number
    }
    CharactersAvatar = {
        Hair, Eyes, Face, Shirt, Pants,
        Armour?, Accessories?,
    }
    Inventory {
        [ItemName]: number -- number of items

}

]]

--[[
    when player joins:
    get playerdata -> EventManager write buffer -> Client 
    CharacterActor.Character_Script {
        Clone and enable the script 
        and parent to the CharacterActorsFolder
    } 
    
]]