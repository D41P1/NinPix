--*Server
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScript = script.Parent.Parent
local NPCCombatUtil = require(ServerScript.NPCCombatUtil)
local MessageAPI = require(ServerScript.MessageAPI)

local Shared = ReplicatedStorage.Shared
local Encyclopedia = require(Shared.Encyclopedia)
local ItemDataMod = require(Shared.ItemDataMod)
local CTask = require(Shared.CustomTask)
local SharedTypes = require(Shared.SharedType)
local HB = require(Shared.Hitbox)

type CombatMachine = SharedTypes.ServerCombatMachine
type StateMachine = SharedTypes.ClientStateMachine
local SendToCombat = MessageAPI.SendToCombat
local CREATE_PLAYER_STATE = function(Length:number, UID, StateNum:number, ActionNum:number) 
    local StateBuffer = buffer.create(Length)
    local Writeu8 = buffer.writeu8
    local State = StateNum --*Blocking,Idle,WeaponOut , ... etc
    local Action = ActionNum --*Blocked, Parried, Block, M1, ... etc
    UID = tonumber(UID)
    Writeu8(StateBuffer, 0, Length)
    Writeu8(StateBuffer, 1, UID)
    Writeu8(StateBuffer, 2, State)
    Writeu8(StateBuffer, 3, Action)
    return StateBuffer    
end
local UPDATE_SERVER_COMBATTICK = function(Length:number, UID, StateNum:number, ActionNum:number, CurrentFrame:number, TypeMessage:string?) 
    local Message = TypeMessage  or "UpdateProfile"
    local StateBuffer = CREATE_PLAYER_STATE(Length, UID, StateNum, ActionNum)
    MessageAPI.SendToCombat(Message, StateBuffer)    
end
local BufferDir = function(CFV:CFrameValue, DirBuffer:buffer, offset:number)
    local CF = CFV.Value
    local Direction = CF.LookVector
    Direction = Vector3.new(Direction.X, 0, Direction.Z)
    Direction = math.atan2(Direction.Z, Direction.X)
    Direction = Direction*1000
    buffer.writei16(DirBuffer, offset, Direction)
    return  DirBuffer, offset + 2
end

local ShadoMercenaryFSM = {
}
ShadoMercenaryFSM["Idle"] = {
    ["InitIdle"]  = function(CombatController: CombatMachine, StateMachine: StateMachine, UID, NPCData: SharedTypes.NPCData,...)
        local WeaponName = NPCData.Weapon
        StateMachine.CurrentItem = WeaponName
        CombatController.ChangeState(UID, "WeaponOut", "WeaponOut")
        local StateBuffer= CREATE_PLAYER_STATE(5, UID, 1, 1)
        MessageAPI.SendToCombat("UpdWithFrame", 4, StateBuffer)    
    end,
    ["SoftStun"] = function(CombatController: CombatMachine, StateMachine: StateMachine, UID, ...)
        CombatController.ChangeState(UID, "SoftStun", "Idle")
        CombatController.TriggerAction(UID, "Stun", ...)
    end    
}
ShadoMercenaryFSM["WeaponOut"]= {
    ["M1"] = function(CombatController: CombatMachine, StateMachine: StateMachine, UID, ...)
        CombatController.ChangeState(UID, "LightAttack", "WeaponOut")
        CombatController.TriggerAction(UID, "Light", ...)
    end,
    ["SoftStun"] = function(CombatController: CombatMachine, StateMachine: StateMachine, UID, ...)
        CombatController.ChangeState(UID, "SoftStun", "WeaponOut")
        CombatController.TriggerAction(UID, "Stun", ...)
    end,
}
ShadoMercenaryFSM["LightAttack"] = {
    ["Light"] = function(CombatController: CombatMachine, StateMachine: StateMachine, UID,  ...)
        local CurrentItem = StateMachine.CurrentItem
        local CFV:CFrameValue =  ShadoMercenaryFSM["CFV"]
        if not CFV then warn("did not Add CFV from NPCScript"); return end  
        local ItemData:SharedTypes.ItemData = ItemDataMod.GiveCopyData(CurrentItem)
        if not ItemData then warn("no ItemData: ", CurrentItem); return end
        local FA:Actor = ShadoMercenaryFSM["FA"] 
        FA:SendMessage("LockMove", true)
        local M1Count:number = StateMachine.M1Count
        local UnixMill = DateTime.now().UnixTimestampMillis
        M1Count += 1
        if M1Count >= 4 then  M1Count = 1 end
        if UnixMill - StateMachine.M1ResetTime > 2500  then --* been longer than a second since the last m1 
            M1Count = 1
        end
        local TypeHit = 0
        if M1Count == 3 then 
            TypeHit = 1
        end
        StateMachine.M1ResetTime = UnixMill
        --* no  add to Q needed Cos its Entirely server
        StateMachine.CurrentAction = CTask.DelayParallel(ItemData.HBTime/1000, function ()    
            --* Task.delay after Q cos its an NPC
            --* Apply Damage Here cos too slow to SendMessage for DetectedUIDs
            local Results = HB:NPCGPB(CFV.Value, ItemData)
            local UIDsT = {}
            for _, BodyCFPart in Results do  
                local NumUID = tonumber(BodyCFPart.Name)
                if NumUID and NumUID == tonumber(UID) then continue end --* number comparison faster than string
                table.insert(UIDsT, BodyCFPart.Name)
            end
            FA:SendMessage("LockMove")
            CombatController.TriggerAction(UID, "Release");
            if #UIDsT <= 0 then return end --* no Hits
            local DetectedUIDs  = HB.BufferTableResults(UIDsT, 0, 1)
            UID = tostring(UID) -- change back to string cos look below
            NPCCombatUtil.ApplyDamage(UID, DetectedUIDs, 0, TypeHit, ItemData)
        end)
        local Length = 7
        local StateBuffer = CREATE_PLAYER_STATE(Length, UID, 4, 13)
        StateBuffer = BufferDir(CFV, StateBuffer, 5)
        MessageAPI.SendToCombat("UpdWithFrame", 4, StateBuffer)
    end,
    ["Release"] = function(CombatController: CombatMachine, StateMachine: StateMachine, UID,  ...)
        local OldState = CombatController.ChangeToOldState(UID)
        local Length = 5
        local StateNum = Encyclopedia.GiveNumRef(OldState)        
        local StateBuffer = CREATE_PLAYER_STATE(Length, UID, StateNum, 25)
        MessageAPI.SendToCombat("UpdWithFrame", 4, StateBuffer)
    end,
    ["SoftStun"] = function(CombatController: CombatMachine, StateMachine: StateMachine, UID,  ...)
        CombatController.ChangeState(UID, "SoftStun", "WeaponOut")
        CombatController.TriggerAction(UID, "Stun", ...)
    end
}
ShadoMercenaryFSM["TrueStun"] = {
    ["Stun"] = function(CombatController: CombatMachine, StateMachine: StateMachine, UID, ItemName, AttackerUID, ClientFrame,  ...)
        local FA:Actor = ShadoMercenaryFSM["FA"] 
        FA:SendMessage("LockMove", true)
        MessageAPI.SendToHealth("SendMessage", "TakeDamage", UID, ItemName, AttackerUID)
        local CA = StateMachine.CurrentAction
        if CA then CTask.Cancel(CA) end
        if StateMachine.SStun then task.cancel(StateMachine.SStun); return end                  
        if StateMachine.TStun then task.cancel(StateMachine.TStun); return end
        local WeaponData = ItemDataMod.GiveCopyData(ItemName)
        if not WeaponData then warn("invalid Item Name: ", WeaponData); return end 
        StateMachine.TStun = task.delay((WeaponData.Stun +2) /2, function()  CombatController.TriggerAction(UID, "Release") end)
        local StateBuffer = CREATE_PLAYER_STATE(6, UID, 7, 20)
        buffer.writeu8(StateBuffer, 5, AttackerUID)
        SendToCombat("UpdWithFrame", 4, StateBuffer)
    end,
    ["Dead"]= function(CombatController: CombatMachine, StateMachine: StateMachine, UID,  ...)
        MessageAPI.SendToSSS("CleanNPC", UID, ShadoMercenaryFSM["Type"])
    end,
    ["Release"] = function(CombatController: CombatMachine, StateMachine: StateMachine, UID, AttackerUID , WeaponData: SharedTypes.ItemData, ...)
        local FA:Actor = ShadoMercenaryFSM["FA"] 
        FA:SendMessage("LockMove")
        CombatController.ChangeToOldState(UID)

        local Length = 5
        local StateNum = Encyclopedia.GiveNumRef(StateMachine.CurrentState)        
        local StateBuffer = CREATE_PLAYER_STATE(Length, UID, StateNum, 25)
        MessageAPI.SendToCombat("UpdWithFrame", 4, StateBuffer)
    end, 
}
ShadoMercenaryFSM["SoftStun"] = {
    ["Stun"]= function(CombatController: CombatMachine, StateMachine: StateMachine, UID, ItemName, AttackerUID, ClientFrame,  ...)
        if StateMachine.CurrentAction then CTask.Cancel(StateMachine.CurrentAction) end
        if StateMachine.SStun then task.cancel(StateMachine.SStun); StateMachine.SStun = nil  end
        MessageAPI.SendToHealth("SendMessage", "TakeDamage", UID, ItemName, AttackerUID)        
        local FA:Actor = ShadoMercenaryFSM["FA"] 
        local WeaponData = ItemDataMod[ItemName]
        if not WeaponData then warn("invalid Item Name: ", WeaponData); return end 
        FA:SendMessage("LockMove", true)                 
        StateMachine.SStun = task.delay(WeaponData.Stun, function()
            FA:SendMessage("LockMove")        
            CombatController.TriggerAction(UID, "Release") 
        end)
        local StateBuffer = CREATE_PLAYER_STATE(6, UID, 6, 20)
        buffer.writeu8(StateBuffer, 5, AttackerUID)
        SendToCombat("UpdWithFrame", 4, StateBuffer)
    end,
    ["SoftStun"] = function(CombatController: CombatMachine, StateMachine: StateMachine, UID,  ...)
        CombatController.TriggerAction(UID, "Stun", ...)
    end,
    ["Release"] = function(CombatController: CombatMachine, StateMachine: StateMachine, UID, ...)
        CombatController.ChangeToOldState(UID)
        local Length = 5
        local StateNum = Encyclopedia.GiveNumRef(StateMachine.CurrentState)        
        local StateBuffer = CREATE_PLAYER_STATE(Length, UID, StateNum, 25)
        MessageAPI.SendToCombat("UpdWithFrame", 4, StateBuffer)
    end
}
do -- Dead
    local Dead = function(CombatController: CombatMachine, StateMachine: StateMachine, UID, ...)
        CombatController.ChangeState(UID, "TrueStun")
        CombatController.TriggerAction(UID, "Dead")
    end    
    -- ShadoMercenaryFSM.Blocking["TriggerDead"] = Dead
    ShadoMercenaryFSM.WeaponOut["TriggerDead"] = Dead
    ShadoMercenaryFSM.Idle["TriggerDead"] = Dead
    ShadoMercenaryFSM.SoftStun["TriggerDead"] = Dead
    -- ShadoMercenaryFSM.HeavyAttack["TriggerDead"] = Dead
    ShadoMercenaryFSM.LightAttack["TriggerDead"] = Dead
    -- ShadoMercenaryFSM.Skill["TriggerDead"] = Dead    
end

return ShadoMercenaryFSM
--[[ --! Info For buffering CombatState
Length
UID
State
Action
CurrentFrame
--* 5 bytes
--* CCT =(Client combat tick)

Rule {
    Update the CCT in ALL ACTIONS
}
]]