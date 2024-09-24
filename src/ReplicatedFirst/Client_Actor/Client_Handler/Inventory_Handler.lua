
--[[ BodyTable
1 = Head
2 = Body
3 = Right Arm
4 = Left Arm
5 = Right Leg
6 = Left Leg
]]
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")


local NumToSymbol = require(ReplicatedStorage.Shared.NumToSymbol)
local InputHandler = require(script.Parent.InputHandler)
local ClientCombatMachine = require(script.Parent.Parent.ClientCombatMachine)
local Gui_Handler = require(script.Parent.Gui_Handler)
-- local ClientMessageAPI = require(script.Parent.Parent.ClientMessageAPI)
local Event_Handler = require(script.Parent.Parent.Event_Handler)
local Shared =ReplicatedStorage.Shared 

-- local ItemManager = require(Shared.ItemManager)
local ItemDataMod = require(Shared.ItemDataMod)
local Encyclopedia = require(Shared.Encyclopedia)
local Inventory_Handler = {}
type  InventoryTool = typeof(Gui_Handler.InventoryGui.InventoryTool)

local InitGui = function(UID)
    Inventory_Handler["InventoryGui"] = Gui_Handler.InventoryGui
    Inventory_Handler["ToolBar"] = Gui_Handler.ToolBar
    Inventory_Handler["UID"] = tostring(UID)
    Gui_Handler.ToolBar.Enabled = true
    do
        local Button_Connections = {}
        local InventoryGui = Inventory_Handler.InventoryGui
        local ToolbarGui = Inventory_Handler.ToolBar
        
        local InventoryFrame = InventoryGui.InventoryFrame
        local BodyFrame = InventoryGui.BodyFrame
        local ToolBarFrame = ToolbarGui.ToolBarFrame

        local BodyTable:{[number]:string} = {
            [1] = "Head",
            [2] = "Body",
            [3] = "Right Arm",
            [4] = "Left Arm",
            [5] = "Right Leg",
            [6] = "Left Leg",                
        }
        local function Send_To_Server(InventoryTool:InventoryTool, EquipType: number, Key: number?)
            local Conns = Button_Connections[InventoryTool]
            if not Conns.ItemId then warn("no Item ID: ", Conns); return end
            -- local Stack_Count = tonumber(InventoryTool.StackLabel.Text) 
            local Length = 5
            local Item_Buffer = buffer.create(Length)
            buffer.writeu16(Item_Buffer, 0, Conns.ItemId)
            local Wu8 = buffer.writeu8
            Wu8(Item_Buffer, 2, EquipType)            
            if Key then  Wu8(Item_Buffer, 3, Key) end
            Event_Handler.Events.Inventory:FireServer(Item_Buffer)
        end
        local function HandleToolBar(InventoryTool: InventoryTool, CopyItemData: ItemDataMod.ItemData)
            ToolbarGui.PressKeyFrame.Visible = true
            local Conns = Button_Connections[InventoryTool]
            local ValidKeyCodes = {
                [Enum.KeyCode.One]= 1,
                [Enum.KeyCode.Two]= 2,
                [Enum.KeyCode.Three]= 3,
                [Enum.KeyCode.Four]= 4,
                [Enum.KeyCode.Five]= 5,
                [Enum.KeyCode.Six]= 6,
                [Enum.KeyCode.Seven]= 7,
                [Enum.KeyCode.Eight]= 8,
            }
            local Conn:RBXScriptConnection
            Conn = UserInputService.InputBegan:Connect(function(InputObject: InputObject, a1: boolean)  
                local LayoutOrder = ValidKeyCodes[InputObject.KeyCode]
                if LayoutOrder then 
                    Conn:Disconnect()
                    -- print(KeyCodes, LayoutOrder)
                    InventoryTool.LayoutOrder = LayoutOrder
                    ToolbarGui.PressKeyFrame.Visible = false
                    InventoryTool.Parent = ToolBarFrame
                    local StateMachine = ClientCombatMachine[Inventory_Handler.UID]
                    if not StateMachine then warn("incorrect UID : ", Inventory_Handler.UID,typeof(Inventory_Handler.UID) , Inventory_Handler, ClientCombatMachine); return end
                    local ActiveToolbar = StateMachine.ActiveToolbar
                    local Toolbar = StateMachine[ActiveToolbar]
                    if not Toolbar then warn("Client TOol bar error: ", Toolbar); return end
                    Toolbar[InputObject.KeyCode.Name] = Conns.ItemId         
                    Send_To_Server(InventoryTool, CopyItemData.EquipType, LayoutOrder)
                end
            end)
        end
        local function SortInventoryTool(InventoryTool, ItemName:string): ImageLabel?
            local Conns = Button_Connections[InventoryTool]
            local CopyItemData:ItemDataMod.ItemData = Conns.ItemData
            InventoryTool.TextLabel.Text = ItemName
            InventoryTool.Visible = true
            InventoryTool.StackLabel.Visible = false
            if CopyItemData.EquipType == 7 then 
                InventoryTool.LayoutOrder = 0
                HandleToolBar(InventoryTool, CopyItemData)
                return InventoryTool
            end
            local Place_To_Be = BodyTable[CopyItemData.EquipType]
            InventoryTool.Parent = BodyFrame[Place_To_Be]
            Send_To_Server(InventoryTool, CopyItemData.EquipType)            
            return InventoryTool
        end
        local  function ToolEquip_Func(InventoryTool, ItemName)  
            local Conns = Button_Connections[InventoryTool]
            if Conns.EquipBool then return end
            Conns.EquipBool = true
            local ItemId = Conns.ItemId
            if not ItemId then warn("incorrect Item ID: ", ItemId, Conns); return end
            -- print("Stacklabel text", InventoryTool.StackLabel.Text)
            SortInventoryTool(InventoryTool, ItemName)
        end
        local Tool_Un_Equip = function (InventoryTool: InventoryTool)
            local Conns = Button_Connections[InventoryTool]
            if not Conns.EquipBool then return end
            Conns.EquipBool = nil            
            local CopyItemData:ItemDataMod.ItemData = Conns.ItemData
            local Stack_Count = tonumber(InventoryTool.StackLabel.Text)
            local Item_Buffer = buffer.create(5)--leave first u16 0 for server to know you unequipped
            local Wu8 = buffer.writeu8
            
            buffer.writeu16(Item_Buffer, 0, Conns.ItemId)
            Wu8(Item_Buffer, 2, CopyItemData.EquipType)
            Wu8(Item_Buffer, 3, InventoryTool.LayoutOrder)
            Wu8(Item_Buffer, 4, 1)

            Event_Handler.Events.Inventory:FireServer(Item_Buffer)
            InventoryTool.StackLabel.Text = tostring(Stack_Count) 
            InventoryTool.StackLabel.Visible = true
            InventoryTool.Parent = InventoryFrame

            local Frame = InputHandler["CurrentFrame"]
            if not Frame then return end 
            local Event = Event_Handler.Events.Tool
            local CurrentFrame: number = Frame
            local FrameBuffer = buffer.create(2) -- gonna write key pressed u8
            buffer.writeu8(FrameBuffer, 0, CurrentFrame)
            local Key:string = NumToSymbol.GiveString(InventoryTool.LayoutOrder)
            local StateMachine = ClientCombatMachine[Inventory_Handler.UID]
            if not StateMachine then warn("inccorecect UID: ", UID, ClientCombatMachine); return end
            ClientCombatMachine.ForceState(Inventory_Handler.UID, "WeaponOut") --* just to double make sure
            ClientCombatMachine.TriggerAction(InputHandler["Character"], Event, "ToolHandle", Key, FrameBuffer)

            local Active = StateMachine.ActiveToolbar
            local ToolBar = StateMachine[Active]
            if not ToolBar then warn("ERROR did not get Unequip: ", UID, StateMachine); return end
            ToolBar[Key] = nil
            warn("unequipping", ToolBar)
        end
        local AddConnections_Inventory = function(ItemName:string, Count:number?)
            if not ItemDataMod[ItemName] then warn("incorrect ItemName: ", ItemName, ItemDataMod); return end
            local InventoryTool = InventoryGui.InventoryTool:Clone()
            InventoryTool.TextLabel.Text = ItemName or "TEST"
            if not Count then warn("stack text"); Count = 1 end
            InventoryTool.StackLabel.Text = tostring(Count)
            -- print("set Stack text", InventoryTool.StackLabel.Text)
            InventoryTool.Visible = true
            InventoryTool.Parent = InventoryFrame
            InventoryTool.Name = ItemName
            Button_Connections[InventoryTool] = {}        
            Button_Connections[InventoryTool].ItemId = Encyclopedia.GiveNumRef(ItemName) 
            Button_Connections[InventoryTool].ItemData = ItemDataMod.GiveCopyData(ItemName)
            Button_Connections[InventoryTool].Connections = {}                    
            local MouseClick = InventoryTool.MouseButton1Click:Connect(function(...: any)  
                InventoryTool.Frame.Visible = true
            end)
            local ToolEquip_MouseClick = InventoryTool.Frame.Equip.MouseButton1Click:Connect(function(...: any)  
                ToolEquip_Func(InventoryTool, ItemName)
                InventoryTool.Frame.Visible = false
            end)
            local Tool_Un_Equip_MouseClick = InventoryTool.Frame.Unequip.MouseButton1Click:Connect(function(...: any)  
                Tool_Un_Equip(InventoryTool)
                -- local CopyData = ItemDataMod.GiveCopyData(ItemName)
                InventoryTool.Frame.Visible = false
                --TODO only problem is that players can unequip a weapon whilst still holding it shouldn't cause an error but whatever
            end)
            Button_Connections[InventoryTool].Connections.EquipRBXSC = ToolEquip_MouseClick
            Button_Connections[InventoryTool].Connections.Un_EquipRBXSC = Tool_Un_Equip_MouseClick
            Button_Connections[InventoryTool].Connections.MouseClick = MouseClick
            return InventoryTool
        end
        local Init_Inventory = function(Inventory_Buffer:buffer)    
            local LenB = buffer.len(Inventory_Buffer)
            local Ru16 = buffer.readu16
            local ToolbarTable = {}
            local BodyFrameTable= {}
            --* the +1 is the UID offset 
            for i = 0+1, 30+1, 2 do --*ToolBar 2x16 = 32
                local Item_ID = Ru16(Inventory_Buffer, i)
                local ItemName = Encyclopedia.GiveString(Item_ID)
                if not ItemName then  continue end
                ToolbarTable[ItemName] = (i+1)/2
            end
            for i = 32+1, 42+1, 2 do --*BodyFrame 2x6 = 12
                local Item_ID = Ru16(Inventory_Buffer, i)
                local ItemName = Encyclopedia.GiveString(Item_ID)
                if not ItemName then  continue end
                BodyFrameTable[ItemName] = Item_ID
            end
            for i = 44+1, LenB+1, 4 do --* inventory
                if i+2 >= LenB+1 then break end
                local Item_ID = Ru16(Inventory_Buffer, i)
                local StackCount = Ru16(Inventory_Buffer, i +2)
                local ItemName = Encyclopedia.GiveString(Item_ID)
                if not ItemName then warn("Invalid Name"); continue end
                local ItemData = ItemDataMod.GiveCopyData(ItemName)
                if not ItemData then warn("Invalid Name 2"); continue end
                local InventoryTool = AddConnections_Inventory(ItemName, StackCount)
                local Tool_LayoutOrder = ToolbarTable[ItemName]
                if  Tool_LayoutOrder then 
                    InventoryTool.StackLabel.Visible = false
                    InventoryTool.LayoutOrder = Tool_LayoutOrder
                    InventoryTool.Parent = ToolBarFrame
                elseif BodyFrameTable[ItemName] then
                    --[[  
                    if StackCount >1 then 
                        InventoryTool.StackLabel.Text = tostring(StackCount - 1)
                        InventoryTool = InventoryTool:Clone()
                    end
                    
                    ]]
                    local Parent = ItemData.EquipType
                    if Parent >= 7 then warn("an Error EquipType: ", ItemName, Parent); continue end
                    local BodyPart = BodyTable[Parent]
                    InventoryTool.StackLabel.Visible = false
                    InventoryTool.Parent = BodyFrame[BodyPart]
                end
            end
            -- print("Done Init Invetory and toolbar: ", ToolbarTable)
        end
        Inventory_Handler["AddConnections"]= AddConnections_Inventory
        Inventory_Handler["Init_Inventory"] = Init_Inventory
        Inventory_Handler["Tool_Un_Equip"] = Tool_Un_Equip
    end
end


Inventory_Handler["InitGui"] = InitGui
return Inventory_Handler