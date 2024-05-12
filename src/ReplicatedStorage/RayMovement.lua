--!native
-- local TweenService = game:GetService("TweenService")
local Shared = script.Parent
-- local CustomTask = require(script.Parent.Parent.CustomTask)
-- local HitBox = require(Shared.Hitbox) 
local SharedTypes  = require(Shared.SharedType) 
type CustomHumanoid = SharedTypes.CustomHumanoid
type Machine = SharedTypes.Machine
type count = { 
    Count: number, 
    Points: {Origin: Vector3, End: Vector3, CurrentPosition: Vector3},
    TweenPoints: {Vector3}
}
local RayMovement = {}
local GiveTimeFromMotion = function (Acceleration:    number, Distance: number) 
    return math.sqrt((2*Distance)/ Acceleration) :: number 
end
local QuadBez = function (t: number, P0: Vector3, P1: Vector3, P2: Vector3)
    return (1 - t)^2 * P0 + 2 * (1 - t) * t * P1 + t^2 * P2 :: Vector3  
end
local CalculateCurvePoints = function (Start: Vector3, End: Vector3, Amount: number, P1: Vector3)
    local P0, P2
    P0 = Start; P2 = End
    local ReturnPoints = {}
    for i = 1, Amount  do 
        local TP = QuadBez(i/Amount, P0, P1, P2)
        table.insert(ReturnPoints, TP)
    end     
    return ReturnPoints :: {Vector3}
end
RayMovement["CurveCalculate"] = CalculateCurvePoints
RayMovement["QuadBez"] = QuadBez
RayMovement["TimeFromMotion"] = GiveTimeFromMotion

--[[ how to do relative direction from a Cframe whilst keeping the Same relative y axis
local Direction = (Body2.Position - CharacterPart.Position).Unit-- what we recieve
local DirCF =  CFrame.new(Direction.X * 5, 0, Direction.Z * 5)
local CharacterCF = CharacterPart.CFrame
Part.CFrame = CharacterCF * CFrame.Angles(0,-math.rad(CharacterPart.Orientation.Y), 0) * DirCF
]]
return RayMovement

--[[
function Visualise(Pos: Vector3, Color: string?)
    local Part = Instance.new("Part")
    task.synchronize()
    Part.Name = "Visualise"
    Part.Anchored = true
    Part.Size = Vector3.one
    Part.Position = Pos
    Part.Parent = workspace

    if Color then 
        Part.BrickColor = BrickColor[Color]()
    end
end
function GetTime(Character: Model, Distance: number, WalkSpeed: number)
    local Time: number
    if Distance/ WalkSpeed < 0.3 then  Time = 0.35 end
    Time = Distance/14
    return Time
end

]]
