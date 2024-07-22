--!native
local CombatController = require(script.Parent.CombatController)
local MessageAPI = require(script.Parent.MessageAPI)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared

local SharedType = require(Shared.SharedType)

local NPCCombatUtil = {}
do  
    NPCCombatUtil["ApplyDamage"] = function(NPC_UID, DetectedUIDs: buffer, NeedleNumber: number) 
        local AttackerUID = NPC_UID
        local AttackerProfile:SharedType.ClientStateMachine = CombatController[AttackerUID]
        local Attackers_ItemName = AttackerProfile.CurrentItem

        local ServerFrame = buffer.readu8(DetectedUIDs, 0)
        local Len: number = buffer.len(DetectedUIDs)
        local ReadString = buffer.readstring
        local Needle: number = NeedleNumber 
        for i = 1, Len do
            if Needle + 1 > Len then break end 
            local UID = ReadString(DetectedUIDs, Needle, 1, 1)
            MessageAPI.SendToHealth("SendMessage", "InCombat", UID) --* regardless if they dodge block or parry they in combat now
            MessageAPI.SendToSSS("TriggerAction", UID, "SoftStun", Attackers_ItemName, AttackerUID, ServerFrame)
            Needle += 1
        end
        CombatController.TriggerAction(AttackerUID, "Release")
    end
end
return NPCCombatUtil