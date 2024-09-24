export type ActionTable = {
    ModName: string,
    FuncName: string,
    Values: {any}
}
export type HumanoidModel = {
    Body: BasePart,
    AC: { Animator: Animator },
    Clone: (self: any) -> HumanoidModel,
    SetAttribute: (self: any, ValueName: string, any) -> nil 
}

export type ServerStorage = {
    Hitbox: {
        Humanoid: HumanoidModel
    }
}

return nil
