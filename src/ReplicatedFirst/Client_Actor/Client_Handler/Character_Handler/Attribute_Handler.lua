local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared
local SharedType = require(Shared.SharedType)


local Attribute_Handler = {
    ["Humanoid"] = {
        BodyType = "Humanoid",
        Hip  = 2.7
    }
}


function Attribute_Handler:SetTheAttributes(Character: Model, BodyType: string, Data)
    for AttributeName, AttributeValue in Attribute_Handler[BodyType] do Character:SetAttribute(AttributeName, AttributeValue) end    
end 

function Attribute_Handler:SetStats(Character: Model, StatBuffer:buffer)
    local Stats = {
        [1] = "Health",
        [2] = "Posture"
        -- Strength
        -- Stamina
        -- Defence
        -- Speed
    }
    local Readu16 = buffer.readu16
    local offset = 0
    for _, StatNames in Stats do 
        Character:SetAttribute(StatNames, Readu16(StatBuffer, offset))
        offset += 2
    end
    Character:SetAttribute("MaxHealth", Readu16(StatBuffer, 0))
    Character:SetAttribute("MaxPosture", Readu16(StatBuffer, 2))
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