--!native
type ValueConnections = RBXScriptConnection | { RBXScriptConnection } | (... any) -> nil
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
-- local player = game.Players.LocalPlayer

local Clientactor  = script.Parent.Parent
local Shared = ReplicatedStorage.Shared

local Gui_Handler = require(script.Parent.Gui_Handler)
local NumToSymbol = require(Shared.NumToSymbol)
local SharedTypes = require(Shared.SharedType)
-- local Task = require(Shared.CustomTask)
type CustomHumanoid = SharedTypes.CustomHumanoid

local EventHandler = require(Clientactor.Event_Handler)
local ClientCombatMachine = require(Clientactor.ClientCombatMachine)
local Movement_Handler = require(Clientactor.Movement_handler)
local MovementHelper = require(Shared.MovementHelper)
local HumanoidMachine = require(Shared.HumanoidMachine)

local MoveKeys = {
    Enum.KeyCode.W, Enum.KeyCode.A, Enum.KeyCode.S, Enum.KeyCode.D,
}
-- local ToolKeys = {
--     Enum.KeyCode.One, Enum.KeyCode.Two, Enum.KeyCode.Three, Enum.KeyCode.Four,
--     Enum.KeyCode.Five, Enum.KeyCode.Six, Enum.KeyCode.Seven, Enum.KeyCode.Eight,
-- }
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
local TickInputs = {}
local KeyHolder = {}
function Concatenate(Table) 
    local S = ""
    for _, String in Table do
        S = S.. String
    end
    return S
end
function AddKeyMove(KeyCode: Enum.KeyCode, Action)
    local Key = KeyCode.Name
    KeyHolder[Key] = Key
    local Concat = Concatenate(KeyHolder)    
    TickInputs["Move"] = Action
    return Concat
end
function RemoveKeyMove(KeyCode: Enum.KeyCode) 
    local Key = KeyCode.Name
    KeyHolder[Key] = nil
    local Fused = Concatenate(KeyHolder)
    if Fused == "" then    
        TickInputs["Move"] = nil
        local Character: Model = InputHandler["Character"]
        local Event = CharacterEvents.StopWalk
        HumanoidMachine.TriggerAction(Character, Event, "StopWalk")
        -- local Action = {
        --     Func = function()end,
        --     Values = {Event}
        -- }
    end
    return 
end
function GiveKeyMove() return Concatenate(KeyHolder)  end
function B_() return Concatenate(KeyHolder) end
local function PressnHold(Event)
    local Concat = Concatenate(KeyHolder)
    -- Movement_Handler:Walk(InputHandler["Character"], Event, Concat)
    return MovementHelper:GiveDirection(InputHandler["Character"], Concat) :: CFrame
end
local InputStateFunctions = { 
    ["Begin"] =AddKeyMove,
    ["End"] =RemoveKeyMove, 
    ["Cancel"] =B_ ,
    ["Change"] =B_ ,
    ["None"] =B_ 
}
local ConnectFuncs = {
    function(...) --* Move
        Connections["Move"] = function(actionName: string, inputState: Enum.UserInputState, inputObject: InputObject) 
            local Event = CharacterEvents.Walk
            local Action = {
                Func = PressnHold,
                Values = {Event}
            }
            InputStateFunctions[inputState.Name](inputObject.KeyCode, Action, Event)
        end
        ContextActionService:BindAction("Move", Connections["Move"] , false, unpack(MoveKeys))    
    end,
    function(...) --* Camera 
        -- Connections["Camera"] = CameraHandler:Start(...)
    end,
    function(...) --* Menu
        local Args  = ...
        local CameraLockBool 
        Connections["M"] = function(actionName: string, inputState: Enum.UserInputState, inputObject: InputObject)
            if inputState == Enum.UserInputState.Begin and not CameraLockBool  then
                -- InputHandler:DisconnectConnections("Camera")
                CameraLockBool = true
                UserInputService.MouseBehavior = Enum.MouseBehavior.Default
                Gui_Handler.InventoryGuiBool()
            elseif inputState == Enum.UserInputState.Begin then
                CameraLockBool = nil
                -- Connections["Camera"] = CameraHandler:Start(Args)
                workspace.CurrentCamera.CameraType = Enum.CameraType.Custom          
                UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter 
                Gui_Handler.InventoryGuiBool()
            end
        end 
        ContextActionService:BindAction("M", Connections["M"] , false, Enum.KeyCode.M)    
    end,
    function(...) --* Jump
        Connections["Jump"] = function(actionName: string, inputState: Enum.UserInputState, inputObject: InputObject)
            local Event = CharacterEvents.Jump
            local Character: Model = InputHandler["Character"]
            if inputState == Enum.UserInputState.Begin then
                local Concat = GiveKeyMove()
                --[[ -- failed wallrunning
                if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
                    Movement_Handler:Jump(Character, Event, Concat, true)
                    return    
                end
                
                ]]
                Movement_Handler:Jump(Character, Event,  Concat)
            end
        end 
        ContextActionService:BindAction("Jump", Connections["Jump"] , false, Enum.KeyCode.Space)
    end,   
    function(...) --* Tool
        --TODO unbind this and make it UserInputService cos then Inventory Equip will not work
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
        --[[ --* OLD
        Connections["Tool"] = function(actionName: string, inputState: Enum.UserInputState, inputObject: InputObject)
            if inputState ~= Enum.UserInputState.Begin then  return end
            local Frame = InputHandler["CurrentFrame"]
            if not  Frame then return end 
            local Event = CharacterEvents.Tool
            local CurrentFrame: number = Frame
            local FrameBuffer = buffer.create(2) -- gonna write key pressed u8
            buffer.writeu8(FrameBuffer, 0, CurrentFrame)
            ClientCombatMachine.TriggerAction(InputHandler["Character"], Event, "ToolHandle", inputObject.KeyCode.Name, FrameBuffer)
            --TODO event fires go through client combat machine first
        end
        -- ContextActionService:BindAction("Tool", Connections["Tool"] , false, unpack(ToolKeys) )
        
        ]]
    end,
    --TODO M1, M2, Block, Roll, Run
    function(...) --* M1
        Connections["M1"] = function(actionName: string, inputState: Enum.UserInputState, inputObject: InputObject)
            if inputState ~= Enum.UserInputState.Begin then  return end
            local Frame = InputHandler["CurrentFrame"]
            if not Frame then return end
            local Event = CharacterEvents.M1
            local Character = InputHandler["Character"]
            local FrameLookBuffer = buffer.create(5)
            buffer.writeu8(FrameLookBuffer, 0, Frame) 
            local ForwardlookCF:CFrame = MovementHelper:GiveDirection(Character, "W")
            local RX = ForwardlookCF.LookVector.X *10000
            local RZ = ForwardlookCF.LookVector.Z *10000
            buffer.writei16(FrameLookBuffer, 1, RX)
            buffer.writei16(FrameLookBuffer, 3, RZ)
            ClientCombatMachine.TriggerAction(Character, Event, "M1", Frame, FrameLookBuffer)
            --TODO event fires go through client combat machine first
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
            local ForwardlookCF:CFrame = MovementHelper:GiveDirection(Character, "W")
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
type action = { Func: (any) -> (...any), Values: {(RemoteEvent | UnreliableRemoteEvent)?} }
function InputHandler:StartTick()  
    local TickDelta,  Step = 0, 0.08
    RunService.Heartbeat:ConnectParallel(function(a0: number)  
        TickDelta += a0
        if TickDelta >= Step then
            TickDelta = 0
            local T = TickInputs
            local RelativeDirCF: CFrame?
            for StringIndex, Action: action in T do 
                local Dir = Action.Func( unpack(Action.Values) )
                RelativeDirCF = Dir
            end
            if not RelativeDirCF then return end
            local Character: Model = InputHandler["Character"]
            HumanoidMachine.TriggerAction(Character, CharacterEvents.Walk, "StartWalk", RelativeDirCF)
        end
    end)
end
return InputHandler
--[[ Info
This module handles Clients inputs only when they are spawned 
Connect to the CharacterEvents when Spawning in
]]
--[[Modules needed
Event_Manager 
Movement_Handler
]]
--[[
    Current Inputs: {
        Movement: W A S D
    }
    ModuleScript Format:
    local CharacterEvents -- events made from the Character Controller script   
    local MovementEvent: Unreliable -- CharacterEvents.MovementEvent  
    local Movement_Handler
    local Event_Manager 
    //////////////////////////////////////MODULESCRIPT./////////////////////////
    local Inputlogic = require(script.MovementHandler)

    local InputHandler = {}
    local MovementKeys = {}
    function CalculateMovement()
        for loop through MovementKeys
        and Concat the inputs = Key 
        Inputlogic:CallLogic(Key)  
    end
    MovementTracker = {
        ["W"] = function()
            if MovementKeys["W"] then MovementKeys["W"] = nil end
            MovementKeys["W"] = ""
            CalculateMovement()
        end
        ["A"]
        ["WA"]
    } -- could be a submodule
    
    inputhandler["MovementPress"] = userinput connect function(key) 
        if not  MovementTracker[key] then return end
        MovementTracker[key]()
    end)
    inputhandler["MovementRelease"] = userinput connect function(key) 
        if not  MovementTracker[key] then return end
        MovementTracker[key]()
    end)

    function InputHandler:GiveConnections()
        -- so you can disconnect Keybinds if need be from another table
        return inputtable    
    end)
    return InputHandler
]]

