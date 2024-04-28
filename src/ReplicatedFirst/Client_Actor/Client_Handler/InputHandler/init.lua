--!native
type ValueConnections = RBXScriptConnection | { RBXScriptConnection } | (... any) -> nil
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
-- local player = game.Players.LocalPlayer

local Shared = ReplicatedStorage.Shared
local SharedTypes = require(Shared.SharedType)
local Task = require(Shared.CustomTask)
type CustomHumanoid = SharedTypes.CustomHumanoid

local EventHandler = require(script.Parent.Parent.Event_Handler)
local CameraHandler = require(script.Camera_Handler)
local Movement_Handler = require(script.Parent.Parent.Movement_handler)
local MoveKeys = {
    Enum.KeyCode.W, Enum.KeyCode.A, Enum.KeyCode.S, Enum.KeyCode.D,
}
local Connections: { [string]:  ValueConnections } = {}
local InputHandler = {}
local CharacterEvents: SharedTypes.CharacterEvents =  EventHandler["Events"]  
function InputHandler:Init(CustomHumanoid: CustomHumanoid)
    InputHandler["Humanoid"] = CustomHumanoid
end
local InputTable = {}; local  Input: Enum.KeyCode
function UpdateKeyCode(T) for KeyCode, _  in T do  Input = KeyCode end; return Input end
function AddKeyMove(KeyCode: Enum.KeyCode)
    local Key = KeyCode.Name
    if not InputTable[KeyCode] then InputTable[KeyCode] = true end
    local MovementTracker = InputHandler["Humanoid"] 
    if string.find(MovementTracker.MoveKeys, Key) then  return MovementTracker.MoveKeys end
    MovementTracker.MoveKeys = MovementTracker.MoveKeys.. Key
    return MovementTracker.MoveKeys
end
function RemoveKeyMove(KeyCode: Enum.KeyCode) 
    local Key = KeyCode.Name
    local MovementTracker = InputHandler["Humanoid"]
    MovementTracker.MoveKeys = string.gsub(MovementTracker.MoveKeys, Key, "")
    InputTable[KeyCode] = nil
    return MovementTracker.MoveKeys
end
function GiveKeyMove() return InputHandler["Humanoid"].MoveKeys  end
function B_() return InputHandler["Humanoid"].MoveKeys end
local KeyMoveFunctions = { ["Begin"] =AddKeyMove, ["End"] =RemoveKeyMove, ["Cancel"] =B_ , ["Change"] =B_ , ["None"] =B_ }
local HOLD
local ConnectFuncs = {
    function(...)
        Connections["Move"] = function(actionName: string, inputState: Enum.UserInputState, inputObject: InputObject) 
            local Event = CharacterEvents.Walk
            local function PressnHold()
                if HOLD then Task.Cancel(HOLD) end
                local MovementTracker: string =  KeyMoveFunctions[inputState.Name](inputObject.KeyCode)
                
                Movement_Handler:Walk(InputHandler["Character"], Event, MovementTracker)
                Input = UpdateKeyCode(InputTable)
                task.synchronize()
                if Input and  UserInputService:IsKeyDown(Input) then 
                    HOLD = Task.DelayParallel(0.5, PressnHold)
                    return
                end
                InputTable = {}
            end
            PressnHold()
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
            elseif inputState == Enum.UserInputState.Begin then
                Connections["Camera"] = CameraHandler:Start(Args)                
            end
        end 
        ContextActionService:BindAction("M", Connections["M"] , false, Enum.KeyCode.M)    
    end,
    function(...)
        Connections["Jump"] = function(actionName: string, inputState: Enum.UserInputState, inputObject: InputObject)
            local Event = CharacterEvents.Jump
            if inputState == Enum.UserInputState.Begin then
                Movement_Handler:Jump(InputHandler["Character"], Event,  GiveKeyMove())
            end
            Task.DelayParallel(0.5, function() Movement_Handler.CheckPlayerCentrePosNetwork() end)
        end 
        ContextActionService:BindAction("Jump", Connections["Jump"] , false, Enum.KeyCode.Space)
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
            for _, SubConns in ConnectionORTable do SubConns:Disconnect() end 
        end
        Connections[TypeOfConnection]= nil
    end
end
function InputHandler:Unbind(actionName: string) ContextActionService:UnbindAction(actionName) 
    Connections[actionName] = nil
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

