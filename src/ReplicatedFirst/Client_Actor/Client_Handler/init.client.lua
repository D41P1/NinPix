task.wait(2)
local CharacterActors = workspace:WaitForChild("WorkSpaceFolder").CharacterActors
local player: Player = game.Players.LocalPlayer
local ServerActor: Actor = CharacterActors:WaitForChild(player.Name)
local Children = ServerActor:GetChildren()
local CharacterEvents = Children[2]
-- local ClientActor:  Actor = script.Parent -- might use for other stuff later
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared

local EventHandler = require(script.Parent.Event_Handler)
local T = {}; for _, Event in CharacterEvents:GetChildren() do T[Event.Name] = Event  end
EventHandler["Events"] = T

local SharedType = require(Shared.SharedType)
local AnimHandler = require(Shared.AnimHandler)   
local InputHandler = require(script.InputHandler)
local CharacterHandler = require(script.Character_Handler)

CharacterHandler["ServerActor"] = ServerActor
InputHandler["ServerActor"] = ServerActor
AnimHandler:InitAnimTypes("Humanoid")
CharacterHandler.Init()

local Character,  CustomHumanoid: SharedType.CustomHumanoid= CharacterHandler.Spawn(player)
InputHandler["Character"] = Character

InputHandler:Init(CustomHumanoid)
InputHandler:GiveConnections(Character)
CustomHumanoid.Idle:Play()



--////////////////////////////////////////////// REMOVE LATER /////////////////////////////////////////////
--////////////////////////////////////////////////////////////

