
--[[ Client inputs pseudo code
when player added  {
    make a player added connection await the attribute "SpawnLocation" from the server
    so when a player is added clients know to make a new character
    recieve spawn position from server via reliable event and set the new character to the spawned event
    Make the character by awaiting the attributes from the server like {
        -- shirt and pants also include armours
        -- we are doing 2D clothing  (maybe 3D if we have time)
        Hair = 4
        Shirt = 1  
        Pants = 4
        Accessory? = 3  -- ? means they might not have an accessory so if check accessory   
    } etc
    save the a clone of the character in a table for the Respawn function
    
}



Start Init input handler


]]