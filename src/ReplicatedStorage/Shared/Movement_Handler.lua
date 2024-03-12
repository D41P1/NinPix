--[[
    local Movement_Util = {
        Make a function that returns Direction { CameraCFrame: CFrame, CharacterPosition: Vector3 }

        Current plan is using +-CameraCFrame.{RightVector} to represent the S,D
        for W { 
        if Camera.Y > 0 then + Z,50 and +Y,1
        else
            + Z,50 and -Y,1
        }
        for S {
        if Camera.Y > 0 then -Y,1
        else
            +Y,1
        }
        --The reason for the Y offset is in the case they decide the wanna look { birds-eye | worms-eye }view or OverView/UnderView
        
        then Create a new vecotr with the X an Z of that Vector and  CharacterPosition.Y  = EndPos
        Direction = EndPos - CharacterPos
        return Direction
    }
    return Movement_Util
]]