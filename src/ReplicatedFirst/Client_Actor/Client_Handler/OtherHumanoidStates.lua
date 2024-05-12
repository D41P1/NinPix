--[[Info
The State moudel for Humanoids
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared
-- local Map_Manager = require(ReplicatedStorage.Shared.Map_Manager)
local SharedTypes = require(Shared.SharedType)
-- local Event_Manager = require(Shared.Event_Manager)
-- local ClientActor = script.Parent.Parent
local CharacterHandler = require(script.Parent.Character_Handler)
-- local Buffer_Converter = require(Shared.Buffer_Converter)

type CustomHumanoid = SharedTypes.CustomHumanoid
type Events = RemoteEvent --| UnreliableRemoteEvent
type Machine = SharedTypes.Machine
--/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
-- //////////////////////////////////////////// new rule added CharacterName and UID are equal ////////////////////////////////////////////////////////////
--/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
local OtherHumanoidStates = {
    ["Walk"] = {
        StopWalk = function(HumanoidMachine: Machine, Character: Model, Event: Events, EndPos: Vector3?)
            local UID = Character.Name
            local Humanoid: CustomHumanoid = HumanoidMachine[UID]
            if not  Humanoid then return end
            task.synchronize()
            if  Humanoid.MoveTracker then Humanoid.MoveTracker:Pause(); Humanoid.MoveTracker:Destroy() end
            if Humanoid.Walk then  Humanoid.Walk:Stop(); Humanoid.IsWalking = false end
            -- if Event then Event_Manager:FireToServer(Event) end
            task.desynchronize()
            local OtherProfile: CharacterHandler.Profile = CharacterHandler.GiveProfile(UID)
            if not OtherProfile then warn("no OtherProfile"); return end
            -- print("send StopForward") -- TESTING THIS STOPPING NOT WORKING/////////////////////////////////////////////////////////
            OtherProfile.Forward:SendMessage("StopForward")
            HumanoidMachine.ChangeState(UID, "Idle")
        end,        
        StartWalk = function(HumanoidMachine: Machine, Character: Model, _, Pos: Vector3)task.desynchronize()
            local UID = Character.Name
            local Humanoid: CustomHumanoid = HumanoidMachine[UID]
            local function playAnim() task.synchronize(); Humanoid.Walk:Play(); Humanoid.IsWalking = true end
            local OtherProfile: CharacterHandler.Profile = CharacterHandler.GiveProfile(UID)
            if not OtherProfile then warn("no OtherProfile"); return end
            if not Humanoid.IsWalking then playAnim()  end
            OtherProfile.Forward:SendMessage("StartForwardRun", Pos)
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
            -- if  Event then Event_Manager:FireToServer(Event, Direction) end 
        end,
        ReleaseJump = function(HumanoidMachine: Machine, Character: Model, ...) HumanoidMachine.ChangeToOldState(Character.Name)  end,
        Fall = function(HumanoidMachine: Machine, Character: Model, Event: Events, Key: string) HumanoidMachine.ChangeState(Character.Name, "Fall") end
    },
    ["Fall"] = {
        ReleaseFall = function(HumanoidMachine: Machine, Character: Model, ...)HumanoidMachine.ChangeToOldState(Character.Name)  end,
        StopWalk = function(HumanoidMachine: Machine, Character: Model, _, EndPos: Vector3?)
            local Humanoid: CustomHumanoid = HumanoidMachine[Character.Name]
            if not  Humanoid then return end
        end,
    }
}



return OtherHumanoidStates