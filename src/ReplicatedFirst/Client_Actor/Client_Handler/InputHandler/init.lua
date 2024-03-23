-- local UserInputService = game:GetService("UserInputService")
-- local Players = game:GetService("Players")
-- local player = Players.LocalPlayer
-- local Mouse = player:GetMouse()
local CameraHandler = require(script.Camera_Handler)
local Connections: {
    [string]: RBXScriptConnection | { RBXScriptConnection } 
} = {}
local ConnectFuncs = {
    function(...) Connections["Camera"] = CameraHandler:Start(...)
    end, 
}
local InputHandler = {}
--[[////////////////////TODO///////////////// 
ANY CharacteEvents write SectionNumber and Partition number also as first 2 in the buffer
sof for example WASD movement Event
The buffer : {
    1, -- Section they are in 
    12,-- Partition they are in  
    Direction --  extra args direction they are moving
}
]]
function InputHandler:GiveConnections(...) for _, Connections in ConnectFuncs do Connections(...) end
end
function InputHandler:DisconnectConnections(TypeOfConnection: string?) task.synchronize()
    if not TypeOfConnection then
        for Key: string, Conns: RBXScriptConnection | { RBXScriptConnection } in Connections do
            if typeof(Conns) == "RBXScriptConnection" then Conns:Disconnect()
            else
                for _, SubConns in Conns do SubConns:Disconnect() end 
            end
        end
    else
        local ConnectionORTable = Connections[TypeOfConnection]
        if typeof(ConnectionORTable) == "RBXScriptConnection" then ConnectionORTable:Disconnect()
        else
            for _, SubConns in ConnectionORTable do SubConns:Disconnect() end 
        end
    end
end

return InputHandler

--[[ Info
This module handles Clients inputs only when they are spawned 
Connect to the CharacterEvents when Spawning in
]]
--[[Modules needed
Event_Manager 
Movement_Handler
]]
--[[
    Current Inputs: {
        Movement: W A S D
    }
    ModuleScript Format:
    local CharacterEvents -- events made from the Character Controller script   
    local MovementEvent: Unreliable -- CharacterEvents.MovementEvent  
    local Movement_Handler
    local Event_Manager 
    //////////////////////////////////////MODULESCRIPT./////////////////////////
    local Inputlogic = require(script.MovementHandler)

    local InputHandler = {}
    local MovementKeys = {}
    function CalculateMovement()
        for loop through MovementKeys
        and Concat the inputs = Key 
        Inputlogic:CallLogic(Key)  
    end
    MovementTracker = {
        ["W"] = function()
            if MovementKeys["W"] then MovementKeys["W"] = nil end
            MovementKeys["W"] = ""
            CalculateMovement()
        end
        ["A"]
        ["WA"]
    } -- could be a submodule
    
    inputhandler["MovementPress"] = userinput connect function(key) 
        if not  MovementTracker[key] then return end
        MovementTracker[key]()
    end)
    inputhandler["MovementRelease"] = userinput connect function(key) 
        if not  MovementTracker[key] then return end
        MovementTracker[key]()
    end)

    function InputHandler:GiveConnections()
        -- so you can disconnect Keybinds if need be from another table
        return inputtable    
    end)
    return InputHandler
]]

