local Players = game:GetService("Players")
local CharacterActors = workspace.WorkSpaceFolder.CharacterActors
local StarterCharacterScripts = script.Parent.StarterCharacterScripts
Players.PlayerAdded:Connect(function(player)
    -- Clone and Enable the script and SetAttribute (PlayerName) -- see character script
    local CharacterScript: Script = StarterCharacterScripts.Character_Script:Clone()
    CharacterScript:SetAttribute("PlayerName", player.Name)
    CharacterScript.Parent = CharacterActors 
    CharacterScript.Enabled = true
end)

--[[
    when player joins:
    get data -> EventManager write buffer -> Client 
    StarterCharacterScripts.Character_Script {
        Clone and enable the script 
        and parent to the CharacterActorsFolder
    } 
]]