--[[ Info
Used to check the CentrePos Partitions
]]
local CurrentSection: number, CurrentRenderPartitions: {}, CurrentNetworkPartition: number 

local CentrePosChecks = {}

export type Map = { [number]: {Vector3} }

function CentrePosChecks:GetClosestSection(Character: Model, HashMap: Map)
    local CharacterPart = Character.PrimaryPart
    local CharacterPos = CharacterPart.Position
    local Closest, ClosestSection = 99999, 1 
    for SectionNumber, PartitonMagnitude in HashMap do
        local SectionDistance = (HashMap[SectionNumber] - CharacterPos).Magnitude 
        if SectionDistance < Closest then
            Closest = SectionDistance
            ClosestSection = SectionNumber
        end
    end 
    CurrentSection = ClosestSection
    return ClosestSection
end  
function ChecksNearestPartition(Character: Model, Map: Map, RawStep: number, SectionNum: number,  PartitionNum: number, ReturnAmount: number)
    local CharacterPart = Character.PrimaryPart
    local CharacterPos = CharacterPart.Position
    local PartitionNumbers = {
        [PartitionNum + RawStep] = "" ,
        [PartitionNum + RawStep + 1] = "" ,
        [PartitionNum + RawStep -1] = "" ,
        [PartitionNum - RawStep] = "" ,
        [PartitionNum - RawStep - 1] = "" ,
        [PartitionNum - RawStep + 1] = "" , 
        [PartitionNum + 1] = "" ,
        [PartitionNum - 1] = "" , 
        [PartitionNum] = "" ,         
    }
    local Nearest9 = {} -- some could be nil should not error
    for PartitionNum, _ in PartitionNumbers do  Nearest9[PartitionNum] = Map[SectionNum][PartitionNum] end

    local NearestPartitions = {}
    local MagnitudePartitions = {} -- holds the Magnitude of all 9 partitions
            
    --First get all their distances and save them 
    for PartitionNumber, PartitionPos: Vector3 in Nearest9  do
        MagnitudePartitions[PartitionNumber] = (PartitionPos - CharacterPos).Magnitude
    end
    for i = 1, ReturnAmount do
        local Closest, ClosestPartitionNumber = 99999, 1
        for PartitionNumber, PartitonMagnitude in MagnitudePartitions do
            local PartitionDistance = MagnitudePartitions[PartitionNumber]
            if PartitionDistance < Closest then
                Closest = PartitionDistance
                ClosestPartitionNumber = PartitionNumber
            end
        end 
        NearestPartitions[ClosestPartitionNumber] = Nearest9[ClosestPartitionNumber]
        MagnitudePartitions[ClosestPartitionNumber] = nil -- Remove the closest so the next closest can be added
    end  
    local NearestPartition = Map[SectionNum][PartitionNum]
    return NearestPartitions :: { [number]: Vector3 } , NearestPartition :: number 
end
function CentrePosChecks:RenderPartitionCentrePosCheck(Character: Model, HashMap: Map)
    local player = game:GetService("Players").LocalPlayer
    local SendSection = CurrentSection or player:GetAttribute("Section")
    local SendRenderPartition = CurrentRenderPartitions or player:GetAttribute("RenderPartition")
    local Check: Map  =  ChecksNearestPartition(Character, HashMap, 8, SendSection, SendRenderPartition, 4)
    CurrentRenderPartitions = Check
    return Check
end 
function CentrePosChecks:NetworkPartitionCentrePosCheck(Character: Model, HashMap: Map)
    local player = game:GetService("Players").LocalPlayer
    local SendSection = CurrentSection or player:GetAttribute("Section")
    local SendNetworkPartition = CurrentNetworkPartition or player:GetAttribute("NetworkPartition")
    local Check: Map , Nearest =  ChecksNearestPartition(Character, HashMap, 4, SendSection, SendNetworkPartition, 1)
    CurrentNetworkPartition = Nearest
    return Check
end 


-- function CentrePosChecks:CheckCentrePos(Character: Model, TypeToCheck: string, SectionNum: number, PartitionNum: number, )
--     local Section = CurrentSection or SectionNum
--     local Partition =  CurrentRenderPartition or PartitionNum
--     local CentrePos = HashMap[SectionNum][PartitionNum]
-- end 


return CentrePosChecks
