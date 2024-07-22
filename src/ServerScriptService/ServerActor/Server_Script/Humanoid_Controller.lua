--!native
--[[Info
Humanoid Controller State Module for Humanoids server
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
--local ServerScript = script.Parent
local Shared = ReplicatedStorage.Shared
local SharedTypes = require(Shared.SharedType)
--//local ServerRayMovement = require(ServerScript.ServerRayMovement)
type CustomHumanoid = SharedTypes.CustomHumanoid
type Events = RemoteEvent --| UnreliableRemoteEvent
type Machine = SharedTypes.Machine
local Humanoid_Controller = {
    ["Walk"] = {
        StopWalk = function(HumanoidMachine: Machine, UID: string) task.desynchronize()
            HumanoidMachine.ChangeState(UID, "Idle")
            --// local Humanoid: CustomHumanoid = HumanoidMachine[UID]
            --// if not  Humanoid then return end
            --// if Humanoid.MoveTracker then task.synchronize(); Humanoid.MoveTracker:Pause(); Humanoid.MoveTracker:Destroy(); Humanoid.MoveTracker = nil end
            --// ServerRayMovement:CheckFalling(UID, HumanoidMachine, Humanoid)
        end,        
        StartWalk = function(HumanoidMachine: Machine, UID:string, Event: Events, CF: CFrame,  ForwardActor: Actor, DownwardsActor: Actor)
            task.desynchronize()
            ForwardActor:SendMessage("StartForward", CF)
            DownwardsActor:SendMessage("StartDownward", CF)
        end,
        Jump = function(HumanoidMachine: Machine, UID: string, Event: Events, ...)
            HumanoidMachine.ChangeState(UID, "Jump", "Walk")
            HumanoidMachine.ServerTriggerAction(UID, Event, "Jump", ...)
        end, 
        Fall = function(HumanoidMachine: Machine, UID: string, Event: Events, Key: string)
            local Humanoid: CustomHumanoid = HumanoidMachine[UID]
            if not  Humanoid then return end
            if  Humanoid.MoveTracker then task.synchronize(); Humanoid.MoveTracker:Pause(); Humanoid.MoveTracker:Destroy() end
            Humanoid.Walk:Stop(); Humanoid.IsWalking = false
            HumanoidMachine.ChangeState(UID, "Fall", "Walk")
        end
    },
    ["Idle"] = {
        StartWalk = function(HumanoidMachine: Machine, UID, Event: Events, ...)
            HumanoidMachine.ChangeState(UID, "Walk")
            HumanoidMachine.ServerTriggerAction(UID, Event, "StartWalk", ...)
        end,
        Jump = function(HumanoidMachine: Machine, UID: string, Event: Events, ...)
            HumanoidMachine.ChangeState(UID, "Jump", "Idle", ...)
            HumanoidMachine.ServerTriggerAction(UID, Event, "Jump", ...)
        end,
    },
    ["Jump"] = {
        Jump = function(HumanoidMachine: Machine, UID: string, Event: Events, Direction: Vector3, ForwardActor: Actor)
            if not Direction then  ForwardActor:SendMessage("Jump"); return end
            ForwardActor:SendMessage("JumpWithMovement", Direction)
            --// ServerRayMovement:Jump(UID, Direction, HumanoidMachine)
        end,
        ReleaseJump = function(HumanoidMachine: Machine, UID: string, ...) HumanoidMachine.ChangeToOldState(UID, ...)  end,
        Fall = function(HumanoidMachine: Machine, UID: string, Event: Events, ...) HumanoidMachine.ChangeState(UID, "Fall", ...) end
    },
    ["Fall"] = {
        ReleaseFall = function(HumanoidMachine: Machine, UID: string, ...)HumanoidMachine.ChangeToOldState(UID)  end,
    }
}



return Humanoid_Controller