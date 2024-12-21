--!native
-- local SSS = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local MessageAPI = require(script.Parent.Parent.MessageAPI)
local FromServer = ReplicatedStorage.FromServer
local LoadGameState = FromServer.GameState
local CombatTickEvent = FromServer.CombatTick
-- local Shared = ReplicatedStorage.Shared
local CombatActor = script.Parent
-- local ServerScript = SSS.Server.ServerActor.Server_Script
-- local MessageAPI = require(ServerScript.MessageAPI)
-- local SharedType = require(Shared.SharedType)
--[[ --! Info For buffering CombatState
Length
UID
State
Action
CurrentFrame
--* 5 bytes
--* CCT =(Client combat tick)

Rule {
    when triggering an action from OutSide from this module then u Must update the CCT in that action
    For example ToolHandle Action
    Or Block Action in WeaponOut or Parried
}
]]
type UID = number
do 
    -- local sy = task.synchronize
    -- local Ru8 = buffer.readu8    
    -- local Wu8 = buffer.writeu8
    -- local Ri16 = buffer.readi16
    -- local Ru16 = buffer.readu16
    -- local Wi16 = buffer.writei16
    -- local Wu16 = buffer.writeu16
    -- local Create = buffer.create
    -- local Len: (buffer) -> number = buffer.len
    -- local Copy = buffer.copy
            
    -- local D, Step = 0, 1/30
    -- local CurrentFrame = 1
    -- --// local PreviousFrame = 0
    -- local PreviosProfile: { [number]: buffer } = {}
    -- local Profiles: { [number]: buffer } = {} -- holds
    --[[
    local SnapShots = {
        --[[
            [1] (FrameCount) = {
                buffer = UID, State, Action,   Skill?, ...
            }
        ]
    }
            --// PreviousFrame = CurrentFrame -10 

            --// if PreviousFrame < 0 then PreviousFrame += 30 end
            --// if SnapShots[PreviousFrame]then  SnapShots[PreviousFrame] = nil end

    ]]
    --! no point saving snapshots on server rollback will only be done by clients
    -- local CombatTickFunc = function(deltaTime: number)          
	-- 	D += deltaTime
	-- 	if D >= Step then
	-- 		D -= Step
    --         CurrentFrame += 1
    --         if CurrentFrame > 30 then CurrentFrame -= 30 end
    --         local ServerBuffer = Create(1)
    --         Wu8(ServerBuffer, 0, CurrentFrame)
    --         for UID, PlayerStateBuffer: buffer in Profiles do
    --             local State: number, Action: number = Ru8(PlayerStateBuffer, 2), Ru8(PlayerStateBuffer, 3) --* 1 offset is UID
    --             local PreviousB: buffer = PreviosProfile[UID]
    --             if not PreviousB then PreviosProfile[UID] = PlayerStateBuffer; continue end --* init the previous Version of the Profile
    --             local PreviousState: number, PreviousAction: number = Ru8(PreviousB, 2), Ru8(PreviousB, 3)       
    --             if State == PreviousState and Action == PreviousAction then continue end --* if state AND action same
    --             local ServerLen: number = Len(ServerBuffer) 
    --             local blen: number = Len(PlayerStateBuffer) 
    --             local NewServerBuff: buffer = Create(blen + ServerLen)
    --             Copy(NewServerBuff, 0, ServerBuffer, 0, ServerLen)
    --             Copy(NewServerBuff, ServerLen, PlayerStateBuffer, 0, blen)
    --             ServerBuffer = NewServerBuff
    --             PreviosProfile[UID] = PlayerStateBuffer
    --         end    
    --         --// SnapShots[CurrentFrame] = Profiles
    --         if Len(ServerBuffer) <= 1 then return end --* no point firing if no changes            
    --         sy()
    --         CombatTickEvent:FireAllClients(ServerBuffer)
    --     end
    -- end

    -- task.delay(6.5, function()
        -- RunService.Heartbeat:ConnectParallel(CombatTickFunc)
    -- end)
    -- Players.PlayerAdded:ConnectParallel(function(player: Player)   
    --     task.delay(8, function()
    --         local UID = player:GetAttribute("UID")
    --         if not UID then task.synchronize(); player:Kick("Roblox data store Probably had an error :C"); return end
    --         local StateBuffer = buffer.create(5)
    --         local Writeu8 = buffer.writeu8
    --         local State = 1 --*Blocking,Idle,WeaponOut , ... etc
    --         local Action = 1 --*Blocked, Parried, Block, M1, ... etc
    --         UID = tonumber(UID)
    --         Writeu8(StateBuffer, 0, 5)
    --         Writeu8(StateBuffer, 1, UID)
    --         Writeu8(StateBuffer, 2, State)
    --         Writeu8(StateBuffer, 3, Action)
    --         CombatActor:SendMessage("UpdWithFrame", 4, StateBuffer)
            
    --         local LoadGameState_Buffer = Create(9)
    --         local ServerUnix = DateTime.now().UnixTimestampMillis
    --         Wu8(LoadGameState_Buffer, 0, CurrentFrame)
    --         buffer.writef64(LoadGameState_Buffer, 1, ServerUnix)
    --         sy()
    --         LoadGameState:FireClient(player, LoadGameState_Buffer)
    --     end)
    -- end)
    -- Players.PlayerRemoving:ConnectParallel(function(player: Player)   
    --     local UID = player:GetAttribute("UID")
    --     if not UID then warn("no UID"); return end
    --     Profiles[UID] = nil
    --     PreviosProfile[UID] = nil
    -- end)
    --[[
    ]]
    -- local function AllowDoubleTrigger(UID, b)
    --     local OldB = PreviosProfile[UID]
    --     if not OldB then return end
    --     local State, Action = Ru8(b, 2), Ru8(b, 3)
    --     local PreviousState, PreviousAction = Ru8(OldB, 2), Ru8(OldB, 3)
    --     if State == PreviousState and Action == PreviousAction then 
    --         Wu8(OldB, 2, 1)
    --         Wu8(OldB, 3, 1)
    --         PreviosProfile[UID] = OldB
    --         --* this is so if a double trigger has happened on the server
    --         --* for example they are given multiple SoftStuns this is to let that happen
    --     end
    -- end

    -- CombatActor:BindToMessageParallel("UpdateProfile", function(b: buffer)
    --     local UID= Ru8(b, 1)
    --     Profiles[UID] = b
    --     AllowDoubleTrigger(UID, b)
    -- end)
    -- CombatActor:BindToMessageParallel("UpdWithFrame", function(offset:number, b: buffer) -- Update Profile Curret Frame
    --     --*assume offset given is empty (unwritten) for the Frame  
    --     Wu8(b, offset, CurrentFrame)
    --     local UID= Ru8(b, 1)
    --     Profiles[UID] = b
    --     AllowDoubleTrigger(UID, b)
    -- end)
    
    -- CombatActor:BindToMessageParallel("PushAlong", function(DirBuffer:buffer)   --TODO needs to be redone for the New Physics System
    --     --TODO check if possible to do the Pushback/Knockback
    --     local AttackerUID = Ru8(DirBuffer, 0)
    --     local PrimaryTargetUID = Ru8(DirBuffer, 1)
    --     local PrimaryProfile = Profiles[PrimaryTargetUID]
    --     if not PrimaryProfile then warn("no Combat Profile CombatScript: ", PrimaryTargetUID, Profiles); return end
    --     local PrimaryState = Ru8(PrimaryProfile, 2)
    --     local PrimaryAction = Ru8(PrimaryProfile, 3)
    --     local TypeHit= Ru8(DirBuffer, 2)        
    --     local function RecreateBuffer(UID:number, OldDirBuffer:buffer)
    --         local NewDirBuffer = Create(5)
    --         local Item_Id = Ru16(OldDirBuffer, 5)
    --         local Atan2Dir = Ri16(OldDirBuffer, 3)
    --         Wu8(NewDirBuffer, 0, UID)
    --         Wu16(NewDirBuffer, 1, Item_Id)
    --         Wi16(NewDirBuffer, 3, Atan2Dir)
    --         return NewDirBuffer
    --     end        
    --     PrimaryTargetUID = tostring(PrimaryTargetUID)
    --     AttackerUID = tostring(AttackerUID)
    --     local PrimaryBuffer = RecreateBuffer(PrimaryTargetUID, DirBuffer)
    --     if PrimaryState == 3 then 
    --         --* blocked
    --         if PrimaryAction == 16 then 
    --             --*Parried 
    --             MessageAPI.SendToSSS("Pushback", PrimaryTargetUID, nil, PrimaryBuffer, true)
    --             return    
    --         end 
    --         local AttackerBuffer = RecreateBuffer(AttackerUID, DirBuffer) 
    --         MessageAPI.SendToSSS("Pushback", AttackerUID, nil, AttackerBuffer)
    --         MessageAPI.SendToSSS("Pushback", PrimaryTargetUID, nil, PrimaryBuffer, true)
    --     else
    --         if TypeHit == 0 then --* flip between 1 and 0 to quick test Knockback with HitDummy,  in PROD it must be 0
    --             local AttackerBuffer = RecreateBuffer(AttackerUID, DirBuffer) 
    --             MessageAPI.SendToSSS("Pushback", AttackerUID, nil, AttackerBuffer)
    --             MessageAPI.SendToSSS("Pushback", PrimaryTargetUID, nil, PrimaryBuffer, true)
    --         else
    --             MessageAPI.SendToSSS("Knockback", PrimaryTargetUID, nil, PrimaryBuffer)        
    --         end
    --     end
    --     --[[ --*Possible scenarious:
    --     Primary blocks then PushALong Both
    --     Primary parries then pushback Primary
    --     Primary Hit then {
    --         PushALong Both if TypeHit is 0 (Pushback)
    --         Primary Knockback if TypeHit is 1 (Knockback)
    --         } 
    --     ]] 
    -- end)

end


