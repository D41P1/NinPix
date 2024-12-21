local SharedType = require(game.ReplicatedStorage.Shared.SharedType)
--[[ Handles Player Attributes
]]
-- Function to generate a random string of a given length

local Stats_Controller = {
    ["Humanoid"] = {
        BodyType = "Humanoid",
        Hip = 5
    },
}
Stats_Controller["Dummy"] = Stats_Controller.Humanoid
Stats_Controller["HitDummy"] = Stats_Controller.Humanoid
Stats_Controller["ShadoMercenary"] = Stats_Controller.Humanoid
local Profiles = {} 
export type Stats = SharedType.Character_Stats

local BaseStats_To_Add = {"Range", "Width", "Height","Knockback", "Stun", "Damage","HBTime"}
local Stats_To_Add = {
    "Range", "Width", "Height","MaxPosture", "Knockback", "Stun", "Damage", "MaxHealth",
    "HBTime"
}
local BaseStats = {
    Health = 100,
    Posture = 200,
    Stamina = 300,
    MaxHealth = 100,
    MaxPosture = 200,
    MaxStamina = 300,
}
for _, Stat_Names in BaseStats_To_Add do 
    BaseStats[Stat_Names] = 0
end
function Stats_Controller:InitAttributes(player: Player?, UID: string?,Connect: boolean?) -- TODO future data affects attributes
    if not player then return end
    player:SetAttribute("UID", UID)
    player:SetAttribute("WalkSpeed", 10) 
    player:SetAttribute("BaseWalkSpeed", 10)
    return UID
end
function Stats_Controller.Init_Profile(UID:string, Data:Stats) --TODO in the future after calculating Stats from equipment
    local Profile = Data
    Profiles[UID] = Profile
    return Profile
end
function Stats_Controller.Give_BaseStats() 
    return table.clone(BaseStats) :: Stats 
end
function Stats_Controller.Give_Stats_To_Add() 
    return Stats_To_Add 
end
function Stats_Controller.GiveProfile(UID:string) --* in the future after calculating Stats from equipment
    return Profiles[UID] :: Stats
end
function Stats_Controller.CleanProfile(UID:string) --* in the future after calculating Stats from equipment
    Profiles[UID] = nil
end
type HipTable  = {
    BodyType: string,
    Hip:number
}
function Stats_Controller.GiveHip(BodyType:string)
    local T:HipTable = Stats_Controller[BodyType]
    if not  T then warn("Invalid BodyType: ", BodyType, "\n: ", Stats_Controller); return end
    return T.Hip
end
function Stats_Controller:CharacterAttributes(Character: Model, BodyType: string)
    for AttributeName, AttributeValue in Stats_Controller[BodyType] do Character:SetAttribute(AttributeName, AttributeValue) end
end
return Stats_Controller