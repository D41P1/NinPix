--!native
--[[ TODO:
-- TODO add ForwardActor and DowanWardActor to OtherProfiles in CharacterHandler
-- TODO_LATER check CharacterEvents = Children[2], it works but risky
-- Add a LoadClient event instead cos its better --///// P R I O R I T Y

]]
task.wait(3)
--* Variables  ↓
local CharacterActors = workspace:WaitForChild("WorkSpaceFolder", 15):WaitForChild("CharacterActors", 15)
task.wait()
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local NPCSP = workspace.NPCSP
local player: Player = game.Players.LocalPlayer
local MyUID = player:GetAttribute("UID")
local MyNumUID = tonumber(MyUID)
--* FromServer Events
local FromServer = ReplicatedStorage.FromServer 
local LoadClient = FromServer.LoadClient
local LoadCombat = FromServer.LoadCombat
local LoadGameState = FromServer.GameState
local LoadStats = FromServer.LoadStat
local CombatTickEvent = FromServer.CombatTick
local HealthEvent = FromServer.HealthEvent
local PostureEvent = FromServer.PostureEvent
local NPCMakeEvent = FromServer.NPCMakeEvent
local RagdollEvent = FromServer.RagdollEvent
local UpVectorEvent = FromServer.UpVectorEvent
local EverythingEvent = FromServer.EverythingEvent
local Shared = ReplicatedStorage.Shared

local MyCharacter_Actor: Actor = CharacterActors:WaitForChild(MyUID, 15)
local ClientActor= script.Parent 
local Children = MyCharacter_Actor:GetChildren()
local CharacterEvent = Children[1]  
--* Shared Modules
local SharedType = require(Shared.SharedType)
-- local Events:SharedType.CharacterEvents = CharacterEvents
-- local HB = require(Shared.Hitbox)
local AnimHandler = require(Shared.AnimHandler);  AnimHandler:InitAnimTypes("Humanoid")
local HumanoidMachine = require(Shared.HumanoidMachine)
local State_Dictionary = require(Shared.State_Dictionary)
-- local ItemDataMod = require(Shared.ItemDataMod)
local Buffer_Converter = require(Shared.Buffer_Converter)
local Hitbox = require(Shared.Hitbox)
local NPCInfo = require(Shared.NPCInfo)
local CharModels = ReplicatedStorage.Character


--* Local Modules
local ClientMessageAPI = require(ClientActor.ClientMessageAPI)
-- local EventHandler = require(ClientActor.Event_Handler)
-- for _, Event in CharacterEvents:GetChildren() do CharEvents[Event.Name] = Event  end
-- EventHandler.init(CharEvents)--* before requiring InputHandler
local T_of_Events:SharedType.CharacterEvents 
T_of_Events = {[CharacterEvent.Name] = CharacterEvent} 
-- print(Children, "CLIENT")
-- if true then return end --TODO REMOVE ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

local InputHandler = require(script.InputHandler)
local CharacterHandler = require(script.Character_Handler)
local Stats_Handler = require(script.Character_Handler.Stats_Handler)
-- local Checks = require(script.Character_Handler.Checks)
local Customise_Handler = require(script.Customise_Handler)
local Data_Handler = require(script.Data_Handler)
local Gui_Handler = require(script.Gui_Handler)

local HumanoidStates = require(script.HumanoidStates)
local Inventory_Handler = require(script.Inventory_Handler)
local OtherHumanoidStates = require(script.OtherHumanoidStates)
local ClientCombatMachine = require(script.Parent.ClientCombatMachine)
local NPCStateModsHandler = require(script.NPCFSM_Handler)
local M1 = require(script.Skills.M1)
local ItemDataMod = require(Shared.ItemDataMod)
local Item_Dictionary = require(Shared.Item_Dictionary)
local MovementHelper = require(Shared.MovementHelper)
local Particle_Handler = require(script.SkillsFolder.Particle_Handler)
local Sound_Handler = require(script.Sound_Handler)

Gui_Handler.Init(player)
Sound_Handler.Init()
Inventory_Handler.InitGui(MyUID)

local Character:SharedType.PixelDummy
local BCreate = buffer.create
local BCopy = buffer.copy
local writeu8 = buffer.writeu8
local readu16 = buffer.readu16
local readu8 = buffer.readu8
local writei16 = buffer.writei16
local writeu16 = buffer.writeu16
local writef32= buffer.writef32
local writef64 = buffer.writef64
local Len = buffer.len
local table_remove = table.remove
local table_insert = table.insert
local task_synchronize = task.synchronize


local Items = ReplicatedStorage.Items
local MyProfile:SharedType.Profile
local Camera = workspace.CurrentCamera
local Original_UP:Vector3 = Vector3.new(0, 1, 0)
local ZoomDistance:number = 15
local Limits:number = 0.9
local CamCF:CFrame = CFrame.lookAlong(Camera.CFrame.Position, Camera.CFrame.LookVector, Original_UP) * CFrame.new(0, 0, ZoomDistance) --* For the tween 
local CurrentFrame  = 1  
local MovementNumber = 0
local CameraLockBool
local PressQ = false
local DashCD, DashUnix = 5, DateTime.now().UnixTimestamp
local JumpCD, JumpUnix = 5, DateTime.now().UnixTimestamp
local WallRunCD, WallRunUnix = 1, DateTime.now().UnixTimestamp
local EquipCD, EquipUnix = 2, DateTime.now().UnixTimestamp


local Client_MainRBXSC
local Inputs_Began
local Inputs_Ended
local UV3VChanged
--* Variables ↑ 
--* Tables ↓
local Input_Receive_Functions = {}
local Remote_Functions = {} --* not to be confused with the instance;  this is what the Everything Event would use
local Inputs_Queue = {}
local Input_Queue_Functions = {}
local Enum_Keycode_Values = {
    [Enum.KeyCode.W.Value]  = 2,  --*W
    [Enum.KeyCode.A.Value]  = 4,  --*A
    [Enum.KeyCode.S.Value]  = 8,  --*S
    [Enum.KeyCode.D.Value]  = 16, --*D
}
local Valid_Input_Values = {
    [Enum.KeyCode.W.Value] = 1,  --*W
    [Enum.KeyCode.A.Value]  =1, --*A
    [Enum.KeyCode.S.Value] = 1,  --*S
    [Enum.KeyCode.D.Value] = 1,  --*D
    [Enum.KeyCode.M.Value] = 2, --*(for menu)
    [Enum.KeyCode.Space.Value]  = 3, --* (Jump)
    [Enum.KeyCode.Q.Value] = 4, --* (Dash)
    [Enum.UserInputType.MouseButton1.Value] = 5, --* (Attack and Dash)
    [Enum.KeyCode.One.Value]    = 6, --* (Tool key)
    [Enum.KeyCode.Two.Value]    = 6, --* (Tool key)
    [Enum.KeyCode.Three.Value]  = 6, --* (Tool key)
    [Enum.KeyCode.Four.Value]   = 6, --* (Tool key)
    [Enum.KeyCode.Five.Value]   = 6, --* (Tool key)
    [Enum.KeyCode.Six.Value]    = 6, --* (Tool key)
    [Enum.KeyCode.Seven.Value]  = 6,  --*(Tool key)
    [Enum.KeyCode.Eight.Value]  = 6, --* (Tool key)
    [Enum.KeyCode.R.Value] = 7, --* (Switch between Toolbars)
    [Enum.KeyCode.E.Value] = 8,
    [Enum.UserInputType.MouseButton2.Value] = 9, --* M2 (attack heavy, Dash attack) 
    [Enum.KeyCode.F.Value] = 10 --* F (Block, Parry) 
}
local ArmourTypes_Func = {
    [1] = function(Char:typeof(workspace.WORKING_PROD_PixelDummy), Armour:Model, Profile)
        --* Head
        local Handle = Armour.PrimaryPart
        local CWeld = Char.Head.CWeld
        CWeld.Part0 = Handle
        Armour.Parent = Char
        Profile.CurrentBodyEquipped[1]= Armour
        print(Armour, Armour.Parent)
    end,
    [2] = function(Char:typeof(workspace.WORKING_PROD_PixelDummy), Armour:Model, Profile)
        --* Right Upper Arm
    end,
    [3] = function(Char:typeof(workspace.WORKING_PROD_PixelDummy), Armour:Model, Profile)
        --* UpperTorso
        local Handle = Armour.PrimaryPart
        local CWeld = Char.UpperTorso.CWeld
        CWeld.Part0 = Handle
        Armour.Parent = Char
        Profile.CurrentBodyEquipped[3]= Armour
    end,
    [4] = function(Char:typeof(workspace.WORKING_PROD_PixelDummy), Armour:Model, Profile)
        --* LeftUpperArm
    end,
    [5] = function(Char:typeof(workspace.WORKING_PROD_PixelDummy), Armour:Model, Profile)
        --* RightUpperLeg
    end,
    [6] = function(Char:typeof(workspace.WORKING_PROD_PixelDummy), Armour:Model, Profile)
        --* Left Upper Leg
    end,
}

--* Tables ↑
--* Functions ↓
--TODO ADD DEAD CHARACTER VFX ↓
local CleanUpChar  = function(UID:string)
    --TODO also to check if its a player that died and not an NPC (if player then reuse the character)
    HumanoidMachine[UID] = nil
    CharacterHandler.CleanProfile(UID)
    ClientCombatMachine.Cleanup(UID)
    ClientActor:SendMessage("Cleanup", UID)
    
    warn("Client Cleaned up Character: ", UID)
end
--TODO ADD DEAD CHARACTER VFX ↑
local InitChar = function(UID)
    local Char  = ReplicatedStorage.Character.PixelDummy:Clone()
    Char.Name = UID
    task.desynchronize()
    return Char
end
local ProjectionVector = function(D:Vector3, N:Vector3)
    return (D - (D:Dot(N) *N)).Unit
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
local Occlusion_RR_Func = function (CamSubjectPos:Vector3, NewCamPos:Vector3)
    local RayDirection = (  NewCamPos- CamSubjectPos).Unit
    local Occlusion_RR = Hitbox:Raycasting(CamSubjectPos, CamSubjectPos + RayDirection, ZoomDistance)
    if Occlusion_RR then 
        local Distance = (CamSubjectPos - Occlusion_RR.Position).Magnitude
        return Distance-1
    end
    return ZoomDistance
end
local FixCamera = function (NewLook:Vector3, UV3V:Vector3Value, LookBody:BasePart)
    --* in case Limits are activated
    local Direction = ProjectionVector(NewLook, UV3V.Value)
    local Occlusion_Distance = Occlusion_RR_Func(CamCF.Position, CamCF.Position + (-Direction))
    CamCF = CFrame.lookAlong(LookBody.Position + (- Direction *Occlusion_Distance), Direction)
end
local MouseMove = function (DeltaX:number, DeltaY:number, UV3V:Vector3Value,  LookBody:BasePart)
    local NewCamCF = Camera.CFrame
    local CamSubjectPos = Character.PrimaryPart.Position + (LookBody.CFrame.RightVector*2 + LookBody.CFrame.UpVector *2)
    local UP:Vector3 = UV3V.Value
    
    local IRx = DeltaX/200
    local IRy = -DeltaY/200
    local NewLook:Vector3 = (NewCamCF.LookVector + (NewCamCF.RightVector * IRx) + (NewCamCF.UpVector * IRy) ).Unit
    local DotProd:number = NewLook:Dot(UP)
    if DotProd >= Limits or DotProd <= -Limits then return  end

    local NewCf = CFrame.lookAlong(CamSubjectPos, NewLook, UP)
    local Occlusion_Distance = Occlusion_RR_Func(CamSubjectPos, NewCamCF.Position)
    CamCF = NewCf * CFrame.new(0, 0, Occlusion_Distance)     
end
local Add_To_Input_Queue = function(Input_ID:number, Values:{any})
    local Input_Insert:Input_Queue_Setup = {
        ["Unix"] = DateTime.now().UnixTimestampMillis,
        ["Input_ID"] = Input_ID,
        ["Values"] = Values,
        ["Net_Processed_Flag"] = false
    }
    table.insert(Inputs_Queue, Input_Insert)
end
local Tween_Equip = function(PhysicalItem, Char:typeof(workspace.WORKING_PROD_PixelDummy))
    local Profile = CharacterHandler.GiveProfile(Char.Name)
    if not Profile then warn("no profile Tween equip"); return end
    Profile.Procedural:SendMessage("Anim", "Equip", {2, 5}, {2, 5})
    local Body = Char.PrimaryPart
    local OrignalCharCF = Body.CFrame
    PhysicalItem.Parent = Char
    local RHGrip = Char.RightHand.RightGrip 
    RHGrip.Part1 = PhysicalItem.PrimaryPart
    RHGrip.C1 = CFrame.new(0.200000003, -0.25, 0, -4.37113883e-08, 1, -4.37113883e-08, 0, -4.37113883e-08, -1, -1, -4.37113883e-08, 1.91068547e-15)
    Body.CFrame = OrignalCharCF
    local TI = TweenInfo.new(0.9, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, 0, false, 0)
    local Item = PhysicalItem
    local LightMesh: Highlight = Item.LightMesh  
    --TODO Send get thier PA,  Send to PA to Animate the arm
    --TODO add more Particle FX
    Sound_Handler.InsertWithId(5, Body, false)
    Particle_Handler.Equip(Item.Mesh)    

    task.delay(0.5, function()
        local TC = TweenService:Create(LightMesh, TI, { Transparency = 1 })
        TC:Play()
        TC.Completed:Connect(function(a0: Enum.PlaybackState)
            for _, Instance in PhysicalItem:GetDescendants() do 
                if Instance:IsA("PointLight") then Instance.Enabled = false end
            end
        end)    
    end)
end
local Init_Stats = function(UID)
    UID = tostring(UID)
    local Stats_To_Add = Stats_Handler.Give_Stats_To_Add()
    local BaseStats = Stats_Handler.Give_BaseStats()
    local OtherProfile = CharacterHandler.GiveProfile(UID)
    local Selected_Item_ID= OtherProfile.Current_Selected_Item
    local Selected_Item_Name = Item_Dictionary[Selected_Item_ID]
    local function Add_To_Stats(ItemData)
        for _, StatName in Stats_To_Add do 
            local StatNumber = ItemData[StatName]
            if StatNumber and StatNumber ~= 0 then  BaseStats[StatName] += StatNumber end
        end
    end
    if Selected_Item_Name then 
        local Selected_Item_Data = ItemDataMod[Selected_Item_Name]
        Add_To_Stats(Selected_Item_Data)

    end
    local BodyEquipped = OtherProfile.BodyEquipped
    for _, Armour_ItemID in BodyEquipped do
        local Armour_ItemName = Item_Dictionary[Armour_ItemID] 
        if not Armour_ItemName then  continue end
        local Armour_Item_Data = ItemDataMod[Armour_ItemName]
        Add_To_Stats(Armour_Item_Data)
    end
    -- warn("Client Stats", BaseStats)
    return BaseStats :: Stats_Handler.Stats
end
--* Functions ↑ 
--* Types ↓
type Input_Queue_Setup = { 
    Input_ID: number, Unix: number, Values: {any}, Net_Processed_Flag:boolean
}
type UID = string
type Client_System_Call = {
    ["Remote_Function_ID"]:number,
    ["Values"]: {any},
    ["Flag"]: boolean
}
--* Types ↑
NPCMakeEvent.OnClientEvent:ConnectParallel(function(NPCInfo_BUFFER:buffer)
    local Readu8 = buffer.readu8 
    local UID = Readu8(NPCInfo_BUFFER, 0, 1);  UID = tostring(UID)
    local SpawnPartNumber = buffer.readu8(NPCInfo_BUFFER, 1)
    local NPCIdN = buffer.readu16(NPCInfo_BUFFER, 2)
    local NPCType:string = State_Dictionary.GiveString(NPCIdN)
    if not NPCType then print("incorrect NPC Id", NPCIdN); return end 
    local NPCSPFolder:any = NPCSP[NPCType]
    local NPCData:SharedType.NPCData = NPCInfo[NPCType]
    local SpawnPart:Part = NPCSPFolder[SpawnPartNumber]
    local SPPos = SpawnPart.Position
    local RR = Hitbox:Raycasting(SPPos, SPPos + Vector3.new(0, -1 , 0), 100)
    if not RR then warn("Failed to Find Ground "); return end
    local Data = {
        ["WalkSpeed"] = NPCData.WalkSpeed,
        ["Hip"] = NPCData.Hip ,
        ["UID"] = UID,
        ["Pos"] = RR.Position
    }
    local CFSM_Name = NPCType.."CFSM"
    -- local HumanoidStateType_Mod = NPCData.BodyType.."States"  --script.HumanoidStates
    local NPCFSM_Module:ModuleScript = NPCStateModsHandler[CFSM_Name]
    if not NPCFSM_Module then warn("Incorrect FSM Module: ", NPCFSM_Module, NPCStateModsHandler); return end
    task.synchronize()
    local NPCChar = CharModels[NPCType]:Clone()
    NPCChar.Name = UID 
    local Humanoid = HumanoidMachine:InitHumanoid(NPCChar, require(script.OtherHumanoidStates))
    local Profile: CharacterHandler.Profile =  CharacterHandler.Spawn(NPCChar, Data, Humanoid)
    local StateMachine = ClientCombatMachine:InitMPCMachine(NPCChar, require(NPCFSM_Module))
    StateMachine.CurrentItem = NPCData.Weapon
    ClientCombatMachine.TriggerAction(NPCChar, nil, "InitIdle", NPCData)
    
    -- Stats_Handler.SetNPCStats(NPCChar, NPCData)
    local ForwardActor, DownwardActor , HBActor= ClientMessageAPI.InitClient(ClientActor)
    Profile.Forward  = ForwardActor
    Profile.Down = DownwardActor
    HBActor:Destroy() --* no longer needed to NativeClient
    task.delay(1, function()
        ForwardActor:SendMessage("Init", UID)
        DownwardActor:SendMessage("Init", UID)
    end)
    local StateNum = State_Dictionary.GiveNumRef(StateMachine.CurrentState)
    if not StateNum then warn("something went wrong NPCMAKE: ", StateNum); return end
    Profile.StateNum = StateNum
    -- CharacterHandler.AddToOtherPlayerTable(Profile)
end)
UpVectorEvent.OnClientEvent:ConnectParallel(function(UpVector_Buffer:buffer)
    local UID:number = buffer.readu8(UpVector_Buffer, 0)
    local Profile = CharacterHandler.GiveProfile(tostring(UID))
    if not Profile then print("error Upvector event"); return end
    local Ri8 = buffer.readi8
    local x, y, z = Ri8(UpVector_Buffer, 1), Ri8(UpVector_Buffer, 2), Ri8(UpVector_Buffer, 3)  
    local UV3 = Vector3.new(x, y, z)
    task.synchronize()
    Profile.UV3V.Value = UV3
end)
ClientActor:BindToMessageParallel("HM_OldState", function()  
    HumanoidMachine.ChangeToOldState(MyUID)    
end)
ClientActor:BindToMessageParallel("FootStep", function(UID:string)  
    UID = tostring(UID)
    local Profile = CharacterHandler.GiveProfile(UID)
    if not Profile then warn("no Profile, ", UID, typeof(UID)); return end
    Sound_Handler.InsertWithId(Profile.FMV.Value, Profile.Avatar.PrimaryPart, false)
end)
ClientActor:BindToMessageParallel("JumpSound", function()  
    Particle_Handler.Jump(Character)
end)

--[[ --TODO_REMOVE
*in future the Bind messages below will become redundant cos the VFXEvent (that handles all particles) will be replacing it 
*this will be after QDash and WallRun and Bounce are on the Server and the Server is synced with the Client
]]
ClientActor:BindToMessageParallel("DashSound", function()  
    Particle_Handler.Dash(Character)
end)
ClientActor:BindToMessageParallel("BounceSound", function()  
    Particle_Handler.Bounce(Character, nil)
end)
ClientActor:BindToMessageParallel("WallRunSound", function()  
    local Profile = CharacterHandler.GiveProfile(Character.Name)
    Particle_Handler.WallRun(Character, nil, -Profile.UV3V.Value)
end)

-- ↓↓↓↓↓↓↓↓↓↓ PLACE HOLDER ↓↓↓↓↓↓↓↓↓↓
-- ↑↑↑↑↑↑↑↑↑↑ PLACE HOLDER ↑↑↑↑↑↑↑↑↑↑

--* ↓↓↓↓↓↓↓↓↓↓ Input Handlers ↓↓↓↓↓↓↓↓↓↓
Input_Receive_Functions[1] = function(inputState: Enum.UserInputState, inputObject: InputObject) --* Movement W A S D 
    if inputState.Value == Enum.UserInputState.Begin.Value then
        local Value = inputObject.KeyCode.Value
        local Add:number = Enum_Keycode_Values[Value]
        if Add then  MovementNumber += Add end
        return
    end
    if inputState.Value == Enum.UserInputState.End.Value then
        local Value = inputObject.KeyCode.Value
        local Subtract:number = Enum_Keycode_Values[Value]
        if Subtract then  MovementNumber -= Subtract end
        return
    end
end
Input_Receive_Functions[2] = function(inputState: Enum.UserInputState, inputObject: InputObject) --* Menu M 
    if inputState.Value == Enum.UserInputState.Begin.Value and  CameraLockBool  then
        CameraLockBool = nil
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
        Gui_Handler.InventoryGuiBool()
    elseif inputState.Value == Enum.UserInputState.Begin.Value then
        CameraLockBool = true
        UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter 
        Gui_Handler.InventoryGuiBool()
    end
end
Input_Receive_Functions[3] = function(inputState: Enum.UserInputState, inputObject: InputObject) --* Jump Space_Bar 
    if inputState.Value == Enum.UserInputState.Begin.Value then
        local CurrentUnix = DateTime.now().UnixTimestamp
        if CurrentUnix - JumpUnix < JumpCD then return end 
        JumpUnix = CurrentUnix
        Add_To_Input_Queue(1, {})
    end 
end
Input_Receive_Functions[4] = function(inputState: Enum.UserInputState, inputObject: InputObject) --* Dash Q 
    if inputState.Value == Enum.UserInputState.End.Value then PressQ = false;  return end
    local CurrentUnix = DateTime.now().UnixTimestamp
    if CurrentUnix - DashUnix < DashCD then return end 
    if inputState.Value == Enum.UserInputState.Begin.Value then PressQ = true; end
end
Input_Receive_Functions[5] = function(inputState: Enum.UserInputState, inputObject: InputObject) --* Attack + Dash  M1 
    if inputState.Value == Enum.UserInputState.Begin.Value  then
        if PressQ then 
            local CurrentUnix = DateTime.now().UnixTimestamp
            if CurrentUnix - DashUnix < DashCD then return end 
            DashUnix = CurrentUnix
            Add_To_Input_Queue(2, {CamCF}) --* they can only dash after they press M1 while Holding down Q     
            return
        end  
        --TODO M1 ↓
        Add_To_Input_Queue(7, {}) --* they can only dash after they press M1 while Holding down Q     
        return
    end
end
Input_Receive_Functions[6] = function(inputState: Enum.UserInputState, inputObject: InputObject) --* Toolbar Keys;  1 -> 8 
    if inputState.Value == Enum.UserInputState.Begin.Value  then
        local CurrentTime = DateTime.now().UnixTimestamp
        if CurrentTime - EquipUnix < EquipCD then return end
        EquipUnix = CurrentTime
        Add_To_Input_Queue(3, {inputObject.KeyCode.Value}) 
        return
    end
end
Input_Receive_Functions[7] = function(inputState: Enum.UserInputState, inputObject: InputObject) --* Switching between Toolbars 
    if inputState.Value == Enum.UserInputState.Begin.Value  then
        Add_To_Input_Queue(4, {})
        return
    end
end
Input_Receive_Functions[8] = function(inputState: Enum.UserInputState, inputObject: InputObject) --* WallRunning
    if inputState.Value == Enum.UserInputState.Begin.Value  then
        local CurrentUnix = DateTime.now().UnixTimestamp
        if CurrentUnix - WallRunUnix < WallRunCD then return end 
        WallRunUnix = CurrentUnix
        Add_To_Input_Queue(5, {CamCF})
        return
    end

end
Input_Receive_Functions[9] = function(inputState: Enum.UserInputState, inputObject: InputObject) --* M2 Heavy
    if inputState.Value == Enum.UserInputState.Begin.Value  then
        Add_To_Input_Queue(8, {})
        return
    end
end
Input_Receive_Functions[10] = function(inputState: Enum.UserInputState, inputObject: InputObject) --* F Block
    if inputState.Value == Enum.UserInputState.Begin.Value  then
        Add_To_Input_Queue(9, {})
        return
    end
    if inputState.Value == Enum.UserInputState.End.Value  then
        Add_To_Input_Queue(10, {})
        return
    end
end
Input_Receive_Functions[2](Enum.UserInputState.Begin, nil)
--* ↑↑↑↑↑↑↑↑↑↑ Input Handlers ↑↑↑↑↑↑↑↑↑↑

--* ↓↓↓↓↓↓↓↓↓↓ Input Processes ↓↓↓↓↓↓↓↓↓↓
Input_Queue_Functions[1] =  function(Client_remote_buffer:buffer, Most_Recent_Input:Input_Queue_Setup) --* Jump Space_Bar 
    local Current_Unix =     DateTime.now().UnixTimestampMillis
    local Artificial_Ping = (player:GetNetworkPing()*500) + 32 --* their Ping/2 + 32ms 
    local Has_Enough_Time_Passed = Current_Unix - Most_Recent_Input.Unix > Artificial_Ping 
    if  Has_Enough_Time_Passed then  --* artificial Delay
        HumanoidMachine.TriggerAction(Character, nil, "Jump")
        return Client_remote_buffer, true
    end 
    if Most_Recent_Input.Net_Processed_Flag then return Client_remote_buffer end
    Most_Recent_Input.Net_Processed_Flag = true
    local Jump_Buffer= BCreate(2)
    writeu8(Jump_Buffer, 0, 2) --* for the Server its ID is 2;  Check Character_Controller
    writeu8(Jump_Buffer, 1, 0) --* There is no additional info to send therefore the Length is 0   
    return Merge_Buffers(Client_remote_buffer, {Jump_Buffer})
end
Input_Queue_Functions[2] =  function(Client_remote_buffer:buffer, Most_Recent_Input:Input_Queue_Setup, CameraCF_Stamp:CFrame) --* Dash Q + M1  
    if not PressQ  then  return Client_remote_buffer, true end --* process the input but its rejected cos they are not pressing the Combo Q + M1
    local Current_Unix =     DateTime.now().UnixTimestampMillis
    local Artificial_Ping = (player:GetNetworkPing()*500) + 32 --* their Ping/2 + 32ms 
    local Has_Enough_Time_Passed = Current_Unix - Most_Recent_Input.Unix > Artificial_Ping 
    if  Has_Enough_Time_Passed then  --* artificial Delay
        HumanoidMachine.TriggerAction(Character, nil, "QDash", CameraCF_Stamp.LookVector)
        return Client_remote_buffer, true
    end 
    if Most_Recent_Input.Net_Processed_Flag then return Client_remote_buffer end
    Most_Recent_Input.Net_Processed_Flag = true
    local Dash_Buffer= BCreate(8)
    local offset = 0
    local x, y, z = CameraCF_Stamp.LookVector.X, CameraCF_Stamp.LookVector.Y, CameraCF_Stamp.LookVector.Z
    writeu8(Dash_Buffer,  offset, 3) --* for the Server its ID is 3;  Check Character_Controller
    offset += 1
    writeu8(Dash_Buffer,  offset, 6) --* the camera Look Buffer  so additional 6 bytes  
    offset += 1
    writei16(Dash_Buffer, offset, x *10000);
    offset += 2
    writei16(Dash_Buffer, offset, y *10000);
    offset += 2
    writei16(Dash_Buffer, offset, z *10000)
    offset += 2
    return Merge_Buffers(Client_remote_buffer, {Dash_Buffer})    
end
Input_Queue_Functions[3] =  function(Client_remote_buffer:buffer, Most_Recent_Input:Input_Queue_Setup, KeyCode_Value:number) --* Toolbar Keys   
    --* the Output for this will be recieved from the server via  Remote_Functions[5] check below 
    local Item_Chosen_Buffer = buffer.create(3)
    local offset  = 0
    writeu8(Item_Chosen_Buffer, offset, 4) --* Server ID
    offset += 1
    writeu8(Item_Chosen_Buffer, offset, 1) --* additional Argument Length is 1 for the Active_ToolBar
    offset += 1
    writeu8(Item_Chosen_Buffer, offset, KeyCode_Value)
    offset += 1

    return Merge_Buffers(Client_remote_buffer, {Item_Chosen_Buffer}), true
end
Input_Queue_Functions[4] =  function(Client_remote_buffer:buffer, Most_Recent_Input:Input_Queue_Setup) --* Switching between Toolbars  
    local Active_ToolBar = MyProfile.Active_ToolBar
    if Active_ToolBar == 1 then 
        Active_ToolBar = 2  
    else  
        Active_ToolBar = 1    
    end
    Gui_Handler.SwitchToolBars(Active_ToolBar)
    MyProfile.Active_ToolBar = Active_ToolBar
    local Active_ToolBar_Buffer = buffer.create(3)
    local offset  = 0
    writeu8(Active_ToolBar_Buffer, offset, 6) --* Server ID
    offset += 1
    writeu8(Active_ToolBar_Buffer, offset, 1) --* additional Argument Length is 1 for the Active_ToolBar
    offset += 1
    writeu8(Active_ToolBar_Buffer, offset, Active_ToolBar)
    offset += 1
    return Merge_Buffers(Client_remote_buffer, {Active_ToolBar_Buffer}), true
end
Input_Queue_Functions[5] =  function(Client_remote_buffer:buffer, Most_Recent_Input:Input_Queue_Setup, CameraCF_Stamp:CFrame) --* wall running  
    if Most_Recent_Input.Net_Processed_Flag then return Client_remote_buffer end
    Most_Recent_Input.Net_Processed_Flag = true
    local Dash_Buffer= BCreate(8)
    local offset = 0
    local x, y, z = CameraCF_Stamp.LookVector.X, CameraCF_Stamp.LookVector.Y, CameraCF_Stamp.LookVector.Z
    writeu8(Dash_Buffer,  offset, 5) --* for the Server its ID is 5; wallrunn;  Check Character_Script
    offset += 1
    writeu8(Dash_Buffer,  offset, 6) --* the camera Look Buffer  so additional 6 bytes  
    offset += 1
    writei16(Dash_Buffer, offset, x *10000);
    offset += 2
    writei16(Dash_Buffer, offset, y *10000);
    offset += 2
    writei16(Dash_Buffer, offset, z *10000)
    offset += 2
    return Merge_Buffers(Client_remote_buffer, {Dash_Buffer}), true
end
Input_Queue_Functions[6] =  function(Client_remote_buffer:buffer, Most_Recent_Input:Input_Queue_Setup, PlacementNum, Place_HolderNum, Inventory_Tool:ImageButton) --* Gui Inventory_Tool Placement  
    local ItemID = Inventory_Tool:GetAttribute("ItemID")
    local offset = 0
    local Inventory_Tool_Placement_buffer = buffer.create(6)
    writeu8(Inventory_Tool_Placement_buffer,  offset, 7) --* for the Server its ID is 5; wallrunn;  Check Character_Script
    offset += 1
    writeu8(Inventory_Tool_Placement_buffer,  offset, 4) --*  additional Length
    offset += 1
    writeu8(Inventory_Tool_Placement_buffer,  offset, PlacementNum)  --* 1, 2 = Toolbars; 3 = BodyFrame; 4 = InventoryFrame
    offset += 1
    writeu8(Inventory_Tool_Placement_buffer,  offset, Place_HolderNum)  --* 1 -> 8 for Toolbars;  1 -> 6 for BodyFrame;  0 means ignore
    offset += 1
    writeu16(Inventory_Tool_Placement_buffer,  offset, ItemID) --* ItemNumType 
    offset += 2
    return Merge_Buffers(Client_remote_buffer, {Inventory_Tool_Placement_buffer}), true
end
Input_Queue_Functions[7] =  function(Client_remote_buffer:buffer, Most_Recent_Input:Input_Queue_Setup) --* M1 Attack
    local Current_Unix =     DateTime.now().UnixTimestampMillis
    local Artificial_Ping = (player:GetNetworkPing()*500) + 32 --* their Ping/2 + 32ms 
    local Has_Enough_Time_Passed = Current_Unix - Most_Recent_Input.Unix > Artificial_Ping 
    if  Has_Enough_Time_Passed then  --* artificial Delay
        ClientCombatMachine.TriggerAction(Character, nil, "M1")
        return Client_remote_buffer, true --* bool for processing input
    end 
    if Most_Recent_Input.Net_Processed_Flag then return Client_remote_buffer end
    Most_Recent_Input.Net_Processed_Flag = true
    local M1Buffer = BCreate(2)
    writeu8(M1Buffer, 0, 8) --* Server ID
    writeu8(M1Buffer, 1, 0) --* Additional Args Length
    return Merge_Buffers(Client_remote_buffer, {M1Buffer})    
end
Input_Queue_Functions[8] =  function(Client_remote_buffer:buffer, Most_Recent_Input:Input_Queue_Setup) --* M2 Attack  
    local Current_Unix =     DateTime.now().UnixTimestampMillis
    local Artificial_Ping = (player:GetNetworkPing()*500) + 32 --* their Ping/2 + 32ms 
    local Has_Enough_Time_Passed = Current_Unix - Most_Recent_Input.Unix > Artificial_Ping 
    if  Has_Enough_Time_Passed then  --* artificial Delay
        ClientCombatMachine.TriggerAction(Character, nil, "M2")
        return Client_remote_buffer, true --* bool for processing input
    end 
    local M2Buffer = BCreate(1)
    writeu8(M2Buffer, 0, CurrentFrame)
    --TODO Merger buffers after doing server side
    return Client_remote_buffer    
end
Input_Queue_Functions[9] =  function(Client_remote_buffer:buffer, Most_Recent_Input:Input_Queue_Setup) --* Block
    local Current_Unix =     DateTime.now().UnixTimestampMillis
    local Artificial_Ping = (player:GetNetworkPing()*500) + 32 --* their Ping/2 + 32ms 
    local Has_Enough_Time_Passed = Current_Unix - Most_Recent_Input.Unix > Artificial_Ping 
    if  Has_Enough_Time_Passed then  --* artificial Delay
        ClientCombatMachine.TriggerAction(Character, nil, "Block")
        return Client_remote_buffer, true --* bool for processing input
    end 
    local M2Buffer = BCreate(1)
    writeu8(M2Buffer, 0, CurrentFrame)
    --TODO Merger buffers after doing server side
    return Client_remote_buffer    
end
Input_Queue_Functions[10] =  function(Client_remote_buffer:buffer, Most_Recent_Input:Input_Queue_Setup) --* Stop Block  
    local Current_Unix =     DateTime.now().UnixTimestampMillis
    local Artificial_Ping = (player:GetNetworkPing()*500) + 32 --* their Ping/2 + 32ms 
    local Has_Enough_Time_Passed = Current_Unix - Most_Recent_Input.Unix > Artificial_Ping 
    if  Has_Enough_Time_Passed then  --* artificial Delay
        ClientCombatMachine.TriggerAction(Character, nil, "StopBlock")
        return Client_remote_buffer, true --* bool for processing input
    end 
    local M2Buffer = BCreate(1)
    writeu8(M2Buffer, 0, CurrentFrame)
    --TODO Merger buffers after doing server side
    return Client_remote_buffer    
end

--* ↑↑↑↑↑↑↑↑↑↑ Input Handlers ↑↑↑↑↑↑↑↑↑↑

local Communicate_MT = setmetatable({}, {
    __call = function(_, Input_ID:number, Values:{any})
        Add_To_Input_Queue(Input_ID, Values)
    end
})
ClientMessageAPI["MT"] = Communicate_MT
--* ↓↓↓↓↓↓↓↓↓↓ FROM SERVER  ↓↓↓↓↓↓↓↓↓↓
Remote_Functions[1] = function (Everything_Buffer:buffer, offset) --* Client_Init_Player
    local Rf32 = buffer.readf32 
    local readu8 = buffer.readu8
    local readu16 = buffer.readu16
    local readf64 = buffer.readf64
    local Hip:number = 4.2
    local WalkSpeed:number = 10
    local UID = readu8(Everything_Buffer, offset)
    UID = tostring(UID)
    offset += 1
    local x =  Rf32(Everything_Buffer, offset)
    offset += 4
    local y =  Rf32(Everything_Buffer, offset)
    offset += 4 
    local z =  Rf32(Everything_Buffer, offset)
    offset += 4
    local Pos:Vector3 = Vector3.new(x, y, z)
    task.synchronize()
    local char= InitChar(UID)
    local MyPlayer: boolean = tonumber(MyUID) == tonumber(UID)
    local Humanoid: SharedType.CustomHumanoid
    local Data = {
        ["UID"] = UID,
        ["Pos"] = Pos,
        ["Hip"] = Hip,
        ["WalkSpeed"] = WalkSpeed,
    }
    local function InitEverything(StateMachine)
        Humanoid = HumanoidMachine:InitHumanoid(char, StateMachine)
        -- AvatarData = Data_Handler.Read_Avatar_Data_Func(AvatarData, AvatarBuffer, AvatarRGBBuffer)
        task.synchronize()
        -- Customise_Handler.init(AvatarData, char)
        CharacterHandler.Spawn(char, Data, Humanoid)
        Stats_Handler:InitAttributes(char, UID, "Humanoid")
        local Profile: CharacterHandler.Profile = CharacterHandler.GiveProfile(UID)
        local ForwardActor, ProceduralActor= ClientMessageAPI.InitClient(ClientActor)
        Profile.Forward  = ForwardActor
        Profile.Procedural = ProceduralActor --* future use for Procedural anims raycasting
        
        local UpVector3Value:Vector3Value = Instance.new("Vector3Value")
        UpVector3Value.Name = "UV3V"
        UpVector3Value:AddTag(UID.."UV3V")
        UpVector3Value.Value = Vector3.new(0, 1, 0)
        Profile.UV3V = UpVector3Value
        UpVector3Value.Parent = ForwardActor
        
        --* for Procedural Actor
        local MoveV3 = Instance.new("Vector3Value")
        MoveV3:AddTag(UID.."Direction")
        Profile.MV3 = MoveV3
        MoveV3.Parent = ForwardActor
        Humanoid["MV3"] = MoveV3
        
        local LookV3 = Instance.new("Vector3Value")
        LookV3:AddTag(UID.."LV3")
        Profile.LV3 = LookV3
        LookV3.Parent = ForwardActor
        Humanoid["LV3"] = LookV3
        
        task.delay(1, function()
            ForwardActor:SendMessage("Init", UID)
        end)

        local FloorMaterialValue = Instance.new("NumberValue")
        FloorMaterialValue.Name = "FMV"
        FloorMaterialValue.Value = Enum.Material.Ground.Value
        FloorMaterialValue:AddTag(UID.."FMV")
        Profile.FMV = FloorMaterialValue
        FloorMaterialValue.Parent = ForwardActor
        return ForwardActor, ProceduralActor
    end
    
    local Profile: CharacterHandler.Profile
    local Toolbars
    local Equipped
    local CosmeticEquipped --TODO
    local BackPack 
    if MyPlayer then        
        local  FA, ProceduralActor = InitEverything(HumanoidStates)
        Character = char
        local VNV = Instance.new("NumberValue")
        VNV:AddTag(UID.."VNV")
        VNV.Parent = FA
        Profile = CharacterHandler.GiveProfile(UID)
        Profile.VNV = VNV
        MyProfile = Profile
        print("PROFILE MADE client")
        UV3VChanged = Profile.UV3V.Changed:Connect(function(a0: Vector3)
            local Avatar = Profile.Avatar  
            FixCamera(Avatar.LookBody.CFrame.LookVector, Profile.UV3V, Avatar.LookBody)
        end)
        task.delay(2, function()
            CharacterHandler["MyCharacter_Actor"] = MyCharacter_Actor
            InputHandler["MyCharacter_Actor"] = MyCharacter_Actor
            InputHandler["Character"] = Character
            task.wait(0.5)
            
            ProceduralActor:SendMessage("Init", UID, true)            
        end)
        local ServerFrame = readu8(Everything_Buffer, offset)
        offset += 1
        local ServerUnix = readf64(Everything_Buffer, offset) 
        offset += 8    
        local DiffUnix = DateTime.now().UnixTimestampMillis  - ServerUnix
        local Decimal = DiffUnix/1000
        local FrameDiff = Decimal/ (1/30)
        ServerFrame = math.round (ServerFrame+ FrameDiff)
        if ServerFrame > 30 then ServerFrame -=30 end
        CurrentFrame  = ServerFrame + 1  
        local InventoryLength = readu16(Everything_Buffer, offset)    
        offset += 2
        offset, Toolbars = Inventory_Handler.Init_Toolbars(Everything_Buffer, offset)
        offset, Equipped = Inventory_Handler.Init_Equipped(Everything_Buffer, offset)
        CosmeticEquipped = Equipped --TODO_FUTURE
        offset += 12 --* bcos of the Cosmetic buffer _FUTURE_ 
        offset, BackPack= Inventory_Handler.Init_BackPack(Everything_Buffer, offset, InventoryLength)
        
        Gui_Handler.BackPack(BackPack)
        Gui_Handler.Equipped(Equipped) 
        Gui_Handler.ToolBars(Toolbars) 
        print(Toolbars)
        Profile.Active_ToolBar = 1
        Profile.ToolBars = {Toolbars[1], Toolbars[2]}
        Profile.BodyEquipped = Equipped
        
        Stats_Handler.Init_Profile(UID, Init_Stats(UID))
        ClientCombatMachine:InitMachine(char, require(script.ClientCombatStateMods.PlayerCombat))    
    else
        --* a different Player (not u) 
        --TODO Cosmetic and armour related things for other characters
        task.synchronize()
        local  FA,  ProceduralActor = InitEverything(OtherHumanoidStates)
        ClientCombatMachine:InitMachine(char, require(script.ClientCombatStateMods.OtherPlayerCombat))
        ProceduralActor:AddTag("ActorPA")
        task.delay(2, function() 
            ProceduralActor:SendMessage("Init", UID) 
            FA:Destroy()   
        end)
    end 
    Profile.CurrentBodyEquipped = {} --* sorted in the ArmourTypes_Func Table
    for ArmourType, Item_ID in pairs(Equipped) do 
        local Item_Name = Item_Dictionary[Item_ID]
        if not Item_Name then  continue end --* just means Item_ID = 0 
        local ItemData:ItemDataMod.ItemData = ItemDataMod[Item_Name]
        local Item_Type_Folder = Items[ItemData.ItemType]
        local ItemClone:Model = Item_Type_Folder[Item_Name]:Clone()            
        ArmourTypes_Func[ArmourType](Profile.Avatar, ItemClone, Profile)
    end
    --* Init Character_StateBuffer ↓ 
    local StateBuffer = buffer.create(5)
    local Writeu8 = buffer.writeu8
    local State = 1 --*Blocking,Idle,WeaponOut , ... etc
    local Action = 1 --*Blocked, Parried, Block, M1, ... etc
    UID = tonumber(UID)
    Writeu8(StateBuffer, 0, 5)
    Writeu8(StateBuffer, 1, UID)
    Writeu8(StateBuffer, 2, State)
    Writeu8(StateBuffer, 3, Action)    
    ClientActor:SendMessage("UpdWithFrame", StateBuffer)

    return Everything_Buffer, offset
end
Remote_Functions[2] = function (Everything_Buffer:buffer, offset, Sub_buffer_Length) --* Character_CF_Tick
    local Ru8 = buffer.readu8    
    local Sub_Len = offset + Sub_buffer_Length
    -- local UIDTEST = Ru8(Everything_Buffer, offset);
    -- print(UIDTEST, "test")
    for i = 1, Sub_Len do
        if offset+ 9 > Sub_Len then break end
        local UID = Ru8(Everything_Buffer, offset);
        local Profile = CharacterHandler.GiveProfile(tostring(UID))
        if not Profile then print("1", UID); break end
        local UpVector:Vector3 = Profile.UV3V.Value
        local LookVector:Vector3 = Buffer_Converter.Reader_UnitVector_Buffer(Everything_Buffer, UpVector, offset + 6)
        local NewCF: CFrame = Buffer_Converter.CF_Read_Buffer(offset+1, Everything_Buffer, LookVector, UpVector)
        offset += 9 --* the Size of our CFrames (8 bytes) + UID (1 byte)
        local Avatar = Profile.Avatar
        local AvatarBody = Avatar.PrimaryPart
        local PreviousPos:Vector3 = AvatarBody.Position
        local Distance  = (PreviousPos- NewCF.Position).Magnitude     
        if UID == MyNumUID then
            if Distance > (Profile.VNV.Value *0.4 )+5 then
                task.synchronize()
                AvatarBody.CFrame  = NewCF
            end     
            continue
        end
        task.synchronize()
        AvatarBody.CFrame = NewCF --* this is to update other players for the Client
    end
end
Remote_Functions[3] = function (Everything_Buffer:buffer, offset, Sub_buffer_Length) --* Stats Upd Health, Posture, Stamina
    local Sub_Len = offset + Sub_buffer_Length
    if Sub_Len <= 1 then return end
    local readu8 = buffer.readu8 
    local readu16 = buffer.readu16
    --TODO add Dead VFX 
    local function DeadCheck(NewHealth, UID:string, MeBool)
        if NewHealth == 0 then 
            if MeBool then 
                Gui_Handler.DeathGui(true)
            end
            task.delay(5, function()
                CleanUpChar(UID)
                if MeBool then 
                    Gui_Handler.DeathGui(false)
                end
            end)         
        end
    end
    local StatsUpdate = function(UID:string, Profile:SharedType.Profile, StatName:string, MeBool)
        --* Gui Stats Update is in Client MAIN RUNSERVICE
        local StatsProfile = Stats_Handler.GiveProfile(UID)
        local NewStat = readu16(Everything_Buffer, offset)
        offset += 2      
        StatsProfile[StatName] = NewStat      
        DeadCheck(StatsProfile.Health, UID, MeBool)
        return offset    
    end
    local Stat_Functions= {
        [1] = "Health",
        [2] = "Posture",
        [3] = "Stamina"
    }
    for i = 1, Sub_Len do 
        if offset + 5 > Sub_Len then return end     
        local UID:number = readu8(Everything_Buffer, offset);
        offset += 1
        local StringUID = tostring(UID)
        local Length:number = readu8(Everything_Buffer, offset); 
        offset += 1
        local Profile: SharedType.Profile = CharacterHandler.GiveProfile(StringUID)
        if not Profile then return end --* sometimes during init_Player MUST KEEP
        for i = 1, Length, 3 do 
            local Type_Of_Stat = readu8(Everything_Buffer, offset);
            offset += 1
            local StatName = Stat_Functions[Type_Of_Stat] 
            if StatName then 
                offset = StatsUpdate(StringUID, Profile, StatName, UID == MyNumUID)
            else
                warn("incorrect StatNumberID: ", Type_Of_Stat)
            end
        end
        
    end
end
Remote_Functions[4] = function (Everything_Buffer:buffer, offset, Sub_buffer_Length) --* Combat States 
    local Sub_Length = offset + Sub_buffer_Length
    local BCopy = buffer.copy
    for i = 1, Sub_Length do 
        if offset + 5 > Sub_Length then  return end
        local Length = readu8(Everything_Buffer, offset)
        if Length == 0 then warn("no length", offset, Len(Everything_Buffer)); return end
        local Character_StateBuffer: buffer = BCreate(Length)
        BCopy(Character_StateBuffer, 0, Everything_Buffer, offset, Length)
        
        local UID: string = readu8(Character_StateBuffer,  1); UID = tostring(UID) 
        local StateNum: number = readu8(Character_StateBuffer, 2)
        local ActionNum: number = readu8(Character_StateBuffer, 3)        
        local ClientFrame = readu8(Character_StateBuffer, 4)
        offset += Length
        if ClientFrame <= 0 then warn("Frame 0: ", UID); continue end
        local Profile: CharacterHandler.Profile = CharacterHandler.GiveProfile(UID)
        if not Profile then warn("no profile");  continue end
        Profile.StateNum = StateNum
        local State: string = State_Dictionary[StateNum]
        local Action: string = State_Dictionary[ActionNum]
        ClientCombatMachine.ForceState(UID, State)
        local FromServerBool:boolean = true
        ClientCombatMachine.TriggerAction(Profile.Avatar, nil, Action, CurrentFrame, Character_StateBuffer, FromServerBool)--* give buffer cos extra args can be Used differently string or number etc        
    end
end
Remote_Functions[5] = function (Everything_Buffer:buffer, offset, Sub_buffer_Length) --* Toolbar_Sort 
    local ItemID = readu16(Everything_Buffer, offset)
    offset +=2
    local UID = readu8(Everything_Buffer, offset)
    offset +=1

    local Item_Name = Item_Dictionary[ItemID]
    if not Item_Name then 
        warn("no item", ItemID, UID) 
        return 
    end
    local Profile:SharedType.Profile = CharacterHandler.GiveProfile(tostring(UID))
    if not Profile then warn("no Character profile: ", UID, CharacterHandler.GiveEveryProfile()); return end
    local ItemData:ItemDataMod.ItemData = ItemDataMod[Item_Name]
    if ItemData.ItemNumType == 2 then 
        if Profile.CurrentPhysicalItem then 
            Profile.CurrentItem = nil
            Profile.CurrentPhysicalItem:Destroy()
            Profile.CurrentPhysicalItem = nil
            Profile.Current_Selected_Item = 0
            Stats_Handler.Init_Profile(UID, Init_Stats(UID))
            print("Unequiped", ItemID)
        else
            local Item_Type_Folder = Items[ItemData.ItemType]
            local ItemClone:Model = Item_Type_Folder[Item_Name]:Clone()        
            Profile.CurrentItem = Item_Name
            Profile.CurrentPhysicalItem = ItemClone
            Tween_Equip(ItemClone, Profile.Avatar)
            Profile.Current_Selected_Item = ItemID
            Stats_Handler.Init_Profile(UID, Init_Stats(UID))
            print("cloned item", ItemClone, ItemID)
        end    
    elseif ItemData.ItemNumType == 3 then 
        --* Skill Select
        Profile.Current_Selected_Item = ItemID
        Init_Stats(UID)
    end
    Gui_Handler.Pressed_Toolbar_Key(ItemID)
    
end
Remote_Functions[6] = function (Everything_Buffer:buffer, offset, Sub_buffer_Length) --* Armour Equip 
    local ItemID = readu16(Everything_Buffer, offset)
    offset +=2
    local UID = readu8(Everything_Buffer, offset)
    offset +=1

    local Item_Name = Item_Dictionary[ItemID]
    if not Item_Name then 
        warn("no item", ItemID, UID) 
        return 
    end

    local Profile = CharacterHandler.GiveProfile(tostring(UID))
    if not Profile then warn("error with profile"); return end
    local ItemData:ItemDataMod.ItemData = ItemDataMod[Item_Name]
    
    local OldItem = Profile.CurrentBodyEquipped[ItemData.ArmourType]
    if OldItem then 
        OldItem:Destroy()
    end
    local Item_Type_Folder = Items[ItemData.ItemType]
    local ItemClone:Model = Item_Type_Folder[Item_Name]:Clone()        
    local Char = Profile.Avatar
    ArmourTypes_Func[ItemData.ArmourType](Char, ItemClone, Profile)
    Profile.BodyEquipped[ItemData.ArmourType] = ItemID
   
    --TODO body equip SFX 
    Stats_Handler.Init_Profile(UID, Init_Stats(UID))
    print("cloned item", ItemClone, ItemID, ItemData.ArmourType)
end
Remote_Functions[7] = function (Everything_Buffer:buffer, offset, Sub_buffer_Length) --* Unequip 
    local UID = readu8(Everything_Buffer, offset)
    offset +=1
    local PlacementNum = readu8(Everything_Buffer, offset)
    offset +=1
    local Placement_Holder_Num = readu8(Everything_Buffer, offset)
    offset +=1
    local Profile = CharacterHandler.GiveProfile(tostring(UID))
    if not Profile then warn("error with profile; ", UID); return end    
    if PlacementNum == 3 then 
        --* Armour
        local OldItem = Profile.CurrentBodyEquipped[Placement_Holder_Num]
        if OldItem then 
            OldItem:Destroy()
        end
        Profile.BodyEquipped[Placement_Holder_Num] = 0
        print(Placement_Holder_Num, "client amrmour unequip")
        Stats_Handler.Init_Profile(UID, Init_Stats(UID))
    end
    if PlacementNum < 3 then
        --* Weapon  or skill
        if Profile.CurrentPhysicalItem then 
            Profile.CurrentPhysicalItem:Destroy()
            Profile.CurrentPhysicalItem = nil
            Profile.Current_Selected_Item = 0
            Stats_Handler.Init_Profile(UID, Init_Stats(UID))
            --* FSM will be updated through CombatStates (Remote_Functions[4])
            print("CLient Rmeoved weapon")
        end    
    end
    --TODO body equip SFX 
end
--* ↑↑↑↑↑↑↑↑↑↑ FROM SERVER  ↑↑↑↑↑↑↑↑↑↑
do  --* ↓↓↓↓↓↓↓↓↓↓ MAIN RUNSERVICE ↓↓↓↓↓↓↓↓↓↓
    local Everything_Event = T_of_Events.Everything
    local TI = TweenInfo.new(0.25, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, 0, false, 0)
    local InputDelta, InputStep = 0, 0.0332
    local FMVDelta, FMVStep = 0, 0.1
    local Cam_Delta, Cam_Step = 0, 0.2
    local StatsDelta, StatsUpdate_Step= 0, 0.5
    local Remote_Queue:{buffer} = {}
    -- local Move_Delta , MoveStep = 0, 0.05
    --* CombatDelta is the same as InputDelta
    Client_MainRBXSC = RunService.Heartbeat:Connect(function(a0: number)  
        FMVDelta += a0
        InputDelta += a0
        Cam_Delta += a0
        StatsDelta += a0
        -- Move_Delta += a0
        local Delta = UserInputService:GetMouseDelta()
        if MyProfile then 
            local Avatar = MyProfile.Avatar
            MouseMove(Delta.X, Delta.Y, MyProfile.UV3V, Avatar.LookBody)
        end
        if InputDelta < InputStep then return end --* smallest Step goes here
        InputDelta -= InputStep
        local Client_remote_buffer = buffer.create(0)
        if FMVDelta >= FMVStep then 
            FMVDelta -= FMVStep
            local Profiles = CharacterHandler.GiveEveryProfile()
            -- print("4", Profiles)
            for _, Profile in Profiles do
                local Avatar = Profile.Avatar
                local Hip:number = Avatar:GetAttribute("Hip")
                if not Hip then continue end
                local Origin:Vector3  = Avatar.PrimaryPart.Position
                local End:Vector3 = Origin + (-Profile.UV3V.Value) 
                local Floor_RR:RaycastResult? =  Hitbox:Raycasting(Origin, End, Hip*1.2)
                if not Floor_RR then 
                    --*Ragodll spinny. 
                    --TODO (technically no longer need ragdoll event)  
                    Profile.Procedural:SendMessage("Anim", "Jump", {7,8,9,10}, {7,8,9,10})
                    Profile.FMV.Value = Enum.Material.Air.Value  --*number value    
                    Profile.JumpBool = true
                    continue
                end
                --*Stop Ragodll spinny
                if Profile.JumpBool then 
                    Profile.JumpBool = false
                    Profile.Procedural:SendMessage("CancelAnim") 
                end
                Profile.FMV.Value = Floor_RR.Material.Value --*number value
            end
        end
        if  MyProfile then --* WASD movement; ShiftLock ↓
            local Input_ID_Buffer = buffer.create(2)
            writeu8(Input_ID_Buffer, 0, 1) --* Input_ID
            local LV3 = MyProfile.LV3
            local MV3 = MyProfile.MV3
            local UV3V = MyProfile.UV3V
            local Character = MyProfile.Avatar
            local Body = Character.PrimaryPart
            local LookBody = Character.LookBody
            local RelativeDirCF = MovementHelper:GiveDirection(Character, MovementNumber) 
            local look_Vector_Buffer = Buffer_Converter.UnitVector_Buffer(ProjectionVector(LV3.Value, UV3V.Value))
            if not RelativeDirCF then 
                HumanoidMachine.TriggerAction(Character, nil, "StopWalk")     
                writeu8(Input_ID_Buffer, 1, 2) --* Length Of Sub buffer
                Client_remote_buffer = Merge_Buffers(Client_remote_buffer, {Input_ID_Buffer, look_Vector_Buffer})
            else
                writeu8(Input_ID_Buffer, 1, 4) --* Length Of Sub buffer
                local Move_Vector_Buffer = Buffer_Converter.UnitVector_Buffer(ProjectionVector(MV3.Value, UV3V.Value))
                Client_remote_buffer = Merge_Buffers(Client_remote_buffer, {Input_ID_Buffer, look_Vector_Buffer, Move_Vector_Buffer})
                HumanoidMachine.TriggerAction(Character, nil, "StartWalk", RelativeDirCF) --* for CLient            
            end
            if CameraLockBool then 
                local CurrentUp = UV3V.Value
                local Current_Move= MV3.Value * 0.3 -- + (-CurrentUp)
                local Projected_CamLook:Vector3 = ProjectionVector(Camera.CFrame.LookVector, CurrentUp)
                local LookCF = CFrame.lookAlong(Body.Position, Projected_CamLook - Current_Move, CurrentUp )
                task.synchronize()
                LookBody.CFrame = LookCF
                LV3.Value = LookCF.LookVector    
            end
        end       
        CurrentFrame += 1
        if CurrentFrame > 30 then CurrentFrame -= 30 end
        InputHandler["CurrentFrame"] = CurrentFrame
        --* processes 30hz*8 = 240 inputs in a second or ~4.15ms ↓  
        for i = 1, 8 do 
            local Most_Recent_Input:Input_Queue_Setup? = Inputs_Queue[1]
            if  Most_Recent_Input then
                local NewBuffer, Processed_Input= Input_Queue_Functions[Most_Recent_Input.Input_ID](Client_remote_buffer, Most_Recent_Input, unpack(Most_Recent_Input.Values))
                if NewBuffer then
                    Client_remote_buffer = NewBuffer
                else
                    warn("Input Queue Error", Most_Recent_Input)
                end 
                if Processed_Input then table.remove(Inputs_Queue, 1) end
            else
                --* no more inputs to process
                break
            end
        end
        if Cam_Delta >= Cam_Step then 
            Cam_Delta -= Cam_Step
            task.synchronize()
            TweenService:Create(Camera, TI, {CFrame = CamCF}):Play()
        end
        if StatsDelta >= StatsUpdate_Step then 
            StatsDelta -=  StatsUpdate_Step
            local StatProfile = Stats_Handler.GiveProfile(MyUID)
            if StatProfile then
                if StatProfile.Health >= StatProfile.MaxHealth then 
                    StatProfile.Health = StatProfile.MaxHealth
                end
                if StatProfile.Posture >= StatProfile.MaxPosture then 
                    StatProfile.Posture = StatProfile.MaxPosture
                end
                if StatProfile.Stamina >= StatProfile.MaxStamina then 
                    StatProfile.Stamina = StatProfile.MaxStamina
                end
                Gui_Handler.SetHealth(Character, StatProfile.Health)
                Gui_Handler.SetPosture(Character, StatProfile.Posture)
                Gui_Handler.SetStamina(Character, StatProfile.Stamina)        
            end
        end
        local Everything_Buffer = table_remove(Remote_Queue, 1)
        if Everything_Buffer then 
            local offset = 0
            local length_Buffer = Len(Everything_Buffer)
            local Previous_Function_ID   --* for debugging purposes
            local YieldFlag = false
            for i = 1,  length_Buffer do 
                if offset + 3 > length_Buffer then break end 
                if YieldFlag then RunService.Heartbeat:Wait() end
                local Function_ID =  readu8(Everything_Buffer, offset)
                if not Remote_Functions[Function_ID] then warn("INCORRECT FUNCTION_ID: ", Function_ID, Previous_Function_ID, offset, length_Buffer); break end
                offset +=  1
                local Sub_buffer_Length =  readu16(Everything_Buffer, offset)
                offset += 2 --* Sub_buffer_Length is a number = 2 bytes
                YieldFlag = true
                Remote_Functions[Function_ID](Everything_Buffer, offset, Sub_buffer_Length)
                YieldFlag = false
                offset += Sub_buffer_Length
                Previous_Function_ID = Function_ID
            end     
        end
        if Len(Client_remote_buffer) <= 1 then return end 
        task_synchronize()
        Everything_Event:FireServer(Client_remote_buffer) 
    end)
    Inputs_Began = UserInputService.InputBegan:Connect(function(a0: InputObject, a1: boolean)  
        local Input2 = Valid_Input_Values[a0.UserInputType.Value]
        if Input2  then      
            Input_Receive_Functions[Input2](Enum.UserInputState.Begin, a0)    
            return  
        end        
        local Input = Valid_Input_Values[a0.KeyCode.Value]
        if Input  then
            Input_Receive_Functions[Input](Enum.UserInputState.Begin, a0)    
            return  
        end        
    end)
    Inputs_Ended = UserInputService.InputEnded:Connect(function(a0: InputObject, a1: boolean)  
        local Input2 = Valid_Input_Values[a0.UserInputType.Value]
        if Input2  then      
            Input_Receive_Functions[Input2](Enum.UserInputState.End, a0)    
            return  
        end        
        local Input = Valid_Input_Values[a0.KeyCode.Value]
        if Input  then      
            Input_Receive_Functions[Input](Enum.UserInputState.End, a0)    
            return  
        end        
    end)
    EverythingEvent.OnClientEvent:Connect(function(Everything_Buffer:buffer)  
        table_insert(Remote_Queue, Everything_Buffer)
    end)    
    ClientActor:BindToMessageParallel("Cleanup", function(UID:string)
    end)
end --* ↑↑↑↑↑↑↑↑↑↑ MAIN RUNSERVICE ↑↑↑↑↑↑↑↑↑↑


--[[ OutDated Stats funcs
local function Sort_Health(UID:string, Profile)
        local NewHealth = readu16(Everything_Buffer, offset)
        offset += 2            
        if tonumber(UID) == MyNumUID then --*Num comparison faster than string
            CharacterHandler.SetHealth(Profile.Avatar, NewHealth)
            Gui_Handler.SetHealth(Character, NewHealth)
            DeadCheck(NewHealth, UID, true)
            return offset
        end
        CharacterHandler.SetHealth(Profile.Avatar, NewHealth)
        DeadCheck(NewHealth, UID)
        return offset    
    end
    local function Sort_Posture(UID:string, Profile)
        local NewPosture = readu16(Everything_Buffer, offset)
        offset += 2            
        if tonumber(UID) == MyNumUID then --*Num comparison faster than string
            CharacterHandler.SetPosture(Profile.Avatar, NewPosture)
            Gui_Handler.SetPosture(Character, NewPosture)
            return offset
        end
        CharacterHandler.SetPosture(Profile.Avatar, NewPosture)
        return offset    
    end    
    local function Sort_Stamina(UID:string, Profile)
        local NewStamina = readu16(Everything_Buffer, offset)
        offset += 2            
        if tonumber(UID) == MyNumUID then --*Num comparison faster than string
            CharacterHandler.SetStamina(Profile.Avatar, NewStamina)
            Gui_Handler.SetStamina(Character, NewStamina)
            return offset
        end
        CharacterHandler.SetStamina(Profile.Avatar, NewStamina)
        return offset    
    end    

]]