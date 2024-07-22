local SSS = game:GetService("ServerScriptService")
local ReplicatedStorage= game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SScript = SSS.Server.ServerActor.Server_Script
local Shared = ReplicatedStorage.Shared
local MessageAPI = require(SScript.MessageAPI)
local Actor = script.Parent

local ItemDataMod = require(Shared.ItemDataMod)

local Connections = {}
export type ItemDataMod = {
    Height: number,
    Width: number,
    Range: number,
    Damage: number,
    [string]: any
}
Actor:BindToMessageParallel("Init", function(UID:string, MaxHealth:number)  
    local Health: number  = MaxHealth
    local WriteU16 = buffer.writeu16
    local Writestring = buffer.writestring
    local Regen: RBXScriptConnection?
    local CombatCheck: RBXScriptConnection?
    local InCombat:boolean?
    local CombatTag: number = DateTime.now().UnixTimestampMillis
    local PlayerTags = {}
    local A:any = Actor:BindToMessageParallel("Send", function(OldHealth:number)   
        if OldHealth == Health then return end
        local b = buffer.create(3)
        Writestring(b, 0, UID, 1)
        WriteU16(b, 1, Health)
        MessageAPI.SendToHealth("NewHealth", UID, b, Health)
    end)
    local B:any = Actor:BindToMessageParallel("TakeDamage", function(ItemName, AttackerUID: string)
        local Info = ItemDataMod[ItemName]
        if not Info then warn("invalid ItemName: ", ItemName); return end 
        Health -= Info.Damage
        if Health <= 0 then Health = 0 end
        CombatTag = DateTime.now().UnixTimestampMillis --* refresh CombatTag
        local TotalDamage= PlayerTags[AttackerUID]
        if not TotalDamage then  PlayerTags[AttackerUID] = Info.Damage;   return  end
        PlayerTags[AttackerUID] += Info.Damage
        --* manually set Combat tag do not set it every time the take damage cos for more Control 
    end)
    local C:any = Actor:BindToMessageParallel("StartRegen", function()
        if Regen then return end
        if InCombat then print("in combat won't regen");  return end 
        local D,S = 0, 1 - 1e-5
        task.synchronize()
        Regen = RunService.Heartbeat:ConnectParallel(function(a0: number)  
            D += a0
            if D >= S then 
                D -= S
                if Health >= MaxHealth then Health = MaxHealth; return  end
                Health += MaxHealth/120
                print("regenerated", Health)
            end 
        end)
    end)
    local D:any =Actor:BindToMessageParallel("InCombat", function() 
        if Regen then task.synchronize(); Regen:Disconnect();  Regen = nil; print("Regen disconnect UID: ", UID) end   
        InCombat = true
        CombatTag = DateTime.now().UnixTimestampMillis  
    end)
    local E:any = Actor:BindToMessageParallel("OutCombat", function() 
        if InCombat then InCombat =nil  end
        if CombatCheck then 
            task.synchronize();
            CombatCheck:Disconnect();  CombatCheck = nil    
            Actor:SendMessage("StartRegen")
        end
    end) 
    local F:any = Actor:BindToMessageParallel("CombatCheck", function()
        local D,S = 0, 5
        task.synchronize()
        CombatCheck = RunService.Heartbeat:ConnectParallel(function(a0: number)  
            D += a0
            if D >= S then 
                D -= S
                if DateTime.now().UnixTimestampMillis - CombatTag > 15_000 then -- 60_0000 
                    print("Out ofCombat")
                    Actor:SendMessage("OutCombat")
                    return
                end
                print("Checking Ccombat")
            end    
        end)
    end) 
    table.insert(Connections, A)
    table.insert(Connections, B)
    table.insert(Connections, C)
    table.insert(Connections, D)
    table.insert(Connections, E)
    table.insert(Connections, F)
end)

