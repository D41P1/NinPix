local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared
local SharedTypes = require(Shared.SharedType)

local ClientActor = script.Parent.Parent
local CharacterHandler = require(ClientActor.Character_Handler)

type CombatMod = SharedTypes.ClientCombatMachine
type FSM = SharedTypes.ClientStateMachine
type ItemDataMod = SharedTypes.ItemDataMod
local OtherPlayerCombat = {
    ["Idle"] = {},    

    ["TrueStun"] = {},
    ["SoftStun"] = {},    
}
local Idle:any = OtherPlayerCombat.Idle
local SStun:any = OtherPlayerCombat.SoftStun
local TStun = OtherPlayerCombat.TrueStun


--* TrueStun_Start
TStun["Dead"] =  function(ClientCombatMachine:CombatMod, StateMachine:FSM, Character:Model, Event:UnreliableRemoteEvent,  ...)
    --TODO Ragdoll,Parent to Dead here,  no need to fire event cos Server should already know
    --! Trigger Dead from Health Event ONLY cos Client and Server Health may differ  better to wait for the correction
end
TStun["GuardBroken"] =  function(ClientCombatMachine:CombatMod, StateMachine:FSM, Character:Model, Event, AttackerUID, WeaponData:ItemDataMod, ...)
    --TODO play the Guard Break Anim
    local UID = Character.Name
    local Profile: CharacterHandler.Profile = CharacterHandler.GiveProfile(UID)
    if not Profile then warn("no Profile GB : ", StateMachine); return end
    Profile.Forward:SendMessage("LockMove", true)
    if StateMachine.SStun then task.cancel(StateMachine.SStun); return end                  
    if StateMachine.TStun then task.cancel(StateMachine.TStun); return end
    StateMachine.TStun = task.delay((WeaponData.Stun +2) /2, function() ClientCombatMachine.TriggerAction(Character, nil, "Release", Profile)     end)
end
TStun["Release"] =  function(ClientCombatMachine:CombatMod, StateMachine:FSM, Character:Model, Event, Prof: CharacterHandler.Profile, ...)
    local UID = Character.Name
    ClientCombatMachine.ChangeToOldState(UID)
    Prof.Forward:SendMessage("LockMove")
    print("released From GuardBreak")
end
--*SoftStun 
SStun["Stun"] = function(ClientCombatMachine:CombatMod, StateMachine:FSM, Character:Model, Event:UnreliableRemoteEvent, ItemDataMod:ItemDataMod, ...)
    local Health = Character:GetAttribute("Health")
    if not Health then warn("no Health Att"); return end
    local UID = Character.Name
    Health -= ItemDataMod.Damage
    task.synchronize()
    local CurrentAction = StateMachine.CurrentAction
    if CurrentAction then  CurrentAction:Stop(); CurrentAction:Destroy(); StateMachine.CurrentAction = nil end
    if StateMachine.SStun then  task.cancel(StateMachine.SStun); StateMachine.SStun = nil  end
    CharacterHandler.SetHealth(Character, Health)
    local Profile: CharacterHandler.Profile = CharacterHandler.GiveProfile(UID)
    if not Profile then warn("no profiel: ", UID, Profile); return end
    local ForwardActor: Actor = Profile.Forward
    if not ForwardActor then warn("no Forward actor"); return end
    ForwardActor:SendMessage("AdjustWS", 1)
    StateMachine.SStun = task.delay(ItemDataMod.Stun, function()
        ForwardActor:SendMessage("OldWS")
        ClientCombatMachine.TriggerAction(Character, Event, "Release")
    end)
end
SStun["Release"] = function(ClientCombatMachine:CombatMod, StateMachine:FSM, Character:Model, Event:UnreliableRemoteEvent, ItemDataMod:ItemDataMod, ...)
    ClientCombatMachine.ChangeToOldState(Character.Name)
end
Idle["SoftStun"] =  function(ClientCombatMachine:CombatMod, StateMachine:FSM, Character:Model, Event:UnreliableRemoteEvent, AUID, ItemDataMod:ItemDataMod, ...)
    ClientCombatMachine.ChangeState(Character.Name, "SoftStun", "Idle")
    ClientCombatMachine.TriggerAction(Character, Event, "Stun", ItemDataMod)
end

return OtherPlayerCombat