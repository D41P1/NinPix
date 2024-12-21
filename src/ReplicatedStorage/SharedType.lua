--// local types = require(script.Parent.types)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared
local types = require(script.Parent.types)
local ItemDataMod = require(Shared.ItemDataMod)

export type CustomHumanoid = { 
    CurrentState: string,
    OldState: string,
    IsLocked: string,
    MoveTracker: Tween?,
    Animator: Animator,
    Motors: {Motor6D}, --TODO remove
    RagdollTime: thread?,
    MoveKeys: string,
    Walk: AnimationTrack,
    IsWalking: boolean,
    Falltracker: Tween?,
    StateMachine: {[string]: (any) -> any}
    
}
export type Events = RemoteEvent? --| UnreliableRemoteEvent
export type Machine =
{
    InitHumanoid: (self: any, PlayerName: string) ->  nil,
    TriggerAction: ( Character: Model, Event: Events,  Action: string, ... any) -> nil,
    ServerTriggerAction: ( UID: string, Event: Events,  Action: string, ... any) -> nil,
    ChangeState: ( PlayerName: string, NewState: string, OldState: string?) -> nil,
    ChangeToOldState: ( PlayerName: string) -> nil
}
--[[
-- export type PixelDummy = {
--     Head: BasePart,
--     Body: BasePart,
--     PrimaryPart: BasePart,
--     Torso: BasePart,
--     Name: string
-- }


]]
export type PixelDummy = typeof(ReplicatedStorage.Character.PixelDummy)

export type CharacterEvents = {
    ["Walk"] : UnreliableRemoteEvent ,
    ["StopWalk"] : UnreliableRemoteEvent,
    ["Jump"] : UnreliableRemoteEvent,
    ["M1"]: UnreliableRemoteEvent,
    ["M2"]: UnreliableRemoteEvent,
    ["Block"]: UnreliableRemoteEvent,
    ["StopBlock"]: UnreliableRemoteEvent,
    ["Skill"]: UnreliableRemoteEvent,
    ["Tool"]: UnreliableRemoteEvent,
    ["Run"]: UnreliableRemoteEvent,
    ["StopRun"]: UnreliableRemoteEvent,
    ["Detect"]: UnreliableRemoteEvent,
    ["Inventory"]:UnreliableRemoteEvent,
    ["MoveLook"]:UnreliableRemoteEvent,
    ["WallRun"]:UnreliableRemoteEvent,
    ["Dash"]:UnreliableRemoteEvent,
    ["Everything"]:UnreliableRemoteEvent
}
export type CDTable = {
    ParryStart: number,
    ParryCD: number
}
export type ClientStateMachine = {
    ["CurrentState"] : string,
    ["OldState"] : string,
    ["CurrentAction"] : thread?,
    ["StateModule"]: any,
    ["WeaponItem"]:string?,
    ["SStun"]: thread?,
    ["TStun"]: thread?,
    ["M1Count"]: number,
    ["M1ResetTime"]:number,
    ["CDs"]: CDTable,
}
export type ServerCombat_Profile = {
    ["CurrentState"] : string,
    ["OldState"] : string,
    ["CurrentAction"] : thread?,
    ["StateModule"]: any,
    ["SStun"]: thread?,
    ["TStun"]: thread?,
    ["Anims"]: {[number]: string},
    ["M1Count"]: number,
    ["M1ResetTime"]:number,
    ["CDs"]: CDTable,
    ["Allow_Hit"]:boolean
}
export type Character_Stats = {
    Health: number,
    Posture: number,
    Stamina: number,
    MaxHealth: number,
    MaxPosture: number,
    MaxStamina: number,
    Range: number, 
    Width: number, 
    Height: number,
    Knockback: number, 
    Stun: number, 
    Damage: number,
    HBTime:number
}
export type Extra_Damage_Data = {
    ["Attackers_Stats"]:Character_Stats,
    ["CFV"]:CFrameValue,
    ["Amplifiers"]:{number}
}


export type NPCStateMachine = {
    ["CurrentState"] : string,
    ["OldState"] : string,
    ["CurrentAction"] : AnimationTrack?,
    ["StateModule"]: any,
    ["CurrentItem"]: string?, -- Weapon, Skill, Misc
    ["CurrentPhysicalItem"]: Model?, 
    ["WeaponItem"]:string?,
    ["SStun"]: thread?,
    ["TStun"]: thread?,
    ["Anims"]: {[number]: string},
    ["M1Count"]: number,
    ["M1ResetTime"]:number,
    ["CDs"]: CDTable,
}

export type ClientCombatMachine = {
    InitMachine: (self: ClientCombatMachine, Character: Model, StateModule: any, buffer?) -> nil,
    InitNPCMachine: (self: ClientCombatMachine, Character: Model, StateModule: any) -> nil,
    TriggerAction: (Character: Model, Event: UnreliableRemoteEvent?,  Action: string, ... any) -> nil,
    ChangeState: (UID: string, NewState: string, OldState: string?) -> nil,
    ForceState: (UID: string, NewState: string, OldState: string?) -> nil,
    ChangeToOldState: (UID: string) -> string 
}
export type ServerCombatMachine = {
    InitMachine: (self: ServerCombatMachine, Character: Model, StateModule: any, buffer?) -> nil,
    TriggerAction: (UID:string, Action: string, ... any) -> nil,
    ChangeState: (UID: string, NewState: string, OldState: string?) -> nil,
    ForceState: (UID: string, NewState: string, OldState: string?) -> nil,
    ChangeToOldState: (UID: string) -> string 
}
export type Skill_Data = {
    Range:number,
    Width:number,
    Height:number
}
export type Profile = {
    UID: string,
    Avatar: typeof(workspace.WORKING_PROD_PixelDummy),
    Humanoid: CustomHumanoid,
    Forward: Actor,
    Down: Actor,
    Procedural: Actor,
    FMV: NumberValue,
    UV3V:Vector3Value,
    MV3:Vector3Value,
    LV3:Vector3Value,
    VNV:NumberValue,
    StateNum:number?,
    JumpBool:boolean,
    ToolBars:{{number}}, --* [ 1 -> 2 ] = { [1] -> [8]: ItemID}
    BodyEquipped:{number},
    Active_ToolBar:number,
    CurrentBodyEquipped: {
        [number]: Model
    },
    Current_Selected_Item:number,
    CurrentItem: string?, -- Weapon, Skill, Misc
    CurrentPhysicalItem: Model?, 
}
export type ItemData = {
    Height: number,
    Width: number,
    Range: number,
    Damage:number,
    Posture: number,
    Knockback: number,
    HBTime:number,
    Stun: number,
    [string]: any
}
export type InitNPCData = {
    TypeFSM: string,
    TypePathFinding:string,
    SpawnPoint: Vector3,
    CurrentCF: CFrame
}
export type NPCData = {
    Health:number,
    Posture:number,
    WalkSpeed:number,
    Hip:number,
    BodyType:string,
    Weapon:string?
}

--* Avatar types
export type Item_ColorInfo = {
    Count:number,
    R: number,
    G: number,
    B: number
}
export type RGBColor = {
    R: number,
    G: number,
    B: number
}
export type PlayerInfo = {
    Eyes: Item_ColorInfo,
    Mouth: Item_ColorInfo,
    Hair: Item_ColorInfo,
    Shirt: Item_ColorInfo,
    Pants: Item_ColorInfo,    
    Skin: RGBColor
}
export type Color_Of_Items = {
    Eyes: RGBColor,
    Mouth: RGBColor,
    Hair: RGBColor,
    Shirt: RGBColor,
    Pants: RGBColor,    
    Skin: RGBColor
}
export type ChosenItemNumbers = {
    Eyes: number,
    Mouth: number,
    Hair: number,
    Shirt: number,
    Pants: number,    
    Skin: number
}
return nil