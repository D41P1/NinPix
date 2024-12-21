local SSS = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local CharacterActors = workspace.WorkSpaceFolder.CharacterActors
local Shared = ReplicatedStorage.Shared
local ServerScript = SSS.Server.ServerActor.Server_Script
local Skill_Infos = require(Shared.Skill_Infos)
local Buffer_Converter = require(Shared.Buffer_Converter)
local Item_Dictionary = require(Shared.Item_Dictionary)
local RateLimiter = require(Shared.RateLimiter)
local Util = require(ServerScript.Util)
local State_Dictionary = require(Shared.State_Dictionary)
local ItemDataMod = require(Shared.ItemDataMod)
local MessageAPI = require(ServerScript.MessageAPI)
local SharedType = require(Shared.SharedType)
local HumanoidMachine = require(Shared.HumanoidMachine)

local CombatController = require(ServerScript.CombatController)
local Character_Scripts_Folder= ServerScript.Character_Scripts_Folder
local Character_Controller = require(ServerScript.Character_Scripts_Folder.Character_Controller) 
local MovementLogic = require(Character_Scripts_Folder.MovementLogic); 
local InventoryLogic = require(Character_Scripts_Folder.InventoryLogic)
local UID  = script:GetAttribute("UID")
local SSS_Bind:BindableEvent = script.Bind
local SSS_Communicate = MessageAPI["MT"]
local ForwardActor 
-- Character_Controller["Actor"] = CharacterActor
-- Character_Controller:InitEvents(CharacterActor.Name)
-- MovementLogic.Init(Character_Controller)
-- local NumUID = tonumber(UID)
--* Update Server Humanoid
--TODO making combat will be Main thread now (SendMessages are just too costly not worth it Main thread is currently not even being used beyond ~5%) 
-- CharacterActor:BindToMessage("InitHotbarInfo", function(Inventory_Buffer:buffer)    
    --[[
    local StateNum = State_Dictionary.GiveNumRef(CombatMachine.CurrentState)
    local ActionNum = State_Dictionary.GiveNumRef(CombatMachine.Action)
    
    local Length = 5  
    local Profile = buffer.create(Length) 
    local writeu8 = buffer.writeu8
    writeu8(Profile, 0, Length)
    writeu8(Profile, 1, tonumber(UID))
    writeu8(Profile, 2, StateNum)
    writeu8(Profile, 3, ActionNum)
    MessageAPI.SendToCombat("UpdWithFrame", 4, Profile)
    ]]
    
-- end)
-- local SSS_MT 
-- local Connections = {}
local Toolbars 
local ActiveToolbarNum = 1
local BodyEquipped
local Backpack
local Bind_Functions = {}
local CPProfile
local DashCD, DashUnix = 4400, DateTime.now().UnixTimestampMillis
local JumpCD, JumpUnix = 4400, DateTime.now().UnixTimestampMillis
local WallRunCD, WallRunUnix = 400, DateTime.now().UnixTimestampMillis
local EquipCD, EquipUnix = 1300, DateTime.now().UnixTimestampMillis
Bind_Functions.Init = function(UID, Data: SharedType.NPCData, Inventory_Buffer)  
    local CFV:CFrameValue = unpack(CollectionService:GetTagged(UID.."CFV"))  
    local BodyCFPart:Part = unpack(CollectionService:GetTagged(UID.."Body"))
    if not CFV then warn("no CFV detected: ", UID); return end
    if not BodyCFPart then warn("no BODY_CF_PART  detected: ", UID); return end

    local PhysicsDirectionV3 = Instance.new("Vector3Value")
    PhysicsDirectionV3.Value = Vector3.zero
    PhysicsDirectionV3:AddTag(UID.."ServerDirection")
    PhysicsDirectionV3.Parent = script
    
    local PhysicsFolder = Instance.new("Folder")
    PhysicsFolder.Name = UID
    PhysicsFolder.Parent = ServerScript

    local VNV:NumberValue = Instance.new("NumberValue")
    VNV:AddTag(UID.."SVNV") --* Server Velocity Number Value
    VNV.Parent = PhysicsFolder

    local LookV3:Vector3Value= Instance.new("Vector3Value")
    LookV3:AddTag(UID.."SLV3") --* 
    LookV3.Parent = PhysicsFolder
    
    local UV3V:Vector3Value= Instance.new("Vector3Value")
    UV3V.Value= Vector3.new(0, 1, 0)
    UV3V:AddTag(UID.."SUV3V") --* Server UpVector3 Value    
    UV3V.Parent = PhysicsFolder
    
    ForwardActor = MessageAPI.InitServerCharacter(script)
    task.delay(1, function()
        ForwardActor:SendMessage("Init", UID)
    end)
    ForwardActor.Name = "FA"
    CPProfile = Character_Controller.Give_Profile(UID)
    CPProfile["FA"] = ForwardActor
    CPProfile["CFV"] = CFV --*Important for the FSM
    CPProfile["BodyPart"] = BodyCFPart
    CPProfile["VNV"] = VNV
    CPProfile["UV3V"] = UV3V
    CPProfile["LV3"] = LookV3
    Toolbars = CPProfile.Toolbars
    Backpack = CPProfile.Backpack
    BodyEquipped = CPProfile.BodyEquipped
    CPProfile.Current_Skill_Item = 0
    CPProfile.Current_Weapon_Item = 0

    local CombatStates = require(ServerScript.ServerCombatStateMods.ServerCombatStates)
    local CombatProfile = CombatController:InitCombatMachine(UID, CombatStates, Inventory_Buffer)
    CombatProfile.Toolbars = CPProfile.Toolbars
    
    HumanoidMachine:InitServerHumanoid(UID, require(ServerScript.Humanoid_Controller))
    SSS_Communicate("UpdCS", {UID, 1, 1}) --* UID, StateNum, ActionNum ; (See State_Dictionary)        
    task.delay(2, function()
        SSS_Communicate("UpdCS", {UID, 1, 2}) --* UID, StateNum, ActionNum ; (See State_Dictionary)        
    end)
end
Bind_Functions.HM_OldState = function()
    HumanoidMachine.ChangeToOldState(UID)
end
SSS_Bind.Event:Connect(function(Message , ...)  
    local Bind_Func = Bind_Functions[Message]
    if Bind_Func then 
        Bind_Func(...)
    end
end)
--[[ --TODO SOME OLD STUFF WILL REUSE SOME OF IT
CharacterActor:BindToMessage("Init", function(UID, Data: SharedType.NPCData)
    
end)
↓ outdated
CharacterActor:BindToMessageParallel("Q", function(CurrentItem: string)  
    TODO the Item Time to wait for in Millis for HBEvent in Combat Logic 
    * --> Char_Controller --> Combat_Logic
    Character_Controller.SendtoQ(CurrentItem)
end)
↑ outdated
HM_OldState
CharacterActor:BindToMessageParallel("HM_OldState", function()
    HumanoidMachine.ChangeToOldState(UID)
end)
*Combat Related Bindables
CharacterActor:BindToMessageParallel("TriggerAction", function(UID:string, Action,...)
    CombatController.TriggerAction(UID, Action, ...)
end)    

do
    local T = {["Blocking"] = true}
    CharacterActor:BindToMessageParallel("Knockback", function(CurrentItem:string?, DirBuffer:buffer, ...)
        --TODO in future will have to do a Iframes Check or make it when they Activate Iframes disconnect the BindMessage   
        local ItemName = CurrentItem or State_Dictionary.GiveString(buffer.readu16(DirBuffer, 1))
        if not ItemName then warn("not itemName; ", CurrentItem);  return end
        local ItemdataCopy = ItemDataMod.GiveCopyData(ItemName)
        if not ItemdataCopy then warn("incorrect itemName: ", ItemName); return end 
        local KB  = ItemdataCopy.KB

        local StateMachine = CombatController[tostring(UID)]
        if not StateMachine then warn("no StateMachine: ", UID); return end 
        if  T[StateMachine.CurrentState] then 
            ForwardActor:SendMessage("Pushback", KB, DirBuffer, ...)    
            DownwardActor:SendMessage("StartDownward")                
            return 
        end
        
        local Ragdollbuffer = buffer.create(2)
        local Wu8 = buffer.writeu8
        Wu8(Ragdollbuffer, 0, tonumber(UID))
        Wu8(Ragdollbuffer, 1, ItemdataCopy.Stun)
        MessageAPI.SendToRagdoll("Ragdoll", Ragdollbuffer)
        DownwardActor:SendMessage("Knockback", KB, DirBuffer, ...)
    end)
    CharacterActor:BindToMessageParallel("Pushback", function(CurrentItem:string?, DirBuffer:buffer, ...)
        local ItemName = CurrentItem or State_Dictionary.GiveString(buffer.readu16(DirBuffer, 1))
        if not ItemName then warn("not itemName; ", CurrentItem, buffer.readu16(DirBuffer, 1));  return end
        local ItemdataCopy = ItemDataMod.GiveCopyData(ItemName)
        if not ItemdataCopy then warn("incorrect ITemName: ", ItemName); return end 
        local KB  = ItemdataCopy.KB
        ForwardActor:SendMessage("Pushback", KB, DirBuffer, ...)    
        DownwardActor:SendMessage("StartDownward")
    end)      
end
CharacterActor:BindToMessageParallel("RespawnPlayer", function(...)        
    task.delay(6, function()
        local RRPOS:RaycastResult  = Util.SpawnPoint()
        if not RRPOS then warn("PROBLEM WITH RRPOS"); return end
        local POS:Vector3 = RRPOS.Position + Vector3.new(0, 5, 0)
        local CF = CFrame.new(POS)
        ForwardActor:SendMessage("SetPCF", CF)
        DownwardActor:SendMessage("SetPCF", CF)
        local CFV:CFrameValue = unpack(CollectionService:GetTagged(UID.."CFV"))  
        if not CFV then warn("no CFV detected: ", UID); return end
        ForwardActor:SendMessage("LockMove")
        task.synchronize()
        CFV.Value = CF
    end)
end)

]]
local ToolBar_Control = function(player:Player, Item_Chosen_Buffer:buffer, offset:number)
    if offset + 2 > buffer.len(Item_Chosen_Buffer)  then  return end --TODO BAN
    local CurrentUnix = DateTime.now().UnixTimestampMillis
    if CurrentUnix - EquipUnix < EquipCD then player:Kick("Check your Internet Connection"); return end 
    EquipUnix = CurrentUnix
    
    offset += 1 --* bcos u8 length
    local KeyCodeValue =  buffer.readu8(Item_Chosen_Buffer, offset)
    offset += 1
    
    local UID = player:GetAttribute("UID")
    local Item_ID = Toolbars[ActiveToolbarNum][KeyCodeValue]
    if Item_ID == 0 then return  end --* no item in that Toolbar
    local ItemName =Item_Dictionary[Item_ID]
    if not ItemName then warn("Error ItemID; ", Item_ID, Item_Dictionary); return end --* itemID does not exist
    local ItemData:ItemDataMod.ItemData = ItemDataMod[ItemName]
    if ItemData.ItemNumType == 2 then 
        --* Weapons 
        if CPProfile.Current_Weapon_Item ~= 0 then 
            --* Unequp
            CPProfile.Current_Weapon_Item = nil
            CPProfile.Current_Selected_Item = nil
            CombatController.TriggerAction(UID, "ToolHandle")
            SSS_Communicate("UpdCS", {UID, 2, 8}) --* UID, StateNum, ActionNum ; (See State_Dictionary)    
            SSS_Communicate("Toolbar_Sort", {Item_ID, UID})   
            SSS_Communicate("Upd_Stats", {UID})
        else
            --* Equip
            CPProfile.Current_Weapon_Item = Item_ID
            CPProfile.Current_Selected_Item = Item_ID
            CombatController.TriggerAction(UID, "ToolHandle")
            SSS_Communicate("UpdCS", {UID, 1, 8}) --* UID, StateNum, ActionNum ; (See State_Dictionary)    
            SSS_Communicate("Toolbar_Sort", {Item_ID, UID})
            SSS_Communicate("Upd_Stats", {UID})
        end
    elseif ItemData.ItemNumType == 3 then 
        --* a Skill selected
        CPProfile.Current_Skill_Item = Item_ID
        CPProfile.Current_Selected_Item = Item_ID
        SSS_Communicate("Upd_Stats", {UID})    
    end
end
local WallRun = function(player:Player, CamLookVector_Buffer:buffer, offset:number)
    if offset + 7 > buffer.len(CamLookVector_Buffer)  then  return end --TODO BAN
    local CurrentUnix = DateTime.now().UnixTimestampMillis
    if CurrentUnix - WallRunUnix < WallRunCD then player:Kick("Check your Internet Connection"); return end 
    WallRunUnix = CurrentUnix
    
    offset += 1 --* bcos u8 length
    local readi16 = buffer.readi16
    local x = readi16(CamLookVector_Buffer, offset)
    offset += 2
    local y = readi16(CamLookVector_Buffer, offset)
    offset += 2
    local z  = readi16(CamLookVector_Buffer, offset)
    offset += 2
    local Cam_LookVector = Vector3.new(x, y, z).Unit
    ForwardActor:SendMessage("WallRun", Cam_LookVector)
end
local Swapping_Tool_Bars =  function(player:Player, ToolBar_Buffer:buffer, offset:number)
    if offset + 2 > buffer.len(ToolBar_Buffer)  then  return end --TODO BAN
    offset += 1 --* bcos u8 length
    local Active_Toolber =  buffer.readu8(ToolBar_Buffer, offset)
    offset += 1
    if Active_Toolber == 1 or Active_Toolber == 2  then 
        CPProfile.ActiveToolbar = Active_Toolber
        ActiveToolbarNum = Active_Toolber
    else  
        --TODO BAN
    end
end 
local Inventory_Tool_Placement =  function(player:Player, Inventory_Tool_Placement_Buffer:buffer, offset:number)
    if offset + 2 > buffer.len(Inventory_Tool_Placement_Buffer)  then  return end --TODO BAN
    offset += 1 --* bcos u8 length
    local PlacementNum =  buffer.readu8(Inventory_Tool_Placement_Buffer, offset)
    offset += 1
    local PlacementHolder =  buffer.readu8(Inventory_Tool_Placement_Buffer, offset)
    offset += 1
    local Item_ID =  buffer.readu16(Inventory_Tool_Placement_Buffer, offset)
    offset += 2
    local UID = player:GetAttribute("UID")
    local Item_Stack =  Backpack[Item_ID]
    if not Item_Stack or Item_Stack < 1 then 
        --TODO ban
        return
    end
    if PlacementNum > 5 or PlacementNum < 1 then 
        --TODO ban
        player:Kick("Spoof Inventory_Tool_Placement")
        return
    end
    if PlacementHolder > 8 or PlacementHolder < 1 then 
        --TODO ban
        player:Kick("Spoof inventory_tool_placement")
        return
    end
    if PlacementNum == 2 or PlacementNum == 1   then
        --* Placed in on of the ToolBars 
        local Index = (Enum.KeyCode.One.Value-1) + PlacementHolder
        local ActiveToolbar =  Toolbars[PlacementNum]
        local Old_Item_ID = ActiveToolbar[Index]
        if Old_Item_ID ~= 0 then 
            --* no need to add back to Backpack cos backpack never removed the item
            --* this is so if they had the item equipped
            print("there was an item already in that tool bar place: ", Old_Item_ID, PlacementNum, Index)
            SSS_Communicate("Unequip", {UID, PlacementNum, PlacementHolder})
            SSS_Communicate("UpdCS", {UID, 2, 8}) --* UID, StateNum, ActionNum ; (See State_Dictionary)    
        end
        for ToolbarKey, ItemID in ActiveToolbar do 
            if ItemID == Item_ID then
                --* They moved the same Weapon or skill from one toolbar placement to another
                ActiveToolbar[ToolbarKey] = 0
            end
        end
        Toolbars[PlacementNum][Index] = Item_ID
        CPProfile.Toolbars = Toolbars
        print(CPProfile, "CCPRofile Weapon")
    end
    if PlacementNum == 3 then
        --* Placed in a Body Frame place
        local Old_Item_ID = BodyEquipped[PlacementNum]
        if Old_Item_ID ~= 0 then 
            -- print("there was an item already in that Body Equipped place: ", Old_Item_ID, PlacementNum)
            SSS_Communicate("Unequip", {UID, PlacementNum, PlacementHolder})
        end
        
        local ItemName = Item_Dictionary[Item_ID]
        local ItemData:ItemDataMod.ItemData = ItemDataMod[ItemName]
        if ItemData.ArmourType == PlacementHolder then 
            BodyEquipped[PlacementHolder] = Item_ID
            SSS_Communicate("ArmourEquip", {Item_ID, UID})
            -- print(BodyEquipped, "Server placed in body equipped Correct NumType: ", ItemData.ArmourType, PlacementHolder)
        end
        SSS_Communicate("Upd_Stats", {UID})    
        print(CPProfile, "CCPRofile Armour")
    end
    if PlacementNum == 4 then
        --* Armour piece -> Backpack
        -- Backpack[Item_ID] = Item_Stack --* <-- not really needed cos its never removed from backpack in this function
        local Old_Item_ID
        Old_Item_ID = BodyEquipped[PlacementHolder]  
        if Old_Item_ID ~= 0 then 
            BodyEquipped[PlacementHolder] = 0 --* its an armour piece that was unequipped
            SSS_Communicate("Unequip", {UID, 3, PlacementHolder})
            print("Armour piece rmoeved from BodyEquipped: ", Item_ID, PlacementHolder)
        end 
        SSS_Communicate("Upd_Stats", {UID})    
    end
    if PlacementNum == 5 then  
        --* Weapon or skill -> Backpack
        local Active_Toolbar = Toolbars[ActiveToolbarNum]
        if Active_Toolbar then 
            local Index = (Enum.KeyCode.One.Value-1) + PlacementHolder
            local Old_Item_ID = Active_Toolbar[Index]
            if Old_Item_ID ~= 0 then 
                Active_Toolbar[Index] = 0 --* its a Weapon or skill that was unequipped
                print("Weapon or skill rmoeved from Toolbar: ", Item_ID)
                SSS_Communicate("Unequip", {UID, ActiveToolbarNum, PlacementHolder})
                SSS_Communicate("UpdCS", {UID, 2, 8}) --* UID, StateNum, ActionNum ; (See State_Dictionary)    
                if Old_Item_ID == CPProfile.Current_Selected_Item then
                    CPProfile.Current_Selected_Item = nil
                    SSS_Communicate("Upd_Stats", {UID}) 
                end
            end
        end
    end

end 
local Dash = function(player: Player, CameraLookBuffer:buffer, offset:number)
    if offset + 7 > buffer.len(CameraLookBuffer)  then  return end --TODO BAN
    local CurrentUnix = DateTime.now().UnixTimestampMillis
    if CurrentUnix - DashUnix < DashCD then player:Kick("Check your Internet Connection"); return end 
    DashUnix = CurrentUnix
    
    --* 6 bytes cos its not projected
    offset += 1 --* bcos of the Length
    local UID = player:GetAttribute("UID")
    local Ri16= buffer.readi16
    local X, Y, Z = Ri16(CameraLookBuffer, offset), Ri16(CameraLookBuffer, offset + 2), Ri16(CameraLookBuffer, offset + 4)
    local Look:Vector3 = Vector3.new(X, Y, Z).Unit
    local Profile = Character_Controller.Give_Profile(UID)
    local ForwardActor:Actor = Profile["FA"]
    HumanoidMachine.ServerTriggerAction(UID, nil, "QDash", Look, ForwardActor)    
end
local UpdMoveLook = function(player:Player, MoveLook_Buffer:buffer, offset:number)
    if offset + 3 > buffer.len(MoveLook_Buffer)  then  return end --TODO BAN
    local UID = player:GetAttribute("UID")
    local Profile = Character_Controller.Give_Profile(UID)
    local ForwardActor:Actor = Profile["FA"]
    local UV3V:Vector3Value = Profile["UV3V"]
    local LV3:Vector3Value = Profile["LV3"]
    local CFV:CFrameValue = Profile["CFV"]
    local Type_Of_Upd = buffer.readu8(MoveLook_Buffer, offset)
    offset += 1 --* bcos of the Length
    task.synchronize();
    if Type_Of_Upd == 2  then  
        local LookVector = Buffer_Converter.Reader_UnitVector_Buffer(MoveLook_Buffer, UV3V.Value, offset)
        LV3.Value =  LookVector
        CFV.Value = CFrame.lookAlong(CFV.Value.Position, LookVector, CFV.Value.UpVector)
        return
    end
    if Type_Of_Upd == 4  then  
        local LookVector = Buffer_Converter.Reader_UnitVector_Buffer(MoveLook_Buffer, UV3V.Value, offset)
        LV3.Value =  LookVector
        offset += 2
        local MoveVector:Vector3 = Buffer_Converter.Reader_UnitVector_Buffer(MoveLook_Buffer, UV3V.Value, offset )

        HumanoidMachine.ServerTriggerAction(UID, nil, "StartWalk", MoveVector, ForwardActor)
        return 
    end
end
local Jump = function(player: Player) 
    local CurrentUnix = DateTime.now().UnixTimestampMillis
    if CurrentUnix - JumpUnix < JumpCD then player:Kick("Check your Internet Connection"); return end 
    JumpUnix = CurrentUnix

    HumanoidMachine.ServerTriggerAction(UID, nil, "Jump", ForwardActor)
end
local AttackM1 = function(player:Player, M1Buffer:buffer, offset:number)
    if offset + 1 > buffer.len(M1Buffer)  then  return end --TODO BAN
    offset += 1 --* bcos of the Length
    --TODO here -> ServerCombatStats; (SSS_Communicate) -> Server Funcions
    SSS_Communicate("TriggerAction", {UID, "M1"})
end
local Input_Processes = {
    [1] = UpdMoveLook,
    [2] = Jump,
    [3] = Dash,
    [4] = ToolBar_Control,
    [5] = WallRun,
    [6] = Swapping_Tool_Bars,
    [7] = Inventory_Tool_Placement,
    [8] = AttackM1 
}
local Everything = function (player:Player, Every_Input_buffer:buffer)
    if typeof(Every_Input_buffer) ~= "buffer" then task.synchronize(); player:Kick("Spoof Buffer Every thing: ".."\n" .. typeof(Every_Input_buffer)); return end
    --TODO add RateLimiter
    local Length = buffer.len(Every_Input_buffer)
    local offset = 0
    local readu8 = buffer.readu8
    for i = 1, Length do 
        if offset + 2 > Length then break end
        local Input_ID = readu8(Every_Input_buffer, offset)
        local Input_Process = Input_Processes[Input_ID]
        if not Input_Process  then warn("no;", Input_ID); break end --TODO Ban
        offset += 1
        local Sub_buffer_Length = readu8(Every_Input_buffer, offset)
        Input_Process(player, Every_Input_buffer, offset)
        offset += 1
        offset += Sub_buffer_Length
    end
end
local Character_Event_Connections = {
    ["Everything"] = Everything
}
local Events = { 
    -- "MoveLook", "Jump", "M1","M2","Block", "StopBlock", "Skill", "Tool", "Run", "StopRun", "Inventory", "WallRun", "Dash",
    "Everything"
}
local CharacterEvents = Instance.new("Folder")
CharacterEvents.Name = UID
CharacterEvents.Parent = CharacterActors
for _, EventNames in Events do
    local CharacterEvent = Instance.new("UnreliableRemoteEvent")
    CharacterEvent.Name = EventNames
    CharacterEvent.OnServerEvent:Connect(Character_Event_Connections[EventNames])
    CharacterEvent.Parent = CharacterEvents 
end
RateLimiter.InitProfile(script.Name)
