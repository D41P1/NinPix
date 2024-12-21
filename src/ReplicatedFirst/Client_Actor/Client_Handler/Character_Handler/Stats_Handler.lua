--[[ Handles Player Attributes
]]
-- Function to generate a random string of a given length

local Stats_Handler = {
    ["Humanoid"] = {
        BodyType = "Humanoid",
        Hip = 5
    },
}
Stats_Handler["Dummy"] = Stats_Handler.Humanoid
Stats_Handler["HitDummy"] = Stats_Handler.Humanoid
Stats_Handler["ShadoMercenary"] = Stats_Handler.Humanoid
local Profiles = {} 
export type Stats = {
    Health: number,
    Posture: number,
    Stamina: number,
    MaxHealth: number,
    MaxPosture: number,
    MaxStamina: number,
    Range: number, 
    Width: number, 
    Height: number,
    Knockback: number, 
    Stun: number, 
    Damage: number
}
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
function Stats_Handler:InitAttributes(Char, UID: string?, BodyType:string) -- TODO future data affects attributes
    Char:SetAttribute("UID", UID)
    Char:SetAttribute("WalkSpeed", 10) 
    Char:SetAttribute("BaseWalkSpeed", 10)
    local Body_Attributes = Stats_Handler[BodyType]
    if not Body_Attributes then warn("Incorrect BodyType; ", BodyType); return end
    for Attributes_Names, Attributes_Value in Body_Attributes do 
        Char:SetAttribute(Attributes_Names, Attributes_Value)
    end 
    return UID
end
function Stats_Handler.Init_Profile(UID:string, Data:Stats) --TODO in the future after calculating Stats from equipment
    UID = tostring(UID)
    local Profile = Data
    Profiles[UID] = Profile
end
function Stats_Handler.Give_BaseStats() 
    return table.clone(BaseStats) :: Stats 
end
function Stats_Handler.Give_Stats_To_Add() 
    return Stats_To_Add 
end
function Stats_Handler.GiveProfile(UID:string) --* in the future after calculating Stats from equipment
    return Profiles[UID] :: Stats
end
function Stats_Handler.CleanProfile(UID:string) --* in the future after calculating Stats from equipment
    Profiles[UID] = nil
end
type HipTable  = {
    BodyType: string,
    Hip:number
}
function Stats_Handler.GiveHip(BodyType:string)
    local T:HipTable = Stats_Handler[BodyType]
    if not  T then warn("Invalid BodyType: ", BodyType, "\n: ", Stats_Handler); return end
    return T.Hip
end
function Stats_Handler:CharacterAttributes(Character: Model, BodyType: string)
    for AttributeName, AttributeValue in Stats_Handler[BodyType] do Character:SetAttribute(AttributeName, AttributeValue) end
end
return Stats_Handler