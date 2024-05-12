--!native
local TweenService = game:GetService("TweenService")
local Shared = script.Parent.Parent
-- local CustomTask = require(script.Parent.Parent.CustomTask)
local HitBox = require(Shared.Hitbox) 

local SharedTypes  = require(Shared.SharedType) 
local WorkSpace: SharedTypes.workspace = workspace
type CustomHumanoid = SharedTypes.CustomHumanoid
type Machine = SharedTypes.Machine
type count = { 
    Count: number, 
    Points: {Origin: Vector3, End: Vector3, CurrentPosition: Vector3},
    TweenPoints: {Vector3}
}
local RayMovement = {}
function RayMovement:RayWalk(Character, Direction: Vector3, CustomHumanoid: CustomHumanoid, HumanoidMachine: Machine) task.desynchronize()
    local Hip: number = Character:GetAttribute("Hip")
    local Body: BasePart = Character.PrimaryPart
    local WalkSpeed = Character:GetAttribute("WalkSpeed") or 14
    local Humanoid: CustomHumanoid = HumanoidMachine[Character.Name]
    local RelativeDirCF = CFrame.new(Direction.X * WalkSpeed/2, 0, Direction.Z *WalkSpeed/2)
    local CharacterCF = Body.CFrame
    local CharacterPos = Body.Position
    local TI = TweenInfo.new(0.53, Enum.EasingStyle.Linear, Enum.EasingDirection.In, 0,false)
    local NewDirCF  =  CharacterCF * CFrame.Angles(0, -math.rad(Body.Orientation.Y), 0) * RelativeDirCF
    
    local FirstRayEndPoint = NewDirCF --* CFrame.new(0, 1.5, 0) -- hit a wall
    local SecondRayStartPoint: CFrame
    local SecondRayEndPoint: CFrame 
    local SecondRay: RaycastResult?

    local FirstRay = HitBox:Raycasting(CharacterPos, FirstRayEndPoint.Position, WalkSpeed/2, {WorkSpace.Map})
    if FirstRay then
        SecondRayStartPoint = CFrame.new(FirstRay.Position) 
        SecondRayEndPoint = SecondRayStartPoint * CFrame.new(0, -5, 0)     
        --Finding ground after hitting wall 
        SecondRay = HitBox:Raycasting(SecondRayStartPoint.Position, SecondRayEndPoint.Position, WalkSpeed/2, {WorkSpace.Map})
        if SecondRay then
            SecondRayEndPoint = CFrame.new(SecondRay.Position)  * CFrame.new(0, Hip, 0) -- TODO put in humanoid heights
            local DirCF = CFrame.lookAt(CharacterCF.Position,  NewDirCF.Position) 
            local DIRLook = DirCF * CFrame.new(0,0, -2_000_000_000)
            local FinalCF =  CFrame.lookAt(SecondRayEndPoint.Position, DIRLook.Position)   * CFrame.new(0, 0, 1)
            CustomHumanoid.MoveTracker = Tween(Body, TI,  {CFrame = FinalCF})    
            return SecondRayEndPoint.Position
        end
    end
    SecondRayStartPoint = CFrame.new(FirstRayEndPoint.Position)
    SecondRayEndPoint = SecondRayStartPoint * CFrame.new(0, -1, 0)
    -- ground
    SecondRay = HitBox:Raycasting(SecondRayStartPoint.Position, SecondRayEndPoint.Position, WalkSpeed/1.75, {WorkSpace.Map})
    if SecondRay then
        --falling from cliff 
        SecondRayEndPoint = CFrame.new(SecondRay.Position)  * CFrame.new(0, Hip, 0) -- TODO put in humanoid heights
        local DirCF = CFrame.lookAt(CharacterCF.Position,  NewDirCF.Position) 
        local DIRLook = DirCF * CFrame.new(0,0, -2_000_000_000)
        local FinalCF =  CFrame.lookAt(SecondRayEndPoint.Position, DIRLook.Position)   

        if SecondRay.Position.Y < CharacterPos.Y - 4 then
            HumanoidMachine.TriggerAction(Character, nil, "Fall")
            local P1 = Vector3.new(SecondRay.Position.X, 1.7 *CharacterPos.Y, SecondRay.Position.Z) 
            local Points = CalculateCurvePoints(CharacterPos, SecondRay.Position, NewDirCF, 3, P1)
            SecondRayEndPoint = CFrame.new(SecondRay.Position + Vector3.new(0, Hip, 0))   -- TODO put in humanoid heights
            Points[3] = SecondRayEndPoint.Position
            local CountTable: count = { TweenPoints = Points , Count = 1, Points = { ["CurrentPosition"] = CharacterPos,  ["Origin"] = CharacterPos, ["End"]=SecondRay.Position}  }
            local AccelTable = {[1] = 75, [2]= 75, [3] = 105}
            FinalCF =  CFrame.lookAt(CharacterPos, DIRLook.Position)   
            Humanoid.Falltracker = RecursiveTween(Body, Character, CountTable, AccelTable, HumanoidMachine, NewDirCF)
            task.synchronize()
            Body.CFrame = FinalCF
            Humanoid.Fall:Play(0.5)
            return SecondRayEndPoint.Position
        end
        CustomHumanoid.MoveTracker = Tween(Body, TI, {CFrame = FinalCF})
        return SecondRayEndPoint.Position
    end
    SecondRay = HitBox:Raycasting(SecondRayStartPoint.Position, SecondRayEndPoint.Position, 300, {WorkSpace.Map})
    if not SecondRay then  return SecondRayEndPoint.Position end
    HumanoidMachine.TriggerAction(Character, nil, "Fall")
    local P1 = Vector3.new(SecondRay.Position.X, 1.7 *CharacterPos.Y, SecondRay.Position.Z) 
    local Points = CalculateCurvePoints(CharacterPos, SecondRay.Position, NewDirCF, 3, P1)
    SecondRayEndPoint = CFrame.new(SecondRay.Position + Vector3.new(0, Hip, 0)) 
    Points[3] = SecondRayEndPoint.Position
    local CountTable: count = { TweenPoints = Points , Count = 1, Points = { ["CurrentPosition"] = CharacterPos,  ["Origin"] = CharacterPos, ["End"]=SecondRay.Position}  }
    local AccelTable = {[1] = 75, [2]= 75, [3] = 105}
    Humanoid.Falltracker = RecursiveTween(Body, Character, CountTable, AccelTable, HumanoidMachine, NewDirCF)
    task.synchronize()
    Humanoid.Fall:Play(0.5)
    return SecondRayEndPoint.Position
end
function RayMovement:Jump(Character, Direction: Vector3, HumanoidMachine)
    local Body = Character.PrimaryPart
    local Humanoid: SharedTypes.CustomHumanoid = HumanoidMachine[Character.Name]
    HumanoidMachine.TriggerAction(Character, nil, "Fall")
    if Direction then JumpWithMovement(Character, Direction, HumanoidMachine);  return end
    local Hip: number = Character:GetAttribute("Hip")

    local Origin, Distance, Ceiling 
    Origin = Body.Position
    Distance = 15
    local CeilingRay = CeilingRayfunc(Origin, Distance)
    Ceiling =  Origin + Vector3.new(0, Distance, 0)
    if CeilingRay then Ceiling = CeilingRay.Position; end

    Distance = (Body.Position - Ceiling).Magnitude   
    local JumpTime = GiveTimeFromMotion(25, Distance) 
    local JumpTI = TweenInfo.new(JumpTime, Enum.EasingStyle.Circular, Enum.EasingDirection.Out, 0, false, 0)
    task.synchronize()
    local JumpTrack: AnimationTrack = Humanoid.Jump
    -- if not JumpTrack then  CustomTask.DelayParallel(JumpTime, HumanoidMachine.TriggerAction , Character, nil, "ReleaseFall"); return  end
    
    local FallTrack: AnimationTrack = Humanoid.Fall
    local JumpTween =  Tween(Body, JumpTI, { Position = Ceiling })
    local FallTween = FallTweenFunc(Body, Origin, nil, nil, Hip)
    JumpTrack:Play()
    FallTrack:Play()
    local Conn: RBXScriptConnection
    Conn =  JumpTween.Completed:Connect(function(playbackState: Enum.PlaybackState) 
        Conn:Disconnect()
        FallTween:Play()
        Conn = FallTween.Completed:Connect(function()
            Conn:Disconnect()
            Humanoid.Landed:Play()
            FallTrack:Stop()
            HumanoidMachine.TriggerAction(Character, nil, "ReleaseFall")
        end)
    end)
end
function RayMovement:CheckFalling(Character: Model, HumanoidMachine: Machine, Humanoid: CustomHumanoid, EndPos: Vector3?)
    local Body = Character.PrimaryPart
    local Pos = EndPos or Body.Position
    local FinalPos: Vector3
    local groundRay = GroundFunc(Pos, 5, {WorkSpace.Map})
    local Falltracker = Humanoid.Falltracker 
    local Hip: number = Character:GetAttribute("Hip")    
    if groundRay then 
        FinalPos = groundRay.Position + Vector3.new(0, Hip, 0)
        task.synchronize()
        Body.Position = FinalPos
        if Falltracker then 
            Falltracker:Pause(); Falltracker:Destroy(); Humanoid.Falltracker = nil
            Humanoid.Fall:Stop()        
            HumanoidMachine.TriggerAction(Character, nil, "ReleaseFall")
        end
        return FinalPos        
    end
    local groundRay2 = GroundFunc(Body.Position, 7, {WorkSpace.Map})
    if not groundRay2 then return FinalPos end
    -- not falling so just tp to place
    FinalPos = groundRay2.Position + Vector3.new(0, Hip, 0) 
    task.synchronize()
    Body.Position = FinalPos
    return FinalPos
end

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

function JumpWithMovement(Character, Direction: Vector3, HumanoidMachine: Machine)
    local Body: BasePart = Character.PrimaryPart
    local Humanoid: CustomHumanoid = HumanoidMachine[Character.Name]
    local Hip: number = Character:GetAttribute("Hip")
    local CharacterCF = Body.CFrame
    local Origin, End, P1
    local Distance, Filter = 15, {WorkSpace.Map}
    local RelativeDirCF = CFrame.new(Direction.X *Distance, 0, Direction.Z *Distance)
    local WallDirCF: CFrame  =  CharacterCF *CFrame.Angles(0, -math.rad(Body.Orientation.Y), 0) *RelativeDirCF
    Origin = Body.Position
    End = WallDirCF.Position
    P1 = Origin:Lerp(End, 0.75)+ Vector3.new(0, 20, 0)
    local Points: {Vector3} =  CalculateCurvePoints(Origin, End, WallDirCF, 8, P1)
    local GroundRay, Ground: Vector3 = GroundFunc(Origin, Distance, Filter), End    
    if GroundRay then Ground = GroundRay.Position + Vector3.new(0, Hip, 0) end
    local CountTable: count = { TweenPoints = Points , Count = 1, Points = { ["CurrentPosition"] = Origin,  ["Origin"] = Origin, ["End"] = Ground}  }
    local FirstTI, JumpTrack: AnimationTrack
    JumpTrack = Humanoid.Jump
    local JumpTime = GiveTimeFromMotion(400, Distance)
    -- if not JumpTrack then   return  end -- cannot do this TODO
    
    Distance = (Points[1] - Origin).Magnitude
    FirstTI = TweenInfo.new(JumpTime, Enum.EasingStyle.Circular, Enum.EasingDirection.Out)
    Tween(Body, FirstTI, {  Position  = Points[1] }) --  first tween
    JumpTrack:Play()
    Humanoid.Fall:Play()
    local AccelTable = { [4] =  225, [5] = 150, [6] = 225, }
    RecursiveTween(Body, Character,CountTable, AccelTable, HumanoidMachine, WallDirCF)
end
function Tween(Instance: Instance, TI: TweenInfo, Property: {[any]: any}) task.synchronize()
    local Tweeny  = TweenService:Create(Instance, TI, Property)
    Tweeny:Play()
    return Tweeny
end
function FinishFall(Body, Character: Model,Point: Vector3, HumanoidMachine: Machine)
    local Humanoid: CustomHumanoid =  HumanoidMachine[Character.Name] 
    local FallTrack: AnimationTrack = Humanoid.Fall
    local Hip: number = Character:GetAttribute("Hip")
    local FallTween = FallTweenFunc(Body, Point, Enum.EasingStyle.Linear, 300, Hip)
    FallTrack:Stop()
    FallTween:Play()
    local Conn; Conn = FallTween.Completed:Connect(function() 
        Humanoid.Landed:Play()
        Conn:Disconnect(); HumanoidMachine.TriggerAction(Character, nil, "ReleaseFall"); Humanoid.Falltracker = nil
    end)
end
function RecursiveTween(Body, Character,CountTable: count, AccelTable: {unknown}?, HumanoidMachine: Machine, WallDirCF)
    CountTable.Count += 1
    local Count = CountTable.Count
    local AccelT = AccelTable or {}; local Acceleration =  AccelT[Count] or 300
    local PreviousPos =  CountTable.Points.CurrentPosition
    if CountTable.Count > #CountTable.TweenPoints then  FinishFall(Body, Character,PreviousPos, HumanoidMachine); return end 
    local Hip: number = Character:GetAttribute("Hip")
    local NextPos = CountTable.TweenPoints[Count] 
    CountTable.Points.CurrentPosition = NextPos
    local Distance = (PreviousPos - NextPos).Magnitude
    local Time = GiveTimeFromMotion(Acceleration, Distance)
    local TI = TweenInfo.new( Time, Enum.EasingStyle.Linear)
    local Stop: boolean
    local WallRay = WallRayFind(PreviousPos, WallDirCF, 5, {WorkSpace.Map}) 
    if WallRay then 
        local WallLook = CFrame.lookAt(Body.Position, WallDirCF.Position); 
        local PosCF = CFrame.lookAt(WallRay.Position, WallLook.Position) * CFrame.new(0, 0, -1)
        NextPos = PosCF.Position + Vector3.new(0,  Hip, 0)
        Stop = true
    end 
    local CeilingRay = CeilingRayfunc(PreviousPos, 5) -- body height size
    if CeilingRay then  NextPos = CeilingRay.Position + Vector3.new(0, -3, 0); Stop = true end
    local NextPointTween = Tween(Body, TI, { Position = NextPos })
    if Stop then NextPointTween.Completed:Connect(function() FinishFall(Body, Character,PreviousPos, HumanoidMachine) end); return end
    NextPointTween.Completed:Connect(function() RecursiveTween(Body, Character,CountTable, AccelTable, HumanoidMachine, WallDirCF) end)  
    return NextPointTween
end
function GiveTimeFromMotion(Acceleration:    number, Distance: number) return math.sqrt((2*Distance)/ Acceleration) end
function CeilingRayfunc(Origin: Vector3, Distance)
    local End = Origin + Vector3.new(0, Distance, 0)
    return  HitBox:Raycasting(Origin, End, Distance, {WorkSpace.Map})
end
function WallRayFind(Origin, DirectionCF, Distance, Filter)
    -- Finding Wall so does not go past it 
    local End = DirectionCF.Position
    local WallRay = HitBox:Raycasting(Origin, End, Distance, Filter)
    return WallRay
end
function GroundFunc(Origin: Vector3, Distance, Filter)
    local End = Origin + Vector3.new(0, -1, 0)
    return HitBox:Raycasting(Origin, End, Distance, Filter)
end
function QuadBez(t: number, P0: Vector3, P1: Vector3, P2: Vector3)   return (1 - t)^2 * P0 + 2 * (1 - t) * t * P1 + t^2 * P2 end
function CalculateCurvePoints(Start: Vector3, End: Vector3, DirectionCF: CFrame, Amount: number, P1: Vector3)
    local P0, P2
    P0 = Start; P2 = End
    local ReturnPoints = {}
    for i = 1, Amount  do 
        local TP = QuadBez(i/Amount, P0, P1, P2)
        table.insert(ReturnPoints, TP)
    end     
    return ReturnPoints
end
function FallTweenFunc(Body: BasePart, Origin: Vector3, EnumType: Enum.EasingStyle?, Acceleration: number?, Hip: number)
    local Ground = GroundFunc(Origin, 300, {WorkSpace.Map})
    if not Ground then Ground = {Position = Origin} end
    local EnumUse = EnumType or Enum.EasingStyle.Circular
    local Accel = Acceleration or 30
    local Distance = (Origin - Ground.Position).Magnitude
    local TI = TweenInfo.new(GiveTimeFromMotion(Accel, Distance), EnumUse, Enum.EasingDirection.In)
    task.synchronize()
    local FallTween = TweenService:Create(Body, TI, {
        Position = Ground.Position + Vector3.new(0, Hip, 0)
    })
    return FallTween :: Tween
end
--[[ how to do relative direction from a Cframe whilst keeping the Same relative y axis
local Direction = (Body2.Position - CharacterPart.Position).Unit-- what we recieve
local DirCF =  CFrame.new(Direction.X * 5, 0, Direction.Z * 5)
local CharacterCF = CharacterPart.CFrame
Part.CFrame = CharacterCF * CFrame.Angles(0,-math.rad(CharacterPart.Orientation.Y), 0) * DirCF
]]
return RayMovement