--[[Info
The State moudel for Humanoids
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared
local Map_Manager = require(ReplicatedStorage.Shared.Map_Manager)
local SharedTypes = require(Shared.SharedType)
local Event_Manager = require(Shared.Event_Manager)
local MovementHelper = require(script.Parent.Parent.MovementHelper)
local RayMovement = require(script.Parent.RayMovement)


type CustomHumanoid = SharedTypes.CustomHumanoid
type Events = RemoteEvent --| UnreliableRemoteEvent
type Machine = SharedTypes.Machine
--/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
-- //////////////////////////////////////////// new rule added CharacterName and UID are equal ////////////////////////////////////////////////////////////
--/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
local HumanoidStates = {
    ["Walk"] = {
        StopWalk = function(HumanoidMachine: Machine, Character: Model, Event: Events, EndPos: Vector3?)
            HumanoidMachine.ChangeState(Character.Name, "Idle")
            local Humanoid: CustomHumanoid = HumanoidMachine[Character.Name]
            if not  Humanoid then return end
            local NetworkPartition: number =  Map_Manager.GiveClosestNetPartition()
            task.synchronize()
            if  Humanoid.MoveTracker then Humanoid.MoveTracker:Pause(); Humanoid.MoveTracker:Destroy() end
            if Humanoid.Walk then  Humanoid.Walk:Stop(); Humanoid.IsWalking = false end
            if Event then Event_Manager:FireToServer(Event, NetworkPartition) end
            task.desynchronize()
            RayMovement:CheckFalling(Character, HumanoidMachine, Humanoid, EndPos)
        end,        
        StartWalk = function(HumanoidMachine: Machine, Character, Event: Events, Direction: Vector3)task.desynchronize()
            local Humanoid: CustomHumanoid = HumanoidMachine[Character.Name]
            local NetworkPartition: number =  Map_Manager.GiveClosestNetPartition()
            local function playAnim() task.synchronize(); Humanoid.Walk:Play(); Humanoid.IsWalking = true end
            if Event then  Event_Manager:FireToServer(Event, NetworkPartition, Direction) end
            if not Humanoid.IsWalking then playAnim()  end
            RayMovement:RayWalk(Character, Direction, Humanoid, HumanoidMachine) 
        end,
        Jump = function(HumanoidMachine: Machine, Character: Model, Event: Events, Key: string)
            local Humanoid: CustomHumanoid = HumanoidMachine[Character.Name]
            if not  Humanoid then return end
            if  Humanoid.MoveTracker then task.synchronize(); Humanoid.MoveTracker:Pause(); Humanoid.MoveTracker:Destroy() end
            Humanoid.Walk:Stop(); Humanoid.IsWalking = false 
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
        StartWalk = function(HumanoidMachine: Machine, Character: Model, Event: Events, Direction: Vector3)
            HumanoidMachine.ChangeState(Character.Name, "Walk")
            HumanoidMachine.TriggerAction(Character, Event, "StartWalk", Direction)
        end,
        Jump = function(HumanoidMachine: Machine, Character: Model, Event: Events)
            HumanoidMachine.ChangeState(Character.Name, "Jump", "Idle")
            HumanoidMachine.TriggerAction(Character, Event, "Jump")
        end,
    },
    ["Jump"] = {
        Jump = function(HumanoidMachine: Machine, Character: Model, Event: Events, Direction: Vector3)
            if  Event then Event_Manager:FireToServer(Event, Direction) end 
            RayMovement:Jump(Character, Direction, HumanoidMachine)            
        end,
        ReleaseJump = function(HumanoidMachine: Machine, Character: Model, ...) HumanoidMachine.ChangeToOldState(Character.Name)  end,
        Fall = function(HumanoidMachine: Machine, Character: Model, Event: Events, Key: string) HumanoidMachine.ChangeState(Character.Name, "Fall") end
    },
    ["Fall"] = {
        ReleaseFall = function(HumanoidMachine: Machine, Character: Model, ...)HumanoidMachine.ChangeToOldState(Character.Name)  end,
        StopWalk = function(HumanoidMachine: Machine, Character: Model, _, EndPos: Vector3?)
            local Humanoid: CustomHumanoid = HumanoidMachine[Character.Name]
            if not  Humanoid then return end
            task.desynchronize()
            RayMovement:CheckFalling(Character, HumanoidMachine, Humanoid, EndPos)
        end,
    }
}



return HumanoidStates