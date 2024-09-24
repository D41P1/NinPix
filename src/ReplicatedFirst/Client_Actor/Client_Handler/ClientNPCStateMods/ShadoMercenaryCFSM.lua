--[[ Some info
this CFSM is exactly the same as HitDummy

]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared
local ItemDataMod = require(Shared.ItemDataMod)
local AnimHandler = require(Shared.AnimHandler)
local HumanoidMachine = require(Shared.HumanoidMachine)
local ItemManager = require(Shared.ItemManager)
local SharedTypes = require(Shared.SharedType)

local ClientActor = script.Parent.Parent.Parent
local Particle_Handler = require(ClientActor.Client_Handler.SkillsFolder.Particle_Handler)
local CharacterHandler = require(ClientActor.Client_Handler.Character_Handler)
local SkillsHandler = require(ClientActor.Client_Handler.SkillsHandler)

type CombatMod = SharedTypes.ClientCombatMachine
type FSM = SharedTypes.ClientStateMachine
type ItemDataMod = SharedTypes.ItemData
local ShadoMercenaryCFSM = {
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
local Idle:any = ShadoMercenaryCFSM.Idle
local SStun:any = ShadoMercenaryCFSM.SoftStun
local TStun:any = ShadoMercenaryCFSM.TrueStun
local LightA:any = ShadoMercenaryCFSM.LightAttack
local WeaponOut:any = ShadoMercenaryCFSM.WeaponOut
--* TrueStun_Start
TStun["Dead"] =  function(ClientCombatMachine:CombatMod, StateMachine:FSM, Character:Model, Event:UnreliableRemoteEvent,  ...)
    --TODO Ragdoll,Parent to Dead here,  no need to fire event cos Server should already know
    --! Trigger Dead from Health Event ONLY cos Client and Server Health may differ  better to wait for the correction
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
Idle["InitIdle"] =  function(ClientCombatMachine:CombatMod, StateMachine:FSM, Character:Model, Event:UnreliableRemoteEvent, NPCData:SharedTypes.NPCData, ...)
    local WeaponName = NPCData.Weapon
    if not WeaponName then warn("No Weapon HitDummy"); return end
StateMachine.CurrentItem = WeaponName
    local PhysicalItem: Model = ItemManager.GiveWeapon(WeaponName)
    if not PhysicalItem then warn("no physical item: ", WeaponName); return end 
    local Char = Character
    local Humanoid:SharedTypes.CustomHumanoid = HumanoidMachine[Char.Name]
    local RHGrip: Motor6D = Char.RightHand.RightGrip
    ItemManager.TweenEquip(RHGrip, PhysicalItem, Character, Humanoid.Animator, StateMachine)
    StateMachine.CurrentPhysicalItem = PhysicalItem
    StateMachine.Anims = {}
    for i = 1, 3 do 
        local AnimName =  WeaponName.."A"..i
        local Anim:Animation =  AnimHandler:GetAnim(AnimName)
        if not Anim then print("no Anim with that name: ", AnimName);  continue end --* init M1Strings for M1 mod
        StateMachine.Anims[i] = AnimName 
    end
    ClientCombatMachine.ChangeState(Char.Name, "WeaponOut", "WeaponOut")
    --* this is to init the State into the CombatTick
    local StateBuffer = buffer.create(5)
    local Writeu8 = buffer.writeu8
    local State = 1 --*Blocking,Idle,WeaponOut , ... etc
    local Action = 1 --*Blocked, Parried, Block, M1, ... etc
    local UID = Character.Name
    UID = tonumber(UID)
    Writeu8(StateBuffer, 0, 5)
    Writeu8(StateBuffer, 1, UID)
    Writeu8(StateBuffer, 2, State)
    Writeu8(StateBuffer, 3, Action)    
    ClientActor:SendMessage("UpdWithFrame", StateBuffer)
end
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
    local M1Count:number = StateMachine.M1Count
    local UnixMill = DateTime.now().UnixTimestampMillis
    M1Count += 1
    if M1Count >= 4 then  M1Count = 1 end
    if UnixMill - StateMachine.M1ResetTime > 1000  then --* been longer than a second since the last m1 
        M1Count = 1
    end
    local TypeHit = 0
    if M1Count == 3 then 
        TypeHit = 1
    end
    StateMachine.M1ResetTime = UnixMill
    
    local AnimName:string = StateMachine.Anims[M1Count]
    local Anim:Animation = AnimHandler:GetAnim(AnimName)
    if not Anim  then ClientCombatMachine.TriggerAction(Character, Event, "Release"); warn("1 release Light", Anim); return end
    local Func = SkillsHandler[CurrentItem .. "M1"]
    if not Func then ClientCombatMachine.TriggerAction(Character, Event, "Release"); warn("2 release Light"); return end
    local Readi16 = buffer.readi16
    local Angle = Readi16(StateBuffer, 5)
    Angle += 1e-8 --* prevent nanvalues
    Angle /= 1000
    local Z = math.sin(Angle)
    local X= math.cos(Angle)
    local Direction = Vector3.new(X, 0, Z).Unit --* must be Unit
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
local Release  = function(ClientCombatMachine:CombatMod, StateMachine:FSM, Character:Model, Event:UnreliableRemoteEvent, FrameBuffer:buffer, ...)
    local UID = Character.Name
    local Profile: CharacterHandler.Profile = CharacterHandler.GiveProfile(UID)
    if not Profile then warn("no profiel: ", UID, Profile); return end
    local ForwardActor: Actor = Profile.Forward 
    ForwardActor:SendMessage("LockMove")
end
TStun["Release"] = Release
LightA["Release"]  = Release
SStun["Release"] = Release


return ShadoMercenaryCFSM