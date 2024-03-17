
--[[ Pre Startup (basically whats already in explorer before play)
Map: Folder
Map: {
    Section1: Folder = {
        --Empty for now Clients will script it in
    } ,
    Section2: Folder,
    Section3: Folder,
    Section4: Folder,
}
]]

--[[InFo
we using a HexaDecatree (16) which should leave each partition as 250x250 
Map is 4000x4000
A Section is 2000x2000
A partition is 250x250
64 partitions total per section
4 partitions rendered at all times simulating 500 stud radius rendering
A column in a section is 4
A row in a Section is 16 (16x4 = 64)
]]
--[[ ///////////////////////////////////////////////////////TODO//////////////////////////////////////////////////////////////////
method for the CLient Init of the Map Dictionary 
Same for the server but do not need the values only SizeValue(Vector3Value) and the partitioncentrePos

spawn player at their Section[Partition]
method for the Server Init of the hitboxes only 
]]

--[[ Map Dictionary
local Map = {
        [SectionNumber] = { -- up to 4
            [PartitionNumber] = { -- up to 64
                PartitionCentrePos: Vector3, 
                Values = {
                    -- All the Values instances e.g StringValue etc 
                }
            }
        }
        
    }  
]]

--[[ Client nearest9Partitions
    function find nearest9Partitions(SectionNum , PartitionNumber)

        -- PartitionNumber - 16 if check >64 then new section  (North)
        -- PartitionNumber - 16 - 1 if check >64 then new section (NorthWest)
        -- PartitionNumber - 1  (West) if check >64 then new section 
        -- PartitionNumber - 16 + 1 if check >64 then new section (NorthEast)
        
        -- PartitionNumber + 16 if check >64 then new section (south)
        -- PartitionNumber + 16 + 1 if check >64 then new section (SouthEast)
        -- PartitionNumber + 16 - 1 if check >64 then new section (SouthWest)
        -- PartitionNumber + 1 (East) if check >64 then new section 
        -- PartitionNumber
        -- Add in a dictionary  
        -- forloop through this dictionary and get the PartitionCentrePos from MapDictionary Using SectionNum
        return { [PartitionNumbers: number] = PartitionPos }  
    end    
]]

--[[ Client PartitionCentreCheck
    function PartitionCentreCheck (Section: number, Partition: number)
        if they are 200 studs away from the centre of their Partition then
            --Gather 9 Partitions the 1 they are currently in and the 8 surrounding the 1 they are in  look like 3x3
            local Partitions: { [PartitionNumbers: number] = PartitionPos } = nearest9Partitions(Section, Partition)  
            --remove the 1 they are in so 8 left 
            
            --Algorithm to find the 4 nearest partitions out of 9
            -- assume Partitions Table holds 9 partitions
            local ClosestPartitions = {} -- holds the nearest 4 Partitions
            local MagnitudePartitions = {} -- holds the Magnitude of all 9 partitions
            
            --First get all their distances and save them 
            for PartitionNumber, PartitionPos in Parititons  do
                MagnitudePartitions[PartitionNumber] = (PartitionPos - CharacterPos).Magnitude
            end
          
            then only get the smallest distant Partition  
            for i = 1, 3 do
                local Closest, ClosestPartitionNumber = 99999, 1
                for PartitionNumber, PartitonMagnitude in MagnitudePartitions do
                    if PartitonMagnitude < Closest then
                        Closest = PartitonMagnitude
                        ClosestPartitionNumber = PartitionNumber
                    end
                end 
                ClosestPartitions[ClosestPartitionNumber] = Partitions[ClosestPartitionNumber]
                MagnitudePartitions[ClosestPartitionNumber] = nil -- Remove the closest so the next closest can be added
            end  

            ClosestPartitions -- now it should have the 4 closest ones now u can render them
            for i = 1, 4 do
                local MapPartition = Map\(ClosestPartitions\i)
                local Partiton
            end
        end
        if 50 studs away from centre then Unrender all other partitions so the only the single is rendered
    end
]]
--[[Client
    -- for loop the Map, Sections, Partitions. Gathering each folder and create a dictionary
    -- For Partitions {
        Centre Points of the Partitions{
            Calculate from 0,0,0 to -2000x , 2000z,  (section 1, partition 1)  
            then Partition 2 = -1750x, 2000z etc until 0, 2000z 
            partition 17 = -2000x, 1750z etc
        }         
        Folders {
            1-64 holding the seriliased data for the Each Partition and whats in the partition
            ColorValue, StringValues etc
        }
    }
    From Server will get PlayerMapLocation = {
        Section: 1-4,
        Partition: 1-64
    }
    
]]
--[[ RenderPartition function
]]


--[[Server
Save their MapLocation {
    Section: 1-4,
    Partition: 1-64 
}
]]
--[[Shared  
]]
