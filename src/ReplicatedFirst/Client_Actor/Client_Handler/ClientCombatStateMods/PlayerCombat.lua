local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared

local SkillsHandler = require(Shared.SkillsHandler)
local Encyclopedia = require(Shared.Encyclopedia)
local SharedTypes = require(Shared.SharedType)
local AnimHandler = require(Shared.AnimHandler)
-- local HB = require(Shared.Hitbox)
--local Encyclopedia = require(Shared.Encyclopedia)
local HumanoidMachine = require(Shared.HumanoidMachine)
local NumToSymbol = require(Shared.NumToSymbol)
local ItemManager = require(Shared.ItemManager)

local ClientActor = script.Parent.Parent
local CharacterHandler = require(ClientActor.Character_Handler)
local Gui_Handler = require(ClientActor.Gui_Handler)
local ClientMessage = require(ClientActor.Parent.ClientMessageAPI)

type CombatMod = SharedTypes.ClientCombatMachine
type FSM = SharedTypes.ClientStateMachine
type ItemDataMod = SharedTypes.ItemDataMod
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
local UPDATE_CLIENTCOMBATTICK = function(Length:number, UID:string, StateNum:number, ActionNum:number, CurrentFrame:number) 
    local StateBuffer = buffer.create(5)
    local Writeu8 = buffer.writeu8
    local State = StateNum --*Blocking,Idle,WeaponOut , ... etc
    local Action = ActionNum --*Blocked, Parried, Block, M1, ... etc
    Writeu8(StateBuffer, 0, Length)
    buffer.writestring(StateBuffer, 1, UID, 1)
    Writeu8(StateBuffer, 2, State)
    Writeu8(StateBuffer, 3, Action)
    Writeu8(StateBuffer, 4, CurrentFrame)
    ClientMessage.SendToClientActor("UpdWithFrame", StateBuffer)    
end

--[[ --TODO Future
Add PlayerStats to the StateMachine
]]

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
Idle["ToolHandle"]=function(ClientCombatMachine:CombatMod, StateMachine:FSM, Character:Model, Event:UnreliableRemoteEvent, Key, FrameBuffer, ...)
    local ActiveHotbar:string = StateMachine.ActiveHotbar -- HotBar1 or HotBar2
    local Hotbar: {[string]: number}  = StateMachine[ActiveHotbar]
    local ItemChosenNum = Hotbar[Key]
    if not ItemChosenNum then warn("no item: ", Key); return end
    local ItemName = Encyclopedia[ItemChosenNum]
    local Writeu8 = buffer.writeu8
    local NumString: number = NumToSymbol.GiveNum(Key)
    Writeu8(FrameBuffer, 1, NumString)
    --*2 bytes 2nd is the Key Pressed    
    Event:FireServer(FrameBuffer)
    local UID: string = Character.Name
    local StateNum: number = 1 -- Idle
    local ActionNum: number =  8 -- ToolHandle
    local CurrentFrame: number, Length  = buffer.readu8(FrameBuffer, 0), 5
    local StateBuffer: buffer = buffer.create(Length)
    
    Writeu8(StateBuffer, 0, Length);        buffer.writestring(StateBuffer, 1, UID, 1);          Writeu8(StateBuffer, 2, StateNum)
    Writeu8(StateBuffer, 3, ActionNum);     Writeu8(StateBuffer, 4, CurrentFrame)
    
    ClientCombatMachine.ChangeState(UID, "WeaponOut", "Idle")    
    ClientMessage.SendToClientActor("UpdWithFrame", StateBuffer)
    local Humanoid:SharedTypes.CustomHumanoid = HumanoidMachine[UID]
    if not Humanoid then warn("no humanoid: ", UID); return end
    local IdleAnimName:string =ItemName.."Idle"
    local IdleAnim:Animation = AnimHandler:GetAnim(IdleAnimName)
    if not IdleAnim then IdleAnimName = "HumanoidIdle"; end
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
    ItemManager.TweenEquip(RHGrip, PhysicalItem, Character, Humanoid.Animator)
    StateMachine.CurrentPhysicalItem = PhysicalItem
    StateMachine.Anims = {}
    
    for i = 1, 3 do 
        local AnimName =  ItemName.."A"..i
        local Anim:Animation =  AnimHandler:GetAnim(AnimName)
        if not Anim then print("no Anim with that name: ", AnimName);  continue end --* init M1Strings for M1 mod
        StateMachine.Anims[i] = AnimName 
        GetWeaponAnims = true
    end
    if not GetWeaponAnims then print("not  a weapon"); return end 
    StateMachine.WeaponItem = ItemName --* means its a Weapon
    local BlockAnimName = ItemName.."B"
    local BlockAnim:Animation = AnimHandler:GetAnim(BlockAnimName)
    if not BlockAnim then print("no Anim with that name: ", BlockAnimName); return end --* init M1Strings for M1 mod
    StateMachine.Anims[4]  = BlockAnimName  --*B = Block 
    StateMachine.Anims[5] = BlockAnimName.."H" --* BH = Block Hit
end
WeaponOut["ToolHandle"]=function(ClientCombatMachine:CombatMod, StateMachine:FSM, Character:Model, Event:UnreliableRemoteEvent, Key, FrameBuffer, ...)
    local ActiveHotbar:string = StateMachine.ActiveHotbar -- HotBar1 or HotBar2
    local Hotbar: {[string]: number}  = StateMachine[ActiveHotbar]
    local ItemChosenNum = Hotbar[Key]
    if not ItemChosenNum then warn("no item: ", Key); return end
    local Writeu8 = buffer.writeu8
    local NumString: number = NumToSymbol.GiveNum(Key)
    Writeu8(FrameBuffer, 1, NumString)    
    Event:FireServer(FrameBuffer)
    local UID: string = Character.Name
    local StateNum: number = 2 -- WeaponOut
    local ActionNum: number =  8 -- ToolHandle
    local CurrentFrame: number, Length  = buffer.readu8(FrameBuffer, 0), 5
    local StateBuffer: buffer = buffer.create(Length)

    Writeu8(StateBuffer, 0, Length);        buffer.writestring(StateBuffer, 1, UID, 1);          Writeu8(StateBuffer, 2, StateNum)
    Writeu8(StateBuffer, 3, ActionNum);     Writeu8(StateBuffer, 4, CurrentFrame)
    
    local Humanoid:SharedTypes.CustomHumanoid = HumanoidMachine[UID]
    if not Humanoid then warn("no humanoid: ", UID); return end
    Humanoid.Idle:Stop()
    Humanoid.Idle:Destroy()
    Humanoid.Idle = AnimHandler:LoadAnim("HumanoidIdle", Humanoid.Animator)
    Humanoid.Idle:Play()

    local Char = Character  
    local RHGrip: Motor6D = Char.RightHand.RightGrip
    local PhysicalItem = StateMachine.CurrentPhysicalItem 
    ItemManager.TweenUnequip(RHGrip, PhysicalItem, Character, Humanoid.Animator)
    StateMachine.CurrentPhysicalItem= nil
    StateMachine.CurrentItem = nil
    StateMachine.Anims = {}
    ClientCombatMachine.ChangeState(UID, "Idle", "Idle")    
    ClientMessage.SendToClientActor("UpdWithFrame", StateBuffer)    
end

--*LightA
WeaponOut["M1"] =function(ClientCombatMachine:CombatMod, StateMachine:FSM, Character:Model, Event:UnreliableRemoteEvent, FrameLookBuffer:buffer, ...)
    --* framelook buffer = 5
    local Weapon = StateMachine.CurrentItem
    if not Weapon then warn("no weapon ! (not possible): ", StateMachine); return end
    local Length = 9
    local StateBuffer = buffer.create(Length) 
    local Writeu8 = buffer.writeu8 
    local UID = Character.Name
    local StateNum = 4 
    local ActionNum = 9
    Writeu8(StateBuffer, 0, Length)
    buffer.writestring(StateBuffer, 1, UID, 1)
    Writeu8(StateBuffer, 2, StateNum) --* WeaponOut
    Writeu8(StateBuffer, 3, ActionNum) --* M1
    buffer.copy(StateBuffer, 4, FrameLookBuffer, 0, buffer.len(FrameLookBuffer))
    
    ClientCombatMachine.ChangeState(UID, "LightAttack", "WeaponOut")
    ClientCombatMachine.TriggerAction(Character, Event, "Light", StateBuffer)   
    ClientMessage.SendToClientActor("UpdWithFrame", StateBuffer)
    task.synchronize()
    Event:FireServer(StateBuffer) --* M1Event To Queue up
end
LightA["Light"] =function(ClientCombatMachine:CombatMod, StateMachine:FSM, Character:Model, Event:UnreliableRemoteEvent, StateBuffer:buffer, ...)
    task.desynchronize()
    local CurrentItem = StateMachine.CurrentItem
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
    print(NewWS)
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
WeaponOut["StopRun"] =function(ClientCombatMachine:CombatMod, StateMachine:FSM, Character:Model, Event:UnreliableRemoteEvent, FrameBuffer:buffer, ...)
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
Idle["StopRun"] =function(ClientCombatMachine:CombatMod, StateMachine:FSM, Character:Model, Event:UnreliableRemoteEvent, FrameBuffer:buffer, ...)
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
LightA["Release"]  = function(ClientCombatMachine:CombatMod, StateMachine:FSM, Character:Model, Event:UnreliableRemoteEvent, FrameBuffer:buffer, ...)
    ClientCombatMachine.ChangeToOldState(Character.Name)
end
--*SoftStun_Start
SStun["Stun"] = function(ClientCombatMachine:CombatMod, StateMachine:FSM, Character:Model, Event:UnreliableRemoteEvent, MyFrame, ItemData:ItemDataMod, ...)
    local Health = Character:GetAttribute("Health")
    if not Health then warn("no Health Att"); return end
    local UID = Character.Name
    Health -= ItemData.Damage
    task.synchronize()
    local CurrentAction = StateMachine.CurrentAction
    if CurrentAction then  CurrentAction:Stop(); CurrentAction:Destroy(); StateMachine.CurrentAction = nil end
    if StateMachine.SStun then  task.cancel(StateMachine.SStun); StateMachine.SStun = nil  end
    Gui_Handler.SetHealth(Character, Health)
    CharacterHandler.SetHealth(Character, Health)
    local Profile: CharacterHandler.Profile = CharacterHandler.GiveProfile(UID)
    if not Profile then warn("no profiel: ", UID, Profile); return end
    local ForwardActor: Actor = Profile.Forward 
    ForwardActor:SendMessage("AdjustWS", 1)
    StateMachine.SStun = task.delay(ItemData.Stun, function()
        ForwardActor:SendMessage("OldWS")
        ClientCombatMachine.TriggerAction(Character, Event, "Release")
    end)
end
SStun["Release"] = function(ClientCombatMachine:CombatMod, StateMachine:FSM, Character:Model, Event:UnreliableRemoteEvent, ItemDataMod:ItemDataMod, ...)
    ClientCombatMachine.ChangeToOldState(Character.Name)
end
Idle["SoftStun"] = function(ClientCombatMachine:CombatMod, StateMachine:FSM, Character:Model, Event:UnreliableRemoteEvent, ...)
    ClientCombatMachine.ChangeState(Character.Name, "SoftStun", "Idle")
    ClientCombatMachine.TriggerAction(Character, Event, "Stun", ...)
end
WeaponOut["SoftStun"] = function(ClientCombatMachine:CombatMod, StateMachine:FSM, Character:Model, Event:UnreliableRemoteEvent, ...)
    ClientCombatMachine.ChangeState(Character.Name, "SoftStun", "Idle")
    ClientCombatMachine.TriggerAction(Character, Event, "Stun", ...)
end
Blocking["SoftStun"] = function(ClientCombatMachine:CombatMod, StateMachine:FSM, Character:Model, Event:UnreliableRemoteEvent,  ...)
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
--* TrueStun_Start
TStun["Dead"] =  function(ClientCombatMachine:CombatMod, StateMachine:FSM, Character:Model, Event:UnreliableRemoteEvent,  ...)
    --TODO Ragdoll,Parent to Dead here,  no need to fire event cos Server should already know
    --! Trigger Dead from Health Event ONLY cos Client and Server Health may differ  better to wait for the correction
end
TStun["GuardBroken"] = function(ClientCombatMachine:CombatMod, StateMachine:FSM, Character:Model, Event:UnreliableRemoteEvent, MyFrame, WeaponData:ItemDataMod, ...)
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

--*Blocking_Start 
WeaponOut["Block"] =function(ClientCombatMachine:CombatMod, StateMachine:FSM, Character:Model, Event:UnreliableRemoteEvent, FrameLookBuffer:buffer, ...)
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
    local StateNum = 2 --* WeaponOut
    local ActionNum = 14 --* Block
    Writeu8(StateBuffer, 0, Length)
    buffer.writestring(StateBuffer, 1, UID, 1)
    Writeu8(StateBuffer, 2, StateNum) --* WeaponOut
    Writeu8(StateBuffer, 3, ActionNum) --* Block
    buffer.copy(StateBuffer, 4, FrameLookBuffer, 0, buffer.len(FrameLookBuffer))
    
    ClientMessage.SendToClientActor("UpdWithFrame", StateBuffer)
    ClientCombatMachine.ChangeState(UID, "Blocking", "WeaponOut")
    ClientCombatMachine.TriggerAction(Character, Event, "Guard", StateBuffer)   
end
Blocking["Guard"] = function(ClientCombatMachine:CombatMod, StateMachine:FSM, Character:Model, Event:UnreliableRemoteEvent, StateBuffer: buffer,   ...)
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
    --TODO save Parry Unixtimes  in StateMachine cos why not   
    task.synchronize()
    ATrack:Play(0.2)
    Body.CFrame = CF
end 
Blocking["StopBlock"]= function(ClientCombatMachine:CombatMod, StateMachine:FSM, Character:Model, Event:UnreliableRemoteEvent, FrameLookBuffer:buffer, ...)
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
    local StateNum = 3 --* Blocking 
    local ActionNum = 15--* StopBlock
    local CurrentFrame = buffer.readu8(FrameLookBuffer, 0)
    Writeu8(StateBuffer, 0, Length)
    buffer.writestring(StateBuffer, 1, UID, 1)
    Writeu8(StateBuffer, 2, StateNum) --* WeaponOut
    Writeu8(StateBuffer, 3, ActionNum) --* StopBlock
    Writeu8(StateBuffer, 4, CurrentFrame) --* StopBlock

    ClientMessage.SendToClientActor("UpdWithFrame", StateBuffer)
    ClientCombatMachine.ChangeToOldState(UID)
    task.synchronize()
    if StateMachine.CurrentAction then StateMachine.CurrentAction:Stop(); StateMachine.CurrentAction:Destroy() end
    task.synchronize()
    Event:FireServer(StateBuffer) --* StopBlockEvent
end
Blocking["Blocked"]= function(ClientCombatMachine:CombatMod, StateMachine:FSM, Character:Model, Event:UnreliableRemoteEvent, MyFrame, ItemDataMod:ItemDataMod, AUID, ...)
    local CurrentItem = StateMachine.WeaponItem 
    if not CurrentItem then warn("no Weapon Item equipped in Blocked ??",  CurrentItem); return end
    local UID = Character.Name
    local Posture = Character:GetAttribute("Posture")
    if not Posture then warn("U have not added  Posture att"); return end 
    Posture -= ItemDataMod.Posture  -- something like this
    local Humanoid: SharedTypes.CustomHumanoid = HumanoidMachine[UID]
    if not Humanoid then warn("no Humanoid Bug Guard; ", HumanoidMachine); return end 
    local AnimName:string = StateMachine.Anims[5] --*ItemNameBH = Block Hit Anim
    if not AnimName then warn("WTF did not Load Block Anim; ", StateMachine, StateMachine.Anims); return end 
    local ATrack = AnimHandler:LoadAnim(AnimName, Humanoid.Animator)
    CharacterHandler.SetPosture(Character, Posture) 
    --TODO add SetPosture in GUI handler
    UPDATE_CLIENTCOMBATTICK(5, UID, 3, 17, MyFrame)
    if Posture <= 0 then
        --TODO Parry here: use saved Parry Unixtimes  in StateMachine  Calc here  
        Posture = 0
        ClientCombatMachine.ChangeState(UID, "TrueStun")    
        ClientCombatMachine.TriggerAction(Character, Event, "GuardBroken", AUID, ItemDataMod)
    end    
    task.synchronize()
    ATrack:Play()
end
Blocking["Parried"]= function(ClientCombatMachine:CombatMod, StateMachine:FSM, Character:Model, Event:UnreliableRemoteEvent, MyFrame, ItemDataMod:ItemDataMod, AUID, ...)
    local CurrentItem = StateMachine.WeaponItem 
    if not CurrentItem then warn("no Weapon Item equipped in Blocked ??",  CurrentItem); return end
    local UID = Character.Name
    local Humanoid: SharedTypes.CustomHumanoid = HumanoidMachine[UID]
    if not Humanoid then warn("no Humanoid some how: "); return end
    local Atrack = AnimHandler:LoadAnim("Parry", Humanoid.Animator)
    --TODO play parry anim and move back upd Frame Tick 
    local StateNum = 3
    local ActionNum = 16
    UPDATE_CLIENTCOMBATTICK(5, UID, StateNum, ActionNum, MyFrame)
    task.synchronize()
    Atrack:Play()
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
            