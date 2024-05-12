--[[Info
The State moudel for Humanoids
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared
-- local Map_Manager = require(ReplicatedStorage.Shared.Map_Manager)
local SharedTypes = require(Shared.SharedType)
local Event_Manager = require(Shared.Event_Manager)
local RayMovement = require(Shared.RayMovement)
-- local ClientActor = script.Parent.Parent
local CharacterHandler = require(script.Parent.Character_Handler)
local MovementHelper = require(Shared.MovementHelper)
local Buffer_Converter = require(Shared.Buffer_Converter)

type CustomHumanoid = SharedTypes.CustomHumanoid
type Events = RemoteEvent --| UnreliableRemoteEvent
type Machine = SharedTypes.Machine
--/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
-- //////////////////////////////////////////// new rule added CharacterName and UID are equal ////////////////////////////////////////////////////////////
--/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
local HumanoidStates = {
    ["Walk"] = {
        StopWalk = function(HumanoidMachine: Machine, Character: Model, _: Events, EndPos: Vector3?)
            local UID = Character.Name
            local Humanoid: CustomHumanoid = HumanoidMachine[UID]
            if not  Humanoid then return end
            local sy =  task.synchronize
            if  Humanoid.MoveTracker then sy(); Humanoid.MoveTracker:Pause(); Humanoid.MoveTracker:Destroy() end
            if Humanoid.Walk then sy(); Humanoid.Walk:Stop(0.5); Humanoid.IsWalking = false end
            -- if Event then Event_Manager:FireToServer(Event) end
            HumanoidMachine.ChangeState(UID, "Idle")
        end,        
        StartWalk = function(HumanoidMachine: Machine, Character: Model, Event: Events, Direction: Vector3)task.desynchronize()
            local UID = Character.Name
            local WS =  Character:GetAttribute("WalkSpeed")
            local Humanoid: CustomHumanoid = HumanoidMachine[UID]
            local function playAnim() task.synchronize(); Humanoid.Walk:Play(); Humanoid.IsWalking = true; Humanoid.Walk:AdjustSpeed(WS/10)  end
            local OtherProfile: CharacterHandler.Profile = CharacterHandler.GiveProfile(UID)
            if not OtherProfile then warn("no OtherProfile"); return end
            local Body  = Character.PrimaryPart
            local RelativeDirCF:CFrame = CFrame.new(Direction.X *100, 0, Direction.Z *100)
            local CharacterCF:CFrame = Body.CFrame
            local NewDirCF:CFrame  =  CharacterCF * CFrame.Angles(0, -math.rad(Body.Orientation.Y), 0) * RelativeDirCF           
            local b:buffer = Buffer_Converter.PosWriter(NewDirCF)
            if Event then   Event_Manager:RawFireToServer(Event, b) end
            if not Humanoid.IsWalking then playAnim()  end
            OtherProfile.Forward:SendMessage("StartForward", NewDirCF.Position)
            OtherProfile.Down:SendMessage("StartDownward", NewDirCF)
        end,
        Jump = function(HumanoidMachine: Machine, Character: Model, Event: Events, ...)
            local Humanoid: CustomHumanoid = HumanoidMachine[Character.Name]
            if not  Humanoid then return end
            if  Humanoid.MoveTracker then task.synchronize(); Humanoid.MoveTracker:Pause(); Humanoid.MoveTracker:Destroy() end
            Humanoid.Walk:Stop(); Humanoid.IsWalking = false 
            HumanoidMachine.ChangeState(Character.Name, "Jump", "Walk")
            HumanoidMachine.TriggerAction(Character, Event, "Jump", ...)
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
        StartWalk = function(HumanoidMachine: Machine, Character: Model, Event: Events, ...)
            HumanoidMachine.ChangeState(Character.Name, "Walk")
            HumanoidMachine.TriggerAction(Character, Event, "StartWalk", ...)
        end,
        Jump = function(HumanoidMachine: Machine, Character: Model, Event: Events, ...)
            HumanoidMachine.ChangeState(Character.Name, "Jump", "Idle")
            HumanoidMachine.TriggerAction(Character, Event, "Jump", ...)
        end,
    },
    ["Jump"] = {
        Jump = function(HumanoidMachine: Machine, Character: Model, Event: Events, Direction: Vector3?)
            local UID = Character.Name
            HumanoidMachine.ChangeState(UID, "Fall")
            -- if  Event then Event_Manager:FireToServer(Event, Direction) end -- TODO
            local OtherProfile: CharacterHandler.Profile = CharacterHandler.GiveProfile(UID)
            if not OtherProfile then warn("no OtherProfile"); return end
            local DownActor = OtherProfile.Down 
            if Direction then   DownActor:SendMessage("JumpWithMovement", Direction); return end
            DownActor:SendMessage("Jump")
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



return HumanoidStates