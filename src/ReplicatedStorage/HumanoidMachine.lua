--[[ Info
This Module is for Handling the Changing of the CustomHumanoid State and their actions
also so the client can keep in sync with the server -- makes remote event redundant reducing network
]]
--[[ States
Jump
Walk
Sprint
WallRun
Fall
]]
--[[ Shared
    Create a function init the the HumanoidStateMachine
]]
-- local HumanoidStates = require(script.HumanoidStates)
local SharedType = require(script.Parent.SharedType)
type StateMachine = {
    ["CurrentState"] : string,
    ["OldState"] : string,
    ["MoveKeys"] : string,
    ["Animator"] : Animator,
    ["StateMachine"]: any
} 
local HumanoidMachine = {}
function HumanoidMachine:InitHumanoid(Character, StateMachine)
    local Humanoid = { 
        ["CurrentState"] = "Idle",
        ["OldState"] = "Idle",
        ["MoveKeys"] = "",
        ["Animator"] = Character.AC.Animator,
        ["StateMachine"] = StateMachine
        -- ["IsLocked"] = false
    }
    HumanoidMachine[Character.Name] = Humanoid
    return Humanoid
end 
function HumanoidMachine:InitServerHumanoid(UID, StateMachine: any)
    local Humanoid = { 
        ["CurrentState"] = "Idle",
        ["OldState"] = "Idle",
        ["StateMachine"] = StateMachine
    }
    HumanoidMachine[UID] = Humanoid
    return Humanoid
end
function HumanoidMachine.TriggerAction(Character: Model, Event: UnreliableRemoteEvent?,  Action: string, ...)
    local Humanoid: StateMachine = HumanoidMachine[Character.Name]
    local HumanoidStates = Humanoid.StateMachine
    if not HumanoidStates[Humanoid.CurrentState][Action] then  return end    
    HumanoidStates[Humanoid.CurrentState][Action](HumanoidMachine, Character, Event, ...)
end
function HumanoidMachine.ServerTriggerAction(UID: string, Event: RemoteEvent?,  Action: string, ...)
    local Humanoid: StateMachine = HumanoidMachine[UID]
    if not Humanoid then warn("No StateMachine", Humanoid) end
    local HumanoidStates = Humanoid.StateMachine
    if not HumanoidStates[Humanoid.CurrentState][Action] then  return end    
    HumanoidStates[Humanoid.CurrentState][Action](HumanoidMachine, UID, Event, ...)
end
function  HumanoidMachine.ChangeState(UID: string, NewState: string, OldState: string?)
    local Humanoid: SharedType.CustomHumanoid = HumanoidMachine[UID]
    if not Humanoid then warn("No StateMachine", Humanoid) end
    local HumanoidStates = Humanoid.StateMachine
    if Humanoid.IsLocked then return end
    if not HumanoidStates[NewState] then return end
    if OldState then  HumanoidMachine[UID].OldState = OldState end
    HumanoidMachine[UID].CurrentState = NewState
end
function  HumanoidMachine.ForceState(UID: string, NewState: string, OldState: string?)
    local Humanoid: SharedType.CustomHumanoid = HumanoidMachine[UID]
    if not Humanoid then warn("No StateMachine", Humanoid) end
    local HumanoidStates:{ [string]: (any) -> any } = Humanoid.StateMachine
    if not HumanoidStates[NewState] then return end
    if OldState then  HumanoidMachine[UID].OldState = OldState end
    HumanoidMachine[UID].CurrentState = NewState
end
function HumanoidMachine.ChangeHumanoidProperty(UID:string, Property:string, Value:any)
    local Humanoid: SharedType.CustomHumanoid = HumanoidMachine[UID]
    if not Humanoid then warn("No StateMachine", Humanoid) end
    if not Humanoid[Property] then warn("incorrect Property: ", Property); return end
    Humanoid[Property] = Value
end
function  HumanoidMachine.ChangeToOldState(UID: string) HumanoidMachine[UID].CurrentState = HumanoidMachine[UID].OldState end
return HumanoidMachine