--*Server
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScript = script.Parent.Parent
local Character_Controller = require(ServerScript.Character_Controller)
local MessageAPI = require(ServerScript.MessageAPI)

local Shared = ReplicatedStorage.Shared
local ItemDataMod = require(Shared.ItemDataMod)
local SharedTypes = require(Shared.SharedType)

type CombatMachine = SharedTypes.ServerCombatMachine
type StateMachine = SharedTypes.ClientStateMachine
local DummyFSM = {
}
DummyFSM["Idle"] = {
    ["SoftStun"] = function(CombatController: CombatMachine, StateMachine: StateMachine, UID, ...)
        CombatController.ChangeState(UID, "SoftStun", "Idle")
        CombatController.TriggerAction(UID, "Stun", ...)
    end
}
DummyFSM["TrueStun"] = {
    ["Stun"] = function(CombatController: CombatMachine, StateMachine: StateMachine, UID, ItemName, AttackerUID, ClientFrame,  ...)
        local FA:Actor = Character_Controller["FA"] 
        FA:SendMessage("LockMove", true)
        MessageAPI.SendToHealth("SendMessage", "TakeDamage", UID, ItemName, AttackerUID)
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
DummyFSM["SoftStun"] = {
    ["Stun"]= function(CombatController: CombatMachine, StateMachine: StateMachine, UID, ItemName, AttackerUID, ClientFrame,  ...)
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
return DummyFSM