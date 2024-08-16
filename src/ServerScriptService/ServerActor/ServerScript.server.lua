local Players = game:GetService("Players")
local Data_Manager = require(script.Parent.Data_Manager)
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SharedEvents = ReplicatedStorage.SharedEvents
local AvatarDataEvent = SharedEvents.AvatarDataEvent

Players.PlayerAdded:Connect(function(player: Player)  
    local Data =  Data_Manager.GetPlayerAvatarData(player)
    --TODO fire to client
    task.delay(4, function ()
        AvatarDataEvent:FireClient(player, Data.AvatarBuffer, Data.AvatarRGBBuffer)    
    end)
end)
Players.PlayerRemoving:Connect(function(player: Player)  
    local PlayerName = player.Name
    local ArrayPlayers = Players:GetPlayers() 
    if #ArrayPlayers <= 1 then 
        Data_Manager.Save_allPlayers_Avatar()
        print("Last player in Server leaving, Saving Data")
    end
    task.delay(5, function()
        Data_Manager.Cleanup(PlayerName)
    end)
end)



AvatarDataEvent.OnServerEvent:Connect(Data_Manager.ChangePlayerAvatarData)

--* this must be under Players RBXConnections cos it takes a lil long
Data_Manager.init()
