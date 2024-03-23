local Players = game:GetService("Players")
local PhysicsService = game:GetService("PhysicsService")
local Shared = game:GetService("ReplicatedStorage").Shared
local CharacterActors = workspace.WorkSpaceFolder.CharacterActors
local StarterCharacterScripts = script.StarterCharacterScripts
PhysicsService:RegisterCollisionGroup("Characters")
PhysicsService:CollisionGroupSetCollidable("Characters", "Characters", false)

local Cleanup_Manager = require(Shared.Cleanup_Manager)
local Attributes_Controller = require(script.Attributes_Controller)
local Spawning = require(script.Character_Controller.Spawning)
local Network_Controller = require(script.Network_Controller)
-- local Task = require(ReplicatedStorage.Shared.CustomTask)

Network_Controller:InitNetworkPartitionEvents()

Players.CharacterAutoLoads = false
Players.PlayerAdded:Connect(function(player)
    -- Clone and Enable the script and SetAttribute (PlayerName) -- see character script
    Attributes_Controller:InitAttributes(player, {}, true)
    local CharacterScript: Script = StarterCharacterScripts.Character_Script:Clone()
    CharacterScript:SetAttribute("PlayerName", player.Name)
    CharacterScript.Enabled = true  
    CharacterScript.Parent = CharacterActors 
    local SpawnPos: Vector3? = Spawning:Spawn("Humanoid")
    player:SetAttribute("SpawnPos", SpawnPos)
    --grab data here and send to Init_Handler with Task.Delay
end)
Players.PlayerRemoving:ConnectParallel(function(player: Player)  
    Cleanup_Manager:Start()
end)
--[[ Modules needed
CustomTask
Data_Controller
Character_Controller
]]
--[[type Data Template
{
    MapLocation = { -- spawn them at the centre of partition
        Partition: number
        Section: number
    }
    CharactersAvatar = {
        Hair, Eyes, Face, Shirt, Pants,
        Armour?, Accessories?,
    }
    Inventory {
        [ItemName]: number -- number of items
    }
}

]]

--[[
    when player joins:
    get playerdata -> EventManager write buffer -> Client 
    StarterCharacterScripts.Character_Script {
        Clone and enable the script 
        and parent to the CharacterActorsFolder
    } 
    
]]