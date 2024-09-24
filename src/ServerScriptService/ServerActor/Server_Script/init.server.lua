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
-- local Task = require(Shared.CustomTask)

local Attributes_Controller = require(script.Attributes_Controller)
local MessageAPI = require(script.MessageAPI); MessageAPI.InitSSS()
local CharacterBox = require(script.CharacterBox)
local Data_Controller = require(script.Data_Controller)
local Util = require(script.Util)
-- local Network_Controller = require(script.Network_Controller)

local ServerTick = require(script.ServerTick); ServerTick.InitSSS()
local LoadClient = FromServer.LoadClient
local LoadCombat = FromServer.LoadCombat
local LoadStat = FromServer.LoadStat
local StartLoading = FromServer.Start
MessageAPI.SendToHealth("Init")
MessageAPI.SendToPosture("Init")
MessageAPI.SendToRagdoll("Init")
-- MessageAPI.SendToPosture("Init")
--// "qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDFGHJKLZXCVBNM1234567890!:@~<>?}]~#;-+=&"
-- local NetMap = Network_Controller:GiveNetMap()
Players.PlayerAdded:Connect(function(player)
    --* data stuff
    local ActiveSlotNumberBuffer = Data_Controller.Get_ActiveSlot(player)
    local ActiveSlotNum = buffer.readu8(ActiveSlotNumberBuffer, 0)
    Data_Controller.Get_SlotDS( ActiveSlotNum )
    local Avatar_Buffer, AvatarRGB_Buffer = Data_Controller.GetPlayerAvatarData(player, ActiveSlotNum)
    if not Avatar_Buffer then return end
    local InventoryBuffer = Data_Controller.Get_Player_Inventory_Data(player, ActiveSlotNum)
    if not InventoryBuffer then return end
    
    --TODO REMOVE
    local Buffer = buffer.create(buffer.len(InventoryBuffer) + 4)
    buffer.writeu16(Buffer, 44, 1000)
    buffer.writeu16(Buffer, 46, 3)
    -- buffer.writeu16(InventoryBuffer, 0, 1000)
    buffer.copy(Buffer, 0, InventoryBuffer, 0, buffer.len(InventoryBuffer))
    InventoryBuffer = Buffer
    --TODO REMOVE 

    local Table_buffers:Data_Controller.DataBuffer = {
        ["AvatarBuffer"] = Avatar_Buffer,
        ["AvatarRGBBuffer"] = AvatarRGB_Buffer,
        ["InventoryBuffer"] = InventoryBuffer,
        ["ActiveSlot_Num_Buffer"] = ActiveSlotNumberBuffer
    }
    Data_Controller.Add_To_Profiles(player, Table_buffers)
    --* let the Util Strings load
    local UID:string = Util.GUID(1, 1, 30)
    warn(UID)
    Cleanup_Manager:Profile(UID)
    task.synchronize()
    player:AddTag(UID)
    local CharacterActor = CharacterActor:Clone()
    CharacterActor:SetAttribute("UID", UID)
    CharacterActor.Name = UID
    local CharacterScript = CharacterActor.Character_Script
    CharacterScript.Enabled = true  
    CharacterActor.Parent = CharacterActors 
    StartLoading:FireClient(player) --* <---------------------------- IMPORTANT 

    --[[ --TODO
    *make Spawn in centre map slighlty randomly offsetted by like 20-40 studs in x,z
    *add this in MessageAPI RespawnPlayer (NPCs will not respawn use CleanNPC instead)
    
    ]]
    Attributes_Controller:InitAttributes(player, UID, true)    
    -- local NetPartNumber = player:GetAttribute("NetworkPartition")
    local RRPos = Util.SpawnPoint()
    if not RRPos then player:Kick("error with spawn"); warn("Error with RRPos"); return end
    local Pos =   RRPos.Position 

    local Hip = 5
    local Base_Health = 100
    local Base_Posture = 200
    
    -- local Writeu16 = buffer.writeu16
    local Writeu8 = buffer.writeu8
    local Writef32 = buffer.writef32
    
    task.delay(7,function()
        if not player then return end
        task.synchronize()
        local LoadClient_Buffer = buffer.create(13)
        Writeu8(LoadClient_Buffer, 0, UID)
        Writef32(LoadClient_Buffer, 1, Pos.X)
        Writef32(LoadClient_Buffer, 5, Pos.Y)
        Writef32(LoadClient_Buffer, 9, Pos.Z)
        LoadClient:FireAllClients(LoadClient_Buffer, Table_buffers.AvatarBuffer, Table_buffers.AvatarRGBBuffer)

        RunService.Heartbeat:Wait()
        local InventoryBuffer = Table_buffers.InventoryBuffer 
        local Inventory_Toolbar = buffer.create(buffer.len(InventoryBuffer) + 1) --* (1 byte --UID) + 44+bytes --(2 loadouts: 0-30 u16) --(BodyFrame 32-42 u16)
        Writeu8(Inventory_Toolbar, 0, UID)
        buffer.copy(Inventory_Toolbar, 1,  InventoryBuffer, 0, buffer.len(InventoryBuffer))
        CharacterActor:SendMessage("InitHotbarInfo", InventoryBuffer)
        LoadCombat:FireAllClients(Inventory_Toolbar)        
        LoadStat:FireAllClients()
        --* everyone base stats are 100 health 200 posture equipment can only change it
    end)
    task.delay(2, function()
        if not CharacterActor then return end --* could leave early
        MessageAPI.SendToHealth("Create", UID, Base_Health) 
        MessageAPI.SendToPosture("Create", UID, Base_Posture) -- TODO TEST THIS
        CharacterActor:SendMessage("Init", UID, {
            ["CurrentCF"] = CFrame.new(Pos),
        })
    end)
    MessageAPI.AddCharacterActor(CharacterActor)
    ServerTick.InitMovementProfile(UID, Pos + Vector3.new(0, Hip, 0), "Player")
    Cleanup_Manager:Insert(UID, CharacterActor)
end)
Cleanup_Manager:InsertTable("PlayerMessageAPI", MessageAPI.Players)
Cleanup_Manager:InsertTable("CharBox", CharacterBox)
Players.PlayerRemoving:ConnectParallel(function(player: Player)  
    local UID = player:GetAttribute("UID")
    local PlayerName: string = player.Name
    task.wait(7)    
    local Success, Error = pcall(function()
        Cleanup_Manager:Start(UID)
        Cleanup_Manager:CleanTable("PlayerMessageAPI", PlayerName)
        Cleanup_Manager:CleanTable("CharBox", PlayerName)
        --// Network_Controller:Cleanup(PlayerName)
        MessageAPI.SendToHealth("Cleanup", UID)
        MessageAPI.SendToPosture("Cleanup", UID)

        Util.Cleanup(UID)
        MessageAPI.Cleanup(UID)
        Data_Controller.Cleanup(PlayerName)
        local ArrayPlayers = Players:GetPlayers()
        print("players array",ArrayPlayers)
        if #ArrayPlayers <= 1 then 
            Data_Controller.Save_allPlayers_Data()
        end
    end)
    if not Success then 
        warn("Error Cleaning Player REPORT ASAP to Discord: ", Error)
        return 
    end
end)
do
    local D, S = 0, 0.2 +1e-6
    local RBX = RunService.Heartbeat:ConnectParallel(function(a0: number)  
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

--* init here cos it yields
Data_Controller.init()



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