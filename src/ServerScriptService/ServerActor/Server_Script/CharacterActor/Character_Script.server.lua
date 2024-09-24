local SSS = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local Shared = ReplicatedStorage.Shared
local CharacterActor = script.Parent
local ServerScript = SSS.Server.ServerActor.Server_Script
local Util = require(ServerScript.Util)
local Encyclopedia = require(Shared.Encyclopedia)
local ItemDataMod = require(Shared.ItemDataMod)
local MessageAPI = require(ServerScript.MessageAPI)
local SharedType = require(Shared.SharedType)
local HumanoidMachine = require(Shared.HumanoidMachine)

local CombatController = require(ServerScript.CombatController)
local Character_Controller = require(ServerScript.Character_Controller) 
local MovementLogic = require(ServerScript.Character_Controller.MovementLogic); MovementLogic.Init(Character_Controller)
local InventoryLogic = require(ServerScript.Character_Controller.InventoryLogic)

Character_Controller["Actor"] = CharacterActor
Character_Controller:InitEvents(CharacterActor.Name)
local UID  = CharacterActor:GetAttribute("UID")
-- local NumUID = tonumber(UID)
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

CharacterActor:BindToMessage("InitHotbarInfo", function(Inventory_Buffer:buffer)
    local CombatStates = require(ServerScript.ServerCombatStateMods.ServerCombatStates)
    CombatController:InitCombatMachine(UID, CombatStates, Inventory_Buffer)
    InventoryLogic.Init_Inventory(Inventory_Buffer, UID)
    CombatStates["Actor"] = CharacterActor
    
    --[[
    local StateNum = EncycloPedia.GiveNumRef(CombatMachine.CurrentState)
    local ActionNum = EncycloPedia.GiveNumRef(CombatMachine.Action)
    
    local Length = 5  
    local Profile = buffer.create(Length) 
    local writeu8 = buffer.writeu8
    writeu8(Profile, 0, Length)
    writeu8(Profile, 1, tonumber(UID))
    writeu8(Profile, 2, StateNum)
    writeu8(Profile, 3, ActionNum)
    MessageAPI.SendToCombat("UpdWithFrame", 4, Profile)
    ]]
    
end)
local Connections = {}
CharacterActor:BindToMessage("Init", function(UID, Data: SharedType.NPCData)
    local CFV:CFrameValue = unpack(CollectionService:GetTagged(UID.."CFV"))  
    local BodyCFPart:Part = unpack(CollectionService:GetTagged(UID.."Body"))
    if not CFV then warn("no CFV detected: ", UID); return end
    if not BodyCFPart then warn("no BODY_CF_PART  detected: ", UID); return end
    Character_Controller["CFV"] = CFV --*Important

    ForwardActor:SendMessage("Init", UID, Data)
    DownwardActor:SendMessage("Init", UID, Data)
    local A  = CharacterActor:BindToMessageParallel("LedgeUp", function(Hip, CF: CFrame)  
        HumanoidMachine.ServerTriggerAction(tostring(UID), nil, "ReleaseFall")
        local NewCF  =  CF * CFrame.new(0, Hip, 0)
        ForwardActor:SendMessage("SetPCF", NewCF)
        task.synchronize()
        CFV.Value = NewCF
        BodyCFPart.CFrame = NewCF
    end)
    table.insert(Connections, A)    
end)
CharacterActor:BindToMessageParallel("ReleaseJump", function()  
    HumanoidMachine.ServerTriggerAction(UID, nil, "ReleaseJump")
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
do
    local T = {["Blocking"] = true}
    CharacterActor:BindToMessageParallel("Knockback", function(CurrentItem:string?, DirBuffer:buffer, ...)
        --TODO in future will have to do a Iframes Check or make it when they Activate Iframes disconnect the BindMessage   
        local ItemName = CurrentItem or Encyclopedia.GiveString(buffer.readu16(DirBuffer, 1))
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
    CharacterActor:BindToMessageParallel("Pushback", function(CurrentItem:string?, DirBuffer:buffer, ...)
        local ItemName = CurrentItem or Encyclopedia.GiveString(buffer.readu16(DirBuffer, 1))
        if not ItemName then warn("not itemName; ", CurrentItem, buffer.readu16(DirBuffer, 1));  return end
        local ItemdataCopy = ItemDataMod.GiveCopyData(ItemName)
        if not ItemdataCopy then warn("incorrect ITemName: ", ItemName); return end 
        local KB  = ItemdataCopy.KB
        ForwardActor:SendMessage("Pushback", KB, DirBuffer, ...)    
        DownwardActor:SendMessage("StartDownward")
    end)      
end
CharacterActor:BindToMessageParallel("RespawnPlayer", function(...)        
    task.delay(6, function()
        local RRPOS:RaycastResult  = Util.SpawnPoint()
        if not RRPOS then warn("PROBLEM WITH RRPOS"); return end
        local POS:Vector3 = RRPOS.Position + Vector3.new(0, 5, 0)
        local CF = CFrame.new(POS)
        ForwardActor:SendMessage("SetPCF", CF)
        DownwardActor:SendMessage("SetPCF", CF)
        local CFV:CFrameValue = unpack(CollectionService:GetTagged(UID.."CFV"))  
        if not CFV then warn("no CFV detected: ", UID); return end
        ForwardActor:SendMessage("LockMove")
        task.synchronize()
        CFV.Value = CF
    end)
end)



