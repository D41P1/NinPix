task.wait(1)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared
-- local WS = require(Shared.Workspace);
-- local WorkS: WS.workspace = workspace 
local RP = require(Shared.ReplicatedStorage); local RepStorage: RP.ReplicatedStorage = ReplicatedStorage
local CharacterActors = workspace:WaitForChild("WorkSpaceFolder").CharacterActors
local player: Player = game.Players.LocalPlayer
local Character
local ServerActor: Actor = CharacterActors:WaitForChild(player.Name)
local CurrentNetworkPartitionEvent: UnreliableRemoteEvent
local Connected: RBXScriptConnection?

-- local HitBox = require(Shared.Hitbox)
local Map_Manager = require(Shared.Map_Manager)
local Event_Manager = require(Shared.Event_Manager)
local Checks = require(script.Checks)
local NetworkHandler = require(script.NetworkHandler)
local NetFunctions = require(script.NetworkFunctions)


local NetWorkHashMap = Map_Manager:GetMapType("NetworkHashMap")
local SectionHashMap = Map_Manager:GetMapType("SectionHashMap", 4096)
local RenderHashMap = Map_Manager:GetMapType("RenderHashMap")
local Character_Handler = {}
Character_Handler.InitChecks = Checks.InitChecks
function Character_Handler:Spawn()
    Character = RepStorage.Character.PixelDummy:Clone()
    local PixelCharacter: RP.PixelDummy = Character
    Character.Parent = ServerActor
    
    local RenderPartition = player:GetAttribute("RenderPartition")
    local Section = player:GetAttribute("Section")
    local SpawnPos = RenderHashMap[Section][RenderPartition]  -- TODO change this to attribute
	local FinalPos = SpawnPos + Vector3.new(0, 2.7, 0)
	Character:PivotTo(CFrame.new(FinalPos))
    return PixelCharacter    
end
function NetworkCaller(BufferArgs: buffer)
    --TODO call functions from networkFunctions 
    -- Decompress in networkfunctions NOT HERE
    NetFunctions:Caller(BufferArgs) 
end
function Character_Handler:Init()
    local CurrentSection = Map_Manager:GetClosestSection(Character, SectionHashMap)
    NetworkHandler:InitEvents(CurrentSection)
    local NetworkPartitionNumber = player:GetAttribute("NetworkPartition")    
    local NewNetworkEvent = NetworkHandler:CheckNetworkPartition(NetworkPartitionNumber)
    if NewNetworkEvent then 
        Connected = NewNetworkEvent.OnClientEvent:Connect(NetworkCaller) 
        CurrentNetworkPartitionEvent = NewNetworkEvent
    end    
end 

function Character_Handler:CheckPlayerCentrePosNetwork()
    local ClosestNetworkPartitionNumber = Map_Manager:NetworkPartitionCentrePosCheck(Character, NetWorkHashMap)
    NetworkHandler:CheckNetworkPartition(ClosestNetworkPartitionNumber)
end




return Character_Handler

--[[ Info
    This Mod is for Creating the Characters for both players, NPCs and managing them
    This Mod will also be the NPC_Handler -- becuase players and NPCs are pretty much going to be treated the same
    Connecting and disconnecting to the NetworkPartition events
    type CharactersAvatar = {
        Hair, Eyes, Face, Shirt, Pants,
        Armour?, Accessories?,
    }
    
]]
--[[ Modules needed:
    MapManager
    EventManager
    CustomTask
    RayMovement_Manager
    Animation_Manager
    --has submodules
]]
--[[   
    -- have all the other players character avatars stored as clones in a dictionary
]]
--[[Upon joining the game  {    
        From Server {
            Data for other Characters {
                CharactersAvatar,
                Pos ,
                CurrentAnim,
                Name,
            } 
            their MapLocation of the players? only in the same NetworkPartition as them --512x512
            Include current NPCs {
                NameOfNPC,
            }
        }
        Client's and their own CharacterAvatar
        Connected PlayerLeave function { 
            --Cleanup {
                Remove from the Avatar dictionary
            }
        }
        From other Modules: { 
            The Section and Partition Client is currently in
            Manage Connections of NetworPartition -- Network_Handler
        }
    }
]]
--[[During the Game continuously {
        From Server {
            For OtherCharacters {
                Pos ,
                CurrentAnim,
                Name,
            }
        }
        From Client {
            Keep State in sync with Server StateMachine -- No need to remote cos Client will keep in check with the server
            For ALL Characters {
                Play anims  --  Animation_handler 
                Keep track of movement  -- RayMovement_Manager
            }
        }
    }
]]