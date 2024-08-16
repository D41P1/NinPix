--[[ Data Format for this game: --! PLEASE READ
AvatarBuffer always 10 bytes 5 u16 values. Each value represents which Hair or Eyes or Pants ... etc it is.
--*[offset = u16]:
0 = Hair, 2 = Shirt, 4 = Pants, 6 = Eyes, 8 = Mouth,

AvatarRGBBuffer always 18 bytes 18 u8 values. Every 3 values reprsent the RGB of each Item (Hair, Eyes, ...)
--* [offset n1 -> n3 = u8x3]
0 -> 2 = RGBHair, 3 -> 5 = RGBShirt, 6 -> 8 = RGBPants, 9 -> 11 = RGBEyes, 12 -> 14 = RGBMouth, 15 -> 17 = RGBSkin, 

AvatarDS = DataStore for Avatar,
Scope is Global (so no scope), 
Key = PlayerName.. "Avatar" and PlayerName.. "AvatarRGB" (both should result in buffers)
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

local Data_Manager = {}
type DataBuffer = {
    AvatarBuffer:buffer,
    AvatarRGBBuffer:buffer,
    [string]: buffer
}
type DataProfiles = {
    [string] :DataBuffer
}
do 
    local AvatarDS 
    local Profiles:DataProfiles = {}
    local Save_allPlayers_Avatar = function ()
        for PlayerName, Player_Profile in Profiles do
            RunService.Heartbeat:Wait() 
            pcall(function()
                AvatarDS:SetAsync(PlayerName.."Avatar", Player_Profile.AvatarBuffer)
                RunService.Heartbeat:Wait()
                AvatarDS:SetAsync(PlayerName.."AvatarRGB", Player_Profile.AvatarRGBBuffer)
            end)
            RunService.Heartbeat:Wait() 
        end
    end
    local GetPlayerAvatarData = function(player:Player): DataBuffer
        local DataBuffer
        local Success, Error = pcall(function()  
            local AvatarBuffer:buffer? =  AvatarDS:GetAsync(player.Name.."Avatar")
            if not AvatarBuffer then 
                --* first time joining default data 
                local NewAvatarBuffer = buffer.create(10)
                local offset = 0
                for i = 1, 4 do 
                    offset += 2
                    buffer.writeu16(NewAvatarBuffer, offset, 1)
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

                local Player_Profile:DataBuffer  = {
                    ["AvatarBuffer"] = NewAvatarBuffer,
                    ["AvatarRGBBuffer"] = NewAvatarRGBBuffer
                }
                Profiles[player.Name] = Player_Profile
                DataBuffer = Player_Profile
                return
            end
            local AvatarRGBBuffer:buffer? = AvatarDS:GetAsync(player.Name.."AvatarRGB")
            local Player_Profile:DataBuffer  = {
                ["AvatarBuffer"] = AvatarBuffer,
                ["AvatarRGBBuffer"] = AvatarRGBBuffer
            }  
            local PlayerName = player.Name
            Profiles[PlayerName] = Player_Profile
            DataBuffer= Player_Profile 
            return
        end)
        if not Success then  
            warn(Error);  player:Kick(Error)
        end
        return DataBuffer
    end 
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
        Profiles[player.Name] = {
            ["AvatarBuffer"]  =  AvatarBuffer,
            ["AvatarRGBBuffer"] = AvatarRGBBuffer
        }
    end
    
    local Init = function()
        local Success, Error = pcall(function()  
            AvatarDS = DataStoreService:GetDataStore("AvatarDS")
            AvatarDS:GetAsync("TEST")
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
    do 
        local D, S = 0, 120 -- 0, 120 in PROD
        RunService.Heartbeat:Connect(function(a0: number)  
            D += a0
            if D >= S then 
                D -= S
                print("Saving Players Data")
                Save_allPlayers_Avatar()
            end
        end)
    end
    local Cleanup = function(PlayerName:string)
        Profiles[PlayerName] = nil
    end

    --* add the functions to the Module
    Data_Manager["init"] = Init
    Data_Manager["GetPlayerAvatarData"] = GetPlayerAvatarData
    Data_Manager["ChangePlayerAvatarData"] = ChangePlayerAvatarData
    Data_Manager["Save_allPlayers_Avatar"]= Save_allPlayers_Avatar
    Data_Manager["Cleanup"] = Cleanup
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
    It would be a single buffer all u16 values and recieve via the Encyclopedia
    u16 Item , u16 Amount_of_that_Item (loop read in 4 bytes at a time)
    save up to 100 unique items --*gamepass to increase to 200 
} 
]]


return Data_Manager