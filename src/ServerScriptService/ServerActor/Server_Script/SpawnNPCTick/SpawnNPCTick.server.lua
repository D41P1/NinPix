local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared
local Encyclopedia = require(Shared.Encyclopedia)
do 
    local List_Of_NPC = {
        -- "Dummy",
        "HitDummy"
    }
    local R = math.random
    local D, S = 0, 10
    local SSSActor = script.Parent.Parent.Parent
    RunService.Heartbeat:ConnectParallel(function(a0: number)  
        D+= a0
        if D >= S then 
            D-= S
            local Name = List_Of_NPC[R(1, #List_Of_NPC)]
            local NPCId = Encyclopedia.GiveNumRef(Name)
            SSSActor:SendMessage("SpawnNPC", Name, Name, Name, NPCId)
        end
    end)
end