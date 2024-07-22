--!native
--* Most or All Communication between Server Actors
local SSS = game:GetService("ServerScriptService")
-- local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SSSActor = SSS.Server.ServerActor
local SScript = SSSActor.Server_Script
local CombatActor = SScript.CombatActor
local HealthActor = SScript.HealthActor
local PostureActor = SScript.PostureActor

local FromServer = ReplicatedStorage.FromServer
local NPCMakeEvent = FromServer.NPCMakeEvent

local MessageAPI = {
    Players = {
        --playerName = player
    }
}
function MessageAPI.SendToSSS(Topic: string, ...)
    SSSActor:SendMessage(Topic, ...)
end

function MessageAPI.SendToCombat(Topic: string, ...)
    CombatActor:SendMessage(Topic, ...)
end
function MessageAPI.SendToHealth(Topic: string, ...)
    HealthActor:SendMessage(Topic, ...)
end
function MessageAPI.SendToPosture(Topic: string, ...)
    PostureActor:SendMessage(Topic, ...)
end
local CharacterActors = {}
local NPCActors = {}
local Connections = {}
function MessageAPI.InitSSS()
    local SSScript = SSSActor.Server_Script
    local Shared = ReplicatedStorage.Shared
    local Attributes_Controller = require(SSScript.Attributes_Controller)
    local Util = require(script.Parent.Util)
    local NetWorkController = require(SSScript.Network_Controller)    
    local ServerTick = require(SSScript.ServerTick)
    local NPCRunTimeFolder = SSScript.NPCRunTimeActors

    local SharedType = require(Shared.SharedType)
    local NPCInfo = require(Shared.NPCInfo)

    local NPCs = {
        ["Bandit"] = {
            ["Max"] = 3,
            ["Array"] = {}
        },
        ["Dummy"] = {
            ["Max"] = 1,
            ["Array"] = {}
        },
        ["HitDummy"] = {
            ["Max"] = 1,
            ["Array"] = {}
        }
    }
    local NPCSpawnPoints = workspace.NPCSP
    Connections["Network"] = SSSActor:BindToMessageParallel("Network", function(PlayerName, Partition,...)
        local player: Player = MessageAPI.Players[PlayerName]
        local CurrentPartition = Partition or NetWorkController:GetPartition(PlayerName)
        NetWorkController:Fire(player, CurrentPartition, ...)
    end)    
    Connections["NetPart"] = SSSActor:BindToMessageParallel("NetPart", function(PlayerName, Partition,...)
        NetWorkController:SetPartition(PlayerName, Partition)
    end)
    Connections["TriggerAction"] = SSSActor:BindToMessageParallel("TriggerAction", function(UID, ...)
        local CharActor:Actor = CharacterActors[UID]
        if not CharActor then warn("Did not get actor"); return end  
        CharActor:SendMessage("TriggerAction", UID, ...)
    end)
    Connections["SpawnNPC"] = SSSActor:BindToMessageParallel("SpawnNPC", function(TypeOfNPC, TypeFSM:string, TypePathFinding:string, NPCId: number) 
        if NPCs[TypeOfNPC] and #NPCs[TypeOfNPC].Array >= NPCs[TypeOfNPC].Max then return end
        local UID:string = Util.GUID(1)
        local R = math.random
        local SpawnPointsFolder:Folder = NPCSpawnPoints[TypeOfNPC]
        local SpawnPoints:{Instance} = SpawnPointsFolder:GetChildren()
        local Part = SpawnPoints[R(1, #SpawnPoints)]
        local RR = Util.FindGround(Part)
        if not RR then warn("Did not Find Ground NPC Spawn Point", Part.Position); return end
        local Data = {
            ["SpawnPoint"] = RR.Position,
            ["TypePathFinding"] = TypePathFinding,
            ["TypeFSM"] = TypeFSM,
            ["Hip"] = Attributes_Controller.GiveHip(TypeOfNPC)
        }
        SSSActor:SendMessage("MakeNPC", UID, Data)
        table.insert(NPCs[TypeOfNPC].Array, UID)
        task.synchronize()
        local SpawnPart = tonumber(Part.Name)
        local b = buffer.create(4)
        buffer.writestring(b, 0, UID, 1)
        buffer.writeu8(b, 1, SpawnPart)
        buffer.writeu16(b, 2 , NPCId)
        NPCMakeEvent:FireAllClients(b)
    end)
    Connections["MakeNPC"] = SSSActor:BindToMessageParallel("MakeNPC", function(UID, Data: SharedType.InitNPCData)
        --* NPCActor made the CombatFSM and MovementActors
        task.synchronize()
        local NPCData:SharedType.NPCData = NPCInfo[Data.TypeFSM]
        local NPCActor = SSScript.NPCActor:Clone()
        NPCActor.NPC_Script.Enabled = true
        NPCActor.Name = UID
        MessageAPI.AddCharacterActor(NPCActor)
        MessageAPI.AddNPCActor(NPCActor)
        MessageAPI.SendToHealth("Create", UID, NPCData.Health)
        MessageAPI.SendToPosture("Create", UID, NPCData.Posture)        
        local SpawnPos = Data.SpawnPoint + Vector3.new(0, NPCData.Hip, 0)
        ServerTick.InitMovementProfile(UID, SpawnPos)
        task.delay(1, function()
            Data.CurrentCF = CFrame.new(SpawnPos) 
            NPCActor:SendMessage("Init", UID, Data)
        end)
        task.synchronize()
        NPCActor.Parent = NPCRunTimeFolder  
        print("MakingNPC Type: ", Data.TypeFSM, UID)
    end)
end
function MessageAPI.InitServerCharacter(CharacterActor: Actor)    
    local ForwardActor = script.Parent.ServerMoveActor:Clone()
    ForwardActor.Name = "ForwardActor"
    ForwardActor.ServerRayScript.Enabled = true
    ForwardActor.Parent = CharacterActor

    local DownActor = script.Parent.ServerMoveActor:Clone()
    DownActor.Name = "DownActor"
    DownActor.ServerRayScript.Enabled = true
    DownActor.Parent = CharacterActor

    return ForwardActor, DownActor
end
function MessageAPI.AddPlayer(player: Player)
    MessageAPI.Players[player.Name] = player
end
function MessageAPI.AddCharacterActor(CharActor: Actor)
    CharacterActors[CharActor.Name] = CharActor
end
function MessageAPI.AddNPCActor(NPCActor: Actor)
    NPCActors[NPCActor.Name] = NPCActor
end
function MessageAPI.GiveCharActors() return CharacterActors end
function MessageAPI.GiveNPCActors() return NPCActors end
function MessageAPI.Cleanup(UID, PlayerName) 
    local Players = MessageAPI.Players
    if NPCActors[UID] then NPCActors[UID]:Destroy();  NPCActors[UID] = nil end
    if CharacterActors[UID]then CharacterActors[UID]:Destroy();  CharacterActors[UID] = nil end
    if PlayerName and Players[PlayerName] then Players[PlayerName] = nil end
end
return MessageAPI