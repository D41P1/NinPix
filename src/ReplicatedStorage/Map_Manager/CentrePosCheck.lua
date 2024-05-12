--[[ Info
Used to check the CentrePos Partitions
]]
local CurrentSection: number, CurrentRenderPartitions: {}, CurrentNetworkPartition: number 

local CentrePosChecks = {}

export type Map = { Vector3 }
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
function ChecksNearestPartition(Character: Model, Map: {Vector3}, RawStep: number,  PartitionNum: number, ReturnAmount: number)
    local CharacterPart = Character.PrimaryPart
    local CharacterPos = CharacterPart.Position
    local PartitionNumbers = {
        [1] = PartitionNum + RawStep,
        [2] = PartitionNum + RawStep + 1,
        [3] = PartitionNum + RawStep - 1,
        [4] = PartitionNum - RawStep,
        [5] = PartitionNum - RawStep - 1,
        [6] = PartitionNum - RawStep + 1,
        [7] = PartitionNum + 1,
        [8] = PartitionNum - 1,
        [9] = PartitionNum
    }
    -- partnumber = 1-256 or 1-64 
    -- map[1-256] = centre of Partition
    local function NearestPartition(PartitionTable: {any})
        local Closest = 999999
        local index = 1
        local NearestPart = 1
        for i:number, PartitionNumber:number in PartitionTable do 
            local PartitionPos:Vector3? = Map[PartitionNumber]
            if not PartitionPos then continue end
            local Distance = (CharacterPos - Map[PartitionNumber]).Magnitude
            if Distance < Closest then  Closest = Distance; index = i; NearestPart = PartitionNumber end
        end    
        return NearestPart, index    
    end
    local NearestPartTable = {}
    for i = 1 , ReturnAmount do 
        local Nearest, index = NearestPartition(PartitionNumbers)
        table.insert(NearestPartTable, Nearest)
        table.remove(PartitionNumbers, index)
    end
    return NearestPartTable, unpack(NearestPartTable)
end
function CentrePosChecks:RenderPartitionCentrePosCheck(Character: Model, HashMap: Map)
    local player = game:GetService("Players").LocalPlayer
    local SendRenderPartition = CurrentRenderPartitions or player:GetAttribute("RenderPartition")
    local Check: Map  =  ChecksNearestPartition(Character, HashMap, 64, SendRenderPartition, 4)
    CurrentRenderPartitions = Check
    return Check
end 
function CentrePosChecks:NetworkPartitionCentrePosCheck(Character: Model, HashMap: Map)
    local SendNetworkPartition = CurrentNetworkPartition or Character:GetAttribute("NetworkPartition")
    local Check: Map , Nearest =  ChecksNearestPartition(Character, HashMap, 16, SendNetworkPartition, 1)
    CurrentNetworkPartition = Nearest
    return Check, Nearest
end 


-- function CentrePosChecks:CheckCentrePos(Character: Model, TypeToCheck: string, SectionNum: number, PartitionNum: number, )
--     local Section = CurrentSection or SectionNum
--     local Partition =  CurrentRenderPartition or PartitionNum
--     local CentrePos = HashMap[SectionNum][PartitionNum]
-- end 


return CentrePosChecks
