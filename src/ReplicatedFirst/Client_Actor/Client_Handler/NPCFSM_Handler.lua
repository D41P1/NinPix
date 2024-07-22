local NPCFSM_FOLDER = script.Parent.ClientNPCStateMods
local NPCFSM_Handler = {}

for _, Mods in NPCFSM_FOLDER:GetChildren() do 
    NPCFSM_Handler[Mods.Name] = Mods
end

return NPCFSM_Handler