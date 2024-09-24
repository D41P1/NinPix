--*Server
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScript = script.Parent.Parent
local Character_Controller = require(ServerScript.Character_Controller)
local MessageAPI = require(ServerScript.MessageAPI)

local Shared = ReplicatedStorage.Shared
local CustomTask = require(Shared.CustomTask)
local ItemDataMod = require(Shared.ItemDataMod)
local SharedTypes = require(Shared.SharedType)

type CombatMachine = SharedTypes.ServerCombatMachine
type StateMachine = SharedTypes.ClientStateMachine
local DummyFSM = {}
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
local SendToCombat = MessageAPI.SendToCombat
DummyFSM["Idle"] = {
    ["SoftStun"] = function(CombatController: CombatMachine, StateMachine: StateMachine, UID, ...)
        CombatController.ChangeState(UID, "SoftStun", "Idle")
        CombatController.TriggerAction(UID, "Stun", ...)
    end,
    ["InitIdle"] = function(CombatController: CombatMachine, StateMachine: StateMachine, UID, ...)
        CombatController.ChangeState(UID, "WeaponOut", "WeaponOut")
        local StateBuffer= CREATE_PLAYER_STATE(5, UID, 1, 1)
        MessageAPI.SendToCombat("UpdWithFrame", 4, StateBuffer)    
    end
}
DummyFSM["TrueStun"] = {
    ["Stun"] = function(CombatController: CombatMachine, StateMachine: StateMachine, UID, ItemName, AttackerUID, ClientFrame,  ...)    
        local FA:Actor = Character_Controller["FA"] 
        FA:SendMessage("LockMove", true)
        MessageAPI.SendToHealth("SendMessage", "TakeDamage", UID, ItemName, AttackerUID)
        local CA = StateMachine.CurrentAction
        if CA then CustomTask.Cancel(CA) end
        if StateMachine.SStun then task.cancel(StateMachine.SStun); return end                  
        if StateMachine.TStun then task.cancel(StateMachine.TStun); return end
        local WeaponData = ItemDataMod.GiveCopyData(ItemName)
        if not WeaponData then warn("invalid Item Name: ", WeaponData); return end 
        StateMachine.TStun = task.delay((WeaponData.Stun +2) /2, function()  CombatController.TriggerAction(UID, "Release") end)
        local StateBuffer = CREATE_PLAYER_STATE(6, UID, 7, 20)
        buffer.writeu8(StateBuffer, 5, AttackerUID)
        SendToCombat("UpdWithFrame", 4, StateBuffer)
    end,
    ["TrueStun"] = function(CombatController: CombatMachine, StateMachine: StateMachine, UID, ...)
        CombatController.TriggerAction(UID, "Stun", ...)
    end,
    ["Release"] = function(CombatController: CombatMachine, StateMachine: StateMachine, UID, AttackerUID , WeaponData: SharedTypes.ItemData, ...)
        local FA:Actor = Character_Controller["FA"] 
        FA:SendMessage("LockMove")
        CombatController.ChangeToOldState(UID)
    end, 
}
DummyFSM["SoftStun"] = {
    ["Stun"]= function(CombatController: CombatMachine, StateMachine: StateMachine, UID, ItemName, AttackerUID, ClientFrame,  ...)
        if StateMachine.CurrentAction then CustomTask.Cancel(StateMachine.CurrentAction) end
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
        local StateBuffer = CREATE_PLAYER_STATE(6, UID, 6, 20)
        buffer.writeu8(StateBuffer, 5, AttackerUID)
        SendToCombat("UpdWithFrame", 4, StateBuffer)
    end,
    ["SoftStun"] = function(CombatController: CombatMachine, StateMachine: StateMachine, UID, ...)
        CombatController.TriggerAction(UID, "Stun", ...)
    end,
    ["Release"] = function(CombatController: CombatMachine, StateMachine: StateMachine, UID, ...)
        CombatController.ChangeToOldState(UID)
    end
}
return DummyFSM