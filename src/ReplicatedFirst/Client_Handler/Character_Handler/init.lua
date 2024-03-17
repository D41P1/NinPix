--[[ Info
    This Mod is for Creating the Characters for both players, NPCs and managing them
    Connecting and disconnecting to the NetworkPartition events
]]
--[[ Modules needed:
    MapManager
    EventManager
    CustomTask
    RayMovement
    AnimationHandler
]]
--[[ TODO
    -- CharactersAvatar = {
        Hair, Eyes, Face, Shirt, Pants,
        Armour?, Accessories?,
    }
    upon joining the game {    
        From Server {
            Data for other CharactersAvatars 
            their MapLocation etc
        }
    }
    Connected PlayerLeave function { 
        --Cleanup {
            Remove from the Avatar dictionary
        }
    }
    
    From other Modules: {
        the MapDictionary 
        The Section and Partition Client is currently in
        The events that need connecting too
    }
    From Server {
        data of 4 nearest Partitions to the Client {
            For OtherCharacters {
                Pos ,
                CurrentAnim,
                Name,
            }
        }

    }
    -- have all the other players character avatars stored as clones in a dictionary 
    
    -- Upon calculating the Partitions after that you will render the partition and also receive From Server 
]]