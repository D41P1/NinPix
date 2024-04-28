--[[Info
Humanoid Controller State Module for Humanoids server
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared
local SharedTypes = require(Shared.SharedType)
local HumanoidMachine = Shared.HumanoidMachine
local RayMovement = require(HumanoidMachine.RayMovement)

type CustomHumanoid = SharedTypes.CustomHumanoid
type Events = RemoteEvent --| UnreliableRemoteEvent
type Machine = SharedTypes.Machine
local Humanoid_Controller = {
    ["Walk"] = {
        StopWalk = function(HumanoidMachine: Machine, Character: Model) task.desynchronize()
            HumanoidMachine.ChangeState(Character.Name, "Idle")
            local Humanoid: CustomHumanoid = HumanoidMachine[Character.Name]
            if not  Humanoid then return end
            if Humanoid.MoveTracker then 
                task.synchronize(); Humanoid.MoveTracker:Pause(); Humanoid.MoveTracker:Destroy(); Humanoid.MoveTracker = nil
            end
            RayMovement:CheckFalling(Character, HumanoidMachine, Humanoid)
        end,        
        StartWalk = function(HumanoidMachine: Machine, Character, HOLDER, Direction: Vector3)task.desynchronize()
            local Humanoid: CustomHumanoid = HumanoidMachine[Character.Name]
            task.desynchronize()
            RayMovement:RayWalk(Character, Direction, Humanoid, HumanoidMachine) 
        end,
        Jump = function(HumanoidMachine: Machine, Character: Model, Event: Events, Key: string)
            HumanoidMachine.ChangeState(Character.Name, "Jump", "Walk")
            HumanoidMachine.TriggerAction(Character, Event, "Jump", Key)
        end, 
        Fall = function(HumanoidMachine: Machine, Character: Model, Event: Events, Key: string)
            local Humanoid: CustomHumanoid = HumanoidMachine[Character.Name]
            if not  Humanoid then return end
            if  Humanoid.MoveTracker then task.synchronize(); Humanoid.MoveTracker:Pause(); Humanoid.MoveTracker:Destroy() end
            Humanoid.Walk:Stop(); Humanoid.IsWalking = false
            HumanoidMachine.ChangeState(Character.Name, "Fall", "Walk")
        end
    },
    ["Idle"] = {
        StartWalk = function(HumanoidMachine: Machine, Character: Model, Event: Events, Key: string)
            HumanoidMachine.ChangeState(Character.Name, "Walk")
            HumanoidMachine.TriggerAction(Character, Event, "StartWalk", Key)
        end,
        Jump = function(HumanoidMachine: Machine, Character: Model, Event: Events)
            HumanoidMachine.ChangeState(Character.Name, "Jump", "Idle")
            HumanoidMachine.TriggerAction(Character, Event, "Jump")
        end,
    },

    ["Jump"] = {
        Jump = function(HumanoidMachine: Machine, Character: Model, Event: Events, Direction: Vector3)
            RayMovement:Jump(Character, Direction, HumanoidMachine)            
        end,
        ReleaseJump = function(HumanoidMachine: Machine, Character: Model, ...) HumanoidMachine.ChangeToOldState(Character.Name)  end,
        Fall = function(HumanoidMachine: Machine, Character: Model, Event: Events, Key: string) HumanoidMachine.ChangeState(Character.Name, "Fall") end
    },
    ["Fall"] = {
        ReleaseFall = function(HumanoidMachine: Machine, Character: Model, ...)HumanoidMachine.ChangeToOldState(Character.Name)  end,
        StopWalk = function(HumanoidMachine: Machine, Character: Model)
            local Humanoid: CustomHumanoid = HumanoidMachine[Character.Name]
            if not  Humanoid then return end
            task.desynchronize()
            RayMovement:CheckFalling(Character, HumanoidMachine, Humanoid)
        end,

    }
}



return Humanoid_Controller