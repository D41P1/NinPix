local SSS = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local Shared = ReplicatedStorage.Shared
local CharacterActor = script.Parent
local ServerScript = SSS.Server.ServerActor.Server_Script
local MessageAPI = require(ServerScript.MessageAPI)
local SharedType = require(Shared.SharedType)
local HumanoidMachine = require(Shared.HumanoidMachine)
local EncycloPedia = require(Shared.Encyclopedia)

local CombatController = require(ServerScript.CombatController)
local Character_Controller = require(ServerScript.Character_Controller) 
local MovementLogic = require(ServerScript.Character_Controller.MovementLogic); MovementLogic.Init(Character_Controller)

Character_Controller["Actor"] = CharacterActor
Character_Controller:InitEvents(CharacterActor.Name)
local UID  = CharacterActor:GetAttribute("UID")
local Humanoid: SharedType.CustomHumanoid = HumanoidMachine:InitServerHumanoid(UID, require(ServerScript.Humanoid_Controller))
function GiveAnims(Humanoid) -- this is so ray movement works
    local AnimNamesTable: any = { "Jump", "Idle", "Walk", "Fall", "Landed" }
    for _ , Anims: string in AnimNamesTable do
        Humanoid[Anims] = { Play = function() end, Stop = function() end, Destroy = function() end, }
    end 
end
GiveAnims(Humanoid)


--TODO test with 2 or more profiles so make a fake profile////////////////////////////////////


local ForwardActor, DownwardActor = MessageAPI.InitServerCharacter(CharacterActor)
Character_Controller["FA"] = ForwardActor
Character_Controller["DA"] = DownwardActor
CharacterActor:BindToMessage("InitHotbarInfo", function(InfoBuffer:buffer)
    local CombatStates = require(ServerScript.ServerCombatStateMods.ServerCombatStates)
    local CombatMachine:any = CombatController:InitCombatMachine(UID, CombatStates, InfoBuffer)
    local StateNum = EncycloPedia.GiveNumRef(CombatMachine.CurrentState)
    local ActionNum = EncycloPedia.GiveNumRef(CombatMachine.Action)
    CombatStates["Actor"] = CharacterActor
    
    local Length = 5  
    local Profile = buffer.create(Length) 
    buffer.writeu8(Profile, 0, Length)
    buffer.writestring(Profile, 1, UID, 1)
    buffer.writeu8(Profile, 2, StateNum)
    buffer.writeu8(Profile, 3, ActionNum)
    MessageAPI.SendToCombat("UpdWithFrame", 4, Profile)
end)
local Connections = {}
CharacterActor:BindToMessage("Init", function(UID, Data: SharedType.NPCData)
    local CFV:CFrameValue = unpack(CollectionService:GetTagged(UID.."CFV"))  
    local BodyCFPart:Part = unpack(CollectionService:GetTagged(UID.."Body"))
    if not CFV then warn("no CFV detected: ", UID); return end
    if not BodyCFPart then warn("no BODY_CF_PART  detected: ", UID); return end
    ForwardActor:SendMessage("Init", UID, Data)
    DownwardActor:SendMessage("Init", UID, Data)
    local A  = CharacterActor:BindToMessageParallel("LedgeUp", function(UID, RayPos: Vector3, Hip, CF: CFrame)  
        local NewCF  =  CF * CFrame.new(0, Hip, 0)
        ForwardActor:SendMessage("SetPCF", NewCF)
        task.synchronize()
        CFV.Value = NewCF
        BodyCFPart.CFrame = NewCF
    end)
    table.insert(Connections, A)    
end)

CharacterActor:BindToMessageParallel("DownNotHit", function(UID, CurrentCF: CFrame)  
    -- In Air did not hit floor    
    HumanoidMachine.ForceState(UID, "Fall")
    DownwardActor:SendMessage("StartFall", CurrentCF)
end)
CharacterActor:BindToMessageParallel("StopFall", function(UID: string, NewCF: CFrame)  
    ForwardActor:SendMessage("SetPCF", NewCF)
    HumanoidMachine.ServerTriggerAction(UID, nil, "ReleaseFall")
end)   
CharacterActor:BindToMessageParallel("Q", function(CurrentItem: string)  
    --TODO the Item Time to wait for in Millis for HBEvent in Combat Logic 
    --* --> Char_Controller --> Combat_Logic
    Character_Controller.SendtoQ(CurrentItem)
end)
--*Combat Related Bindables
CharacterActor:BindToMessageParallel("TriggerAction", function(UID:string, Action,...)
    CombatController.TriggerAction(UID, Action, ...)
end)

--[[ Events
    W,
    A,
    S,
    D
    Jump,
    M1,
    M2,
    F
]]
--[[
    create Actor(s) parent to Actors Folder
    Create CharacterEvents --Send TableOfEventNames To Character_Controller
    init CustomHumanoid
    connect functions to events through Character_Controller Module
    init attributes
]]