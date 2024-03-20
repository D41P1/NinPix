local Players = game:GetService("Players")
local CharacterActors = workspace.WorkSpaceFolder.CharacterActors
local StarterCharacterScripts = script.StarterCharacterScripts
Players.PlayerAdded:Connect(function(player)
    -- Clone and Enable the script and SetAttribute (PlayerName) -- see character script
    local CharacterScript: Script = StarterCharacterScripts.Character_Script:Clone()
    CharacterScript:SetAttribute("PlayerName", player.Name)
    CharacterScript.Parent = CharacterActors 
    CharacterScript.Enabled = true
end)
--[[Data Template
{
    MapLocation = { -- spawn them at the centre of partition
        Partition: number
        Section: number
    }
    CharactersAvatar = {
        Hair, Eyes, Face, Shirt, Pants,
        Armour?, Accessories?,
    }
    Inventory {
        [ItemName]: number -- number of items
    }
}

]]

--[[
    when player joins:
    get playerdata -> EventManager write buffer -> Client 
    StarterCharacterScripts.Character_Script {
        Clone and enable the script 
        and parent to the CharacterActorsFolder
    } 
]]