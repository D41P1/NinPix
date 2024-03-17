--[[
    local Movement_Util = {
        Make a function that returns Direction { CameraCFrame: CFrame, CharacterPosition: Vector3 }

        Current plan is using +-CameraCFrame.{RightVector} to represent the A,D
        -- get the x and z only and use Character Y-----------------
        -- -1000 offset must be the same because of pythag and to get Accurate diagonal movement
        W = ((cameraCFrame * CFrame.new(0, 1, -1000)).Position - CharacterPos).Unit 
        S = (cameraCFrame.Positon - CharacterPos).Unit
        A = CharacterPos + (cameraCFrame.RightVector * -1000)
        D = CharacterPos + (cameraCFrame.RightVector * 1000)
        WA = (( (W + A) / 2) - CharacterPos).Unit -- (MidPoint of W and A - CharacterPos).Unit 
        WD = (( (W + D) / 2) - CharacterPos).Unit  
        SD = (( (S + A) / 2) - CharacterPos).Unit  
        SD = (( (S + D) / 2) - CharacterPos).Unit  
        --------------------------------------------------
        --The reason for the Y offset is in the case they decide the wanna look { birds-eye | worms-eye }view or OverView/UnderView        
        return Direction
    }
    return Movement_Util
]]