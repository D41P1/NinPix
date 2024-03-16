--[[ this module script is used for handling the clientss inputs{
        calculate direction based on the inputs -- used shared MovementHandler module 
        Handles skill key inputs
        Tool key inputs 
    }
    local InputLogic = {
        ["W"] = function() 
            -- calculate Direction = MovementHandler:GetDirection("W")
            -- write direction to buffer            
        end,
        ["WA"] 
        ["WD]
        ["S"]
        ["SA"]
        ["SD"]
    }

    function InputLogic:CallLogic(Key: string)
        if not  InputLogic[Key] then  return end  
        InputLogic[Key]()
    end


]]