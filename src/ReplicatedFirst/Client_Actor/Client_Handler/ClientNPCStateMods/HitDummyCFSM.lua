local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared

local ClientCombatMachine = require(script.Parent.Parent.Parent.ClientCombatMachine)
local SkillsHandler = require(Shared.SkillsHandler)
local AnimHandler = require(Shared.AnimHandler)
local HumanoidMachine = require(Shared.HumanoidMachine)
local ItemManager = require(Shared.ItemManager)
local SharedTypes = require(Shared.SharedType)

local ClientActor = script.Parent.Parent
local CharacterHandler = require(ClientActor.Character_Handler)

type CombatMod = SharedTypes.ClientCombatMachine
type FSM = SharedTypes.ClientStateMachine
type ItemDataMod = SharedTypes.ItemDataMod
local HitDummyCFSM = {
    ["Idle"] = {},    
    ["TrueStun"] = {},
    ["SoftStun"] = {},
    ["WeaponOut"] = {},
    ["LightAttack"] = {}
}

local frameDifference = function (MyFrame: number, PastFrame: number)
    local CycleLength = 30  -- Total number of frames
    local frameDuration = 1/30  -- Duration of each frame in seconds (~0.3333 s) 
    local difference
    if MyFrame < PastFrame then 
        difference = (MyFrame - PastFrame) + CycleLength
    else
        difference = (MyFrame - PastFrame)
    end
    local timeDifference = difference * frameDuration --* in seconds
    return timeDifference :: number
end
local Idle:any = HitDummyCFSM.Idle
local SStun:any = HitDummyCFSM.SoftStun
local TStun:any = HitDummyCFSM.TrueStun
local LightA:any = HitDummyCFSM.LightAttack
local WeaponOut:any = HitDummyCFSM.WeaponOut
--* TrueStun_Start
TStun["Dead"] =  function(ClientCombatMachine:CombatMod, StateMachine:FSM, Character:Model, Event:UnreliableRemoteEvent,  ...)
    --TODO Ragdoll,Parent to Dead here,  no need to fire event cos Server should already know
    --! Trigger Dead from Health Event ONLY cos Client and Server Health may differ  better to wait for the correction
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
Idle["InitIdle"] =  function(ClientCombatMachine:CombatMod, StateMachine:FSM, Character:Model, Event:UnreliableRemoteEvent, NPCData:SharedTypes.NPCData, ...)
    local WeaponName = NPCData.Weapon
    if not WeaponName then warn("No Weapon HitDummy"); return end
    StateMachine.CurrentItem = WeaponName
    local PhysicalItem: Model = ItemManager.GiveWeapon(WeaponName)
    if not PhysicalItem then warn("no physical item: ", WeaponName); return end 
    local Char = Character
    local Humanoid:SharedTypes.CustomHumanoid = HumanoidMachine[Char.Name]
    local RHGrip: Motor6D = Char.RightHand.RightGrip
    ItemManager.TweenEquip(RHGrip, PhysicalItem, Character, Humanoid.Animator)
    StateMachine.CurrentPhysicalItem = PhysicalItem
    StateMachine.Anims = {}
    for i = 1, 3 do 
        local AnimName =  WeaponName.."A"..i
        local Anim:Animation =  AnimHandler:GetAnim(AnimName)
        if not Anim then print("no Anim with that name: ", AnimName);  continue end --* init M1Strings for M1 mod
        StateMachine.Anims[i] = AnimName 
    end
    ClientCombatMachine.ChangeState(Char.Name, "WeaponOut", "WeaponOut")
end
--*LightA
WeaponOut["M1"] =function(ClientCombatMachine:CombatMod, StateMachine:FSM, Character:Model, Event:UnreliableRemoteEvent, ...)
    ClientCombatMachine.ChangeState(Character.Name, "LightAttack", "WeaponOut")
    ClientCombatMachine.TriggerAction(Character, nil, "LightA")
end
LightA["Light"] =function(ClientCombatMachine:CombatMod, StateMachine:FSM, Character:Model, Event:UnreliableRemoteEvent, MyFrame, StateBuffer:buffer, ...)
    --* 4th byte is ClientFrame Recieved in StateBuffer
    local Readu8 = buffer.readu8
    local OtherClientFrame = Readu8(StateBuffer, 4)
    local Diff = frameDifference(MyFrame, OtherClientFrame) --* in seconds 
    if Diff >= 0.332 then Diff = 0.332 end 
    local CurrentItem:string = StateMachine.CurrentItem or ""
    if not StateMachine.Anims then warn("no m1String"); return end
    StateMachine.M1Count += 1
    if StateMachine.M1Count >= 4 then  StateMachine.M1Count = 1 end
    local M1Count:number = StateMachine.M1Count
    local AnimName:string = StateMachine.Anims[M1Count]
    local Anim:Animation = AnimHandler:GetAnim(AnimName)
    if not Anim  then ClientCombatMachine.TriggerAction(Character, Event, "Release"); warn("1 release Light", Anim); return end
    local Func = SkillsHandler[CurrentItem .. "M1"]
    if not Func then ClientCombatMachine.TriggerAction(Character, Event, "Release"); warn("2 release Light"); return end
    local Readi16 = buffer.readi16
    local rx:number,  rz:number= Readi16(StateBuffer, 5), Readi16(StateBuffer, 7)
    local Direction:Vector3 = Vector3.new(rx, 0, rz).Unit
    local Body = Character.PrimaryPart
    local CF = CFrame.lookAlong(Body.Position, Direction, Body.CFrame.UpVector) 
    local UID = Character.Name
    local Profile: CharacterHandler.Profile = CharacterHandler.GiveProfile(UID)
    local Humanoid: SharedTypes.CustomHumanoid = HumanoidMachine[UID]
    if not  Profile then warn("no Char profile"); return end
    local Data = {
        ["Profile"] = Profile,
        ["AnimName"] = AnimName,
        ["Humanoid"] = Humanoid,
        ["ItemName"] = CurrentItem,
    }
    local ATrack: AnimationTrack= Func(ClientCombatMachine, StateMachine, Character, Data)
    ATrack.TimePosition = Diff
    --// ClientCombatMachine.ChangeToOldState(UID) 
    task.synchronize()
    Body.CFrame = CF
end
LightA["Release"] =function(ClientCombatMachine:CombatMod, StateMachine:FSM, Character:Model, Event:UnreliableRemoteEvent, ...)
    ClientCombatMachine.ChangeToOldState(Character.Name)
end

return HitDummyCFSM