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
local Connections  = {} --* only to prevent potential memory leak
Actor:BindToMessageParallel("Init", function(UID, Data)  
    local CFV:CFrameValue = unpack(CollectionService:GetTagged(UID.."CFV"))  
    local BodyCFPart:Part = unpack(CollectionService:GetTagged(UID.."Body"))
    if not CFV then warn("no CFV detected: ", UID); return end
    if not BodyCFPart then warn("no BODY_CF_PART  detected: ", UID); return end
    
    local WalkSpeed: number = Data.WalkSpeed
    local OldWalkSpeed = Data.WalkSpeed
    local Hip: number = Data.Hip
    local PreviousCF: CFrame = Data.CurrentCF * CFrame.new(0, Hip, 0)
    local LockMovement = false

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
        if LockMovement then return end
        local WS = WalkSpeed
        local PreviousPos = PreviousCF.Position
        local NewDir:Vector3 = CF.LookVector 
        local NewPos:Vector3 = PreviousPos + NewDir *(WS *0.08)
        local Origin:Vector3 = PreviousPos; local End = Origin + (NewDir * 2)
        
        local DownRR = HitBox:Raycasting(NewPos, NewPos + Vector3.new(0, -1, 0), 2.8)
        if not DownRR then return end
    
        local RR = HitBox:Raycasting(Origin, End, WS*0.24)
        local CFLook = CFrame.lookAlong(NewPos, CF.LookVector, CF.UpVector)
        if RR then 
            local Look = CFrame.lookAlong(RR.Position, CF.LookVector, CF.UpVector) 
            CFLook = Look * CFrame.new(0, 0, 1)
            PreviousCF = CFLook     
        end
        PreviousCF = CFLook
        -- Send message 2 to SSS only
        task.synchronize()
        CFV.Value = CFLook
        BodyCFPart.CFrame = CFLook
    end)
    local StartDown:any = Actor:BindToMessageParallel("StartDownward", function(CF: CFrame)--* Downwards Actor
        local Origin = CF.Position
        local End: Vector3 = Origin + (CF.UpVector *-10)        
        local RR: RaycastResult =  HitBox:Raycasting(Origin, End, 2.75)
        if RR then
            local RRHitHip = RR.Position.Y + Hip
            local BodyY = Origin.Y + 0.1
            if RRHitHip > BodyY then 
                CharacterActor:SendMessage("LedgeUp", UID, RR.Position, Hip, CF) --move up here 
            end
            return 
        end     
        --*start fall
        CharacterActor:SendMessage("DownNotHit", UID, CF)
    end)
    local StartFall:any = Actor:BindToMessageParallel("StartFall", function(CurrentCFrame:CFrame)  
        local d: number, s: number = 0, 0.1
        local Conn:RBXScriptConnection
        local sy: () -> () = task.synchronize
        sy()
        local CurrentPos = CurrentCFrame.Position
        Conn = RunService.Heartbeat:ConnectParallel(function(a0: number) 
            local deltanew = d
            deltanew += a0
            if deltanew >= s then
                local Origin: Vector3 = CurrentPos
                local End: Vector3 = Origin + Vector3.new(0, -1 , 0)
                local RR: RaycastResult? =  HitBox:Raycasting(Origin, End, 2.75)
                if not RR then   
                    d = deltanew
                    sy()
                    local NewPos =Origin + Vector3.new(0, -1, 0)
                    CurrentPos = NewPos
                    local CFLook =  CFrame.lookAlong(NewPos, CurrentCFrame.LookVector, CurrentCFrame.UpVector)
                    task.synchronize()
                    CFV.Value = CFLook
                    BodyCFPart.CFrame = CFLook
                    return   
                end
                local Pos = RR.Position + Vector3.new(0, Hip, 0)
                CurrentPos = Pos
                local CFLook =  CFrame.lookAlong(Pos, CurrentCFrame.LookVector, CurrentCFrame.UpVector)
                CharacterActor:SendMessage("StopFall", UID, CFLook)      
                sy()
                Conn:Disconnect()    
            end    
            d = deltanew 
        end)    
    end)
    local JumpWithMovement:any = Actor:BindToMessageParallel("JumpWithMovement", function(Direction: Vector3) -- for other characters 
        local CurrentCF = PreviousCF
        local Start = CurrentCF.Position 
        local End  = Start + (Direction *15)
        local Amount = 30
        local P1 = Start:Lerp(End, 0.5) + Vector3.new(0, Amount, 0)
        local CurvePoints = RayMovement.CurveCalculate(Start, End, Amount, P1)
        local Conn: RBXScriptConnection , d, s = nil, 0, 0.1
        local NextPoint = 0
        local sy = task.synchronize
        local function Stop()
            sy()
            if Conn then Conn:Disconnect();  end
            CharacterActor:SendMessage("DownNotHit", UID, PreviousCF)
        end
        local Origin = Start
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
            d = NewDelta
        end)

    end)    
    local Jump:any = Actor:BindToMessageParallel("Jump", function() --* forward Actor
        local CurrentCF = PreviousCF
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
    local AdjustWS:any = Actor:BindToMessageParallel("AdjustWS", function(NewWs: number) --* forward Actor
        OldWalkSpeed = WalkSpeed
        WalkSpeed = NewWs
    end)
    local OldWS:any = Actor:BindToMessageParallel("OldWS", function() --* forward Actor
        WalkSpeed = OldWalkSpeed
    end)
    local LM:any = Actor:BindToMessageParallel("LockMove", function(Bool:boolean?) --* forward Actor
        LockMovement = Bool
    end)    
    
    table.insert(Connections, Set)
    table.insert(Connections, StartDown)
    table.insert(Connections, StartFall)
    table.insert(Connections, StartForward)
    table.insert(Connections, AdjustWS)
    table.insert(Connections, Jump)
    table.insert(Connections, JumpWithMovement)
    table.insert(Connections, OldWS)
    table.insert(Connections, LM)
    
    --TODO knockback
end)

-- Actor:BindToMessageParallel("StopForward", function()
-- end)
-- Actor:BindToMessageParallel("StopDownward", function()   if Down then Down:Disconnect() end end)




