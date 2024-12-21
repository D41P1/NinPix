local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared
local Items = ReplicatedStorage.Items

local Client_HandlerScript = script.Parent.Parent
local Particle_Handler = require(Client_HandlerScript.SkillsFolder.Particle_Handler)
local ItemDataMod = require(Shared.ItemDataMod)
local AnimHandler = require(Shared.AnimHandler)
local SharedTypes = require(Shared.SharedType)

type Combat = SharedTypes.ClientCombatMachine
type FSM = SharedTypes.ClientStateMachine
type Extra = {
    Humanoid: SharedTypes.CustomHumanoid,
    Profile: SharedTypes.Profile,
    M1Count:number,
    ItemName:string,
    [string]: any
}
local M1 = {
    ["Sword"] = function(ClientCombatMachine: Combat, StateMachine: FSM , Character: Model, Data: Extra)
        local Profile: SharedTypes.Profile = Data.Profile
        local Info: ItemDataMod.ItemData = ItemDataMod.GiveCopyData(Data.ItemName)   
        local AnimSpeed =Info.HBTime *0.001      
        local AttackSpeed = 1/AnimSpeed
        Profile.Forward:SendMessage("LockMove", true) 
        Profile.Procedural:SendMessage("Anim", "SwordM1"..Data["M1Count"], {2, 5}, {2, 5}, AttackSpeed)
        local Thread 
        Thread = task.delay(AnimSpeed + 0.12, function()
            ClientCombatMachine.TriggerAction(Character, nil, "Release")
            Particle_Handler.Swing(Character)
        end)
        StateMachine.CurrentAction = Thread        
        return 
    end,
    ["SwordM2"] = function(ClientCombatMachine: Combat, StateMachine: FSM , Character: Model, Data: Extra)
        local Profile: SharedTypes.Profile = Data.Profile
        local Info: ItemDataMod.ItemData = ItemDataMod.GiveCopyData(Data.ItemName)   
        local AnimSpeed =Info.HBTime/1000      
        local AttackSpeed = 1/AnimSpeed
        Profile.Forward:SendMessage("LockMove", true) 
        Profile.Procedural:SendMessage("Anim", "SwordM2", {2, 5, 6}, {2, 5, 6}, AttackSpeed)
        local Thread 
        Thread = task.delay(AnimSpeed + 0.12, function()
            ClientCombatMachine.TriggerAction(Character, nil, "Release")
            Particle_Handler.Swing(Character)
        end)
        StateMachine.CurrentAction = Thread        
        return 
    end
}
M1["Rusty.Sword"] = M1.Sword
M1["Rusty.SwordM2"] = M1.SwordM2

return M1 
