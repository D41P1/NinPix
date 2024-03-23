local player = game.Players.LocalPlayer
local Client_Actor 

function Respawn()
    Client_Actor = script.Parent.Parent.Client_Actor:Clone()
    Client_Actor.Client_Handler.Enabled = true
    Client_Actor.Parent = player:WaitForChild("PlayerScripts")    
end 
Respawn()

player:GetAttributeChangedSignal("Health"):Connect(function()
    local Health = player:GetAttribute("Health")
    if Health <= 0 then 
        Client_Actor:Destroy(); Client_Actor = nil
        Respawn()
     end
end)



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