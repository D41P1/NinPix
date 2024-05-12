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
    [string]: AnimationTrack
}
export type Events = RemoteEvent? --| UnreliableRemoteEvent
export type Machine = {
    InitHumanoid: (self: any, PlayerName: string) ->  nil,
    TriggerAction: ( Character: Model, Event: Events,  Action: string, ... any) -> nil,
    ChangeState: ( PlayerName: string, NewState: string, OldState: string?) -> nil,
    ChangeToOldState: ( PlayerName: string) -> nil
}
export type PixelDummy = {
    Head: BasePart,
    Body: BasePart,
    PrimaryPart: BasePart,
    Torso: BasePart,
    Name: string
}
export type CharacterEvents = {
    ["Walk"] : UnreliableRemoteEvent ,
    ["StopWalk"] : UnreliableRemoteEvent,
    ["Jump"] : UnreliableRemoteEvent
}
export type workspace = {
    Map : {
        Spawn: BasePart -- temporary
    },
    FX: Folder
}


return nil