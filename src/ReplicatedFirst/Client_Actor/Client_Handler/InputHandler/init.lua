--!native
type ValueConnections = RBXScriptConnection | { RBXScriptConnection } | (... any) -> nil
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local CollectionService = game:GetService("CollectionService")
-- local player = game.Players.LocalPlayer

local Clientactor  = script.Parent.Parent
local Shared = ReplicatedStorage.Shared

local Character_Handler = require(script.Parent.Character_Handler)
local Gui_Handler = require(script.Parent.Gui_Handler)
local Buffer_Converter = require(Shared.Buffer_Converter)
local Hitbox = require(Shared.Hitbox)
local NumToSymbol = require(Shared.NumToSymbol)
local SharedTypes = require(Shared.SharedType)

type CustomHumanoid = SharedTypes.CustomHumanoid
type action = { Func: (any) -> (...any), Values: {(RemoteEvent | UnreliableRemoteEvent)?} }
type Character = typeof(workspace.WORKING_PROD_PixelDummy)
local EventHandler = require(Clientactor.Event_Handler)
local ClientCombatMachine = require(Clientactor.ClientCombatMachine)

local MovementHelper = require(Shared.MovementHelper)
local HumanoidMachine = require(Shared.HumanoidMachine)
local MoveKeys = {
    Enum.KeyCode.W, Enum.KeyCode.A, Enum.KeyCode.S, Enum.KeyCode.D,
}
local ToolKeys = {
    [Enum.KeyCode.One] =  "", [Enum.KeyCode.Two] =  "", [Enum.KeyCode.Three] =  "", [Enum.KeyCode.Four] =  "",
    [Enum.KeyCode.Five] =  "", [Enum.KeyCode.Six] =  "", [Enum.KeyCode.Seven] =  "", [Enum.KeyCode.Eight] =  "",
}
local Connections: { [string]:  ValueConnections } = {}
local InputHandler = {}
local CharacterEvents: SharedTypes.CharacterEvents =  EventHandler["Events"]  
function InputHandler:Init(CustomHumanoid: CustomHumanoid)
    InputHandler["Humanoid"] = CustomHumanoid
end
local ProjectionVector = function(D:Vector3, N:Vector3)
    return (D - (D:Dot(N) *N)).Unit
end

local ShiftLockRBX
local ShiftLockFunc = function  (Character:typeof(workspace.WORKING_PROD_PixelDummy), UV3V:Vector3Value, LV3:Vector3Value) 
    local CamLockDelta, CamLockStep = 0, 0.03
    local Cam = workspace.CurrentCamera
    local Body:BasePart = Character.Body       
    local LookBody = Character.LookBody
    ShiftLockRBX = RunService.Heartbeat:ConnectParallel(function(a0: number)  
        CamLockDelta += a0
        if CamLockDelta <= CamLockStep then return end
        CamLockDelta -= CamLockStep
        local CurrentUp = UV3V.Value
        local Current_Move= Body.CFrame.LookVector * 0.3 -- + (-CurrentUp)
        local Projected_CamLook:Vector3 = ProjectionVector(Cam.CFrame.LookVector, CurrentUp)
        local LookCF = CFrame.lookAlong(Body.Position, Projected_CamLook - Current_Move, CurrentUp )
        task.synchronize()
        LookBody.CFrame = LookCF
        LV3.Value = LookCF.LookVector
    end)
end

local CameraCF = CFrame.new() --* Cos camera tweens its Instance can be a lil behind this is where the camera will be
local Dash_Func = function(Character)
    --[[
    --* Q = 1, M1 = 2, M2 = 4    
    --* Valid Numbers are 2, 5
    ]]
    local Current_Dash_Number:number = InputHandler["DashNumber"]
    if Current_Dash_Number ~= 2 and Current_Dash_Number ~= 5 then return end
    HumanoidMachine.TriggerAction(Character, CharacterEvents.Dash, "QDash", CameraCF)         
    return true
end
InputHandler["DashNumber"] = 0
local ConnectFuncs = {
    function(Character) --* Move
        --[[ Keycode values
            07:26:11.830  119 Enum.KeyCode.W  -  Client - InputHandler:107
            07:26:11.930  97 Enum.KeyCode.A  -  Client - InputHandler:107
            07:26:12.114  115 Enum.KeyCode.S  -  Client - InputHandler:107
            07:26:12.247  100 Enum.KeyCode.D 
        ]]
        local UID = Character.Name
        local UV3V:Vector3Value = CollectionService:GetTagged(UID.."UV3V")[1]
        if not UV3V then warn("[Client] no UV3V detected: ", UID); return end    
        local LV3:Vector3Value = CollectionService:GetTagged(UID.."LV3")[1]
        if not LV3 then warn("[Client] no LV3 detected: ", UID); return end    
           
        local MovementNumber = 0
        local Enum_Keycode_Values = {
            [119] = 2,  --*W
            [97]  = 4,  --*A
            [115] = 8,  --*S
            [100] = 16, --*D
        }
        Connections["Move"] = function(actionName: string, inputState: Enum.UserInputState, inputObject: InputObject) 
            if inputState == Enum.UserInputState.Begin then
                local Value = inputObject.KeyCode.Value
                local Add:number = Enum_Keycode_Values[Value]
                if Add then  MovementNumber += Add end
                return
            end
            if inputState == Enum.UserInputState.End then
                local Value = inputObject.KeyCode.Value
                local Subtract:number = Enum_Keycode_Values[Value]
                if Subtract then  MovementNumber -= Subtract end
                return
            end
        end
        ContextActionService:BindAction("Move", Connections["Move"] , false, unpack(MoveKeys))        
        local TickDelta,  Step = 0, 0.05
        local MoveLook = CharacterEvents.MoveLook

        local MyProifle = Character_Handler.GiveProfile(UID)
        local MV3 = MyProifle.MV3                    
        RunService.Heartbeat:ConnectParallel(function(a0: number)  
            TickDelta += a0
            if TickDelta <= Step then return end
            TickDelta -= Step     
            -- print(MovementNumber)
            local RelativeDirCF = MovementHelper:GiveDirection(InputHandler["Character"], MovementNumber) 
            local Character: Model = InputHandler["Character"]
            local look_Vector_Buffer = Buffer_Converter.UnitVector_Buffer(ProjectionVector(LV3.Value, UV3V.Value))
            if not RelativeDirCF then 
                HumanoidMachine.TriggerAction(Character, nil, "StopWalk")     
                task.synchronize()
                MoveLook:FireServer(look_Vector_Buffer)
                return 
            end
            local Move_Vector_Buffer = Buffer_Converter.UnitVector_Buffer(ProjectionVector(MV3.Value, UV3V.Value))
            local Combined_Buffer = buffer.create(4)
            buffer.copy(Combined_Buffer, 0, look_Vector_Buffer, 0, 2)
            buffer.copy(Combined_Buffer, 2, Move_Vector_Buffer, 0, 2)
            HumanoidMachine.TriggerAction(Character, nil, "StartWalk", RelativeDirCF) --* for CLient    
            task.synchronize()
            MoveLook:FireServer(Combined_Buffer) --* For Server
        end)
    end,
    function(Character) --* Camera 
        local UID = Character.Name
        local UV3V:Vector3Value = CollectionService:GetTagged(UID.."UV3V")[1]
        if not UV3V then warn("[Client] no UV3V detected: ", UID); return end    
        local LookBody:BasePart = Character.LookBody
        
        local Camera = workspace.CurrentCamera
        local Original_UP:Vector3 = Vector3.new(0, 1, 0)
        local ZoomDistance:number = 15
        local Limits:number = 0.9
        local CamCF:CFrame = CFrame.lookAlong(UV3V.Value, Camera.CFrame.LookVector, Original_UP) * CFrame.new(0, 0, ZoomDistance) 
        Camera.CFrame = CamCF
        local Occlusion_RR_Func = function (CamSubjectPos:Vector3, NewCamPos:Vector3)
            local RayDirection = (  NewCamPos- CamSubjectPos).Unit
            local Occlusion_RR = Hitbox:Raycasting(CamSubjectPos, CamSubjectPos + RayDirection, ZoomDistance)
            if Occlusion_RR then 
                local Distance = (CamSubjectPos - Occlusion_RR.Position).Magnitude
                return Distance-1
            end
            return ZoomDistance
        end
        local FixCamera = function (NewLook:Vector3)
            --* in case Limits are activated
            local Direction = ProjectionVector(NewLook, UV3V.Value)
            local Occlusion_Distance = Occlusion_RR_Func(CamCF.Position, CamCF.Position + (-Direction))
            CamCF = CFrame.lookAlong(LookBody.Position + (- Direction *Occlusion_Distance), Direction)
        end
        local MouseMove = function (DeltaX:number, DeltaY:number)
            local NewCamCF = Camera.CFrame
            local CamSubjectPos = Character.PrimaryPart.Position + (LookBody.CFrame.RightVector*2 + LookBody.CFrame.UpVector *2)
            local UP:Vector3 = UV3V.Value
            
            local IRx = DeltaX/200
            local IRy = -DeltaY/200
            local NewLook:Vector3 = (NewCamCF.LookVector + (NewCamCF.RightVector * IRx) + (NewCamCF.UpVector * IRy) ).Unit
            local DotProd:number = NewLook:Dot(UP)
            if DotProd >= Limits or DotProd <= -Limits then return  end

            local NewCf = CFrame.lookAlong(CamSubjectPos, NewLook, UP)
            local Occlusion_Distance = Occlusion_RR_Func(CamSubjectPos, NewCamCF.Position)
            CamCF = NewCf * CFrame.new(0, 0, Occlusion_Distance)     
            CameraCF = CamCF
        end

        local D, S  = 0, 0.2
        local TI = TweenInfo.new(0.25, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, 0, false, 0)

        local TweenCam = function (DeltaTime:number)
            D += DeltaTime
            local Delta = UserInputService:GetMouseDelta()
            MouseMove(Delta.X, Delta.Y)
            if D <= S then return end
            D -= S
            task.synchronize()
            TweenService:Create(Camera, TI, {CFrame = CamCF}):Play()
        end
        RunService.RenderStepped:Connect(TweenCam)
        UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
        UV3V.Changed:Connect(function()  
            FixCamera(LookBody.CFrame.LookVector)
        end)
    end,
    function(Character) --* Menu
        -- local Args  = ...
        local UID = Character.Name
        local UV3V:Vector3Value = CollectionService:GetTagged(UID.."UV3V")[1]
        if not UV3V then warn("[Client] no UV3V detected: ", UID); return end    
        local LV3:Vector3Value = CollectionService:GetTagged(UID.."LV3")[1]
        if not LV3 then warn("[Client] no LV3 detected: ", UID); return end    
       
        local CameraLockBool = true
        Connections["M"] = function(actionName: string, inputState: Enum.UserInputState, inputObject: InputObject)
            if inputState == Enum.UserInputState.Begin and  CameraLockBool  then
                CameraLockBool = nil
                UserInputService.MouseBehavior = Enum.MouseBehavior.Default
                Gui_Handler.InventoryGuiBool()
                ShiftLockRBX:Disconnect()
            elseif inputState == Enum.UserInputState.Begin then
                CameraLockBool = true
                UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter 
                Gui_Handler.InventoryGuiBool()
                ShiftLockFunc(Character, UV3V, LV3)
            end
        end         
        ShiftLockFunc(Character, UV3V, LV3)
        ContextActionService:BindAction("M", Connections["M"] , false, Enum.KeyCode.M)    
    end,
    function(Character) --* Jump
        --TODO after New physics system is added rework this
        --TODO_Rework: only really need to fire to server sending nothing cos the upvector is tracked on server
        Connections["Jump"] = function(actionName: string, inputState: Enum.UserInputState, inputObject: InputObject)
            local Event = CharacterEvents.Jump
            if inputState == Enum.UserInputState.Begin then
                HumanoidMachine.TriggerAction(Character, Event, "Jump")     
            end
        end 
        ContextActionService:BindAction("Jump", Connections["Jump"] , false, Enum.KeyCode.Space)
    end,   
    function(...) --* Tool
        local Equipping
        Connections["Tool"] = UserInputService.InputBegan:Connect(function(a0: InputObject, a1: boolean)   
            if Equipping then return end
            if not ToolKeys[a0.KeyCode] then  return end
            local Frame = InputHandler["CurrentFrame"]
            if not  Frame then return end 
            local Event = CharacterEvents.Tool
            local CurrentFrame: number = Frame
            local FrameBuffer = buffer.create(2) -- gonna write key pressed u8
            buffer.writeu8(FrameBuffer, 0, CurrentFrame)
            local KeyPressed: number = NumToSymbol.GiveNum(a0.KeyCode.Name)
            buffer.writeu8(FrameBuffer, 1, KeyPressed) --*2 bytes 1 is the Key Pressed    
            Event:FireServer(FrameBuffer)
            Equipping = true
            task.wait(1.6)
            Equipping = nil            
        end)
    end,
    function(Character) --* WallRunning
        --TODO make a wallRun event on the server
        local WallRunUnix = DateTime.now().UnixTimestamp
        Connections["WallRun"] = function(actionName: string, inputState: Enum.UserInputState, inputObject: InputObject)
            if inputState == Enum.UserInputState.Begin then
                local CurrentUnix = DateTime.now().UnixTimestamp 
                if CurrentUnix - WallRunUnix < 1.5 then  return end 
                WallRunUnix = CurrentUnix 
                HumanoidMachine.TriggerAction(Character, CharacterEvents.WallRun, "WallRun", workspace.CurrentCamera.CFrame)         
            end
        end
        ContextActionService:BindAction("WallRun", Connections["WallRun"] , false, Enum.KeyCode.E)
    end,
    --TODO Q + M1, Q + M2 (2 different Dashes), M2 (Heavy)
    function(Character) --* Q + m1/m2 Dash
        InputHandler["DashNumber"] = 0
        Connections["QDash"] = function(actionName: string, inputState: Enum.UserInputState, inputObject: InputObject)
            if inputState == Enum.UserInputState.End then InputHandler.DashNumber -= 1;  return end
            if inputState == Enum.UserInputState.Begin then  
                InputHandler.DashNumber += 1
                Dash_Func(Character)    
                return 
            end
        end
        ContextActionService:BindAction("QDash", Connections["QDash"] , false, Enum.KeyCode.Q)
    end,
    function(Character) --* M2 
        InputHandler["DashNumber"] = 0
        Connections["M2"] = function(actionName: string, inputState: Enum.UserInputState, inputObject: InputObject)
            if inputState == Enum.UserInputState.End then  
                InputHandler.DashNumber -= 4
                return 
            end
            if inputState ~= Enum.UserInputState.Begin then  return end
            InputHandler.DashNumber += 4
            if Dash_Func(Character) then return end
        end
        ContextActionService:BindAction("M2", Connections["M2"] , false, Enum.UserInputType.MouseButton2)
    end,
    function(Character) --* M1
        InputHandler["DashNumber"] = 0
        Connections["M1"] = function(actionName: string, inputState: Enum.UserInputState, inputObject: InputObject)
            if inputState == Enum.UserInputState.End then  
                InputHandler.DashNumber -= 1
                return 
            end
            if inputState ~= Enum.UserInputState.Begin then  return end
            InputHandler.DashNumber += 1
            if Dash_Func(Character) then return end
                        
            local Frame = InputHandler["CurrentFrame"]
            if not Frame then return end
            local Event = CharacterEvents.M1
            local FrameLookBuffer = buffer.create(5)
            buffer.writeu8(FrameLookBuffer, 0, Frame) 
            local ForwardlookCF:CFrame = MovementHelper:GiveDirection(Character, 2) --* 2 = W
            local RX = ForwardlookCF.LookVector.X *10000
            local RZ = ForwardlookCF.LookVector.Z *10000
            buffer.writei16(FrameLookBuffer, 1, RX)
            buffer.writei16(FrameLookBuffer, 3, RZ)
            ClientCombatMachine.TriggerAction(Character, Event, "M1", Frame, FrameLookBuffer)
        end
        ContextActionService:BindAction("M1", Connections["M1"] , false, Enum.UserInputType.MouseButton1)
    end,
    function(...) --* Run
        local Run
        Connections["Run"] = function(actionName: string, inputState: Enum.UserInputState, inputObject: InputObject)
            if inputState ~= Enum.UserInputState.Begin then  return end
            local Frame = InputHandler["CurrentFrame"]
            if not  Frame then return end 
            local Event = CharacterEvents.Run
            local Character = InputHandler["Character"]
            local FrameLookBuffer = buffer.create(1)
            buffer.writeu8(FrameLookBuffer, 0, Frame)
            if Run then  
                Event = CharacterEvents.StopRun; Run = false
                ClientCombatMachine.TriggerAction(Character, Event, "StopRun", FrameLookBuffer) 
                return 
            end
            Run = true
            ClientCombatMachine.TriggerAction(Character, Event, "Run", FrameLookBuffer)
        end
        ContextActionService:BindAction("Run", Connections["Run"] , false, Enum.KeyCode.LeftShift)
    end,
    function(...) --* Block 
        --TODO ///////////////////////////////////////////// NEEDS TESTING///////////////////////////////////
        local Block
        Connections["Block"] = function(actionName: string, inputState: Enum.UserInputState, inputObject: InputObject)
            local Proceed = false
            if inputState == Enum.UserInputState.Begin then Proceed = true   end
            if inputState == Enum.UserInputState.End then Proceed = true  end
            if not Proceed then return end
            local Frame = InputHandler["CurrentFrame"]
            if not  Frame then return end 
            local Event = CharacterEvents.Block
            local Character = InputHandler["Character"]
            local FrameLookBuffer = buffer.create(5)
            buffer.writeu8(FrameLookBuffer, 0, Frame)            
            if Block then  
                Event = CharacterEvents.StopBlock; Block = false
                ClientCombatMachine.TriggerAction(Character, Event, "StopBlock", FrameLookBuffer)
                return 
            end
            Block = true
            local ForwardlookCF:CFrame = MovementHelper:GiveDirection(Character, 2) --* 2 = W
            local RX = ForwardlookCF.LookVector.X *10000
            local RZ = ForwardlookCF.LookVector.Z *10000
            buffer.writei16(FrameLookBuffer, 1, RX)
            buffer.writei16(FrameLookBuffer, 3, RZ)
            ClientCombatMachine.TriggerAction(Character, Event, "Block", FrameLookBuffer)
        end
        ContextActionService:BindAction("Block", Connections["Block"] , false, Enum.KeyCode.F)
    end
}
function InputHandler:GiveConnections(...) 
    for _, Connections in ConnectFuncs do Connections(...) end
end
function InputHandler:DisconnectConnections(TypeOfConnection: string?) task.synchronize()
    if not TypeOfConnection then
        for Key: string, Conns: ValueConnections in Connections do
            if typeof(Conns) == "RBXScriptConnection" then Conns:Disconnect()
            elseif typeof(Conns) == "table" then
                for _, SubConns in Conns do SubConns:Disconnect() end 
            end
            Connections[Key] = nil
        end
    else
        local ConnectionORTable = Connections[TypeOfConnection]
        if typeof(ConnectionORTable) == "RBXScriptConnection" then ConnectionORTable:Disconnect()
        else
            print("disconnected stuff for camera")
            for _, SubConns in ConnectionORTable do SubConns:Disconnect() end
        end
        Connections[TypeOfConnection]= nil
    end
end
function InputHandler:Unbind(actionName: string) ContextActionService:UnbindAction(actionName) 
    Connections[actionName] = nil
end

function InputHandler:StartTick()  --TODO remove potentially after new system added
    local TickDelta,  Step = 0, 0.08
    RunService.Heartbeat:ConnectParallel(function(a0: number)  
        TickDelta += a0
        if TickDelta >= Step then
            TickDelta = 0
            --TODO add input delat to everything
        end
    end)
end
return InputHandler
--[[ Info
This module handles Clients inputs only when they are spawned 
Connect to the CharacterEvents when Spawning in
]]