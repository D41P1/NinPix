local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Actor = script.Parent

Actor:BindToMessageParallel("Init", function()
    local D, S = 0, 0.5
    local Wu8 = buffer.writeu8
    local BCreate = buffer.create
    local len = buffer.len
    local BCopy = buffer.copy

    local LoopQ = BCreate(0)
    local RagdollEvent:UnreliableRemoteEvent = ReplicatedStorage.FromServer.RagdollEvent
    task.synchronize()
    RunService.Heartbeat:ConnectParallel(function(a0: number)  
        D += a0
        if D >= S then 
            D -= S
            if len(LoopQ) <= 0 then return end
            task.synchronize()
            RagdollEvent:FireAllClients(LoopQ)
            LoopQ = BCreate(0) --* reset the Q
        end
    end)
    local function Add_To_RagdollQ(Ragdollbuffer:buffer)
        local ru8 = buffer.readu8 
        local UID = ru8(Ragdollbuffer, 0)
        local Duration = ru8(Ragdollbuffer, 1)

        local OldLoopSize = len(LoopQ)
        local NewLoopQ = BCreate(OldLoopSize + 2)
        BCopy(NewLoopQ, 0, LoopQ, 0, OldLoopSize)
        Wu8(NewLoopQ, OldLoopSize, UID)
        Wu8(NewLoopQ, OldLoopSize +1, Duration)
        LoopQ = NewLoopQ
        warn("added Ragdoll")
    end
    Actor:BindToMessageParallel("Ragdoll", Add_To_RagdollQ)
end)