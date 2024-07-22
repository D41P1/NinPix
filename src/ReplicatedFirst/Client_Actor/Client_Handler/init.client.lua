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
local FromServer = ReplicatedStorage.FromServer 
local LoadClient = FromServer.LoadClient
local LoadCombat = FromServer.LoadCombat
local LoadGameState = FromServer.GameState
local LoadStats = FromServer.LoadStat
local CombatTickEvent = FromServer.CombatTick
local HealthEvent = FromServer.HealthEvent
local PostureEvent = FromServer.PostureEvent
local NPCMakeEvent = FromServer.NPCMakeEvent

local Shared = ReplicatedStorage.Shared

local ServerActor: Actor = CharacterActors:WaitForChild(MyUID, 15)
local ClientActor= script.Parent 
local Children = ServerActor:GetChildren()
local CharacterEvents = Children[2]  
--* Shared Mods
local SharedType = require(Shared.SharedType)
local Events:SharedType.CharacterEvents = CharacterEvents
local HB = require(Shared.Hitbox)
local AnimHandler = require(Shared.AnimHandler);  AnimHandler:InitAnimTypes("Humanoid")
local Event_Manager = require(Shared.Event_Manager)
local HumanoidMachine = require(Shared.HumanoidMachine)
local Encyclopedia = require(Shared.Encyclopedia)
local ItemDataMod = require(Shared.ItemDataMod)
local CharModels = ReplicatedStorage.Character
local Hitbox = require(Shared.Hitbox)
local NPCInfo = require(Shared.NPCInfo)


--// local ArgsForInputs= require(Shared.ArgsForInputs)
--* Local
local ClientMessageAPI = require(ClientActor.ClientMessageAPI)
local EventHandler = require(ClientActor.Event_Handler)
local T = {}; 
for _, Event in CharacterEvents:GetChildren() do T[Event.Name] = Event  end
EventHandler["Events"] = T -- before requiring InputHandler
local InputHandler = require(script.InputHandler)
local CharacterHandler = require(script.Character_Handler)
local Attribute_Handler = require(script.Character_Handler.Attribute_Handler)
local Checks = require(script.Character_Handler.Checks)
local Gui_Handler = require(script.Gui_Handler)

local HumanoidStates = require(script.HumanoidStates)
local OtherHumanoidStates = require(script.OtherHumanoidStates)
local ClientCombatMachine = require(script.Parent.ClientCombatMachine)
local NPCStateModsHandler = require(script.NPCFSM_Handler)


local Character
LoadCombat.OnClientEvent:ConnectParallel(function(b: buffer) 
    task.wait(1) -- for Character to not be nil form LoadClient 
    -- Hotbar 1 and 2 
    --TODO MAKE: HotbarGui
    local UID = buffer.readstring(b, 0, 1)
    local Profile = CharacterHandler.GiveProfile(UID) -- get Character from here 
    local Char = Profile.Avatar
    ClientCombatMachine:InitMachine(Char, require(script.ClientCombatStateMods.PlayerCombat), b)
end)
local InitChar = function(UID)
    local Char  = ReplicatedStorage.Character.PixelDummy:Clone()
    Char.Name = UID
    task.desynchronize()
    return Char
end
LoadClient.OnClientEvent:ConnectParallel(function(buff:buffer)  
    local TableOfReferences = { "number", "string", "Vector3", "number" }
    local Hip:number, UID:string, Pos:Vector3, WalkSpeed:number = Event_Manager.Read(TableOfReferences, buff)    
    task.synchronize()
    local char= InitChar(UID)
    
    local MyPlayer: boolean = MyUID == UID
    local Humanoid: SharedType.CustomHumanoid
    local Data = {
        ["UID"] = UID,
        ["Pos"] = Pos,
        ["Hip"] = Hip,
        ["WalkSpeed"] = WalkSpeed
    }
    local function InitEverything(StateMachine)
        Humanoid = HumanoidMachine:InitHumanoid(char, StateMachine)
        task.synchronize()
        CharacterHandler.Spawn(char, Data, Humanoid, ClientActor)    
        
        local Profile: CharacterHandler.Profile = CharacterHandler.GiveProfile(UID)
        local ForwardActor, DownwardActor , HBActor= ClientMessageAPI.InitClient(ClientActor)
        Profile.Forward  = ForwardActor
        Profile.Down = DownwardActor
        Profile.Detect = HBActor
        task.delay(1, function()
            ForwardActor:SendMessage("Init", UID)
            DownwardActor:SendMessage("Init", UID)
            HBActor:SendMessage("Init", UID, true)
        end)
        return ForwardActor, DownwardActor, HBActor
    end
    if MyPlayer then
        InitEverything(HumanoidStates)
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
        end)
    else
        task.synchronize()
        local  ForwardActor, DownwardActor, DetectActor = InitEverything(OtherHumanoidStates)
        ClientCombatMachine:InitMachine(char, require(script.ClientCombatStateMods.OtherPlayerCombat))
        ForwardActor.Name = UID.."Forward"
        DownwardActor.Name = UID.."Downward"
        DetectActor.Name = UID.."Detect"
    end 
    Events.Detect:AddTag("DetectEvent")   
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

    local EntityCombatStates: { [UID]: buffer } = {} -- holds
    local SnapShots = {}    
    local CompareSnapShot = function(OtherClientFrame: number, UID: string, StateNum: number, ActionNum: number)
        local Bool: boolean?

        local Frame = OtherClientFrame
        local PastSnapShot = SnapShots[Frame]
        if not PastSnapShot then  print("no Past", Frame, CurrentFrame, "\n StateN ,ActionN: ", StateNum, ActionNum);  return end --* Safe check
        local PreviousPlayerState: buffer = PastSnapShot[UID]
        if not PreviousPlayerState then print("no PastPlayerstate", PastSnapShot, UID); return   end --* it should init a PastPlayerState
        local ReadU8 = buffer.readu8
        local PreviousStateNum = ReadU8(PreviousPlayerState, 2)
        local PreviousActionNum = ReadU8(PreviousPlayerState, 3)
        print(PreviousStateNum, PreviousActionNum, StateNum, ActionNum, "At Tick".. OtherClientFrame) --* keep for ez debugging
        
        --*this is for just in case the Client has already corrected itself at a later Frame i.e Another Prevention of Double Trigger
        local CurrentPlayerState: buffer = EntityCombatStates[UID]
        if not CurrentPlayerState then print("no CurrentPlayerState", EntityCombatStates, UID); return   end --* it should init a PastPlayerState
        local CurrentStateNum = ReadU8(CurrentPlayerState, 2)
        local CurrentActionNum = ReadU8(CurrentPlayerState, 3)
        
        if PreviousStateNum == StateNum and PreviousActionNum == ActionNum then  Bool = true end
        if CurrentStateNum == StateNum and CurrentActionNum == ActionNum then  Bool = true end
        print("C:",CurrentStateNum, CurrentActionNum) --* keep for ez debugging
        return Bool
    end     
    sy()
    RunService.Heartbeat:ConnectParallel(function(deltaTime: number)
		D += deltaTime
		if D >= Step then
			D -= Step
            CurrentFrame += 1
            PreviousFrame = CurrentFrame -10 -- storing upto 10 frames 333ms
            if CurrentFrame > 30 then CurrentFrame -= 30 end
			if PreviousFrame < 0 then PreviousFrame += 30 end
            if SnapShots[PreviousFrame]then  SnapShots[PreviousFrame] = nil end
            SnapShots[CurrentFrame] = EntityCombatStates
            InputHandler["CurrentFrame"] = CurrentFrame
        end
    end)
    CombatTickEvent.OnClientEvent:ConnectParallel(function(ServerBuffer:buffer)
        --* you have to recursively read and process it as it contains multiple buffers within it
        local Readstring = buffer.readstring
        local ReadU8 = buffer.readu8
        local Copy = buffer.copy
        -- local CurrentServerFrame = ReadU8(ServerBuffer, 0)
        local offset = 1
        local ServerBufferLen = buffer.len(ServerBuffer)
        for i = 1, ServerBufferLen do --80 UIDs max
                if offset >= ServerBufferLen then  return end
            local Length = ReadU8(ServerBuffer, offset)
            if Length == 0 then warn("no length"); return end
            local b: buffer = buffer.create(Length)
            Copy(b, 0, ServerBuffer, offset, Length)
            local UID: string = Readstring(b, 1, 1) 
            local StateNum: number = ReadU8(b, 2)
            local ActionNum: number = ReadU8(b, 3)        
            local ClientFrame = ReadU8(b, 4)
            offset += Length
            if ClientFrame <= 0 then warn("Frame 0: ", UID); continue end
            local Profile: CharacterHandler.Profile = CharacterHandler.GiveProfile(UID)
            if not Profile then warn("no profile");  continue end 
        
            local Check = CompareSnapShot(ClientFrame, UID, StateNum, ActionNum)
            if  Check == true then continue end --* Action already triggered in past frame

            local State: string = Encyclopedia[StateNum]
            local Action: string = Encyclopedia[ActionNum]
            ClientCombatMachine.ForceState(UID, State)
            ClientCombatMachine.TriggerAction(Profile.Avatar, nil, Action, CurrentFrame, b)--* give buffer cos extra args can be Used differently string or number etc
            EntityCombatStates[UID] = b
            return EntityCombatStates
        end
        return
    end)
    ClientActor:BindToMessageParallel("UpdateProfile", function(b: buffer)
        local UID:string = buffer.readstring(b, 1, 1)
        EntityCombatStates[UID] = b
    end)
    ClientActor:BindToMessageParallel("UpdWithFrame", function(b: buffer)
        local UID:string = buffer.readstring(b, 1, 1)
        local FrameToUpd = buffer.readu8(b, 4)
        local Snap = SnapShots[FrameToUpd]
        if not Snap then warn("no snap made yet Frame: ", FrameToUpd, CurrentFrame); return end
        EntityCombatStates[UID] = b
    end)
end)
HealthEvent.OnClientEvent:ConnectParallel(function(HEALTH_BUFFER:buffer)
    local Len = buffer.len(HEALTH_BUFFER)
    if Len <= 1 then return end
    local ReadString = buffer.readstring 
    local Readu16 = buffer.readu16
    local Needle = 0
    for i = 1, 60 do 
        if Needle+ 3 > Len then return end 
        local UID = ReadString(HEALTH_BUFFER, Needle, 1) 
        local Profile: CharacterHandler.Profile = CharacterHandler.GiveProfile(UID)
        if not Profile then print("no profile, Health Tick ");  return end --* sometimes during init process not to worry
        local NewHealth = Readu16(HEALTH_BUFFER, Needle + 1)
        CharacterHandler.SetHealth(Profile.Avatar, NewHealth)
        Gui_Handler.SetHealth(Profile.Avatar, NewHealth)
        Needle += 3
    end
end)
PostureEvent.OnClientEvent:ConnectParallel(function(POSTURE_BUFFER:buffer)
    local Len = buffer.len(POSTURE_BUFFER)
    if Len <= 1 then return end
    local ReadString = buffer.readstring 
    local Readu16 = buffer.readu16
    local Needle = 0
    for i = 1, 60 do 
        if Needle+ 3 > Len then return end 
        local UID = ReadString(POSTURE_BUFFER, Needle, 1) 
        local Profile: CharacterHandler.Profile = CharacterHandler.GiveProfile(UID)
        if not Profile then print("no profile, Posture Tick ");  return end --* sometimes during init process not to worry
        CharacterHandler.SetPosture(Profile.Avatar, Readu16(POSTURE_BUFFER, Needle + 1))
        Needle += 3
    end
end)
LoadStats.OnClientEvent:Connect(function(StatBuffer:buffer)  
    task.wait(1)
    CharacterHandler.InitStats(Character, StatBuffer)
    Gui_Handler.Init(player)
end)
NPCMakeEvent.OnClientEvent:ConnectParallel(function(NPCInfo_BUFFER:buffer)
    local UID:string = buffer.readstring(NPCInfo_BUFFER, 0, 1)
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
    local HumanoidStateType_Mod = NPCData.BodyType.."States"  --script.HumanoidStates
    local NPCFSM_Module:ModuleScript = NPCStateModsHandler[CFSM_Name]
    if not NPCFSM_Module then warn("Incorrect FSM Module: ", NPCFSM_Module, NPCStateModsHandler); return end
    task.synchronize()
    local NPCChar = CharModels[NPCType]:Clone()
    NPCChar.Name = UID 
    local Humanoid = HumanoidMachine:InitHumanoid(NPCChar, require(script[HumanoidStateType_Mod]))
    local Profile: CharacterHandler.Profile =  CharacterHandler.Spawn(NPCChar, Data, Humanoid, ClientActor)
    ClientCombatMachine:InitMPCMachine(NPCChar, require(NPCFSM_Module))
    ClientCombatMachine.TriggerAction(NPCChar, nil, "InitIdle", NPCData)
    Attribute_Handler.SetNPCStats(NPCChar, NPCData)
    local ForwardActor, DownwardActor , HBActor= ClientMessageAPI.InitClient(ClientActor)
    Profile.Forward  = ForwardActor
    Profile.Down = DownwardActor
    Profile.Detect = HBActor
    task.delay(1, function()
        ForwardActor:SendMessage("Init", UID)
        DownwardActor:SendMessage("Init", UID)
        HBActor:SendMessage("Init", UID)
    end)
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
ClientActor:BindToMessageParallel("SoftStun", function(DetectedUIDs, InfoT, Bool:boolean)  
    local WeaponName:string = InfoT["WeaponName"]
    for _ , UID in DetectedUIDs do  
        local Profile: CharacterHandler.Profile = CharacterHandler.GiveProfile(UID)
        if not Profile then warn("Invalid Profile", Character); return end 
        local ItemDataMod = ItemDataMod.GiveCopyData(WeaponName)
        if not ItemDataMod then warn("invalid WeaponName; ", WeaponName); return end
        ClientCombatMachine.TriggerAction(Profile.Avatar, nil, "SoftStun", InputHandler["CurrentFrame"], ItemDataMod, InfoT.AUID)
    end
    if not Bool then return end 
    local b:buffer = HB.BufferTableResults(DetectedUIDs, 1, 1)
    buffer.writeu8(b, 0, InputHandler["CurrentFrame"])
    task.synchronize()
    Events.Detect:FireServer(b, 1)
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
