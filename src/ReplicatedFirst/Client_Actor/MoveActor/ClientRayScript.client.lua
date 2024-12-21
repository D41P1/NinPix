--!native
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")

local Shared = ReplicatedStorage.Shared

local Hitbox = require(Shared.Hitbox)

local Actor = script.Parent
local ClientActor = script.Parent.Parent -- for the downwards actor
-- local Forward: RBXScriptConnection
local Character
local PhysicsTick:RBXScriptConnection?
local StartForward:RBXScriptConnection
local Jump:RBXScriptConnection 
local WallRun:RBXScriptConnection
local LockMove:RBXScriptConnection
local QDash
Actor:BindToMessage("Init", function(UID: string)  
    Character = CollectionService:GetTagged("Char"..UID)[1]
    local Character1PDV3:Vector3Value = unpack(CollectionService:GetTagged(UID.."Direction"))
    if not Character1PDV3 then warn("[Client] no Character1PDV3 detected: ", UID); return end
    local UV3V:Vector3Value = CollectionService:GetTagged(UID.."UV3V")[1]
    if not UV3V then warn("[Client] no UV3V detected: ", UID); return end
    local VNV:NumberValue = CollectionService:GetTagged(UID.."VNV")[1] --* Velocity Number Value
    if not VNV then warn("[Client] no VNV detected: ", UID); return end

    local MoveBody:BasePart = Character.PrimaryPart
    local LookBody:BasePart = Character.LookBody
    
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
    local Velocity_Min:number = WalkSpeed/12 
    local WorldUp= Vector3.yAxis
    local ProjectionVector = function(D:Vector3, N:Vector3)
       return (D - (D:Dot(N) *N)).Unit
    end
    --* you cannot do .Unit of a Vector3.Zero value you get NAN direction so we using 1e-12
    Direction.Value = ProjectionVector(workspace.CurrentCamera.CFrame.LookVector, UV3V.Value)    
    
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
                task.synchronize()
                UV3V.Value = WorldUp
            end
            task.synchronize()
            MoveBody.CFrame = CURRENT_CFrame
            return CURRENT_POS
            --TODO check the Gravity at this point if its over a certain threshold u could add a Crater effect it means they hit the floor HARD and FAST 
        else
            --* they have hit the floor
            Gravity = BaseGravity            
            AirTimeUnix = DateTime.now().UnixTimestamp
            CURRENT_POS= GravityRR.Position+ (GravityRR.Normal *Hip) --* basically this the cancollide with the floor so they don't half phase through
            return CURRENT_POS
        end        
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
    local Movement_Sort = function (CURRENT_UNIT_DIR:Vector3, CURRENT_POS:Vector3, GravityDir:Vector3, Stepped_Movement:number)
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
    local function SetValues(CURRENT_CFrame:CFrame, CURRENT_POS:Vector3, CURRENT_UNIT_DIR:Vector3)
        task.synchronize()
        CURRENT_CFrame = CFrame.lookAlong(CURRENT_POS, CURRENT_UNIT_DIR, UV3V.Value)    
        Direction.Value = CURRENT_UNIT_DIR;
        MoveBody.CFrame = CURRENT_CFrame  
        return CURRENT_POS, CURRENT_UNIT_DIR
    end
    local DefaultPhysics_Tick = function(a0:number)
        --* gain access to the Instances in Main thread to possibly avoid conflicts of data
        local CURRENT_UNIT_DIR:Vector3 = Direction.Value
        local CURRENT_CFrame:CFrame = MoveBody.CFrame --* where character is moving
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
            ClientActor:SendMessage("HM_OldState")
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
    StartForward = Actor:BindToMessageParallel("Walk", function(LookVector:Vector3)
        if Character:GetAttribute("LockMove") then return end
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
        if Character:GetAttribute("LockMove") then ClientActor:SendMessage("HM_OldState"); return end
        task.synchronize()
        Gravity = JumpHeight
        GravityAcceleration *= 2 

        if not PhysicsTick then return end
        PhysicsTick:Disconnect()
        PhysicsTick = RunService.Heartbeat:Connect(Jump_Physics_Tick) 
        ClientActor:SendMessage("JumpSound")
    end)
    --TODO move/rework stuff below to Server Only after finishing↑ ↓↓↓↓↓↓↓
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
    local function KB_Sort(CURRENT_UNIT_DIR:Vector3, CURRENT_POS:Vector3, GravityDir:Vector3, Stepped_Movement:number)
        local CURRENT_DIR_RR:RaycastResult? = Hitbox:Raycasting(CURRENT_POS, CURRENT_POS + CURRENT_UNIT_DIR, Stepped_Movement *1.1)
        if CURRENT_DIR_RR then
            --* sliding/Bouncing against a wall or floor or ceiling 
            -- CURRENT_UNIT_DIR = SLIDING_DIR --* SLIDING_DIR -> has potential to be NAN value so do not SET HERE
            if Velocity.Value >= 120 then
                --*travelling too fast in KB so Bounce  
                CURRENT_POS , CURRENT_UNIT_DIR= Bounce_Sort(CURRENT_UNIT_DIR, CURRENT_DIR_RR, CURRENT_POS, GravityDir, Stepped_Movement)
                CURRENT_DIR_RR = Hitbox:Raycasting(CURRENT_POS, CURRENT_POS + CURRENT_UNIT_DIR, Stepped_Movement * 1.1)
                ClientActor:SendMessage("BounceSound")

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
        task.synchronize()
        local CURRENT_UNIT_DIR:Vector3 = Direction.Value
        local CURRENT_CFrame:CFrame = MoveBody.CFrame --* where character is moving
        DeltaMove += a0
        DashDelta += a0
        if DeltaMove <= TickMovement then return end
        DeltaMove -= TickMovement
        if DashDelta >= DashEnd then 
            --* end dash momentum
            DashDelta -= DashEnd
            task.synchronize()
            Character:SetAttribute("LockMove", false)
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
    QDash = Actor:BindToMessageParallel("QDash", function(CameraLookVector:Vector3)
        if Character:GetAttribute("LockMove") then return end
        task.synchronize()
        Character:SetAttribute("LockMove", true)
        if not PhysicsTick then return end
        PhysicsTick:Disconnect()
        Velocity.Value = DashSpeed
        Gravity = BaseGravity
        GravityAcceleration = BaseGravity_Acceleration 
        SetValues(MoveBody.CFrame, MoveBody.CFrame.Position + UV3V.Value*(Hip *3), CameraLookVector)
        ClientActor:SendMessage("HM_OldState") --* so it doesnt get stuck in the Jump Humanoid State
        ClientActor:SendMessage("DashSound")
        
        PhysicsTick = RunService.Heartbeat:Connect(QDash_Tick)        

    end)
end)

--[[ --*SOME NOTES
-- Vector3Values are not limited to being changed multiple times in the same thread within the same frame  so what that means is if i change it 5 times 
and then use each value 5 times it will take into consideration the other 4 times it was changed and it will use, correctly, with the same Frame the Most updated value
for example i change it once and use it to calculate movement then change it again for something else the values would be different for both usages (even tho its the same Frame)
this is not the case for BaseParts (Rendered instances)
-- on the other hand BaseParts are limited to only being updated once per frame (they would take the last update of the Variable to update it )
so if you changed a basePart 8 times in a Frame it will only take the 8th value into consideration so if you tried using it 8 times you would only visually see the 1st values and 8th values
being used in your calculations which can cause errors in you calculations  
-- only one PhysicsTick can be Connected at any given Time
]]
