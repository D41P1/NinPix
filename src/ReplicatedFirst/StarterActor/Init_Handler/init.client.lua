local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContentService = game:GetService("ContentProvider")
ContentService:PreloadAsync(ReplicatedStorage:GetDescendants())
task.wait()
local FromServer = ReplicatedStorage:WaitForChild("FromServer")
local player = game.Players.LocalPlayer
local Client_Actor 
function Respawn()
    Client_Actor = script.Parent.Parent.Client_Actor:Clone()
    Client_Actor.Client_Handler.Enabled = true
    Client_Actor.Parent = player:WaitForChild("PlayerScripts")    
end 
FromServer.Start.OnClientEvent:Connect(function()   Respawn() end)

--[[
when player added  {
    make a player added connection await the attribute "SpawnLocation" from the server
    Create new character for the player ONLY DO ATTRIBUTES NOT EVENTS -- so later players can just grab neccessary data also

    -- shirt and pants also include armours
    -- we are doing 3D clothing  
    -- ? means it might be nil

    Make the character by awaiting the attributes from the server like {
        Hair = 4
        Shirt = 1  
        Pants = 4
        Accessory? = 3     
    } etc
    save the a clone of the character in a table for the Respawn function
}

]]