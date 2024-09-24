local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared
local Items = ReplicatedStorage.Items

local Particle_Handler = require(script.Parent.Parent.SkillsFolder.Particle_Handler)
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
        local Info: ItemDataMod.ItemData = ItemDataMod.GiveCopyData(Data.ItemName)
        local Body = Character.PrimaryPart
        Info["SkillName"] = "SwordM1"       
        Info["WeaponName"] = StateMachine.CurrentItem       
        Info["Topic"] = "SoftStun"
        Info["Origin"] = Body.CFrame
        Info["AUID"] = Character.Name
        Profile.Forward:SendMessage("LockMove", true) 
        local AttackSpeed = 1/(Info.HBTime/1000)
        ATrack:AdjustSpeed(AttackSpeed)
        ATrack.KeyframeReached:ConnectParallel(function(a0: string)  
            ClientCombatMachine.TriggerAction(Character, nil, "Release")
            Profile.Forward:SendMessage("LockMove")
            Particle_Handler.Swing(Character, Info.Type) 
        end)
        return ATrack
    end
}
return M1 
