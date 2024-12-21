--!native
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local Shared = ReplicatedStorage.Shared
local RayMovement = require(Shared.RayMovement)
local Hitbox = require(Shared.Hitbox)
local UpVectorEvent = ReplicatedStorage.FromServer.UpVectorEvent
local Server_Script = game:GetService("ServerScriptService").Server.ServerActor.Server_Script
local MessageAPI = require(Server_Script.MessageAPI)
-- //local RunService = game:GetService("RunService")
local Character_Script= script.Parent.Parent
local Character_Bindable:BindableEvent = Character_Script.Bind
local Actor = script.Parent

--// local Down: RBXScriptConnection
--// local Character: Model
-- local SetCF = function(NewCF: CFrame) PreviousCF = NewCF end
-- local GetCF = function() return PreviousCF end
local Connections  = {} --* only to prevent potential memory leak when this scripts gets destroyed
local PhysicsTick
local StartForward
local Jump:RBXScriptConnection 
local WallRun:RBXScriptConnection
local LockMove:RBXScriptConnection
local QDash
Actor:BindToMessageParallel("Init", function(UID, Data)  
    print("Initialized FA Working")
    --* if you want to change or affect the direction of movement get the Character1PDV3.Value and add ur own direction  and then set it 
    --* BodyCFPart (Server) = Character (Client)
    --* CFV Look is where the Character is LOOKING NOT MOVING!!!
    local CFV:CFrameValue = unpack(CollectionService:GetTagged(UID.."CFV"))  
    if not CFV then warn("no CFV detected: ", UID); return end
    local BodyCFPart:Part = unpack(CollectionService:GetTagged(UID.."Body"))
    if not BodyCFPart then warn("no BODY_CF_PART  detected: ", UID); return end
    local Character1PDV3:Vector3Value = unpack(CollectionService:GetTagged(UID.."ServerDirection"))    
    if not Character1PDV3 then warn("no Character1PDV3 detected: ", UID); return end
    local VNV:NumberValue = unpack(CollectionService:GetTagged(UID.."SVNV"))    
    if not VNV then warn("no VNV detected: ", UID); return end
    local LookV3:Vector3Value= unpack(CollectionService:GetTagged(UID.."SLV3"))
    if not LookV3 then warn("no LookV3 detected: ", UID); return end
    local UV3V:Vector3Value=  unpack(CollectionService:GetTagged(UID.."SUV3V"))
    if not UV3V then warn("no UV3V detected: ", UID); return end  
    local NumUID  = tonumber(UID)
    task.synchronize()
    UV3V.Value= Vector3.new(0, 1, 0)  

    local MoveBody:Part = BodyCFPart
    local DeltaMove:number, TickMovement =  0, 0.0332 --* 30hz
    local JumpDelta, JumpEnd= 0, 1
    local DashDelta, DashEnd = 0, 1.5 
    local AirTimeUnix:number = DateTime.now().UnixTimestamp
    local WalkSpeed:number = 40
    local Hip:number = 4.2
    local Velocity:NumberValue = VNV
    local DashSpeed = 100 --* 100
    local Direction:Vector3Value = Character1PDV3
    local JumpHeight:number = 45
    local BaseGravity:number = 3
    local BaseGravity_Acceleration:number = 1.2
    local Gravity:number = BaseGravity
    local GravityAcceleration:number = BaseGravity_Acceleration 
    local Deceleration:number = 1
    local Velocity_Min:number = WalkSpeed /12 
    local BaseDirection:Vector3 = Vector3.new(1e-12, -1e-12, 1e-12)
    local WorldUp= Vector3.yAxis
    local ProjectionVector = function(D:Vector3, N:Vector3)
        return (D - (D:Dot(N) *N)).Unit
    end
    
    task.synchronize()
    --* you cannot do .Unit of a Vector3.Zero value you get NAN direction so we using 1e-12
    Direction.Value = BaseDirection
    local function FireUpVectorEvent(UpVector:Vector3)
        local UpVector_Buffer = buffer.create(4)
        buffer.writeu8(UpVector_Buffer, 0, NumUID)
        buffer.writei8(UpVector_Buffer, 1, math.round(UpVector.X))
        buffer.writei8(UpVector_Buffer, 2, math.round(UpVector.Y))
        buffer.writei8(UpVector_Buffer, 3, math.round(UpVector.Z))
        task.synchronize()
        UV3V.Value = UpVector
        UpVectorEvent:FireAllClients(UpVector_Buffer)
    end
    local function Gravity_Sort(CURRENT_UNIT_DIR:Vector3, CURRENT_POS:Vector3, GravityDir:Vector3, CURRENT_CFrame:CFrame)
        local GravityRR:RaycastResult? = Hitbox:Raycasting(CURRENT_POS, CURRENT_POS + GravityDir, Hip*1.5)
        if not GravityRR then 
            local Ceiling_RR =  Hitbox:Raycasting(CURRENT_POS, CURRENT_POS - GravityDir, Gravity *TickMovement *1.1)
            if Ceiling_RR then 
                CURRENT_POS += Ceiling_RR.Normal*2  --* basically this the cancollide with the floor so they don't half phase through
                return CURRENT_POS
            end
            --* they are in the air
            CURRENT_POS= CURRENT_POS + (GravityDir *Gravity *TickMovement) --* basically this the cancollide with the floor so they don't half phase through
            CURRENT_CFrame = CFrame.lookAlong(CURRENT_POS, CURRENT_UNIT_DIR, UV3V.Value)        
            if DateTime.now().UnixTimestamp - AirTimeUnix > 2 then 
                --* Airborne for > 3 seconds will set them back to Default World UpVector
                CURRENT_CFrame = CFrame.lookAlong(CURRENT_POS, CURRENT_UNIT_DIR, WorldUp)    
                FireUpVectorEvent(WorldUp)
            end
            task.synchronize()
            MoveBody.CFrame = CURRENT_CFrame
            CFV.Value = CFrame.lookAlong(CURRENT_POS, LookV3.Value, UV3V.Value)
            --TODO check the Gravity at this point if its over a certain threshold u could add a Crater effect it means they hit the floor HARD and FAST 
        else
            --* they have hit the floor
            Gravity = BaseGravity            
            AirTimeUnix = DateTime.now().UnixTimestamp
            CURRENT_POS= GravityRR.Position+ (GravityRR.Normal *Hip) --* basically this the cancollide with the floor so they don't half phase through
        end        
        return CURRENT_POS
    end
    local Slide_Sort = function(CURRENT_UNIT_DIR:Vector3, CURRENT_DIR_RR:RaycastResult, CURRENT_POS:Vector3, GravityDir:Vector3, Stepped_Movement)
        local SLIDING_DIR = ProjectionVector(CURRENT_UNIT_DIR, CURRENT_DIR_RR.Normal) 
        local SLIDING_RR = Hitbox:Raycasting(CURRENT_POS, CURRENT_POS+SLIDING_DIR, Hip/2)
        if not SLIDING_RR then
            local Check_If_Floor = GravityDir:Dot(SLIDING_DIR)
            if Check_If_Floor <  0.1  then
                --* wall or Ceiling
                CURRENT_POS = CURRENT_POS + (SLIDING_DIR *Stepped_Movement *0.1) + (-CURRENT_UNIT_DIR)        
            else
                --* Floor 
                CURRENT_POS = CURRENT_POS + (SLIDING_DIR *Stepped_Movement )
            end
        end
        return CURRENT_POS, CURRENT_UNIT_DIR
    end
    local function Movement_Sort(CURRENT_UNIT_DIR:Vector3, CURRENT_POS:Vector3, GravityDir:Vector3, Stepped_Movement:number)
        local CURRENT_DIR_RR:RaycastResult? = Hitbox:Raycasting(CURRENT_POS, CURRENT_POS + CURRENT_UNIT_DIR, Stepped_Movement*2)
        if CURRENT_DIR_RR then
            --* sliding against a wall or floor or ceiling 
            -- CURRENT_UNIT_DIR = SLIDING_DIR --* SLIDING_DIR -> has potential to be NAN value so do not SET HERE
            CURRENT_POS = Slide_Sort(CURRENT_UNIT_DIR, CURRENT_DIR_RR, CURRENT_POS, GravityDir, Stepped_Movement)
        else
            CURRENT_UNIT_DIR = ProjectionVector(CURRENT_UNIT_DIR, UV3V.Value)
            local StepDirection = CURRENT_UNIT_DIR*Stepped_Movement
            local Ceiling_RR:RaycastResult? = Hitbox:Raycasting(CURRENT_POS, CURRENT_POS + (-GravityDir + (CURRENT_UNIT_DIR*0.3)), Hip*1.2)
            if Ceiling_RR then
                --* in case they hit a ceiling walking upside down to prevent going under the map        
                local Dir = (CURRENT_POS - Ceiling_RR.Position).Unit                
                CURRENT_UNIT_DIR = ProjectionVector(Dir, Ceiling_RR.Normal)
                StepDirection = CURRENT_UNIT_DIR *Stepped_Movement *0.1
                CURRENT_POS = CURRENT_POS + StepDirection
                return CURRENT_POS
            end
            --* the actual Movement assuming the direction in which they are moving does not hit an object 
            CURRENT_POS = CURRENT_POS + StepDirection
        end
        return CURRENT_POS 
    end
    local function SetValues(CURRENT_CFrame:CFrame, CURRENT_POS:Vector3, CURRENT_UNIT_DIR:Vector3) --* SEND MOVEMENT DIRECTION NOT LOOK
        task.synchronize()
        CURRENT_CFrame = CFrame.lookAlong(CURRENT_POS, CURRENT_UNIT_DIR, UV3V.Value)    
        Direction.Value = CURRENT_UNIT_DIR;
        MoveBody.CFrame = CURRENT_CFrame  
        CFV.Value = CFrame.lookAlong(CURRENT_POS, LookV3.Value, UV3V.Value)
        return CURRENT_POS, CURRENT_UNIT_DIR
    end
    local DefaultPhysics_Tick = function(a0:number)
        --* gain access to the Instances in Main thread to possibly avoid conflicts of data
        if BodyCFPart:GetAttribute("LockMove") then  return end
        local CURRENT_UNIT_DIR:Vector3 = Direction.Value
        local CURRENT_CFrame:CFrame = CFV.Value --* where character is moving
        task.desynchronize()
        DeltaMove += a0
        if DeltaMove <= TickMovement then return end
        DeltaMove -= TickMovement
        local Stepped_Movement = Velocity.Value *TickMovement        
        local CURRENT_POS:Vector3 = CURRENT_CFrame.Position
        local GravityDir:Vector3 = -UV3V.Value
        CURRENT_POS = Gravity_Sort(CURRENT_UNIT_DIR, CURRENT_POS, GravityDir, CURRENT_CFrame)   
        task.synchronize()
        Velocity.Value -= Deceleration
        Gravity += GravityAcceleration
        if Velocity.Value <= Velocity_Min then 
            --* no point carrying on cos NAN values will appear if Direction becomes Zero
            Velocity.Value = 0
            return 
        end
        CURRENT_UNIT_DIR = CURRENT_UNIT_DIR.Unit
        CURRENT_POS = Movement_Sort(CURRENT_UNIT_DIR, CURRENT_POS, GravityDir, Stepped_Movement)
        --* updating CFrame
        CURRENT_POS = SetValues(CURRENT_CFrame, CURRENT_POS, CURRENT_UNIT_DIR) 
    end
    local Jump_Physics_Tick = function(a0:number)
        if BodyCFPart:GetAttribute("LockMove") then  return end
        --* DIFFERENCE between functions is the gravity mechanic
        --* gain access to the Instances in Main thread to possibly avoid conflicts of data
        local CURRENT_UNIT_DIR:Vector3 = Direction.Value
        local CURRENT_CFrame:CFrame = MoveBody.CFrame --* where character is moving
        task.desynchronize()
        DeltaMove += a0
        JumpDelta += a0
        if DeltaMove <= TickMovement then return end
        DeltaMove -= TickMovement
        if JumpDelta >= JumpEnd then 
            --* end the Upwards Momentum
            JumpDelta -= JumpEnd
            task.synchronize()
            Gravity = -Gravity
            GravityAcceleration = BaseGravity_Acceleration
            if PhysicsTick then 
                PhysicsTick:Disconnect()
                PhysicsTick = RunService.Heartbeat:Connect(DefaultPhysics_Tick)    
            end
            Character_Bindable:Fire("HM_OldState")
            return
        end
        local Stepped_Movement = Velocity.Value*TickMovement        
        local CURRENT_POS:Vector3 = CURRENT_CFrame.Position
        local GravityDir:Vector3 = UV3V.Value
        CURRENT_POS = Gravity_Sort(CURRENT_UNIT_DIR, CURRENT_POS, GravityDir, CURRENT_CFrame)   
        task.synchronize()
        Velocity.Value -= Deceleration
        Gravity -= GravityAcceleration
        if Velocity.Value <= Velocity_Min then 
            --* no point carrying on cos NAN values will appear if Direction becomes Zero
            Velocity.Value = 0
            CURRENT_POS = SetValues(CURRENT_CFrame, CURRENT_POS, CURRENT_UNIT_DIR) 
            return 
        end
        CURRENT_UNIT_DIR = CURRENT_UNIT_DIR.Unit
        CURRENT_POS = Movement_Sort(CURRENT_UNIT_DIR, CURRENT_POS, GravityDir, Stepped_Movement)
        --* updating CFrame
        CURRENT_POS = SetValues(CURRENT_CFrame, CURRENT_POS, CURRENT_UNIT_DIR) 

    end
    PhysicsTick = RunService.Heartbeat:Connect(DefaultPhysics_Tick)
    StartForward = Actor:BindToMessage("Walk", function(LookVector:Vector3)
        if BodyCFPart:GetAttribute("LockMove") then return end
        local MoveDirection = LookVector
        local AddDir = (Direction.Value + MoveDirection*3).Unit
        task.synchronize()
        Direction.Value = AddDir
        if Velocity.Value >= WalkSpeed then 
            Velocity.Value = WalkSpeed
            return
        end
        Velocity.Value += (WalkSpeed * 0.4) --* Deceleration acting as acceleration also
    end)  
    Jump = Actor:BindToMessageParallel("Jump", function()
        if BodyCFPart:GetAttribute("LockMove") then Character_Bindable:Fire("HM_OldState"); return end
        task.synchronize()
        Gravity = JumpHeight
        GravityAcceleration *= 2 

        if not PhysicsTick then return end
        PhysicsTick:Disconnect()
        PhysicsTick = RunService.Heartbeat:Connect(Jump_Physics_Tick) 
    end)
    local Bounce_Vector = function(n:Vector3, v:Vector3)
        return -2*(n:Dot(v) )* n + v
    end
    local Bounce_Sort = function(CURRENT_UNIT_DIR:Vector3, CURRENT_DIR_RR:RaycastResult, CURRENT_POS:Vector3, GravityDir:Vector3, Stepped_Movement)
        --* they Hit something (Wall, floor, ceiling) Too fast in KB_Sort
        local Surface_Normal = CURRENT_DIR_RR.Normal
        local NewDir:Vector3 = Bounce_Vector(Surface_Normal, CURRENT_UNIT_DIR) --* should be a more accurate way of calculating the bounce direction
        CURRENT_UNIT_DIR = NewDir
        task.synchronize()
        Velocity.Value *=  0.8
        return CURRENT_POS, CURRENT_UNIT_DIR
    end
    local Dash_Sort = function (CURRENT_UNIT_DIR:Vector3, CURRENT_POS:Vector3, GravityDir:Vector3, Stepped_Movement:number)
        local CURRENT_DIR_RR:RaycastResult? = Hitbox:Raycasting(CURRENT_POS, CURRENT_POS + CURRENT_UNIT_DIR, Stepped_Movement*1.1)
        if CURRENT_DIR_RR then
            --* sliding against a wall or floor or ceiling 
            -- CURRENT_UNIT_DIR = SLIDING_DIR --* SLIDING_DIR -> has potential to be NAN value so do not SET HERE
            CURRENT_POS = Slide_Sort(CURRENT_UNIT_DIR, CURRENT_DIR_RR, CURRENT_POS, GravityDir, Stepped_Movement)
        else
            --* the actual Movement assuming the direction in which they are moving does not hit an object 
            local StepDirection = CURRENT_UNIT_DIR*Stepped_Movement     
            local Ceiling_RR:RaycastResult? = Hitbox:Raycasting(CURRENT_POS, CURRENT_POS + (-GravityDir + (CURRENT_UNIT_DIR*0.3)), Hip*1.2)
            if Ceiling_RR then
                --* in case they hit a ceiling walking upside down to prevent going under the map        
                local Dir = (CURRENT_POS - Ceiling_RR.Position).Unit                
                CURRENT_UNIT_DIR = ProjectionVector(Dir, Ceiling_RR.Normal)
                StepDirection = CURRENT_UNIT_DIR *Stepped_Movement *0.1
                CURRENT_POS = CURRENT_POS + StepDirection
                return CURRENT_POS
            end
            CURRENT_POS = CURRENT_POS + StepDirection
        end
        return CURRENT_POS 
    end
    --TODO in KB_Sort Add Particle_Controller.Insert 
    local function KB_Sort(CURRENT_UNIT_DIR:Vector3, CURRENT_POS:Vector3, GravityDir:Vector3, Stepped_Movement:number)
        local CURRENT_DIR_RR:RaycastResult? = Hitbox:Raycasting(CURRENT_POS, CURRENT_POS + CURRENT_UNIT_DIR, Stepped_Movement *1.1)
        if CURRENT_DIR_RR then
            --* sliding/Bouncing against a wall or floor or ceiling 
            -- CURRENT_UNIT_DIR = SLIDING_DIR --* SLIDING_DIR -> has potential to be NAN value so do not SET HERE
            if Velocity.Value >= 60 then 
                --*travelling too fast in KB so Bounce  
                CURRENT_POS , CURRENT_UNIT_DIR= Bounce_Sort(CURRENT_UNIT_DIR, CURRENT_DIR_RR, CURRENT_POS, GravityDir, Stepped_Movement)
                CURRENT_DIR_RR = Hitbox:Raycasting(CURRENT_POS, CURRENT_POS + CURRENT_UNIT_DIR, Stepped_Movement * 1.1)

                if CURRENT_DIR_RR then 
                    KB_Sort(CURRENT_UNIT_DIR, CURRENT_POS, GravityDir, Stepped_Movement)
                else
                    CURRENT_POS += CURRENT_UNIT_DIR
                end
                return CURRENT_POS, CURRENT_UNIT_DIR
            end
            CURRENT_POS = Slide_Sort(CURRENT_UNIT_DIR, CURRENT_DIR_RR, CURRENT_POS, GravityDir, Stepped_Movement)
        else
            --* the actual Movement assuming the direction in which they are moving does not hit an object 
            local StepDirection = CURRENT_UNIT_DIR*Stepped_Movement     
            local Ceiling_RR:RaycastResult? = Hitbox:Raycasting(CURRENT_POS, CURRENT_POS + (-GravityDir + (CURRENT_UNIT_DIR*0.3)), Hip*1.2)
            if Ceiling_RR then
                --* in case they hit a ceiling walking upside down to prevent going under the map        
                local Dir = (CURRENT_POS - Ceiling_RR.Position).Unit                
                CURRENT_UNIT_DIR = ProjectionVector(Dir, Ceiling_RR.Normal)
                StepDirection = CURRENT_UNIT_DIR *Stepped_Movement *0.1
                CURRENT_POS = CURRENT_POS + StepDirection                
                return CURRENT_POS, CURRENT_UNIT_DIR
            end
            CURRENT_POS = CURRENT_POS + StepDirection
        end
        return CURRENT_POS , CURRENT_UNIT_DIR
    end
    local QDash_Tick = function(a0:number)
        --* gain access to the Instances in Main thread to possibly avoid conflicts of data
        local CURRENT_UNIT_DIR:Vector3 = Direction.Value
        local CURRENT_CFrame:CFrame = MoveBody.CFrame --* where character is moving
        task.desynchronize()
        DeltaMove += a0
        DashDelta += a0
        if DeltaMove <= TickMovement then return end
        DeltaMove -= TickMovement
        if DashDelta >= DashEnd then 
            --* end dash momentum
            DashDelta -= DashEnd
            task.synchronize()
            BodyCFPart:SetAttribute("LockMove", false)
            if PhysicsTick then 
                PhysicsTick:Disconnect()
                Direction.Value = ProjectionVector(CURRENT_UNIT_DIR, UV3V.Value)
                PhysicsTick = RunService.Heartbeat:Connect(DefaultPhysics_Tick)    
            end            
            return
        end
        local Stepped_Movement = Velocity.Value*TickMovement        
        local CURRENT_POS:Vector3 = CURRENT_CFrame.Position
        local GravityDir:Vector3 = -UV3V.Value
        CURRENT_POS = Gravity_Sort(CURRENT_UNIT_DIR, CURRENT_POS, GravityDir, CURRENT_CFrame)
        task.synchronize()
        Velocity.Value -= Deceleration
        Gravity += GravityAcceleration
        if Velocity.Value <= Velocity_Min then 
            --* no point carrying on cos NAN values will appear if Direction becomes Zero
            Velocity.Value = 0
            return 
        end
        CURRENT_UNIT_DIR = CURRENT_UNIT_DIR.Unit
        CURRENT_POS= Dash_Sort(CURRENT_UNIT_DIR, CURRENT_POS, GravityDir, Stepped_Movement) --* comment this when Testing KB
        -- CURRENT_POS, CURRENT_UNIT_DIR = KB_Sort(CURRENT_UNIT_DIR, CURRENT_POS, GravityDir, Stepped_Movement) --* uncomment to quickly test KB 
        --* updating CFrame
        CURRENT_POS = SetValues(CURRENT_CFrame, CURRENT_POS, CURRENT_UNIT_DIR) 
    end
    WallRun = Actor:BindToMessage("WallRun", function(CameraLookVector:Vector3)
        if BodyCFPart:GetAttribute("LockMove") then return end
        local MoveBodyCF = MoveBody.CFrame
        task.desynchronize()
        local End:Vector3 = MoveBodyCF.Position + CameraLookVector
        local Find_Wall_RR:RaycastResult? = Hitbox:Raycasting(MoveBodyCF.Position, End, 25)
        if not Find_Wall_RR then return end
        local Relative_Direction:Vector3 = ProjectionVector(CameraLookVector, Find_Wall_RR.Normal)
        local New_Pos:Vector3 = Find_Wall_RR.Position + (Find_Wall_RR.Normal*(Hip+5))
        local RRCFPos:CFrame = CFrame.lookAlong(New_Pos, Relative_Direction, Find_Wall_RR.Normal)           
        task.synchronize()    
        FireUpVectorEvent(Find_Wall_RR.Normal)
        MoveBody.CFrame = RRCFPos 
        LookV3.Value = RRCFPos.LookVector
        Velocity.Value = 0
    end)
    QDash = Actor:BindToMessage("QDash", function(CameraLookVector:Vector3)
        if BodyCFPart:GetAttribute("LockMove") then  return end
        if not PhysicsTick then return end
        PhysicsTick:Disconnect()
        BodyCFPart:SetAttribute("LockMove", true)
        Direction.Value = CameraLookVector 
        Velocity.Value = DashSpeed
        Gravity = BaseGravity
        GravityAcceleration = BaseGravity_Acceleration 
        Character_Bindable:Fire("HM_OldState") --* so it doesnt get stuck in the Jump Humanoid State
        local NewCF = CFrame.lookAlong(CFV.Value.Position + UV3V.Value*(Hip *3), CFV.Value.LookVector, UV3V.Value)
        SetValues(NewCF, NewCF.Position, CameraLookVector)
        PhysicsTick = RunService.Heartbeat:Connect(QDash_Tick)        
        --TODO Do Hit Detection Main thread NOT HERE 
    end)
end)

--[[ --* OLD ATTEMPT AT NEW SYSTSEM
-- local WalkSpeed = 10
    local Hip= 5
    local Velocity:number = 0
    local Direction:Vector3Value = Character1PDV3
    local Gravity = 2
    local GravityAcceleration = 0.05  
    local Deceleration = GravityAcceleration - 0.02 --* has to be less than gravity cos that makes sense just make sure its not negative
    local DeltaMove, TickMovement =  0, 0.0332 --* 30hz
    Deceleration = math.clamp(Deceleration, 0.01, Gravity)

    local ProjectionVector = function(D:Vector3, N:Vector3)
        return (D - (D:Dot(N) *N)).Unit
    end
    task.synchronize()
    if true then return end --TODO REMOVE 
    PhysicsTick = RunService.Heartbeat:Connect(function(a0: number)  
        DeltaMove += a0
        if DeltaMove <= TickMovement then return end
        DeltaMove -= TickMovement
        --* gain access to the Instances in Main thread to possibly avoid conflicts of data
        local CURRENT_UNIT_DIR:Vector3 = Direction.Value.Unit
        local CURRENT_CFrame:CFrame = CFV.Value

        task.desynchronize()
        local Stepped_Movement = Velocity*TickMovement*1.5        
        local CURRENT_POS:Vector3 = CURRENT_CFrame.Position
        local GravityDir:Vector3 = -CURRENT_CFrame.UpVector
        local GravityRR:RaycastResult? = HitBox:ServerMapRaycasting(CURRENT_POS, CURRENT_POS + GravityDir, Hip)
        if not GravityRR then 
            --* they are in the air
            CURRENT_UNIT_DIR = (CURRENT_UNIT_DIR + GravityDir*GravityAcceleration).Unit
        else
            --* they have hit the floor
            local Distance = (CURRENT_POS - GravityRR.Position).Magnitude                
            local Difference = Hip - Distance
            CURRENT_POS= CURRENT_POS + (-GravityDir * Difference) --* basically this the cancollide with the floor so they don't half phase through     
        end
        local CURRENT_DIR_RR:RaycastResult? = HitBox:ServerMapRaycasting(CURRENT_POS, CURRENT_POS + CURRENT_UNIT_DIR, Hip/2)
        if CURRENT_DIR_RR then
            --* sliding against a wall or floor 
            --* D - (D:Dot(N) *N) to get the projection Vector or cancel out the axis not needed
            local SLIDING_DIR = ProjectionVector(CURRENT_UNIT_DIR, CURRENT_DIR_RR.Normal) 
            CURRENT_UNIT_DIR = SLIDING_DIR
            local SLIDING_RR = HitBox:ServerMapRaycasting(CURRENT_POS, CURRENT_POS+SLIDING_DIR, Hip/2)
            if SLIDING_RR then
                local NEWPOS = SLIDING_RR.Position+ (-SLIDING_DIR *Stepped_Movement)
                CURRENT_CFrame = CFrame.lookAlong(NEWPOS, CURRENT_CFrame.LookVector, CURRENT_CFrame.UpVector)
                --TODO check the velocity at this point if its over a certain threshold u could add a Crater effect it means they hit the floor HARD and FAST 
            else
                local NEWPOS = CURRENT_POS + (SLIDING_DIR *Stepped_Movement)
                CURRENT_CFrame = CFrame.lookAlong(NEWPOS, CURRENT_CFrame.LookVector, CURRENT_CFrame.UpVector)    
            end
        else
            --* the actual Final Movement assuming the direction in which they are moving does not hit an object 
            CURRENT_POS += CURRENT_UNIT_DIR *Stepped_Movement
            CURRENT_CFrame = CFrame.lookAlong(CURRENT_POS, CURRENT_CFrame.LookVector, CURRENT_CFrame.UpVector)
        end
        task.synchronize()
        CFV.Value = CURRENT_CFrame
        BodyCFPart.CFrame = CURRENT_CFrame
        Direction.Value = CURRENT_UNIT_DIR
        Gravity += GravityAcceleration
        if Velocity <= 0.2 then  Velocity = 0;  return end
        Velocity -= Deceleration
    end)

]]
--[[ --* OLD SYSTEM
    local WalkSpeed: number = 16
    local Hip = 5
    local PreviousCF: CFrame = CURRENT_CFrame
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
        if LockMovement then  warn("3"); return end
        if not CF then warn("2");  return end
        local WS = WalkSpeed
        local PreviousPos:Vector3 = CF.Position
        local NewDir:Vector3 = CF.LookVector 
        local NewPos:Vector3 = PreviousPos + NewDir *(WS *0.08)
        local Origin:Vector3 = PreviousPos
        local End =  Origin + (NewDir * 2)
        
        local DownRR = HitBox:Raycasting(NewPos, NewPos + Vector3.new(0, -1, 0), Hip + 0.5)
        if not DownRR then  warn("5"); return end
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
        
        local RR: RaycastResult =  HitBox:Raycasting(Origin, End, Hip * 1.2)
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
        if HitAnotherBodyRR then --* hit another BodyCFPart or the Map 
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
    
]]