local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared
local SharedType = require(Shared.SharedType)


local Attribute_Handler = {
    ["Humanoid"] = {
        BodyType = "Humanoid",
        Hip  = 5
    }
}


function Attribute_Handler:SetTheAttributes(Character: Model, BodyType: string, Data)
    for AttributeName, AttributeValue in Attribute_Handler[BodyType] do Character:SetAttribute(AttributeName, AttributeValue) end    
end 

function Attribute_Handler:SetStats(Character: Model)
    Character:SetAttribute("MaxHealth", 100)
    Character:SetAttribute("MaxPosture", 200)
    Character:SetAttribute("Health", 100)
    Character:SetAttribute("Posture", 200)
end 
function Attribute_Handler.SetNPCStats(Character:Model, NPCData:SharedType.NPCData)
    local T = {
        "Health",
        "Posture",
    }
    task.synchronize()
    for _, Name_Of_atts in T do 
        Character:SetAttribute(Name_Of_atts, NPCData[Name_Of_atts])
    end
end





return Attribute_Handler