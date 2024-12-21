--!native
--[[
    local MovementLogic = {}
    function MovementLogic:Move(DirectionBuffer: buffer)
        -- checks todo: {
            if not a buffer then kick
            buffer length >= 13
            <= walkspeed Radius distance
            raycast to see if it hits walls/trees etc,  use Cframe:Lerp() for interpolation     
        }
    end

    return MovementLogic
]]
-- local RunSerivce = game:GetService("RunService")
local MovementLogic = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScript = script.Parent.Parent

local Shared = ReplicatedStorage.Shared
-- local Humanoid_Controller = require(script.Parent.Parent.Humanoid_Controller)
local Character_Controller = require(script.Parent.Character_Controller)
local RateLimiter = require(Shared.RateLimiter)
-- local Map_Manager = require(Shared.Map_Manager)
--
local BufferConverter = require(Shared.Buffer_Converter)
local HumanoidMachine = require(Shared.HumanoidMachine)

type CharController = {
    GiveCharacter: (UID: string) -> Model
}
function MovementLogic.Jump(player: Player)
    if RateLimiter.ServerCheck(player, "Jump") then return end
    local UID = player:GetAttribute("UID")
    local Profile = Character_Controller.Give_Profile(UID)
    local ForwardActor:Actor = Profile["FA"]
    HumanoidMachine.ServerTriggerAction(UID, nil, "Jump", ForwardActor)
end
function MovementLogic.Dash(player: Player, CameraLookBuffer:buffer, offset:number)
    if offset + 7 > buffer.len(CameraLookBuffer)  then  return end --TODO BAN
    --* 6 bytes cos its not projected
    offset += 1 --* cos of the Length
    local UID = player:GetAttribute("UID")
    local Ri16= buffer.readi16
    local X, Y, Z = Ri16(CameraLookBuffer, offset), Ri16(CameraLookBuffer, offset + 2), Ri16(CameraLookBuffer, offset + 4)
    local Look:Vector3 = Vector3.new(X, Y, Z).Unit
    local Profile = Character_Controller.Give_Profile(UID)
    local ForwardActor:Actor = Profile["FA"]
    HumanoidMachine.ServerTriggerAction(UID, nil, "QDash", Look, ForwardActor)    
end
function MovementLogic.UpdMoveLook(player:Player, MoveLook_Buffer:buffer, offset:number)
    if offset + 3 > buffer.len(MoveLook_Buffer)  then  return end --TODO BAN
    local UID = player:GetAttribute("UID")
    local Profile = Character_Controller.Give_Profile(UID)
    local ForwardActor:Actor = Profile["FA"]
    local UV3V:Vector3Value = Profile["UV3V"]
    local LV3:Vector3Value = Profile["LV3"]
    local CFV:CFrameValue = Profile["CFV"]
    local Type_Of_Upd = buffer.readu8(MoveLook_Buffer, offset)
    offset += 1    
    task.synchronize();
    if Type_Of_Upd == 2  then  
        local LookVector = BufferConverter.Reader_UnitVector_Buffer(MoveLook_Buffer, UV3V.Value, offset)
        LV3.Value =  LookVector
        CFV.Value = CFrame.lookAlong(CFV.Value.Position, LookVector, CFV.Value.UpVector)
        return
    end
    if Type_Of_Upd == 4  then  
        local LookVector = BufferConverter.Reader_UnitVector_Buffer(MoveLook_Buffer, UV3V.Value, offset)
        LV3.Value =  LookVector
        offset += 2
        local MoveVector:Vector3 = BufferConverter.Reader_UnitVector_Buffer(MoveLook_Buffer, UV3V.Value, offset )

        HumanoidMachine.ServerTriggerAction(UID, nil, "StartWalk", MoveVector, ForwardActor)
        return 
    end
end
return MovementLogic
