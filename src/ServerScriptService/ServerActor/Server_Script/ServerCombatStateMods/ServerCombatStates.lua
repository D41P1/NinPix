--!native
--[[ --*Info on Module
reason for Release function that just leads to actual release is cos sometimes i may not know which state they are in and i might need to release
for example look at the combatlogic  ApplyDamage function

    ]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScript = script.Parent.Parent
local Shared = ReplicatedStorage.Shared
local CharacterScripts_Folder = ServerScript.Character_Scripts_Folder
local Stats_Controller = require(ServerScript.Stats_Controller)
local CombatLogic = require(CharacterScripts_Folder.CombatLogic)
local Character_Controller = require(CharacterScripts_Folder.Character_Controller)
local MessageAPI = require(ServerScript.MessageAPI)
local SSS_Communicate = MessageAPI["MT"]

local Hitbox = require(Shared.Hitbox)
local ItemDataMod = require(Shared.ItemDataMod)
local SharedTypes = require(Shared.SharedType)
local State_Dictionary = require(Shared.State_Dictionary)
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
local Dead = function(CombatController: CombatMachine, StateMachine: StateMachine, UID, ...)
    CombatController.ChangeState(UID, "TrueStun")
    CombatController.TriggerAction(UID, "Dead")
end    
local SoftStun= function(CombatController: CombatMachine, StateMachine: StateMachine, UID,  ...)
    CombatController.ChangeState(UID, "SoftStun")
    CombatController.TriggerAction(UID, "Stun")
end
local TrueStun = function(CombatController: CombatMachine, StateMachine: StateMachine, UID,  ...)
    CombatController.ChangeState(UID, "TrueStun")
    CombatController.TriggerAction(UID, "Stun")
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
        CombatController.ChangeState(UID, "Idle", "Idle")
    end,
    ["Block"] = function(CombatController: CombatMachine, StateMachine: StateMachine, UID, FrameBuffer: buffer, ...)
        CombatController.ChangeState(UID, "Blocking", "WeaponOut")
        CombatController.TriggerAction(UID, "Guard", FrameBuffer, ...)
    end,
}
ServerCombatStates["Idle"] = {
    ["ToolHandle"] = function(CombatController: CombatMachine, StateMachine: StateMachine, UID, FrameBuffer: buffer)
        CombatController.ChangeState(UID, "WeaponOut", "WeaponOut")
    end,
}
ServerCombatStates["HeavyAttack"] = {
    ["TrueStun"]= function(CombatController: CombatMachine, StateMachine: StateMachine, UID,  ...)
        CombatController.ChangeState(UID, "TrueStun")
        CombatController.TriggerAction(UID, "Stun", ...)
    end,
    ["SoftStun"]= function(CombatController: CombatMachine, StateMachine: StateMachine, UID,  ...)
        CombatController.ChangeState(UID, "SoftStun")
        CombatController.TriggerAction(UID, "Stun", ...)
    end,
    ["Release"]  = function(CombatController: CombatMachine, StateMachine: StateMachine, UID, ...)
        local OldState = CombatController.ChangeToOldState(UID)
        local StateNum = State_Dictionary.GiveNumRef(OldState) 
        SSS_Communicate("UpdCS", {UID, StateNum, 0})
    end, 
    ["Heavy"] = function(CombatController: CombatMachine, StateMachine: StateMachine, UID, ...)
        local StatsProfile = Stats_Controller.GiveProfile(UID)
        local CPProfile =  Character_Controller.Give_Profile(UID)
        local Amplifiers = {1.25} --* M2 does 25% more dps
        local SwingSpeed_In_Seconds = StatsProfile.HBTime*0.001 * 1.5
        SSS_Communicate("Single_HitBox", {UID, CPProfile.CFV, StateMachine, Amplifiers}, SwingSpeed_In_Seconds) --* takes 50% longer to swing but does 25% more damage
    end,
}
ServerCombatStates["LightAttack"] = {
    ["Light"] = function(CombatController: CombatMachine, StateMachine: StateMachine, UID, StateBuffer: buffer, ...)
        local StatsProfile = Stats_Controller.GiveProfile(UID)
        local M1Count:number = StateMachine.M1Count
        local UnixMill = DateTime.now().UnixTimestampMillis
        M1Count += 1
        if  UnixMill - StateMachine.M1ResetTime > 1500  then --* been longer than a second since the last m1 
            M1Count = 1
        end
        StateMachine.M1ResetTime = UnixMill
        StateMachine.M1Count = M1Count        
        local CPProfile =  Character_Controller.Give_Profile(UID)
        local Amplifiers = {}
        local SwingSpeed_In_Seconds = StatsProfile.HBTime*0.001 
        SSS_Communicate("Single_HitBox", {UID, CPProfile.CFV, StateMachine, Amplifiers}, SwingSpeed_In_Seconds)
        warn("Add to single hitbox")
    end,
    ["TrueStun"]= function(CombatController: CombatMachine, StateMachine: StateMachine, UID,  ...)
        CombatLogic.RemoveFromQ() --* so they cannot cheat the Q
        CombatController.ChangeState(UID, "TrueStun")
        CombatController.TriggerAction(UID, "Stun", ...)
    end,
    ["Release"] = function(CombatController: CombatMachine, StateMachine: StateMachine, UID, ...)
        local OldState = CombatController.ChangeToOldState(UID)
        local StateNum = State_Dictionary.GiveNumRef(OldState) 
        SSS_Communicate("UpdCS", {UID, StateNum, 0})
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
    ["Stun"] = function(CombatController: CombatMachine, StateMachine: StateMachine, UID, Extra_Data, ...)
        SSS_Communicate("SoftStun", {UID, Extra_Data})        
        SSS_Communicate("Health_Damage", {UID, Extra_Data})
        SSS_Communicate("UpdCS", {UID, 7, 20})
    end,
    ["GuardBroken"] = function(CombatController: CombatMachine, StateMachine: StateMachine, UID, Extra_Data:SharedTypes.Extra_Damage_Data,...)
        SSS_Communicate("SoftStun", {UID, Extra_Data})      
        local Guard_Amplifier = -0.4  -- * take 40% less damage from the GuardBroken damage
        table.insert(Extra_Data.Amplifiers, Guard_Amplifier)
        SSS_Communicate("Health_Damage", {UID, Extra_Data})
        SSS_Communicate("UpdCS", {UID, 7, 24})
    end,
    ["Release"]  = function(CombatController: CombatMachine, StateMachine: StateMachine, UID, ...)
        local OldState = CombatController.ChangeToOldState(UID)
        local StateNum = State_Dictionary.GiveNumRef(OldState) 
        SSS_Communicate("UpdCS", {UID, StateNum, 0})    
    end, 
    ["Dead"]= function(CombatController: CombatMachine, StateMachine: StateMachine, UID,  ...)
        SSS_Communicate("Dead", {UID})
        SSS_Communicate("RespawnPlayer", {UID})
    end,
}
ServerCombatStates["SoftStun"] = {
    ["Stun"] = function(CombatController: CombatMachine, StateMachine: StateMachine, UID, ...)
        SSS_Communicate("SoftStun", {UID, ...})        
        SSS_Communicate("Health_Damage", {UID, ...})
        SSS_Communicate("UpdCS", {UID, 7, 20})
    end,
    ["SoftStun"]= function(CombatController: CombatMachine, StateMachine: StateMachine, UID,  ...)
        CombatController.TriggerAction(UID, "Stun")
    end,
    ["Release"]  = function(CombatController: CombatMachine, StateMachine: StateMachine, UID, ...)
        local OldState = CombatController.ChangeToOldState(UID)
        local StateNum = State_Dictionary.GiveNumRef(OldState) 
        SSS_Communicate("UpdCS", {UID, StateNum, 0})
    end, 
    ["Block"] = function(CombatController: CombatMachine, StateMachine: StateMachine, UID, FrameBuffer: buffer, ...)
        CombatController.ChangeState(UID, "Blocking", "SoftStun")
        CombatController.TriggerAction(UID, "Guard", FrameBuffer, ...)
    end,
}
ServerCombatStates["Blocking"] = {
    ["Guard"]= function(CombatController: CombatMachine, StateMachine: StateMachine, UID, ...)
        SSS_Communicate("UpdCS", {UID, 3, 18})
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
    ["Blocked"] = function(CombatController: CombatMachine, StateMachine: StateMachine, UID, Extra_Data:SharedTypes.Extra_Damage_Data, ...)
        SSS_Communicate("Posture_Damage", {UID, Extra_Data})
        SSS_Communicate("UpdCS", {UID, 3, 17})
        local CPProfile = Character_Controller.Give_Profile(UID)
        CPProfile.FA:SendMessage("KBMove", Extra_Data)
        print("Blocked the Hit")
    end,    
    ["Parried"] = function(CombatController: CombatMachine, StateMachine: StateMachine, UID, Extra_Data:SharedTypes.Extra_Damage_Data, ...)
        SSS_Communicate("Posture_Damage", {UID, Extra_Data})
        SSS_Communicate("UpdCS", {UID, 3, 16})
        local CPProfile = Character_Controller.Give_Profile(UID)
        CPProfile.FA:SendMessage("KBMove", Extra_Data)
        print("Parried the Hit")
    end,

    ["GuardBroken"] = function(CombatController: CombatMachine, StateMachine: StateMachine, UID, ...)
        CombatController.ChangeState(UID, "TrueStun")
        CombatController.TriggerAction(UID, "GuardBroken", ...)
    end,
    --* "StopBlock" replaces "Release" reason Action "Release" is NOT here is bcos in SoftStun you can still Block 
    ["StopBlock"] = function(CombatController: CombatMachine, StateMachine: StateMachine, UID, ...)
        local OldState = CombatController.ChangeToOldState(UID)
        local StateNum = State_Dictionary.GiveNumRef(OldState) 
        SSS_Communicate("UpdCS", {UID, StateNum, 0})
        CombatController.ChangeToOldState(UID)
    end, 
}
ServerCombatStates.Blocking["TriggerDead"] = Dead
ServerCombatStates.WeaponOut["TriggerDead"] = Dead
ServerCombatStates.Idle["TriggerDead"] = Dead
ServerCombatStates.SoftStun["TriggerDead"] = Dead
ServerCombatStates.HeavyAttack["TriggerDead"] = Dead
ServerCombatStates.LightAttack["TriggerDead"] = Dead
ServerCombatStates.Skill["TriggerDead"] = Dead    

ServerCombatStates.WeaponOut["SoftStun"] = SoftStun
ServerCombatStates.Idle["SoftStun"] = SoftStun
ServerCombatStates.TrueStun["SoftStun"] = SoftStun
ServerCombatStates.Skill["SoftStun"] = SoftStun    
ServerCombatStates.LightAttack["SoftStun"] = SoftStun    

ServerCombatStates.WeaponOut["TrueStun"] = TrueStun
ServerCombatStates.Idle["TrueStun"] = TrueStun
ServerCombatStates.SoftStun["TrueStun"] = TrueStun
ServerCombatStates.Skill["TrueStun"] = TrueStun

--[[ --* Run and StopRun may get removed from the game
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

]]

return ServerCombatStates