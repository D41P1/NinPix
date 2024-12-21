local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- local Cleanup_Manager = require(ReplicatedStorage.Shared.Cleanup_Manager)
-- local State_Dictionary = require(ReplicatedStorage.Shared.State_Dictionary)
-- local NumToSymbol = require(ReplicatedStorage.Shared.NumToSymbol)
-- local CombatController = require(ServerScriptService.Server.ServerActor.Server_Script.CombatController)
local Item_Dictionary = require(ReplicatedStorage.Shared.Item_Dictionary)
local PlayerBan_Manager = require(ServerScriptService.Server.ServerActor.Server_Script.PlayerBan_Manager)

local BCreate = buffer.create
local BCopy = buffer.copy
local Len = buffer.len
local Merge_Buffers = function(MainBuffer:buffer, Buffers:{buffer})
    local Length_Of_Old_Buffer = Len(MainBuffer)
    local Full_Length = Length_Of_Old_Buffer
    for _, all_Buffers in Buffers do 
        Full_Length += Len(all_Buffers)
    end
    local Whole_Buffer = BCreate(Full_Length) 
    BCopy(Whole_Buffer, 0, MainBuffer, 0, Length_Of_Old_Buffer)
    local offset = Length_Of_Old_Buffer
    for _, all_Buffers in Buffers do 
        local Length_Of_buffer = Len(all_Buffers)
        BCopy(Whole_Buffer, offset, all_Buffers, 0, Length_Of_buffer)
        offset += Length_Of_buffer
    end
    return Whole_Buffer
end
local Inventory_Logic = {}

local Toolbar_Keys = {
    [Enum.KeyCode.One.Value]    = 0, 
    [Enum.KeyCode.Two.Value]    = 0, 
    [Enum.KeyCode.Three.Value]  = 0, 
    [Enum.KeyCode.Four.Value]   = 0, 
    [Enum.KeyCode.Five.Value]   = 0, 
    [Enum.KeyCode.Six.Value]    = 0, 
    [Enum.KeyCode.Seven.Value]  = 0, 
    [Enum.KeyCode.Eight.Value]  = 0, 
}
local Init_Toolbars = function(Inventory_Buffer:buffer, offset:number)
    --*ToolBar 2x16 = +32 0->30+2
    local LenB = buffer.len(Inventory_Buffer)
    local Ru16 = buffer.readu16
    local Toolbar1_Table = table.clone(Toolbar_Keys)
    local Toolbar2_Table = table.clone(Toolbar_Keys)
    for ToolKey_Value:number, _ in Toolbar1_Table do 
        if offset+2 > LenB then break end
        local Item_ID = Ru16(Inventory_Buffer, offset)
        offset += 2
        Toolbar1_Table[ToolKey_Value] = Item_ID    
    end
    for ToolKey_Value:number, _ in Toolbar2_Table do 
        if offset+2 > LenB then break end
        local Item_ID = Ru16(Inventory_Buffer, offset)
        offset += 2
        Toolbar2_Table[ToolKey_Value] = Item_ID    
    end
    local Values_To_Return = { Toolbar1_Table, Toolbar2_Table}
    return offset, Values_To_Return
end
local Init_Equipped = function(Inventory_Buffer:buffer, offset:number)
    --*ToolBar 2x6 = +12 32->42+2
    local LenB = buffer.len(Inventory_Buffer)
    local Ru16 = buffer.readu16
    local BodyKeys= {
        [1] = 0,
        [2] = 0,
        [3] = 0,
        [4] = 0,
        [5] = 0,
        [6] = 0
    }
    for i = 1, 6 do 
        if offset+2 > LenB then break end
        local Item_ID = Ru16(Inventory_Buffer, offset)
        offset += 2
        BodyKeys[i] = Item_ID
    end
    return offset, BodyKeys
end
local Init_Backpack = function(Inventory_Buffer:buffer, offset:number)
    local LenB = buffer.len(Inventory_Buffer)
    local Ru16 = buffer.readu16
    local Backpack = {}
    offset = 56
    for i = 1, LenB do
        if offset+4 > LenB then break end
        local Item_ID = Ru16(Inventory_Buffer, offset)
        offset+=2
        local Stack = Ru16(Inventory_Buffer, offset)
        offset+=2
        Backpack[Item_ID]=Stack        
    end
    return offset, Backpack
end
local Convert_To_Inventory_Buffer = function(Toolbars, BodyEquipped, CosmeticEquipped, Backpack)
    --* 0-30+2 toolbar1 -> toolbar2 16xu16 ; 32-42+2  6xu16 BodyFrame; 44 -> 56+2 CosmeticFrame (Not added yet); 58-1024_u16xu16 Backpack 
    local writeu16 = buffer.writeu16
    local ToolBar1:{number} = Toolbars[1]
    local ToolBar2:{number} = Toolbars[1]
    local ToolBarBuffer =  BCreate(32)
    local Body_Equipped_Buffer = BCreate(12) 
    local Cosmetic_Equipped_Buffer = BCreate(12) 
    local offset = 0
    for i = Enum.KeyCode.One.Value, 7 + Enum.KeyCode.One.Value do 
        writeu16(ToolBarBuffer, offset, ToolBar1[i])
        offset += 2
    end 
    offset = 0
    for i = Enum.KeyCode.One.Value, 7 + Enum.KeyCode.One.Value do 
        writeu16(ToolBarBuffer, offset, ToolBar2[i])
        offset += 2
    end 
    offset = 0
    for i = 1, 6 do 
        writeu16(Body_Equipped_Buffer, offset, BodyEquipped[i])
        offset += 2
    end 
    offset = 0  
    for i = 1, 6 do 
        writeu16(Cosmetic_Equipped_Buffer, offset, CosmeticEquipped[i])
        offset += 2
    end 
    offset = 0
    local Count = 0
    for _, _ in Backpack do
        Count += 1
    end
    local BackPack_Buffer = BCreate(Count *4)
    for ItemID, Stack in pairs(Backpack) do
        writeu16(BackPack_Buffer, offset, ItemID)
        offset += 2
        writeu16(BackPack_Buffer, offset, Stack)
        offset += 2
    end
    return Merge_Buffers(ToolBarBuffer, {Body_Equipped_Buffer, Cosmetic_Equipped_Buffer, BackPack_Buffer})
end
local Add_Item_To_Backpack = function(Backpack:{number}, Item_ID:number) : {number}
    if not Item_Dictionary[Item_ID] then  
        --* item does not exist in game
        warn("incorrect Item_ID: ", Item_ID, Item_Dictionary); 
        return Backpack 
    end 
    local Stack:number? = Backpack[Item_ID]
    if Stack then 
        Stack += 1
        Backpack[Item_ID] = Stack
    else
        Backpack[Item_ID] = 1
    end
    return Backpack
end
Inventory_Logic["Add_Item_To_Backpack"] = Add_Item_To_Backpack
Inventory_Logic["Init_Toolbars"] = Init_Toolbars
Inventory_Logic["Init_Equipped"] = Init_Equipped
Inventory_Logic["Init_Backpack"] = Init_Backpack
Inventory_Logic["Convert_To_Inventory_Buffer"] = Convert_To_Inventory_Buffer  

return Inventory_Logic