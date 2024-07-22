--*Server
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScript = script.Parent.Parent
local NPCCombatUtil = require(ServerScript.NPCCombatUtil)
local Character_Controller = require(ServerScript.Character_Controller)
local MessageAPI = require(ServerScript.MessageAPI)

local Shared = ReplicatedStorage.Shared
local ItemDataMod = require(Shared.ItemDataMod)
local CTask = require(Shared.CustomTask)
local SharedTypes = require(Shared.SharedType)
local HB = require(Shared.Hitbox)

type CombatMachine = SharedTypes.ServerCombatMachine
type StateMachine = SharedTypes.ClientStateMachine
local UPDATE_SERVER_COMBATTICK = function(Length:number, UID:string, StateNum:number, ActionNum:number, CurrentFrame:number, TypeMessage:string?) 
    local Message = TypeMessage  or "UpdateProfile"
    local StateBuffer = buffer.create(Length)
    local Writeu8 = buffer.writeu8
    local State = StateNum --*Blocking,Idle,WeaponOut , ... etc
    local Action = ActionNum --*Blocked, Parried, Block, M1, ... etc
    Writeu8(StateBuffer, 0, Length)
    buffer.writestring(StateBuffer, 1, UID, 1)
    Writeu8(StateBuffer, 2, State)
    Writeu8(StateBuffer, 3, Action)
    Writeu8(StateBuffer, 4, CurrentFrame)
    MessageAPI.SendToCombat("UpdateProfile", StateBuffer)    
end
local BufferDir = function(CFV:CFrameValue, b:buffer, offset:number)
    local CF = CFV.Value
    local Dir = CF.LookVector
    local Writei16 = buffer.writei16
    Writei16(b, offset, Dir.X)
    Writei16(b, offset + 2, Dir.Z)
    return  b, offset + 2
end

local HitDummyFSM = {
}
HitDummyFSM["Idle"] = {
    ["InitIdle"]  = function(CombatController: CombatMachine, StateMachine: StateMachine, UID, NPCData: SharedTypes.NPCData,...)
        local WeaponName = NPCData.Weapon
        StateMachine.CurrentItem = WeaponName
        CombatController.ChangeState(UID, "WeaponOut", "WeaponOut")
    end,
    ["SoftStun"] = function(CombatController: CombatMachine, StateMachine: StateMachine, UID, ...)
        CombatController.ChangeState(UID, "SoftStun", "Idle")
        CombatController.TriggerAction(UID, "Stun", ...)
    end    
}
HitDummyFSM["WeaponOut"]= {
    ["M1"] = function(CombatController: CombatMachine, StateMachine: StateMachine, UID, ...)
        CombatController.ChangeState(UID, "LightAttack", "WeaponOut")
        CombatController.TriggerAction(UID, "Light", ...)
    end,
    ["SoftStun"] = function(CombatController: CombatMachine, StateMachine: StateMachine, UID, ...)
        CombatController.ChangeState(UID, "SoftStun", "WeaponOut")
        CombatController.TriggerAction(UID, "Stun", ...)
    end,
}
HitDummyFSM["LightAttack"] = {
    ["Light"] = function(CombatController: CombatMachine, StateMachine: StateMachine, UID,  ...)
        local CurrentItem = StateMachine.CurrentItem
        local CFV:CFrameValue =  HitDummyFSM["CFV"]
        if not CFV then warn("did not Add CFV from NPCScript"); return end  
        local ItemData:SharedTypes.ItemDataMod = ItemDataMod.GiveCopyData(CurrentItem)
        if not ItemData then warn("no ItemData: ", CurrentItem); return end
        local FA:Actor = Character_Controller["FA"] 
        FA:SendMessage("LockMove", true)
        local Length = 9
        local b = buffer.create(Length)
        local Writeu8 = buffer.writeu8
        Writeu8(b, 0, Length)
        buffer.writestring(b, 1, UID, 1)
        Writeu8(b, 2, 4)--*StateNum
        Writeu8(b, 3, 13)--*ActionNum
        local StateBuffer = BufferDir(CFV, b, 5)
        MessageAPI.SendToCombat("UpdWithFrame", 4, StateBuffer)

        --* no  add to Q needed Cos its Entirely server
        StateMachine.CurrentAction = CTask.DelayParallel(ItemData.HBTime/1000, function ()    
            --* Task.delay after Q cos its an NPC
            --* Apply Damage Here cos too slow to SendMessage for DetectedUIDs
            local Results = HB:NPCGPB(CFV.Value, ItemData)
            local UIDsT = {}
            for _, BodyCFPart in Results do  
                if BodyCFPart.Name == UID then continue end
                table.insert(UIDsT, BodyCFPart.Name)
            end
            if #UIDsT <= 0 then CombatController.TriggerAction(UID, "Release"); return end
            local DetectedUIDs  = HB.BufferTableResults(UIDsT, 0, 1)
            --TODO buffer ServerFrame into it
            --* Send to CombatScript ?? and then Send it From there to NPCombatUtil
            NPCCombatUtil.ApplyDamage(UID, DetectedUIDs, 0)
            FA:SendMessage("LockMove")
        end)
    end,
    ["Release"] = function(CombatController: CombatMachine, StateMachine: StateMachine, UID,  ...)
        CombatController.ChangeToOldState(UID)
        local Length = 5
        local StateBuffer = buffer.create(Length)
        local Writeu8 = buffer.writeu8
        Writeu8(StateBuffer, 0, Length)
        buffer.writestring(StateBuffer, 1, UID, 1)
        Writeu8(StateBuffer, 2, 4) --*LightAttack
        Writeu8(StateBuffer, 3, 19)--*Release       
        MessageAPI.SendToCombat("UpdWithFrame", 4, StateBuffer)
    end
}
HitDummyFSM["TrueStun"] = {
    ["Stun"] = function(CombatController: CombatMachine, StateMachine: StateMachine, UID, ItemName, AttackerUID, ClientFrame,  ...)
        local FA:Actor = Character_Controller["FA"] 
        FA:SendMessage("LockMove", true)
        MessageAPI.SendToHealth("SendMessage", "TakeDamage", UID, ItemName, AttackerUID)
        local CA = StateMachine.CurrentAction
        if CA then CTask.Cancel(CA) end
        if StateMachine.SStun then task.cancel(StateMachine.SStun); return end                  
        if StateMachine.TStun then task.cancel(StateMachine.TStun); return end
        local WeaponData = ItemDataMod.GiveCopyData(ItemName)
        if not WeaponData then warn("invalid Item Name: ", WeaponData); return end 
        StateMachine.TStun = task.delay((WeaponData.Stun +2) /2, function()  CombatController.TriggerAction(UID, "Release") end)
    end,
    ["Release"] = function(CombatController: CombatMachine, StateMachine: StateMachine, UID, AttackerUID , WeaponData: SharedTypes.ItemDataMod, ...)
        local FA:Actor = Character_Controller["FA"] 
        FA:SendMessage("LockMove")
        CombatController.ChangeToOldState(UID)
    end, 
}
HitDummyFSM["SoftStun"] = {
    ["Stun"]= function(CombatController: CombatMachine, StateMachine: StateMachine, UID, ItemName, AttackerUID, ClientFrame,  ...)
        local CA = StateMachine.CurrentAction
        if CA then CTask.Cancel(CA) end
        if StateMachine.SStun then task.cancel(StateMachine.SStun); StateMachine.SStun = nil  end
        MessageAPI.SendToHealth("SendMessage", "TakeDamage", UID, ItemName, AttackerUID)
        local FA:Actor = Character_Controller["FA"] 
        local WeaponData = ItemDataMod[ItemName]
        if not WeaponData then warn("invalid Item Name: ", WeaponData); return end 
        FA:SendMessage("LockMove", true)                 
        StateMachine.SStun = task.delay(WeaponData.Stun, function()
            FA:SendMessage("LockMove")        
            CombatController.TriggerAction(UID, "Release") 
        end)
    end,
    ["Release"] = function(CombatController: CombatMachine, StateMachine: StateMachine, UID, ...)
        CombatController.ChangeToOldState(UID)
    end
}
return HitDummyFSM
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