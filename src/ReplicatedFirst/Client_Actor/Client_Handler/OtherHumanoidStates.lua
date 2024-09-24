--[[Info
The State moudel for Humanoids
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared
local SharedTypes = require(Shared.SharedType)
type CustomHumanoid = SharedTypes.CustomHumanoid
type Events = RemoteEvent --| UnreliableRemoteEvent
type Machine = SharedTypes.Machine
--/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
-- //////////////////////////////////////////// new rule added CharacterName and UID are equal ////////////////////////////////////////////////////////////
--/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
--* StartWalk only thing being used here (just setting CF)
--[[ --*Some info
No Jump or fall cos thats handled via CheckMove for OtherPlayers
]]
local OtherHumanoidStates = {
    ["Walk"] = { 
        StopWalk = function(HumanoidMachine: Machine, Character: Model, Event: Events)
            local UID = Character.Name
            local Humanoid: CustomHumanoid = HumanoidMachine[UID]
            if not  Humanoid then return end
            if not Humanoid.IsWalking then return end
            task.synchronize()
            if Humanoid.MoveTracker then Humanoid.MoveTracker:Pause(); Humanoid.MoveTracker:Destroy() end
            if Humanoid.Walk then  Humanoid.Walk:Stop(); Humanoid.IsWalking = false end
        end,        
        StartWalk = function(HumanoidMachine: Machine, Character: Model)task.desynchronize()
            local UID = Character.Name
            local Humanoid: CustomHumanoid = HumanoidMachine[UID]
            local function playAnim() task.synchronize(); Humanoid.Walk:Play(); Humanoid.IsWalking = true end
            if not Humanoid.IsWalking then playAnim()  end
        end,
    },
    ["Idle"] = {
        StartWalk = function(HumanoidMachine: Machine, Character: Model, Event: Events, Direction: Vector3)
            HumanoidMachine.ChangeState(Character.Name, "Walk")
            HumanoidMachine.TriggerAction(Character, Event, "StartWalk", Direction)
        end,
    },
}
return OtherHumanoidStates