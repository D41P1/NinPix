local SSS = game:GetService("ScriptChangeService")
if not script.Parent:IsA("Actor") then
    local CharacterActor = Instance.new("Actor")
    CharacterActor.Name = "NetworkActor"
    CharacterActor.Parent = SSS
    script.Parent = CharacterActor
end

--[[Info
This Module is for Sending / Relaying the Data received From Character_Controller 
Relaying the Data to the Other Clients   
]]
--[[
    Map_Manager
    Event_Manager
]]

--[[
    Use Map_Manager to init the Network Partitions (512x512)
    init all the Network Partition events 16 per section
    Fire To Network Partition Method 
]]
