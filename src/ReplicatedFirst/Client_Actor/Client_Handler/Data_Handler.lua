--[[ Data Format for this game: --! PLEASE READ
AvatarBuffer always 10 bytes 5 u16 values. Each value represents which Hair or Eyes or Pants ... etc it is.
--*[offset = u16]:
0 = Hair, 2 = Shirt, 4 = Pants, 6 = Eyes, 8 = Mouth,

AvatarRGBBuffer always 18 bytes 18 u8 values. Every 3 values reprsent the RGB of each Item (Hair, Eyes, ...)
--* [offset n1 -> n3 = u8x3]
0 -> 2 = RGBHair, 3 -> 5 = RGBShirt, 6 -> 8 = RGBPants, 9 -> 11 = RGBEyes, 12 -> 14 = RGBMouth, 15 -> 17 = RGBSkin, 

]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SharedExports = require(ReplicatedStorage.Shared.SharedType)

--* Client Reading and writing their data  cos the data shoudl  always be in buffer format 
local Data_Handler = {}

local Write_Avatar_Data_Func = function(ItemCountTable: SharedExports.ChosenItemNumbers, ColorOfItems: SharedExports.Color_Of_Items)
    local Writeu8 = buffer.writeu8
    local Writeu16 = buffer.writeu16
    
    local AvatarBuffer = buffer.create(10)
    local AvatarRGBBuffer = buffer.create(18)
    local HairCount = ItemCountTable.Hair
    local ShirtCount = ItemCountTable.Shirt
    local PantsCount = ItemCountTable.Pants
    local EyesCount = ItemCountTable.Eyes
    local MouthCount = ItemCountTable.Mouth
    Writeu16(AvatarBuffer, 0, HairCount)
    Writeu16(AvatarBuffer, 2, ShirtCount)
    Writeu16(AvatarBuffer, 4, PantsCount)
    Writeu16(AvatarBuffer, 6, EyesCount)
    Writeu16(AvatarBuffer, 8, MouthCount)
    
    local HairRGB = ColorOfItems.Hair
    local ShirtRGB = ColorOfItems.Shirt
    local PantsRGB = ColorOfItems.Pants
    local EyesRGB = ColorOfItems.Eyes
    local MouthRGB = ColorOfItems.Mouth
    local SkinRGB = ColorOfItems.Skin

    Writeu8(AvatarRGBBuffer, 0, HairRGB.R)
    Writeu8(AvatarRGBBuffer, 1, HairRGB.G)
    Writeu8(AvatarRGBBuffer, 2, HairRGB.B)
    
    Writeu8(AvatarRGBBuffer, 3, ShirtRGB.R)
    Writeu8(AvatarRGBBuffer, 4, ShirtRGB.G)
    Writeu8(AvatarRGBBuffer, 5, ShirtRGB.B)

    Writeu8(AvatarRGBBuffer, 6, PantsRGB.R)
    Writeu8(AvatarRGBBuffer, 7, PantsRGB.G)
    Writeu8(AvatarRGBBuffer, 8, PantsRGB.B)
    
    Writeu8(AvatarRGBBuffer, 9, EyesRGB.R)
    Writeu8(AvatarRGBBuffer, 10, EyesRGB.G)
    Writeu8(AvatarRGBBuffer, 11, EyesRGB.B)
    
    Writeu8(AvatarRGBBuffer, 12, MouthRGB.R)
    Writeu8(AvatarRGBBuffer, 13, MouthRGB.G)
    Writeu8(AvatarRGBBuffer, 14, MouthRGB.B)
    
    Writeu8(AvatarRGBBuffer, 15, SkinRGB.R)
    Writeu8(AvatarRGBBuffer, 16, SkinRGB.G)
    Writeu8(AvatarRGBBuffer, 17, SkinRGB.B)
     
    return AvatarBuffer, AvatarRGBBuffer
end

local Read_Avatar_Data_Func = function (Data: SharedExports.PlayerInfo, AvatarBuffer:buffer, AvatarRGBBuffer:buffer)
    local Readu8 = buffer.readu8
    local Readu16 = buffer.readu16
    
    Data.Hair.Count = Readu16(AvatarBuffer, 0)
    Data.Shirt.Count = Readu16(AvatarBuffer, 2)
    Data.Pants.Count = Readu16(AvatarBuffer, 4)
    Data.Eyes.Count = Readu16(AvatarBuffer, 6)
    Data.Mouth.Count = Readu16(AvatarBuffer, 8)

    Data.Hair.R, Data.Hair.G, Data.Hair.B = Readu8(AvatarRGBBuffer, 0), Readu8(AvatarRGBBuffer, 1), Readu8(AvatarRGBBuffer, 2)
    Data.Shirt.R, Data.Shirt.G, Data.Shirt.B = Readu8(AvatarRGBBuffer, 3), Readu8(AvatarRGBBuffer, 4), Readu8(AvatarRGBBuffer, 5)
    Data.Pants.R, Data.Pants.G, Data.Pants.B = Readu8(AvatarRGBBuffer, 6), Readu8(AvatarRGBBuffer, 7), Readu8(AvatarRGBBuffer, 8)
    Data.Eyes.R, Data.Eyes.G, Data.Eyes.B = Readu8(AvatarRGBBuffer, 9), Readu8(AvatarRGBBuffer, 10), Readu8(AvatarRGBBuffer, 11)
    Data.Mouth.R, Data.Mouth.G, Data.Mouth.B = Readu8(AvatarRGBBuffer, 12), Readu8(AvatarRGBBuffer, 13), Readu8(AvatarRGBBuffer, 14)
    Data.Skin.R, Data.Skin.G, Data.Skin.B = Readu8(AvatarRGBBuffer, 15), Readu8(AvatarRGBBuffer, 16), Readu8(AvatarRGBBuffer, 17)
    
    return Data
end
Data_Handler["Write_Avatar_Data_Func"] = Write_Avatar_Data_Func
Data_Handler["Read_Avatar_Data_Func"] = Read_Avatar_Data_Func
return Data_Handler