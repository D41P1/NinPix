local Players = game:GetService("Players")
local WorkspaceFolder = workspace.WorkSpaceFolder
local CharacterActorsFolder: Folder = Instance.new("Folder")
CharacterActorsFolder.Parent = WorkspaceFolder

Players.PlayerAdded:Connect(function(player)
    
end)

--[[
    when player joins:
    get data -> EventManager write buffer -> Client 
    StarterCharacterScripts.Character_Script {
        enable the script 
        and parent to the CharacterActorsFolder
    } 
]]