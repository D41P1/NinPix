--[[ Handles Player Attributes
]]
-- Function to generate a random string of a given length

local Attributes_Controller = {
    ["Humanoid"] = {
        BodyType = "Humanoid",
        Hip = 5
    },
}
Attributes_Controller["Dummy"] = Attributes_Controller.Humanoid
Attributes_Controller["HitDummy"] = Attributes_Controller.Humanoid
Attributes_Controller["ShadoMercenary"] = Attributes_Controller.Humanoid

function Attributes_Controller:InitAttributes(player: Player?, UID: string?,Connect: boolean?) -- TODO future data affects attributes
    -- local NetworkPartition = 1
    if not player then return end
    --mainly for Combat Machine these attributes 
    -- player:SetAttribute("Health", 100)
    -- player:SetAttribute("NetworkPartition", NetworkPartition) -- 1-64
    player:SetAttribute("UID", UID)
    player:SetAttribute("WalkSpeed", 10) 
    player:SetAttribute("BaseWalkSpeed", 10)
    -- player:SetAttribute("WallRun", true)
    return UID
end
type HipTable  = {
    BodyType: string,
    Hip:number
}
function Attributes_Controller.GiveHip(BodyType:string)
    local T:HipTable = Attributes_Controller[BodyType]
    if not  T then warn("Invalid BodyType: ", BodyType, "\n: ", Attributes_Controller); return end
    return T.Hip
end
function Attributes_Controller:CharacterAttributes(Character: Model, BodyType: string)
    for AttributeName, AttributeValue in Attributes_Controller[BodyType] do Character:SetAttribute(AttributeName, AttributeValue) end
end
return Attributes_Controller