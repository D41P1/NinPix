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
local SharedTypes = require(game:GetService("ReplicatedStorage").Shared.SharedType)
export type ClientStateMachine = SharedTypes.ClientStateMachine

local ClientCombatMachine = {}
function ClientCombatMachine:InitMachine(Character, StateModule, Inventory_Toolbar)
    local UnixMill = DateTime.now().UnixTimestampMillis
    local StateMachine:ClientStateMachine = { 
        ["CurrentState"] = "Idle",
        ["OldState"] = "Idle",
        ["StateModule"] = StateModule,
        ["ActiveToolbar"] = "Toolbar1",
        ["M1Count"] = 0,
        ["M1ResetTime"] = UnixMill,
        ["M1String"] = {},
        ["Anims"] = {},
        ["CDs"] = {
            ParryCD = UnixMill,
            ParryStart = UnixMill
        }
        -- ["IsLocked"] = false
    }
    ClientCombatMachine[Character.Name] = StateMachine
    print("inited ClientCombat machine: ", Character.Name, ClientCombatMachine)
    local ReadU16 = buffer.readu16
    local Keys = { "One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight" }
    local offset = 1 --* 0 is UID
    StateMachine.Toolbar1 = {}
    StateMachine.Toolbar2 = {}
    for _, Key in Keys do
        local NumberReference = ReadU16(Inventory_Toolbar, offset) 
        if StateMachine.Toolbar1  then 
            StateMachine.Toolbar1[Key] = NumberReference -- could be Item/Skill
        end
        offset += 2
    end
    for _, Key in Keys do
        local NumberReference = ReadU16(Inventory_Toolbar, offset)
        if StateMachine.Toolbar2 then 
            StateMachine.Toolbar2[Key] = NumberReference -- could be Item/Skill
        end
        offset += 2
    end

    return StateMachine
end 
function ClientCombatMachine:InitMPCMachine(Character, StateModule)
    local UnixMill = DateTime.now().UnixTimestampMillis
    local StateMachine:ClientStateMachine = { 
        ["CurrentState"] = "Idle",
        ["OldState"] = "Idle",
        ["StateModule"] = StateModule,
        ["ActiveToolbar"] = "Toolbar1",
        ["M1Count"] = 0,
        ["M1ResetTime"] = UnixMill,
        ["M1String"] = {},
        ["Anims"] = {},
        ["CDs"] = {
            ParryCD = UnixMill,
            ParryStart = UnixMill
        }
        -- ["IsLocked"] = false
    }
    ClientCombatMachine[Character.Name] = StateMachine
    return StateMachine
end 
function ClientCombatMachine.TriggerAction(Character: Model, Event: UnreliableRemoteEvent?,  Action: string, ...)
    local StateMachine: ClientStateMachine = ClientCombatMachine[Character.Name]
    if not StateMachine then warn("no state machine in trigg action"); return end
    local Machine = StateMachine.StateModule
    if not Machine[StateMachine.CurrentState][Action] then print("no Action in state: ", Action, StateMachine.CurrentState);  return end    
    Machine[StateMachine.CurrentState][Action](ClientCombatMachine, StateMachine, Character, Event, ...)
end
function  ClientCombatMachine.ChangeState(UID: string, NewState: string, OldState: string?)
    local StateMachine: ClientStateMachine = ClientCombatMachine[UID]
    if not StateMachine then warn("no State Machine: ", UID); return end
    local Machine = StateMachine.StateModule
    if not Machine[NewState] then warn("incorrect State: ", NewState, Machine);  return end
    if OldState then  ClientCombatMachine[UID].OldState = OldState end
    StateMachine.CurrentState = NewState
end
function  ClientCombatMachine.ForceState(UID: string, NewState: string, OldState: string?)
    local StateMachine: ClientStateMachine = ClientCombatMachine[UID]
    if not StateMachine then return end
    local Machine = StateMachine.StateModule
    if not Machine[NewState] then return end
    if OldState then  ClientCombatMachine[UID].OldState = OldState end
    ClientCombatMachine[UID].CurrentState = NewState
end
function  ClientCombatMachine.ChangeToOldState(UID: string) 
    local StateMachine = ClientCombatMachine[UID]
    if not StateMachine then return end
    local OldState = StateMachine.OldState
    StateMachine.CurrentState = OldState 
    return OldState
end
function ClientCombatMachine.Cleanup(UID:string)
    --* no need to destroy physical item in SM cos Char Handlers clean up does that
    local StateMachine: ClientStateMachine = ClientCombatMachine[UID]
    if not StateMachine then warn("no state machine in Cleanup action"); return end
    local SStun = StateMachine.SStun
    if SStun then task.cancel(SStun) end
    local TStun = StateMachine.TStun
    if TStun then task.cancel(TStun) end
    ClientCombatMachine[UID] = nil
end


return ClientCombatMachine