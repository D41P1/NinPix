local Attribute_Handler = {
    ["Humanoid"] = {
        BodyType = "Humanoid",
        Hip  = 2.7
    }
}
function Attribute_Handler:SetTheAttributes(Character: Model, BodyType: string)
    for AttributeName, AttributeValue in Attribute_Handler[BodyType] do Character:SetAttribute(AttributeName, AttributeValue) end
end 



return Attribute_Handler