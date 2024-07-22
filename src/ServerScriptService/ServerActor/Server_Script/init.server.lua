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
-- local ServerTypes = require(script.ServerTypes)

local Players = game:GetService("Players")
Players.CharacterAutoLoads = false

local PhysicsService = game:GetService("PhysicsService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RunService = game:GetService("RunService")
local Shared = ReplicatedStorage.Shared
local CharacterActors = workspace.WorkSpaceFolder.CharacterActors
local CharacterActor = script.CharacterActor
local FromServer = ReplicatedStorage.FromServer
PhysicsService:RegisterCollisionGroup("Characters")
PhysicsService:CollisionGroupSetCollidable("Characters", "Characters", false)
local Cleanup_Manager = require(Shared.Cleanup_Manager)
local Task = require(Shared.CustomTask)
-- local Encyclopedia = require(Shared.Encyclopedia)

local Attributes_Controller = require(script.Attributes_Controller)
local MessageAPI = require(script.MessageAPI); MessageAPI.InitSSS()
local CharacterBox = require(script.CharacterBox)
local Util = require(script.Util)
local Network_Controller = require(script.Network_Controller)

local ServerTick = require(script.ServerTick); ServerTick.InitSSS()
local LoadClient = FromServer.LoadClient
local LoadCombat = FromServer.LoadCombat
local LoadStat = FromServer.LoadStat
MessageAPI.SendToHealth("Init")


--// "qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDFGHJKLZXCVBNM1234567890!:@~<>?}]~#;-+=&"

local NetMap = Network_Controller:GiveNetMap()
Players.PlayerAdded:Connect(function(player)
    task.wait(2)
    local UID = Util.GUID(1)
    Cleanup_Manager:Profile(UID)
    task.synchronize()
    local CharacterActor = CharacterActor:Clone()
    CharacterActor:SetAttribute("UID", UID)
    CharacterActor.Name = UID
    local CharacterScript = CharacterActor.Character_Script
    CharacterScript.Enabled = true  
    CharacterActor.Parent = CharacterActors 

    local Data = { --* Pretend data for now
        WalkSpeed = 12,
        Hip = 2.7,
        Skills = {
            --Jutsus and weapon Skills
        },
        HotBar1 = {
            --["One"] = 1101 --* Reference for item or weapon jutsu etc
            ["One"] = 1000 -- sword ref
        },
        HotBar2 = {}, 
        PlayerStats = { --TODO add Fake PlayerStats Health, Attack, Speed,  ...etc 
            Health = 100,
            Posture = 200
        },
        Inventory = {}
    }
    Attributes_Controller:InitAttributes(player, Data, UID,true)
    
    local NetPartNumber = player:GetAttribute("NetworkPartition")
    local Pos = NetMap[NetPartNumber]  
    
    local Walkspeed = Data.WalkSpeed -- TODO change with Data
    local Hip = Data.Hip
    local HotBar1 = Data.HotBar1
    local HotBar2    = Data.HotBar2
    local Writeu16 = buffer.writeu16

    Task.Delay(7,function()
        Network_Controller.FireAllClient(LoadClient, Hip, UID, Pos, Walkspeed)
        RunService.Heartbeat:Wait()
        local b = buffer.create(33) --UID = 1  8 *2 *2 = (Keys) *(bytes)  *(loadouts
        buffer.writestring(b, 0, UID, 1)
        local offset = 1
        for _ , NumberReference: number in HotBar1 do  Writeu16(b, offset, NumberReference); offset += 2 end       
        for _ , NumberReference: number in HotBar2 do  Writeu16(b, offset, NumberReference); offset += 2 end       
        CharacterActor:SendMessage("InitHotbarInfo", b)
        LoadCombat:FireAllClients(b)
        local StatB = buffer.create(8)
        Writeu16(StatB, 0, Data.PlayerStats.Health)
        Writeu16(StatB, 2, Data.PlayerStats.Posture)
        LoadStat:FireAllClients(StatB)
    end)
    Task.Delay(2, function()
        MessageAPI.SendToHealth("Create", UID, Data.PlayerStats.Health) 
        MessageAPI.SendToPosture("Create", UID, Data.PlayerStats.Posture) -- TODO TEST THIS
        CharacterActor:SendMessage("Init", UID, {
            ["CurrentCF"] = CFrame.new(Pos),
            ["WalkSpeed"] = Walkspeed,
            ["Hip"] = Hip
        })
    end)
    MessageAPI.AddPlayer(player)
    MessageAPI.AddCharacterActor(CharacterActor)
    ServerTick.InitMovementProfile(UID, Pos + Vector3.new(0, Hip, 0))
    Cleanup_Manager:Insert(UID, CharacterActor)
end)

Cleanup_Manager:InsertTable("PlayerNetParts", Network_Controller.NetParts)
Cleanup_Manager:InsertTable("PlayerMessageAPI", MessageAPI.Players)
Cleanup_Manager:InsertTable("CharBox", CharacterBox)
Players.PlayerRemoving:ConnectParallel(function(player: Player)  
    local UID = player:GetAttribute("UID")
    local PlayerName: string = player.Name
    Cleanup_Manager:Start(UID)
    Cleanup_Manager:CleanTable("PlayerNetParts", PlayerName)
    Cleanup_Manager:CleanTable("PlayerMessageAPI", PlayerName)
    Cleanup_Manager:CleanTable("CharBox", PlayerName)
    Network_Controller:Cleanup(PlayerName)
    MessageAPI.SendToHealth("Cleanup", UID)
    Util.CleanCharSet(UID)
    MessageAPI.Cleanup(UID, PlayerName)
end)



do
    local D, S = 0, 0.2 +1e-6
    local T = RunService.Heartbeat:ConnectParallel(function(a0: number)  
        D += a0
        if D >= S then 
            D-= S
            local T = MessageAPI.GiveNPCActors()
            for _, Actors in T do 
                Actors:SendMessage("Tick")
            end
        end
    end)    
end






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