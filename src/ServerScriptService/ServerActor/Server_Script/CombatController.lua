--[[ Info
This Module is for Handling the Changing of the Combat State and their actions
also so the client can keep in sync with the server -- makes remote event redundant reducing network
]]
--[[ States

WeaponOut
Idle
Skill
LightAttack
HeavyAttack
SoftStun -- so u can parry
TrueStun 

]]
--[[ Shared
-- local HumanoidStates = require(script.HumanoidStates)
-- local ReplicatedStorage = game:GetService("ReplicatedStorage")
-- local SharedType = require(ReplicatedStorage.Shared.SharedType)
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared
local SharedTypes = require(Shared.SharedType)
export type CombatController = {
    ["CurrentState"] : string,
    ["OldState"] : string,
    ["Action"] : any,
    ["StateModule"]: any,
} 
local CombatController = {}
function CombatController:InitCombatMachine(UID: string, StateModule: any, HotBarInfo:buffer?)
    local StateMachine: SharedTypes.ClientStateMachine = { 
        ["CurrentState"] = "Idle",
        ["OldState"] = "Idle",
        ["Action"] = "Stand",
        ["StateModule"] = StateModule,
        ["ActiveHotbar"] = "Hotbar1",
        ["M1Count"] = 0,
        ["Anims"] = {},
        ["CDs"] = {
            ["ParryCD"] = DateTime.now().UnixTimestampMillis,
            ["ParryStart"] =DateTime.now().UnixTimestampMillis
        }
    }
    if HotBarInfo then 
        local ReadU16 = buffer.readu16
        local offset = 1 
        local Keys = { "One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight" }
        StateMachine.Hotbar1 = {}
        StateMachine.Hotbar2 = {}
        local Hotbar1 = StateMachine.Hotbar1
        local Hotbar2 = StateMachine.Hotbar2
        for _, Key in Keys do
            local NumberReference = ReadU16(HotBarInfo, offset)
            Hotbar1[Key] = NumberReference --* Item/Skill
            offset += 2
        end
        for _, Key in Keys do
            local NumberReference = ReadU16(HotBarInfo, offset)
            Hotbar2[Key] = NumberReference
            offset += 2
        end
    end
    CombatController[UID] = StateMachine
    return StateMachine
end
function CombatController:InitNPCombatMachine(UID: string, StateModule: any)
    local StateMachine: SharedTypes.NPCStateMachine = { 
        ["CurrentState"] = "Idle",
        ["OldState"] = "Idle",
        ["Action"] = "Stand",
        ["StateModule"] = StateModule,
        ["M1Count"] = 0,
        ["Anims"] = {},
        ["CDs"] = {
            ["ParryCD"] = DateTime.now().UnixTimestampMillis,
            ["ParryStart"] =DateTime.now().UnixTimestampMillis
        }
    }
    CombatController[UID] = StateMachine
    return StateMachine :: SharedTypes.NPCStateMachine
end

function CombatController.TriggerAction(UID: string, Action: string, ...)
    local StateMachine: CombatController = CombatController[UID]
    if not StateMachine then warn("no State machine; ", CombatController); return end
    local Machine = StateMachine.StateModule
    if not Machine then warn("no machine: ", UID); return end 
    if not Machine[StateMachine.CurrentState][Action] then warn("no action in State: ", Machine, Action);  return end    
    Machine[StateMachine.CurrentState][Action](CombatController, StateMachine, UID, ...)
end
function  CombatController.ChangeState(UID: string, NewState: string, OldState: string?)
    local StateMachine: CombatController = CombatController[UID]
    if not StateMachine then warn("no State machine; ", CombatController); return end
    local Machine = StateMachine.StateModule
    if not Machine[NewState] then return end
    if OldState then  CombatController[UID].OldState = OldState end
    CombatController[UID].CurrentState = NewState
end
function  CombatController.ForceState(UID: string, NewState: string, OldState: string?)
    local StateMachine: CombatController = CombatController[UID]
    local Machine = StateMachine.StateModule
    if not Machine[NewState] then return end
    if OldState then  CombatController[UID].OldState = OldState end
    CombatController[UID].CurrentState = NewState
end
function  CombatController.ChangeToOldState(UID: string)
    local OldState = CombatController[UID].OldState
    CombatController[UID].CurrentState =  OldState
    return OldState :: string
end
return CombatController