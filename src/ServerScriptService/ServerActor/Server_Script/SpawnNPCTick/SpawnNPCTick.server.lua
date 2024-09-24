local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared
local Encyclopedia = require(Shared.Encyclopedia)
task.wait(7.5)
do 
    local List_Of_NPC = {
        -- "Dummy",
        -- "HitDummy"
        "ShadoMercenary"
    }
    local R = math.random
    --* The S must be 10 cannot be less than 4 or else NPCs will not init properly
    local D, S = 0, 0.1 
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