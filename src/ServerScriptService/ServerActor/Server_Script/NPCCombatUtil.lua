--!native
local CombatController = require(script.Parent.CombatController)
local MessageAPI = require(script.Parent.MessageAPI)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared
local CollectionService = game:GetService("CollectionService")

local State_Dictionary = require(Shared.State_Dictionary)
local SharedType = require(Shared.SharedType)

local NPCCombatUtil = {}
do  
    local TypeHit_Table = {
        --* reverse the 2 if you want quick tests with 
        [0] = "Pushback", 
        [1] = "Knockback"
    }
    NPCCombatUtil["ApplyDamage"] = function(NPC_UID, DetectedUIDs: buffer, NeedleNumber: number, TypeOfHit_Id:number?, Attackers_ItemData) 
        local AttackerUID = NPC_UID
        local AttackerSM:SharedType.ClientStateMachine = CombatController[AttackerUID]
        if not AttackerSM then warn("no attacker Profile: ", CombatController, AttackerUID, typeof(AttackerUID) ); return end
        CombatController.TriggerAction(AttackerUID, "Release")

        local Attackers_ItemName = AttackerSM.CurrentItem
        local AttackerCFV:CFrameValue = unpack(CollectionService:GetTagged(AttackerUID.."CFV"))
        if not AttackerCFV then warn("no CFV for NPC"); return end
        local AttackersItemID = State_Dictionary.GiveNumRef(Attackers_ItemName)
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
            local ItemId = State_Dictionary.GiveNumRef(Attackers_ItemName)
            Wu16(DirBuffer, 5, ItemId)
            task.defer(function()
                MessageAPI.SendToCombat("PushAlong", DirBuffer)    
            end)
        end
        
    end

end
return NPCCombatUtil