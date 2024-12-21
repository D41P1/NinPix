--!native
local Players = game:GetService("Players")
Players.CharacterAutoLoads = false
local CollectionService = game:GetService("CollectionService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RunService = game:GetService("RunService")
local Shared = ReplicatedStorage.Shared

local CharacterScripts_Folder = script.Character_Scripts_Folder
local RunTime_CharacterScripts = script.RunTime_Character_Scripts
local Character_Script = CharacterScripts_Folder.Character_Script
local FromServer = ReplicatedStorage.FromServer
local ServerActor = script.Parent

local Cleanup_Manager = require(Shared.Cleanup_Manager)
local Stats_Controller = require(script.Stats_Controller)
local MessageAPI = require(script.MessageAPI); MessageAPI.InitSSS()
local CharacterBox = require(script.CharacterBox)
local Character_Controller = require(script.Character_Scripts_Folder.Character_Controller)
local InventoryLogic = require(script.Character_Scripts_Folder.InventoryLogic)
local CombatController = require(script.CombatController)
local Data_Controller = require(script.Data_Controller)
local Hitbox = require(script.Parent.Parent.Parent.Parent.ReplicatedStorage.Shared.Hitbox)
local ItemDataMod = require(script.Parent.Parent.Parent.Parent.ReplicatedStorage.Shared.ItemDataMod)
local Item_Dictionary = require(script.Parent.Parent.Parent.Parent.ReplicatedStorage.Shared.Item_Dictionary)
local Stat_Dictionary = require(Shared.Stat_Dictionary)
local SharedType = require(Shared.SharedType)
local Skill_Infos = require(Shared.Skill_Infos)
local Buffer_Converter = require(Shared.Buffer_Converter)
local Debris = require(Shared.Debris)
local Util = require(script.Util)
local ServerTick = require(script.ServerTick); ServerTick.InitSSS()
-- local LoadClient = FromServer.LoadClient
-- local LoadCombat = FromServer.LoadCombat
-- local LoadStat = FromServer.LoadStat
-- local NetworkEvent = FromServer.NotifyEvent
local StartLoading = FromServer.Start
local EverythingEvent = FromServer.EverythingEvent
-- MessageAPI.SendToHealth("Init")
-- MessageAPI.SendToPosture("Init"

--// "qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDFGHJKLZXCVBNM1234567890!:@~<>?}]~#;-+=&"
local BCreate = buffer.create
local BCopy = buffer.copy
local Len = buffer.len
local writeu8 = buffer.writeu8
local writei16 = buffer.writei16
local writeu16 = buffer.writeu16
local writef32= buffer.writef32
local writef64 = buffer.writef64
local readu8 = buffer.readu8
local readu16 = buffer.readu16
local table_remove = table.remove
local table_insert = table.insert
local Previous_System_Queue:SystemCall = {} --* for debugging
local System_Queue:SystemCall = {}
local PreviosProfile: { [number]: buffer } = {}
local Profiles: { [number]: buffer } = {} -- holds
local Stats_Buffer = BCreate(3)

local ServerFrame = 1 --* 1-30, 30hz


local CREATE_PLAYER_STATE = function(Length:number, UID, StateNum:number, ActionNum:number) 
    local StateBuffer = buffer.create(Length)
    local State = StateNum --*Blocking,Idle,WeaponOut , ... etc
    local Action = ActionNum --*Blocked, Parried, Block, M1, ... etc
    UID = tonumber(UID)
    writeu8(StateBuffer, 0, Length)
    writeu8(StateBuffer, 1, UID)
    writeu8(StateBuffer, 2, State)
    writeu8(StateBuffer, 3, Action)
    writeu8(StateBuffer, 4, ServerFrame)
    return StateBuffer    
end
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
local AllowDoubleTrigger = function(UID, b)
    local OldB = PreviosProfile[UID]
    if not OldB then return end
    local State, Action = readu8(b, 2), readu8(b, 3)
    local PreviousState, PreviousAction = readu8(OldB, 2), readu8(OldB, 3)
    if State == PreviousState and Action == PreviousAction then 
        writeu8(OldB, 2, 1)
        writeu8(OldB, 3, 1)
        PreviosProfile[UID] = OldB
        --* this is so if a double trigger has happened on the server
        --* for example they are given multiple SoftStuns this is to let that happen by purposely making the OldCombatState ~= CurrentCombatState
    end
end
local Add_To_Stat_Buffer = function(Data:{[string]:number}, UID:number, Number_Of_stats_To_Send:number)
    local Needle = 0
    local New_StatsBuffer:buffer = BCreate((Number_Of_stats_To_Send *3) + 2)
    writeu8(New_StatsBuffer, Needle, UID)
    Needle += 1
    writeu8(New_StatsBuffer, Needle, Number_Of_stats_To_Send *3)
    Needle += 1
    for StatName, StatNumber in Data do 
        local StatID = Stat_Dictionary[StatName]
        if not StatID then warn("INCORRECT STAT ID or Name: ", StatName, StatID); break end
        writeu8(New_StatsBuffer, Needle, StatID) -- * 1 =  health, 2 = Posture , 3 = Stamina,  ...
        Needle += 1
        writeu16(New_StatsBuffer, Needle, StatNumber) --* actual Stat number Remaining
        Needle += 2
    end
    Stats_Buffer = Merge_Buffers(Stats_Buffer, {New_StatsBuffer})        
    return New_StatsBuffer
end
local Init_Stats = function(UID)
    local Stats_To_Add = Stats_Controller.Give_Stats_To_Add()
    local BaseStats = Stats_Controller.Give_BaseStats()
    local CPProfile = Character_Controller.Give_Profile(UID)
    local Selected_Item_ID= CPProfile.Current_Selected_Item
    local Selected_Item_Name = Item_Dictionary[Selected_Item_ID]
    local function Add_To_Stats(ItemData)
        for _, StatName in Stats_To_Add do 
            local StatNumber = ItemData[StatName]
            if StatNumber and StatNumber ~= 0 then  
                if not BaseStats[StatName] then warn("add Stat to BaseStat; ", StatName); continue end
                BaseStats[StatName] += StatNumber 
            end
        end
    end
    if Selected_Item_Name then 
        local Selected_Item_Data = ItemDataMod[Selected_Item_Name]
        Add_To_Stats(Selected_Item_Data)
    end
    local BodyEquipped = CPProfile.BodyEquipped
    for _, Armour_ItemID in BodyEquipped do
        local Armour_ItemName = Item_Dictionary[Armour_ItemID] 
        if not Armour_ItemName then  continue end
        local Armour_Item_Data = ItemDataMod[Armour_ItemName]
        Add_To_Stats(Armour_Item_Data)
    end
    -- print("Server Stats", BaseStats)
    return BaseStats :: Stats_Controller.Stats
end
type Call =  {
    ["Name"]: string,
    ["Values"]: {any},
    ["Flag"]: boolean,
    ["Delay"]:{
        ["Unix_ms"]:number,
        ["Duration_In_ms"]:number
    }?,
}
type SystemCall = {Call}
Players.PlayerAdded:Connect(function(player)
    local Player_Init:Call = {
        ["Name"] = "Init_Player",
        ["Values"] = {player},
        ["Flag"]  = false
    }
    table.insert(System_Queue, Player_Init)
end)
Cleanup_Manager:InsertTable("PlayerMessageAPI", MessageAPI.Players)
Cleanup_Manager:InsertTable("CharBox", CharacterBox)
Players.PlayerRemoving:Connect(function(player: Player)  
    local Player_Remove:Call = {
        ["Name"] = "Remove_Player",
        ["Values"] = {player},
        ["Flag"]  = false
    }
    table.insert(System_Queue, Player_Remove)
end)
local Server_Functions = {}
Server_Functions.Init_Player = function(Everything_Buffer:buffer,   offset:number, player:Player)
    --* data stuff
    local ActiveSlotNumberBuffer = Data_Controller.Get_ActiveSlot(player)
    local ActiveSlotNum = readu8(ActiveSlotNumberBuffer, 0)
    Data_Controller.Get_SlotDS( ActiveSlotNum )
    local ASL_Buffer = Data_Controller.Get_AccountSession_Info(player)
    if not ASL_Buffer then print("i1"); return Everything_Buffer, offset end
    local AccountLocked = readu8(ASL_Buffer, 0)
    if AccountLocked == 1 then 
        local UxTimeStamp = buffer.readf32(ASL_Buffer, 1) 
        if DateTime.now().UnixTimestamp - UxTimeStamp < 900 then --* it has not been 15 minutes
            print("i2")
            player:Kick([[Account currently Locked rejoin in 2 minutes \n 
            if error Continues after 20 minutes contact Staff on discord
            ]])
            return Everything_Buffer, offset
        end
        warn("Could've potentially lost data: ", player)
    end
    writeu8(ASL_Buffer, 0, 1) --* locking them in this session
    -- local Avatar_Buffer, AvatarRGB_Buffer = Data_Controller.GetPlayerAvatarData(player, ActiveSlotNum)
    -- if not Avatar_Buffer then return end
    
    local InventoryBuffer = Data_Controller.Get_Player_Inventory_Data(player, ActiveSlotNum)
    if not InventoryBuffer then print("i3"); return Everything_Buffer, offset end --* 42 bytes+;  0-30+2 = ToolBar;  32-42+2 = 6 bodyParts
    warn("Got Data")

    local Table_buffers:Data_Controller.DataBuffer = {
        ["InventoryBuffer"] = InventoryBuffer,
        ["ActiveSlot_Num_Buffer"] = ActiveSlotNumberBuffer,
        ["ASL_Buffer"] = ASL_Buffer --* Account Session Lock
    }
    
    Data_Controller.Add_To_Profiles(player, Table_buffers)
    local UID:string = Util.GUID(1, 1, 30)
    warn(UID)
    local CCProfile= Character_Controller.Init_Profile(UID)
    local Needle = 0
    local Toolbars, BodyEquipped, Backpack
    Needle, Toolbars = InventoryLogic.Init_Toolbars(InventoryBuffer, Needle)
    Needle, BodyEquipped = InventoryLogic.Init_Equipped(InventoryBuffer, Needle)
    Needle, Backpack = InventoryLogic.Init_Backpack(InventoryBuffer, Needle)
    CCProfile["Toolbars"] = Toolbars
    CCProfile["BodyEquipped"] = BodyEquipped
    CCProfile["CosmeticEquipped"] = BodyEquipped --TODO future
    CCProfile["Backpack"] = Backpack
    Stats_Controller:InitAttributes(player, UID, true)    
    local Stats = Stats_Controller.Init_Profile(UID, Init_Stats(UID))
    Stats.Health= Stats.MaxHealth
    Stats.Posture= Stats.MaxPosture
    Stats.Stamina= Stats.MaxStamina
    
    --TODO Remove ↓
    -- InventoryLogic.Add_Item_To_Backpack(Backpack, 4)
    --TODO Remove ↑
    
    print(CCProfile, "made CCProfile")
    Cleanup_Manager:Profile(UID)
    task.synchronize()
    player:AddTag(UID)
        
    local CharacterScript = Character_Script:Clone()
    CharacterScript.Name = UID
    CharacterScript.Enabled = true
    CharacterScript:SetAttribute("UID", UID)  
    local Character_Bindable = CharacterScripts_Folder.Bind:Clone()
    Character_Bindable.Parent = CharacterScript
    CharacterScript.Parent = RunTime_CharacterScripts

    
    local RRPos = Util.SpawnPoint()
    if not RRPos then player:Kick("error with spawn"); warn("Error with RRPos"); return Everything_Buffer, offset end
    local Pos =   RRPos.Position 
    local Hip = 5
    --TODO some BASE STATS ↑ need to be affected by what armour they are wearing Use Stats_Controller + (TODO Equipment Dictionary) 
    
    local Load_GameState_Length = 9
    local LoadClientLength = 12
    local InventoryLength = buffer.len(InventoryBuffer)
    local Full_Sub_buffer_Length =  (InventoryLength + 2) + 3 + 1 + LoadClientLength + Load_GameState_Length
    local New_Everything_Buffer = buffer.create(Full_Sub_buffer_Length) 
    
    do  --* Remote Init
        --* (the + 3 in Full_Sub_buffer_Length ) ↓        
        local Needle = 0
        writeu8(New_Everything_Buffer, Needle, 1) --* Client_Remote_function_ID; 1 = Client_Init_Player
        Needle += 1
        writeu16(New_Everything_Buffer, Needle, Full_Sub_buffer_Length -3) --*  Sub buffer additional args Length u16
        Needle += 2
        --* (the + 1 in Full_Sub_buffer_Length ) ↓
        writeu8(New_Everything_Buffer,  Needle, UID) --* UID u8
        Needle += 1

        --*LoadClientLength ↓    
        writef32(New_Everything_Buffer, Needle, Pos.X) --* Pos f32
        Needle += 4
        writef32(New_Everything_Buffer, Needle, Pos.Y) --* Pos f32
        Needle += 4
        writef32(New_Everything_Buffer, Needle, Pos.Z) --* Pos f32
        Needle += 4
        
        --*Load_GameState_Length ↓
        local ServerUnix = DateTime.now().UnixTimestampMillis
        writeu8(New_Everything_Buffer, Needle, ServerFrame)
        Needle += 1
        writef64(New_Everything_Buffer, Needle, ServerUnix)
        Needle += 8
        
        --* Inventory Length + 2 ↓
        warn(InventoryLength, Needle, Full_Sub_buffer_Length)
        writeu16(New_Everything_Buffer, Needle, InventoryLength) --* entire Sub buffer Length u16
        Needle += 2
        BCopy(New_Everything_Buffer,     Needle, InventoryBuffer, 0, InventoryLength) --* Entire Inventory Length
        Needle += InventoryLength
        
        Everything_Buffer = Merge_Buffers(Everything_Buffer, {New_Everything_Buffer})
        offset = Len(Everything_Buffer)
    end
    task.delay(1, function()
        if not CharacterScript then return  end --* player could leave early
        local Data =  {
            ["CurrentCF"] = CFrame.new(Pos),
            --TODO in future send WalkSpeed after adding their Armour buffs (if any) to the base WalkSpeed of 10
        }
        task.synchronize()
        Character_Bindable:Fire("Init", UID, Data, InventoryBuffer)
        StartLoading:FireClient(player) --* <-------------------------------------------------------------------------------------//////// IMPORTANT ///////////////////////
    end)
    -- MessageAPI.AddCharacterActor(CharacterActor)
    ServerTick.InitMovementProfile(UID, Pos + Vector3.new(0, Hip, 0), "Player")
    Cleanup_Manager:Insert(UID, CharacterScript)
    
    return Everything_Buffer, offset, 999 --* High weight bcos computationally heavy + this func yields 
end
Server_Functions.Remove_Player = function(Everything_Buffer:buffer, offset:number, player:Player)
    local UID = player:GetAttribute("UID")
    local PlayerName: string = player.Name
    local ArrayPlayers = Players:GetPlayers()
    local Success, Error = pcall(function()
        if not UID then return end
        Cleanup_Manager:Start(UID)
        Cleanup_Manager:CleanTable("PlayerMessageAPI", PlayerName)
        Cleanup_Manager:CleanTable("CharBox", PlayerName)
        Data_Controller.Cleanup(PlayerName, UID)
        if #ArrayPlayers <= 1 then 
            local Player_Data_Profile: Data_Controller.DataBuffer = Data_Controller.GiveProfile(PlayerName)
            if not Player_Data_Profile then error("[Cleanup Error] did not retrieven player_Data_Profile"); return end
            local ASL = Player_Data_Profile.ASL_Buffer
            buffer.writeu8(ASL, 0 , 0)--* unlocking Account Session
            buffer.writef32(ASL, 1 , DateTime.now().UnixTimestamp) --* Resetting Session Lock Timeout fail Safety measure
            Player_Data_Profile.ASL_Buffer = ASL
            Data_Controller.SavePlayer(PlayerName, UID)
        end
        Util.Cleanup(UID)
        Stats_Controller.CleanProfile(UID)
        Character_Controller.Clean_Profile(UID)
    end)
    if not Success then 
        warn("Error Cleaning Player : \n ", Error)
        return Everything_Buffer, offset
    end
    return Everything_Buffer, offset, 999 --* High weight bcos computationally heavy + this func yields 
end
Server_Functions.Toolbar_Sort = function(Everything_Buffer:buffer,  offset:number, ItemID:number, UID)
    local Chosen_Tool_Buffer = BCreate(6)
    local Needle = 0
    writeu8(Chosen_Tool_Buffer, Needle, 5)--* Client Remote Function ID
    Needle += 1
    writeu16(Chosen_Tool_Buffer, Needle, 3) --* additional args Length
    Needle +=2
    --* additional ↓
    writeu16(Chosen_Tool_Buffer, Needle, ItemID)     
    Needle +=2
    writeu8(Chosen_Tool_Buffer, Needle, tonumber(UID))
    Needle += 1
    Everything_Buffer = Merge_Buffers(Everything_Buffer, {Chosen_Tool_Buffer})
    offset = Len(Everything_Buffer)
    print(ItemID, UID)
    return Everything_Buffer, offset, 1
end
Server_Functions.ArmourEquip = function(Everything_Buffer:buffer,  offset:number, ItemID:number, UID)
    local ArmourEquip_Buffer = BCreate(6)    
    local Needle = 0
    writeu8(ArmourEquip_Buffer, Needle, 6)--* Client Remote Function ID
    Needle += 1
    writeu16(ArmourEquip_Buffer, Needle, 3) --* additional args Length
    Needle +=2

    --* additional ↓
    writeu16(ArmourEquip_Buffer, Needle, ItemID)     
    Needle +=2
    writeu8(ArmourEquip_Buffer, Needle, tonumber(UID))
    Needle += 1

    Everything_Buffer = Merge_Buffers(Everything_Buffer, {ArmourEquip_Buffer})
    offset = Len(Everything_Buffer) 
    return Everything_Buffer, offset, 1
end
Server_Functions.Unequip = function(Everything_Buffer:buffer,  offset:number,  UID,  PlacementNum:number, Place_Holder_Num:number)
    local ArmourEquip_Buffer = BCreate(6)    
    local Needle = 0
    writeu8(ArmourEquip_Buffer, Needle, 7)--* Client Remote Function ID
    Needle += 1
    writeu16(ArmourEquip_Buffer, Needle, 3) --* additional args Length
    Needle +=2
    --* additional ↓
    writeu8(ArmourEquip_Buffer, Needle, tonumber(UID))
    Needle += 1
    writeu8(ArmourEquip_Buffer, Needle, PlacementNum)
    Needle += 1
    writeu8(ArmourEquip_Buffer, Needle, Place_Holder_Num)
    Needle += 1

    Everything_Buffer = Merge_Buffers(Everything_Buffer, {ArmourEquip_Buffer})
    offset = Len(Everything_Buffer) 
    return Everything_Buffer, offset, 1
end
Server_Functions.UpdCS = function(Everything_Buffer:buffer,  offset:number, UID, StateNum, ActionNum, ClientFrame:number?)
    --* Update Combat States
    local Combat_State = CREATE_PLAYER_STATE(5, UID, StateNum, ActionNum)
    if ClientFrame then 
        local Lower_Boundary = ServerFrame - 10
        if Lower_Boundary < 1 then 
            Lower_Boundary = 30 + Lower_Boundary --* lower boundary should be negative
        end
        if ClientFrame <= Lower_Boundary then 
            --TODO player kick unstable connection
            ClientFrame = Lower_Boundary
            return Everything_Buffer, offset
        end        
        writeu8(Combat_State, 4, ClientFrame)
    end
    Profiles[UID] = Combat_State
    AllowDoubleTrigger(UID, Combat_State)
    return Everything_Buffer, offset, 1
end
Server_Functions.Upd_Stats = function(Everything_Buffer:buffer,  offset:number, UID)
    Stats_Controller.Init_Profile(UID, Init_Stats(UID))
    print("Updated stats")
    return Everything_Buffer, offset, 5
end  
Server_Functions.TriggerAction = function(Everything_Buffer:buffer,  offset:number, UID, Action:string)
    CombatController.TriggerAction(tostring(UID), Action)
    return Everything_Buffer , offset, 1
end
-- Single_HitBox
Server_Functions.Single_HitBox = function(Everything_Buffer:buffer,  offset:number, UID, CFV:CFrameValue, StateMachine:SharedType.ServerCombat_Profile, Amplifiers:{number})
    print("in single hbox")
    if StateMachine.Allow_Hit then 
        local StatsProfile:Stats_Controller.Stats = Stats_Controller.GiveProfile(UID)
        if not StatsProfile then warn("Character no StatsProfile : ", UID); return end
        local Results = Hitbox:NPCGPB(CFV.Value, StatsProfile)
        local MyNumUID = tonumber(UID)
        for _, BodyCFPart in Results do  
            local NumUID = BodyCFPart:GetAttribute("NumUID")
            if not NumUID then warn("no  NUMID; ", BodyCFPart.Name); continue end
            if NumUID == MyNumUID then continue end --* number comparison faster than string
            local Extra_Data:SharedType.Extra_Damage_Data = {
                ["Attackers_Stats"] = StatsProfile,
                ["CFV"] = CFV,
                ["Amplifiers"] = Amplifiers
            }
            CombatController.TriggerAction(BodyCFPart.Name, "SoftStun", Extra_Data)
        end
        print("Releasing single Hbox")
        CombatController.TriggerAction(UID, "Release");
    end
    return Everything_Buffer , offset, 8 --* fast compute but Spacial query can be heavy at times
end
Server_Functions.Health_Damage = function(Everything_Buffer:buffer,  offset:number, UID, Extra_Data:SharedType.Extra_Damage_Data)
    local StatProfile = Stats_Controller.GiveProfile(UID)
    if not StatProfile then warn("no statprofile: ", UID); return end
    local Attackers_Stat_Profile = Extra_Data.Attackers_Stats
    local Amplifiers = Extra_Data.Amplifiers
    local Add_Damage = 1 
    for _, Amplify_Num in Amplifiers do 
        Add_Damage += Amplify_Num
    end
    local NewHealth = StatProfile.Health - (Attackers_Stat_Profile.Damage * Add_Damage)
    if NewHealth <=  0 then 
        NewHealth = 0
    end
    local Data = {
        ["Health"] = NewHealth
    }
    Add_To_Stat_Buffer(Data, UID, 1)
end
Server_Functions.Posture_Damage = function(Everything_Buffer:buffer,  offset:number, UID, Extra_Data:SharedType.Extra_Damage_Data, ParryBool)
    local StatProfile = Stats_Controller.GiveProfile(UID)
    if not StatProfile then warn("no statprofile: ", UID); return end
    local Attackers_Stat_Profile = Extra_Data.Attackers_Stats
    local Amplifiers = Extra_Data.Amplifiers
    local Add_Damage = 1
    for _, Amplify_Num in Amplifiers do  Add_Damage += Amplify_Num end
    local NewPosture = StatProfile.Posture - (Attackers_Stat_Profile.Damage *4 *Add_Damage)
    if ParryBool then 
        NewPosture = StatProfile.Posture - (Attackers_Stat_Profile.Damage *4 *0.3) --* 70% reduction when parrying in posture damage
    end
    if NewPosture <=  0 then 
        NewPosture = 0
    end
    local Data = {
        ["Posture"] = NewPosture
    }
    Add_To_Stat_Buffer(Data, UID, 1)
end
Server_Functions.SoftStun = function(Everything_Buffer:buffer,  offset:number, UID, Extra_Data:SharedType.Extra_Damage_Data)
   local CPPprofile = Character_Controller.Give_Profile(UID)
   if not CPPprofile then warn("no character  profile; ", UID); return end  
   local Attackers_Stat_Profile = Extra_Data.Attackers_Stats
   CPPprofile.BodyPart:SetAttribute("LockMove", true)
   local ReleaseStun:Call = {
        ["Name"] = "Release_Stun",
        ["Values"] = {UID},
        ["Flag"]  = false,
        ["Delay"] = {
            ["Duration_In_ms"] = Attackers_Stat_Profile.Stun *1000,
            ["Unix_ms"] = DateTime.now().UnixTimestampMillis
        }
    }
    table.insert(System_Queue, ReleaseStun)
end
Server_Functions.Release_Stun = function(Everything_Buffer:buffer,  offset:number, UID)
    local CPPprofile = Character_Controller.Give_Profile(UID)
    if not CPPprofile then warn("no character  profile; ", UID); return end  
    CPPprofile.BodyPart:SetAttribute("LockMove", false)
    CombatController.TriggerAction(UID, "Release")
end
--[[
]]
local Message_MT = setmetatable({}, {
    __call = function(_, FunctionName:string, Values:{any}, Duration_In_ms:number?)
        task.synchronize()
        local System_Call:Call = {
            ["Name"] = FunctionName,
            ["Values"] = Values,
            ["Flag"] = false            
        }
        if Duration_In_ms then 
            System_Call.Delay = {
                ["Unix_ms"] = DateTime.now().UnixTimestampMillis,
                ["Duration_In_ms"] = Duration_In_ms
            }
        end
        table.insert(System_Queue, System_Call)
    end
})
MessageAPI["MT"] = Message_MT

--? /////////////////////////////////////////////////////////////////////// WHEN ADDING ANYTHIN to System_Queue Make sure its in Main thread //////////////////////////////////////
local MainRBXSC
do
    --[[ --*  revamped and simplified codebase
    local Stats_Delta, Stats_Step = 0, 0.1 --* Health, Posture, Stamina (Replaces Main_Posture, Main_Health actors so delete them later if this works)
    local Combat_Delta, Combat_Step = 0, 0.0332 --* Combat_Script Replacement

    The Concept or Idea is akin to ECS = {
        - the idea is to Send a Buffer across all the Functions IF Their Deltas (e.g Combat_Delta) are high enough
        - Then Go through the System_Queue And Send the Large buffer through their
        - These Functions would edit or enlargen the buffer and return it + the current offset 
        *System_Queue will hold tasks (e.g Player inputs, Player Joining etc)
    }
    Buffer Setup: {
        - 1st byte would be the Function Id for the Client
        - 2nd & 3rd byte The additional Args length of the Sub buffer (64K limit) writeu16         
        * this buffer setup would be repeated through the buffer, the Client would add the Length to their Offset and carry on reading the Buffer as a for loop
    }
    Systems Setup: {
        - (string) Name of the Server function inn the Server_Functions dictionary you want to perform
        -  Values an array of values you want to send to that function
    }
    ]]
    
    local DebrisPartREMOVE_ME = Instance.new("Folder")
    DebrisPartREMOVE_ME.Parent = workspace

    local PathFinding_Delta, PathFinding_Step = 0, 0.2
    local Stats_Delta, Stats_Step = 0, 0.1 --* Health, Posture, Stamina 
    local Combat_Delta, Combat_Step = 0, 0.0332 --* Combat
    local SendCF_Delta, SendCF_Step = 0, 0.166
    local Regen_Delta, Regen_Step = 0, 2
    local Count = 0 --TODO_REMOVE <--
    --* some functions in the system Queue may not Edit Everything But ALL must return Everything_Buffer, offset
    local CombatTickFunc = function(Everything_Buffer:buffer)          
        ServerFrame += 1
        if ServerFrame > 30 then ServerFrame -= 30 end
        local ServerBuffer = BCreate(3)
        writeu8(ServerBuffer, 0, 4) --*Function ID
        --* 1 offset is being used for Length look below ↓ 
        for UID, PlayerStateBuffer: buffer in Profiles do
            local State: number, Action: number = readu8(PlayerStateBuffer, 2), readu8(PlayerStateBuffer, 3) --* 1 offset is UID
            local PreviousB: buffer = PreviosProfile[UID]
            if not PreviousB then PreviosProfile[UID] = PlayerStateBuffer; continue end --* init the previous Version of the Profile
            local PreviousState: number, PreviousAction: number = readu8(PreviousB, 2), readu8(PreviousB, 3)       
            if State == PreviousState and Action == PreviousAction then  continue end --* if state AND action same
            ServerBuffer = Merge_Buffers(ServerBuffer, {PlayerStateBuffer})
            PreviosProfile[UID] = PlayerStateBuffer
        end
        --// SnapShots[ServerFrame] = Profiles
        if Len(ServerBuffer) <= 3 then return Everything_Buffer end --* no point firing if no changes            
        --// CombatTickEvent:FireAllClients(ServerBuffer)
        writeu16(ServerBuffer, 1, Len(ServerBuffer) - 3) --* additional  args Length of the Serverbuffer
        return Merge_Buffers(Everything_Buffer, {ServerBuffer})
    end
    local ProjectionVector = function(D:Vector3, N:Vector3)
        return (D - (D:Dot(N) *N)).Unit
    end
    local Process_System_Call = function(System_Call:Call, Everything_Buffer:buffer, offset:number)
        local NewBuffer, NewOffset, Weight_Process_Number = Server_Functions[System_Call.Name](Everything_Buffer, offset, unpack(System_Call.Values))
        if NewBuffer and NewOffset then 
            Everything_Buffer, offset = NewBuffer, NewOffset    
        else
            warn("Error 69", System_Call)
        end 
        return Everything_Buffer, offset, Weight_Process_Number
    end
    MainRBXSC = RunService.Heartbeat:Connect(function(a0: number)  
        task.desynchronize()
        PathFinding_Delta += a0
        Stats_Delta += a0
        Combat_Delta += a0
        SendCF_Delta += a0
        Regen_Delta += a0
        if Combat_Delta <=  Combat_Step then return end --* Makes Server Computation time limit ~32ms instead of ~16ms  
        local offset = 0
        local Everything_Buffer = BCreate(0)
        if Stats_Delta >= Stats_Step then 
            Stats_Delta -= Stats_Step
            local Stats_Buffer_Length = Len(Stats_Buffer)
            if Stats_Buffer_Length >= 3 then 
                --* at least a single characters Health has changed
                local Client_ID_buffer = BCreate(3) 
                local Needle = 0
                writeu8(Client_ID_buffer,  Needle, 3) --* 3 = Client Remote Function ID StatsUpd
                Needle  += 1
                writeu16(Client_ID_buffer, Needle, Stats_Buffer_Length) --* additional args length
                Needle  += 2
                Everything_Buffer = Merge_Buffers(Everything_Buffer, {Client_ID_buffer, Stats_Buffer})
                Stats_Buffer = BCreate(0) --* Resetting the Queue to not Send the same Buffer
            end
        end 
        if Regen_Delta >= Regen_Step then 
            Regen_Delta -= Regen_Step
            local T = CollectionService:GetTagged("Character_CFV")
            for _, CFV:CFrameValue in T do
                local UID = CFV.Name 
                local Stats_Profile= Stats_Controller.GiveProfile(CFV.Name)
                if not Stats_Profile then continue end
                local Health = Stats_Profile.Health
                local Posture = Stats_Profile.Posture
                local Stamina = Stats_Profile.Stamina
                local MaxHealth = Stats_Profile.MaxHealth
                local MaxPosture = Stats_Profile.MaxPosture
                local MaxStamina = Stats_Profile.MaxStamina
                if Health == MaxHealth and Posture == MaxPosture and Stamina == MaxStamina then  continue end
                Health += MaxHealth * 0.01
                Posture += MaxPosture * 0.04
                Stamina += MaxStamina * 0.05
                if Health > MaxHealth then  Health = MaxHealth end
                if Posture > MaxPosture then Posture = MaxPosture end
                if Stamina > MaxStamina then Stamina = MaxStamina end
                local StatsData = {
                    ["Health"] = Health,
                    ["Posture"] = Posture,
                    ["Stamina"] = Stamina,
                } 
                Stats_Buffer= Add_To_Stat_Buffer(StatsData, tonumber(UID), 3)
                Stats_Profile.Health = Health
                Stats_Profile.Posture = Posture
                Stats_Profile.Stamina = Stamina
            end
        end
        if PathFinding_Delta >= PathFinding_Step then 
            PathFinding_Delta-= PathFinding_Step
            local T = MessageAPI.GiveNPCActors()
            for _, Actors in T do 
                Actors:SendMessage("Tick")
            end
        end
        if SendCF_Delta >= SendCF_Step then
            SendCF_Delta -= SendCF_Step 
            --TODO currently works for 1 character, Not TESTED for multiple characters yet 
            local CF_Buffer = buffer.create(3)
            writeu8(CF_Buffer, 0, 2) --* function ID
            local T = CollectionService:GetTagged("Character_CFV")
            local CFBuffer_offset= 3
            for _, CFValues:CFrameValue in T do
                local UID = CFValues.Name; 
                UID = tonumber(UID)
                local CF = CFValues.Value
                if (CF.Position - CFValues:GetAttribute("PreviousPos")).Magnitude <= 0.5 and CF.LookVector:Dot(CFValues:GetAttribute("PreviousLook")) > 0.999 then  
                    --* they have not moved or are looking in the same direction
                    continue 
                end
                task.synchronize()
                CFValues:SetAttribute("PreviousPos", CF.Position)
                CFValues:SetAttribute("PreviousLook", CF.LookVector)
                local LenOLDBuffer = Len(CF_Buffer)
                local NewInfoBuffer = BCreate(LenOLDBuffer + 9) 
                BCopy(NewInfoBuffer, 0, CF_Buffer, 0, LenOLDBuffer)
                writeu8(NewInfoBuffer, CFBuffer_offset, UID)
                CFBuffer_offset += 1
                local look_Vector_Buffer = Buffer_Converter.UnitVector_Buffer(ProjectionVector(CF.LookVector, CF.UpVector))
                Buffer_Converter.CF_Write_Buffer(NewInfoBuffer, CFBuffer_offset, look_Vector_Buffer, CF.Position)
                CFBuffer_offset += 8
                CF_Buffer = NewInfoBuffer
                --TODO ↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓ REMOVE ↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓                
                Count += 1
                if Count == 2 then 
                    Count = 0
                    task.synchronize()
                    local Part = Instance.new("Part")
                    Part.CFrame = CF
                    Part.BrickColor = BrickColor.Red()
                    Part.Anchored = true
                    Part.CanCollide = false
                    Part.Transparency = 0.4
                    Debris:AddItem(Part, 0.5)
                    Part.Parent = DebrisPartREMOVE_ME
                end
                --TODO ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑ REMOVE ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑
            end
            task.synchronize()
            local CFBuff_Length =Len(CF_Buffer) 
            if CFBuff_Length > 3 then 
                --* some CFs have changed
                writeu16(CF_Buffer, 1, CFBuff_Length -3) --* additional args Length
                Everything_Buffer = Merge_Buffers(Everything_Buffer, {CF_Buffer})
            end 
        end
        task.synchronize()
        local Weighted_Process_Count = 0
        local Garbage = {}
        for Index = 1, 256 do --* limits the amount of things it can compute to prevent Server Ping spike 
            if Weighted_Process_Count >= 200 then break end --* Look at Weight_Number (basically done enough computation for this frame)
            local Weight_Number = 1
            local System_Call = System_Queue[Index]
            if not System_Call then continue end
            if System_Call.Flag then continue end
            System_Call.Flag = true --* this loop does not take into account if the function yields so do this to prevent repeated function calls (MUST KEEP)
            local Removed = System_Call        
            local Success, Error = pcall(function()  
                if System_Call.Delay then 
                    local Has_Time_Passed= DateTime.now().UnixTimestampMillis - System_Call.Delay.Unix_ms > System_Call.Delay.Duration_In_ms
                    if Has_Time_Passed then 
                        --* the delay has passed; simulates task.delay whilst still keeping ECS type framework
                        table_insert(Garbage, System_Call) 
                        Everything_Buffer, offset, Weight_Number =  Process_System_Call(System_Call, Everything_Buffer, offset)       
                    end
                else
                    table_insert(Garbage, System_Call) 
                    Everything_Buffer, offset, Weight_Number = Process_System_Call(System_Call, Everything_Buffer, offset)
                end
                Weighted_Process_Count += Weight_Number
            end)
            if not Success then  
                warn("[Error 1]: ", Error, "\n", Removed, "\n", System_Queue, Previous_System_Queue)
                for _, Values:Instance in System_Call.Values do 
                    if typeof(Values) == "Instance" and  Values:IsA("Player") then  Values:Kick("[Error 1] please rejoin") end
                end
            end
            Previous_System_Queue = System_Queue--* for debug
        end
        for Index, _ in Garbage  do --* for garbage collector
            table_remove(System_Queue, Index) 
        end
        Everything_Buffer = CombatTickFunc(Everything_Buffer)
        if not Everything_Buffer then return end --* chance at going nill if System Call errors
        if Len(Everything_Buffer) <= 3 then return end --* nothing to send 
        EverythingEvent:FireAllClients(Everything_Buffer)
    end)
    
    --[[ --*Test Stats
    ServerActor:BindToMessage("DELETE_THIS", function(UID:number)  
        local StatsData = {
            ["Health"] = 69,
            ["Posture"] = 69,
            ["Stamina"] = 69,
        }
        local New_StatsBuffer = Add_To_Stat_Buffer(StatsData, UID, 3)
        Stats_Buffer = New_StatsBuffer
        local StatsProfile = Stats_Controller.GiveProfile(tostring(UID))
        StatsProfile.Health = 69
        StatsProfile.Posture = 69
        StatsProfile.Stamina = 69
    end)
    ]]
    --[[
    ServerActor:BindToMessageParallel("UpdateProfile", function(b: buffer)
        local UID= readu8(b, 1)
        Profiles[UID] = b
        AllowDoubleTrigger(UID, b)
    end)
    
    ServerActor:BindToMessageParallel("UpdWithFrame", function(offset:number, b: buffer) -- Update Profile Curret Frame
        --*assume offset given is empty (unwritten) for the Frame  
        writeu8(b, offset, ServerFrame)
        local UID= readu8(b, 1)
        Profiles[UID] = b
        AllowDoubleTrigger(UID, b)
    end)
    
    ]]
end


--* TESTING ↓
-- task.delay(10, function()
--     for _, CFV in CollectionService:GetTagged("Character_CFV") do
--         ServerActor:SendMessage("DELETE_THIS", CFV.Name)
--         print("started random Stats", CFV.Name)    
--     end    
-- end)
--* TESTING ↑
--[[
C:/Users/User/Downloads/Ai Images/Knight with Eyes COOL AF.jpeg
]]
Data_Controller.init()--* init here cos it yields
