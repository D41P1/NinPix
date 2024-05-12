--!native
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared
local HitBox = require(Shared.Hitbox)
local Server_Script = game:GetService("ServerScriptService").Server.ServerActor.Server_Script
local MessageAPI = require(Server_Script.MessageAPI)
local RunService = game:GetService("RunService")
local Actor = script.Parent

local Down: RBXScriptConnection
local Character: Model
local Direction 
local WalkSpeed
local PreviousCF:CFrame
local UID: string
Actor:BindToMessageParallel("Init", function(Data)  
    WalkSpeed = Data.WS
    PreviousCF = Data.CurrentCF * CFrame.new(0, 2.7, 0)
    UID = Data.UID
end)

Actor:BindToMessageParallel("StartForward", function(CF:CFrame)      
    local WS = WalkSpeed
    local PreviousPos = PreviousCF.Position
    local Pos:Vector3 = CF.Position
    local NewDir:Vector3 = (Pos - PreviousPos).Unit 
    local NewPos:Vector3 = PreviousPos + NewDir * (WS *0.08)
    local Origin:Vector3 = PreviousPos; local End = Origin + (NewDir * 2)
    
    local DownRR = HitBox:Raycasting(NewPos, NewPos + Vector3.new(0, -1, 0), 2.8)
    if not DownRR then return end

    local RR = HitBox:Raycasting(Origin, End, WS*0.24)
    local CFLook = CFrame.new(NewPos, Pos)
    if RR then 
        -- TODO send a message to SSS -- maybe characterActor ????
        local LookPos = Pos + NewDir*10 
        local Look = CFrame.new(RR.Position, LookPos) 
        CFLook = Look * CFrame.new(0, 0, 1.5)
        PreviousCF = CFLook     
    end
    -- Send message 2 to SSS only
    Direction = NewDir
    PreviousCF = CFLook     
    MessageAPI.SendToSSS("ChangeProfile", UID, "CurrentCF", CFLook)
end)
Actor:BindToMessageParallel("StartDownward", function(NewDirection:Vector3)  
    local Body = Character.PrimaryPart
    local TotDelta, Step = 0, 0.1
    Down = RunService.Heartbeat:ConnectParallel(function(a0: number)  
        local NewDelta = TotDelta
        NewDelta += a0
        if NewDelta >= Step then
            NewDelta = 0
            local Origin = Body.Position
            local End = Origin + (Direction * 2)
            local RR:RaycastResult? = HitBox:Raycasting(Origin, End, 2)
            if not RR then
                Down:Disconnect()
                -- MessageAPI.SendToClientActor("DownNotHit")
            end
        end
        TotDelta = NewDelta
    end)
end)
Actor:BindToMessageParallel("StopForward", function()
    Direction = Vector3.zero
    return Direction
end)
Actor:BindToMessageParallel("StopDownward", function()   if Down then Down:Disconnect() end end)




