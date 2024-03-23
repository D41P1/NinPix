-- local CharacterActors = workspace:WaitForChild("WorkSpaceFolder").CharacterActors
-- local player: Player = game.Players.LocalPlayer
-- local ServerActor: Actor = CharacterActors:WaitForChild(player.Name)

-- local ClientActor:  Actor = script.Parent -- might use for other stuff later
local ReplicatedStorage = game:GetService("ReplicatedStorage")
-- local Shared = ReplicatedStorage:WaitForChild("Shared")
-- local WS = require(Shared.Workspace); local WorkS: WS.workspace = workspace 
-- local RP = require(Shared.ReplicatedStorage); local RepStorage: RP.ReplicatedStorage = ReplicatedStorage
-- local Task = require(ReplicatedStorage.Shared.CustomTask)

local InputHandler = require(script.InputHandler)
-- local Map_Manager = require(Shared.Map_Manager)
local CharacterHandler = require(script.Character_Handler)

local Character = CharacterHandler:Spawn()
CharacterHandler:Init()

InputHandler:GiveConnections(Character)

--////////////////////////////////////////////// REMOVE LATER /////////////////////////////////////////////
--////////////////////////////////////////////////////////////




--[[ TODO
--//// Init phase
Connect to the Data Event 
BindMessage Actor 
Start Init input handler
--/// Inputs
Client inputs pseudo code
]]

