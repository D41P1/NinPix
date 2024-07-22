--*Posture Actor
local SScript = script.Parent.Parent
local Actor = script.Parent
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Shared = ReplicatedStorage.Shared
local SharedType = require(Shared.SharedType)
local FromServer = ReplicatedStorage.FromServer
local PostureEvent = FromServer.PostureEvent
local RunTimeFolder = Actor.PostureRunTimeActors

type ActorTable = {
    Actor: Actor,
    Posture: number,
    Script: Script 
}
local Actors = {}
local LoopQ = {}
Actor:BindToMessageParallel("Init", function()
    local D, S = 0, 3
    task.synchronize()
    RunService.Heartbeat:ConnectParallel(function(a0: number)  
        D += a0
        if D >= S then
            D -= S
            for _, HealthActors:Actor in RunTimeFolder:GetChildren() do 
                local UID = HealthActors.Name
                local Prof: ActorTable = Actors[UID]
                if not Prof then warn("no Prof: ", UID); return end
                HealthActors:SendMessage("Send", Prof.Posture) --Send this
            end 
            local SendBuffer = buffer.create(0)
            local Len = buffer.len
            local Copy = buffer.copy
            local CloneLoop = table.clone(LoopQ)
            for Index, T in CloneLoop do
                local PostureBuffer: buffer = T.PostureBuffer
                local LenSend = Len(SendBuffer)
                local LenPosture = Len(PostureBuffer)
                local NewBuffer = buffer.create(LenSend + LenPosture)
                Copy(NewBuffer, 0, SendBuffer, 0, LenSend)
                Copy(NewBuffer, LenSend, PostureBuffer, 0, LenPosture)
                table.remove(LoopQ, Index)
                SendBuffer = NewBuffer
            end
            if Len(SendBuffer) <= 1 then return end -- means nothing in the LoopQ
            task.synchronize()
            PostureEvent:FireAllClients(SendBuffer)
        end
    end)        
end)
Actor:BindToMessageParallel("NewPosture", function(UID:string, b:buffer, Posture: number) -- they reply with this
    local Prof:ActorTable = Actors[UID]
    if not Prof then warn("incorrect UID For Posture: ", UID); return end 
    Prof.Posture = Posture
    local T = {
        ["UID"] = UID,
        ["PostureBuffer"] = b
    }
    table.insert(LoopQ, T)
end)
Actor:BindToMessage("Create", function(UID:string, Posture: number)
    local CharPostureActor = Actor.Character_PostureActor:Clone()
    local PScript = CharPostureActor.PostureScript
    CharPostureActor.Name = UID
    CharPostureActor.Parent = RunTimeFolder
    PScript.Enabled = true
    local T  = {
        ["Posture"] = Posture,
        ["Actor"] = CharPostureActor,
        ["Script"] = PScript 
    }
    Actors[UID] = T
    local b = buffer.create(2)
    buffer.writeu16(b, 0, Posture)
    task.delay(1, function()
        CharPostureActor:SendMessage("Init", UID, Posture)
        task.wait(1)
        CharPostureActor:SendMessage("StartRegen", UID, Posture)
    end)
    PostureEvent:FireAllClients(b)
end)
Actor:BindToMessageParallel("SendMessage", function(Topic, UID:string, ...)  
    local Prof:ActorTable = Actors[UID]
    if not Prof then warn("No Prof For: ", UID); return end
    Prof.Actor:SendMessage(Topic, ...)
end)
Actor:BindToMessageParallel("Cleanup", function(UID:string)  
    local Prof:ActorTable = Actors[UID]
    if not Prof then warn("No Prof For: ", UID); return end
    Actors[UID] = nil
    task.synchronize()
    Prof.Actor:Destroy()
    print("cleaned")
end)
