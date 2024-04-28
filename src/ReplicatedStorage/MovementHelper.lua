--!native
local Camera = workspace.CurrentCamera 
local Movement_Helper = {}
--[[
function Visualise(Pos: Vector3)
    local Part = Instance.new("Part")
    task.synchronize()
    Part.Name = "Visualise"
    Part.Anchored = true
    Part.Size = Vector3.one
    Part.Position = Pos
    Part.Parent = workspace
end
]]
Movement_Helper["Walk"] = {
    W = function(Character): Vector3
        local CameraCFrame = Camera.CFrame
        return CameraCFrame.LookVector  :: Vector3 
    end,
    S = function(Character): Vector3
        local CameraCFrame = Camera.CFrame
        return  -CameraCFrame.LookVector 
    end, 
    A =  function(Character): Vector3
        local CameraCFrame = Camera.CFrame
        return  -CameraCFrame.RightVector 
    end,
    D = function(Character): Vector3
        local CameraCFrame = Camera.CFrame
        return  CameraCFrame.RightVector 
    end,     
    WA = function(Character)
        local CharacterPos = Character.PrimaryPart.CFrame.Position
        local W, A = Movement_Helper.Walk.W(Character),  Movement_Helper.Walk.A(Character) 
        local Wpos, Dpos = CharacterPos + W*5 , CharacterPos + A*5
        local Midpoint: Vector3 = (Wpos + Dpos)/2
        return (Midpoint - CharacterPos).Unit   
    end,
    WD = function(Character)
        local CharacterPos: Vector3 = Character.PrimaryPart.CFrame.Position
        local W, D = Movement_Helper.Walk.W(Character), Movement_Helper.Walk.D(Character) 
        local Wpos, Dpos = CharacterPos + W*5 , CharacterPos + D*5
        local Midpoint: Vector3 = (Wpos + Dpos)/2
        return (Midpoint - CharacterPos).Unit   
    end,
    SA = function(Character)
        local CharacterPos = Character.PrimaryPart.CFrame.Position
        local S, A = Movement_Helper.Walk.S(Character),  Movement_Helper.Walk.A(Character) 
        local Wpos, Dpos = CharacterPos + S*5 , CharacterPos + A*5
        local Midpoint: Vector3 = (Wpos + Dpos)/2
        return (Midpoint - CharacterPos).Unit   
    end,
    SD = function(Character)
        local CharacterPos = Character.PrimaryPart.CFrame.Position
        local S, D = Movement_Helper.Walk.S(Character),  Movement_Helper.Walk.D(Character) 
        local Wpos, Dpos = CharacterPos + S*5 , CharacterPos + D*5
        local Midpoint: Vector3 = (Wpos + Dpos)/2
        return (Midpoint - CharacterPos).Unit   
    end,
}

Movement_Helper.Walk["DS"] = Movement_Helper.Walk.SD 
Movement_Helper.Walk["DW"] = Movement_Helper.Walk.WD
Movement_Helper.Walk["AS"] = Movement_Helper.Walk.SA 
Movement_Helper.Walk["AW"] = Movement_Helper.Walk.WA 
Movement_Helper.Jump = Movement_Helper.Walk
function Movement_Helper:Move(Character, HumanoidState, Key) return Movement_Helper[HumanoidState][Key](Character) end
function Movement_Helper:GiveDirection(Character, Key) return Movement_Helper["Walk"][Key](Character) end

return Movement_Helper
--[[ info
This module Manages the Calculation of the direction of movement    
Mainly for clients only
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
            W = ((CameraCFrame * CFrame.new(0, 1, -1000)).Position - CharacterPos).Unit 
            S = (CameraCFrame.Positon - CharacterPos).Unit
            A = -CameraCFrame.RightVector  -- for moving CharacterPos + (CameraCFrame.RightVector * -1000)
            D = CameraCFrame.RightVector  -- for moving CharacterPos + CameraCFrame.RightVector * 1000)
            WA = (( (W + (CharacterPos + (A * 1000) ) ) / 2) - CharacterPos).Unit  
            WD = (( (W + (CharacterPos + (D * 1000) ) ) / 2) - CharacterPos).Unit  
            
            SA = (( (S + (CharacterPos + (A * 1000) ) ) / 2) - CharacterPos).Unit  
            SD = (( (S + (CharacterPos + (D * 1000) ) ) / 2) - CharacterPos).Unit  
        }
        CamCharacterDiffInYAxis = CameraPos.Y - CharacterPos.Y (used to get 45 degrees ?)
        Fall {
            
            W =  ( (CameraCFrame * CFrame.new(0, -1000, -1000)).Position - CharacterPos ).Unit  
            A =  (CharacterPos + (CameraCFrame.RightVector * -1000) +  vector3.new(0, -1000, 0)).Unit
            S =  ((CameraCFrame.Positon - vector3.new(0, -2*CamCharacterDiffInYAxis, 0)) - CharacterPos).Unit
            D =  (CharacterPos + (CameraCFrame.RightVector * 1000) +  vector3.new(0, -1000, 0)).Unit
            WA = ( ( (W + (CharacterPos + (A * -1000)))/ 2) - CharacterPos ).Unit
        }
    }
    function (HumanoidState: String, Key: string, ...: CFrame | Vector3, )
        return InputDirections[Key](...)         
    end

    return Movement_Util
]]

