local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Shared = ReplicatedStorage.Shared
local HitBox = require(Shared.Hitbox) 
local SharedTypes  = require(Shared.SharedType) 
type CustomHumanoid = SharedTypes.CustomHumanoid
type Machine = SharedTypes.Machine

local ServerRayMovement = {}
local DirectionCurve = {}
function Startcurve(Points: {Vector3}, WalkSpeed: number, UID)
    DirectionCurve = Points
    local Conn: RBXScriptConnection
    local TotDelta, Step = 0, 0.06 
    local Caller = ServerRayMovement["Caller"]
    local PreviousPoint = Points[1]; table.remove(Points, 1)
    Conn = RunService.Heartbeat:Connect(function(a0: number)  
        TotDelta += a0
        if TotDelta >=  Step then
            if #DirectionCurve <= 0 then Conn:Disconnect(); return end
            TotDelta -= Step
            local VelocityDir = (Points[1] - PreviousPoint).Unit
            local TravelTick = VelocityDir * (WalkSpeed/15)-- 15p/s is the tick
            table.remove(DirectionCurve, 1)
            Caller(UID, "CurrentDirection", TravelTick)
        end
    end)
end

function ServerRayMovement:RayWalk(Data, Direction: Vector3, CustomHumanoid: CustomHumanoid, HumanoidMachine: Machine) task.desynchronize()
    local UID = Data.UID
    local WalkSpeed = Data.WalkSpeed or 14
    -- local Humanoid: CustomHumanoid = HumanoidMachine[UID]
    local CharacterPos = Data.Pos
    local NewDirCF  =  Direction
    local Caller = ServerRayMovement["Caller"]
            
    local FirstRayEndPoint = NewDirCF --* CFrame.new(0, 1.5, 0) -- hit a wall
    local SecondRayStartPoint: CFrame
    local SecondRayEndPoint: CFrame 
    local SecondRay: RaycastResult?

    local FirstRay = HitBox:Raycasting(CharacterPos, FirstRayEndPoint.Position, WalkSpeed/2)
    if FirstRay then
        SecondRayStartPoint = CFrame.new(FirstRay.Position) 
        SecondRayEndPoint = SecondRayStartPoint * CFrame.new(0, -5, 0)     
        --Finding ground after hitting wall 
        SecondRay = HitBox:Raycasting(SecondRayStartPoint.Position, SecondRayEndPoint.Position, WalkSpeed/2)
        if SecondRay then
            local VelocityDir = (SecondRayEndPoint.Position - CharacterPos).Unit
            -- local TravelTick = VelocityDir 
            Caller(UID, "CurrentDirection", VelocityDir)
            return 
        end
    end
    SecondRayStartPoint = CFrame.new(FirstRayEndPoint.Position)
    SecondRayEndPoint = SecondRayStartPoint * CFrame.new(0, -1, 0)
    -- ground
    SecondRay = HitBox:Raycasting(SecondRayStartPoint.Position, SecondRayEndPoint.Position, WalkSpeed/1.75)
    if SecondRay then
        --falling from cliff 
        local VelocityDir = (SecondRayEndPoint.Position - CharacterPos).Unit
        -- local TravelTick = VelocityDir * (WalkSpeed/15)-- 15p/s is the tick
        Caller(UID, "CurrentDirection", VelocityDir)
        return 
    end
    SecondRay= HitBox:Raycasting(SecondRayStartPoint.Position, SecondRayEndPoint.Position, 300)
    if not SecondRay then  return SecondRayEndPoint.Position end
    local SecondRayPos: Vector3 = SecondRay.Position
    local P1 = Vector3.new(SecondRayPos.X, 1.7 *CharacterPos.Y, SecondRayPos.Z) 
    local Amount = CalculateAmount(CharacterPos, SecondRayPos)
    local Points = CalculateCurvePoints(CharacterPos, SecondRayPos,  Amount, P1)
    Startcurve(Points, WalkSpeed, UID)
    return 
end
function QuadBez(t: number, P0: Vector3, P1: Vector3, P2: Vector3)   return (1 - t)^2 * P0 + 2 * (1 - t) * t * P1 + t^2 * P2 end
function CalculateCurvePoints(Start: Vector3, End: Vector3, Amount: number, P1: Vector3)
    local P0, P2
    P0 = Start; P2 = End
    local ReturnPoints = {}
    for i = 1, Amount  do 
        local TP = QuadBez(i/Amount, P0, P1, P2)
        table.insert(ReturnPoints, TP)
    end     
    return ReturnPoints
end
function CalculateAmount(Origin: Vector3, EndPos: Vector3)
    local Distance = (EndPos - Origin).Magnitude
    return Distance * 15 -- 15 ticks
end



return ServerRayMovement