--!native
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local Shared = ReplicatedStorage.Shared
local RayMovement = require(Shared.RayMovement)
local HitBox = require(Shared.Hitbox)
local Server_Script = game:GetService("ServerScriptService").Server.ServerActor.Server_Script
local MessageAPI = require(Server_Script.MessageAPI)
-- //local RunService = game:GetService("RunService")
local CharacterActor = script.Parent.Parent
local Actor = script.Parent

--// local Down: RBXScriptConnection
--// local Character: Model
-- local SetCF = function(NewCF: CFrame) PreviousCF = NewCF end
-- local GetCF = function() return PreviousCF end
local Connections  = {} --* only to prevent potential memory leak when this scripts gets destroyed
Actor:BindToMessageParallel("Init", function(UID, Data)  
    local CFV:CFrameValue = unpack(CollectionService:GetTagged(UID.."CFV"))  
    local BodyCFPart:Part = unpack(CollectionService:GetTagged(UID.."Body"))
    if not CFV then warn("no CFV detected: ", UID); return end
    if not BodyCFPart then warn("no BODY_CF_PART  detected: ", UID); return end
    
    local WalkSpeed: number = 16
    local Hip = 5
    local PreviousCF: CFrame = CFV.Value
    local LockMovement = false
    
    local function Knockback(Direction:Vector3, Amount:number, MidPointHeight:number , Distance:number)
        local CurrentCF = CFV.Value
        local Start = CurrentCF.Position 
        local End  = Start + (Direction *Distance) 
        local P1 = Start:Lerp(End, 0.5) + Vector3.new(0, MidPointHeight, 0) --* P1 is the midpoint
        local CurvePoints = RayMovement.CurveCalculate(Start, End, Amount, P1)
        local Conn: RBXScriptConnection , D, S = nil, 0, 0.1
        local NextPoint = 0
        local sy = task.synchronize
        local function Stop()
            sy()
            if Conn then Conn:Disconnect();  end
            Actor:SendMessage("StartDownward")
            CharacterActor:SendMessage("ReleaseJump")
        end
        local Origin = Start
        local ForwardRay = HitBox:Raycasting(Origin, Origin + Direction*4, 2)
        local AxisRay = HitBox:Raycasting(Origin, Origin + Vector3.new(0, 10, 0), 4)
        if ForwardRay or AxisRay then Stop(); return end
        sy()
        Conn = RunService.Heartbeat:Connect(function(a0: number)  
            local NewDelta = D
            NewDelta +=  a0
            NextPoint += 1
            if NewDelta >= S then
                NewDelta = 0
                if NextPoint >= #CurvePoints then  Stop(); return  end
                local Origin = CurrentCF.Position
                local End =  CurvePoints[NextPoint] 
                local Dist = (End - Origin).Magnitude
                local ForwardRay = HitBox:Raycasting(Origin, End, Dist)
                -- local DownRay = HitBox:Raycasting(Origin, Origin + Vector3.new(0, -1, 0), 4)
                local UpRay = HitBox:Raycasting(Origin, End + Vector3.new(0, 1, 0), 4)
                if ForwardRay or UpRay then Stop(); return  end
                --// if NextPoint >= Amount/2 then  Sign = 1 end
                local CFLook = CFrame.lookAlong(End, CurrentCF.LookVector, CurrentCF.UpVector)
                CurrentCF = CFLook
                PreviousCF = CFLook
                task.synchronize()
                CFV.Value = CFLook
                BodyCFPart.CFrame = CFLook
            end
            D = NewDelta
        end)
    end
    local Set:any= Actor:BindToMessageParallel("SetPCF", function(NewCF:CFrame) --* forward Actor      
        PreviousCF = NewCF
    end)
    local Dir:any= Actor:BindToMessageParallel("SetDir", function(Dir:Vector3) --* forward Actor      
        local NewCF = CFrame.lookAlong(CFV.Value.Position, Dir)
        PreviousCF = NewCF
        task.synchronize()
        CFV.Value = NewCF
    end)
    local StartForward:any = Actor:BindToMessageParallel("StartForward", function(CF:CFrame) --* forward Actor      
        if LockMovement then  return end
        if not CF then  return end
        local WS = WalkSpeed
        local PreviousPos:Vector3 = CF.Position
        local NewDir:Vector3 = CF.LookVector 
        local NewPos:Vector3 = PreviousPos + NewDir *(WS *0.08)
        local Origin:Vector3 = PreviousPos
        local End =  Origin + (NewDir * 2)
        
        local DownRR = HitBox:Raycasting(NewPos, NewPos + Vector3.new(0, -1, 0), Hip *4)
        if not DownRR then  return end
        local RR = HitBox:Raycasting(Origin, End, WS*0.24)
        local CFLook = CFrame.lookAlong(NewPos, CF.LookVector, CF.UpVector)
        if RR then 
            local Look = CFrame.lookAlong(RR.Position, CF.LookVector, CF.UpVector) 
            CFLook = Look * CFrame.new(0, 0, 1)
        end
        PreviousCF = CFLook
        task.synchronize()
        CFV.Value = CFLook
        BodyCFPart.CFrame = CFLook
    end)
    local Pushback:any = Actor:BindToMessageParallel("Pushback", function(KB, DirBuffer:buffer, ReverseBool:boolean?) --* forward Actor      
        local Angle = buffer.readi16(DirBuffer, 3)
        Angle += 1e-7 --* prevent nanvalues
        Angle /= 1000
        local Z = math.sin(Angle)
        local X= math.cos(Angle)
        local Direction = Vector3.new(X, 0, Z).Unit --* must be Unit
        local PreviousPos = PreviousCF.Position
        local NewDir:Vector3 = Direction 
        local NewPos:Vector3 = PreviousPos + NewDir *(KB)
        
        local DownRR = HitBox:Raycasting(NewPos, NewPos + Vector3.new(0, -1, 0), Hip *1.2)
        if not DownRR then warn("down not hit"); return end --* let StartDownward handle it
        local WallRR = HitBox:Raycasting(PreviousPos, NewPos, KB *1.024)
        local CFLook = CFrame.lookAlong(NewPos, NewDir)
        if WallRR then 
            CFLook = CFrame.lookAlong(WallRR.Position, NewDir) * CFrame.new(0, 0, 3)     
            if ReverseBool then 
                CFLook = CFrame.lookAlong(WallRR.Position, -NewDir) * CFrame.new(0, 0, 1)                     
            end
        end
        if ReverseBool then 
            CFLook = CFrame.lookAlong(NewPos, -NewDir)
        end
        PreviousCF = CFLook
        task.synchronize()
        CFV.Value = CFLook
        BodyCFPart.CFrame = CFLook
    end)    
    -- the CF recieved can be nil?? sometimes when they leave
    local StartDown:any = Actor:BindToMessageParallel("StartDownward", function(CF: CFrame)--* Downwards Actor
        if not CF then CF = CFV.Value end
        local Origin = CF.Position
        local End: Vector3 = Origin + Vector3.new(0, -1, 0)        
        
        local RR: RaycastResult =  HitBox:Raycasting(Origin, End, Hip * 4)
        if RR then
            local RRHitHip = RR.Position.Y + Hip *0.5
            local BodyY = Origin.Y --+ 0.1
            if RRHitHip > BodyY then 
                CharacterActor:SendMessage("LedgeUp", Hip, CF) --move up here 
            end
            return 
        end     
        --*start fall
        CharacterActor:SendMessage("DownNotHit", UID, CF)
    end)
    local StartFall:any = Actor:BindToMessageParallel("StartFall", function(CurrentCFrame:CFrame)  
        CurrentCFrame = CFV.Value
        local d: number, s: number = 0, 0.05
        local Conn:RBXScriptConnection
        local sy: () -> () = task.synchronize
        sy()
        local CurrentPos = CurrentCFrame.Position
        Conn = RunService.Heartbeat:ConnectParallel(function(a0: number) 
            d += a0
            if d >= s then
                d -= s   
                local Origin: Vector3 = CurrentPos
                local End: Vector3 = Origin + Vector3.new(0, -1 , 0)
                local RR: RaycastResult? =  HitBox:Raycasting(Origin, End, 2.75)
                if not RR then   
                    local NewPos =Origin + Vector3.new(0, -1, 0)
                    CurrentPos = NewPos
                    local CFLook =  CFrame.lookAlong(NewPos, CurrentCFrame.LookVector, CurrentCFrame.UpVector)
                    sy()
                    CFV.Value = CFLook
                    BodyCFPart.CFrame = CFLook
                    PreviousCF = CFLook
                    return   
                end
                local Pos = RR.Position 
                CurrentPos = Pos
                local CFLook =  CFrame.lookAlong(Pos, CurrentCFrame.LookVector, CurrentCFrame.UpVector) --* CFrame.new(0, Hip, 0
                CharacterActor:SendMessage("LedgeUp", Hip, CFLook) --* to message Forward Actor 
                PreviousCF = CFLook
                sy()
                Conn:Disconnect()    
            end     
        end)    
    end)
    local JumpWithMovement:any = Actor:BindToMessageParallel("JumpWithMovement", function(Direction: Vector3) -- for other characters 
        if LockMovement then return end
        local Amount = 30
        Knockback(Direction, Amount, Amount, 15)
    end)    
    local KBConn = Actor:BindToMessageParallel("Knockback", function(KB:number, DirBuffer:buffer)  
        local Angle = buffer.readi16(DirBuffer, 3)
        Angle += 1e-7 --* prevent nanvalues
        Angle /= 1000
        local X= math.cos(Angle)
        local Z = math.sin(Angle)
        local Direction = Vector3.new(X, 0, Z).Unit --* must be Unit
        Knockback(Direction, math.random(30, 45), math.random(35, 65), math.random(KB*6, KB*10)) --* the 3 is to amplify a bit
    end)
    local Jump:any = Actor:BindToMessageParallel("Jump", function() --* forward Actor
        if LockMovement then return end
        local CurrentCF = CFV.Value
        local Start: Vector3 = CurrentCF.Position
        local End: Vector3  = Start + Vector3.new(0, 22, 0) 
        local Amount: number = 20
        local P1: Vector3 = Start:Lerp(End, 0.5) 
        local CurvePoints: {Vector3} = RayMovement.CurveCalculate(Start, End, Amount, P1)
        local Conn: RBXScriptConnection , d: number, s: number = nil, 0, 0.1
        local NextPoint: number = 0
        local sy: () -> () = task.synchronize
        local function Stop()
            sy()
            Conn:Disconnect(); 
            CharacterActor:SendMessage("DownNotHit", UID, CurrentCF)
        end
        sy()
        Conn = RunService.Heartbeat:Connect(function(a0: number)  
            local NewDelta = d
            NewDelta +=  a0
            NextPoint += 1
            if NewDelta >= s then
                NewDelta = 0
                if NextPoint >= #CurvePoints then  Stop(); return  end
                local Origin = CurrentCF.Position
                local AxisRay = HitBox:Raycasting(Origin, Origin + Vector3.new(0, 1, 0), 4)
                if AxisRay then Stop(); return  end
                local NewPos: Vector3 = CurvePoints[NextPoint]
                local CFLook: CFrame = CFrame.lookAlong(NewPos, CurrentCF.LookVector, CurrentCF.UpVector)
                CurrentCF = CFLook
                PreviousCF= CFLook
                task.synchronize()
                CFV.Value = CFLook
                BodyCFPart.CFrame = CFLook
            end
            d = NewDelta
        end)
    end)
    local LM:any = Actor:BindToMessageParallel("LockMove", function(Bool:boolean?) --* forward Actor
        LockMovement = Bool
    end)
    local NPCSF = Actor:BindToMessageParallel("NPCStartForward", function(TargetPos:Vector3, WalkSpeed:number, Range:number)  
        if LockMovement then return end
        local WS = WalkSpeed
        local PreviousPos:Vector3 = CFV.Value.Position
        local DistanceCheck = (TargetPos - PreviousPos).Magnitude
        if DistanceCheck < Range then  return end --* already in range
        
        local NewDir:Vector3 = (TargetPos - PreviousPos).Unit   
        local NewPos:Vector3 = PreviousPos + NewDir *(WS *0.165) --* 0.165 cos the tick is 0.166 seconds
        local Origin:Vector3 = PreviousPos 
        local End = NewPos --// Origin + (NewDir *2)
        local Distance = WS*0.2 --* slightly more than 0.166 for guarantee

        local DownRR = HitBox:Raycasting(NewPos, NewPos + Vector3.new(0, -1, 0), Hip *1.25)
        if not DownRR then return end --* Whenever Calling this Func call StartDownwards with it
        local HitAnotherBodyRR  = HitBox:ServerCameraRaycast(Origin, End, Distance)
        local FacingDirection = (TargetPos - NewPos).Unit
        local CFLook = CFrame.lookAlong(NewPos, FacingDirection)
        if HitAnotherBodyRR then --* hit another Character or the Map 
            local Look = CFrame.lookAlong(HitAnotherBodyRR.Position, FacingDirection) 
            CFLook = Look * CFrame.new(0, 0, WS*0.165) 
        end
        PreviousCF = CFLook
        task.synchronize()
        CFV.Value = CFLook
        BodyCFPart.CFrame = CFLook
    end)
    table.insert(Connections, NPCSF)
    table.insert(Connections, Set)
    table.insert(Connections, StartDown)
    table.insert(Connections, StartFall)
    table.insert(Connections, StartForward)
    table.insert(Connections, Jump)
    table.insert(Connections, JumpWithMovement)
    table.insert(Connections, LM)
    table.insert(Connections, KBConn)
    table.insert(Connections, Dir)
    table.insert(Connections, Pushback)
    
end)

-- Actor:BindToMessageParallel("StopForward", function()
-- end)
-- Actor:BindToMessageParallel("StopDownward", function()   if Down then Down:Disconnect() end end)




