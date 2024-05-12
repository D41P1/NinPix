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
local HumanoidStates = require(script.HumanoidStates)
type StateMachine = {
    ["CurrentState"] : string,
    ["OldState"] : string,
    ["MoveKeys"] : string,
    ["Animator"] : Animator,
    ["StateMachine"]: any
} 
local HumanoidMachine = {}
function HumanoidMachine:InitHumanoid(Character)
    local Humanoid = { 
        ["CurrentState"] = "Idle",
        ["OldState"] = "Idle",
        ["MoveKeys"] = "",
        ["Animator"] = Character.AC.Animator,
        ["StateMachine"] = HumanoidStates
    }
    HumanoidMachine[Character.Name] = Humanoid
    return Humanoid
end 
function HumanoidMachine:InitServerHumanoid(Character, StateMachine: any)
    local Humanoid = { 
        ["CurrentState"] = "Idle",
        ["OldState"] = "Idle",
        ["StateMachine"] = StateMachine
    }
    HumanoidMachine[Character.Name] = Humanoid
    return Humanoid
end
function HumanoidMachine.TriggerAction(Character: Model, Event: RemoteEvent?,  Action: string, ...)
    local Humanoid: StateMachine = HumanoidMachine[Character.Name]
    local HumanoidStates = Humanoid.StateMachine
    if not HumanoidStates[Humanoid.CurrentState][Action] then  return end    
    HumanoidStates[Humanoid.CurrentState][Action](HumanoidMachine, Character, Event, ...)
end
function  HumanoidMachine.ChangeState(PlayerName: string, NewState: string, OldState: string?)
    local Humanoid: StateMachine = HumanoidMachine[PlayerName]
    local HumanoidStates = Humanoid.StateMachine
    if not HumanoidStates[NewState] then return end
    if OldState then  HumanoidMachine[PlayerName].OldState = OldState end
    HumanoidMachine[PlayerName].CurrentState = NewState 
end
function  HumanoidMachine.ChangeToOldState(PlayerName: string) HumanoidMachine[PlayerName].CurrentState = HumanoidMachine[PlayerName].OldState end
return HumanoidMachine