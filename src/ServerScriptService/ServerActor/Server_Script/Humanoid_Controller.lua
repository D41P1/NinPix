--!native
--* FOR PLAYER humanoids only NPCs are handled differently
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
local Walk_Func  = function(HumanoidMachine: Machine, UID:string, Event: Events, MoveVector: Vector3,  ForwardActor: Actor)
    task.synchronize()
    ForwardActor:SendMessage("Walk", MoveVector)
end
local Jump_Func = function(HumanoidMachine: Machine, UID: string, Event: Events, ...)
    HumanoidMachine.ChangeState(UID, "Jump", "Walk")
    HumanoidMachine.ServerTriggerAction(UID, Event, "Jump", ...)
end
local WallRun_Func = function(HumanoidMachine: Machine, UID: string, Event: Events, LookVector: Vector3,  ForwardActor: Actor)
    ForwardActor:SendMessage("WallRun", LookVector)
end
local QDash_Func = function(HumanoidMachine: Machine, UID: string, Event: Events, LookVector: Vector3,  ForwardActor: Actor)
    ForwardActor:SendMessage("QDash", LookVector)
end
local Humanoid_Controller = {
    ["Walk"] = {
        StopWalk = function(HumanoidMachine: Machine, UID: string) task.desynchronize()
            HumanoidMachine.ChangeState(UID, "Idle")
        end,    
        QDash = QDash_Func,    
        StartWalk =Walk_Func,
        Jump = Jump_Func,
        WallRun = WallRun_Func
    },
    ["Idle"] = {
        StartWalk = function(HumanoidMachine: Machine, UID, Event: Events, ...)
            HumanoidMachine.ChangeState(UID, "Walk")
            HumanoidMachine.ServerTriggerAction(UID, Event, "StartWalk", ...)
        end,
        Jump = Jump_Func,
        QDash = QDash_Func,
        WallRun = WallRun_Func
    },
    ["Jump"] = {
        Jump = function(HumanoidMachine: Machine, UID: string, Event: Events, ForwardActor: Actor)
            ForwardActor:SendMessage("Jump")
        end,
        StartWalk =Walk_Func,
        QDash = QDash_Func,    
        WallRun = WallRun_Func
    },
    
}



return Humanoid_Controller