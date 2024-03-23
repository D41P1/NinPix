--[[ info
This module Manages the verification of the movement through Raycasts   
the handling of a Rollback will also be here or in a submodule of this
]]
--[[ ModulesNeeded 
]]
--[[
    local Movement_Util = {
        This a Client Function {
        --/////////////////// get the x and z only and use Character Y ///////////////////////////
        -- -1000 offset must be the to get Accurate diagonal movement (45 degrees)
        --The reason for the  1 in Y-axis offset if they decide the wanna look { birds-eye | worms-eye }view or OverView/UnderView        
        -- Direction is (EndPoint - StartPoint).Unit
        -- For Diagonal movement you would Calculate the  MidPoint For example {
            WA = (MidPoint of W and A - CharacterPos).Unit  
        }
        Walk {
            W = ((cameraCFrame * CFrame.new(0, 1, -1000)).Position - CharacterPos).Unit 
            S = (cameraCFrame.Positon - CharacterPos).Unit
            A = -cameraCFrame.RightVector  -- for moving CharacterPos + (cameraCFrame.RightVector * -1000)
            D = cameraCFrame.RightVector  -- for moving CharacterPos + cameraCFrame.RightVector * 1000)
            WA = (( (W + (CharacterPos + (A * -1000) ) ) / 2) - CharacterPos).Unit  
            WD = (( (W + (CharacterPos + (D * 1000) ) ) / 2) - CharacterPos).Unit  
            SA = (( (S + (CharacterPos + (A * -1000) ) ) / 2) - CharacterPos).Unit  
            SD = (( (S + (CharacterPos + (D * 1000) ) ) / 2) - CharacterPos).Unit  
        }
        CamCharacterDiffInYAxis = CameraPos.Y - CharacterPos.Y (used to get 45 degrees ?)
        Fall {
            
            W =  ( (cameraCFrame * CFrame.new(0, -1000, -1000)).Position - CharacterPos ).Unit  
            A =  (CharacterPos + (cameraCFrame.RightVector * -1000) +  vector3.new(0, -1000, 0)).Unit
            S =  ((cameraCFrame.Positon - vector3.new(0, -2*CamCharacterDiffInYAxis, 0)) - CharacterPos).Unit
            D =  (CharacterPos + (cameraCFrame.RightVector * 1000) +  vector3.new(0, -1000, 0)).Unit
            WA = ( ( (W + (CharacterPos + (A * -1000)))/ 2) - CharacterPos ).Unit
        }
    }
    function (HumanoidState: String, Key: string, ...: CFrame | Vector3, )
        return InputDirections[Key](...)         
    end

    return Movement_Util
]]
