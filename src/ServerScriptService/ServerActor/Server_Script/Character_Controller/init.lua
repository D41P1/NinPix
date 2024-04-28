--[[Info
This module is for Handling All Player Characters (Managing inputs, verifying them, relaying them to other clients etc)
Character_Handler <-|-> Character_Controller
]]
--[[ Modules Needed:
Network_Controller
Map_Manager
RayMovement_Manager
EventManager
Physics_Manager
Humanoid_Manager

-- Has Submodules
]]
--[[
    local Character_Controller = {}
    type TableOfEvents = { [string]: Unreliable | Reliable }    
    local Connections: { [String]: () -> nil? } = {
        MovementEvent = function(DirectionBuffer: Buffer)
            -- all the logic is done in MovementLogic so send it there
        end
    }
    function Character_Controller:(Events: TableOfEvents)
        for   loop - connect everything etc
    end
    return Character_Controller
]]
local MovementLogic = require(script.MovementLogic)
local CollectionService = game:GetService("CollectionService")
local Replicatedstorage = game:GetService("ReplicatedStorage")
local RateLimiter = require(Replicatedstorage.Shared.RateLimiter)
local Character_Controller = {
-- ["Actor"]
}

type TableOfEvents = { string }    
local Connections: { [string]: (Player, buffer) -> nil? } = {
    ["Walk"] = MovementLogic.Walk,
    ["StopWalk"] = MovementLogic.StopWalk,
    ["Jump"] = MovementLogic.Jump
}
function Character_Controller:InitEvents(PlayerName)
    local Events = { "Walk", "Jump","StopWalk" }
    local CharacterEvents = Instance.new("Folder")
    CharacterEvents.Name = "CharacterEvents"
    CharacterEvents.Parent =  Character_Controller["Actor"]
    for _, EventNames in Events do
        local CharacterEvent = Instance.new("UnreliableRemoteEvent")
        CharacterEvent.Name = EventNames
        CharacterEvent.OnServerEvent:ConnectParallel(Connections[EventNames])
        CharacterEvent.Parent = CharacterEvents 
    end
    RateLimiter.InitProfile(PlayerName)
end
function Character_Controller.GiveCharacter(UID: string) return CollectionService:GetTagged(UID)[1] end
return Character_Controller