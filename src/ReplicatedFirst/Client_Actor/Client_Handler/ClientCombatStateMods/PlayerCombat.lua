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

local ItemDataMod = require(Shared.ItemDataMod)

local Encyclopedia = require(Shared.Encyclopedia)
local SharedTypes = require(Shared.SharedType)
local AnimHandler = require(Shared.AnimHandler)
-- local HB = require(Shared.Hitbox)
-- local Encyclopedia = require(Shared.Encyclopedia)
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
local Idle:any = ClientCombatStates.Idle
local WeaponOut:any = ClientCombatStates.WeaponOut
local LightA:any = ClientCombatStates.LightAttack
local SStun:any = ClientCombatStates.SoftStun
local TStun = ClientCombatStates.TrueStun
local Blocking = ClientCombatStates.Blocking
--[[ --! Info For buffering CombatState
Length
UID
State
Action
CurrentFrame
--* 5 bytes
--* CCT =(Client combat tick)
Rule {
    when triggering an action from OutSide from this module then u Must update the CCT in that action
    For example ToolHandle Action
    Or Block Action in WeaponOut or Parried
}
]]
Idle["ToolHandle"]=function(ClientCombatMachine:CombatMod, StateMachine:FSM, Character:Model, Event:UnreliableRemoteEvent,  Frame, FrameBuffer, ...)
    --*Server only action now
    local ActiveToolbar:string = StateMachine.ActiveToolbar -- Toolbar1 or Toolbar2
    local Hotbar: {[string]: number}  = StateMachine[ActiveToolbar]
    
    local Key = buffer.readu8(FrameBuffer, 5)
    Key = NumToSymbol.GiveString(Key)    
    local ItemChosenNum = Hotbar[Key]
    if not ItemChosenNum then warn("no item: ", Key); return end
    local ItemName = Encyclopedia[ItemChosenNum]
    if not ItemName then warn("no item: ", Key , ItemName, ItemChosenNum); return end
    local ItemDataCopy = ItemDataMod.GiveCopyData(ItemName)
    if not ItemDataCopy then warn("incorrect Item name: ", ItemName); return end

    local UID: string = Character.Name
    
    ClientCombatMachine.ChangeState(UID, "WeaponOut", "Idle")    
    local Humanoid:SharedTypes.CustomHumanoid = HumanoidMachine[UID]
    if not Humanoid then warn("no humanoid: ", UID); return end
    local IdleAnimName:string =ItemName.."Idle"
    local IdleAnim:Animation = AnimHandler:GetAnim(IdleAnimName)
    if not IdleAnim then IdleAnimName = "HumanoidIdle"; end
    task.synchronize()
    Humanoid.Idle:Stop()
    Humanoid.Idle:Destroy()
    Humanoid.Idle = AnimHandler:LoadAnim(IdleAnimName, Humanoid.Animator)
    Humanoid.Idle:Play()
    StateMachine.CurrentItem = ItemName
    local PhysicalItem: Model = ItemManager.GiveWeapon(ItemName)
    if not PhysicalItem then warn("no physical item: ", ItemName); return end 
    local GetWeaponAnims = false
    local Char = Character  
    local RHGrip: Motor6D = Char.RightHand.RightGrip
    ItemManager.TweenEquip(RHGrip, PhysicalItem, Character, Humanoid.Animator, StateMachine)

    StateMachine.CurrentPhysicalItem = PhysicalItem
    StateMachine.Anims = {}

    for i = 1, 3 do 
        local AnimName =  ItemDataCopy.Type.."A"..i
        local Anim:Animation =  AnimHandler:GetAnim(AnimName)
        if not Anim then print("no Anim with that name: ", AnimName);  continue end --* init M1Strings for M1 mod
        StateMachine.Anims[i] = AnimName 
        GetWeaponAnims = true
    end
    local M2AnimName = ItemName.."M2"
    local M2Anim = AnimHandler:GetAnim(M2AnimName)
    if not M2Anim then warn("inccorrect item name: ", ItemName, M2AnimName); return end
    if not GetWeaponAnims then print("not  a weapon"); return end 
    StateMachine.WeaponItem = ItemName --* means its a Weapon
    StateMachine.Anims[4]  = "B"  --*B = Block 
    StateMachine.Anims[5] = "BH" --* BH = Block Hit
    StateMachine.Anims[6] = ItemName.."M2"
end
WeaponOut["ToolHandle"]=function(ClientCombatMachine:CombatMod, StateMachine:FSM, Character:Model, Event:UnreliableRemoteEvent, Frame, FrameBuffer, ...)
    --* this action is From Server Only
    local Key = buffer.readu8(FrameBuffer, 5)
    Key = NumToSymbol.GiveString(Key)
    local ActiveToolbar:string = StateMachine.ActiveToolbar -- Toolbar1 or Toolbar2
    local Hotbar: {[string]: number}  = StateMachine[ActiveToolbar]
    local ItemChosenNum = Hotbar[Key]
    if not ItemChosenNum then warn("no item: ", Key); return end
    if not StateMachine.CurrentItem then return end --* if they decide to unequip the item through Inventory Handler
    
    local UID: string = Character.Name    
    local Humanoid:SharedTypes.CustomHumanoid = HumanoidMachine[UID]
    if not Humanoid then warn("no humanoid: ", UID); return end
    ClientCombatMachine.ChangeState(UID, "Idle", "Idle")    
    
    task.synchronize()
    Humanoid.Idle:Stop()
    Humanoid.Idle:Play(1)
    local Char = Character  
    local RHGrip: Motor6D = Char.RightHand.RightGrip
    local PhysicalItem = StateMachine.CurrentPhysicalItem 
    ItemManager.TweenUnequip(RHGrip, PhysicalItem, Character, Humanoid.Animator, StateMachine)
    StateMachine.CurrentPhysicalItem= nil
    StateMachine.CurrentItem = nil
    StateMachine.Anims = {}
end
--*LightA
WeaponOut["M1"] =function(ClientCombatMachine:CombatMod, StateMachine:FSM, Character:Model, Event:UnreliableRemoteEvent, Frame, DirBuffer:buffer, ...)
    --* DirBuffer = 5
    local Weapon = StateMachine.CurrentItem
    if not Weapon then warn("No Weapon ", StateMachine); return end
    local Length = 9
    local StateBuffer = buffer.create(Length) 
    local Writeu8 = buffer.writeu8 
    local UID = Character.Name
    local StateNum = 4 -- * LightAttack
    local ActionNum = 13 --* Light (M1 -> Light) avoids Double Trig 
    Writeu8(StateBuffer, 0, Length)
    Writeu8(StateBuffer, 1, UID)
    Writeu8(StateBuffer, 2, StateNum) --* WeaponOut
    Writeu8(StateBuffer, 3, ActionNum) --* M1
    Writeu8(StateBuffer, 4, Frame) --* M1
    ClientMessage.SendToClientActor("UpdateProfile", StateBuffer)
    -- buffer.copy(StateBuffer, 5, DirBuffer, 1, buffer.len(DirBuffer)-1)
    ClientCombatMachine.ChangeState(UID, "LightAttack", "WeaponOut")
    ClientCombatMachine.TriggerAction(Character, Event, "Light", Frame, DirBuffer) 
    --* update Client SnapShot at the Frame from Frame lookbuffer  
    task.synchronize()
    Event:FireServer(DirBuffer) --* M1Event To Queue up
end
LightA["Light"] =function(ClientCombatMachine:CombatMod, StateMachine:FSM, Character:Model, Event:UnreliableRemoteEvent, Frame, DirBuffer:buffer, ServerBool,...)
    if ServerBool then return end --* to prevent a double trigger when a client spams 
    task.desynchronize()
    local CurrentItem = StateMachine.CurrentItem
    if not StateMachine.Anims then warn("no m1String"); return end    
    
    local M1Count:number = StateMachine.M1Count
    local UnixMill = DateTime.now().UnixTimestampMillis
    M1Count += 1
    if M1Count >= 4 then  M1Count = 1 end
    if  UnixMill - StateMachine.M1ResetTime > 1500  then --* been longer than a second since the last m1 
        M1Count = 1
    end
    StateMachine.M1ResetTime = UnixMill
    StateMachine.M1Count = M1Count

    local AnimName:string = StateMachine.Anims[M1Count]
    local Anim:Animation = AnimHandler:GetAnim(AnimName)
    if not Anim  then ClientCombatMachine.TriggerAction(Character, Event, "Release"); warn("1 release Light", Anim); return end
    local Func = SkillsHandler[CurrentItem .. "M1"]
    if not Func then ClientCombatMachine.TriggerAction(Character, Event, "Release"); warn("2 release Light"); return end
    local Readi16 = buffer.readi16

    local rx:number,  rz:number= Readi16(DirBuffer, 1), Readi16(DirBuffer, 3)
    local Direction:Vector3 = Vector3.new(rx, 0, rz).Unit
    local Body = Character.PrimaryPart
    local CF = CFrame.lookAlong(Body.Position, Direction, Body.CFrame.UpVector) 
    local UID = Character.Name
    local Profile: CharacterHandler.Profile = CharacterHandler.GiveProfile(UID)
    local Humanoid: SharedTypes.CustomHumanoid = HumanoidMachine[UID]
    if not  Profile then warn("no Char profile"); return end
    Profile.Forward:SendMessage("LockMove", true)

    local Data = {
        ["Profile"] = Profile,
        ["AnimName"] = AnimName,
        ["Humanoid"] = Humanoid,
        ["ItemName"] = CurrentItem
    }
    Func(ClientCombatMachine, StateMachine, Character, Data)
    
    --// ClientCombatMachine.ChangeToOldState(UID) 
    task.synchronize()
    Body.CFrame = CF
end
--*Sprint
WeaponOut["Run"] =function(ClientCombatMachine:CombatMod, StateMachine:FSM, Character:Model, Event:UnreliableRemoteEvent, FrameBuffer:buffer, ...)
    local UID = Character.Name
    local Humanoid: SharedTypes.CustomHumanoid =  HumanoidMachine[UID]
    if not Humanoid then warn("error no humanoid: ", Character, Humanoid); return end 
    local Profile: CharacterHandler.Profile = CharacterHandler.GiveProfile(UID)
    if not Profile then warn("no profiel: ", UID, Profile); return end
    
    Event:FireServer(FrameBuffer)
    local WS = Character:GetAttribute("BaseWalkSpeed")
    local NewWS = WS * 2
    local ItemName:string? = StateMachine.CurrentItem
    Humanoid.Walk:Stop()
    Humanoid.Walk:Destroy()
    if not ItemName then Humanoid.Walk = AnimHandler:LoadAnim("HumanoidRun", Humanoid.Animator); return end

    local AnimName:string = ItemName.."Run"
    local Anim:Animation = AnimHandler:GetAnim(AnimName)
    if not Anim then  Humanoid.Walk = AnimHandler:LoadAnim("HumanoidRun", Humanoid.Animator); return end
    Humanoid.Walk = AnimHandler:LoadAnim(AnimName, Humanoid.Animator)
    Humanoid.Walk:Play()
    Humanoid.Walk:AdjustSpeed(NewWS/10)
    Profile.Forward:SendMessage("AdjustWS", NewWS)
    task.synchronize()
    Character:SetAttribute("WalkSpeed", NewWS)
end
Idle["Run"] =function(ClientCombatMachine:CombatMod, StateMachine:FSM, Character:Model, Event:UnreliableRemoteEvent, FrameBuffer:buffer, ...)
    local UID = Character.Name
    local Humanoid: SharedTypes.CustomHumanoid =  HumanoidMachine[UID]
    if not Humanoid then warn("error no humanoid: ", Character, Humanoid); return end 
    local Profile: CharacterHandler.Profile = CharacterHandler.GiveProfile(UID)
    if not Profile then warn("no profiel: ", UID, Profile); return end
    
    Event:FireServer(FrameBuffer)
    local WS = Character:GetAttribute("BaseWalkSpeed")
    local NewWS = WS * 2
    Humanoid.Walk:Stop()
    Humanoid.Walk:Destroy()
    Humanoid.Walk = AnimHandler:LoadAnim("HumanoidRun", Humanoid.Animator)
    Humanoid.Walk:Play()
    Humanoid.Walk:AdjustSpeed(NewWS/10)
    Profile.Forward:SendMessage("AdjustWS", NewWS)
    task.synchronize()
    Character:SetAttribute("WalkSpeed", NewWS)
end
local StopRun= function(ClientCombatMachine:CombatMod, StateMachine:FSM, Character:Model, Event:UnreliableRemoteEvent, FrameBuffer:buffer, ...)
    Event:FireServer(FrameBuffer)
    local WS = Character:GetAttribute("BaseWalkSpeed")
    local UID = Character.Name
    local Humanoid: SharedTypes.CustomHumanoid =  HumanoidMachine[UID]
    if not Humanoid then warn("error no humanoid: ", Character, Humanoid); return end 
    local Profile: CharacterHandler.Profile = CharacterHandler.GiveProfile(UID)
    if not Profile then warn("no profiel: ", UID, Profile); return end
    Humanoid.Walk:Stop()
    Humanoid.Walk:Destroy()
    Humanoid.Walk = AnimHandler:LoadAnim("HumanoidWalk", Humanoid.Animator); 
    Humanoid.Walk:Play(0.4)
    Profile.Forward:SendMessage("AdjustWS", WS)
    task.synchronize()
    Character:SetAttribute("WalkSpeed", WS)
end
WeaponOut["StopRun"] = StopRun
Idle["StopRun"] = StopRun
--[[
Idle["SoftStun"] = function(ClientCombatMachine:CombatMod, StateMachine:FSM, Character:Model, Event:UnreliableRemoteEvent, ...)
    ClientCombatMachine.ChangeState(Character.Name, "SoftStun", "Idle")
    ClientCombatMachine.TriggerAction(Character, Event, "Stun", ...)
end
WeaponOut["SoftStun"] = function(ClientCombatMachine:CombatMod, StateMachine:FSM, Character:Model, Event:UnreliableRemoteEvent, ...)
    ClientCombatMachine.ChangeState(Character.Name, "SoftStun", "Idle")
    ClientCombatMachine.TriggerAction(Character, Event, "Stun", ...)
end
Blocking["SoftStun"] = function(ClientCombatMachine:CombatMod, StateMachine:FSM, Character:Model, Event:UnreliableRemoteEvent,  ...)
    --* transferring action  do not update here
    local CDTable = StateMachine.CDs
    local UnixMill  = DateTime.now().UnixTimestampMillis
    local ParryStarted = CDTable["ParryStart"]
    if not ParryStarted then print("parry not started"); return end
    local ParryCD = CDTable["ParryCD"]
    if not ParryCD then ParryCD = UnixMill end
    local ParryCDCheck = UnixMill - ParryCD
    if ParryCDCheck > 1200 then 
        --*it means 1 second has passed since they last tried parrying accept it this time
        local Check = UnixMill - ParryStarted
        --*less than 0.35s since they started blocking so accept Parry
        if Check <= 350 then ClientCombatMachine.TriggerAction(Character, Event, "Parried", ...) end    
        CDTable.ParryCD = UnixMill        
        return
    end
    ClientCombatMachine.TriggerAction(Character, Event, "Blocked", ...)
end

]]
--[[
TStun["Dead"] =  function(ClientCombatMachine:CombatMod, StateMachine:FSM, Character:Model, Event:UnreliableRemoteEvent,  ...)
    --TODO Ragdoll,Parent to Dead here,  no need to fire event cos Server should already know
    --! Trigger Dead from Health Event ONLY cos Client and Server Health may differ  better to wait for the correction
end

]]
TStun["GuardBroken"] = function(ClientCombatMachine:CombatMod, StateMachine:FSM, Character:Model, Event:UnreliableRemoteEvent, MyFrame, StateBuffer, ...)
    --TODO play the Guard Break Anim
    --* this action For PlayerCombat will only ever be triggered by the CombatTickEvent via the server Never on Client First
    --* therefore theres no real reason to update here as the CombatTickEvent Updates for you
    if StateMachine.CurrentAction then task.synchronize(); StateMachine.CurrentAction:Stop(); StateMachine.CurrentAction:Destroy() end --*should stop Block
    local AttackerUID = buffer.readu8(StateBuffer, 5)
    local AttackerStateMachine:FSM = ClientCombatMachine[tostring(AttackerUID)]
    if not AttackerStateMachine then warn("no attacker FSM: ", AttackerUID, ClientCombatMachine); return end
    local CurrentItem = AttackerStateMachine.CurrentItem
    local WeaponData = ItemDataMod.GiveCopyData(CurrentItem)

    local UID = Character.Name
    local Profile: CharacterHandler.Profile = CharacterHandler.GiveProfile(UID)
    if not Profile then warn("no Profile GB : ", StateMachine); return end
    local Humanoid:SharedTypes.CustomHumanoid = HumanoidMachine[UID]
    Profile.Forward:SendMessage("LockMove", true)
    if StateMachine.SStun then task.cancel(StateMachine.SStun);  end                  
    if StateMachine.TStun then task.cancel(StateMachine.TStun);  end
    StateMachine.TStun = task.delay((WeaponData.Stun +2) /2, function() ClientCombatMachine.TriggerAction(Character, nil, "Release", Profile)     end)
    local Atrack = AnimHandler:LoadAnim("GB", Humanoid.Animator)
    Atrack:Play()
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
LightA["Release"]  = Release
SStun["Release"] = Release

--*Blocking_Start 
Blocking["Guard"] = function(ClientCombatMachine:CombatMod, StateMachine:FSM, Character:Model, Event:UnreliableRemoteEvent, StateBuffer: buffer,_, ServerBool, ...)
    if ServerBool then return end
    local CurrentItem = StateMachine.WeaponItem 
    if not CurrentItem then warn("how no weapon Item Block ??",  CurrentItem); return end
    local Readi16 = buffer.readi16
    local rx:number,  rz:number= Readi16(StateBuffer, 5), Readi16(StateBuffer, 7)
    local Direction:Vector3 = Vector3.new(rx, 0, rz).Unit
    local Body = Character.PrimaryPart
    local CF = CFrame.lookAlong(Body.Position, Direction, Body.CFrame.UpVector) 
    local UID = Character.Name

    local Humanoid: SharedTypes.CustomHumanoid = HumanoidMachine[UID]
    if not Humanoid then warn("no Humanoid Bug Guard; ", HumanoidMachine); return end 
    local AnimName:string = StateMachine.Anims[4] --*ItemNameB = Block Anim 
    if not AnimName then warn("WTF did not Load Block Anim; ", StateMachine, StateMachine.Anims); return end 
    local ATrack = AnimHandler:LoadAnim(AnimName, Humanoid.Animator)
    local Profile: CharacterHandler.Profile = CharacterHandler.GiveProfile(UID)
    if not Profile then warn("no Profile GB : ", StateMachine); return end
    Profile.Forward:SendMessage("LockMove", true)
    --*already updated CCT 
    StateMachine.CurrentAction = ATrack
    StateMachine.CDs.ParryStart = DateTime.now().UnixTimestampMillis
    task.synchronize()
    ATrack:Play(0.2)
    Body.CFrame = CF
end 
Blocking["StopBlock"]= function(ClientCombatMachine:CombatMod, StateMachine:FSM, Character:Model, Event:UnreliableRemoteEvent, FrameLookBuffer:buffer, _, ServerBool, ...)
    if ServerBool then return end
    --* this is a Transferring Action
    --* framelook buffer = 5
    local Weapon = StateMachine.WeaponItem
    if not Weapon then warn("not a weapon : ", Weapon); return end
    local UID = Character.Name
    local Profile: CharacterHandler.Profile = CharacterHandler.GiveProfile(UID)
    if not Profile then warn("no Profile GB : ", StateMachine); return end
    Profile.Forward:SendMessage("LockMove")

    local Length = 5
    local StateBuffer = buffer.create(Length) 
    local Writeu8 = buffer.writeu8 
    
    local OldState =  ClientCombatMachine.ChangeToOldState(UID)
    local StateNum = Encyclopedia.GiveNumRef(OldState) --* Most likely WeaponOut 
    if not StateNum then warn("incorrect OldState ", StateNum, OldState); return end 
    local ActionNum = 25 --* Return
    local CurrentFrame = buffer.readu8(FrameLookBuffer, 0)
    Writeu8(StateBuffer, 0, Length)
    Writeu8(StateBuffer, 1, UID)
    Writeu8(StateBuffer, 2, StateNum) --* WeaponOut
    Writeu8(StateBuffer, 3, ActionNum) --* Return
    Writeu8(StateBuffer, 4, CurrentFrame) 

    ClientMessage.SendToClientActor("UpdWithFrame", StateBuffer)
    task.synchronize()
    if StateMachine.CurrentAction then StateMachine.CurrentAction:Stop(); StateMachine.CurrentAction:Destroy() end
    Event:FireServer(StateBuffer) --* StopBlockEvent
end
Blocking["Blocked"]= function(ClientCombatMachine:CombatMod, StateMachine:FSM, Character:Model, Event:UnreliableRemoteEvent, MyFrame, StateBuffer, ...)
    --* this action For PlayerCombat will only ever be triggered by the CombatTickEvent via the server Never on Client First
    --* therefore theres no real reason to update here as the CombatTickEvent Updates for you
    --* the Posture Event will be the sole thing responsible for Updating Posture More info in CLient_Handler, MainPostureScript
    local UID = Character.Name    
    local Humanoid: SharedTypes.CustomHumanoid = HumanoidMachine[UID]
    if not Humanoid then warn("no Humanoid; ", HumanoidMachine); return end 
    local AnimName:string = StateMachine.Anims[5] --*BH = Block Hit = AnimName
    if not AnimName then warn("WTF did not Load Block Anim; ", StateMachine, StateMachine.Anims); return end 
    local ATrack = AnimHandler:LoadAnim(AnimName, Humanoid.Animator)
    task.synchronize()
    ATrack:Play()
    Particle_Handler.Blocked(Character)
    -- warn("done Block")
end
WeaponOut["Block"] =function(ClientCombatMachine:CombatMod, StateMachine:FSM, Character:Model, Event:UnreliableRemoteEvent, FrameLookBuffer:buffer, ...)
    --* this action is a transferring action so do NOT Buffer the player State with 2, 14
    --* framelook buffer = 5
    local Weapon = StateMachine.WeaponItem
    if not Weapon then warn("not a weapon : ", Weapon); return end
    task.synchronize()
    Event:FireServer(FrameLookBuffer) --* BlockEvent
    task.desynchronize()
    local Length = 9
    local StateBuffer = buffer.create(Length) 
    local Writeu8 = buffer.writeu8 
    local UID = Character.Name
    
    local StateNum = 3 --* Blocking
    local ActionNum = 18 --* Guard
    Writeu8(StateBuffer, 0, Length)
    Writeu8(StateBuffer, 1, UID)
    Writeu8(StateBuffer, 2, StateNum)  
    Writeu8(StateBuffer, 3, ActionNum) 
    buffer.copy(StateBuffer, 4, FrameLookBuffer, 0, buffer.len(FrameLookBuffer))
    
    ClientMessage.SendToClientActor("UpdWithFrame", StateBuffer)
    ClientCombatMachine.ChangeState(UID, "Blocking", "WeaponOut")
    ClientCombatMachine.TriggerAction(Character, Event, "Guard", StateBuffer)   
end
Blocking["Parried"]= function(ClientCombatMachine:CombatMod, StateMachine:FSM, Character:Model, Event:UnreliableRemoteEvent, MyFrame,  ...)
    --* this action For PlayerCombat will only ever be triggered by the CombatTickEvent via the server Never on Client First
    --* therefore theres no real reason to update here as the CombatTickEvent Updates for you
    local CurrentItem = StateMachine.WeaponItem 
    if not CurrentItem then warn("no Weapon Item equipped in Blocked ??",  CurrentItem); return end
    local UID = Character.Name
    local Humanoid: SharedTypes.CustomHumanoid = HumanoidMachine[UID]
    if not Humanoid then warn("no Humanoid some how: "); return end
    local Atrack = AnimHandler:LoadAnim("Parry", Humanoid.Animator)
    --TODO knockback
    --[[ --TODO remove
    -- local StateNum = 3
    -- local ActionNum = 16
    -- UPDATE_CLIENTCOMBATTICK(5, UID, StateNum, ActionNum, MyFrame)
    
    ]]
    task.synchronize()
    Atrack:Play()
    Particle_Handler.Parried(Character)
end
return ClientCombatStates

--[[ --* Done 24/05/2024  See Client_HandlerScript LoadGameState for more info
{
    30fps tick on Server and Client
    during init proccess do get everyone on the same frame number
    fire (FrameNumber, UnixtimeStampMillis) then do Current Millis Subtract from Server UnixMillis
    then Multiply by 1/30 ~= 0.033332
    so for example
        --FromServer: FrameCount, ServerUnix
        FrameCount(Server) = 3,  Clientunix - ServerUnix = 100
        100/33.2 ~= 3.012....
        100ms/ 33.2ms == 0.1/ 0.03332
        so then the server Frame would approximately be around 6 now after the Client received 3 
        so then Client and Server FrameCount = 6 (as long as they are within the same frame its fine)
        Reset the Frame Count every 30 Frames
        --*Store upto 14 frames == ~466 ms wihich would encompass 99% of players
        --* info being stored would only be UID, STATE, CURRENT_ACTION = 3 bytes
        --! With CURRENT_ACTION and STATE compare with Client Version of it then if not Same then Play The Action
        --TODO i would have to Change Combat Init and On Client SAVE OtherPlayers HotBar info            
}
]]
            