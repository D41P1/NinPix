--[[
when player added  {
    make a player added connection await the attribute "SpawnLocation" from the server
    Create new character for the player ONLY DO ATTRIBUTES NOT EVENTS -- so later players can just grab neccessary data also

    -- shirt and pants also include armours
    -- we are doing 2D clothing  (maybe 3D if we have time)
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