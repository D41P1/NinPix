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
local MovementLogic = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserService = game:GetService("UserService")
local ServerScript = script.Parent.Parent

local Shared = ReplicatedStorage.Shared
local RateLimiter = require(Shared.RateLimiter)
local Map_Manager = require(Shared.Map_Manager)
local MessageAPI = require(ServerScript.MessageAPI)
local Eventmanager = require(Shared.Event_Manager)
local HumanoidMachine = require(Shared.HumanoidMachine)

type CharController = {
    GiveCharacter: (UID: string) -> Model
}
local CharController: CharController 
function MovementLogic.Init(Character_Controller: CharController)
    CharController = Character_Controller
end
local NetMap = Map_Manager:GetMapType("NetworkHashMap")
-- local Count = 0
function MovementLogic.Walk(player: Player, DirectionBuffer: buffer)
    if typeof(DirectionBuffer) ~= "buffer" then task.synchronize(); player:Kick("Spoof Buffer move"); return end
    if buffer.len(DirectionBuffer) > 64 then  task.synchronize(); player:Kick("Spoof buffer move".. buffer.len(DirectionBuffer) ); return end
    if RateLimiter.ServerCheck(player, "Move") then return end
    local UID = player:GetAttribute("UID") 
    local References = {"number", "Vector3"}
    local NetPartition: number , Direction: Vector3 =  Eventmanager.Read(References, DirectionBuffer)
    local Character = CharController.GiveCharacter(UID)
    local CurrentPos =  Character.PrimaryPart.Position 
    NetPartition = math.abs(NetPartition)
    -- MessageAPI.SendToSSS("Network", player.Name, NetPartition, "M", DirectionBuffer, UID, CurrentPos)
    -- anti cheat
    if math.round(NetPartition) ~= NetPartition then task.synchronize(); player:Kick("Spoof NetPart Move: ".. NetPartition); return end
    if NetPartition > 64 then task.synchronize(); player:Kick("Spoof NetPart move"); return end 
    -- anti cheat
    local Pos:Vector3 =  NetMap[NetPartition]
    if (Pos - CurrentPos).Magnitude > 270 then task.synchronize(); player:Kick("Spoof Netpart move"); return end 
    HumanoidMachine.TriggerAction(Character, nil, "StartWalk", Direction)
end
function MovementLogic.StopWalk(player: Player, NetPartBuffer: buffer)
    if typeof(NetPartBuffer) ~= "buffer" then task.synchronize(); player:Kick("Spoof Buffer move"); return end
    if buffer.len(NetPartBuffer) > 64 then  task.synchronize(); player:Kick("Spoof buffer move".. buffer.len(NetPartBuffer) ); return end
    
    local References = {"number", "Vector3"}
    local NetPartition: number  =  Eventmanager.Read(References, NetPartBuffer)
    local UID = player:GetAttribute("UID") -- fire to all clients
    local Character = CharController.GiveCharacter(UID)
    local CurrentPos= Character.PrimaryPart.Position
    NetPartition = math.abs(NetPartition)
    MessageAPI.SendToSSS("Network", player.Name, NetPartition,   "S",  UID, CurrentPos)    
    -- anti cheat
    if math.round(NetPartition) ~= NetPartition then task.synchronize(); player:Kick("Spoof NetPart Move"); return end
    if NetPartition > 64 then task.synchronize(); player:Kick("Spoof NetPart move"); return end 
    -- anti cheat
    local Pos:Vector3 =  NetMap[NetPartition]
    if (Pos - CurrentPos).Magnitude > 270 then task.synchronize(); player:Kick("Spoof Netpart move"); return end 
    HumanoidMachine.TriggerAction(Character, nil, "StopWalk")
end
function MovementLogic.Jump(player: Player, DirectionBuffer: buffer)
    if typeof(DirectionBuffer) ~= "buffer" then task.synchronize(); player:Kick("Spoof Buffer move"); return end
    if buffer.len(DirectionBuffer) > 64 then  task.synchronize(); player:Kick("Spoof buffer move".. buffer.len(DirectionBuffer) ); return end
    if RateLimiter.ServerCheck(player, "Jump") then return end
    local UID = player:GetAttribute("UID") 
    local Character = CharController.GiveCharacter(UID)
    local CurrentPos
    -- Count += 1
    -- if Count == 8 then Count = 0; 
    CurrentPos = Character.PrimaryPart.Position 
    -- end
    MessageAPI.SendToSSS("Network", player.Name, nil,   "J", DirectionBuffer, UID, CurrentPos)    

    local References = {"Vector3"}
    local Direction: Vector3 =  Eventmanager.Read(References, DirectionBuffer)
    HumanoidMachine.TriggerAction(Character, nil, "Jump", Direction)
end


return MovementLogic
