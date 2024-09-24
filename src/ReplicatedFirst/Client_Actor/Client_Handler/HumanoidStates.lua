--[[Info
The State moudel for Humanoids
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared
-- local Map_Manager = require(ReplicatedStorage.Shared.Map_Manager)
local SharedTypes = require(Shared.SharedType)
local Event_Manager = require(Shared.Event_Manager)
-- local RayMovement = require(Shared.RayMovement)
-- local ClientActor = script.Parent.Parent
local CharacterHandler = require(script.Parent.Character_Handler)
-- local MovementHelper = require(Shared.MovementHelper)
local Buffer_Converter = require(Shared.Buffer_Converter)

type CustomHumanoid = SharedTypes.CustomHumanoid
type Events = RemoteEvent --| UnreliableRemoteEvent
type Machine = SharedTypes.Machine
--* /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
--* /////////////////////////////////////////// new rule:  CharacterName and UID are equal ////////////////////////////////////////////////////////////
--* /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
local HumanoidStates = {
    ["Walk"] = {
        StopWalk = function(HumanoidMachine: Machine, Character: Model, Event: Events, EndPos: Vector3?)
            if not Event then warn("HOW"); return end
            local UID = Character.Name
            local Humanoid: CustomHumanoid = HumanoidMachine[UID]
            if not  Humanoid then return end
            local sy =  task.synchronize
            if  Humanoid.MoveTracker then sy(); Humanoid.MoveTracker:Pause(); Humanoid.MoveTracker:Destroy() end
            if Humanoid.Walk then sy(); Humanoid.Walk:Stop(0.5); Humanoid.IsWalking = false end
            if Event then Event_Manager:FireToServer(Event) end
            HumanoidMachine.ChangeState(UID, "Idle")
        end,        
        StartWalk = function(HumanoidMachine: Machine, Character: Model, Event: Events, RelativeDirCF: CFrame)task.desynchronize()
            if not Event then warn("HOW"); return end
            local UID = Character.Name
            local WS =  Character:GetAttribute("WalkSpeed")
            local Humanoid: CustomHumanoid = HumanoidMachine[UID]
            if not Humanoid.IsWalking then task.synchronize(); Humanoid.Walk:Play(); Humanoid.IsWalking = true; Humanoid.Walk:AdjustSpeed(WS/10) end
            local b:buffer = Buffer_Converter.CF_Write_Buffer(RelativeDirCF)
            if Event then task.synchronize(); Event:FireServer(b)  end
            
            local OtherProfile: CharacterHandler.Profile = CharacterHandler.GiveProfile(UID)
            if not OtherProfile then warn("no OtherProfile"); return end
            OtherProfile.Forward:SendMessage("StartForward", RelativeDirCF)
            OtherProfile.Down:SendMessage("StartDownward", RelativeDirCF)
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
        Jump = function(HumanoidMachine: Machine, Character: Model, Event: Events, RelativeDirCF: CFrame?, ...)
            local UID = Character.Name
            HumanoidMachine.ChangeState(UID, "Fall")        
            local OtherProfile: CharacterHandler.Profile = CharacterHandler.GiveProfile(UID)
            if not OtherProfile then warn("no OtherProfile"); return end
            local DownActor = OtherProfile.Down 
            local Writei16 = buffer.writei16
            if RelativeDirCF then   
                local b = buffer.create(6)
                local Look = RelativeDirCF.LookVector
                Writei16(b, 0, Look.X *10000)
                Writei16(b, 2, Look.Y *10000)
                Writei16(b, 4, Look.Z *10000)
                if  Event then Event_Manager:RawFireToServer(Event, b) end 
                DownActor:SendMessage("JumpWithMovement", RelativeDirCF); 
                return 
            end
            if Event then Event_Manager:RawFireToServer(Event, buffer.create(0)) end 
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
--[[failed wallrun
if WallRun  and Character:GetAttribute("WallRun") then
    DownActor:SendMessage("WallRun", RelativeDirCF); 
    HumanoidMachine.TriggerAction(Character, nil, "ReleaseFall");

    return
end
            
]]
            


return HumanoidStates