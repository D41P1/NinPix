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