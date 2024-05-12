--!native
local ActivityHistoryService = game:GetService("ActivityHistoryService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local DebuggablePluginWatcher = game:GetService("DebuggablePluginWatcher")
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



local RayForward= function(Pos: Vector3, PreviousPos:Vector3, NewDir: Vector3, WS: number, Body, DeltaMove: number)
    local NewPos = Body.Position + NewDir * (WS *DeltaMove)
    local CFLook = CFrame.new(NewPos, Pos)
    local Origin = Body.Position; local End = Origin + (NewDir * 2)
    local RR = HitBox:Raycasting(Origin, End, WS*DeltaMove*3)
    if RR then 
        local LookPos = Pos + NewDir*10 
        local Look = CFrame.new(RR.Position, LookPos) 
        CFLook = Look * CFrame.new(0, 0, 1.5)
        -- ClientMessageAPI.SendToClientActor("ForwardHit", CFLook) 
        -- ClientActor:SendMessage("ForwardHit", CFLook) 
    end
    return CFLook
end

Actor:BindToMessageParallel("Init", function(UID: string)  
    Character = CollectionService:GetTagged(UID)[1]
    local Hip = Character:GetAttribute("Hip")
    local WS = Character:GetAttribute("WalkSpeed")
    local Body = Character.PrimaryPart
    Actor:BindToMessageParallel("StartForward", function(Pos:Vector3) -- client
        local Sync = task.synchronize
        local PreviousPos = Body.Position
        local NewDir = (Pos - PreviousPos).Unit 
        local CFLook = RayForward(Pos, PreviousPos, NewDir, WS, Body, 0.08)
        -- Direction = NewDir 
        Sync()
        Body.CFrame = CFLook    
    end)
    local PreviousCF: CFrame
    Actor:BindToMessageParallel("StartForwardRun", function(CF:CFrame) -- for other characters 
        if PreviousCF and (PreviousCF.Position - CF.Position).Magnitude < 0.01 then
            print("probably the same")
            ClientActor:SendMessage("StopWalk", UID)
        end
        task.synchronize()
        Body.CFrame = CF
        PreviousCF = CF
    end)
    -- /////////////////////////////////TODO in the downwards ray if RR then send to Client to ForceState Fall/////////////////////
    Actor:BindToMessageParallel("StartDownward", function(CF: CFrame)  
        local Origin: Vector3 = Body.Position
        local End: Vector3 = Origin + Vector3.new(0, -1 , 0)
        local RR: RaycastResult =  HitBox:Raycasting(Origin, End, 2.75)
        if RR  then
            local RRHitHip = RR.Position.Y + Hip
            local BodyY = Origin.Y + 0.1
            if RRHitHip > BodyY then 
                ClientActor:SendMessage("LedgeUp", UID, RR.Position, Hip) --move up here 
            end
            return 
        end
        --start fall
        ClientActor:SendMessage("DownNoHit", UID)        
    end)
    Actor:BindToMessageParallel("StartFall", function()  
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
                    Body.Position  = Origin + Vector3.new(0, -1.5, 0)
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
    Actor:BindToMessageParallel("JumpWithMovement", function(Direction: Vector3) -- for other characters 
        local Start = Body.Position 
        local End  = Start + (Direction *15)
        local Amount = 30
        local P1 = Start:Lerp(End, 0.5) + Vector3.new(0, Amount, 0)
        local CurvePoints = RayMovement.CurveCalculate(Start, End, Amount, P1)
        local Conn: RBXScriptConnection , d, s = nil, 0, 0.1
        local NextPoint = 0
        local sy = task.synchronize
        local function Stop()
            sy()
            Conn:Disconnect(); 
            ClientActor:SendMessage("DownNoHit", UID)
        end
        local Sign = -1
        sy()
        Conn = RunService.Heartbeat:Connect(function(a0: number)  
            local NewDelta = d
            NewDelta +=  a0
            NextPoint += 1
            if NewDelta >= s then
                NewDelta = 0
                if NextPoint >= #CurvePoints then  Stop(); return  end
                local Origin = Body.Position
                local ForwardRay = HitBox:Raycasting(Origin, Origin + Direction*5, 2)
                local AxisRay = HitBox:Raycasting(Origin, Origin + Vector3.new(0, -1 *Sign , 0), 4)
                if ForwardRay or AxisRay then Stop(); return  end
                if NextPoint >= Amount/2 then  Sign = 1 end
                sy()
                Body.Position = CurvePoints[NextPoint]
            end
            d = NewDelta
        end)
    end)
    Actor:BindToMessageParallel("Jump", function() -- for other characters 
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
    
    -- Actor:BindToMessageParallel("StopForward", function()
    --     Direction = Vector3.zero
    -- end)
    -- Actor:BindToMessageParallel("StopDownward", function()   if Down then Down:Disconnect() end end)

end)
