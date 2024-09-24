--!native
--* Most or All Communication between Server Actors
--* should have easy access to all Actors in the server
local SSS = game:GetService("ServerScriptService")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SSSActor = SSS.Server.ServerActor
local SScript = SSSActor.Server_Script
local CombatActor = SScript.CombatActor
local HealthActor = SScript.HealthActor
local PostureActor = SScript.PostureActor
local RagdollActor = SScript.RagdollActor
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
function MessageAPI.SendToRagdoll(Topic: string, ...)
    RagdollActor:SendMessage(Topic, ...)
end

local CharacterActors = {}
local NPCActors = {}
local Connections = {}
function MessageAPI.InitSSS()
    local SSScript = SSSActor.Server_Script
    local Shared = ReplicatedStorage.Shared
    local Hitbox = require(Shared.Hitbox)
    local Attributes_Controller = require(SSScript.Attributes_Controller)
    local Util = require(script.Parent.Util)
    local NetWorkController = require(SSScript.Network_Controller)    
    local ServerTick = require(SSScript.ServerTick)
    local NPCRunTimeFolder = SSScript.NPCRunTimeActors
    local SharedType = require(Shared.SharedType)
    local NPCInfo = require(Shared.NPCInfo)

    
    local NPCs = {
        ["ShadoMercenary"] = {
            ["Max"] = 25, --*3 Prod for now
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
    Connections["TriggerAction"] = SSSActor:BindToMessageParallel("TriggerAction", function(UID: string, ...)
        UID =  tostring(UID)
        local CharActor:Actor = CharacterActors[UID]
        if not CharActor then warn("Did not get actor"); return end  
        CharActor:SendMessage("TriggerAction", UID, ...)
    end)
    Connections["RespawnPlayer"] = SSSActor:BindToMessageParallel("RespawnPlayer", function(UID: string, ...)
        UID =  tostring(UID)
        local CharActor:Actor = CharacterActors[UID]
        if not CharActor then warn("Did not get actor"); return end  
        CharActor:SendMessage("RespawnPlayer", UID, ...)
        local Args = ...
        task.delay(6, function()
            MessageAPI.SendToHealth("RespawnPlayer", UID, Args)
            MessageAPI.SendToPosture("RespawnPlayer", UID, Args)        
        end)
    end)
    Connections["Knockback"] = SSSActor:BindToMessageParallel("Knockback", function(UID:string, ...)
        UID =  tostring(UID)
        local CharActor:Actor = CharacterActors[UID]
        if not CharActor then warn("Did not get actor"); return end  
        CharActor:SendMessage("Knockback", ...)
    end)
    Connections["Pushback"] = SSSActor:BindToMessageParallel("Pushback", function(UID:string, ...)
        UID = tostring(UID)
        local CharActor:Actor = CharacterActors[UID]
        if not CharActor then warn("Did not get actor"); return end  
        CharActor:SendMessage("Pushback", ...)
    end)
    --TODO change NPC UID make process to something simialr to Players starting from number 32 --> 92
    Connections["SpawnNPC"] = SSSActor:BindToMessageParallel("SpawnNPC", function(TypeOfNPC, TypeFSM:string, TypePathFinding:string, NPCId: number) 
        if not NPCs[TypeOfNPC] then warn("add NPC HERE message API: ", TypeOfNPC); return end 
        if #NPCs[TypeOfNPC].Array >= NPCs[TypeOfNPC].Max then return end
        local UID = Util.GUID(1, 31, 256)
        local R = math.random
        local SpawnPointsFolder = NPCSpawnPoints[TypeOfNPC]
        local SpawnPoints:{BasePart} = SpawnPointsFolder:GetChildren()
        local Part:BasePart = SpawnPoints[R(1, #SpawnPoints)]
        local PartPos = Part.Position + Vector3.new(math.random(5, 25),0, math.random(5, 25))
        local RR = Hitbox:Raycasting(PartPos, PartPos + Vector3.new(0, -1, 0), 100) --Util.FindGround(Part)
        if not RR then warn("Did not Find Ground NPC Spawn Point", PartPos); return end
        local Data = {
            ["SpawnPoint"] = RR.Position,
            ["TypePathFinding"] = TypePathFinding,
            ["TypeFSM"] = TypeFSM,
        ["Hip"] = Attributes_Controller.GiveHip(TypeOfNPC)
        }
        SSSActor:SendMessage("MakeNPC", UID, Data)
        table.insert(NPCs[TypeOfNPC].Array, UID)
        UID = tonumber(UID)
        task.synchronize()
        local SpawnPart = tonumber(Part.Name)
        local b = buffer.create(4)
        buffer.writeu8(b, 0, UID)
        buffer.writeu8(b, 1, SpawnPart)
        buffer.writeu16(b, 2 , NPCId)
        NPCMakeEvent:FireAllClients(b)
        -- warn("Number of Shados: ", #NPCs[TypeOfNPC].Array)
    end)
    Connections["MakeNPC"] = SSSActor:BindToMessageParallel("MakeNPC", function(UID, Data: SharedType.InitNPCData)
        --* NPCActor made the CombatFSM and MovementActors
        task.synchronize()
        local NPCData:SharedType.NPCData = NPCInfo[Data.TypeFSM]
        if not NPCData then warn("FORGOT TO ADD NPC INFO: ", Data.TypeFSM); return end
        local NPCActor = SSScript.NPCActor:Clone()
        local SpawnPos = Data.SpawnPoint + Vector3.new(0, NPCData.Hip, 0)
        ServerTick.InitMovementProfile(UID, SpawnPos, "NPC")
        task.delay(1,function()
            NPCActor:SetAttribute("UID", UID)
            NPCActor.NPC_Script.Enabled = true --* delay to enable cos helps with loading
            NPCActor.Name = UID
            NPCActor:AddTag(UID) --* important
            NPCActor.Parent = NPCRunTimeFolder
            task.wait(1)  
            MessageAPI.AddCharacterActor(NPCActor)
            MessageAPI.AddNPCActor(NPCActor)    
        end)
        MessageAPI.SendToHealth("Create", UID, NPCData.Health)
        MessageAPI.SendToPosture("Create", UID, NPCData.Posture)            
        task.delay(2, function()
            Data.CurrentCF = CFrame.new(SpawnPos) 
            NPCActor:SendMessage("Init", UID, Data)
        end)
    end)
    Connections["CleanNPC"] =  SSSActor:BindToMessageParallel("CleanNPC", function(UID, TypeOfNPC:string)
        -- Util.Cleanup(UID) --* no point cos Destroy auto removes tag anyway
        MessageAPI.Cleanup(UID) --* this should destroy the NPCActor
        local NPCCFVs:{CFrameValue} = CollectionService:GetTagged("NPCCFV")
        local MyNumID = tonumber(UID)
        task.synchronize()
        for _, NPC_CFV in NPCCFVs do 
            local NumID = tonumber(NPC_CFV.Name)
            if not NumID then continue end
            if NumID == MyNumID then  NPC_CFV:Destroy(); warn("Destroy NPCCFV up"); break end
        end
        local NPCTable = NPCs[TypeOfNPC]
        if not NPCTable then warn("Wrong Type: ", TypeOfNPC); return end
        local NPCArray = NPCTable.Array
        for i, UID in NPCArray do 
            if tonumber(UID) == MyNumID then 
               table.remove(NPCArray, i)
               warn("FOUND NPC REMOVING FROM NPC ARRAY: ", UID, TypeOfNPC, NPCArray) 
               break
            end
        end

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
function MessageAPI.AddCharacterActor(CharActor: Actor)
    CharacterActors[CharActor.Name] = CharActor
end
function MessageAPI.AddNPCActor(NPCActor: Actor)
    NPCActors[NPCActor.Name] = NPCActor
end
function MessageAPI.GiveCharActors() return CharacterActors end
function MessageAPI.GiveNPCActors() return NPCActors end
function MessageAPI.Cleanup(UID) 
    task.synchronize()
    if NPCActors[UID] then NPCActors[UID]:Destroy();  NPCActors[UID] = nil end
    if CharacterActors[UID]then CharacterActors[UID]:Destroy();  CharacterActors[UID] = nil end
end
return MessageAPI











