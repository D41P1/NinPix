
--[[ BodyTable
1 = Head
2 = Body
3 = Right Arm
4 = Left Arm
5 = Right Leg
6 = Left Leg
]]
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local NumToSymbol = require(ReplicatedStorage.Shared.NumToSymbol)
local InputHandler = require(script.Parent.InputHandler)
local ClientCombatMachine = require(script.Parent.Parent.ClientCombatMachine)
local Gui_Handler = require(script.Parent.Gui_Handler)
-- local ClientMessageAPI = require(script.Parent.Parent.ClientMessageAPI)
-- local Event_Handler = require(script.Parent.Parent.Event_Handler)
local Shared =ReplicatedStorage.Shared 

-- local ItemManager = require(Shared.ItemManager)
local ItemDataMod = require(Shared.ItemDataMod)
local Inventory_Handler = {}
type  InventoryTool = typeof(Gui_Handler.InventoryGui.InventoryTool)
local InitGui = function(UID)
    Inventory_Handler["InventoryGui"] = Gui_Handler.InventoryGui
    Inventory_Handler["UID"] = tostring(UID)
    
end
--* they have 2 Toolbars press R  to switch between them (1 -> 8 keys twice) ↓
--* + 16 bcos 1 -> 8 twice
--* + 12 bcos 6 Items they would have equipped the So Equipped Table
--* + Length of the bag  Init the Backpack (or bag) 
--? Remember the InventoryLength is the Entire Inventory (made up of 3 parts the 2 toolbars (32b) the Equipped Table (12b) and the Backpack ( >=0b))
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
local Init_Toolbars = function(Everything_Buffer:buffer, offset:number)
    --*ToolBar 2x16 = 32
    local LenB = buffer.len(Everything_Buffer)
    local Ru16 = buffer.readu16
    local Toolbar1_Table = table.clone(Toolbar_Keys)
    local Toolbar2_Table = table.clone(Toolbar_Keys)
    for ToolKey_Value:number, _ in Toolbar1_Table do 
        if offset+2 > LenB then break end
        local Item_ID = Ru16(Everything_Buffer, offset)
        offset += 2
        Toolbar1_Table[ToolKey_Value] = Item_ID    
    end
    for ToolKey_Value:number, _ in Toolbar2_Table do 
        if offset+2 > LenB then break end
        local Item_ID = Ru16(Everything_Buffer, offset)
        offset += 2
        Toolbar2_Table[ToolKey_Value] = Item_ID    
    end
    local Values_To_Return = { Toolbar1_Table, Toolbar2_Table}
    return offset, Values_To_Return
end
local Init_Equipped =  function(Everything_Buffer:buffer, offset:number)
    local LenB = buffer.len(Everything_Buffer)
    local Ru16 = buffer.readu16
    local Equipped_Table= {}
    for i = 1, 6 do 
        if offset+2 > LenB then break end
        local Item_ID = Ru16(Everything_Buffer, offset)
        offset += 2
        table.insert(Equipped_Table, Item_ID)
    end
    return offset, Equipped_Table
end
local Init_BackPack = function(Everything_Buffer:buffer, offset:number, InventoryLength:number)
    local LenB = buffer.len(Everything_Buffer)
    local Ru16 = buffer.readu16
    local BackPack= {}
    for i = 1, LenB do 
        if offset+4 > LenB then break end
        local Item_ID = Ru16(Everything_Buffer, offset)
        offset += 2
        local Stack = Ru16(Everything_Buffer, offset)
        offset += 2
        BackPack[Item_ID] = Stack
    end
    return offset, BackPack
end
Inventory_Handler["Init_Toolbars"] = Init_Toolbars
Inventory_Handler["Init_BackPack"] = Init_BackPack
Inventory_Handler["Init_Equipped"] = Init_Equipped

Inventory_Handler["InitGui"] = InitGui
return Inventory_Handler