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

local SharedType = require(Shared.SharedType)
local NPCInfo = require(Shared.NPCInfo)
local HumanoidMachine = require(Shared.HumanoidMachine)
local ItemDataMod = require(Shared.ItemDataMod)
local State_Dictionary = require(Shared.State_Dictionary)


local UID  = NPCActor:GetAttribute("UID")
UID = tonumber(UID)

local ForwardActor, DownwardActor = MessageAPI.InitServerCharacter(NPCActor)
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
    
    ForwardActor:SendMessage("Init", UID, Data, true)
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
    StateModule["Type"] = TypeFSM
    StateModule["FA"] = ForwardActor
    StateModule["DA"] = DownwardActor
    
    CombatController:InitNPCombatMachine(UID, StateModule)
    CombatController.TriggerAction(UID, "InitIdle", NPCData)
    if PathFindingTick["Init"] then 
        PathFindingTick["Init"](tostring(UID), ForwardActor, NPCInfo.ShadoMercenary.WalkSpeed)
    end
    local A = NPCActor:BindToMessageParallel("Tick", function()
        if not PathFindingTick["Tick"] then warn("no Tick Func; ", PathFindingTick); return end
        PathFindingTick["Tick"]( tonumber(UID) )
    end)
    local B =  NPCActor:BindToMessageParallel("LedgeUp", function(Hip, CF: CFrame)  
        --* a Clash in this context is when the FA and DA and CFV have different CFs causing weird movement
        local NewCF  =  CF * CFrame.new(0, Hip, 0)
        ForwardActor:SendMessage("SetPCF", NewCF)
        DownwardActor:SendMessage("SetPCF", NewCF) --! for some reason DownActor does not Update properly causing a Clash DO NOT REMOVE
        task.synchronize()
        CFV.Value = NewCF
        BodyCFPart.CFrame = NewCF
    end)
    table.insert(Connections, A)
    table.insert(Connections, B)
    local Humanoid: SharedType.CustomHumanoid = HumanoidMachine:InitServerHumanoid(tostring(UID), require(ServerScript.Humanoid_Controller))
    local function GiveAnims(Humanoid) -- this is so ray movement works
        local AnimNamesTable: any = { "Jump", "Idle", "Walk", "Fall", "Landed" }
        for _ , Anims: string in AnimNamesTable do
            Humanoid[Anims] = { Play = function() end, Stop = function() end, Destroy = function() end, }
        end 
    end
    GiveAnims(Humanoid)    
end)
NPCActor:BindToMessageParallel("TriggerAction", function(UID:string, Action,...)
    CombatController.TriggerAction(UID, Action, ...)
end)
do
    local T = {["Blocking"] = true}
    NPCActor:BindToMessageParallel("Knockback", function(CurrentItem:string?, DirBuffer:buffer, ...)
        --TODO in future will have to do a Iframes Check or make it when they Activate Iframes disconnect the BindMessage   
        local ItemName = CurrentItem or State_Dictionary.GiveString(buffer.readu16(DirBuffer, 1))
        if not ItemName then warn("not itemName; ", CurrentItem);  return end
        local ItemdataCopy = ItemDataMod.GiveCopyData(ItemName)
        if not ItemdataCopy then warn("incorrect itemName: ", ItemName); return end 
        local KB  = ItemdataCopy.KB

        local StateMachine = CombatController[tostring(UID)]
        if not StateMachine then warn("no StateMachine: ", UID); return end 
        if  T[StateMachine.CurrentState] then 
            ForwardActor:SendMessage("Pushback", KB, DirBuffer, ...)    
            DownwardActor:SendMessage("StartDownward")                
            return 
        end

        local Ragdollbuffer = buffer.create(2)
        local Wu8 = buffer.writeu8
        Wu8(Ragdollbuffer, 0, tonumber(UID))
        Wu8(Ragdollbuffer, 1, ItemdataCopy.Stun)
        MessageAPI.SendToRagdoll("Ragdoll", Ragdollbuffer)
        DownwardActor:SendMessage("Knockback", KB, DirBuffer, ...)
    end)
    NPCActor:BindToMessageParallel("Pushback", function(CurrentItem:string?, DirBuffer:buffer, ...)
        local ItemName = CurrentItem or State_Dictionary.GiveString(buffer.readu16(DirBuffer, 1))
        if not ItemName then warn("not itemName; ", CurrentItem, buffer.readu16(DirBuffer, 1));  return end
        local ItemdataCopy = ItemDataMod.GiveCopyData(ItemName)
        if not ItemdataCopy then warn("incorrect ITemName: ", ItemName); return end 
        local KB  = ItemdataCopy.KB
        ForwardActor:SendMessage("Pushback", KB, DirBuffer, ...)    
        DownwardActor:SendMessage("StartDownward")
    end)    
    
end


