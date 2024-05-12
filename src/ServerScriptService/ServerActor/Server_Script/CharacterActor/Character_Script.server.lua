local SSS = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local CharacterActor = script.Parent
local ServerScript = SSS.Server.ServerActor.Server_Script
local MessageAPI = require(ServerScript.MessageAPI)
local SharedType = require(Shared.SharedType)
local HumanoidMachine = require(Shared.HumanoidMachine)
local Character_Controller = require(ServerScript.Character_Controller) 
local MovementLogic = require(ServerScript.Character_Controller.MovementLogic); MovementLogic.Init(Character_Controller)
local Character = workspace.Camera:FindFirstChild(CharacterActor.Name)
Character_Controller["Actor"] = CharacterActor
Character_Controller:InitEvents(CharacterActor.Name)

local Humanoid: SharedType.CustomHumanoid = HumanoidMachine:InitServerHumanoid(Character, require(ServerScript.Humanoid_Controller))
function GiveAnims(Humanoid) -- this is so ray movement works
    local AnimNamesTable: any = { "Jump", "Idle", "Walk", "Fall", "Landed" }
    for _ , Anims: string in AnimNamesTable do
        Humanoid[Anims] = { Play = function() end, Stop = function() end, Destroy = function() end, }
    end 
end
GiveAnims(Humanoid)
local ForwardActor, DownwardActor = MessageAPI.InitServerCharacter(CharacterActor)
Character_Controller["FA"] = ForwardActor
Character_Controller["DA"] = DownwardActor
CharacterActor:BindToMessage("Init", function(Data)
    ForwardActor:SendMessage("Init", Data)
end)
CharacterActor:BindToMessageParallel("DownNotHit", function()  
    -- In Air did not hit floor    

end)
CharacterActor:BindToMessageParallel("ForwardHit", function(...: any) 
    --Hit A wall
end)


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