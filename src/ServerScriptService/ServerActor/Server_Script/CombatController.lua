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
    local UxMill = DateTime.now().UnixTimestampMillis
    local StateMachine: SharedTypes.ServerCombat_Profile= { 
        ["CurrentState"] = "Idle",
        ["OldState"] = "Idle",
        ["Action"] = "Stand",
        ["StateModule"] = StateModule,
        ["Allow_Hit"] = true,
        ["M1Count"] = 0,
        ["M1ResetTime"] = UxMill,
        ["Anims"] = {},
        ["CDs"] = {
            ["ParryCD"] = UxMill,
            ["ParryStart"] = UxMill
        }, 
    }
    --[[ --* OLD Toolbar system
    if HotBarInfo then 
        local ReadU16 = buffer.readu16
        local offset = 1 
        local Keys = { "One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight" }
        StateMachine.Toolbar1 = {}
        StateMachine.Toolbar2 = {}
        local Toolbar1 = StateMachine.Toolbar1
        local Toolbar2 = StateMachine.Toolbar2
        for _, Key in Keys do
            local ItemId = ReadU16(HotBarInfo, offset)
            Toolbar1[Key] = ItemId --* Item/Skill
            offset += 2
        end
        for _, Key in Keys do
            local ItemId = ReadU16(HotBarInfo, offset)
            Toolbar2[Key] = ItemId
            offset += 2
        end
    end
    ]]
    CombatController[UID] = StateMachine
    return StateMachine
end
function CombatController:InitNPCombatMachine(UID: string, StateModule: any)
    local Uxmill = DateTime.now().UnixTimestampMillis
    local StateMachine: SharedTypes.NPCStateMachine = { 
        ["CurrentState"] = "Idle",
        ["OldState"] = "Idle",
        ["Action"] = "Stand",
        ["StateModule"] = StateModule,
        ["M1Count"] = 0,
        ["M1ResetTime"] = Uxmill,
        ["Anims"] = {},
        ["CDs"] = {
            ["ParryCD"] = Uxmill,
            ["ParryStart"] = Uxmill
        }
    }
    CombatController[UID] = StateMachine
    return StateMachine :: SharedTypes.NPCStateMachine
end
function CombatController.TriggerAction(UID: string, Action: string, ...)
    UID = tostring(UID)
    local StateMachine: CombatController = CombatController[UID]
    if not StateMachine then warn("no State machine; ", UID, typeof(UID),CombatController); return end
    local Machine = StateMachine.StateModule
    if not Machine then print("no machine: ", UID); return end 
    if not Machine[StateMachine.CurrentState] then print("no State: ", Machine, StateMachine.CurrentState);  return end    
    if not Machine[StateMachine.CurrentState][Action] then print("no action in State: ", Machine, Action, StateMachine.CurrentState);  return end    
    Machine[StateMachine.CurrentState][Action](CombatController, StateMachine, UID, ...)
end
function  CombatController.ChangeState(UID: string, NewState: string, OldState: string?)
    UID = tostring(UID)
    local StateMachine: CombatController = CombatController[UID]
    if not StateMachine then warn("no State machine; ", CombatController); return end
    local Machine = StateMachine.StateModule
    if not Machine[NewState] then return end
    if OldState then  CombatController[UID].OldState = OldState end
    StateMachine.CurrentState = NewState
end
function  CombatController.ForceState(UID: string, NewState: string, OldState: string?)
    UID = tostring(UID)
    local StateMachine: CombatController = CombatController[UID]
    if not StateMachine then warn("no State machine; ", CombatController); return end
    local Machine = StateMachine.StateModule
    if not Machine[NewState] then return end
    if OldState then  CombatController[UID].OldState = OldState end
    CombatController[UID].CurrentState = NewState
end
function  CombatController.ChangeToOldState(UID: string)
    UID = tostring(UID)
    local StateMachine: CombatController = CombatController[UID]
    if not StateMachine then warn("no State machine; ", CombatController); return end
    local OldState = StateMachine.OldState
    StateMachine.CurrentState =  OldState
    return OldState :: string
end
return CombatController