local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Cleanup_Manager = require(ReplicatedStorage.Shared.Cleanup_Manager)
local Encyclopedia = require(ReplicatedStorage.Shared.Encyclopedia)
local NumToSymbol = require(ReplicatedStorage.Shared.NumToSymbol)
local CombatController = require(ServerScriptService.Server.ServerActor.Server_Script.CombatController)
local PlayerBan_Manager = require(ServerScriptService.Server.ServerActor.Server_Script.PlayerBan_Manager)

-- Required by CharacterScript in CharActor
local Inventory_Logic = {}
local Init_Inventory = function(Inventory_Buffer:buffer, UID:number)
    --* does NOT have UID offset so start = 0 index
    Inventory_Logic["Inventory"] = Inventory_Buffer
    Inventory_Logic["UID"] = tostring(UID)
end 
do
    local Currently_Equipped = {}
    local function SetStateMachine_ToolBar(Key_Pressed:number, Item_ID:number, Bool:boolean?)
        local StateMachine = CombatController[Inventory_Logic.UID]
        if not StateMachine then warn("incorrect UID must be string", Inventory_Logic.UID); return end
        local Active_Toolbar = StateMachine.ActiveToolbar
        local Symbol = NumToSymbol.GiveString(Key_Pressed)
        local Toolbar = StateMachine[Active_Toolbar]
        if not Toolbar then warn("an error with Toolbar"); return end
        if Bool then Toolbar[Symbol] = nil; return end
        Toolbar[Symbol] = Item_ID
        -- CombatController.TriggerAction(Inventory_Logic.UID, "ToolHandle")
        
        -- warn("THE TOOOLBARRR Server:", Toolbar)
    end
    local EquipFuncs = {
        --* 0 = Equip , 1 = Unequip
        [0] = function(player:Player, Item_Buffer:buffer)
            local ServerInventory = Inventory_Logic.Inventory
            local LenB = buffer.len(ServerInventory)
            local Ru16  =buffer.readu16 
            local Ru8 = buffer.readu8
            local Wu16 = buffer.writeu16
            local Client_ItemID  = Ru16(Item_Buffer, 0)
            local Item_EquipType = Ru8(Item_Buffer, 2)
            local Key_Pressed = Ru8(Item_Buffer, 3)
            Key_Pressed = math.clamp(Key_Pressed, 1, 8)
            Item_EquipType = math.abs(Item_EquipType)
            for i = 44 , LenB, 4 do 
                if i + 2 >= LenB then return end
                local Item_ID  = Ru16(ServerInventory, i)
                -- print(Item_ID)
                if Client_ItemID ~= Item_ID then  continue end
                Wu16(ServerInventory, i, 0)
                if Item_EquipType >= 7 then 
                    --* its a tool
                    local offset = (Key_Pressed *2) - 2 --* 1-16 = 0->30+2 u16
                    Wu16(ServerInventory, offset, Item_ID)
                    SetStateMachine_ToolBar(Key_Pressed, Item_ID)

                    --TODO you would fire here GlobalInventoryEvent the entire Buffer
                    -- print(offset, (Key_Pressed*2) -2, "A Weapon/skill equip", Ru16(ServerInventory, i), Ru16(ServerInventory, offset))
                else
                    --* its a Body Frame Armour
                    local offset = (Key_Pressed *2) + 30 --* 1-6 = 32->42+2 u16  
                    Wu16(ServerInventory, offset, Item_ID)
                    -- print(offset, Item_EquipType, "An Armour equip")
                    --TODO you would fire here GlobalInventoryEvent the entire Buffer
                end
                local Current_Equipped_Buffer = buffer.create(4)
                Wu16(Current_Equipped_Buffer, 0, Item_ID)
                Wu16(Current_Equipped_Buffer, 2, i)
                Currently_Equipped[Key_Pressed] = Current_Equipped_Buffer
                break
            end    
        end,
        [1] = function(player:Player, Item_Buffer:buffer)
            local ServerInventory = Inventory_Logic.Inventory
            local LenB = buffer.len(ServerInventory)
            local Ru16  =buffer.readu16 
            local Ru8 = buffer.readu8
            local Wu16 = buffer.writeu16
            local Client_ItemID  = Ru16(Item_Buffer, 0)
            local Item_EquipType = Ru8(Item_Buffer, 2)
            local Key_Pressed = Ru8(Item_Buffer, 3)
            Key_Pressed = math.clamp(Key_Pressed, 1, 8)
            Item_EquipType = math.abs(Item_EquipType)
            
            local Currently_Equipped_buffer:buffer  = Currently_Equipped[Key_Pressed] --change here
            if not Currently_Equipped_buffer then warn("nothing currently equipped at that key: ", Key_Pressed);  return end
            local Item_ID = Ru16(Currently_Equipped_buffer, 0)
            --* attempting to unequip something they do not have equipped at that key
            if Client_ItemID ~= Item_ID then  warn("Item ID does not match: ", Client_ItemID, Item_ID); PlayerBan_Manager:Ban(7, 2); return end
            local offset = Ru16(Currently_Equipped_buffer, 2)
            -- if Client_ItemID ~= Item_ID then  continue end
            warn("ServerInventory writing in this offset unequip: ", offset, Item_ID)
            if Item_EquipType >= 7 then 
                --* tool  unequiping
                Wu16(ServerInventory, offset, Item_ID)
                SetStateMachine_ToolBar(Key_Pressed, Item_ID, true)
                -- print(offset, Item_EquipType, "An weapon Unequip")
                --TODO you would fire here GlobalInventoryEvent the entire Buffer
            else
                --* Body Frame Armour unequipping
                Wu16(ServerInventory, offset, Item_ID)
                -- print(offset, Item_EquipType, "An Armour Unequip")
                --TODO you would fire here GlobalInventoryEvent the entire Buffer
            end

        end
    }
    local Receive = function(player:Player, Item_Buffer:buffer, ...: any)
        --TODO add RateLimiter
        --TODO add an SharedInventory Event so other clients can sync what player has done and update
        if typeof(Item_Buffer) ~= "buffer" then PlayerBan_Manager.Ban(player, 7, 2);  return end
        local LenB = buffer.len(Item_Buffer)
        if LenB ~= 5 then PlayerBan_Manager.Ban(player, 7, 2);  return end
        local Func = buffer.readu8(Item_Buffer, 4)
        if not EquipFuncs[Func] then warn("FUNC: ", Func, EquipFuncs);  PlayerBan_Manager.Ban(player, 7, 2); return  end
        EquipFuncs[Func](player, Item_Buffer)
    end

    Inventory_Logic["Recieve"] = Receive
end
Inventory_Logic["Init_Inventory"] = Init_Inventory

return Inventory_Logic