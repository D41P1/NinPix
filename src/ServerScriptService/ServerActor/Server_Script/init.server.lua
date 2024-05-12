--[[TODO
grab data here and send to Init_Handler with Task.Delay
SendCharacterAvatar Data all numbers
Remove Characters Box {
    Only calculating Pos now no need for Box
}
Tag player with UID        

P R I O R I T Y:
Make ServerRayScript from RayScript 
CharacterScript will be making these Scripts and init them

]]


local ServerTypes = require(script.ServerTypes)
local Players = game:GetService("Players")
Players.CharacterAutoLoads = false
local PhysicsService = game:GetService("PhysicsService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local CollectionService = game:GetService("CollectionService")

local Shared = ReplicatedStorage.Shared
local CharacterActors = workspace.WorkSpaceFolder.CharacterActors
local CharacterActor = script.CharacterActor
local FromServer = ReplicatedStorage.FromServer
PhysicsService:RegisterCollisionGroup("Characters")
PhysicsService:CollisionGroupSetCollidable("Characters", "Characters", false)
local Cleanup_Manager = require(Shared.Cleanup_Manager)
local Task = require(Shared.CustomTask)
local Attributes_Controller = require(script.Attributes_Controller)
local MessageAPI = require(script.MessageAPI); MessageAPI.InitSSS()
local CharacterBox = require(script.CharacterBox)
local Network_Controller = require(script.Network_Controller)
local ServerTick = require(script.ServerTick); ServerTick.InitSSS()

local LoadClient = FromServer.LoadClient
-- local LoadOther = FromServer.LoadOther

-- "qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDFGHJKLZXCVBNM1234567890!:@~<>?}]~#;-+=&"
local charset = "qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDFGHJKLZXCVBNM1234567890!:@~<>?}]~#;-+=&)|/.,_`'" -- 84
function randomString(length)
	local result = {}
	local charsetLength = #charset
	for i = 1, length do local randomIndex = math.random(1, charsetLength); table.insert(result, charset:sub(randomIndex, randomIndex)) end
	local UID = table.concat(result)
    local Find
    local Success, Error = pcall(function(...)  Find = string.gsub(charset, UID, "") end)
    if not Success then print("Error with UID making: \n|\n", Error) end 
    charset = Find
    return UID
end
function GUID(Length): string
	local UID:string = randomString(Length)
	-- local check = CollectionService:GetTagged(UID)
	-- if #check > 0 then  GUID(Length) else return UID :: string end
    return UID
end
local NetMap = Network_Controller:GiveNetMap()
Players.PlayerAdded:Connect(function(player)
    local UID = GUID(1)
    -- player:AddTag(UID)    
    Cleanup_Manager:Profile(UID)
    Attributes_Controller:InitAttributes(player, {}, UID,true)
    local NetPartNumber = player:GetAttribute("NetworkPartition")
    task.synchronize()
    local Character = ServerStorage.Hitbox.Humanoid:Clone()
    Attributes_Controller:CharacterAttributes(Character, "Humanoid")
    -- Character:AddTag(UID)-- REMOVE ????

    local Pos = NetMap[NetPartNumber]  
    -- Character.Body.Position =  
    Character.Name = player.Name
    Character.Parent = workspace.CurrentCamera 
    Character:SetAttribute("UID", UID)
    CharacterBox[player.Name] = Character
    
    local CharacterActor = CharacterActor:Clone()
    CharacterActor.Name = player.Name
    local CharacterScript = CharacterActor.Character_Script
    CharacterScript.Enabled = true  
    CharacterActor.Parent = CharacterActors 

    local Walkspeed = 14 -- TODO change with Data
    Task.Delay(7,function()
        Network_Controller.FireAllClient(LoadClient, 2.7, UID, Pos, Walkspeed)
    end)
    Task.Delay(1.5, function()
        CharacterActor:SendMessage("Init", {
            ["CurrentCF"] = CFrame.new(Pos),
            ["WS"] = Walkspeed,
            ["UID"]= UID
        })
    end)
    MessageAPI.Players[player.Name] = player
    ServerTick.InitPlayerProfile(player.Name, UID, Pos + Vector3.new(0, 2.7, 0))
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
    charset = charset..UID
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