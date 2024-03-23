local CentrePosChecks = require(script.CentrePosCheck)

local Maps = {}
local HashMapSize = {
    NetworkHashMap =  512,
    RenderHashMap = 256,
    SectionHashMap = 2048
}
local Map_Manager = {}
Map_Manager.GetClosestSection = CentrePosChecks.GetClosestSection
Map_Manager.NetworkPartitionCentrePosCheck = CentrePosChecks.NetworkPartitionCentrePosCheck
Map_Manager.RenderPartitionCentrePosCheck = CentrePosChecks.RenderPartitionCentrePosCheck

export type Map = {Vector3}

function Map_Manager:GetMapType(TypeOfMap: string, Size: number?)
    local Map = Maps[TypeOfMap]
    local SectionSize =  Size or 2048
    if Size then
        local TablePos =  GetSection(HashMapSize[TypeOfMap])        
        Maps[TypeOfMap] = TablePos
        return TablePos
    end
    if Map then return Map
    else
        local TablePos =  CreatePartitions(HashMapSize[TypeOfMap] , SectionSize)
        Maps[TypeOfMap]  = TablePos
        return TablePos
    end 
end
function GetSection(HashMap: Map)
    local SectionsTable = {
        [1] = Vector3.new(-1012,0,1012),
        [2] = Vector3.new(1012,0,1012),
        [3] = Vector3.new(-1012,0,-1012),
        [4] = Vector3.new(1012,0,-1012),
    }
    return SectionsTable
end
function CreatePartitions(Size: number, SectionSize: number)
    local TableOfPos = {
        [1] = {},
        [2] = {},
        [3] = {},
        [4] = {},
    }
    local NumberOfPartitions = 0
    local function MakeSection(SectionNumber: number, AxisFlipX: number, AxisFlipZ: number)
        for Ydown = SectionSize, Size, -Size do
            local OffsetZ = AxisFlipZ*(Ydown + -Size/2) 
            for XAcross = SectionSize, Size/2, -Size do
                NumberOfPartitions += 1
                local CentrePoint = Vector3.new( AxisFlipX*(XAcross + -Size/2), 0, OffsetZ)
                TableOfPos[SectionNumber][NumberOfPartitions] = CentrePoint
            end
        end
        NumberOfPartitions = 0
    end
    MakeSection(1, -1, 1)
    MakeSection(2, 1, 1)
    MakeSection(3, -1, -1)
    MakeSection(4, 1, -1)
    return TableOfPos :: { [number]: {Vector3} }
end


return Map_Manager
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
we using a HexaDecatree (8) which should leave each partition as 250x250 
Map is 4096x4096
A Section is 2048x2048
A Hexdeca partition is 256x256
64 partitions total per section
4 partitions rendered at all times simulating 500 stud radius rendering
Total Columns,Rows in a section is 8 (8x8 = 64)
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
--[[ equations
-- y/2 - y/32 = n
where n is an multiple of 8 
--y = 32(8k)/15 = 256k/15 where k is an integer
]]

--[[ Client nearest9Partitions
    function find nearest9Partitions(SectionNum , PartitionNumber)
        section = 8x8
        -- PartitionNumber - 8 if check <0 then new section?  (North)
        -- PartitionNumber -8 -1 if check <0 then new section? (NorthWest)
        -- PartitionNumber -1  if check <0 then new section? (West) 
        -- PartitionNumber -8 +1 if check <0 then new section? (NorthEast)
        
        -- PartitionNumber +8 if check >64 then new section? (south)
        -- PartitionNumber +8 +1 if check >64 then new section? (SouthEast)
        -- PartitionNumber +8 -1 if check >64 then new section? (SouthWest)
        -- PartitionNumber +1  if check >64 then new section?  (East)
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
        if 350 studs away change PositionPointOfCalculation to the new nearest Partition (should be ~150 studs away)
    end
]]
--[[Client
    -- for loop the Map, Sections, Partitions. Gathering each folder and create a dictionary
    -- For Partitions {
        Centre Points of the Partitions section = 8x8 {  
            Section 1 {
                Calculate from 0,0,0 to -1920 x , 1920 z,  (section 1, partition 1) (2000 - 256 = 1920)  
                Partition 2 = -1664 x, 1920 z   --etc until -128, 1920z  
                Partition 3 = -1408 x, 1920 z 
                partition 9 = -1920 x, 1664 z 
            }
            Section 2 {
                Partition 1 = 128 x, 1920 z 
                Partition 2 = 256 x, 1920 z   
                Partition 3 = 384 x, 1920 z
                partition 9 = 128 x, 1664 z     
            }
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
function to Generate hitboxes For Map
]]
