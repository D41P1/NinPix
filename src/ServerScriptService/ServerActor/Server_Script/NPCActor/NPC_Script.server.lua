local SSS = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local Shared = ReplicatedStorage.Shared
local NPCActor = script.Parent
local ServerScript = SSS.Server.ServerActor.Server_Script
local NPCStateMods_Controller = require(ServerScript.NPCStateMods_Controller)
local NPCPathFind_Controller = require(ServerScript.NPCPathFind_Controller)
local MessageAPI = require(ServerScript.MessageAPI)
local CombatController = require(ServerScript.CombatController)
local Character_Controller = require(ServerScript.Character_Controller) 

local SharedType = require(Shared.SharedType)
local NPCInfo = require(Shared.NPCInfo)
local HumanoidMachine = require(Shared.HumanoidMachine)
local EncycloPedia = require(Shared.Encyclopedia)

Character_Controller["Actor"] = NPCActor

local UID  = NPCActor:GetAttribute("UID")
--// local Humanoid: SharedType.CustomHumanoid = HumanoidMachine:InitServerHumanoid(UID, require(ServerScript.Humanoid_Controller))

local ForwardActor, DownwardActor = MessageAPI.InitServerCharacter(NPCActor)
Character_Controller["FA"] = ForwardActor
Character_Controller["DA"] = DownwardActor
NPCActor:BindToMessage("InitHotbarInfo", function(InfoBuffer:buffer)
    local CombatStates = require(ServerScript.ServerCombatStateMods.ServerCombatStates)
    local CombatMachine:any = CombatController:InitCombatMachine(UID, CombatStates, InfoBuffer)
    local StateNum = EncycloPedia.GiveNumRef(CombatMachine.CurrentState)
    local ActionNum = EncycloPedia.GiveNumRef(CombatMachine.Action)
    CombatStates["Actor"] = NPCActor
    
    local Length = 5  
    local Profile = buffer.create(Length) 
    buffer.writeu8(Profile, 0, Length)
    buffer.writestring(Profile, 1, UID, 1)
    buffer.writeu8(Profile, 2, StateNum)
    buffer.writeu8(Profile, 3, ActionNum)
    MessageAPI.SendToCombat("UpdWithFrame", 4, Profile)
end)
NPCActor:BindToMessageParallel("DownNotHit", function(UID, CurrentCF: CFrame)  
    -- In Air did not hit floor    
    HumanoidMachine.ForceState(UID, "Fall")
    DownwardActor:SendMessage("StartFall", CurrentCF)
end)
NPCActor:BindToMessageParallel("StopFall", function(UID: string, NewCF: CFrame)  
    ForwardActor:SendMessage("SetPCF", NewCF)
    HumanoidMachine.ServerTriggerAction(UID, nil, "ReleaseFall")
end)   

local Connections = {}
--*Combat Related Bindables
NPCActor:BindToMessage("Init", function(UID, Data:SharedType.InitNPCData)
    local CFV:CFrameValue = unpack(CollectionService:GetTagged(UID.."CFV"))  
    local BodyCFPart:Part = unpack(CollectionService:GetTagged(UID.."Body"))
    if not CFV then warn("no CFV detected: ", UID); return end
    if not BodyCFPart then warn("no BODY_CF_PART  detected: ", UID); return end
    
    ForwardActor:SendMessage("Init", UID, Data)
    DownwardActor:SendMessage("Init", UID, Data)    
    
    local TypeFSM = Data.TypeFSM
    local Module:ModuleScript = NPCStateMods_Controller.GiveMod(TypeFSM.."FSM")
    if not Module then warn("Invalid StateMod: ", TypeFSM); return end
    local PathFindModule:ModuleScript = NPCPathFind_Controller.GiveMod(Data.TypePathFinding.."PF" )
    if not PathFindModule then warn("Invalid PathFindMod: ", Data.TypePathFinding); return end
    local StateModule = require(Module)
    local PathFindingTick = require(PathFindModule)
    local NPCData = NPCInfo[TypeFSM]
    if not NPCData then warn("add npcData: ", TypeFSM); return end
    StateModule["CFV"] = CFV
    
    CombatController:InitNPCombatMachine(UID, StateModule)
    CombatController.TriggerAction(UID, "InitIdle", NPCData)
    local A = NPCActor:BindToMessageParallel("Tick", function()
        --TODO pathFinding Tick func
        if not PathFindingTick["Tick"] then warn("no Tick Func; ", PathFindingTick); return end
        PathFindingTick["Tick"](UID)
    end)
    local B =  NPCActor:BindToMessageParallel("LedgeUp", function(UID, RayPos: Vector3, Hip, CF: CFrame)  
        local NewCF  =  CF * CFrame.new(0, Hip, 0)
        ForwardActor:SendMessage("SetPCF", NewCF)
        -- MessageAPI.SendToSSS("ChangeProfile", UID, "CurrentCF", NewCF)
        task.synchronize()
        CFV.Value = NewCF
        BodyCFPart.CFrame = NewCF
    end)
    table.insert(Connections, A)
    table.insert(Connections, B)
end)
NPCActor:BindToMessageParallel("TriggerAction", function(UID:string, Action,...)
    CombatController.TriggerAction(UID, Action, ...)
end)
