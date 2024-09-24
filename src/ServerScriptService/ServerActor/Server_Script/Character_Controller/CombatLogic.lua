local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService  = game:GetService("CollectionService")
local ServerScript = script.Parent.Parent
-- local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage.Shared
local Encyclopedia = require(Shared.Encyclopedia)
local PlayerBan_Manager = require(ServerScript.PlayerBan_Manager)
local SharedType = require(Shared.SharedType)
-- local RateLimiter = require(Shared.RateLimiter) -- TODO add rate limiters to Every CombatLogic index
local ItemDataMod = require(Shared.ItemDataMod)
local MessageAPI = require(ServerScript.MessageAPI)
local CombatController = require(ServerScript.CombatController)

local CombatLogic = {
    M1 = function(player: Player, FrameBuffer: buffer)
        if buffer.len(FrameBuffer) < 5 then PlayerBan_Manager:Ban(28, 4); return end
        local UID = player:GetAttribute("UID")
        CombatController.TriggerAction(UID, "M1", FrameBuffer) --* with Dir (rx, rz) so 9 bytes        
    end,
    M2 = function(player: Player)
        
    end,
    Block = function(player: Player, FrameBuffer: buffer)
        if buffer.len(FrameBuffer) < 5 then PlayerBan_Manager:Ban(28, 4); return end
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
type Q = { 
    Compare: number,
    Data: SharedType.ItemData,
    Unix: number,
    ItemName: string, 
    TypeHitId:number,
    ItemId:number
}

function CombatLogic.AddtoQ(CurrentItem: string, TypeOfHit_Id:number?)
    local Data: SharedType.ItemData = ItemDataMod.GiveCopyData(CurrentItem)
    if not Data then warn("incorrect ITem Name: ", CurrentItem);  return end
    local ItemId = Encyclopedia.GiveNumRef(CurrentItem)
    if not ItemId then warn("incorrect ItemName: ", ItemId); return end
    local T:Q = {
        ["Unix"] = DateTime.now().UnixTimestampMillis,
        ["Compare"] = Data.HBTime,
        ["Data"] = Data,
        ["ItemName"] = CurrentItem,
        ["ItemId"] = ItemId,
        ["TypeHitId"] = TypeOfHit_Id
    }
    table.insert(Queue, T)
end
function CombatLogic.RemoveFromQ()
    table.remove(Queue, 1)
end
--[[
CombatLogic["ApplyDamage"] = function(player: Player, DetectedUIDs: buffer) 
    if typeof(DetectedUIDs) ~= "buffer" then warn("spoof ApplyDamage"); return end
    local AttackerUID = player:GetAttribute("UID")
    local Ru8 = buffer.readu8
    local ClientFrame = Ru8(DetectedUIDs, 0)
    local Len: number = buffer.len(DetectedUIDs)
    warn("Queue", #Queue)
    local AttackersQ:Q = Queue[1]
    if #Queue == 0 then warn("Did not Queue H"); CombatController.TriggerAction(AttackerUID, "Release", ClientFrame); return end --*   
    table.remove(Queue, 1)
    if Len == 0 then PlayerBan_Manager:Ban(28, 3);  return end
    if Len < 2 or Len > 256 then CombatController.TriggerAction(AttackerUID, "Release", ClientFrame); return end  --* did not hit anything
    
    local Check = DateTime.now().UnixTimestampMillis - AttackersQ.Unix < AttackersQ.Compare -100
    if Check then PlayerBan_Manager:Ban(28, 3); warn("CA1"); return end --* they sent the check to early
    
    local Attackers_ItemData = AttackersQ.Data
    local AttackerCFV:CFrameValue = unpack(CollectionService:GetTagged(AttackerUID.."CFV"))
    if not AttackerCFV then warn("no CFV for player [combat logic] "); return end 
    
    -- local Needle: number = 1
    local TypeHit_Table = {
        [0] = "Pushback",
        [1] = "Knockback"
    }
    local BCreate = buffer.create
    local Wi16 = buffer.writei16
    local Wu16 = buffer.writeu16
    local Wu8 = buffer.writeu8
    
    --* starts at 2 cos 1 is being handled at the bottom, it is the Primary Target for the pushalong effect
    for i = 2, Len do
        if i + 1 > Len then break end 
        local UID = Ru8(DetectedUIDs, i, 1)
        UID = tostring(UID)
        local VictimCFV:CFrameValue = unpack(CollectionService:GetTagged(UID.."CFV"))
        if not VictimCFV then warn("no CFV"); continue end 
        local AttackerPos, VictimPos = AttackerCFV.Value.Position, VictimCFV.Value.Position
        if (AttackerPos- VictimPos).Magnitude >= Attackers_ItemData.Range then continue end --* HB ANTI_CHEAT
        MessageAPI.SendToSSS("TriggerAction", UID, "SoftStun", AttackersQ.ItemName, AttackerUID, ClientFrame)
        MessageAPI.SendToHealth("SendMessage", "InCombat", UID) --* regardless if they dodge block or parry they in combat now
        local TypeHit = TypeHit_Table[AttackersQ.TypeHitId] 
        if TypeHit then  
            local Direction = (VictimCFV.Value.Position - AttackerCFV.Value.Position).Unit
            local DirBuffer = BCreate(5)
            Direction = Vector3.new(Direction.X, 0, Direction.Z)
            Direction = math.atan2(Direction.Z, Direction.X)
            Direction = Direction*1000
            Wu8(DirBuffer, 0, UID)
            Wu16(DirBuffer, 1, AttackersQ.ItemId)
            Wi16(DirBuffer, 3, Direction)
            
            MessageAPI.SendToSSS(TypeHit, UID, AttackersQ.ItemName, DirBuffer)
        end
    end
    local PrimaryVictimUID = Ru8(DetectedUIDs, 1)
    local VictimCFV:CFrameValue = unpack(CollectionService:GetTagged(PrimaryVictimUID.."CFV"))
    if not VictimCFV then warn("no CFV"); return end 
    local AttackerPos, VictimPos = AttackerCFV.Value.Position, VictimCFV.Value.Position
    if (AttackerPos- VictimPos).Magnitude >= Attackers_ItemData.Range then return end --* ANTI_CHEAT
    MessageAPI.SendToSSS("TriggerAction", PrimaryVictimUID, "SoftStun", AttackersQ.ItemName, AttackerUID, ClientFrame)
    MessageAPI.SendToHealth("SendMessage", "InCombat", PrimaryVictimUID) --* regardless if they dodge block or parry they in combat now
    local TypeHit = TypeHit_Table[AttackersQ.TypeHitId] 
    if TypeHit then  
        local DirBuffer = BCreate(7)
        Wu8(DirBuffer, 0, tonumber(AttackerUID))
        Wu8(DirBuffer, 1, tonumber(PrimaryVictimUID))
        --// Wu8(DirBuffer, 2, Attackers_ItemData.KB)
        Wu8(DirBuffer, 2, AttackersQ.TypeHitId)
        
        local Direction = (VictimCFV.Value.Position - AttackerCFV.Value.Position).Unit
        Direction = Vector3.new(Direction.X, 0, Direction.Z)
        Direction = math.atan2(Direction.Z, Direction.X)
        Direction = Direction*1000
        Wi16(DirBuffer, 3, Direction)
        Wu16(DirBuffer, 5, AttackersQ.ItemId)
        task.defer(function()
            MessageAPI.SendToCombat("PushAlong", DirBuffer)
        end)
    end

    --[[--TODO 
    the PushAlong effect of both players 
    similar to Sekiro when you hit an enemy whether they block or get hit they move back and you move forward the same distance, same direction
    ]
    CombatController.TriggerAction(AttackerUID, "Release", ClientFrame)
end

]]
--TODO Typehit Table
do
    local TypeHit_Table = {
        --* reverse the 2 if you want quick tests with 
        [0] = "Pushback", 
        [1] = "Knockback"
    }
    CombatLogic["ApplyDamage"] = function(NPC_UID, DetectedUIDs: buffer, NeedleNumber: number, TypeOfHit_Id:number?, Attackers_ItemData) 
        local AttackerUID = NPC_UID
        local AttackerSM:SharedType.ClientStateMachine = CombatController[AttackerUID]
        if not AttackerSM then warn("no attacker Profile: ", CombatController, AttackerUID, typeof(AttackerUID) ); return end
        CombatController.TriggerAction(AttackerUID, "Release")
    
        local Attackers_ItemName = AttackerSM.CurrentItem
        local AttackerCFV:CFrameValue = unpack(CollectionService:GetTagged(AttackerUID.."CFV"))
        if not AttackerCFV then warn("no CFV for NPC"); return end     
        local AttackersItemID = Encyclopedia.GiveNumRef(Attackers_ItemName)
        if not AttackersItemID then warn("incorrect Name for id: ", Attackers_ItemName); return end
        local BCreate = buffer.create
        local Wi16 = buffer.writei16
        local Wu16 = buffer.writeu16
        local Wu8 = buffer.writeu8    
        local Len: number = buffer.len(DetectedUIDs)
        if Len < 1 then  print("TooShort", Len); return end 
    
        local Ru8 = buffer.readu8
        for i = 1, Len do
            if i + 1 > Len then break end 
            local UID = Ru8(DetectedUIDs, i, 1)
            UID = tostring(UID)
            local VictimCFV:CFrameValue = unpack(CollectionService:GetTagged(UID.."CFV"))
            if not VictimCFV then warn("no Victim CFV"); continue end 
            MessageAPI.SendToHealth("SendMessage", "InCombat", UID) --* regardless if they dodge block or parry they in combat now
            MessageAPI.SendToSSS("TriggerAction", UID, "SoftStun", Attackers_ItemName, AttackerUID)
            local TypeHit = TypeHit_Table[TypeOfHit_Id] 
            if TypeHit then  
                local Direction = (VictimCFV.Value.Position - AttackerCFV.Value.Position).Unit
                local DirBuffer = BCreate(5)
                Direction = Vector3.new(Direction.X, 0, Direction.Z)
                Direction = math.atan2(Direction.Z, Direction.X)
                Direction = Direction*1000
                Wu8(DirBuffer, 0, UID)
                Wu16(DirBuffer, 1, AttackersItemID)
                Wi16(DirBuffer, 3, Direction)
                MessageAPI.SendToSSS(TypeHit, UID, AttackerSM.CurrentItem, DirBuffer)
            end    
        end
        --* 0 start here cos theres no Client Frame
        local PrimaryVictimUID = Ru8(DetectedUIDs, 0)
        --// if PrimaryVictimUID == NPC_UID then warn("SAME UID WTHHTHT: ", NPC_UID, PrimaryVictimUID); return end
        local VictimCFV:CFrameValue = unpack(CollectionService:GetTagged(PrimaryVictimUID.."CFV"))
        if not VictimCFV then warn("no CFV"); return end 
        local AttackerPos, VictimPos = AttackerCFV.Value.Position, VictimCFV.Value.Position
        if (AttackerPos- VictimPos).Magnitude >= Attackers_ItemData.Range then return end --* ANTI_CHEAT
        PrimaryVictimUID = tostring(PrimaryVictimUID)
    
        MessageAPI.SendToSSS("TriggerAction", PrimaryVictimUID, "SoftStun", Attackers_ItemName, AttackerUID)
        MessageAPI.SendToHealth("SendMessage", "InCombat", PrimaryVictimUID) --* regardless if they dodge block or parry they in combat now
        local TypeHit = TypeHit_Table[TypeOfHit_Id] 
        if TypeHit then  
            
            local DirBuffer = BCreate(7)
            Wu8(DirBuffer, 0, tonumber(AttackerUID))
            Wu8(DirBuffer, 1, tonumber(PrimaryVictimUID))
            Wu8(DirBuffer, 2, TypeOfHit_Id)
            
            local Direction = (VictimCFV.Value.Position - AttackerCFV.Value.Position).Unit
            Direction = Vector3.new(Direction.X, 0, Direction.Z).Unit
            local Atan2Dir = math.atan2(Direction.Z, Direction.X)
            Atan2Dir = Atan2Dir*1000
    
            Wi16(DirBuffer, 3, Atan2Dir)
            local ItemId = Encyclopedia.GiveNumRef(Attackers_ItemName)
            if not ItemId then warn("Item Id add in encyclyopedia: ", Attackers_ItemName); return end
            Wu16(DirBuffer, 5, ItemId)
            task.defer(function()
                MessageAPI.SendToCombat("PushAlong", DirBuffer)    
            end)
        end    
    end
end

return CombatLogic