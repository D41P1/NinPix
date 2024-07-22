--// local types = require(script.Parent.types)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared
local ItemDataMod = require(Shared.ItemDataMod)
export type CustomHumanoid = { 
    CurrentState: string,
    OldState: string,
    IsLocked: string,
    MoveTracker: Tween?,
    Animator: Animator,
    MoveKeys: string,
    Mover: AnimationTrack,  --thread
    Walk: AnimationTrack,
    IsWalking: boolean,
    Idle: AnimationTrack,
    Fall: AnimationTrack,
    Sprint: AnimationTrack,
    Jump: AnimationTrack,
    Landed: AnimationTrack,
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
    ["Detect"]: UnreliableRemoteEvent
}
export type CDTable = {
    ParryStart: number,
    ParryCD: number
}
export type ClientStateMachine = {
    ["CurrentState"] : string,
    ["OldState"] : string,
    ["CurrentAction"] : AnimationTrack?,
    ["StateModule"]: any,
    ["ActiveHotbar"]: string,
    ["Hotbar1"]: any?,
    ["Hotbar2"]: any?,
    ["CurrentItem"]: string?, -- Weapon, Skill, Misc
    ["CurrentPhysicalItem"]: Model?, 
    ["WeaponItem"]:string?,
    ["SStun"]: thread?,
    ["TStun"]: thread?,
    ["Anims"]: {[number]: string},
    ["M1Count"]: number,
    ["CDs"]: CDTable,
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
export type Profile = {
    UID: string,
    Actor: Actor,
    Avatar: Model,
    Humanoid: CustomHumanoid,
    Forward: Actor,
    Down: Actor,
    Detect: Actor,
}
export type ItemDataMod = {
    Height: number,
    Width: number,
    Range: number,
    Damage:number,
    Posture: number,
    KB: number,
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

return nil