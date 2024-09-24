local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared
local Particle_Handler = require(script.Parent.Parent.SkillsFolder.Particle_Handler)
local SharedTypes = require(Shared.SharedType)

local ClientActor = script.Parent.Parent
local CharacterHandler = require(ClientActor.Character_Handler)

type CombatMod = SharedTypes.ClientCombatMachine
type FSM = SharedTypes.ClientStateMachine
type ItemDataMod = SharedTypes.ItemData
local OtherPlayerCombat = {
    ["Idle"] = {},    

    ["TrueStun"] = {},
    ["SoftStun"] = {},    
}
local Idle:any = OtherPlayerCombat.Idle
local SStun:any = OtherPlayerCombat.SoftStun
local TStun = OtherPlayerCombat.TrueStun
--[[
TStun["Dead"] =  function(ClientCombatMachine:CombatMod, StateMachine:FSM, Character:Model, Event:UnreliableRemoteEvent,  ...)
    --TODO Ragdoll,Parent to Dead here,  no need to fire event cos Server should already know
    --! Trigger Dead from Health Event ONLY cos Client and Server Health may differ  better to wait for the correction
end
]]
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
local StunFunc = function(ClientCombatMachine:CombatMod, StateMachine:FSM, Character:Model, Event:UnreliableRemoteEvent, MyFrame, StateBuffer, ...)
    --* this action For PlayerCombat will only ever be triggered by the CombatTickEvent via the server Never on Client First
    --* therefore theres no real reason to update here as the CombatTickEvent Updates for you   
    local CurrentAction = StateMachine.CurrentAction
    if CurrentAction then  task.synchronize(); CurrentAction:Stop(); CurrentAction:Destroy() end
    local UID = Character.Name    
    local Profile: CharacterHandler.Profile = CharacterHandler.GiveProfile(UID)
    if not Profile then warn("no Profile TrueStun Stun : ", StateMachine); return end
    Profile.Forward:SendMessage("LockMove", true)
    Particle_Handler.Hurt(Character)
end
TStun["Stun"] = StunFunc
SStun["Stun"] = StunFunc
local Release  = function(ClientCombatMachine:CombatMod, StateMachine:FSM, Character:Model, Event:UnreliableRemoteEvent, FrameBuffer:buffer, ...)
    local UID = Character.Name
    local Profile: CharacterHandler.Profile = CharacterHandler.GiveProfile(UID)
    if not Profile then warn("no profiel: ", UID, Profile); return end
    local ForwardActor: Actor = Profile.Forward 
    ForwardActor:SendMessage("LockMove")
end
TStun["Release"] = Release
SStun["Release"] = Release
Idle["SoftStun"] =  function(ClientCombatMachine:CombatMod, StateMachine:FSM, Character:Model, Event:UnreliableRemoteEvent, AUID, ItemDataMod:ItemDataMod, ...)
    ClientCombatMachine.ChangeState(Character.Name, "SoftStun", "Idle")
    ClientCombatMachine.TriggerAction(Character, Event, "Stun", ItemDataMod)
end
return OtherPlayerCombat