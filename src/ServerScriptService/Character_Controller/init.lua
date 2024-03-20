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