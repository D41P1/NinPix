--[[ Info
Module Controls the NPCs {
Storing NPC StateMods
} 
]]
local NPCStateMods = script.Parent.NPCStateMods
local NPCStateMods_Controller = {}
for _, V in NPCStateMods:GetChildren() do NPCStateMods_Controller[V.Name] = V end
function NPCStateMods_Controller.GiveMod(TypeOfStateModule:string)
    return NPCStateMods_Controller[TypeOfStateModule] :: ModuleScript  
end
return NPCStateMods_Controller