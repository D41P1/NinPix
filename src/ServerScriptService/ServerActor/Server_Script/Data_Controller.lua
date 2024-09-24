--[[ Info
This Module is for get, set, and updating data 
]]
--[[ Data Format for this game: --! PLEASE READ
AvatarBuffer always 10 bytes 5 u16 values. Each value represents which Hair or Eyes or Pants ... etc it is.
--*[offset = u16]:
0 = Hair, 2 = Shirt, 4 = Pants, 6 = Eyes, 8 = Mouth,

AvatarRGBBuffer always 18 bytes 18 u8 values. Every 3 values reprsent the RGB of each Item (Hair, Eyes, ...)
--* [offset n1 -> n3 = u8x3]
0 -> 2 = RGBHair, 3 -> 5 = RGBShirt, 6 -> 8 = RGBPants, 9 -> 11 = RGBEyes, 12 -> 14 = RGBMouth, 15 -> 17 = RGBSkin, 




Slots = {} --* look at Slots type  
this table would store all the new Slots gotten do a check before attemting to get the DataStore  
--* This is in preparation for Slots
revamp DataStore in preparations for Slots
New DataStore called ActiveSlot 
Each Slot will be a Separate DataStore (a scop of the GlobalActiveSlotDS)
for example:
--* this code would get their ActiveSlot number 1u8  
ActiveSlot_DS DataStoreService:GetDataStore("ActiveSlot")
local SlotNumberBuffer ActiveSlot_DS:GetAsync(PlayerName) 
local SlotNumber = Ru8(SlotNumberBuffer, 0)
if not Slots[SlotNumber] then 
    Slots[SlotNumber] = DataStoreService:GetDataStore("ActiveSlot", "Slot"..SlotNumber)
end

How Inventory Saves
first 32 bytes are u16 ids for what items are their in their tool bar 1-16 (0 - 30 +2)
after that it shall be 

32-42+2 6x16 6 cos 6 bodyparts it will only be Armours in here never weapons

--* max slots will be 256
]]

local RunService = game:GetService("RunService")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlayerBan_Manager = require(script.Parent.PlayerBan_Manager)


local Eyes = ReplicatedStorage.Eyes
local Mouth = ReplicatedStorage.Mouths
local Hair = ReplicatedStorage.Hairs
local Shirts  = ReplicatedStorage.Shirts
local Pants = ReplicatedStorage.Pants

local Data_Controller = {}
export type DataBuffer = {
    AvatarBuffer:buffer,
    AvatarRGBBuffer:buffer,
    InventoryBuffer:buffer,
    ActiveSlot_Num_Buffer:buffer,
    [string]: buffer
}
export type DataProfiles = {
    [string] :DataBuffer
}
export type Slots = {
    [string]: DataStore
}

do 
    local Slots = {}
    local GlobalActiveSlotDS:DataStore
    local Profiles:DataProfiles = {}
    --TODO make sure to keep updating the Save_allPlayers_Data when adding new things like inventory, stats etc
    local Save_allPlayers_Data = function ()
        task.synchronize()
        local RHB= RunService.Heartbeat
        print("starting For loop", Profiles)
        for PlayerName, Player_Profile in Profiles do
            pcall(function()
                task.synchronize()
                local SlotNum = Player_Profile.ActiveSlot_Num
                local PlayerSlotDS:DataStore = Slots[SlotNum]
                print("saving")
                GlobalActiveSlotDS:SetAsync(PlayerName, Player_Profile.ActiveSlot_Num)
                RHB:Wait()
                PlayerSlotDS:SetAsync(PlayerName.."Inventory", Player_Profile.InventoryBuffer)
                RHB:Wait()
                PlayerSlotDS:SetAsync(PlayerName.."Avatar", Player_Profile.AvatarBuffer)
                RHB:Wait()
                PlayerSlotDS:SetAsync(PlayerName.."AvatarRGB", Player_Profile.AvatarRGBBuffer)
                print("saved no problems")
            end)
            task.wait(1)
        end
    end
    local Get_ActiveSlot = function(player:Player): buffer
        local PlayerName = player.Name
        local Player_ActiveSlot_Buffer
        local Success, Error = pcall(function()  
            Player_ActiveSlot_Buffer = GlobalActiveSlotDS:GetAsync(PlayerName)
        end)
        if not Success then
            warn(Error); player:Kick(Error)
            return Player_ActiveSlot_Buffer
        end
        if not Player_ActiveSlot_Buffer then 
            Player_ActiveSlot_Buffer = buffer.create(1)
            buffer.writeu8(Player_ActiveSlot_Buffer, 0, 1)
        end
        return Player_ActiveSlot_Buffer
    end
    local Get_SlotDS = function(ActiveSlotNumber:number)
        if Slots[ActiveSlotNumber]  then  return Slots[ActiveSlotNumber] end
        Slots[ActiveSlotNumber] = DataStoreService:GetDataStore("ActiveSlot", "Slot"..ActiveSlotNumber)
        return Slots[ActiveSlotNumber]
    end
    local Get_Player_Avatar_Data = function(player:Player, ActiveSlot_Num:number)
        local PlayerActiveSlotDS = Slots[ActiveSlot_Num]
        if not PlayerActiveSlotDS then warn("Wrong Number: ", ActiveSlot_Num, typeof(ActiveSlot_Num), Slots); return end
        local Avatar_Buffer, AvatarRGB_Buffer
        local Success, Error = pcall(function()  
            local AvatarBuffer:buffer? =  PlayerActiveSlotDS:GetAsync(player.Name.."Avatar")
            if not AvatarBuffer then 
                --* first time joining default data 
                print("creating new avatar")
                local NewAvatarBuffer = buffer.create(10)
                local offset = 0
                for i = 1, 4 do 
                    buffer.writeu16(NewAvatarBuffer, offset, 1)
                    offset += 2
                end
                buffer.writeu16(NewAvatarBuffer, 8, 4)
                local NewAvatarRGBBuffer = buffer.create(18)
                for i = 0, 14 do 
                    buffer.writeu8(NewAvatarRGBBuffer, i, 0)
                end
                --* default skin color yellow so R, G , B = 200, 200, 0
                buffer.writeu8(NewAvatarRGBBuffer, 15, 200)
                buffer.writeu8(NewAvatarRGBBuffer, 16, 200)
                buffer.writeu8(NewAvatarRGBBuffer, 17, 0)    
                Avatar_Buffer = NewAvatarBuffer
                AvatarRGB_Buffer = NewAvatarRGBBuffer
                return 
            end
            local AvatarRGBBuffer:buffer? = PlayerActiveSlotDS:GetAsync(player.Name.."AvatarRGB")
            Avatar_Buffer = AvatarBuffer
            AvatarRGB_Buffer = AvatarRGBBuffer
        end)
        if not Success then  
            warn(Error);  player:Kick(Error)
        end
        return Avatar_Buffer, AvatarRGB_Buffer
    end 
    local Get_Player_Inventory_Data = function(player:Player, ActiveSlot_Num:number)
        local PlayerActiveSlotDS = Slots[ActiveSlot_Num]
        if not PlayerActiveSlotDS then warn("Wrong Number: ", ActiveSlot_Num, typeof(ActiveSlot_Num), Slots); return end
        local Inventory:buffer
        local Success, Error = pcall(function()  
            local Inventory_Buffer: buffer? = PlayerActiveSlotDS:GetAsync(player.Name.."Inventory")
            if not Inventory_Buffer then 
                --* player is new
                Inventory = buffer.create(44) -- 0-30 toolbar 16xu16 32-42 6xu16 BodyFrame (44-1024_2xu16)
            else
                Inventory = Inventory_Buffer
            end
        end)
        if not Success then 
            player:Kick(Error)
        end 
        return Inventory
    end
    local Add_To_Profiles = function(player:Player, Data: DataBuffer)
        local PlayerName = player.Name
        Profiles[PlayerName] = Data     
    end
    --*update Avatar Data
    local ChangePlayerAvatarData = function(player:Player, AvatarBuffer: buffer, AvatarRGBBuffer: buffer)
        local BanFunc = PlayerBan_Manager.Ban
        if typeof(AvatarBuffer) ~=  "buffer" then print("1");  BanFunc(player, 28, 1); return end
        if typeof(AvatarRGBBuffer) ~=  "buffer" then print("2"); BanFunc(player, 28, 1); return end
        if buffer.len(AvatarBuffer) ~= 10  then print("3"); BanFunc(player, 28, 1); return end
        if buffer.len(AvatarRGBBuffer) ~= 18  then print("4"); BanFunc(player, 28, 1); return end
        local EyesCount = buffer.readu16(AvatarBuffer, 0)
        if EyesCount > #Eyes:GetChildren()  or EyesCount <= 0 then print("5"); BanFunc(player, 28, 1); return end
        
        local MouthCount =buffer.readu16(AvatarBuffer, 2)
        if MouthCount > #Mouth:GetChildren() or MouthCount <= 0 then  print("6"); BanFunc(player, 28, 1); return end

        local HairCount =buffer.readu16(AvatarBuffer, 4) 
        if HairCount > #Hair:GetChildren() or HairCount <= 0 then  print("7"); BanFunc(player, 28, 1); return end
        
        local ShirtsCount  =buffer.readu16(AvatarBuffer, 6)
        if ShirtsCount > #Shirts:GetChildren() or ShirtsCount <= 0 then  print("8"); BanFunc(player, 28, 1); return end
        
        local PantsCount =buffer.readu16(AvatarBuffer, 8) 
        if PantsCount > #Pants:GetChildren() or PantsCount <= 0 then print("9"); BanFunc(player, 28, 1); return end
        local profile = Profiles[player.Name]
        if not profile then warn("no profile did not save"); return end
        profile.AvatarBuffer = AvatarBuffer
        profile.AvatarRGBBuffer = AvatarRGBBuffer
    end
    local Init = function()
        local Success, Error = pcall(function()  
            GlobalActiveSlotDS = DataStoreService:GetDataStore("ActiveSlot")
            GlobalActiveSlotDS:GetAsync("TEST")
        end)
        if not Success then 
            warn("[DataStore Error]: Roblox DataStore Maybe down:  \n|\n", Error)
            local Players = game:GetService("Players")
            local PlayerArray = Players:GetPlayers()
            for i = 1, #PlayerArray do 
                local player = PlayerArray[i]
                player:Kick(Error)
            end
        else
            print("Data Store is working no Errors ")
        end
    end
    local Player_Left_Queue = {}
    do 
        local D, S = 0, 120 -- 0, 120 in PROD
        task.synchronize()
        RunService.Heartbeat:ConnectParallel(function(a0: number)  
            D += a0
            if D >= S then 
                D -= S
                print("Saving Players Data")
                Save_allPlayers_Data()
                local PlayerLeft_Clone = table.clone(Player_Left_Queue)
                for i, PlayerNames in PlayerLeft_Clone do 
                    Profiles[PlayerNames] = nil
                    table.remove(Player_Left_Queue, i)
                end
            end
        end)
    end
    local Cleanup = function(PlayerName:string)
        table.insert(Player_Left_Queue, PlayerName)
    end
    --* add the functions to the Module
    Data_Controller["init"] = Init
    Data_Controller["GetPlayerAvatarData"] = Get_Player_Avatar_Data
    Data_Controller["ChangePlayerAvatarData"] = ChangePlayerAvatarData
    Data_Controller["Save_allPlayers_Data"]= Save_allPlayers_Data
    Data_Controller["Cleanup"] = Cleanup
    Data_Controller["Add_To_Profiles"] = Add_To_Profiles
    Data_Controller["Get_Player_Inventory_Data"] = Get_Player_Inventory_Data
    Data_Controller["Get_ActiveSlot"] = Get_ActiveSlot
    Data_Controller["Get_SlotDS"] = Get_SlotDS
end

--[[Data Store Plan
Slots Data Store {
    --* for the main menu
    buffer with {
        DataSize, What it is , Offset in the buffer
        -u16      hair          0
        -u16      Shirt         2
        -u16      Pants         4
        -u16      Eyes          6
        -u16      Mouth         8
    }- 10 bytes
    buffer with {
        DataSize, What it is , Offset in the buffer
        -u8x3    RGB hair,    0, 2
        -u8x3    RGB Shirt    3, 5
        -u8x3    RGB Pants    6, 8
        -u8x3    RGB Eyes     9, 11
        -u8x3    RGB Mouth    12, 14
        -u8x3    RGB Skin     15, 17
    } 18 bytes

}
Inventory Data Store {
    --*this Store will not be needed in the Main menu Starter Place
    It would be a single buffer all u16 values and recieve via the Itemencyclopedia
    u16 Item , u16 Amount_of_that_Item (loop read in 4 bytes at a time)
    save up to 100 unique items --*gamepass to increase to 200 
} 
]]
return Data_Controller