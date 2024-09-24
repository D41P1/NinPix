local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SharedType = require(ReplicatedStorage.Shared.SharedType)
local Event_Handler = {}
function Event_Handler.init(T:SharedType.CharacterEvents)
    Event_Handler["Events"] = T
end
return Event_Handler