--[[
    Current Inputs: {
        Movement: W A S D
    }
    ModuleScript Format:
    local CharacterEvents -- events made from the Character Controller script   
    local MovementEvent: Unreliable -- CharacterEvents.MovementEvent  
    local Movement_Util
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

