local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService  = game:GetService("CollectionService")
local ServerScript = script.Parent.Parent

local Shared = ReplicatedStorage.Shared
local Encyclopedia = require(Shared.Encyclopedia)
local SharedType = require(Shared.SharedType)
local RateLimiter = require(Shared.RateLimiter) -- TODO add rate limiters to Every CombatLogic index
local ItemDataMod = require(Shared.ItemDataMod)
local MessageAPI = require(ServerScript.MessageAPI)
local CombatController = require(ServerScript.CombatController)

local CombatLogic = {
    M1 = function(player: Player, FrameBuffer: buffer)
        local UID = player:GetAttribute("UID")
        CombatController.TriggerAction(UID, "M1", FrameBuffer) --* with Dir (rx, rz) so 9 bytes        
    end,
    M2 = function(player: Player)
    end,
    Block = function(player: Player, FrameBuffer: buffer)
        local UID = player:GetAttribute("UID")
        CombatController.TriggerAction(UID, "Block", FrameBuffer)        
    end,
    StopBlock = function(player, FrameBuffer:buffer)
        local UID = player:GetAttribute("UID")
        CombatController.TriggerAction(UID, "StopBlock", FrameBuffer)        
    end,
    Skill = function(player: Player, FrameBuffer:buffer)
    end,
    Tool = function(player: Player, FrameBuffer: buffer)
        local UID = player:GetAttribute("UID")
        CombatController.TriggerAction(UID, "ToolHandle", FrameBuffer)
    end,
    Run = function(player: Player, FrameBuffer: buffer)
        local WS = player:GetAttribute("BaseWalkSpeed")
        local UID = player:GetAttribute("UID")
        CombatController.TriggerAction(UID, "Run", FrameBuffer, WS)
    end,
    StopRun = function(player: Player, FrameBuffer: buffer)
        local WS = player:GetAttribute("BaseWalkSpeed")
        local UID = player:GetAttribute("UID")
        CombatController.TriggerAction(UID, "StopRun", FrameBuffer, WS)
    end,    
}
local Queue = {}
function CombatLogic.AddtoQ(CurrentItem: string)
    local Data: ItemDataMod.ItemDataMod = ItemDataMod.GiveCopyData(CurrentItem)
    if not Data then warn("incorrect ITem Name: ", CurrentItem);  return end
    local T = {
        ["Unix"] = DateTime.now().UnixTimestampMillis,
        ["Compare"] = Data.HBTime,
        ["Data"] = Data
    }
    table.insert(Queue, T)
end

CombatLogic["ApplyDamage"] = function(player: Player, DetectedUIDs: buffer, NeedleNumber: number) 
    if typeof(DetectedUIDs) ~= "buffer" then warn("spoof ApplyDamage"); return end
    if #Queue == 0 then task.synchronize(); player:Kick("Did not Queue H"); return end --TODO add Mod that Controls Players:BanAsync 
    local T = Queue[1]
    local Check = DateTime.now().UnixTimestampMillis - T.Unix < T.Compare
    if  Check then return end
    local AttackerUID = player:GetAttribute("UID")
    local Len: number = buffer.len(DetectedUIDs)
    if Len <= 1 then     CombatController.TriggerAction(AttackerUID, "Release"); return end 
    local AttackerProfile:SharedType.ClientStateMachine = CombatController[AttackerUID]
    local Attackers_ItemName = AttackerProfile.CurrentItem
    local Attackers_ItemData = ItemDataMod.GiveCopyData(Attackers_ItemName)
    local AttackerCFV:CFrameValue = unpack(CollectionService:GetTagged(AttackerUID))
    if not AttackerCFV then warn("no CFV for player [CombatLogic ApplyDam]"); return end 
    
    table.remove(Queue, 1)

    local ClientFrame = buffer.readu8(DetectedUIDs, 0)
    local ReadString = buffer.readstring
    local Needle: number = NeedleNumber 
    for i = 1, Len do
        if Needle + 1 > Len then break end 
        local UID = ReadString(DetectedUIDs, Needle, 1, 1)
        local VictimCFV:CFrameValue = unpack(CollectionService:GetTagged(UID.."CFV"))
        if not VictimCFV then warn("no CFV"); Needle += 1; continue end 
        local AttackerPos, VictimPos = AttackerCFV.Value.Position, VictimCFV.Value.Position
        if (AttackerPos- VictimPos).Magnitude >= Attackers_ItemData.Range then Needle += 1; continue end --* ANTI_CHEAT
        MessageAPI.SendToHealth("SendMessage", "InCombat", UID) --* regardless if they dodge block or parry they in combat now
        MessageAPI.SendToSSS("TriggerAction", UID, "SoftStun", Attackers_ItemName, AttackerUID, ClientFrame)
        Needle += 1
    end
    CombatController.TriggerAction(AttackerUID, "Release", ClientFrame)
end
return CombatLogic