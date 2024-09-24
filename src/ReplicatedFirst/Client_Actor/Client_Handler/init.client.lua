--!native
--[[ TODO:
-- TODO add ForwardActor and DowanWardActor to OtherProfiles in CharacterHandler
-- TODO_LATER check CharacterEvents = Children[2], it works but risky
-- Add a LoadClient event instead cos its better --///// P R I O R I T Y

]]
task.wait(3)
--* Constants
local CharacterActors = workspace:WaitForChild("WorkSpaceFolder", 15):WaitForChild("CharacterActors", 15)
task.wait()
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local NPCSP = workspace.NPCSP
local player: Player = game.Players.LocalPlayer
local MyUID = player:GetAttribute("UID")
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


local Shared = ReplicatedStorage.Shared

local ServerActor: Actor = CharacterActors:WaitForChild(MyUID, 15)
local ClientActor= script.Parent 
local Children = ServerActor:GetChildren()
local CharacterEvents = Children[2]  
--* Shared Mods
local SharedType = require(Shared.SharedType)
-- local Events:SharedType.CharacterEvents = CharacterEvents
-- local HB = require(Shared.Hitbox)
local AnimHandler = require(Shared.AnimHandler);  AnimHandler:InitAnimTypes("Humanoid")
-- local Event_Manager = require(Shared.Event_Manager)
local HumanoidMachine = require(Shared.HumanoidMachine)
local Encyclopedia = require(Shared.Encyclopedia)
-- local ItemDataMod = require(Shared.ItemDataMod)
local CharModels = ReplicatedStorage.Character
local Hitbox = require(Shared.Hitbox)
local NPCInfo = require(Shared.NPCInfo)


--// local ArgsForInputs= require(Shared.ArgsForInputs)
--* Local
local ClientMessageAPI = require(ClientActor.ClientMessageAPI)
local EventHandler = require(ClientActor.Event_Handler)
local T = {}; 
for _, Event in CharacterEvents:GetChildren() do T[Event.Name] = Event  end
EventHandler.init(T)-- before requiring InputHandler
local InputHandler = require(script.InputHandler)
local CharacterHandler = require(script.Character_Handler)
local Attribute_Handler = require(script.Character_Handler.Attribute_Handler)
-- local Checks = require(script.Character_Handler.Checks)
local Customise_Handler = require(script.Customise_Handler)
local Data_Handler = require(script.Data_Handler)
local Gui_Handler = require(script.Gui_Handler)

local HumanoidStates = require(script.HumanoidStates)
local Inventory_Handler = require(script.Inventory_Handler)
local OtherHumanoidStates = require(script.OtherHumanoidStates)
local ClientCombatMachine = require(script.Parent.ClientCombatMachine)
local NPCStateModsHandler = require(script.NPCFSM_Handler)

Gui_Handler.Init(player)
Inventory_Handler.InitGui(MyUID)

local Character: typeof(workspace.PixelDummy)
local DisableMotors =function (Motors:{Motor6D}, AbleBool:boolean, UID:string)
    task.synchronize()
    for _, Motor6D in Motors do 
        Motor6D.Enabled = AbleBool
    end
    local Profile: CharacterHandler.Profile = CharacterHandler.GiveProfile(UID)
    if not Profile then return end
    local Char:typeof(workspace.PixelDummy) = Profile.Avatar
    Char.Body.AO.Enabled = AbleBool
    if AbleBool then return end
    Char.Body:ApplyImpulse(Vector3.new(0, 50, 0))
end

LoadCombat.OnClientEvent:ConnectParallel(function(Inventory_Buffer: buffer) 
    task.wait(1) -- for Character to not be nil form LoadClient 
    -- Hotbar 1 and 2 
    --TODO MAKE: HotbarGui
    local UID = buffer.readu8(Inventory_Buffer, 0); UID = tostring(UID)
    local Profile = CharacterHandler.GiveProfile(UID) -- get Character from here 
    local Char = Profile.Avatar
    task.synchronize()
    ClientCombatMachine:InitMachine(Char, require(script.ClientCombatStateMods.PlayerCombat), Inventory_Buffer)
    Inventory_Handler.Init_Inventory(Inventory_Buffer)

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
end)
local InitChar = function(UID)
    local Char  = ReplicatedStorage.Character.PixelDummy:Clone()
    Char.Name = UID
    task.desynchronize()
    return Char
end
LoadClient.OnClientEvent:ConnectParallel(function(buff:buffer, AvatarBuffer:buffer, AvatarRGBBuffer:buffer)  
    --TODO you have added the Avatar Modules from NinPix MainMenu adjust them  Customise_Handler
    local Rf32 = buffer.readf32
    local Ru8 = buffer.readu8
    local Hip:number = 5
    local WalkSpeed:number = 16
    local UID:string = Ru8(buff, 0)
    UID = tostring(UID)
    local Pos:Vector3 = Vector3.new(Rf32(buff, 1), Rf32(buff, 5), Rf32(buff, 9))
    task.synchronize()
    local char= InitChar(UID)
    local MyPlayer: boolean = tonumber(MyUID) == tonumber(UID)
    local Humanoid: SharedType.CustomHumanoid
    local AvatarData = {
        ["Hair"] = {
            R = 0,
            G = 0,
            B = 0,
            Count = 0
        },
        ["Shirt"] = {
            R = 0,
            G = 0,
            B = 0,
            Count = 0
        },
        ["Pants"] = {
            R = 0,
            G = 0,
            B = 0,
            Count = 0
        },
        ["Eyes"] = {
            R = 0,
            G = 0,
            B = 0,
            Count = 0
        },
        ["Mouth"] = {
            R = 0,
            G = 0,
            B = 0,
            Count = 0
        },
        ["Skin"] = {
            R = 0,
            G = 0,
            B = 0,
            Count = 0    
        }
    }
    local Data = {
        ["UID"] = UID,
        ["Pos"] = Pos,
        ["Hip"] = Hip,
        ["WalkSpeed"] = WalkSpeed,
    }
    local function InitEverything(StateMachine)
        Humanoid = HumanoidMachine:InitHumanoid(char, StateMachine)
        AvatarData = Data_Handler.Read_Avatar_Data_Func(AvatarData, AvatarBuffer, AvatarRGBBuffer)
        task.synchronize()
        Customise_Handler.init(AvatarData, char)
        CharacterHandler.Spawn(char, Data, Humanoid)    
        
        local Profile: CharacterHandler.Profile = CharacterHandler.GiveProfile(UID)
        local ForwardActor, DownwardActor , HBActor= ClientMessageAPI.InitClient(ClientActor)
        Profile.Forward  = ForwardActor
        Profile.Down = DownwardActor
        Profile.Detect = HBActor --* future use for Procedural anims raycasting
        task.delay(1, function()
            ForwardActor:SendMessage("Init", UID)
            DownwardActor:SendMessage("Init", UID)
        end)
        return ForwardActor, DownwardActor, HBActor
    end
    if MyPlayer then
        local  _, _, DetectActor = InitEverything(HumanoidStates)
        Character = char
        task.delay(1, function()     
            CharacterHandler["ServerActor"] = ServerActor
            InputHandler["ServerActor"] = ServerActor
            InputHandler:StartTick()
            CharacterHandler.Init()
            InputHandler["Character"] = Character
            InputHandler:Init(Humanoid)
            InputHandler:GiveConnections(Character)
            Humanoid.Idle:Play()
            DetectActor:SendMessage("Init", UID, true)
        end)
        game.UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
        workspace.CurrentCamera.CameraSubject = char.Head
        local player = game.Players.LocalPlayer
        -- player.Character = char
        player.CameraMaxZoomDistance = 20
        player.CameraMinZoomDistance = 12
        -- print("Changed Camera subject set char")
    else
        task.synchronize()
        local  ForwardActor, DownwardActor, DetectActor = InitEverything(OtherHumanoidStates)
        ClientCombatMachine:InitMachine(char, require(script.ClientCombatStateMods.OtherPlayerCombat))
        ForwardActor.Name = UID.."Forward"
        DownwardActor.Name = UID.."Downward"
        -- DetectActor:Destroy() --* now needed for OtherPlayers cos future Procedural anims
    end 
end)
type UID = string
LoadGameState.OnClientEvent:ConnectParallel(function(initb: buffer) --* fired only once when they join  
    local sy = task.synchronize
    local FrameCount:number = buffer.readu8(initb, 0)-- 1
    local ServerUnix:number = buffer.readf64(initb, 1)-- 8
    local DiffUnix = DateTime.now().UnixTimestampMillis  - ServerUnix
	local Decimal = DiffUnix/1000
	local FrameDiff = Decimal/ (1/30)
	local ServerFrame = math.round (FrameCount + FrameDiff)
	if ServerFrame > 30 then ServerFrame -=30 end
    local CurrentFrame  = ServerFrame + 1 -- +1 syncs it better 
	local PreviousFrame = 0
    local D, Step = 0, 1/30

    local EntityCombatStates: { [UID]: buffer } = {} -- holds character State Buffer    
    sy()
    RunService.Heartbeat:ConnectParallel(function(deltaTime: number)
		D += deltaTime
		if D >= Step then
			D -= Step
            CurrentFrame += 1
            PreviousFrame = CurrentFrame -10 -- storing upto 10 frames 333ms
            if CurrentFrame > 30 then CurrentFrame -= 30 end
			if PreviousFrame < 0 then PreviousFrame += 30 end
            InputHandler["CurrentFrame"] = CurrentFrame
        end
    end)
    CombatTickEvent.OnClientEvent:ConnectParallel(function(ServerBuffer:buffer)
        --* you have to recursively read and process it as it contains multiple buffers within it
        local ReadU8 = buffer.readu8
        local Copy = buffer.copy
        -- local CurrentServerFrame = ReadU8(ServerBuffer, 0)
        local offset = 1
        local ServerBufferLen = buffer.len(ServerBuffer)
        
        for i = 1, ServerBufferLen do --95 max
            if offset >= ServerBufferLen then  return end
            local Length = ReadU8(ServerBuffer, offset)
            if Length == 0 then warn("no length"); return end
            local b: buffer = buffer.create(Length)
            Copy(b, 0, ServerBuffer, offset, Length)
            local UID: string = ReadU8(b, 1); UID = tostring(UID) 
            local StateNum: number = ReadU8(b, 2)
            local ActionNum: number = ReadU8(b, 3)        
            local ClientFrame = ReadU8(b, 4)
            offset += Length
            if ClientFrame <= 0 then warn("Frame 0: ", UID); continue end
            local Profile: CharacterHandler.Profile = CharacterHandler.GiveProfile(UID)
            if not Profile then warn("no profile");  continue end
            Profile.StateNum = StateNum
            --[[
            -- local DoubleTriggerCheck:boolean? = CompareSnapShot(ClientFrame, UID, StateNum, ActionNum)
            -- if  DoubleTriggerCheck == true then continue end --* Action already triggered in past frame
            
            ]] 
            local State: string = Encyclopedia[StateNum]
            local Action: string = Encyclopedia[ActionNum]
            ClientCombatMachine.ForceState(UID, State)
            local FromServerBool = true
            ClientCombatMachine.TriggerAction(Profile.Avatar, nil, Action, CurrentFrame, b, FromServerBool)--* give buffer cos extra args can be Used differently string or number etc
            EntityCombatStates[UID] = b
        end

        return EntityCombatStates
    end)
    ClientActor:BindToMessageParallel("UpdateProfile", function(b: buffer)
        local UID = buffer.readu8(b, 1); UID = tostring(UID)
        EntityCombatStates[UID] = b
    end)
    ClientActor:BindToMessageParallel("UpdWithFrame", function(b: buffer)
        local UID = buffer.readu8(b, 1); UID = tostring(UID)
        buffer.writeu8(b, 4, CurrentFrame)
        EntityCombatStates[UID] = b
    end)
    ClientActor:BindToMessageParallel("Cleanup", function(UID:string)
        EntityCombatStates[UID] = nil
    end)
end)
local CleanUpChar  = function(UID:string)
    HumanoidMachine[UID] = nil
    CharacterHandler.CleanProfile(UID)
    ClientCombatMachine.Cleanup(UID)
    ClientActor:SendMessage("Cleanup", UID)
    
    warn("Client Cleaned up Character: ", UID)
end
HealthEvent.OnClientEvent:ConnectParallel(function(HEALTH_BUFFER:buffer)
    local Len = buffer.len(HEALTH_BUFFER)
    if Len <= 1 then return end
    local Readu8 = buffer.readu8 
    local Readu16 = buffer.readu16
    local Needle = 0
    local function DeadCheck(NewHealth, UID:string, MeBool)
        if NewHealth == 0 then 
            local CustomHumanoid:SharedType.CustomHumanoid = HumanoidMachine[UID]
            if not CustomHumanoid then warn("incorrect UID: ", HumanoidMachine); return  end
            local Motors= CustomHumanoid.Motors
            DisableMotors(Motors, false, UID)
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
    for i = 1, 60 do 
        if Needle+ 3 > Len then return end 
        local UID = Readu8(HEALTH_BUFFER, Needle, 1);  
        local NewHealth = Readu16(HEALTH_BUFFER, Needle + 1)
        if UID == tonumber(MyUID) then --*Num comparison faster than string
            local Profile: CharacterHandler.Profile = CharacterHandler.GiveProfile(tostring(UID))
            if not Profile then print("no profile, Health Tick ");  return end --* sometimes during init process not to worry
            CharacterHandler.SetHealth(Profile.Avatar, NewHealth)
            Gui_Handler.SetHealth(Character, NewHealth)
            Needle += 3    
            DeadCheck(NewHealth, tostring(UID), true)
            continue
        end
        UID = tostring(UID)
        local Profile: CharacterHandler.Profile = CharacterHandler.GiveProfile(UID)
        if not Profile then print("no profile, Health Tick ");  return end --* sometimes during init process not to worry
        CharacterHandler.SetHealth(Profile.Avatar, NewHealth)
        Needle += 3
        DeadCheck(NewHealth, UID)
    end
end)
PostureEvent.OnClientEvent:ConnectParallel(function(POSTURE_BUFFER:buffer)
    --* posture changes should never happen in any CFSM it will be completely sorted from here
    local Len = buffer.len(POSTURE_BUFFER)
    if Len <= 1 then return end
    local Readu8 = buffer.readu8 
    local Readu16 = buffer.readu16
    -- local Needle = 0
    for i = 0, Len, 3 do 
        if i+ 3 > Len then return end 
        local UID = Readu8(POSTURE_BUFFER, i);  
        local NewPosture = Readu16(POSTURE_BUFFER, i + 1)
        if UID == tonumber(MyUID) then --*Num comparison faster than string
            local Profile: CharacterHandler.Profile = CharacterHandler.GiveProfile(tostring(UID))
            if not Profile then print("no profile, Posture Tick ");  return end --* sometimes during init process not to worry
            CharacterHandler.SetPosture(Profile.Avatar, NewPosture)
            Gui_Handler.SetPosture(Character, NewPosture)
            -- i += 3    
            continue
        end
        UID = tostring(UID)
        local Profile: CharacterHandler.Profile = CharacterHandler.GiveProfile(UID)
        if not Profile then print("no profile, Posture Tick ");  return end --* sometimes during init process not to worry
        CharacterHandler.SetPosture(Profile.Avatar, NewPosture)
        -- i += 3
    end
end)
RagdollEvent.OnClientEvent:ConnectParallel(function(RAGDOLL_BUFFER:buffer)  
    --TODO in Future add a Distance check of the Character (if they are not rendered)
    local Ru8 = buffer.readu8
    local Len = buffer.len(RAGDOLL_BUFFER)
    for i = 0, Len, 2 do 
        if i +1 >= Len then return end 
        local UID = Ru8(RAGDOLL_BUFFER, i)
        local Duration = Ru8(RAGDOLL_BUFFER, i +1)
        UID = tostring(UID)
        local CustomHumanoid:SharedType.CustomHumanoid = HumanoidMachine[UID]
        if not CustomHumanoid then warn("incorrect UID"); continue end
        local Motors= CustomHumanoid.Motors
        DisableMotors(Motors, false, UID) 

        
        local RagdollTime = CustomHumanoid.RagdollTime
        if RagdollTime then  task.cancel(RagdollTime) end   
        CustomHumanoid.RagdollTime = task.delay(Duration - 0.5, function()
            DisableMotors(Motors, true, UID)
            --TODO Add the Recovery animation maybe some dust VFX and sound
        end)
    end
end)

LoadStats.OnClientEvent:Connect(function()  
    task.wait(1)
    CharacterHandler.InitStats(Character)
end)
NPCMakeEvent.OnClientEvent:ConnectParallel(function(NPCInfo_BUFFER:buffer)
    local Readu8 = buffer.readu8 
    local UID = Readu8(NPCInfo_BUFFER, 0, 1);  UID = tostring(UID)
    local SpawnPartNumber = buffer.readu8(NPCInfo_BUFFER, 1)
    local NPCIdN = buffer.readu16(NPCInfo_BUFFER, 2)
    local NPCType:string = Encyclopedia.GiveString(NPCIdN)
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
    
    Attribute_Handler.SetNPCStats(NPCChar, NPCData)
    local ForwardActor, DownwardActor , HBActor= ClientMessageAPI.InitClient(ClientActor)
    Profile.Forward  = ForwardActor
    Profile.Down = DownwardActor
    HBActor:Destroy() --* no longer needed to NativeClient
    task.delay(1, function()
        ForwardActor:SendMessage("Init", UID)
        DownwardActor:SendMessage("Init", UID)
    end)
    local StateNum = Encyclopedia.GiveNumRef(StateMachine.CurrentState)
    if not StateNum then warn("something went wrong NPCMAKE: ", StateNum); return end
    Profile.StateNum = StateNum
    -- CharacterHandler.AddToOtherPlayerTable(Profile)
end)
--[[
local function CombatTick(ServerBuffer: buffer, offset: number)
    --copying constants and figuring out how many extra args
    
    -- if offset >= buffer.len(ServerBuffer) then return end
    -- local Needle = 
    -- CombatTick(ServerBuffer, Needle)
end
CombatTick(ServerBuffer, offset)
]]    
ClientActor:BindToMessageParallel("DownNoHit", function(UID)  
    local Profile: CharacterHandler.Profile = CharacterHandler.GiveProfile(UID)
    HumanoidMachine.ForceState(Profile.Avatar.Name, "Fall")
    Profile.Down:SendMessage("StartFall")
end)
ClientActor:BindToMessageParallel("LedgeUp", function(UID, RayPos: Vector3, Hip, CF: CFrame)  
    local Profile: CharacterHandler.Profile = CharacterHandler.GiveProfile(UID) 
    local AvatarBody = Profile.Avatar.PrimaryPart
    task.synchronize()
    AvatarBody.CFrame =  AvatarBody.CFrame * CFrame.new(0, Hip, 0)
end)
ClientActor:BindToMessageParallel("StopFall", function(UID)  
    local Profile: CharacterHandler.Profile = CharacterHandler.GiveProfile(UID)
    HumanoidMachine.TriggerAction(Profile.Avatar, nil, "ReleaseFall")
end)
ClientActor:BindToMessageParallel("ForwardHit", function(WallCF: CFrame) 
    local Body = Character.PrimaryPart
    task.synchronize()
    Body.CFrame = WallCF
end)
ClientActor:BindToMessageParallel("StopWalk", function(UID) 
    local Profile: CharacterHandler.Profile = CharacterHandler.GiveProfile(UID)
    Profile.Humanoid.IsWalking = false
    task.synchronize()
    Profile.Humanoid.Walk:Stop(0.6)
end)
ClientActor:BindToMessageParallel("SoftStun", function(DetectedUIDs, InfoT, FireEventBool:boolean)  
    --* this is for when the player hits otherplayers/Npcs NOT for player
    --* so this softstun here will never trigger PlayerCombat CFSM
    --* this will only ever be called by the player    
    if not FireEventBool then return end 
    -- local DetectedUIDs_Buffer:buffer = HB.BufferTableResults(DetectedUIDs, 1, 1)
    -- buffer.writeu8(DetectedUIDs_Buffer, 0, InputHandler["CurrentFrame"])
    -- Events.Detect:FireServer(DetectedUIDs_Buffer) --* this must in order to Release in ServerPlayerFSM
    warn("REMOVE THE DETECT IT NOW USELESS")
end)
--* Init Combat Anims
AnimHandler:InitAnimTypes("Sword")
AnimHandler:InitAnimTypes("Other")
AnimHandler:InitAnimTypes("Parry")



--[[ --* EXPLANATION on CombatTickEvent in LoadGameState
--* The EntityCombatStates is what can be Updated this will represent the SnapShots at all times
--* so SnapShots[CurrentFrame] = EntityCombatStates
--* so it important that When creating an Entity for Combat purposes u need to Init their State as a 5+ byte buffer
    -- or else it will indefinitely never work
--* what is a Double Trigger? 
it is when the Client triggers something and the Client will trigger it again cos the Server and Client are not aligned 
See the CompareSnapshot function which can prevent this from happening

]]
