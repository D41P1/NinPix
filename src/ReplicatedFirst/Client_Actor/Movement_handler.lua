--!native
--[[
    local Movement_Util = {
        Make a function that returns Direction { CameraCFrame: CFrame, CharacterPosition: Vector3 }

        Current plan is using +-CameraCFrame.{RightVector} to represent the A,D
        -- get the x and z only and use Character Y-----------------
        -- -1000 offset must be the same because of pythag and to get Accurate diagonal movement
        W = RayMovement_Manager(CustomHumanoidState, W)
        A =  RayMovement_Manager(CustomHumanoidState, A)
        S =  RayMovement_Manager(CustomHumanoidState, S)
        D = RayMovement_Manager(CustomHumanoidState, D)
        
        WA =  RayMovement_Manager(CustomHumanoidState, WA)
        WD =  RayMovement_Manager(CustomHumanoidState, WD)
        
        SA =  RayMovement_Manager(CustomHumanoidState, SA)
        SD =  RayMovement_Manager(CustomHumanoidState, SD)

        AW =  RayMovement_Manager(CustomHumanoidState, WA)
        AS =  RayMovement_Manager(CustomHumanoidState, SA)
        
        DW =  RayMovement_Manager(CustomHumanoidState, WD)
        DS =  RayMovement_Manager(CustomHumanoidState, SD)


        --------------------------------------------------
        --The reason for the Y offset is in the case they decide the wanna look { birds-eye | worms-eye }view or OverView/UnderView        
        return Direction
    }

    function MovementUtil:CallLogic(Key: string)
        if not  MovementUtil[Key] then  return end  
        return MovementUtil[Key]()
    end
]]
local ReplicateStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicateStorage.Shared
local SharedTypes = require(Shared.SharedType)
local Map_Manager = require(Shared.Map_Manager)
local CharacterHandler = require(script.Parent.Client_Handler.Character_Handler)
local Events: SharedTypes.CharacterEvents = require(script.Parent.Event_Handler)["Events"]
local HumanoidMachine = require(Shared.HumanoidMachine)
local MovementHelper = require(Shared.MovementHelper) 
local player = game.Players.LocalPlayer
local PlayerName  = player.Name
local RateLimiter = require(Shared.RateLimiter); RateLimiter.InitProfile(PlayerName)

local Movement_Handler = {
    ["W"] = HumanoidMachine.TriggerAction,
    ["A"] = HumanoidMachine.TriggerAction,
    ["S"] = HumanoidMachine.TriggerAction,
    ["D"] = HumanoidMachine.TriggerAction,
    ["WA"] = HumanoidMachine.TriggerAction,
    ["WD"] = HumanoidMachine.TriggerAction,
    ["SA"] = HumanoidMachine.TriggerAction,
    ["SD"] = HumanoidMachine.TriggerAction,
    ["AW"] = HumanoidMachine.TriggerAction,
    ["AS"] = HumanoidMachine.TriggerAction,
    ["DW"] = HumanoidMachine.TriggerAction,
    ["DS"] = HumanoidMachine.TriggerAction,
    ["Stop"] = HumanoidMachine.TriggerAction,
}
local NetHashmap = Map_Manager:GetMapType("NetworkHashMap")
function Movement_Handler:Walk(Character: Model, Direction: Vector3)
    local Body = Character.PrimaryPart
    local CharacterPos = Body.Position
    local PosToSend = CharacterPos + (Direction *1.5) 
    return PosToSend
end
function Movement_Handler:Jump(Character: Model, Event: UnreliableRemoteEvent, Key: string)
    if RateLimiter.ClientCheck(PlayerName, "Jump") then return end    
    if not  Movement_Handler[Key] then HumanoidMachine.TriggerAction(Character, Event, "Jump"); return end  
    local Dir  = MovementHelper:GiveDirection(Character, Key)
    HumanoidMachine.TriggerAction(Character, Event, "Jump", Dir)
end
function Movement_Handler.CheckPlayerCentrePosNetwork()
    local Character: Model = CharacterHandler.GiveCharacter()
    local _, Nearest = Map_Manager:NetworkPartitionCentrePosCheck(Character, NetHashmap)
    Map_Manager.SetClosestNetPartition(Nearest)
end

return Movement_Handler
