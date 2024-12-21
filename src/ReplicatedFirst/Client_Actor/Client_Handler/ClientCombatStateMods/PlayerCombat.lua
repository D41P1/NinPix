--!native
--[[ Some Info

Client Initated actions for example Light in LightAttack State should have the following Code:
if ServerBool then return end --* to prevent a double trigger when a client spams 

The reason being the Server will never First initiate these actions
like Light , Guard etc.

Toolhandle is a little weird theres a Client Side Swap CD instead
if they go past it it will just break their character --* won't affect Server
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared

local ClientCombatMachine = require(script.Parent.Parent.Parent.ClientCombatMachine)
local ItemDataMod = require(Shared.ItemDataMod)

local State_Dictionary = require(Shared.State_Dictionary)
local SharedTypes = require(Shared.SharedType)
local AnimHandler = require(Shared.AnimHandler)
-- local HB = require(Shared.Hitbox)
-- local State_Dictionary = require(Shared.State_Dictionary)
local HumanoidMachine = require(Shared.HumanoidMachine)
local NumToSymbol = require(Shared.NumToSymbol)
local ItemManager = require(Shared.ItemManager)

local ClientActor = script.Parent.Parent
local CharacterHandler = require(ClientActor.Character_Handler)
-- local Gui_Handler = require(ClientActor.Gui_Handler)
local ClientMessage = require(ClientActor.Parent.ClientMessageAPI)
local Particle_Handler = require(ClientActor.SkillsFolder.Particle_Handler)
local SkillsHandler = require(ClientActor.SkillsHandler)


type CombatMod = SharedTypes.ClientCombatMachine
type FSM = SharedTypes.ClientStateMachine
type ItemData = SharedTypes.ItemData
local ClientCombatStates = {
    ["WeaponOut"] = {},
    ["Idle"] = {},
    
    ["HeavyAttack"] = {},
    ["LightAttack"] = {},
    ["Skill"] = {},

    ["TrueStun"] = {},
    ["SoftStun"] = {},
    
    ["Blocking"] = {},
    ["Parrying"] = {},
}
local Release  = function(ClientCombatMachine:CombatMod, StateMachine:FSM, Character:Model, Event:UnreliableRemoteEvent, FrameBuffer:buffer, ...)
    Character:SetAttribute("LockMove")
    ClientCombatMachine.ChangeToOldState(Character.Name) --TODO REMOVE this only server should release
    -- print("REMOVE THIS ↑")
end
local StopRun= function(ClientCombatMachine:CombatMod, StateMachine:FSM, Character:Model, Event:UnreliableRemoteEvent, FrameBuffer:buffer, ...)
    Event:FireServer(FrameBuffer)
    local WS = Character:GetAttribute("BaseWalkSpeed")
    local UID = Character.Name
    local Humanoid: SharedTypes.CustomHumanoid =  HumanoidMachine[UID]
    if not Humanoid then warn("error no humanoid: ", Character, Humanoid); return end 
    local Profile: CharacterHandler.Profile = CharacterHandler.GiveProfile(UID)
    if not Profile then warn("no profiel: ", UID, Profile); return end
    Profile.Forward:SendMessage("AdjustWS", WS)
    task.synchronize()
    Character:SetAttribute("WalkSpeed", WS)
end
local StunFunc = function(ClientCombatMachine:CombatMod, StateMachine:FSM, Character:Model, Event:UnreliableRemoteEvent, MyFrame, StateBuffer, ...)
    --* this action For PlayerCombat will only ever be triggered by the server Never on Client First
    --* therefore theres no real reason to update here as the CombatTickEvent Updates for you
    local UID = Character.Name    
    local Profile: CharacterHandler.Profile = CharacterHandler.GiveProfile(UID)
    if not Profile then warn("no Profile TrueStun Stun : ", StateMachine); return end
    Profile.Procedural:SendMessage("CancelAnim")
    Character:SetAttribute("LockMove", true)
    Particle_Handler.Hurt(Character)
end

local Idle:any = ClientCombatStates.Idle
local WeaponOut:any = ClientCombatStates.WeaponOut
local LightA:any = ClientCombatStates.LightAttack
local SStun:any = ClientCombatStates.SoftStun
local HeavyA = ClientCombatStates.HeavyAttack
local TStun = ClientCombatStates.TrueStun
local Blocking = ClientCombatStates.Blocking
Idle["ToolHandle"]=function(ClientCombatMachine:CombatMod, StateMachine:FSM, Character:Model, Event:UnreliableRemoteEvent,  Frame, FrameBuffer, ...)
    --*Server only action now
    local UID: string = Character.Name    
    ClientCombatMachine.ChangeState(UID, "WeaponOut", "Idle")    
end
Idle["Run"] =function(ClientCombatMachine:CombatMod, StateMachine:FSM, Character:Model, Event:UnreliableRemoteEvent, FrameBuffer:buffer, ...)
    local UID = Character.Name
    -- local Humanoid: SharedTypes.CustomHumanoid =  HumanoidMachine[UID]
    -- if not Humanoid then warn("error no humanoid: ", Character, Humanoid); return end 
    local Profile: CharacterHandler.Profile = CharacterHandler.GiveProfile(UID)
    if not Profile then warn("no profiel: ", UID, Profile); return end
    
    local WS = Character:GetAttribute("BaseWalkSpeed")
    local NewWS = WS * 2
    
    Profile.Forward:SendMessage("AdjustWS", NewWS)
    task.synchronize()
    Character:SetAttribute("WalkSpeed", NewWS)
end
Idle["StopRun"] = StopRun

WeaponOut["ToolHandle"]=function(ClientCombatMachine:CombatMod, StateMachine:FSM, Character:Model, Event:UnreliableRemoteEvent, Frame, FrameBuffer, ...)
    --* this action is From Server Only
    local UID: string = Character.Name    
    ClientCombatMachine.ChangeState(UID, "Idle", "Idle")        
end
WeaponOut["Block"] =function(ClientCombatMachine:CombatMod, StateMachine:FSM, Character:Model, Event:UnreliableRemoteEvent, FrameLookBuffer:buffer, ...) 
    ClientCombatMachine.ChangeState(Character.Name, "Blocking", "WeaponOut")
    ClientCombatMachine.TriggerAction(Character, Event, "Guard")   
end
WeaponOut["M1"] =function(ClientCombatMachine:CombatMod, StateMachine:FSM, Character:Model, Event:UnreliableRemoteEvent, ...)
    local UID = Character.Name
    ClientCombatMachine.ChangeState(UID, "LightAttack", "WeaponOut")
    ClientCombatMachine.TriggerAction(Character, Event, "Light") 
end
WeaponOut["M2"] =function(ClientCombatMachine:CombatMod, StateMachine:FSM, Character:Model, Event:UnreliableRemoteEvent, ...)
    local UID = Character.Name
    ClientCombatMachine.ChangeState(UID, "HeavyAttack", "WeaponOut")
    ClientCombatMachine.TriggerAction(Character, Event, "Heavy") 
end
WeaponOut["Run"] =function(ClientCombatMachine:CombatMod, StateMachine:FSM, Character:Model, Event:UnreliableRemoteEvent, FrameBuffer:buffer, ...)
    local UID = Character.Name
    -- local Humanoid: SharedTypes.CustomHumanoid =  HumanoidMachine[UID]
    -- if not Humanoid then warn("error no humanoid: ", Character, Humanoid); return end 
    local Profile: CharacterHandler.Profile = CharacterHandler.GiveProfile(UID)
    if not Profile then warn("no profiel: ", UID, Profile); return end
    
    Event:FireServer(FrameBuffer)
    local WS = Character:GetAttribute("BaseWalkSpeed")
    local NewWS = WS * 2
    
    Profile.Forward:SendMessage("AdjustWS", NewWS)
    task.synchronize()
    Character:SetAttribute("WalkSpeed", NewWS)
end
WeaponOut["StopRun"] = StopRun

LightA["Light"] =function(ClientCombatMachine:CombatMod, StateMachine:FSM, Character:Model, Event:UnreliableRemoteEvent, Frame, DirBuffer:buffer, ServerBool,...)
    if ServerBool then return end --* to prevent a double trigger when a client spams 
    local UID = Character.Name
    local Profile: CharacterHandler.Profile = CharacterHandler.GiveProfile(UID)
    if not Profile then warn("no Char profile"); return end
    local CurrentItem = Profile.CurrentItem
    local Func = SkillsHandler[CurrentItem .. "M1"]
    if not Func then ClientCombatMachine.TriggerAction(Character, Event, "Release"); warn("2 release Light"); return end

    local M1Count:number = StateMachine.M1Count
    local UnixMill = DateTime.now().UnixTimestampMillis
    M1Count += 1
    if M1Count > 3 then  M1Count = 1 end
    if UnixMill - StateMachine.M1ResetTime > 1500  then --* been longer than a second since the last m1 
        M1Count = 1
    end
    StateMachine.M1ResetTime = UnixMill
    StateMachine.M1Count = M1Count
    local Humanoid: SharedTypes.CustomHumanoid = HumanoidMachine[UID]
    local Data = {
        ["Profile"] = Profile,
        ["Humanoid"] = Humanoid,
        ["M1Count"] = M1Count,
        ["ItemName"] = CurrentItem
    }
    Func(ClientCombatMachine, StateMachine, Character, Data)
end
LightA["Release"]  = Release

HeavyA["Release"]  = Release
HeavyA["Heavy"] =function(ClientCombatMachine:CombatMod, StateMachine:FSM, Character:Model, Event:UnreliableRemoteEvent, Frame, DirBuffer:buffer, ServerBool,...)
    if ServerBool then return end --* to prevent a double trigger when a client spams 
    local UID = Character.Name
    local Profile: CharacterHandler.Profile = CharacterHandler.GiveProfile(UID)
    if not Profile then warn("no Char profile"); return end    
    local CurrentItem = Profile.CurrentItem
    local UnixMill = DateTime.now().UnixTimestampMillis
    StateMachine.M1ResetTime = UnixMill
    local Func = SkillsHandler[CurrentItem .. "M2"]
    if not Func then ClientCombatMachine.TriggerAction(Character, Event, "Release"); warn("2 release heavy"); return end
    local Humanoid: SharedTypes.CustomHumanoid = HumanoidMachine[UID]
    local Data = {
        ["Profile"] = Profile,
        ["Humanoid"] = Humanoid,
        ["ItemName"] = CurrentItem
    }
    Func(ClientCombatMachine, StateMachine, Character, Data)
end

TStun["GuardBroken"] = function(ClientCombatMachine:CombatMod, StateMachine:FSM, Character:Model, Event:UnreliableRemoteEvent, MyFrame, StateBuffer, ...)
    --TODO play the Guard Break Anim
    --* this action For PlayerCombat will only ever be  the server Never on Client First
    --* therefore theres no real reason to update here as the CombatTickEvent Updates for you
    --* Release for this will happen over the Server
    local UID = Character.Name
    local Profile: CharacterHandler.Profile = CharacterHandler.GiveProfile(UID)
    if not Profile then warn("no Profile GB : ", StateMachine); return end
    Profile.Forward:SendMessage("LockMove", true)
end
TStun["Stun"] = StunFunc
TStun["Release"] = Release

SStun["Release"] = Release
SStun["Stun"] = StunFunc

--*Blocking_Start 
Blocking["Guard"] = function(ClientCombatMachine:CombatMod, StateMachine:FSM, Character:Model, Event:UnreliableRemoteEvent, StateBuffer: buffer,_, ServerBool, ...)
    if ServerBool then return end
    local UID = Character.Name
    local Humanoid: SharedTypes.CustomHumanoid = HumanoidMachine[UID]
    if not Humanoid then warn("no Humanoid Bug Guard; ", HumanoidMachine); return end 
    local Profile: CharacterHandler.Profile = CharacterHandler.GiveProfile(UID)
    if not Profile then warn("no Profile GB : ", StateMachine); return end
    Profile.Forward:SendMessage("LockMove", true)
    Profile.Procedural:SendMessage("Anim", "SwordBlock", {2, 5,  4, 3}, {2, 5,  4, 3})
end 
Blocking["StopBlock"]= function(ClientCombatMachine:CombatMod, StateMachine:FSM, Character:Model, Event:UnreliableRemoteEvent, FrameLookBuffer:buffer, _, ServerBool, ...)
    if ServerBool then return end
    local UID = Character.Name
    local Profile: CharacterHandler.Profile = CharacterHandler.GiveProfile(UID)
    if not Profile then warn("no Profile GB : ", StateMachine); return end
    ClientCombatMachine.TriggerAction(Character, nil, "Release")
    Profile.Forward:SendMessage("LockMove")    
    Profile.Procedural:SendMessage("CancelAnim")
end
Blocking["Release"]  = Release

Blocking["Blocked"]= function(ClientCombatMachine:CombatMod, StateMachine:FSM, Character:Model, Event:UnreliableRemoteEvent, MyFrame, StateBuffer, ...)
    --* this action For PlayerCombat will only ever be triggered by the CombatTickEvent via the server Never on Client First
    --* therefore theres no real reason to update here as the CombatTickEvent Updates for you
    --* the Posture Event will be the sole thing responsible for Updating Posture More info in CLient_Handler, MainPostureScript
    task.synchronize()
    Particle_Handler.Blocked(Character)
    -- warn("done Block")
end
Blocking["Parried"]= function(ClientCombatMachine:CombatMod, StateMachine:FSM, Character:Model, Event:UnreliableRemoteEvent, MyFrame,  ...)
    --* this action For PlayerCombat will only ever be triggered by the CombatTickEvent via the server Never on Client First
    --* therefore theres no real reason to update here as the CombatTickEvent Updates for you
    Particle_Handler.Parried(Character)
end

return ClientCombatStates