--!native
--[[ --*Info on Module
reason for Release function that just leads to actual release is cos sometimes i may not know which state they are in and i might need to release
for example look at the combatlogic  ApplyDamage function
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScript = script.Parent.Parent
local CustomTask = require(script.Parent.Parent.Parent.Parent.Parent.Parent.ReplicatedStorage.Shared.CustomTask)
local Hitbox = require(script.Parent.Parent.Parent.Parent.Parent.Parent.ReplicatedStorage.Shared.Hitbox)
local CombatLogic = require(ServerScript.Character_Controller.CombatLogic)
local Character_Controller = require(ServerScript.Character_Controller)
local MessageAPI = require(ServerScript.MessageAPI)
local Shared = ReplicatedStorage.Shared
local ItemDataMod = require(Shared.ItemDataMod)
local SharedTypes = require(Shared.SharedType)
local Encyclopedia = require(Shared.Encyclopedia)
local NumToSymbol = require(Shared.NumToSymbol)
local SendToCombat = MessageAPI.SendToCombat
local CREATE_PLAYER_STATE = function(Length:number, UID, StateNum:number, ActionNum:number) 
    local StateBuffer = buffer.create(Length)
    local Writeu8 = buffer.writeu8
    local State = StateNum --*Blocking,Idle,WeaponOut , ... etc
    local Action = ActionNum --*Blocked, Parried, Block, M1, ... etc
    UID = tonumber(UID)
    Writeu8(StateBuffer, 0, Length)
    Writeu8(StateBuffer, 1, UID)
    Writeu8(StateBuffer, 2, State)
    Writeu8(StateBuffer, 3, Action)
    return StateBuffer    
end
local UPDATE_SERVER_COMBATTICK = function(Length:number, UID, StateNum:number, ActionNum:number, CurrentFrame:number) 
    local Message = "UpdateProfile"
    UID = tonumber(UID)
    local StateBuffer = CREATE_PLAYER_STATE(Length, UID, StateNum, ActionNum)
    if CurrentFrame then 
        buffer.writeu8(StateBuffer, 4, CurrentFrame)
    end
    SendToCombat(Message, StateBuffer)
    return StateBuffer    
end
--[[
local UPDATE_SERVER_COMBATTICK_WITH_FRAME = function(Length:number, UID, StateNum:number, ActionNum:number) 
    local Message = "UpdWithFrame"
    UID = tonumber(UID)
    local StateBuffer = CREATE_PLAYER_STATE(Length, UID, StateNum, ActionNum) 
    SendToCombat(Message, 4, StateBuffer)
    return StateBuffer    
end

]]

type CombatMachine = SharedTypes.ServerCombatMachine
type StateMachine = SharedTypes.ClientStateMachine
local ServerCombatStates = {
}
--TODO Kick player if FrameDifference is Aboce 333ms (Unstable InternetConnecction)
ServerCombatStates["WeaponOut"] = {
    ["M1"] = function(CombatController: CombatMachine, StateMachine: StateMachine, UID, ...)
        CombatController.ChangeState(UID, "LightAttack", "WeaponOut")
        CombatController.TriggerAction(UID, "Light", ...)
    end,
    ["ToolHandle"] = function(CombatController: CombatMachine, StateMachine: StateMachine, UID, FrameBuffer: buffer)
        local KeyPress = buffer.readu8(FrameBuffer, 1) --* 0 index is Frame
        if KeyPress > 8 or KeyPress < 1 then return end
        StateMachine.CurrentItem = nil
        local Length = 6
        local b = buffer.create(Length)
        local Writeu8 = buffer.writeu8
        local ClientFrame = buffer.readu8(FrameBuffer, 0)
        Writeu8(b, 0, Length)
        UID = tonumber(UID)
        Writeu8(b, 1, UID)
        Writeu8(b, 2, 2) --* WeaponOut
        Writeu8(b, 3, 8) --* ToolHandle
        Writeu8(b, 4, ClientFrame)
        Writeu8(b, 5, KeyPress)
        
        MessageAPI.SendToCombat("UpdateProfile", b)
        CombatController.ChangeState(UID, "Idle", "Idle")
    end,
    ["Block"] = function(CombatController: CombatMachine, StateMachine: StateMachine, UID, FrameBuffer: buffer, ...)
        CombatController.ChangeState(UID, "Blocking", "WeaponOut")
        CombatController.TriggerAction(UID, "Guard", FrameBuffer, ...)
        local ClientFrame = buffer.readu8(FrameBuffer, 0)
        local StateNum = 3 --* Blocking
        local ActionNum = 18 --* Guard
        UPDATE_SERVER_COMBATTICK(5, UID, StateNum, ActionNum, ClientFrame)        
    end,
}
ServerCombatStates["Idle"] = {
    ["ToolHandle"] = function(CombatController: CombatMachine, StateMachine: StateMachine, UID, FrameBuffer: buffer)
        local KeyPress = buffer.readu8(FrameBuffer, 1)
        if KeyPress > 8 or KeyPress < 1 then return end
        local Hotbar = StateMachine[StateMachine.ActiveToolbar]
        if not  Hotbar then warn("no ActiveToolbar: ", Hotbar, StateMachine); return end
        CombatController.ChangeState(UID, "WeaponOut", "WeaponOut")

        local StringNum = NumToSymbol.GiveString(KeyPress)
        local ItemNum = Hotbar[StringNum]
        local Item = Encyclopedia[ItemNum]
        StateMachine.CurrentItem = Item

        local Length = 6
        local b = buffer.create(Length)
        local Writeu8 = buffer.writeu8
        local ClientFrame = buffer.readu8(FrameBuffer, 0)
        Writeu8(b, 0, Length)
        UID = tonumber(UID)
        Writeu8(b, 1, UID)
        Writeu8(b, 2, 1) --* Idle
        Writeu8(b, 3, 8) --* ToolHandle
        Writeu8(b, 4, ClientFrame)
        Writeu8(b, 5, KeyPress)
        
        MessageAPI.SendToCombat("UpdateProfile", b)
    end,
}
ServerCombatStates["HeavyAttack"] = {
    ["TrueStun"]= function(CombatController: CombatMachine, StateMachine: StateMachine, UID,  ...)
        CombatLogic.RemoveFromQ() --* so they cannot cheat the Q
        CombatController.ChangeState(UID, "TrueStun")
        CombatController.TriggerAction(UID, "Stun", ...)
    end,
    ["SoftStun"]= function(CombatController: CombatMachine, StateMachine: StateMachine, UID,  ...)
        CombatLogic.RemoveFromQ() --* so they cannot cheat the Q
        CombatController.ChangeState(UID, "SoftStun")
        CombatController.TriggerAction(UID, "Stun", ...)
    end,
    ["Release"]= function(CombatController: CombatMachine, StateMachine: StateMachine, UID,  ...)
        --* releases from CombatLogic ApplyDamage (processing the Queue)
        local OldState = CombatController.ChangeToOldState(UID)
        local Length = 5
        local StateNum = Encyclopedia.GiveNumRef(OldState)        
        local StateBuffer = CREATE_PLAYER_STATE(Length, UID, StateNum, 25)
        MessageAPI.SendToCombat("UpdWithFrame", 4, StateBuffer)
        local FA:Actor = Character_Controller["FA"]
        FA:SendMessage("LockMove")
    end,
}
ServerCombatStates["LightAttack"] = {
    ["Light"] = function(CombatController: CombatMachine, StateMachine: StateMachine, UID, StateBuffer: buffer, ...)
        local CurrentItem = StateMachine.CurrentItem
        local ItemData:SharedTypes.ItemData = ItemDataMod.GiveCopyData(CurrentItem)
        if not ItemData then warn("no ItemData: ", CurrentItem); return end

        local M1Count:number = StateMachine.M1Count
        local UnixMill = DateTime.now().UnixTimestampMillis
        M1Count += 1
        if M1Count >= 4 then  M1Count = 1 end
        if  UnixMill - StateMachine.M1ResetTime > 1500  then --* been longer than a second since the last m1 
            M1Count = 1
        end
        local TypeHit = 0
        if M1Count == 3 then 
            TypeHit = 1
        end
        StateMachine.M1ResetTime = UnixMill
        StateMachine.M1Count = M1Count
        CombatLogic.AddtoQ(CurrentItem, TypeHit)
        
        local Ri16 = buffer.readi16 
        local X, Z = Ri16(StateBuffer, 1), Ri16(StateBuffer, 3)
        local LookDir = Vector3.new(X, 0, Z).Unit
        local FA:Actor = Character_Controller["FA"]
        FA:SendMessage("SetDir", LookDir) 
        FA:SendMessage("LockMove", true)
        local ClientFrame = buffer.readu8(StateBuffer, 4)
        local CFV:CFrameValue =  Character_Controller["CFV"]
        StateMachine.CurrentAction = CustomTask.DelayParallel(ItemData.HBTime/1000, function ()    
            --* Task.delay after Q cos its an NPC
            --* Apply Damage Here cos too slow to SendMessage for DetectedUIDs
            local Results = Hitbox:NPCGPB(CFV.Value, ItemData)
            local UIDsT = {}
            for _, BodyCFPart in Results do  
                local NumUID = tonumber(BodyCFPart.Name)
                if NumUID and NumUID == tonumber(UID) then continue end --* number comparison faster than string
                table.insert(UIDsT, BodyCFPart.Name)
            end
            if #UIDsT <= 0 then CombatController.TriggerAction(UID, "Release"); FA:SendMessage("LockMove"); return end --* no Hits
            local DetectedUIDs  = Hitbox.BufferTableResults(UIDsT, 0, 1)
            UID = tostring(UID) -- change back to string cos look below
            CombatLogic.ApplyDamage(UID, DetectedUIDs, 0, TypeHit, ItemData)
            FA:SendMessage("LockMove")
            CombatController.TriggerAction(UID, "Release");
        end)
        UPDATE_SERVER_COMBATTICK(5, UID, 4, 13, ClientFrame)
    end,
    ["TrueStun"]= function(CombatController: CombatMachine, StateMachine: StateMachine, UID,  ...)
        CombatLogic.RemoveFromQ() --* so they cannot cheat the Q
        CombatController.ChangeState(UID, "TrueStun")
        CombatController.TriggerAction(UID, "Stun", ...)
    end,
    ["Release"]= function(CombatController: CombatMachine, StateMachine: StateMachine, UID,  ...)
        --* releases from CombatLogic ApplyDamage (processing the Queue)
        local OldState = CombatController.ChangeToOldState(UID)
        local Length = 5
        local StateNum = Encyclopedia.GiveNumRef(OldState)        
        local StateBuffer = CREATE_PLAYER_STATE(Length, UID, StateNum, 25)
        MessageAPI.SendToCombat("UpdWithFrame", 4, StateBuffer)
        local FA:Actor = Character_Controller["FA"]
        FA:SendMessage("LockMove")
    end,
    --[[
    ["ReleaseLightAttack"] = function(CombatController: CombatMachine, StateMachine: StateMachine, UID,  ...)
        local FA:Actor = Character_Controller["FA"] 
        FA:SendMessage("LockMove", nil)        
        CombatController.ChangeToOldState(UID)         
        UPDATE_SERVER_COMBATTICK_WITH_FRAME(5, UID, 4, 21)
    end

    ]]
}
ServerCombatStates["Skill"] = {}
ServerCombatStates["TrueStun"] = {
    ["Stun"] = function(CombatController: CombatMachine, StateMachine: StateMachine, UID, AttackerUID, ItemName, Frame, ...)
        local FA:Actor = Character_Controller["FA"] 
        FA:SendMessage("LockMove", true)
        MessageAPI.SendToHealth("SendMessage", "TakeDamage", UID, ItemName, AttackerUID)
        if StateMachine.SStun then task.cancel(StateMachine.SStun); return end                  
        if StateMachine.TStun then task.cancel(StateMachine.TStun); return end
        local WeaponData = ItemDataMod.GiveCopyData(ItemName)
        if not WeaponData then warn("invalid Item Name: ", WeaponData); return end 
        StateMachine.TStun = task.delay((WeaponData.Stun +2) /2, function()  CombatController.TriggerAction(UID, "Release") end)
        -- UPDATE_SERVER_COMBATTICK(5, UID, StateNum, ActionNum, nil, "UpdWithFrame")
        if Frame then 
            --*player hit player
            local StateBuffer = CREATE_PLAYER_STATE(6, UID, 7, 20)
            buffer.writeu8(StateBuffer, 5, AttackerUID)
            SendToCombat("UpdateProfile", StateBuffer)
            return
        end
        --* NPC hit Player
        local StateBuffer = CREATE_PLAYER_STATE(6, UID, 7, 20)
        buffer.writeu8(StateBuffer, 5, AttackerUID)
        SendToCombat("UpdWithFrame", 4, StateBuffer)    
    end,
    ["GuardBroken"] = function(CombatController: CombatMachine, StateMachine: StateMachine, UID, AttackerUID, ItemName, Frame, ...)
        local FA:Actor = Character_Controller["FA"] 
        FA:SendMessage("LockMove", true)
        MessageAPI.SendToHealth("SendMessage", "TakeDamage", UID, ItemName, AttackerUID)
        if StateMachine.SStun then task.cancel(StateMachine.SStun); return end                  
        if StateMachine.TStun then task.cancel(StateMachine.TStun); return end
        local WeaponData = ItemDataMod.GiveCopyData(ItemName)
        if not WeaponData then warn("invalid Item Name: ", WeaponData); return end 
        StateMachine.TStun = task.delay((WeaponData.Stun +2) /2, function()  CombatController.TriggerAction(UID, "Release") end)
        if Frame then 
            --*player hit player
            local StateBuffer = CREATE_PLAYER_STATE(5, UID, 7, 24)
            SendToCombat("UpdateProfile", StateBuffer)
            return
        end
        --* NPC hit Player
        local StateBuffer = CREATE_PLAYER_STATE(5, UID, 7, 24)
        SendToCombat("UpdWithFrame", 4, StateBuffer)        
    end,
    ["Release"]  = function(CombatController: CombatMachine, StateMachine: StateMachine, UID, AttackerUID , WeaponData: SharedTypes.ItemData, ...)
        local FA:Actor = Character_Controller["FA"] 
        FA:SendMessage("LockMove")
        CombatController.ChangeToOldState(UID)

        local OldState = CombatController.ChangeToOldState(UID)
        local Length = 5
        local StateNum = Encyclopedia.GiveNumRef(OldState)        
        local StateBuffer = CREATE_PLAYER_STATE(Length, UID, StateNum, 25)
        MessageAPI.SendToCombat("UpdWithFrame", 4, StateBuffer)
    end, 
    ["Dead"]= function(CombatController: CombatMachine, StateMachine: StateMachine, UID,  ...)
        local FA:Actor = Character_Controller["FA"] 
        FA:SendMessage("LockMove", true)
        MessageAPI.SendToSSS("RespawnPlayer", UID)
    end,
}
ServerCombatStates["SoftStun"] = {
    ["Stun"]= function(CombatController: CombatMachine, StateMachine: StateMachine, UID, ItemName, AttackerUID, Frame,  ...)
        if StateMachine.SStun then task.cancel(StateMachine.SStun); StateMachine.SStun = nil  end
        local FA:Actor = Character_Controller["FA"] 
        warn(ItemName)
        local WeaponData = ItemDataMod[ItemName]
        if not WeaponData then warn("invalid Item Name: ", WeaponData); return end 
        MessageAPI.SendToHealth("SendMessage", "TakeDamage", UID, ItemName, AttackerUID)        
        FA:SendMessage("LockMove", true)                 
        StateMachine.SStun = task.delay(WeaponData.Stun, function()
            FA:SendMessage("LockMove")        
            CombatController.TriggerAction(UID, "Release") 
        end)
        if Frame then 
            --*player hit player
            local StateBuffer = CREATE_PLAYER_STATE(6, UID, 6, 20)
            buffer.writeu8(StateBuffer, 5, AttackerUID)
            SendToCombat("UpdateProfile", StateBuffer)
            return
        end
        --* NPC hit Player
        local StateBuffer = CREATE_PLAYER_STATE(6, UID, 6, 20)
        buffer.writeu8(StateBuffer, 5, AttackerUID)
        SendToCombat("UpdWithFrame", 4, StateBuffer)
    end,
    ["SoftStun"]= function(CombatController: CombatMachine, StateMachine: StateMachine, UID,  ...)
        CombatController.TriggerAction(UID, "Stun")
    end,
    ["Release"] = function(CombatController: CombatMachine, StateMachine: StateMachine, UID, ...)
        local FA:Actor = Character_Controller["FA"] 
        FA:SendMessage("LockMove")                 
        local OldState = CombatController.ChangeToOldState(UID)
        local Length = 5
        local StateNum = Encyclopedia.GiveNumRef(OldState)        
        local StateBuffer = CREATE_PLAYER_STATE(Length, UID, StateNum, 25)
        MessageAPI.SendToCombat("UpdWithFrame", 4, StateBuffer)
    end,
}
ServerCombatStates["Blocking"] = {
    ["Guard"]= function(CombatController: CombatMachine, StateMachine: StateMachine, UID, StateBuffer: buffer, a, b,   ...)
        if not StateBuffer then warn("no state buffer: ", StateBuffer, a, b); return end
        local Ri16= buffer.readi16
        local X, Z = Ri16(StateBuffer, 1), Ri16(StateBuffer, 3)
        local LookDir = Vector3.new(X, 0, Z).Unit
        local FA:Actor = Character_Controller["FA"]
        FA:SendMessage("SetDir", LookDir) 
        FA:SendMessage("LockMove", true)
        StateMachine.CDs.ParryStart = DateTime.now().UnixTimestampMillis                
    end,
    ["SoftStun"]  = function(CombatController: CombatMachine, StateMachine: StateMachine, UID, ...)
        local CDTable = StateMachine.CDs
        local UnixMill  = DateTime.now().UnixTimestampMillis
        local ParryStarted = CDTable.ParryStart
        if not ParryStarted then print("parry not started"); return end
        local ParryCD = CDTable.ParryCD
        if not ParryCD then ParryCD = UnixMill end
        local ParryCDCheck = UnixMill - ParryCD
        if ParryCDCheck > 1200 then 
            --*it means 1 second has passed since they last tried parrying accept it this time
            local Check = UnixMill - ParryStarted
            --*less than 0.35s since they started blocking so accept Parry
            if Check <= 370 then 
                CombatController.TriggerAction(UID, "Parried", ...) 
                return
            end    
            CDTable.ParryCD = UnixMill --* they can carry on Parrying if they parried Successfully        
        end
        CombatController.TriggerAction(UID, "Blocked", ...)
    end,
    ["Blocked"] = function(CombatController: CombatMachine, StateMachine: StateMachine, UID, ItemName, AttackerUID, Frame,  ...)
        MessageAPI.SendToPosture("SendMessage", "TakeDamage", UID, ItemName, AttackerUID, Frame) 
        if Frame then 
            --*player hit player
            local StateBuffer = CREATE_PLAYER_STATE(5, UID, 3, 17)
            SendToCombat("UpdateProfile", StateBuffer)
            return
        end
        --* NPC hit Player
        local StateBuffer = CREATE_PLAYER_STATE(5, UID, 3, 17)
        SendToCombat("UpdWithFrame", 4, StateBuffer)
        --TODO KB move
    end,    
    ["Parried"] = function(CombatController: CombatMachine, StateMachine: StateMachine, UID, ItemName, AttackerUID, Frame,  ...)
        MessageAPI.SendToPosture("SendMessage", "TakeDamage", UID, ItemName, AttackerUID, Frame, true) 
        if Frame then 
            --*player hit player
            local StateBuffer = CREATE_PLAYER_STATE(5, UID, 3, 16)
            SendToCombat("UpdateProfile", StateBuffer)
            return
        end
        --* NPC hit Player
        local StateBuffer = CREATE_PLAYER_STATE(5, UID, 3, 16)
        SendToCombat("UpdWithFrame", 4, StateBuffer)
        print("Parried the Hit")
        --TODO KB move
    end,
    ["GuardBroken"] = function(CombatController: CombatMachine, StateMachine: StateMachine, UID, AttackerUID, ItemName, Frame, ...)
        CombatController.ChangeState(UID, "TrueStun")
        CombatController.TriggerAction(UID, "GuardBroken", AttackerUID, ItemName)
    end, 
    ["StopBlock"] = function(CombatController: CombatMachine, StateMachine: StateMachine, UID, FrameBuffer: buffer, ...)
        local FA:Actor = Character_Controller["FA"] 
        FA:SendMessage("LockMove")
        local OldState = CombatController.ChangeToOldState(UID)  
        local StateNum = Encyclopedia.GiveNumRef(OldState)
        if not StateNum then warn("incorrect OldState ", StateNum, OldState); return end 
        local ClientFrame = buffer.readu8(FrameBuffer, 4)
        UPDATE_SERVER_COMBATTICK(5, UID, StateNum, 25, ClientFrame)
    end,
}
do -- Dead
    local Dead = function(CombatController: CombatMachine, StateMachine: StateMachine, UID, ...)
        CombatController.ChangeState(UID, "TrueStun")
        CombatController.TriggerAction(UID, "Dead")
    end    
    ServerCombatStates.Blocking["TriggerDead"] = Dead
    ServerCombatStates.WeaponOut["TriggerDead"] = Dead
    ServerCombatStates.Idle["TriggerDead"] = Dead
    ServerCombatStates.SoftStun["TriggerDead"] = Dead
    ServerCombatStates.HeavyAttack["TriggerDead"] = Dead
    ServerCombatStates.LightAttack["TriggerDead"] = Dead
    ServerCombatStates.Skill["TriggerDead"] = Dead    
end
do -- Softstun
    local SoftStun= function(CombatController: CombatMachine, StateMachine: StateMachine, UID,  ...)
        CombatController.ChangeState(UID, "SoftStun")
        CombatController.TriggerAction(UID, "Stun")
    end
    ServerCombatStates.WeaponOut["SoftStun"] = SoftStun
    ServerCombatStates.Idle["SoftStun"] = SoftStun
    ServerCombatStates.TrueStun["SoftStun"] = SoftStun
    ServerCombatStates.Skill["SoftStun"] = SoftStun    
    ServerCombatStates.LightAttack["SoftStun"] = SoftStun    
end
do--TrueStun
    local TrueStun = function(CombatController: CombatMachine, StateMachine: StateMachine, UID,  ...)
        CombatController.ChangeState(UID, "TrueStun")
        CombatController.TriggerAction(UID, "Stun")
    end
    
    ServerCombatStates.WeaponOut["TrueStun"] = TrueStun
    ServerCombatStates.Idle["TrueStun"] = TrueStun
    ServerCombatStates.SoftStun["TrueStun"] = TrueStun
    ServerCombatStates.Skill["TrueStun"] = TrueStun
    
end
do-- Run StopRun
    local Run = function(CombatController: CombatMachine, StateMachine: StateMachine, UID, FrameBuffer: buffer, WS)
        local FA:Actor = Character_Controller["FA"] 
        FA:SendMessage("AdjustWS", WS *2)
    end
    local StopRun = function(CombatController: CombatMachine, StateMachine: StateMachine, UID, FrameBuffer: buffer, WS)
        local FA:Actor = Character_Controller["FA"] 
        FA:SendMessage("AdjustWS", WS)
    end 
    ServerCombatStates.WeaponOut["Run"] = Run
    ServerCombatStates.Idle["Run"] = Run
    ServerCombatStates.WeaponOut["StopRun"] = StopRun
    ServerCombatStates.Idle["StopRun"] = StopRun
end
return ServerCombatStates