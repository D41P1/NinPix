-- local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
-- local TweenService = game:GetService("TweenService")
local Shared = ReplicatedStorage.Shared
local player: Player = game.Players.LocalPlayer
local MyUID = player:GetAttribute("UID")
local MyNumUID = tonumber(MyUID)
local OtherPlrs = {}

local Map_Manager = require(Shared.Map_Manager)
local SharedType = require(Shared.SharedType); 
local HumanoidMachine = require(Shared.HumanoidMachine)

local NetworkHandler = require(script.NetworkHandler)
local Checks = require(script.Checks)

export type Profile = SharedType.Profile
local  Character_Handler = {} 
local MT = setmetatable({}, {
    __call = function(_, Data) Character_Handler[Data.Func](Data) end
})
Character_Handler.InitChecks = Checks.InitChecks
function Character_Handler.Init()
    -- local NetworkPartitionNumber = player:GetAttribute("NetworkPartition")    
    -- Map_Manager.SetClosestNetPartition(NetworkPartitionNumber)    
end 
function Character_Handler.Spawn(Character: Model, Data, Humanoid: SharedType.CustomHumanoid)
    task.synchronize()
    local UID = Data.UID
    local Pos = Data.Pos
    local Hip = Data.Hip
    local WS = Data.WalkSpeed
    Character.Parent = workspace.Bodies
    Character:PivotTo(CFrame.new(Pos + Vector3.new(0, Hip, 0)))
    Character:SetAttribute("WalkSpeed", WS)
    Character:SetAttribute("BaseWalkSpeed", WS)
    
    Character:AddTag("Char"..UID)
    OtherPlrs[UID] = {
        ["Avatar"] = Character,
        ["Humanoid"] = Humanoid
    }
    local Body = Character.PrimaryPart
    Body.CollisionGroup = "Chars"
    
    return Character_Handler.GiveProfile(UID)
end
function Character_Handler.AddToOtherPlayerTable(Profile:Profile)
    OtherPlrs[Profile.UID] = Profile
end
function Character_Handler.CheckMove(Data)
    local UID: string = Data.UID
    local OtherProfile: Profile = OtherPlrs[UID]
    if not OtherProfile then print(UID, OtherPlrs); return end --* during an NPC Init this might prevent a temporary error SO KEEP IT !!! 
    local Avatar = OtherProfile.Avatar
    local AvatarBody = Avatar.PrimaryPart
    local PreviousPos:Vector3 = AvatarBody.Position
    local NewCF: CFrame = Data.CurrentCF
    local Distance  = (PreviousPos- NewCF.Position).Magnitude     
    if Distance > 4.5 then
        task.synchronize()
        AvatarBody.CFrame  = NewCF
    end
    if tonumber(UID) == MyNumUID then   return end
    task.synchronize()
    AvatarBody.CFrame = NewCF --* this is to update other players for the Client

end
function Character_Handler:CheckPlayerCentrePosNetwork()    
    local ClosestNetworkPartitionNumber: number = Map_Manager.GiveClosestNetPartition() 
    if not ClosestNetworkPartitionNumber then warn("DID NOT get closestnetpartition"); return end
    -- NetworkHandler:CheckNetworkPartition(ClosestNetworkPartitionNumber)
    return ClosestNetworkPartitionNumber:: number
end
function Character_Handler.ChangeCharProperty(UID:string, Property:string, Value:any)
    local Profile: Profile = OtherPlrs[UID]
    if not Profile then warn("No StateMachine", Profile) end
    local Char = Profile.Avatar 
    if not Char:GetAttribute(Property) then warn("incorrect Property: ", Property); return end
    Char:SetAttribute(Property, Value)
end
function Character_Handler.SetHealth(Char:Model, Health:number)
    task.synchronize()
    if Health <= 0 then  Char:SetAttribute("Health", 0);  return  end
    Char:SetAttribute("Health", Health)
    return
end
function Character_Handler.SetPosture(Char:Model, Posture:number)
    task.synchronize()
    if Posture <= 0 then  Char:SetAttribute("Posture", 0);  return  end
    Char:SetAttribute("Posture", Posture)
    return
end
function Character_Handler.SetStamina(Char:Model, Stamina:number)
    task.synchronize()
    if Stamina <= 0 then  Char:SetAttribute("Stamina", 0);  return  end
    Char:SetAttribute("Stamina", Stamina)
    return
end
-- function Character_Handler.GiveCharacter() return Character end
function Character_Handler.GiveProfile(UID:string):Profile 
    return OtherPlrs[UID] 
end
function Character_Handler.GiveEveryProfile() 
    return OtherPlrs :: {[string]: Profile}
end

function Character_Handler.CleanProfile(UID:string) 
    local Prof:Profile = OtherPlrs[UID]
    if not Prof then warn("no Profile Cleanup"); return end 
    for _, V in Prof do 
        task.synchronize()
        warn(V)
        if typeof(V) == "Instance" then V:Destroy() end
    end
    OtherPlrs[UID] = nil
end


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