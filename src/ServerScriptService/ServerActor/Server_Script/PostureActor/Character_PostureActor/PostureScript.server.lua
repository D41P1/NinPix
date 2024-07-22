local SSS = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared
local SScript = SSS.Server.ServerActor.Server_Script
local ItemDataMod = require(Shared.ItemDataMod)
local MessageAPI = require(SScript.MessageAPI)
local Actor = script.Parent
local Connections = {}

export type ItemDataMod = {
    Height: number,
    Width: number,
    Range: number,
    Damage: number,
    [string]: any
}
Actor:BindToMessageParallel("Init", function(UID:string, MaxPosture:number)  
    local Posture: number  = MaxPosture
    local WriteU16 = buffer.writeu16
    local Writestring = buffer.writestring
    local Regen: RBXScriptConnection?
    local A:any = Actor:BindToMessageParallel("Send", function(OldHealth:number)   
        if OldHealth == Posture then return end
        local b = buffer.create(3)
        Writestring(b, 0, UID, 1)
        WriteU16(b, 1, Posture)
        MessageAPI.SendToHealth("NewHealth", UID, b, Posture)
    end)
    local B:any = Actor:BindToMessageParallel("TakeDamage", function(ItemName: string, AttackerUID:string)
        local Info = ItemDataMod.GiveCopyData(ItemName)
        if not Info then warn("no Info: ", Info, UID, AttackerUID); return end
        Posture -= Info.Damage        
        if Posture <= 0 then 
            Posture = 0
            MessageAPI.SendToSSS("TriggerAction", UID, "GuardBroken", AttackerUID, ItemName)             
        end
    end)
    local C:any = Actor:BindToMessageParallel("StartRegen", function()
        if Regen then return end
        local D,S = 0, 1 - 1e-5
        task.synchronize()
        Regen = RunService.Heartbeat:ConnectParallel(function(a0: number)  
            D += a0
            if D >= S then 
                D -= S
                if Posture >= MaxPosture then Posture = MaxPosture; return  end
                Posture += MaxPosture/120
            end 
        end)
    end) 
    table.insert(Connections, A)
    table.insert(Connections, B)
    table.insert(Connections, C)
end)

