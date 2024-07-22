-- local SSS = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
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
type UID = string
do 
    local sy = task.synchronize
    local D, Step = 0, 1/30
    local CurrentFrame = 1
    --// local PreviousFrame = 0
    local PreviosProfile: { [UID]: buffer } = {}
    local Profiles: { [UID]: buffer } = {} -- holds
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
    local CombatTickFunc = function(deltaTime: number)          
		D += deltaTime
		if D >= Step then
			D -= Step
            CurrentFrame += 1
            if CurrentFrame > 30 then CurrentFrame -= 30 end
            local Create = buffer.create
            local ServerBuffer = Create(1)
            local Len: (buffer) -> number = buffer.len
            local ReadU8 = buffer.readu8
            local Copy = buffer.copy
            buffer.writeu8(ServerBuffer, 0, CurrentFrame)
            for UID: string, b: buffer in Profiles do
                local State: number, Action: number = ReadU8(b, 2), ReadU8(b, 3) --* 1 offset is UID
                local PreviousB: buffer = PreviosProfile[UID]
                if not PreviousB then PreviosProfile[UID] = b; continue end --* init the previous Version of the Profile
                local PreviousState: number, PreviousAction: number = ReadU8(PreviousB, 2), ReadU8(PreviousB, 3)       
                if State == PreviousState and Action == PreviousAction then continue end --* if state AND action same

                local ServerLen: number = Len(ServerBuffer) 
                local blen: number = Len(b) 
                local NewServerBuff: buffer = Create(blen + ServerLen)
                Copy(NewServerBuff, 0, ServerBuffer, 0, ServerLen)
                Copy(NewServerBuff, ServerLen, b, 0, blen)
                ServerBuffer = NewServerBuff
                PreviosProfile[UID] = b
            end
            --// SnapShots[CurrentFrame] = Profiles
            if Len(ServerBuffer) <= 1 then return end --* no point firing if no changes            
            sy()
            CombatTickEvent:FireAllClients(ServerBuffer)
        end
    end
    task.delay(6.5, function()
        RunService.Heartbeat:ConnectParallel(CombatTickFunc)
    end)
    Players.PlayerAdded:ConnectParallel(function(player: Player)   
        task.delay(8, function()
            local b = buffer.create(9)
            local ServerUnix = DateTime.now().UnixTimestampMillis
            buffer.writeu8(b, 0, CurrentFrame)
            buffer.writef64(b, 1, ServerUnix)
            sy()
            LoadGameState:FireClient(player, b)
        end)
    end)
    Players.PlayerRemoving:ConnectParallel(function(player: Player)   
        local UID = player:GetAttribute("UID")
        Profiles[UID] = nil
        PreviosProfile[UID] = nil
    end)
    --[[
    ]]
    CombatActor:BindToMessageParallel("UpdateProfile", function(b: buffer)
        local UID:string = buffer.readstring(b, 1, 1)
        Profiles[UID] = b
    end)
    CombatActor:BindToMessageParallel("UpdWithFrame", function(offset:number, b: buffer) -- Update Profile Curret Frame
        --*assume offset given is empty (unwritten) for the Frame  
        buffer.writeu8(b, offset, CurrentFrame)
        local UID:string = buffer.readstring(b, 1, 1)
        Profiles[UID] = b
    end)
end


