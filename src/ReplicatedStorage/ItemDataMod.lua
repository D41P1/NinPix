
--[[ Some Info on Mod
Fasterst it can go is 550 HBTime
Anim:AdjustSpeed(1/(HBTime/1000)) = Simulating AttackSpeed
Type is for Animations and SFX
all the Weapon Types so far {
Sword
HeavySword
Dagger
Fist
}
]]
local ItemDataMod = {}
--* All KB for weapons must be 5<
--* All Range needs to be at least 2 studs bigger than their own KB
ItemDataMod["Sword"] = {
    Type = "Sword",
    Height = 8,
    EquipType = 7,
    Width = 8,
    Range = 12,
    Damage = 5,
    Posture = 24, 
    KB = 8,
    HBTime = 650,
    Stun = 2,
}
ItemDataMod["RustySword"] = {
    Type = "Sword",
    Height = 8,
    EquipType = 7,
    Width = 8,
    Range = 12,
    Damage = 6,
    Posture = 24, 
    KB = 7,
    HBTime = 650,
    Stun = 2,
}
ItemDataMod["RustySabre"] = {
    Type = "Sword",
    Height = 12,
    EquipType = 7,
    Width = 10,
    Range = 12,
    Damage = 5,
    Posture = 25, 
    KB = 7,
    HBTime = 650,
    Stun = 2,
}
ItemDataMod["RustyAxe"] = {
    Type = "HeavySword",
    Height = 8,
    EquipType = 7,
    Width = 8,
    Range = 16,
    Damage = 10,
    Posture = 34, 
    KB = 12,
    HBTime = 850,
    Stun = 2,
}
ItemDataMod["RustyDagger"] = {
    Type = "Dagger",
    Height = 8,
    EquipType = 7,
    Width = 10,
    Range = 10,
    Damage = 5,
    Posture = 20, 
    KB = 6,
    HBTime = 550,
    Stun = 2,
}
ItemDataMod["RustyDusters"] = {
    Type = "Fist",
    Height = 8,
    EquipType = 7,
    Width = 8,
    Range = 10,
    Damage = 6,
    Posture = 24, 
    KB = 6,
    HBTime = 550,
    Stun = 2,
}
ItemDataMod["ZabZaBlade"] = {
    Type = "HeavySword",
    Height = 12,
    EquipType = 7,
    Width = 15,
    Range = 17,
    Damage = 15,
    Posture = 40, 
    KB = 13,
    HBTime = 800,
    Stun = 2,
}





--[[ BodyTable
1 = Head
2 = Body
3 = Right Arm
4 = Left Arm
5 = Right Leg
6 = Left Leg
7 = ToolBar
]]
export type ItemData = {
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
export type WeaponData = {
    Height: number,
    Width: number,
    Range: number,
    Damage:number,
    KB: number,
    HBTime:number,
    Stun: number,
    [string]: any
}

function ItemDataMod.GiveCopyData(ItemName:string) 
    local ItemInfo = ItemDataMod[ItemName]
    if  ItemInfo then 
        return table.clone(ItemInfo) :: ItemData
    end
    warn("incorrect item name: ", ItemName);
    return 
end

return ItemDataMod