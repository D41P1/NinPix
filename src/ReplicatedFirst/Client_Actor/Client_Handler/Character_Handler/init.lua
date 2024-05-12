local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Shared = ReplicatedStorage.Shared
local player: Player = game.Players.LocalPlayer
task.wait(2)
local CharacterActors = workspace.WorkSpaceFolder.CharacterActors
local Character
local ServerActor: Actor = CharacterActors:WaitForChild(player.Name)
local ClientActor = script.Parent.Parent

-- local CurrentNetworkPartitionEvent: UnreliableRemoteEvent
local OtherPlrs = {}
local Map_Manager = require(Shared.Map_Manager)
local SharedType = require(Shared.SharedType); 
local Cleanup_Manager = require(Shared.Cleanup_Manager)
local Task = require(Shared.CustomTask)
local HumanoidMachine = require(Shared.HumanoidMachine)
local AnimHandler = require(Shared.AnimHandler)   


local NetworkHandler = require(script.NetworkHandler)
local AttributeHandler = require(script.Attribute_Handler)
local Checks = require(script.Checks)
local MyUID = player:GetAttribute("UID")
local NetWorkHashMap = Map_Manager:GetMapType("NetworkHashMap")
-- local RenderHashMap = Map_Manager:GetMapType("RenderHashMap")
local  Character_Handler = {} 
local MT = setmetatable({}, {
    __call = function(_, Data) Character_Handler[Data.Func](Data) end
})
Character_Handler.InitChecks = Checks.InitChecks
function Character_Handler.Init()
    local NetworkPartitionNumber = player:GetAttribute("NetworkPartition")    
    Map_Manager.SetClosestNetPartition(NetworkPartitionNumber)
    ReplicatedStorage.FromServer.NotifyEvent.OnClientEvent:Connect(NetworkHandler.Receiver)
end 
function Character_Handler.Spawn(player: Player)
    local PlayerName = player.Name
    local UID = player:GetAttribute("UID")
    Character = ReplicatedStorage.Character.PixelDummy:Clone()
    local PixelCharacter: SharedType.PixelDummy = Character
    Character.Name = UID
    Character.Parent = ServerActor
    AttributeHandler:SetTheAttributes(Character, "Humanoid")
    local Hip = Character:GetAttribute("Hip")    
    local NetworkPartition = player:GetAttribute("NetworkPartition")
    local SpawnPos = NetWorkHashMap[NetworkPartition]  
    local FinalPos = SpawnPos + Vector3.new(0, Hip, 0)
	Character:PivotTo(CFrame.new(FinalPos))
    Character:SetAttribute("NetworkPartition", NetworkPartition)
    local Humanoid: SharedType.CustomHumanoid =  HumanoidMachine:InitHumanoid(Character)
    OtherPlrs[UID] = {
        ["Actor"] = ClientActor,
        ["Avatar"] = Character,
        ["Humanoid"] = Humanoid
    }
    GiveAnims(Humanoid)
    return PixelCharacter, Humanoid
end
function GiveAnims(Humanoid: SharedType.CustomHumanoid)
    local Animator: Animator = Humanoid.Animator 
    local AnimsLoaded = AnimHandler:loadAnims(Animator, "Humanoid")
    local AnimNamesTable: any = {
        ["HumanoidJump"] = "Jump", ["HumanoidIdle"] = "Idle", ["HumanoidWalk"] = "Walk",
        ["HumanoidFall"] = "Fall", ["HumanoidLanded"] = "Landed"
    }
    for _ , Anims: AnimationTrack in AnimsLoaded do
        local AnimName = AnimNamesTable[Anims.Name]
        if string.match(Anims.Name, AnimName) then Humanoid[AnimName] = Anims end    
    end 
end
function Character_Handler.InitChar(Data) task.desynchronize() 
    local UID: string = Data.UID
    if UID == MyUID then return end -- Clients character, look at Spawn Func !
    local NetPartNumber = Data.NetPartNumber
    local Hip: Vector3 = Vector3.new(0, Data.HipHeight, 0)
    local Pos: Vector3 = Data.CurrentPos or NetWorkHashMap[ NetPartNumber ]
    local CF: CFrame = CFrame.new(Pos + Hip)  
    task.synchronize()
    local OtherActor = script.Parent.Parent.OtherActor:Clone()
    local OtherCharacterScript = OtherActor.OtherCharacter
    OtherCharacterScript.Enabled = true
    OtherActor.Name = UID
    Cleanup_Manager:Profile(UID)
    
    local Avatar = ReplicatedStorage.Character.PixelDummy:Clone()
    Avatar:SetAttribute("UID", UID)
    Avatar:SetAttribute("Hip", Data.HipHeight)
    Avatar:PivotTo(CF)
    Avatar:AddTag(UID)
    Avatar.Name = UID
    
    Avatar.Parent = CharacterActors
    OtherActor.Parent  = ClientActor
    OtherPlrs[UID] = {
        ["Actor"] = OtherActor, ["Avatar"] = Avatar,
        --TODO avatar data 
    }
    Task.DelayParallel(1, function() print("fired to other character"); Data.Func = "Load"; OtherActor:SendMessage("Info", Data)end)
    Cleanup_Manager:Insert(UID, Avatar)
    Cleanup_Manager:Insert(UID, OtherPlrs[UID])
    Cleanup_Manager:Insert(UID, OtherActor)
    print("made Character: ", OtherPlrs)
end
type Profile = {
    UID: string,
    Actor: Actor,
    Avatar: Model,
    Humanoid: SharedType.CustomHumanoid
}
function Character_Handler.OtherCharMove(Data)
    local UID: string = Data.UID
    local OtherProfile: Profile = OtherPlrs[UID]
    if UID== MyUID  then   return end 
    Data.Func = "TriggerAction"     
    Data.Action = "StartWalk"
    OtherProfile.Actor:SendMessage("Info", Data)
end
function Character_Handler.StopMove(Data)
    local UID: string = Data.UID
    local OtherProfile: Profile = OtherPlrs[UID]
    local Avatar = OtherProfile.Avatar.PrimaryPart
    local Pos:Vector3 = Data.CurrentPos 
    if (Avatar.Position - Pos).Magnitude > 1 then Avatar.Position = Pos end
    if UID== MyUID then 
        local Humanoid: SharedType.CustomHumanoid = HumanoidMachine[UID]
        if Humanoid.Falltracker then Humanoid.Falltracker:Pause(); Humanoid.Falltracker:Destroy() end
        HumanoidMachine.TriggerAction(Character, nil, "StopWalk")        
        return  
    end -- IMPORTANT
    Data.Func = "TriggerAction"
    Data.Action = "StopWalk"
    OtherProfile.Actor:SendMessage("Info", Data)
end
function Character_Handler.Jump(Data)
    local UID: string = Data.UID
    local OtherProfile: Profile = OtherPlrs[UID]
    local Avatar = OtherProfile.Avatar.PrimaryPart
    local Pos:Vector3 = Data.CurrentPos
    if Pos and (Pos -  Avatar.Position).Magnitude > 1  then Avatar:PivotTo( CFrame.new(Pos) )  end   
    if UID== MyUID then  return end -- IMPORTANT
    Data.Func = "TriggerAction"
    Data.Action = "Jump"
    OtherProfile.Actor:SendMessage("Info", Data)
end 

function Character_Handler:CheckPlayerCentrePosNetwork()    
    local ClosestNetworkPartitionNumber: number = Map_Manager.GiveClosestNetPartition() 
    if not ClosestNetworkPartitionNumber then warn("DID NOT get closestnetpartition"); return end
    -- NetworkHandler:CheckNetworkPartition(ClosestNetworkPartitionNumber)
    return ClosestNetworkPartitionNumber:: number
end
function Character_Handler.GiveCharacter() return Character end

NetworkHandler:Init(MT)--/////////////////IMPORTANT
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
                
            } 
            their MapLocation is the centre of the Networkpartition
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