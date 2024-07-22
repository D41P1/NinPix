local Shared = script.Parent.Parent
local ReplicatedStorage = Shared.Parent
local Items = ReplicatedStorage.Items
local ItemDataMod = require(Shared.ItemDataMod)
local AnimHandler = require(Shared.AnimHandler)
local SharedTypes = require(Shared.SharedType)

type Combat = SharedTypes.ClientCombatMachine
type FSM = SharedTypes.ClientStateMachine
type Extra = {
    Animator: Animator,
    AnimName: string,
    Humanoid: SharedTypes.CustomHumanoid,
    Profile: SharedTypes.Profile,
    [string]: any
}
local M1 = {
    ["Sword"] = function(ClientCombatMachine: Combat, StateMachine: FSM , Character: Model, Data: Extra)
        local M1Anim: string = Data.AnimName
        local Humanoid: SharedTypes.CustomHumanoid = Data.Humanoid
        local ATrack: AnimationTrack = AnimHandler:LoadAnim(M1Anim, Humanoid.Animator)
        StateMachine.CurrentAction = ATrack
        ATrack:Play()
        local Profile: SharedTypes.Profile = Data.Profile
        local Info: ItemDataMod.ItemDataMod = ItemDataMod.GiveCopyData(Data.ItemName)
        local Body = Character.PrimaryPart
        Info["SkillName"] = "SwordM1"       
        Info["WeaponName"] = StateMachine.CurrentItem       
        Info["Topic"] = "SoftStun"
        Info["Origin"] = Body.CFrame
        Info["AUID"] = Character.Name
        Profile.Forward:SendMessage("LockMove", true) 
        local Count = 0
        ATrack.KeyframeReached:ConnectParallel(function(a0: string)  
            Profile.Detect:SendMessage("GPB", Info)
            Count += 1
            ClientCombatMachine.TriggerAction(Character, nil, "Release")
            Profile.Forward:SendMessage("LockMove") 
        end)
        return ATrack
    end
}
return M1 
