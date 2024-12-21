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

--[[ New Calculation

	--TODO_IMPORTANT/////: Notes to avoid character having a chance of being flung into non existence keep CanCollide On for a single part
	local CharacterPos = Prim.Position -- Replace with Character PrimaryPart  
	local CharacterCF = Prim.CFrame -- ↑↑↑same here↑↑↑
	local NRCF = CFrame.new(Vector3.one) -- plain CF no Rotation
	local NoRotateCF = CFrame.lookAt(CharacterPos, CharacterPos +NRCF.LookVector *50, CharacterCF.UpVector)
	
	local CamDirection = Cam.CFrame.LookVector
	local NewCF = NoRotateCF * CFrame.new(CamDirection.X *150, 0, CamDirection.Z  *150)
	local	NewDir = (NewCF.Position - CharacterPos).Unit
	local Look = CharacterPos +NewDir *150 
	local CF = CFrame.lookAt(CharacterPos, Look, CharacterCF.UpVector)
	CamLookModel.PrimaryPart.CFrame = CF
]]
    
local ProjectionVector = function(D:Vector3, N:Vector3)
    return (D - (D:Dot(N) *N)).Unit
end
 
local RelativeDir = function(Character: Model,CamDirection:Vector3)
    --[[
    
    local Prim = Character.PrimaryPart
    local CharacterPos = Prim.Position -- Replace with Character PrimaryPart  
	local CharacterCF = Prim.CFrame -- ↑↑↑same here↑↑↑
	local NRCF = CFrame.new(Vector3.zero) -- plain CF no Rotation
	-- NRCF = CFrame.lookAlong(NRCF.Position, NRCF.LookVector, CharacterCF.UpVector)
    local NoRotateCF = CFrame.lookAlong(CharacterPos, NRCF.LookVector, CharacterCF.UpVector)

	local NewCF = NoRotateCF * CFrame.new(CamDirection.X *150, 0, CamDirection.Z  *150)
	local NewDir = (NewCF.Position - CharacterPos).Unit
	-- local Look = CharacterPos +NewDir *150 
	local CF = CFrame.lookAlong(CharacterPos, NewDir, CharacterCF.UpVector)
	
    ]]
    local MoveBody = Character.PrimaryPart
    local BodyCF = MoveBody.CFrame
    local UpVector = BodyCF.UpVector
    local Projection_Vector = ProjectionVector(CamDirection.Unit, UpVector)
	local CF = CFrame.lookAlong(BodyCF.Position, Projection_Vector.Unit)
    return CF
end

Movement_Helper["Walk"] = {
    [2] = function(Character): Vector3 --* W
        local CameraCFrame = Camera.CFrame
        return CameraCFrame.LookVector  :: Vector3 
    end,
    [4] = function(Character): Vector3 --*A
        local CameraCFrame = Camera.CFrame
        return  -CameraCFrame.RightVector 
    end,
    [8] = function(Character): Vector3 --*S
        local CameraCFrame = Camera.CFrame
        return  -CameraCFrame.LookVector 
    end, 
    [16] = function(Character): Vector3 --*D
        local CameraCFrame = Camera.CFrame
        return  CameraCFrame. RightVector 
    end,     
    [6] = function(Character)
        local CharacterPos = Character.PrimaryPart.CFrame.Position
        local W, A = Movement_Helper.Walk[2](Character),  Movement_Helper.Walk[4](Character) 
        local Wpos, Dpos = CharacterPos + W*5 , CharacterPos + A*5
        local Midpoint: Vector3 = (Wpos + Dpos)/2
        return (Midpoint - CharacterPos).Unit   
    end,
    [12] = function(Character)
        local CharacterPos = Character.PrimaryPart.CFrame.Position
        local S, A = Movement_Helper.Walk[8](Character),  Movement_Helper.Walk[4](Character) 
        local Wpos, Dpos = CharacterPos + S*5 , CharacterPos + A*5
        local Midpoint: Vector3 = (Wpos + Dpos)/2
        return (Midpoint - CharacterPos).Unit   
    end,
    [18] = function(Character)
        local CharacterPos: Vector3 = Character.PrimaryPart.CFrame.Position
        local W, D = Movement_Helper.Walk[2](Character), Movement_Helper.Walk[16](Character) 
        local Wpos, Dpos = CharacterPos + W*5 , CharacterPos + D*5
        local Midpoint: Vector3 = (Wpos + Dpos)/2
        return (Midpoint - CharacterPos).Unit   
    end,
    [24] = function(Character)
        local CharacterPos = Character.PrimaryPart.CFrame.Position
        local S, D = Movement_Helper.Walk[8](Character),  Movement_Helper.Walk[16](Character) 
        local Wpos, Dpos = CharacterPos + S*5 , CharacterPos + D*5
        local Midpoint: Vector3 = (Wpos + Dpos)/2
        return (Midpoint - CharacterPos).Unit   
    end,
}
-- Movement_Helper.Walk["DS"] = Movement_Helper.Walk.SD 
-- Movement_Helper.Walk["DW"] = Movement_Helper.Walk.WD
-- Movement_Helper.Walk["AS"] = Movement_Helper.Walk.SA 
-- Movement_Helper.Walk["AW"] = Movement_Helper.Walk.WA 
Movement_Helper.Jump = Movement_Helper.Walk

function Movement_Helper:Move(Character, HumanoidState, Key) return Movement_Helper[HumanoidState][Key](Character) end
-- function Movement_Helper:GiveDirection(Character, Key) 
--     local Dir = Movement_Helper["Walk"][Key]
--     if not Dir then return end
--     local Direction:Vector3 = Dir(Character)
--     return RelativeDir(Character, Direction) :: CFrame
-- end


function Movement_Helper:GiveDirection(Character, Number) 
    local Dir = Movement_Helper["Walk"][Number]
    if not Dir then return end
    local Direction:Vector3 = Dir(Character)
    return RelativeDir(Character, Direction) :: CFrame
end
--[[ --OLD system

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

]]

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

