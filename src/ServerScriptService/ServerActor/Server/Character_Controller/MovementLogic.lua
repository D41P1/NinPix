--[[
    local MovementLogic = {}
    function MovementLogic:Move(DirectionBuffer: buffer)
        -- checks todo: {
            if not a buffer then kick
            buffer length >= 13
            <= walkspeed Radius distance
            raycast to see if it hits walls/trees etc,  use Cframe:Lerp() for interpolation 
            
            When Physics is added add this also:
            raycast check to ground to see if there is a floor if not call a  PhyscisEngine:fall(RaycastPosition) 
        }
    end

    return MovementLogic
]]