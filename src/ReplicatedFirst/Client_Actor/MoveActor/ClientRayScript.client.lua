--!native
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
-- local Debris = game:GetService("Debris")

local Shared = ReplicatedStorage.Shared
local HitBox = require(Shared.Hitbox)
-- local ClientMessageAPI = require()
local RunService = game:GetService("RunService")
local Actor = script.Parent
local ClientActor = script.Parent.Parent -- for the downwards actor
local RayMovement = require(Shared.RayMovement)
-- local Forward: RBXScriptConnection
local Character: Model


--[[

local RayForward= function(Pos: Vector3, PreviousPos:Vector3, NewDir: Vector3, WS: number, Body, DeltaMove: number)
    local Origin = Body.Position;
    local End = Origin + (NewDir * 2)
    local RR = HitBox:Raycasting(Origin, End, WS*DeltaMove*3)
    -- local CFLook
    if RR then 
        -- local LookPos = Pos + NewDir*10 
        -- local Look = CFrame.new(RR.Position, LookPos) 
        -- CFLook = Look * CFrame.new(0, 0, 2)
        -- -- ClientMessageAPI.SendToClientActor("ForwardHit", CFLook) 
        -- ClientActor:SendMessage("ForwardHit", CFLook) 
        return RR.Position
    end
    return
end

]]

--[[failed wallrunning --place it into StartForwards
local IsWallRun = Character:GetAttribute("IsWallRun")

if IsWallRun then
--TODO
--! does not work on the Z axis walls  
-- local EndCF = 
-- local EndCF = CFrame.lookAlong(NewPos, CF.LookVector, CF.UpVector) * -CF.UpVector*10
local End = CF.Position + (CF.UpVector *-10)
local RR: RaycastResult =  HitBox:Raycasting(NewPos, End, Hip +0.1)
if not RR then return end
print(RR.Instance)
end

]]

local Connections = {}
Actor:BindToMessageParallel("Init", function(UID: string)  
    Character = CollectionService:GetTagged("Char"..UID)[1]
    local Hip = Character:GetAttribute("Hip")
    local WS = Character:GetAttribute("BaseWalkSpeed")
    local OldWalkSpeed = WS
    local Body = Character.PrimaryPart
    local LockMovement = false
    local SF:any = Actor:BindToMessageParallel("StartForward", function(CF:CFrame) -- client    
        if LockMovement then return end
        local Pos= CF.Position
        local PreviousPos = Body.Position
        local NewPos = Pos + CF.LookVector *WS *0.08
        local sy = task.synchronize
        local RR = HitBox:Raycasting(PreviousPos, PreviousPos + CF.LookVector, WS*0.08)
        local CFLook:CFrame
        CFLook = CFrame.lookAlong(NewPos, CF.LookVector, CF.UpVector)
        if RR then 
            CFLook = CFrame.lookAlong(RR.Position, CF.LookVector, CF.UpVector)* CFrame.new(0, 0, 2)
            sy();
            Body.CFrame = CFLook;
            return 
        end
        sy()
        Body.CFrame = CFLook
    end)
    local PreviousCF: CFrame
    local SFR:any = Actor:BindToMessageParallel("StartForwardRun", function(CF:CFrame) -- for other characters 
        if PreviousCF and (PreviousCF.Position - CF.Position).Magnitude < 0.01 then
            ClientActor:SendMessage("StopWalk", UID)
        end
        task.synchronize()
        Body.CFrame = CF
        PreviousCF = CF
    end)
    local SD:any = Actor:BindToMessageParallel("StartDownward", function(CF: CFrame)
        local Origin: Vector3 = Body.Position
        local EndCF  = Body.CFrame * CFrame.new(0, -1, 0)
        local End: Vector3 = EndCF.Position        
        local RR: RaycastResult =  HitBox:Raycasting(Origin, End, Hip*1.2)
        if RR then
            local RRHitHip = RR.Position.Y + Hip
            local BodyY = Origin.Y + 0.1
            if RRHitHip > BodyY then 
                ClientActor:SendMessage("LedgeUp", UID, RR.Position, Hip, CF) --move up here 
            end
            return 
        end
        --start fall
        ClientActor:SendMessage("DownNoHit", UID)
    end)
    local SFa:any = Actor:BindToMessageParallel("StartFall", function()  
        local d: number, s: number = 0, 0.1
        local Conn:RBXScriptConnection
        local sy: () -> () = task.synchronize
        sy()
        Conn = RunService.Heartbeat:ConnectParallel(function(a0: number) 
            local deltanew = d
            deltanew += a0
            if deltanew >= s then
                local Origin: Vector3 = Body.Position
                local End: Vector3 = Origin + Vector3.new(0, -1 , 0)
                local RR: RaycastResult? =  HitBox:Raycasting(Origin, End, 2.75)
                if not RR then   
                    d = deltanew
                    sy()
                    Body.Position  = Origin + Vector3.new(0, -2, 0)
                    return   
                end
                ClientActor:SendMessage("StopFall", UID)     
                sy()
                Body.Position = RR.Position + Vector3.new(0, Hip, 0)
                Conn:Disconnect()
            end    
            d = deltanew 
        end)    
    end)
    local JWM:any = Actor:BindToMessageParallel("JumpWithMovement", function(RelativeDirCF: CFrame)  
        local Start = Body.Position 
        local Direction = RelativeDirCF.LookVector
        local End  = Start + (Direction *15)
        local Amount = 35
        local P1 = Start:Lerp(End, 0.5) + Vector3.new(0, Amount, 0)
        local CurvePoints = RayMovement.CurveCalculate(Start, End, Amount, P1)
        local Conn: RBXScriptConnection , d, s = nil, 0, 0.1
        local NextPoint = 0
        local sy = task.synchronize
        local function Stop()
            sy()
            if Conn then Conn:Disconnect();  end
            ClientActor:SendMessage("DownNoHit", UID)
        end
        local Origin = Body.Position
        local ForwardRay = HitBox:Raycasting(Origin, Origin + Direction*4, 2)
        local AxisRay = HitBox:Raycasting(Origin, Origin + Vector3.new(0, 10, 0), 4)
        if ForwardRay or AxisRay then Stop(); return end
        sy()
        Conn = RunService.Heartbeat:Connect(function(a0: number)  
            local NewDelta = d
            NewDelta +=  a0
            NextPoint += 1
            if NewDelta >= s then
                NewDelta = 0
                if NextPoint >= #CurvePoints then  Stop(); return  end
                local Origin = Body.Position
                local End =  CurvePoints[NextPoint] 
                local Dist = (End - Origin).Magnitude
                local ForwardRay = HitBox:Raycasting(Origin, End, Dist)
                -- local DownRay = HitBox:Raycasting(Origin, Origin + Vector3.new(0, -1, 0), 4)
                local UpRay = HitBox:Raycasting(Origin, End + Vector3.new(0, 1, 0), 4)

                if ForwardRay or UpRay then Stop(); return  end
                --// if NextPoint >= Amount/2 then  Sign = 1 end
                sy()
                Body.Position = End
            end
            d = NewDelta
        end)
    end)
    local J:any = Actor:BindToMessageParallel("Jump", function()  
        local Start = Body.Position 
        local End  = Start + Vector3.new(0, 22, 0) 
        local Amount = 20
        local P1 = Start:Lerp(End, 0.5) 
        local CurvePoints = RayMovement.CurveCalculate(Start, End, Amount, P1)
        local Conn: RBXScriptConnection , d, s = nil, 0, 0.1
        local NextPoint = 0
        local sy = task.synchronize
        local function Stop()
            sy()
            Conn:Disconnect(); 
            ClientActor:SendMessage("DownNoHit", UID)
        end
        sy()
        Conn = RunService.Heartbeat:Connect(function(a0: number)  
            local NewDelta = d
            NewDelta +=  a0
            NextPoint += 1
            if NewDelta >= s then
                NewDelta = 0
                if NextPoint >= #CurvePoints then  Stop(); return  end
                local Origin = Body.Position
                local AxisRay = HitBox:Raycasting(Origin, Origin + Vector3.new(0, 1, 0), 4)
                if AxisRay then Stop(); return  end
                sy()
                Body.Position = CurvePoints[NextPoint]
            end
            d = NewDelta
        end)
    end) 
    local AWS:any = Actor:BindToMessageParallel("AdjustWS", function(NewWs: number) --* forward Actor
        OldWalkSpeed = WS
        WS = NewWs
    end)
    local OldWS:any = Actor:BindToMessageParallel("OldWS", function() --* forward Actor
        WS = OldWalkSpeed
    end)
    local LM:any = Actor:BindToMessageParallel("LockMove", function(Bool:boolean?) -- for other characters 
        LockMovement = Bool
    end)
    
    table.insert(Connections, SF)
    table.insert(Connections, SFR)
    table.insert(Connections, SD)
    table.insert(Connections, JWM)
    table.insert(Connections, J)
    table.insert(Connections, AWS)
    table.insert(Connections, SFa)
    table.insert(Connections, OldWS)
    table.insert(Connections, LM)

    --[[ semi working attempt at WallRunning
    Actor:BindToMessageParallel("WallRun", function() 
        --//////////////////////////////////////// TODO NEEEDS TESTING ///////////////////////////////////////////////
        local Origin = Body.Position
        local Direction = Body.CFrame.LookVector
        local End = Body.Position + (Direction *1000)
        local Distance = 5
        local RR = HitBox:Raycasting(Origin, End, Distance)
        if not RR then return end 
        local Look = Body.Position + Body.CFrame.UpVector *1000
        local NewCF = CFrame.lookAt(RR.Position, Look, RR.Normal) 
        NewCF = NewCF * CFrame.new(0, Hip, 0)
        task.synchronize()
        Body.CFrame = NewCF
        Character:SetAttribute("IsWallRun", true)
        -- Character:SetAttribute("CameraType", "Horizontal")
    end)    
    ]]
    -- Actor:BindToMessageParallel("StopForward", function()
    --     Direction = Vector3.zero
    -- end)
    -- Actor:BindToMessageParallel("StopDownward", function()   if Down then Down:Disconnect() end end)

end)
