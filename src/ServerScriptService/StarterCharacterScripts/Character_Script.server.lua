local CharacterActors = workspace.WorkSpaceFolder.CharacterActors
if not script.Parent:IsA("Actor") then
   local CharacterActor = Instance.new("Actor")
   CharacterActor.Name = script:GetAttribute("PlayerName") -- set it from Main
   CharacterActor.Parent = CharacterActors 
   script.Parent = CharacterActor
end
--[[ Events
    W,
    A,
    S,
    D
    Jump,
    M1,
    M2,
    F
]]
--[[
    create Actor(s) parent to Actors Folder
    Create CharacterEvents  
    init CustomHumanoid
    connect functions to events through Character_Controller Module
    init attributes
]]