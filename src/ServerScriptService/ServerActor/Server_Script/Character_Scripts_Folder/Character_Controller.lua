local Character_Controller = {}
type TableOfEvents = { string }    
local Character_Controller_Profiles = {}
type CPProfile = {
    ["UID"]:string ,
    ["FA"]:Actor,
    ["CFV"]: CFrameValue, --*Important for the FSM
    ["BodyPart"]:BasePart,
    ["VNV"]: NumberValue,
    ["UV3V"]: Vector3Value,
    ["LV3"]: Vector3Value,
    ["Current_Skill_Item"]:number,
    ["Current_Weapon_Item"]:number,
    ["Current_Selected_Item"]:number,
    ["Toolbars"]: {{number}},
    ["BodyEquipped"]:{number},
    ["CosmeticEquipped"]: {number},
    ["Backpack"]: {number},
}
--[[ --* how NPC CPProfile will look during RunTime
type NPC_Profile = {
    ["UID"]:string ,
    ["FA"]:Actor,
    ["CFV"]: CFrameValue, --*Important for the FSM
    ["VNV"]: NumberValue,
    ["UV3V"]: Vector3Value,
    ["LV3"]: Vector3Value,
    ["BodyEquipped"]:{number},
    ["CosmeticEquipped"]: {number},
}
]]
function Character_Controller.Init_Profile(UID:string, ForwardActor:Actor?)
    local CPProfile = {
        ["UID"] = UID,
        ["FA"] = ForwardActor
    }
    Character_Controller_Profiles[UID] = CPProfile
    return CPProfile
end
function Character_Controller.Give_Profile(UID:string) : CPProfile
    return Character_Controller_Profiles[UID] 
end
function Character_Controller.Clean_Profile(UID:string) 
    Character_Controller_Profiles[UID] = nil 
end

return Character_Controller