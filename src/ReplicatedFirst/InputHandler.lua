--[[
    Current Inputs: {
        Movement: W A S D
    }
    ModuleScript Format:
    local CharacterEvents -- events made from the Character Controller script   
    local MovementEvent: Unreliable -- CharacterEvents.MovementEvent  
    
    local InputHandler = {}
    inputtable = {
        W = function()
            -- calculate the Direction: Vector3 they wanna move using the x and z of the camera
            -- write direction to buffer
            MovementEvent:FireServer(buffer)
        end
    } -- could be a submodule

    userinput connect function(key) 
        if not  inputtable[key] then return end
        inputtable[key]()
    end)

    function InputHandler:GiveConnections()
        -- so you can disconnect Keybinds if need be from another table
        return inputtable    
    end)
    return InputHandler
]]
