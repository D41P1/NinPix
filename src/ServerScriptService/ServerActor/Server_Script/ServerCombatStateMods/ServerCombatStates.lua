--*Server
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScript = script.Parent.Parent
local CombatLogic = require(ServerScript.Character_Controller.CombatLogic)
local Character_Controller = require(ServerScript.Character_Controller)
local MessageAPI = require(ServerScript.MessageAPI)

local Shared = ReplicatedStorage.Shared
local ItemDataMod = require(Shared.ItemDataMod)
local SharedTypes = require(Shared.SharedType)
local Encyclopedia = require(Shared.Encyclopedia)
local NumToSymbol = require(Shared.NumToSymbol)
--// local ServerRayMovement = require(ServerScript.ServerRayMovement)

-- local HB = require(Shared.Hitbox) 
-- local Eventmanager = require(Shared.Event_Manager)
-- local HumanoidMachine = require(Shared.HumanoidMachine)

local UPDATE_SERVER_COMBATTICK = function(Length:number, UID:string, StateNum:number, ActionNum:number, CurrentFrame:number, TypeMessage:string?) 
    local Message = TypeMessage  or "UpdateProfile"
    local StateBuffer = buffer.create(Length)
    local Writeu8 = buffer.writeu8
    local State = StateNum --*Blocking,Idle,WeaponOut , ... etc
    local Action = ActionNum --*Blocked, Parried, Block, M1, ... etc
    Writeu8(StateBuffer, 0, Length)
    buffer.writestring(StateBuffer, 1, UID, 1)
    Writeu8(StateBuffer, 2, State)
    Writeu8(StateBuffer, 3, Action)
    Writeu8(StateBuffer, 4, CurrentFrame)
    MessageAPI.SendToCombat(Message, StateBuffer)
    return StateBuffer    
end


type CombatMachine = SharedTypes.ServerCombatMachine
type StateMachine = SharedTypes.ClientStateMachine
local ServerCombatStates = {
}

--TODO Kick player if FrameDifference is Aboce 333ms (Unstable InternetConnecction)
ServerCombatStates["WeaponOut"] = {
    ["Run"] = function(CombatController: CombatMachine, StateMachine: StateMachine, UID, FrameBuffer: buffer, WS)
        local FA:Actor = Character_Controller["FA"] 
        FA:SendMessage("AdjustWS", WS *2)
    end,
    ["M1"] = function(CombatController: CombatMachine, StateMachine: StateMachine, UID, ...)
        CombatController.ChangeState(UID, "LightAttack", "WeaponOut")
        CombatController.TriggerAction(UID, "Light", ...)
    end,
    ["ToolHandle"] = function(CombatController: CombatMachine, StateMachine: StateMachine, UID, FrameBuffer: buffer)
        local KeyPress = buffer.readu8(FrameBuffer, 1)
        if KeyPress > 8 or KeyPress < 1 then return end
        StateMachine.CurrentItem = nil
        local Length = 5
        local b = buffer.create(Length)
        local Writeu8 = buffer.writeu8
        local ClientFrame = buffer.readu8(FrameBuffer, 0)
        Writeu8(b, 0, Length)
        buffer.writestring(b, 1, UID, 1)
        Writeu8(b, 2, 2) --* WeaponOut
        Writeu8(b, 3, 8) --* ToolHandle
        Writeu8(b, 4, ClientFrame)
        MessageAPI.SendToCombat("UpdateProfile", b)
        CombatController.ChangeState(UID, "Idle")
    end,
    ["SoftStun"] = function(CombatController: CombatMachine, StateMachine: StateMachine, UID, ...)
        CombatController.ChangeState(UID, "SoftStun", "WeaponOut")
        CombatController.TriggerAction(UID, "Stun", ...)
    end,
    ["Block"] = function(CombatController: CombatMachine, StateMachine: StateMachine, UID, FrameBuffer: buffer, WS, ...)
        CombatController.ChangeState(UID, "Blocking", "WeaponOut")
        CombatController.TriggerAction(UID, "Guard", ...)
        local ClientFrame = buffer.readu8(FrameBuffer, 0)
        local StateNum = 2 --* WeaponOut
        local ActionNum = 14 --* Block
        UPDATE_SERVER_COMBATTICK(5, UID, StateNum, ActionNum, ClientFrame)        
    end,
    ["StopRun"] = function(CombatController: CombatMachine, StateMachine: StateMachine, UID, FrameBuffer: buffer, WS)
        local FA:Actor = Character_Controller["FA"] 
        FA:SendMessage("AdjustWS", WS)
    end,
}
ServerCombatStates["Idle"] = {
    ["ToolHandle"] = function(CombatController: CombatMachine, StateMachine: StateMachine, UID, FrameBuffer: buffer)
        local KeyPress = buffer.readu8(FrameBuffer, 1)
        if KeyPress > 8 or KeyPress < 1 then return end
        local Hotbar = StateMachine[StateMachine.ActiveHotbar]
        if not  Hotbar then warn("no ActiveHotbar: ", Hotbar, StateMachine); return end
        CombatController.ChangeState(UID, "WeaponOut", "WeaponOut")

        local StringNum = NumToSymbol[KeyPress]
        local ItemNum = Hotbar[StringNum]
        local Item = Encyclopedia[ItemNum]
        StateMachine.CurrentItem = Item

        local Length = 5
        local b = buffer.create(Length)
        local Writeu8 = buffer.writeu8
        local ClientFrame = buffer.readu8(FrameBuffer, 0)
        Writeu8(b, 0, Length)
        buffer.writestring(b, 1, UID, 1)
        Writeu8(b, 2, 1) --* Idle
        Writeu8(b, 3, 8) --* ToolHandle
        Writeu8(b, 4, ClientFrame)
        MessageAPI.SendToCombat("UpdateProfile", b)
    end,
    ["Run"] = function(CombatController: CombatMachine, StateMachine: StateMachine, UID, FrameBuffer: buffer, WS)
        local FA:Actor = Character_Controller["FA"] 
        FA:SendMessage("AdjustWS", WS *2)
    end,
    ["StopRun"] = function(CombatController: CombatMachine, StateMachine: StateMachine, UID, FrameBuffer: buffer, WS)
        local FA:Actor = Character_Controller["FA"] 
        FA:SendMessage("AdjustWS", WS)
    end,
    ["SoftStun"] = function(CombatController: CombatMachine, StateMachine: StateMachine, UID, ...)
        CombatController.ChangeState(UID, "SoftStun", "Idle")
        CombatController.TriggerAction(UID, "Stun", ...)
    end
}
ServerCombatStates["HeavyAttack"] = {}
ServerCombatStates["LightAttack"] = {
    ["Light"] = function(CombatController: CombatMachine, StateMachine: StateMachine, UID, StateBuffer: buffer, ...)
        local CurrentItem = StateMachine.CurrentItem
        CombatLogic.AddtoQ(CurrentItem)
        local Ri16 = buffer.readi16 
        local X, Z = Ri16(StateBuffer, 5), Ri16(StateBuffer, 7)
        local LookDir = Vector3.new(X, 0, Z).Unit
        local FA:Actor = Character_Controller["FA"]
        FA:SendMessage("SetDir", LookDir) 
        FA:SendMessage("LockMove", true)
        local ClientFrame = buffer.readu8(StateBuffer, 4)
        UPDATE_SERVER_COMBATTICK(5, UID, 4, 13, ClientFrame)
    end,
    ["SoftStun"]= function(CombatController: CombatMachine, StateMachine: StateMachine, UID,  ...)
        CombatController.ChangeState(UID, "SoftStun")
        CombatController.TriggerAction(UID, "Stun", ...)
    end,
    ["Release"]= function(CombatController: CombatMachine, StateMachine: StateMachine, UID, ClientFrame:number, ...)
        --* releases from CombatLogic ApplyDamage (processing the Queue)
        local FA:Actor = Character_Controller["FA"] 
        FA:SendMessage("LockMove")        
        CombatController.ChangeToOldState(UID) 
        UPDATE_SERVER_COMBATTICK(5, UID, 4, 19, ClientFrame)        
    end
}
ServerCombatStates["Skill"] = {}
ServerCombatStates["TrueStun"] = {
    ["Stun"] = function(CombatController: CombatMachine, StateMachine: StateMachine, UID, AttackerUID, ItemName, ...)
        local FA:Actor = Character_Controller["FA"] 
        FA:SendMessage("LockMove", true)
        MessageAPI.SendToHealth("SendMessage", "TakeDamage", UID, ItemName, AttackerUID)
        if StateMachine.SStun then task.cancel(StateMachine.SStun); return end                  
        if StateMachine.TStun then task.cancel(StateMachine.TStun); return end
        local WeaponData = ItemDataMod.GiveCopyData(ItemName)
        if not WeaponData then warn("invalid Item Name: ", WeaponData); return end 
        StateMachine.TStun = task.delay((WeaponData.Stun +2) /2, function()  CombatController.TriggerAction(UID, "Release") end)

        local StateNum  = 7
        local ActionNum = 20
        UPDATE_SERVER_COMBATTICK(5, UID, StateNum, ActionNum, nil, "UpdWithFrame")
    end,
    ["Release"] = function(CombatController: CombatMachine, StateMachine: StateMachine, UID, AttackerUID , WeaponData: SharedTypes.ItemDataMod, ...)
        local FA:Actor = Character_Controller["FA"] 
        FA:SendMessage("LockMove")
        CombatController.ChangeToOldState(UID)
    end, 
}
ServerCombatStates["SoftStun"] = {
    ["Stun"]= function(CombatController: CombatMachine, StateMachine: StateMachine, UID, ItemName, AttackerUID, ClientFrame,  ...)
        if StateMachine.SStun then task.cancel(StateMachine.SStun); StateMachine.SStun = nil  end
        MessageAPI.SendToHealth("SendMessage", "TakeDamage", UID, ItemName, AttackerUID)        
        local FA:Actor = Character_Controller["FA"] 
        local WeaponData = ItemDataMod[ItemName]
        if not WeaponData then warn("invalid Item Name: ", WeaponData); return end 
        FA:SendMessage("LockMove", true)                 
        StateMachine.SStun = task.delay(WeaponData.Stun, function()
            FA:SendMessage("LockMove")        
            CombatController.TriggerAction(UID, "Release") 
        end)
    end,
    ["Release"] = function(CombatController: CombatMachine, StateMachine: StateMachine, UID, ...)
        CombatController.ChangeToOldState(UID)
    end
}
ServerCombatStates["Blocking"] = {
    ["Guard"] = function(CombatController: CombatMachine, StateMachine: StateMachine, UID, FrameBuffer: buffer, WS, ...)
        local FA:Actor = Character_Controller["FA"] 
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
                print("Parry trig")
                return
            end    
            CDTable.ParryCD = UnixMill --* they can carry on Parrying if they parried Successfully        
        end
        CombatController.TriggerAction(UID, "Blocked", ...)
        print("BLock trig")
    end,
    ["Blocked"] = function(CombatController: CombatMachine, StateMachine: StateMachine, UID, ItemName, AttackerUID, ClientFrame,  ...)
        local WeaponData = ItemDataMod[ItemName]
        if not WeaponData then warn("invalid Item Name: ", WeaponData); return end 
        MessageAPI.SendToPosture("SendMessage", "TakeDamage", UID, ItemName, AttackerUID)
        UPDATE_SERVER_COMBATTICK(5, UID, 3, 17, ClientFrame)
        print("Blocked the Hit")
        --TODO KB move
    end,
    ["Parried"] = function(CombatController: CombatMachine, StateMachine: StateMachine, UID, AttackerUID, AttackerProfile: StateMachine, ClientFrame,  ...)
        UPDATE_SERVER_COMBATTICK(5, UID, 3, 16, ClientFrame)
        print("Parried the Hit")
        --TODO KB move
    end,
    ["GuardBroken"] = function(CombatController: CombatMachine, StateMachine: StateMachine, UID, AttackerUID, ItemName,  ...)
        CombatController.ChangeState(UID, "TrueStun")
        CombatController.TriggerAction(UID, "Stun", AttackerUID, ItemName)
    end, 
    ["StopBlock"] = function(CombatController: CombatMachine, StateMachine: StateMachine, UID, FrameBuffer: buffer, WS, ...)
        local FA:Actor = Character_Controller["FA"] 
        FA:SendMessage("LockMove")
        CombatController.ChangeToOldState(UID)  
        local ClientFrame = buffer.readu8(FrameBuffer, 4)
        UPDATE_SERVER_COMBATTICK(5, UID, 3, 15, ClientFrame)
    end,
}   

ServerCombatStates["Parrying"] = {}
return ServerCombatStates