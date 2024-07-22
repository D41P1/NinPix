--*Health Actor
local SScript = script.Parent.Parent
local Actor = script.Parent
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Shared = ReplicatedStorage.Shared
local SharedType = require(Shared.SharedType)
local FromServer = ReplicatedStorage.FromServer
local HealthEvent = FromServer.HealthEvent
local RunTimeFolder = Actor.Health_RunTimeActors

type ActorTable = {
    Actor: Actor,
    Health: number,
    Script: Script 
}
local Actors = {}
local LoopQ = {}
Actor:BindToMessageParallel("Init", function()
    local D, S = 0, 1
    task.synchronize()
    RunService.Heartbeat:ConnectParallel(function(a0: number)  
        D += a0
        if D >= S then
            D -= S
            for _, HealthActors:Actor in RunTimeFolder:GetChildren() do 
                local UID = HealthActors.Name
                local Prof: ActorTable = Actors[UID]
                if not Prof then warn("no Prof: ", UID); return end
                HealthActors:SendMessage("Send", Prof.Health) --Send this
            end 
            local SendBuffer = buffer.create(0)
            local Len = buffer.len
            local Copy = buffer.copy
            local CloneLoop = table.clone(LoopQ)
            for Index, T in CloneLoop do
                local HealthBuffer: buffer = T.HealthBuffer
                local LenSend = Len(SendBuffer)
                local LenHealth = Len(HealthBuffer)
                local NewBuffer = buffer.create(LenSend + LenHealth)
                Copy(NewBuffer, 0, SendBuffer, 0, LenSend)
                Copy(NewBuffer, LenSend, HealthBuffer, 0, LenHealth)
                table.remove(LoopQ, Index)
                SendBuffer = NewBuffer
            end
            if Len(SendBuffer) <= 1 then return end -- means nothing in the LoopQ
            task.synchronize()
            HealthEvent:FireAllClients(SendBuffer)
        end
    end)        
end)
Actor:BindToMessageParallel("NewHealth", function(UID:string, b:buffer, Health: number) -- they reply with this
    local Prof:ActorTable = Actors[UID]
    if not Prof then warn("incorrect UID For Health: ", UID); return end 
    Prof.Health = Health
    local T = {
        ["UID"] = UID,
        ["HealthBuffer"] = b
    }
    table.insert(LoopQ, T)
end)
Actor:BindToMessage("Create", function(UID:string, Health: number)
    local CharHealthActor = Actor.CharacterHealthActor:Clone()
    local HScript = CharHealthActor.HealthScript
    CharHealthActor.Name = UID
    CharHealthActor.Parent = RunTimeFolder
    HScript.Enabled = true
    local T  = {
        ["Health"] = Health,
        ["Actor"] = CharHealthActor,
        ["Script"] = HScript 
    }
    Actors[UID] = T
    local b = buffer.create(2)
    buffer.writeu16(b, 0, Health)
    task.delay(1, function()
        CharHealthActor:SendMessage("Init", UID, Health)
        task.wait(1)
        CharHealthActor:SendMessage("StartRegen", UID, Health)
    end)
    HealthEvent:FireAllClients(b)
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
