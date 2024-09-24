local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared



local Encyclopedia = require(Shared.Encyclopedia)
local SharedTypes = require(Shared.SharedType)
local AnimHandler = require(Shared.AnimHandler)
local HB = require(Shared.Hitbox)
--local Encyclopedia = require(Shared.Encyclopedia)
local HumanoidMachine = require(Shared.HumanoidMachine)
local NumToSymbol = require(Shared.NumToSymbol)
local ItemManager = require(Shared.ItemManager)

local ClientActor = script.Parent.Parent
local SkillsHandler = require(ClientActor.SkillsHandler)
local CharacterHandler = require(ClientActor.Character_Handler)
-- local Gui_Handler = require(ClientActor.Gui_Handler)
-- local ClientMessage = require(ClientActor.Parent.ClientMessageAPI)
local Particle_Handler = require(ClientActor.SkillsFolder.Particle_Handler)

type CombatMod = SharedTypes.ClientCombatMachine
type FSM = SharedTypes.ClientStateMachine
type ItemDataMod = SharedTypes.ItemData
local OtherPlayerCombat = {
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
local Idle:any = OtherPlayerCombat.Idle
local WeaponOut:any = OtherPlayerCombat.WeaponOut
local LightA:any = OtherPlayerCombat.LightAttack
local Blocking = OtherPlayerCombat.Blocking
local SStun:any = OtherPlayerCombat.SoftStun
local TStun = OtherPlayerCombat.TrueStun


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

--* ToolHandle
WeaponOut["ToolHandle"] =function(ClientCombatMachine:CombatMod, StateMachine:FSM, Character:Model, Event:UnreliableRemoteEvent, MyFrame, StateBuffer:buffer, ...)
    local ActiveToolbar:string = StateMachine.ActiveToolbar -- Toolbar1 or Toolbar2
    local Hotbar: {[string]: number}  = StateMachine[ActiveToolbar]
    local Key= buffer.readu8(StateBuffer, 1)
    local ItemChosenNum = Hotbar[Key]
    if not ItemChosenNum then warn("no item: ", Key); return end
    local Writeu8 = buffer.writeu8
    local NumString:string = NumToSymbol[Key]
    Writeu8(StateBuffer, 1, NumString)    
    Event:FireServer(StateBuffer)
    local UID: string = Character.Name
    
    local Humanoid:SharedTypes.CustomHumanoid = HumanoidMachine[UID]
    if not Humanoid then warn("no humanoid: ", UID); return end
    Humanoid.Idle:Stop()
    Humanoid.Idle:Destroy()
    Humanoid.Idle = AnimHandler:LoadAnim("HumanoidIdle", Humanoid.Animator)
    Humanoid.Idle:Play()

    local Char = Character  
    local RHGrip: Motor6D = Char.RightHand.RightGrip
    local PhysicalItem = StateMachine.CurrentPhysicalItem 
    ItemManager.TweenUnequip(RHGrip, PhysicalItem, Character, Humanoid.Animator, StateMachine)
    StateMachine.CurrentPhysicalItem= nil
    StateMachine.CurrentItem = nil
    StateMachine.Anims = {}
    ClientCombatMachine.ChangeState(UID, "Idle", "Idle")    
end
Idle["ToolHandle"] =function(ClientCombatMachine:CombatMod, StateMachine:FSM, Character:Model, Event:UnreliableRemoteEvent, MyFrame, StateBuffer:buffer, ...)
    local ActiveToolbar:string = StateMachine.ActiveToolbar -- Toolbar1 or Toolbar2
    local Hotbar: {[string]: number}  = StateMachine[ActiveToolbar]
    local Key= buffer.readu8(StateBuffer, 1)
    local ItemChosenNum = Hotbar[Key]
    if not ItemChosenNum then warn("no item: ", Key); return end
    local ItemName = Encyclopedia[ItemChosenNum]
    local UID = Character.Name
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
    local Char = Character  
    local RHGrip: Motor6D = Char.RightHand.RightGrip
    local GetWeaponAnims = false
    ItemManager.TweenEquip(RHGrip, PhysicalItem, Character, Humanoid.Animator, StateMachine)
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
    Particle_Handler.Hurt(Character)
end
SStun["Release"] = function(ClientCombatMachine:CombatMod, StateMachine:FSM, Character:Model, Event:UnreliableRemoteEvent, ItemDataMod:ItemDataMod, ...)
    ClientCombatMachine.ChangeToOldState(Character.Name)
end
Idle["SoftStun"] =  function(ClientCombatMachine:CombatMod, StateMachine:FSM, Character:Model, Event:UnreliableRemoteEvent, AUID, ItemDataMod:ItemDataMod, ...)
    ClientCombatMachine.ChangeState(Character.Name, "SoftStun", "Idle")
    ClientCombatMachine.TriggerAction(Character, Event, "Stun", ItemDataMod)
end
Blocking["SoftStun"]= function(ClientCombatMachine:CombatMod, StateMachine:FSM, Character:Model, Event:UnreliableRemoteEvent, ...)
    local CDTable = StateMachine.CDs
    local UnixMill  = DateTime.now().UnixTimestampMillis
    local ParryStarted = CDTable["ParryStart"]
    if not ParryStarted then print("parry not started"); return end
    local ParryCD = CDTable["ParryCD"]
    if not ParryCD then ParryCD = UnixMill end
    local ParryCDCheck = UnixMill - ParryCD
    if ParryCDCheck > 1000 then 
        --*it means 1 second has passed since they last tried parrying accept it this time
        local Check = UnixMill - ParryStarted
        --*less than 0.35s since they started blocking so accept Parry
        if Check <= 350 then ClientCombatMachine.TriggerAction(Character, Event, "Parried", ...) end    
        CDTable.ParryCD = UnixMill        
        return
    end
    ClientCombatMachine.TriggerAction(Character, Event, "Blocked", ...)
end
--*LightA
WeaponOut["M1"]=function(ClientCombatMachine:CombatMod, StateMachine:FSM, Character:Model, Event:UnreliableRemoteEvent, MyFrame, StateBuffer:buffer, ...)    
    ClientCombatMachine.ChangeState(Character.Name, "LightAttack", "WeaponOut")
    ClientCombatMachine.TriggerAction(Character, nil, "Light", MyFrame, StateBuffer)
end
--TODO Make sure frameDifference is Always below 0.332s in all Anim based actions like below 
LightA["Light"] =function(ClientCombatMachine:CombatMod, StateMachine:FSM, Character:Model, Event:UnreliableRemoteEvent, MyFrame, StateBuffer:buffer, ...)
    --* 4th byte is ClientFrame Recieved in StateBuffer
    local Readu8 = buffer.readu8
    local OtherClientFrame = Readu8(StateBuffer, 4)
    local Diff = frameDifference(MyFrame, OtherClientFrame) --* in seconds 
    if Diff >= 0.332 then Diff = 0.332 end --* Important 
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
--*Blocking
Blocking["Guard"]=function(ClientCombatMachine:CombatMod, StateMachine:FSM, Character:Model, Event:UnreliableRemoteEvent, MyFrame, StateBuffer:buffer, ...)
    --* 4th byte is ClientFrame Recieved in StateBuffer
    if not StateMachine.Anims then warn("no Anims"); return end
    local AnimName:string = StateMachine.Anims[4] --* Block
    local Anim:Animation = AnimHandler:GetAnim(AnimName)
    if not Anim  then ClientCombatMachine.TriggerAction(Character, Event, "Release"); warn("1 release guard", Anim); return end
    
    local Readi16 = buffer.readi16
    local rx:number,  rz:number= Readi16(StateBuffer, 5), Readi16(StateBuffer, 7)
    local Direction:Vector3 = Vector3.new(rx, 0, rz).Unit
    local Body = Character.PrimaryPart
    local CF = CFrame.lookAlong(Body.Position, Direction, Body.CFrame.UpVector) 
    local UID = Character.Name
    local Humanoid: SharedTypes.CustomHumanoid = HumanoidMachine[UID]
    if not Humanoid then print("no humanoid Otherplr Guard"); return end 
    local Atrack:AnimationTrack = AnimHandler:LoadAnim(AnimName, Humanoid.Animator)
    StateMachine.CDs.ParryStart = DateTime.now().UnixTimestampMillis
    StateMachine.CurrentAction = Atrack
    task.synchronize()
    Atrack:Play()
    Body.CFrame = CF
end

Blocking["Blocked"] =function(ClientCombatMachine:CombatMod, StateMachine:FSM, Character:Model, Event:UnreliableRemoteEvent, MyFrame, StateBuffer:buffer, ...)
    --* 4th byte is ClientFrame Recieved in StateBuffer
    --* posture will be updated from the Posture State same with health
    local UID = Character.Name
    local Humanoid:SharedTypes.CustomHumanoid = HumanoidMachine[UID]
    local AnimName = StateMachine.Anims[5] --* ItemNameBH
    if not AnimName then warn("did not init CFSM Anims"); return end
    local Atrack =AnimHandler:LoadAnim(AnimName, Humanoid.Animator)
    Atrack:Play()
end 
Blocking["Parried"] =function(ClientCombatMachine:CombatMod, StateMachine:FSM, Character:Model, Event:UnreliableRemoteEvent, MyFrame, StateBuffer:buffer, ...)
    local UID = Character.Name
    local Humanoid:SharedTypes.CustomHumanoid = HumanoidMachine[UID]
    local Atrack =AnimHandler:LoadAnim("Parry", Humanoid.Animator)
    Atrack:Play()
end
Blocking["Release"] =function(ClientCombatMachine:CombatMod, StateMachine:FSM, Character:Model, Event:UnreliableRemoteEvent, MyFrame, StateBuffer:buffer, ...)
    ClientCombatMachine.ChangeToOldState(Character.Name)
end

return OtherPlayerCombat