--[[
    
    local Character_Controller = {}
    type TableOfEvents = { [string]: Unreliable | Reliable }
    local Connections: { [String]: () -> nil? } = {
        MovementEvent = function(DirectionBuffer: Buffer)
            -- all the checks
            
        end
    }
    function Character_Controller:(Events: TableOfEvents)
        for   loop - connect everything etc
    end
    return Character_Controller
]]