--[[Info
The State moudel for Humanoids
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared
-- local Map_Manager = require(ReplicatedStorage.Shared.Map_Manager)
local SharedTypes = require(Shared.SharedType)
-- local RayMovement = require(Shared.RayMovement)
-- local ClientActor = script.Parent.Parent
local CharacterHandler = require(script.Parent.Character_Handler)
-- local MovementHelper = require(Shared.MovementHelper)
local Buffer_Converter = require(Shared.Buffer_Converter)

type PixelCharacter = typeof(workspace.WORKING_PROD_PixelDummy)
type CustomHumanoid = SharedTypes.CustomHumanoid
type Events = RemoteEvent --| UnreliableRemoteEvent
type Machine = SharedTypes.Machine
local HumanoidStates = {}
local WalkFunc = function(HumanoidMachine: Machine, Character: Model, Event: Events, RelativeDirCF: CFrame)
    task.synchronize()
    local UID = Character.Name    
    local OtherProfile: CharacterHandler.Profile = CharacterHandler.GiveProfile(UID)
    if not OtherProfile then warn("no OtherProfile"); return end
    OtherProfile.Forward:SendMessage("Walk", RelativeDirCF.LookVector)
    OtherProfile.Procedural:SendMessage("Switch", true)
end
local JumpFunc = function(HumanoidMachine: Machine, Character:PixelCharacter, Event: Events, RelativeDirCF: CFrame, ...)
    task.synchronize()
    local UID = Character.Name
    local OtherProfile: CharacterHandler.Profile = CharacterHandler.GiveProfile(UID)
    if not OtherProfile then warn("no OtherProfile"); return end
    HumanoidMachine.ChangeState(Character.Name, "Jump")
    OtherProfile.Forward:SendMessage("Jump")
    OtherProfile.Procedural:SendMessage("Switch")
end
local WallRun_Func = function(HumanoidMachine: Machine, Character:PixelCharacter, Event: Events, CameraCF: CFrame, ...)
    task.synchronize()
    local Wi16 = buffer.writei16
    local CamLookBuffer = buffer.create(6)
    local x, y, z = CameraCF.LookVector.X, CameraCF.LookVector.Y, CameraCF.LookVector.Z
    Wi16(CamLookBuffer, 0, x *10000); Wi16(CamLookBuffer, 2, y *10000); Wi16(CamLookBuffer, 4, z *10000)
    Event:FireServer(CamLookBuffer)

    local UID = Character.Name
    local OtherProfile: CharacterHandler.Profile = CharacterHandler.GiveProfile(UID)
    if not OtherProfile then warn("no OtherProfile"); return end
    OtherProfile.Procedural:SendMessage("WallRun")
end
local QDash_Func = function(HumanoidMachine: Machine, Character:PixelCharacter, Event: Events, CameraLookVector:Vector3, ...)
    -- Event:FireServer(CamLookBuffer)
    task.synchronize()
    local UID = Character.Name
    local OtherProfile: CharacterHandler.Profile = CharacterHandler.GiveProfile(UID)
    if not OtherProfile then warn("no OtherProfile"); return end
    OtherProfile.Forward:SendMessage("QDash", CameraLookVector)
end
HumanoidStates["Walk"] = {
    StopWalk = function(HumanoidMachine: Machine, Character: Model, Event: Events)
        local UID = Character.Name
        -- local Humanoid: CustomHumanoid = HumanoidMachine[UID]
        -- if not  Humanoid then return end
        -- if Humanoid.MoveTracker then sy(); Humanoid.MoveTracker:Pause(); Humanoid.MoveTracker:Destroy() end
        -- if Humanoid.Walk then Humanoid.IsWalking = false end
        -- if Event then task.synchronize(); Event:FireServer() end
        HumanoidMachine.ChangeState(UID, "Idle")
        local OtherProfile: CharacterHandler.Profile = CharacterHandler.GiveProfile(UID)
        if not OtherProfile then warn("no OtherProfile"); return end
        OtherProfile.Procedural:SendMessage("Switch")
    end,        
    StartWalk = WalkFunc,
    Jump = JumpFunc, 
    QDash  = QDash_Func,
    WallRun = WallRun_Func     
}
HumanoidStates["Idle"] = {
    StartWalk = function(HumanoidMachine: Machine, Character: Model, Event: Events, ...)
        HumanoidMachine.ChangeState(Character.Name, "Walk")
        HumanoidMachine.TriggerAction(Character, Event, "StartWalk", ...)
    end,
    Jump = JumpFunc,
    WallRun = WallRun_Func,  
    QDash  = QDash_Func,
}
HumanoidStates["Jump"] = {
    StartWalk = WalkFunc,
    ReleaseJump = function(HumanoidMachine: Machine, Character: Model, ...) HumanoidMachine.ChangeToOldState(Character.Name)  end,
    WallRun = WallRun_Func,
    QDash  = QDash_Func,
}

--[[ USELESS
HumanoidStates["Fall"] = {
    ReleaseFall = function(HumanoidMachine: Machine, Character: Model, ...)HumanoidMachine.ChangeToOldState(Character.Name)  end,
    StopWalk = function(HumanoidMachine: Machine, Character: Model, _, EndPos: Vector3?)
        local Humanoid: CustomHumanoid = HumanoidMachine[Character.Name]
        if not  Humanoid then return end
    end,
}

]]

--[[failed wallrun
if WallRun  and Character:GetAttribute("WallRun") then
    DownActor:SendMessage("WallRun", RelativeDirCF); 
    HumanoidMachine.TriggerAction(Character, nil, "ReleaseFall");

    return
end
            
]]
            


return HumanoidStates