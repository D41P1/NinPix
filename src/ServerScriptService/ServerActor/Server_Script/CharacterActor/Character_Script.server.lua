local SSS = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared
local SharedType = require(Shared.SharedType)
local HumanoidMachine = require(Shared.HumanoidMachine)
local CharacterScripts = SSS.Server.ServerActor.Server_Script
local Character_Controller = require(CharacterScripts.Character_Controller) 
local MovementLogic = require(CharacterScripts.Character_Controller.MovementLogic); MovementLogic.Init(Character_Controller)
local CharacterActor: Actor = script.Parent
local Character = workspace.Camera:FindFirstChild(CharacterActor.Name)
Character_Controller["Actor"] = CharacterActor
Character_Controller:InitEvents(CharacterActor.Name)
local Humanoid = HumanoidMachine:InitServerHumanoid(Character, require(CharacterScripts.Humanoid_Controller))

function GiveAnims(Humanoid) -- this is so ray movement works
    local AnimNamesTable: any = { "Jump", "Idle", "Walk", "Fall", "Landed" }
    for _ , Anims: string in AnimNamesTable do
        Humanoid[Anims] = { Play = function() end, Stop = function() end, Destroy = function() end, }
    end 
end
GiveAnims(Humanoid)
--[[ Events
    W,
    A,
    S,
    D
    Jump,
    M1,
    M2,
    F
]]
--[[
    create Actor(s) parent to Actors Folder
    Create CharacterEvents --Send TableOfEventNames To Character_Controller
    init CustomHumanoid
    connect functions to events through Character_Controller Module
    init attributes
]]