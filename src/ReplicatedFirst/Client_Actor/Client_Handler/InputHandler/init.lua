--[[///////////////////TODO
Change press and gold to only change direction and return its value
]]

--!native

type ValueConnections = RBXScriptConnection | { RBXScriptConnection } | (... any) -> nil
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
-- local player = game.Players.LocalPlayer

local Shared = ReplicatedStorage.Shared
local SharedTypes = require(Shared.SharedType)
local Task = require(Shared.CustomTask)
type CustomHumanoid = SharedTypes.CustomHumanoid

local EventHandler = require(script.Parent.Parent.Event_Handler)
local CameraHandler = require(script.Camera_Handler)
local Movement_Handler = require(script.Parent.Parent.Movement_handler)
local MovementHelper = require(Shared.MovementHelper)
local HumanoidMachine = require(Shared.HumanoidMachine)

local MoveKeys = {
    Enum.KeyCode.W, Enum.KeyCode.A, Enum.KeyCode.S, Enum.KeyCode.D,
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
        local Action = {
            Func = function()end,
            Values = {Event}
        }
    end
    return 
end
function GiveKeyMove() return Concatenate(KeyHolder)  end
function B_() return Concatenate(KeyHolder) end
local function PressnHold(Event)
    local Concat = Concatenate(KeyHolder)
    -- Movement_Handler:Walk(InputHandler["Character"], Event, Concat)
    return MovementHelper:GiveDirection(InputHandler["Character"], Concat)
end
local InputStateFunctions = { 
    ["Begin"] =AddKeyMove,
    ["End"] =RemoveKeyMove, 
    ["Cancel"] =B_ ,
    ["Change"] =B_ ,
    ["None"] =B_ 
}
local ConnectFuncs = {
    function(...)
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
    function(...) Connections["Camera"] = CameraHandler:Start(...)
    end,
    function(...)
        local Args  = ...
        Connections["M"] = function(actionName: string, inputState: Enum.UserInputState, inputObject: InputObject)
            if inputState == Enum.UserInputState.Begin and Connections["Camera"] then
                InputHandler:DisconnectConnections("Camera")
                task.defer(function()
                    UserInputService.MouseBehavior = Enum.MouseBehavior.Default
                end)
            elseif inputState == Enum.UserInputState.Begin then
                Connections["Camera"] = CameraHandler:Start(Args)          
                UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter      
            end
        end 
        ContextActionService:BindAction("M", Connections["M"] , false, Enum.KeyCode.M)    
    end,
    function(...)
        --
        local WallWalk = DateTime.now().UnixTimestampMillis
        Connections["Jump"] = function(actionName: string, inputState: Enum.UserInputState, inputObject: InputObject)
            local Event = CharacterEvents.Jump
            if inputState == Enum.UserInputState.Begin then
                local Concat = GiveKeyMove()
                local CurrentTime = DateTime.now().UnixTimestampMillis
                if CurrentTime -WallWalk >=500 then
                    WallWalk = CurrentTime
                    -- wall run
                    -- CF:
                    return
                end
                Movement_Handler:Jump(InputHandler["Character"], Event,  GiveKeyMove())
            end
            -- Task.DelayParallel(0.5, function() Movement_Handler.CheckPlayerCentrePosNetwork() end)
        end 
        ContextActionService:BindAction("Jump", Connections["Jump"] , false, Enum.KeyCode.Space)
    end
}
--[[ WallRun Turning Body
local raycastResult =  -- assume you've set up the raycast correctly
local normal = raycastResult.Normal
-- Create a look direction based on the normal
local lookDir = Body.LookVector -- assuming your character's up direction is Y-axis
-- Create a new CFrame that orients the character to the wall
local wallCFrame = CFrame.lookAt(raycastResult.Position, raycastResult.Position + lookDir, normal)

-- Apply the new CFrame to your character
character.HumanoidRootPart.CFrame = wallCFrame
]]
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

local TickFunc, EventTickFunc
function InputHandler:StartTick()  
    -- local InputEvents = {}
    -- local TickDelta,  Step = 0, 0.0332
    -- TickFunc = RunService.Heartbeat:ConnectParallel(function(a0: number)  
    --     TickDelta += a0
    --     if TickDelta >= Step then
    --         TickDelta = 0
    --         local T = TickInputs
    --         for StringIndex, Action: action in T do 
    --             local Dir = Action.Func( unpack(Action.Values) )
    --             table.insert(InputEvents, Dir)
    --         end
    --     end
    -- end)
    local TickDelta,  Step = 0, 0.08
    EventTickFunc = RunService.Heartbeat:ConnectParallel(function(a0: number)  
        TickDelta += a0
        if TickDelta >= Step then
            TickDelta = 0
            --TODO fire LatestDir
            local T = TickInputs
            local LatestDir
            for StringIndex, Action: action in T do 
                local Dir = Action.Func( unpack(Action.Values) )
                LatestDir = Dir
            end
            if not LatestDir then return end
           
            local Character: Model = InputHandler["Character"]
            -- local PosToSend: Vector3 = Movement_Handler:Walk(Character, LatestDir)
            HumanoidMachine.TriggerAction(Character, CharacterEvents.Walk, "StartWalk", LatestDir)
            
            -- InputEvents = {} -- cleanup
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

