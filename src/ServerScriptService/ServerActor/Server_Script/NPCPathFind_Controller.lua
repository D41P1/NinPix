--[[Info
Module used for NPC behavious etc

Use raycasting Pathfind with interpolate
]]


local NPCPathFind_Controller = {}

for _, V in script.Parent.NPCPathFindMods:GetChildren() do
    NPCPathFind_Controller[V.Name] = V
end
function NPCPathFind_Controller.GiveMod(TypePathFind:string)
    return NPCPathFind_Controller[TypePathFind]:: ModuleScript
end
return NPCPathFind_Controller